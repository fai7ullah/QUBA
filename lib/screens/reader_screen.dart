import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../app_state.dart';
import '../audio.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Quran reader: one surah, verse-by-verse cards, bookmarks,
/// last-read tracking, Alafasy audio (stream + offline download).
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
  Surah get _surah => QuranRepository.instance.surah(widget.surahNumber);

  @override
  void initState() {
    super.initState();
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
    appState.setLastRead(widget.surahNumber, first.index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final surah = _surah;
    final p = QubaPalette.of(context);
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TitleRow(
                        title: '${surah.number}. ${surah.nameEnglish}',
                        subtitle:
                            '${surah.meaning} • ${surah.ayahCount} verses',
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(8),
                      onTap: _showTextSettings,
                      child: Icon(
                        Icons.format_size_rounded,
                        size: 20,
                        color: p.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _audioBar(context),
              ),
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
                child: ScrollablePositionedList.builder(
                  itemScrollController: _scrollController,
                  itemPositionsListener: _positionsListener,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: surah.ayahCount,
                  itemBuilder: (context, i) =>
                      _verseCard(context, surah.ayahs[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _verseCard(BuildContext context, Ayah ayah) {
    final p = QubaPalette.of(context);
    final bookmarked = appState.isBookmarked(widget.surahNumber, ayah.number);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 20,
        onTap: () => _verseActions(ayah),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.surahNumber}:${ayah.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.gold,
                    ),
                  ),
                ),
                const Spacer(),
                if (bookmarked)
                  Icon(Icons.bookmark_rounded, size: 18, color: p.gold),
              ],
            ),
            const SizedBox(height: 8),
            Text(
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
            if (appState.showTranslation) ...[
              const SizedBox(height: 10),
              Text(
                ayah.english,
                style: TextStyle(
                  height: 1.5,
                  color: p.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _verseActions(Ayah ayah) {
    final bookmarked =
        appState.isBookmarked(widget.surahNumber, ayah.number);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(bookmarked
                  ? Icons.bookmark_remove_rounded
                  : Icons.bookmark_add_rounded),
              title: Text(bookmarked ? 'Remove bookmark' : 'Bookmark this verse'),
              onTap: () {
                appState.toggleBookmark(widget.surahNumber, ayah.number);
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: const Text('Play surah audio (Alafasy)'),
              onTap: () {
                Navigator.pop(ctx);
                AudioService.instance.playSurah(widget.surahNumber);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.my_location_rounded),
              title: const Text('Set as my place (last read)'),
              onTap: () {
                appState.setLastRead(widget.surahNumber, ayah.number);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
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

  Widget _audioBar(BuildContext context) {
    final audio = AudioService.instance;
    final p = QubaPalette.of(context);
    return ValueListenableBuilder<int?>(
      valueListenable: audio.currentSurah,
      builder: (context, current, _) {
        return ValueListenableBuilder<int?>(
          valueListenable: audio.downloadingSurah,
          builder: (context, downloading, _) {
            final thisActive = current == widget.surahNumber;
            final thisDownloading = downloading == widget.surahNumber;
            final downloaded =
                appState.downloadedSurahs.contains(widget.surahNumber);
            return GlassCard(
              radius: 18,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: thisDownloading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ValueListenableBuilder<double>(
                            valueListenable: audio.downloadProgress,
                            builder: (_, prog, _) => Text(
                              'Downloading… ${(prog * 100).round()}%',
                              style: TextStyle(color: p.ink),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.headphones_rounded,
                            size: 19, color: p.emerald),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            thisActive
                                ? 'Now playing — Alafasy'
                                : 'Listen — Mishary Alafasy',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: p.ink,
                            ),
                          ),
                        ),
                        if (thisActive) ...[
                          StreamBuilder<Duration>(
                            stream: audio.player.positionStream,
                            builder: (_, snap) {
                              final pos = snap.data ?? Duration.zero;
                              final dur = audio.player.duration;
                              String f(Duration d) =>
                                  '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
                              return Text(
                                dur == null
                                    ? f(pos)
                                    : '${f(pos)} / ${f(dur)}',
                                style: TextStyle(color: p.muted),
                              );
                            },
                          ),
                          StreamBuilder<bool>(
                            stream: audio.player.playingStream,
                            builder: (_, snap) {
                              final playing = snap.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  playing
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                  size: 32,
                                  color: p.emerald,
                                ),
                                onPressed: () =>
                                    audio.toggle(widget.surahNumber),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle_outlined),
                            onPressed: () async {
                              await audio.stop();
                              setState(() {});
                            },
                          ),
                        ] else ...[
                          if (downloaded)
                            IconButton(
                              icon:
                                  const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Delete offline audio',
                              onPressed: () async {
                                await audio
                                    .deleteDownload(widget.surahNumber);
                                setState(() {});
                              },
                            ),
                          IconButton(
                            icon: Icon(downloaded
                                ? Icons.offline_pin_rounded
                                : Icons.download_rounded),
                            tooltip: downloaded
                                ? 'Saved for offline'
                                : 'Download for offline',
                            onPressed: downloaded
                                ? null
                                : () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final ok = await audio
                                        .downloadSurah(widget.surahNumber);
                                    if (!ok) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Download failed — check connection')),
                                      );
                                    }
                                    if (mounted) setState(() {});
                                  },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              size: 30,
                              color: QubaColors.emerald,
                            ),
                            onPressed: () =>
                                audio.playSurah(widget.surahNumber),
                          ),
                        ],
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
