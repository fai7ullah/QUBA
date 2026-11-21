import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../audio.dart';
import '../data.dart';
import '../i18n.dart';
import '../juz_data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'notes_screen.dart';

/// Quran tab, redesigned to the reference layout: title + bookmark /
/// search / settings icons, a Continue card of last-read surahs, a
/// SURAH / JUZ toggle, surah rows with a green play button + bookmark,
/// and juz rows with names and ranges.
///
/// No search bars on this screen — full-text search lives behind the
/// magnifier icon (SearchScreen). Layout copies the reference; colors
/// are QUBA's own palette so both themes look right.
class QuranScreen extends StatefulWidget {
  const QuranScreen({
    super.key,
    required this.onOpenSurah,
    required this.onOpenSearch,
    required this.onOpenReader,
    required this.onOpenJuz,
    required this.onOpenSettings,
  });
  final void Function(int surah) onOpenSurah;
  final VoidCallback onOpenSearch;
  final void Function(int surah, int ayah) onOpenReader;
  final void Function(int juz) onOpenJuz;
  final VoidCallback onOpenSettings;

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _showJuz = false;

  /// Last-read place first, then one chip per bookmarked surah (its
  /// first bookmarked verse). Always at least Al-Faatiha Ayat 1: the
  /// last-read place defaults to 1:1.
  List<(int surah, int ayah)> _continueItems() {
    final items = <(int, int)>[];
    final seen = <int>{};
    void add(int s, int a) {
      if (s < 1 || s > 114 || a < 1) return;
      if (seen.add(s)) items.add((s, a));
    }

    add(appState.lastReadSurah, appState.lastReadAyah);
    final marks = appState.bookmarks.map((key) {
      final parts = key.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }).toList()
      ..sort((a, b) =>
          a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    for (final m in marks) {
      add(m.$1, m.$2);
    }
    return items;
  }

  void _playSurah(Surah s) {
    final audio = AudioService.instance;
    if (appState.downloadedSurahs.contains(s.number)) {
      // Offline file when the surah was downloaded once.
      unawaited(audio.playSurah(s.number));
    } else {
      // Stream verse by verse from the start; auto-advances.
      unawaited(audio.playAyah(s.number, 1));
    }
    widget.onOpenSurah(s.number);
  }

  void _showBookmarks() {
    final repo = QuranRepository.instance;
    final marks = appState.bookmarks.map((key) {
      final parts = key.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }).toList()
      ..sort((a, b) =>
          a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('bookmarks'),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (marks.isEmpty)
                  Text(
                    tr('no_bookmarks'),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: marks.length,
                      itemBuilder: (ctx, i) {
                        final m = marks[i];
                        final surah = repo.surah(m.$1);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: RosetteNumber(number: m.$1, size: 40),
                          title: Text(
                            '${surah.nameEnglish} ${m.$1}:${m.$2}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            repo.surahNameArabic(m.$1),
                            style: TextStyle(
                                fontFamily:
                                    repo.arabicFontFamily),
                          ),
                          trailing: const Icon(
                              Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onOpenReader(m.$1, m.$2);
                          },
                        );
                      },
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
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    if (!repo.loaded) {
      return Center(
        child: Text(tr('loading'), style: TextStyle(color: p.muted)),
      );
    }
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Column(
        children: [
          _header(context),
          _continueCard(context),
          _toggle(context),
          Expanded(
            child: _showJuz ? _juzList(context) : _surahList(context),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final p = QubaPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr('quran'),
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded),
            iconSize: 27,
            color: p.ink,
            tooltip: tr('bookmarks'),
            onPressed: _showBookmarks,
          ),
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            iconSize: 27,
            color: p.ink,
            tooltip: tr('notes'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotesScreen(onOpenReader: widget.onOpenReader),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            iconSize: 27,
            color: p.ink,
            tooltip: tr('search_quran'),
            onPressed: widget.onOpenSearch,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            iconSize: 27,
            color: p.ink,
            tooltip: tr('settings'),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
    );
  }

  Widget _continueCard(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final items = _continueItems();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('continue'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final surah = repo.surah(item.$1);
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          widget.onOpenReader(item.$1, item.$2),
                      child: Container(
                        width: 148,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 13),
                        decoration: BoxDecoration(
                          color: p.bgSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              surah.nameEnglish,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${tr('ayat')} ${item.$2}',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: p.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggle(BuildContext context) {
    final p = QubaPalette.of(context);
    Widget side(String label, bool active, VoidCallback onTap) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? p.bgSecondary : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: p.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight:
                        active ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.8,
                    color: active ? p.ink : p.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: p.cardFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.cardBorder),
        ),
        child: Row(
          children: [
            side(tr('surah').toUpperCase(), !_showJuz,
                () => setState(() => _showJuz = false)),
            side(tr('juz').toUpperCase(), _showJuz,
                () => setState(() => _showJuz = true)),
          ],
        ),
      ),
    );
  }

  Widget _surahList(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    return ListView.separated(
      // NOT primary: see home_screen.dart — each tab owns its scroll
      // state instead of sharing the route's PrimaryScrollController.
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemCount: repo.surahs.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: p.gold.withValues(alpha: 0.22),
      ),
      itemBuilder: (context, i) {
        final s = repo.surahs[i];
        final bookmarked = appState.isBookmarked(s.number, 1);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onOpenSurah(s.number),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  RosetteNumber(number: s.number),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nameEnglish,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.emerald,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${tr('surah_meaning_${s.number}')} (${s.ayahCount})",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: p.ink),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    iconSize: 32,
                    color: p.emerald,
                    tooltip: trf('play_surah', {'name': s.nameEnglish}),
                    onPressed: () => _playSurah(s),
                  ),
                  IconButton(
                    icon: Icon(bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded),
                    iconSize: 26,
                    color: p.emerald,
                    tooltip: bookmarked
                        ? tr('remove_bookmark')
                        : tr('bookmark'),
                    onPressed: () =>
                        appState.toggleBookmark(s.number, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _juzList(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    return ListView.separated(
      // NOT primary: see home_screen.dart — each tab owns its scroll
      // state instead of sharing the route's PrimaryScrollController.
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemCount: juzList.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: p.gold.withValues(alpha: 0.22),
      ),
      itemBuilder: (context, i) {
        final j = juzList[i];
        final bookmarked =
            appState.isBookmarked(j.startSurah, j.startAyah);
        final range =
            '${repo.surah(j.startSurah).nameEnglish} ${j.startSurah}:${j.startAyah} - '
            '${repo.surah(j.endSurah).nameEnglish} ${j.endSurah}:${j.endAyah}';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onOpenJuz(j.number),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  RosetteNumber(number: j.number),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('juz_name_${j.number}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: p.emerald,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          range,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 13.5, color: p.ink),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded),
                    iconSize: 26,
                    color: p.emerald,
                    tooltip: bookmarked
                        ? tr('remove_bookmark')
                        : tr('bookmark'),
                    onPressed: () => appState.toggleBookmark(
                        j.startSurah, j.startAyah),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
