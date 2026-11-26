import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../audio.dart';
import '../data.dart';
import '../i18n.dart';
import '../juz_data.dart';
import '../mushaf_data.dart';
import '../share_card.dart';
import '../tafsir/tafsir_screen.dart';
import '../theme.dart';
import '../translation_data.dart';
import '../widgets.dart';
import '../widgets/note_editor.dart';
import 'mushaf_screen.dart';
import 'search_screen.dart';

/// Quran reader, redesigned to the reference layout: back / download /
/// search / settings icons, a surah picker pill + "Juz: N" pill, and one
/// card per verse — Arabic with a circled verse number, share + bookmark
/// + green play/pause buttons, English translation below in a plain
/// card. The playing verse is highlighted yellow and the app-wide
/// bottom player (lib/widgets/global_player.dart) stays visible
/// while audio plays.
///
/// Audio is per-verse streaming with auto-advance through the surah, in
/// any of eighteen reciters; a surah downloaded once plays offline (whole
/// file for Alafasy and Yasser Al-Dosari, verse by verse for the others).
/// No teacher-feedback banner (QUBA has no teacher service).
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah = 1,
  });
  final int surahNumber;
  final int initialAyah;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();
  final Listenable _audioListenable = Listenable.merge([
    AudioService.instance.currentSurah,
    AudioService.instance.currentAyah,
    AudioService.instance.currentName,
    AudioService.instance.currentReciter,
  ]);

  late int _surahNumber;
  late int _visibleJuz;

  Surah get _surah => QuranRepository.instance.surah(_surahNumber);

  /// List offset of the first verse: 1 when the surah shows a Basmala
  /// header as list item 0, 0 for surahs 1 and 9. The Basmala is never
  /// an ayah — verse numbering stays 1-based from the first real verse.
  int get _basmalaOffset => hasBasmalaHeader(_surahNumber) ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.surahNumber;
    _visibleJuz = juzOf(widget.surahNumber, widget.initialAyah);
    _positionsListener.itemPositions.addListener(_trackVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached && widget.initialAyah > 1) {
        _scrollController.jumpTo(
          index: widget.initialAyah - 1 + _basmalaOffset,
        );
      }
      appState.setLastRead(widget.surahNumber, widget.initialAyah);
    });
  }

  @override
  void dispose() {
    _positionsListener.itemPositions.removeListener(_trackVisible);
    super.dispose();
  }

  void _trackVisible() {
    final positions = _positionsListener.itemPositions.value.where(
      (p) => p.itemTrailingEdge > 0,
    );
    if (positions.isEmpty) return;
    final first = positions.reduce(
      (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b,
    );
    // List index 0 is the Basmala header when one is shown; the first
    // real verse sits at index _basmalaOffset. Clamp to verse 1 so the
    // Basmala itself still counts as "start of the surah".
    var ayah = first.index + 1 - _basmalaOffset;
    if (ayah < 1) ayah = 1;
    appState.setLastRead(_surahNumber, ayah);
    final j = juzOf(_surahNumber, ayah);
    if (j != _visibleJuz) setState(() => _visibleJuz = j);
  }

  void _switchSurah(int surah, int ayah) {
    // Playback is app-wide now: switching the surah being read does
    // not stop the recitation session. The bottom player keeps
    // showing (and controlling) whatever is actually playing until
    // the user plays a verse here or closes the player.
    setState(() {
      _surahNumber = surah;
      _visibleJuz = juzOf(surah, ayah);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.jumpTo(index: ayah - 1 + _basmalaOffset);
      }
      appState.setLastRead(surah, ayah);
    });
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          onOpenReader: (s, a) {
            Navigator.of(context).pop();
            _switchSurah(s, a);
          },
          onOpenJuz: (juz) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MushafScreen(
                  initialPage: MushafData.instance.pageOfJuz(juz),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _pickSurah() {
    final repo = QuranRepository.instance;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final p = QubaPalette.of(ctx);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    tr('choose_surah'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: repo.surahs.length,
                    itemBuilder: (ctx, i) {
                      final s = repo.surahs[i];
                      final current = s.number == _surahNumber;
                      return ListTile(
                        leading: RosetteNumber(number: s.number, size: 40),
                        title: Text(
                          s.nameEnglish,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          "${tr('surah_meaning_${s.number}')} • ${s.ayahCount} ${tr('verses')}",
                        ),
                        trailing: current
                            ? Icon(Icons.check_rounded, color: p.emerald)
                            : null,
                        tileColor: current ? p.activeFill : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _switchSurah(s.number, 1);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareAyah(Ayah ayah) {
    final surah = _surah;
    final ref = '${surah.nameEnglish} ${surah.number}:${ayah.number}';
    final repo = QuranRepository.instance;
    final arabic = repo.arabicText(_surahNumber, ayah.number);
    final shown = TranslationRepository.instance.textFor(
      appState.translationId,
      _surahNumber,
      ayah.number,
    );
    final text = '$arabic\n\n"${ayah.english}"\n— $ref';
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(tr('share_as_image')),
              onTap: () {
                Navigator.of(ctx).pop();
                unawaited(
                  ShareCard.share(
                    arabic: arabic,
                    body: shown ?? '',
                    reference: ref,
                    fallbackText: text,
                    bodyRtl: TranslationRepository.instance.isRtl(
                      appState.translationId,
                    ),
                    arabicFont: repo.arabicFontFamily,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: Text(tr('share_as_text')),
              onTap: () {
                Navigator.of(ctx).pop();
                unawaited(SharePlus.instance.share(ShareParams(text: text)));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onPlayTap(Ayah ayah) {
    final audio = AudioService.instance;
    final isCurrent =
        audio.currentSurah.value == _surahNumber &&
        audio.currentAyah.value == ayah.number;
    if (isCurrent) {
      unawaited(audio.togglePause());
    } else {
      unawaited(audio.playAyah(_surahNumber, ayah.number));
    }
  }

  Future<void> _onDownloadTap(bool downloaded) async {
    final audio = AudioService.instance;
    if (downloaded) {
      await audio.deleteDownload(_surahNumber);
    } else {
      final ok = await audio.downloadSurah(_surahNumber);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('download_failed'))));
      }
    }
    if (mounted) setState(() {});
  }

  void _showTextSettings() {
    final p = QubaPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trf('arabic_text_size_n', {
                    'n': appState.arabicFontSize.round(),
                  }),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: appState.arabicFontSize,
                  min: 20,
                  max: 46,
                  divisions: 26,
                  onChanged: (v) {
                    appState.update(() => appState.arabicFontSize = v);
                    setSheet(() {});
                    setState(() {});
                  },
                ),
                // Translation: label-above-control — the dropdown holds
                // long names and would squeeze the label to one letter
                // wide if it shared the row (same bug as Settings).
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate_rounded, color: p.emerald),
                        const SizedBox(width: 12),
                        Text(
                          tr('translation'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: appState.translationId,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final id in TranslationRepository.ids)
                          DropdownMenuItem(
                            value: id,
                            child: Text(
                              tr(TranslationRepository.labelKeyFor(id)),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          appState.setTranslation(v);
                          setSheet(() {});
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                if (!TranslationRepository.instance.isAvailable(
                  appState.translationId,
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      tr('translation_unavailable'),
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surah;
    final audio = AudioService.instance;
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _audioListenable,
            builder: (context, _) {
              final playingAyah = audio.currentAyah.value;
              // Bottom padding keeps the last verse clear of the
              // app-wide player while any session is active.
              final audioActive = audio.hasActiveSession;
              return Column(
                children: [
                  _topBar(context),
                  _selectorRow(context),
                  Expanded(
                    child: StreamBuilder<bool>(
                      stream: audio.player.playingStream,
                      initialData: audio.player.playing,
                      builder: (context, snap) {
                        final playing = snap.data ?? false;
                        // The Basmala is list item 0 (when shown) so
                        // it scrolls away with the verses instead of
                        // staying pinned at the top. It is not a verse:
                        // verse cards start at index _basmalaOffset and
                        // keep their 1-based numbers.
                        return ScrollablePositionedList.builder(
                          itemScrollController: _scrollController,
                          itemPositionsListener: _positionsListener,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            audioActive ? 120 : 24,
                          ),
                          itemCount: surah.ayahCount + _basmalaOffset,
                          itemBuilder: (context, i) {
                            if (_basmalaOffset == 1 && i == 0) {
                              return _basmalaHeader(context);
                            }
                            return _verseCard(
                              context,
                              surah.ayahs[i - _basmalaOffset],
                              playingAyah,
                              playing,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The Basmala as the list's first item: same centered styling as
  /// before, but now it scrolls away with the verses. Text and font
  /// follow the active Mushaf style.
  Widget _basmalaHeader(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Text(
        repo.bismillah,
        style: TextStyle(
          fontFamily: repo.arabicFontFamily,
          fontSize: appState.arabicFontSize * 0.9,
          color: p.ink,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final p = QubaPalette.of(context);
    final audio = AudioService.instance;
    Widget circleButton(IconData icon, VoidCallback onTap) {
      return GlassCard(
        radius: 20,
        padding: const EdgeInsets.all(8),
        onTap: onTap,
        child: Icon(icon, size: 20, color: p.emerald),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          circleButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          ValueListenableBuilder<int?>(
            valueListenable: audio.downloadingSurah,
            builder: (context, downloading, _) {
              if (downloading == _surahNumber) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.emerald,
                    ),
                  ),
                );
              }
              final downloaded = audio.isDownloadedSync(_surahNumber);
              return circleButton(
                downloaded ? Icons.offline_pin_rounded : Icons.download_rounded,
                () => _onDownloadTap(downloaded),
              );
            },
          ),
          const SizedBox(width: 8),
          circleButton(Icons.search_rounded, _openSearch),
          const SizedBox(width: 8),
          circleButton(Icons.settings_outlined, _showTextSettings),
        ],
      ),
    );
  }

  Widget _selectorRow(BuildContext context) {
    final p = QubaPalette.of(context);
    final surah = _surah;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              onTap: _pickSurah,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      surah.nameEnglish,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: p.ink,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GlassCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              trf('juz_n', {'n': _visibleJuz}),
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verseCard(
    BuildContext context,
    Ayah ayah,
    int? playingAyah,
    bool playing,
  ) {
    final p = QubaPalette.of(context);
    final bookmarked = appState.isBookmarked(_surahNumber, ayah.number);
    final isCurrent =
        playingAyah == ayah.number &&
        AudioService.instance.currentSurah.value == _surahNumber;
    // Yellow highlight on the playing verse, as in the reference.
    // A deeper gold-olive in dark mode so the text stays readable.
    final highlight = isCurrent
        ? (p.dark ? const Color(0xFF7A6A1F) : const Color(0xFFFFF6A5))
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic + actions. Flat (no blur) like the reference —
            // and lighter on scrolling performance.
            Container(
              color: highlight ?? p.cardFill,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          QuranRepository.instance.arabicText(
                            _surahNumber,
                            ayah.number,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily:
                                QuranRepository.instance.arabicFontFamily,
                            fontSize: appState.arabicFontSize,
                            height: 1.9,
                            color: p.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: p.ink, width: 1.3),
                        ),
                        child: Text(
                          '${ayah.number}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        iconSize: 24,
                        color: p.emerald,
                        tooltip: tr('share_verse'),
                        onPressed: () => _shareAyah(ayah),
                      ),
                      IconButton(
                        icon: Icon(
                          bookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                        iconSize: 24,
                        color: p.emerald,
                        tooltip: bookmarked
                            ? tr('remove_bookmark')
                            : tr('bookmark_verse'),
                        onPressed: () {
                          appState.toggleBookmark(_surahNumber, ayah.number);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          appState.noteFor(_surahNumber, ayah.number).isNotEmpty
                              ? Icons.note_alt_rounded
                              : Icons.note_alt_outlined,
                        ),
                        iconSize: 24,
                        color: p.emerald,
                        tooltip: tr('note'),
                        onPressed: () async {
                          await showNoteEditor(
                            context,
                            _surahNumber,
                            ayah.number,
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                      // Phase 2: this ayah's tafsir in a bottom sheet
                      // (same content as the Extras screen, opened at
                      // this ayah). The word-by-word button is hidden
                      // until licensed word data exists — restore it
                      // (WordByWordScreen.showSheet) with the data.
                      IconButton(
                        icon: const Icon(Icons.menu_book_rounded),
                        iconSize: 24,
                        color: p.emerald,
                        tooltip: tr('tafsir'),
                        onPressed: () => TafsirScreen.showSheet(
                          context,
                          _surahNumber,
                          ayah.number,
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: p.emerald,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _onPlayTap(ayah),
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              isCurrent && playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 27,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The reader's own note on this verse, when one exists.
            if (appState.noteFor(_surahNumber, ayah.number).isNotEmpty)
              Container(
                color: p.bgSecondary,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt_rounded, size: 16, color: p.emerald),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appState.noteFor(_surahNumber, ayah.number),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                          color: p.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Translation under the verse, per the translation setting
            // ('none' hides it). Urdu/Dari translations read right to left.
            if (TranslationRepository.instance.textFor(
                  appState.translationId,
                  _surahNumber,
                  ayah.number,
                ) !=
                null)
              Container(
                color: p.bgSecondary,
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                child: Text(
                  TranslationRepository.instance.textFor(
                    appState.translationId,
                    _surahNumber,
                    ayah.number,
                  )!,
                  textDirection:
                      TranslationRepository.instance.isRtl(
                        appState.translationId,
                      )
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: TextStyle(fontSize: 15, height: 1.5, color: p.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
