import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../translation_data.dart';
import '../widgets.dart';
import 'tafsir_repo.dart';

/// Tafsir view for one ayah: the verse (Arabic + the current
/// translation) followed by Tafsir al-Jalalayn and, when available,
/// Yusuf Ali's commentary.
///
/// Defaults to the last-read ayah. An integrator wires
/// [TafsirScreen.showSheet] into the reader so any ayah can open its
/// tafsir in a bottom sheet.
class TafsirScreen extends StatelessWidget {
  const TafsirScreen({super.key, this.surah, this.ayah});
  final int? surah;
  final int? ayah;

  /// Opens the same tafsir content in a modal bottom sheet.
  static void showSheet(BuildContext context, int surah, int ayah) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.88,
          child: QubaBackground(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TafsirContent(
                  surah: surah,
                  ayah: ayah,
                  inSheet: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _TafsirContent(
              surah: surah ?? appState.lastReadSurah,
              ayah: ayah ?? appState.lastReadAyah,
              inSheet: false,
            ),
          ),
        ),
      ),
    );
  }
}

/// The tafsir body shared by [TafsirScreen] and [TafsirScreen.showSheet]:
/// header, the ayah card, the Jalalayn tafsir, the Yusuf Ali commentary,
/// then prev/next navigation and a surah/ayah jump.
class _TafsirContent extends StatefulWidget {
  const _TafsirContent({
    required this.surah,
    required this.ayah,
    required this.inSheet,
  });
  final int surah;
  final int ayah;
  final bool inSheet;

  @override
  State<_TafsirContent> createState() => _TafsirContentState();
}

class _TafsirContentState extends State<_TafsirContent> {
  late int _surah;
  late int _ayah;
  bool _ready = false;

  final _surahController = TextEditingController();
  final _ayahController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _surah = widget.surah.clamp(1, 114);
    // 286 is the longest surah (Al-Baqara); the exact clamp happens in
    // [_load] once the surah lengths are known.
    _ayah = widget.ayah.clamp(1, 286);
    _surahController.text = '$_surah';
    _ayahController.text = '$_ayah';
    _load();
  }

  @override
  void dispose() {
    _surahController.dispose();
    _ayahController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final quran = QuranRepository.instance;
    if (!quran.loaded) {
      try {
        await quran.load();
      } catch (_) {
        // The Quran bundle is loaded by main() before runApp; if it
        // ever fails, the screen below stays on its loading state.
      }
    }
    await TafsirRepository.instance.load();
    await TranslationRepository.instance.load();
    if (!mounted) return;
    setState(() {
      if (quran.loaded) {
        _ayah = _ayah.clamp(1, quran.surah(_surah).ayahCount);
        _ayahController.text = '$_ayah';
      }
      _ready = true;
    });
  }

  /// Moves [delta] ayahs, crossing surah boundaries (1:1 <-> 114:6).
  void _step(int delta) {
    final quran = QuranRepository.instance;
    if (!quran.loaded) return;
    final global = (quran.globalIndexOf(_surah, _ayah) + delta).clamp(1, 6236);
    final sa = quran.surahAyahForGlobal(global);
    setState(() {
      _surah = sa[0];
      _ayah = sa[1];
      _surahController.text = '$_surah';
      _ayahController.text = '$_ayah';
    });
  }

  /// Jumps to the surah/ayah typed in the jump fields (clamped to the
  /// real ranges; invalid input is ignored).
  void _jump() {
    final quran = QuranRepository.instance;
    if (!quran.loaded) return;
    final s = int.tryParse(_surahController.text.trim());
    final a = int.tryParse(_ayahController.text.trim());
    if (s == null || a == null) return;
    final surah = s.clamp(1, 114);
    final ayah = a.clamp(1, quran.surah(surah).ayahCount);
    setState(() {
      _surah = surah;
      _ayah = ayah;
      _surahController.text = '$_surah';
      _ayahController.text = '$_ayah';
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    if (!_ready || !QuranRepository.instance.loaded) {
      return Column(
        children: [
          _header(p),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    tr('tafsir_loading'),
                    style: TextStyle(fontSize: 14, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    final quran = QuranRepository.instance;
    final surah = quran.surah(_surah);
    final translation = TranslationRepository.instance.textFor(
      appState.translationId,
      _surah,
      _ayah,
    );
    final jalalayn =
        TafsirRepository.instance.textFor('jalalayn', _surah, _ayah);
    final yusufali = TafsirRepository.instance.textFor(
      'yusufali_commentary',
      _surah,
      _ayah,
    );
    final jalalaynAvailable =
        TafsirRepository.instance.isAvailable('jalalayn');
    final yusufaliAvailable =
        TafsirRepository.instance.isAvailable('yusufali_commentary');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(p),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            surah.nameEnglish,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            surah.nameArabic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: quran.arabicFontFamily,
                              fontSize: 18,
                              color: p.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      quran.arabicText(_surah, _ayah),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: quran.arabicFontFamily,
                        fontSize: 26,
                        height: 1.9,
                        color: p.ink,
                      ),
                    ),
                    if (translation != null) ...[
                      const SizedBox(height: 12),
                      GoldDivider(),
                      const SizedBox(height: 12),
                      Text(
                        translation,
                        textDirection:
                            TranslationRepository.instance.isRtl(
                                    appState.translationId)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                        textAlign:
                            TranslationRepository.instance.isRtl(
                                    appState.translationId)
                                ? TextAlign.right
                                : TextAlign.left,
                        style: TextStyle(
                          fontSize: 15,
                          color: p.muted,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionLabel(tr('tafsir_jalalayn')),
              const SizedBox(height: 8),
              if (jalalayn != null)
                GlassCard(
                  child: Text(
                    jalalayn,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: quran.arabicFontFamily,
                      fontSize: 21,
                      height: 1.9,
                      color: p.ink,
                    ),
                  ),
                )
              else if (!jalalaynAvailable)
                GlassCard(child: _unavailableText(p))
              else
                GlassCard(
                  child: Text(
                    tr('tafsir_no_commentary'),
                    style: TextStyle(
                      fontSize: 14.5,
                      color: p.muted,
                      height: 1.5,
                    ),
                  ),
                ),
              if (yusufaliAvailable) ...[
                const SizedBox(height: 20),
                SectionLabel(tr('tafsir_yusufali')),
                const SizedBox(height: 8),
                GlassCard(
                  child: yusufali != null
                      ? Text(
                          yusufali,
                          style: TextStyle(
                            fontSize: 15,
                            color: p.ink,
                            height: 1.65,
                          ),
                        )
                      : Text(
                          tr('tafsir_no_commentary'),
                          style: TextStyle(
                            fontSize: 14.5,
                            color: p.muted,
                            height: 1.5,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
        _navBar(p),
        const SizedBox(height: 8),
        _jumpRow(p),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _header(QubaPalette p) {
    if (widget.inSheet) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('tafsir_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  trf('tafsir_ayah_label', {'surah': _surah, 'ayah': _ayah}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: p.muted,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      );
    }
    return TitleRow(
      title: tr('tafsir_title'),
      subtitle: trf('tafsir_ayah_label', {'surah': _surah, 'ayah': _ayah}),
    );
  }

  Widget _unavailableText(QubaPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('tafsir_unavailable'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('tafsir_unavailable_body'),
          style: TextStyle(fontSize: 14, color: p.muted, height: 1.5),
        ),
      ],
    );
  }

  Widget _navBar(QubaPalette p) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            onTap: () => _step(-1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18, color: p.emerald),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tr('tafsir_previous'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            onTap: () => _step(1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    tr('tafsir_next'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 18, color: p.emerald),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _jumpRow(QubaPalette p) {
    return Row(
      children: [
        Expanded(
          child: _jumpField(
            p,
            controller: _surahController,
            label: tr('tafsir_surah'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _jumpField(
            p,
            controller: _ayahController,
            label: tr('tafsir_ayah'),
          ),
        ),
        const SizedBox(width: 10),
        GlassCard(
          radius: 16,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          onTap: _jump,
          child: Text(
            tr('go'),
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: p.emerald,
            ),
          ),
        ),
      ],
    );
  }

  Widget _jumpField(
    QubaPalette p, {
    required TextEditingController controller,
    required String label,
  }) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _jump(),
        style: TextStyle(color: p.ink, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: p.muted),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
