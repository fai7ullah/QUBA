import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../audio.dart';
import '../data.dart';
import '../juz_data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'search_screen.dart';

/// Quran reader, redesigned to the reference layout: back / download /
/// search / settings icons, a surah picker pill + "Juz: N" pill, and one
/// card per verse — Arabic with a circled verse number, share + bookmark
/// + green play/pause buttons, English translation below in a plain
/// card. The playing verse is highlighted yellow and a mini-player bar
/// sits at the bottom while audio plays.
///
/// Audio is per-verse Alafasy streaming with auto-advance through the
/// surah; a surah downloaded once plays its whole-surah file offline.
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
  ]);

  late int _surahNumber;
  late int _visibleJuz;

  Surah get _surah => QuranRepository.instance.surah(_surahNumber);

  @override
  void initState() {
    super.initState();
    _surahNumber = widget.surahNumber;
    _visibleJuz = juzOf(widget.surahNumber, widget.initialAyah);
    _positionsListener.itemPositions.addListener(_trackVisible);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached && widget.initialAyah > 1) {
        _scrollController.jumpTo(index: widget.initialAyah - 1);
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
    final positions = _positionsListener.itemPositions.value
        .where((p) => p.itemTrailingEdge > 0);
    if (positions.isEmpty) return;
    final first = positions.reduce(
        (a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);
    final ayah = first.index + 1;
    appState.setLastRead(_surahNumber, ayah);
    final j = juzOf(_surahNumber, ayah);
    if (j != _visibleJuz) setState(() => _visibleJuz = j);
  }

  void _switchSurah(int surah, int ayah) {
    if (surah != _surahNumber) {
      // Stop audio of the old surah so the mini-player follows the new one.
      unawaited(AudioService.instance.stop());
    }
    setState(() {
      _surahNumber = surah;
      _visibleJuz = juzOf(surah, ayah);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.jumpTo(index: ayah - 1);
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Choose surah',
                    style:
                        TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: repo.surahs.length,
                    itemBuilder: (ctx, i) {
                      final s = repo.surahs[i];
                      final current = s.number == _surahNumber;
                      return ListTile(
                        leading:
                            RosetteNumber(number: s.number, size: 40),
                        title: Text(
                          s.nameEnglish,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                            '${s.meaning} • ${s.ayahCount} verses'),
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
    final text =
        '${ayah.arabic}\n\n"${ayah.english}"\n— ${surah.nameEnglish} ${surah.number}:${ayah.number}';
    unawaited(Share.share(text));
  }

  void _onPlayTap(Ayah ayah) {
    final audio = AudioService.instance;
    final isCurrent = audio.currentSurah.value == _surahNumber &&
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Download failed — check connection')),
        );
      }
    }
    if (mounted) setState(() {});
  }

  void _showTextSettings() {
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
                  'Arabic text size: ${appState.arabicFontSize.round()}',
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show English translation (Pickthall)'),
                  value: appState.showTranslation,
                  onChanged: (v) {
                    appState.update(() => appState.showTranslation = v);
                    setSheet(() {});
                    setState(() {});
                  },
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
    final p = QubaPalette.of(context);
    final audio = AudioService.instance;
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _audioListenable,
            builder: (context, _) {
              final playingSurah = audio.currentSurah.value;
              final playingAyah = audio.currentAyah.value;
              final audioActive = playingSurah == _surahNumber;
              return Stack(
                children: [
                  Column(
                    children: [
                      _topBar(context),
                      _selectorRow(context),
                      if (surah.number != 1 && surah.number != 9)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 6),
                          child: Text(
                            bismillahUthmani,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: appState.arabicFontSize * 0.9,
                              color: p.ink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Expanded(
                        child: StreamBuilder<bool>(
                          stream: audio.player.playingStream,
                          initialData: audio.player.playing,
                          builder: (context, snap) {
                            final playing = snap.data ?? false;
                            return ScrollablePositionedList.builder(
                              itemScrollController: _scrollController,
                              itemPositionsListener: _positionsListener,
                              padding: EdgeInsets.fromLTRB(
                                  16, 4, 16, audioActive ? 120 : 24),
                              itemCount: surah.ayahCount,
                              itemBuilder: (context, i) => _verseCard(
                                context,
                                surah.ayahs[i],
                                playingAyah,
                                playing,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (audioActive)
                    _miniPlayer(context, playingAyah),
                ],
              );
            },
          ),
        ),
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
          circleButton(Icons.arrow_back_ios_new_rounded,
              () => Navigator.of(context).maybePop()),
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
                        strokeWidth: 2, color: p.emerald),
                  ),
                );
              }
              final downloaded =
                  appState.downloadedSurahs.contains(_surahNumber);
              return circleButton(
                downloaded
                    ? Icons.offline_pin_rounded
                    : Icons.download_rounded,
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _pickSurah,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: p.bgSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: p.cardBorder),
                  ),
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
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 22, color: p.ink),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: p.bgSecondary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: p.cardBorder),
            ),
            child: Text(
              'Juz: $_visibleJuz',
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
      BuildContext context, Ayah ayah, int? playingAyah, bool playing) {
    final p = QubaPalette.of(context);
    final bookmarked = appState.isBookmarked(_surahNumber, ayah.number);
    final isCurrent = playingAyah == ayah.number &&
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
                          ayah.arabic,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
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
                        tooltip: 'Share this verse',
                        onPressed: () => _shareAyah(ayah),
                      ),
                      IconButton(
                        icon: Icon(bookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded),
                        iconSize: 24,
                        color: p.emerald,
                        tooltip: bookmarked
                            ? 'Remove bookmark'
                            : 'Bookmark this verse',
                        onPressed: () {
                          appState.toggleBookmark(
                              _surahNumber, ayah.number);
                          setState(() {});
                        },
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
            if (appState.showTranslation)
              Container(
                color: p.bgSecondary,
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                child: Text(
                  ayah.english,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: p.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Floating mini-player while this surah's audio plays: medallion,
  /// "Surah: ayah" + reciter, prev / pause / next (verse mode only),
  /// close, and a thin progress line — as in the reference.
  Widget _miniPlayer(BuildContext context, int? playingAyah) {
    final p = QubaPalette.of(context);
    final audio = AudioService.instance;
    final surah = _surah;
    final ayahMode = playingAyah != null;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        decoration: BoxDecoration(
          color: p.bgSecondary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: p.cardBorder),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                children: [
                  RosetteNumber(number: surah.number, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ayahMode
                              ? '${surah.nameEnglish}: $playingAyah'
                              : surah.nameEnglish,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mishari Rashid al-Afasy',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (ayahMode)
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 28,
                      color: p.ink,
                      tooltip: 'Previous verse',
                      onPressed: audio.playPrevAyah,
                    ),
                  StreamBuilder<bool>(
                    stream: audio.player.playingStream,
                    initialData: audio.player.playing,
                    builder: (context, snap) {
                      final playing = snap.data ?? false;
                      return IconButton(
                        icon: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                        ),
                        color: p.ink,
                        tooltip: playing ? 'Pause' : 'Play',
                        onPressed: audio.togglePause,
                      );
                    },
                  ),
                  if (ayahMode)
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 28,
                      color: p.ink,
                      tooltip: 'Next verse',
                      onPressed: audio.playNextAyah,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    iconSize: 24,
                    color: p.muted,
                    tooltip: 'Stop',
                    onPressed: audio.stop,
                  ),
                ],
              ),
            ),
            StreamBuilder<Duration>(
              stream: audio.player.positionStream,
              builder: (context, snap) {
                final pos = snap.data ?? Duration.zero;
                final dur = audio.player.duration;
                final value = (dur != null && dur.inMilliseconds > 0)
                    ? (pos.inMilliseconds / dur.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0;
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 3,
                  backgroundColor:
                      p.emerald.withValues(alpha: 0.15),
                  color: p.emerald,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
