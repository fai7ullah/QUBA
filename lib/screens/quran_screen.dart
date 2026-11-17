import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Quran tab: surah list with name/number filter, bookmarks,
/// and the full-Quran search entry point.
class QuranScreen extends StatefulWidget {
  const QuranScreen({
    super.key,
    required this.onOpenSurah,
    required this.onOpenSearch,
    required this.onOpenReader,
  });
  final void Function(int surah) onOpenSurah;
  final VoidCallback onOpenSearch;
  final void Function(int surah, int ayah) onOpenReader;

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
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
    final all = repo.surahs;
    final filtered = _query.isEmpty
        ? all
        : all
            .where((s) =>
                s.nameEnglish.toLowerCase().contains(_query.toLowerCase()) ||
                s.meaning.toLowerCase().contains(_query.toLowerCase()) ||
                s.number.toString() == _query.trim())
            .toList();
    final bookmarks = appState.bookmarks.toList()..sort();

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: QubaSearchField(
              controller: _queryController,
              hint: tr('search_surah'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: GlassCard(
              radius: 16,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              onTap: widget.onOpenSearch,
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: p.emerald),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('search_quran'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  Text(
                    'Arabic + English',
                    style: TextStyle(fontSize: 12.5, color: p.muted),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: p.muted),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 120),
              children: [
                if (bookmarks.isNotEmpty && _query.isEmpty) ...[
                  SectionLabel('Bookmarks'),
                  const SizedBox(height: 10),
                  ...bookmarks.map((key) {
                    final parts = key.split(':');
                    final s = int.parse(parts[0]);
                    final a = int.parse(parts[1]);
                    final surah = repo.surah(s);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        radius: 18,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        onTap: () => widget.onOpenReader(s, a),
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_rounded,
                                size: 19, color: p.gold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${surah.nameEnglish} $s:$a',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                            ),
                            Text(
                              surah.nameArabic,
                              style: const TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                for (final s in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _surahRow(context, s),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _surahRow(BuildContext context, Surah s) {
    final p = QubaPalette.of(context);
    final downloaded = appState.downloadedSurahs.contains(s.number);
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => widget.onOpenSurah(s.number),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.emerald.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: p.gold.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                '${s.number}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: p.emerald,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nameEnglish,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.meaning} • ${s.revelation} • ${s.ayahCount} ${tr('verses')}',
                  style: TextStyle(fontSize: 12.5, color: p.muted),
                ),
              ],
            ),
          ),
          if (downloaded) ...[
            Icon(Icons.offline_pin_rounded, color: p.emerald, size: 20),
            const SizedBox(width: 6),
          ],
          Text(
            s.nameArabic,
            style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, color: p.ink),
          ),
        ],
      ),
    );
  }
}
