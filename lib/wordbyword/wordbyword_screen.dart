import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../translation_data.dart';
import '../widgets.dart';
import 'wbw_repo.dart';

/// Word-by-word view for one ayah: the verse, then each word as a chip
/// — Arabic word on top, transliteration and English meaning below.
///
/// Defaults to the last-read ayah. An integrator wires
/// [WordByWordScreen.showSheet] into the reader so any ayah can open
/// its word breakdown in a bottom sheet.
class WordByWordScreen extends StatelessWidget {
  const WordByWordScreen({super.key, this.surah, this.ayah});
  final int? surah;
  final int? ayah;

  /// Opens the same word-by-word content in a modal bottom sheet.
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
                child: _WbwContent(surah: surah, ayah: ayah, inSheet: true),
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
            child: _WbwContent(
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

/// The word-by-word body shared by [WordByWordScreen] and
/// [WordByWordScreen.showSheet]: header, the ayah card, the word chips,
/// then prev/next navigation and a surah/ayah jump.
class _WbwContent extends StatefulWidget {
  const _WbwContent({
    required this.surah,
    required this.ayah,
    required this.inSheet,
  });
  final int surah;
  final int ayah;
  final bool inSheet;

  @override
  State<_WbwContent> createState() => _WbwContentState();
}

class _WbwContentState extends State<_WbwContent> {
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
    await WordByWordRepository.instance.load();
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
                    tr('wbw_loading'),
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
    final repo = WordByWordRepository.instance;
    final words = repo.wordsFor(_surah, _ayah);

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
                              appState.translationId,
                            )
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        textAlign:
                            TranslationRepository.instance.isRtl(
                              appState.translationId,
                            )
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
              if (!repo.isAvailable)
                GlassCard(child: _unavailableText(p))
              else if (words.isEmpty)
                GlassCard(
                  child: Text(
                    tr('wbw_no_words'),
                    style: TextStyle(
                      fontSize: 14.5,
                      color: p.muted,
                      height: 1.5,
                    ),
                  ),
                )
              else ...[
                SectionLabel(trf('wbw_words', {'n': words.length})),
                const SizedBox(height: 12),
                // Word chips always flow right-to-left (Arabic reading
                // order), whatever the UI language is.
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final w in words)
                        _wordChip(p, w, quran.arabicFontFamily),
                    ],
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

  /// One word chip: Arabic word on top, transliteration and meaning
  /// below. Width-capped so a long meaning wraps instead of stretching
  /// the chip across the screen.
  Widget _wordChip(QubaPalette p, WbwWord word, String arabicFont) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.arabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: arabicFont,
                fontSize: 22,
                height: 1.6,
                color: p.ink,
              ),
            ),
            if (word.transliteration.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                word.transliteration,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: p.emerald,
                ),
              ),
            ],
            if (word.meaning.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                word.meaning,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.35),
              ),
            ],
          ],
        ),
      ),
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
                  tr('wbw_title'),
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
                  trf('wbw_ayah_label', {'surah': _surah, 'ayah': _ayah}),
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
      title: tr('wbw_title'),
      subtitle: trf('wbw_ayah_label', {'surah': _surah, 'ayah': _ayah}),
    );
  }

  Widget _unavailableText(QubaPalette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('wbw_unavailable'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('wbw_unavailable_body'),
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
                    tr('wbw_previous'),
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
                    tr('wbw_next'),
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
            label: tr('wbw_surah'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _jumpField(
            p,
            controller: _ayahController,
            label: tr('wbw_ayah'),
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
