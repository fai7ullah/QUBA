import 'package:flutter/material.dart';

import '../data.dart';
import '../i18n.dart';
import '../juz_data.dart';
import '../search_match.dart';
import '../theme.dart';
import '../widgets.dart';

/// Quran search: surahs and juz by name/number (instant, forgiving
/// spelling), plus verse full-text in Arabic (diacritic-insensitive)
/// or English. Tap a result to open it.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onOpenReader,
    required this.onOpenJuz,
  });
  final void Function(int surah, int ayah) onOpenReader;
  final void Function(int juz) onOpenJuz;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<SearchHit> _results = [];
  List<Surah> _surahMatches = [];
  List<JuzInfo> _juzMatches = [];
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = value.trim();
    final repo = QuranRepository.instance;
    setState(() {
      _query = query;
      _results = query.isEmpty ? const [] : repo.search(query);
      _surahMatches = query.isEmpty
          ? const []
          : matchSurahs(query, repo.surahs);
      _juzMatches = query.isEmpty ? const [] : matchJuz(query, juzList);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final searching = _query.isNotEmpty;
    final hasAny =
        _surahMatches.isNotEmpty ||
        _juzMatches.isNotEmpty ||
        _results.isNotEmpty;

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleRow(
                  title: tr('search_quran'),
                  subtitle: trf('verses_count', {'n': '6,236'}),
                ),
                const SizedBox(height: 16),
                QubaSearchField(
                  controller: _controller,
                  hint: tr('search_hint'),
                  autofocus: true,
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 12),
                if (searching && _results.isNotEmpty)
                  Text(
                    _results.length >= 200
                        ? trf('showing_first_n', {'n': 200})
                        : _results.length == 1
                        ? trf('verses_found_one', {'n': _results.length})
                        : trf('verses_found_other', {'n': _results.length}),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.muted,
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: !repo.loaded
                      ? Center(
                          child: Text(
                            tr('loading'),
                            style: TextStyle(color: p.muted),
                          ),
                        )
                      : !searching
                      ? _hintState(p)
                      : !hasAny
                      ? _emptyState(p)
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            if (_surahMatches.isNotEmpty) ...[
                              _sectionHeader(p, tr('search_surahs')),
                              for (final s in _surahMatches) _surahRow(p, s),
                            ],
                            if (_juzMatches.isNotEmpty) ...[
                              _sectionHeader(p, tr('search_juz')),
                              for (final j in _juzMatches) _juzRow(p, j),
                            ],
                            if (_results.isNotEmpty) ...[
                              _sectionHeader(p, tr('search_verses')),
                              for (final hit in _results) _verseRow(p, hit),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(QubaPalette p, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.emerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    p.gold.withValues(alpha: 0.7),
                    p.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surahRow(QubaPalette p, Surah s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => widget.onOpenReader(s.number, 1),
        child: Row(
          children: [
            RosetteNumber(number: s.number, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.nameEnglish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tr('surah_meaning_${s.number}')} • ${s.ayahCount} ${tr('verses')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              s.nameArabic,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 19,
                color: p.emerald,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.muted),
          ],
        ),
      ),
    );
  }

  Widget _juzRow(QubaPalette p, JuzInfo j) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => widget.onOpenJuz(j.number),
        child: Row(
          children: [
            RosetteNumber(number: j.number, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tr('juz')} ${j.number} • ${tr('juz_name_${j.number}')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${j.startSurah}:${j.startAyah} – ${j.endSurah}:${j.endAyah}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.muted),
          ],
        ),
      ),
    );
  }

  Widget _verseRow(QubaPalette p, SearchHit hit) {
    final surah = QuranRepository.instance.surah(hit.surah);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () => widget.onOpenReader(hit.surah, hit.ayah),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${surah.nameEnglish} • ${tr('ayah')} ${hit.ayah}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: p.emerald,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.muted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hit.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: QuranRepository.instance.arabicFontFamily,
                fontSize: 21,
                height: 1.8,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hit.english,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, color: p.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hintState(QubaPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 48, color: p.gold),
            const SizedBox(height: 16),
            Text(
              tr('search_quran'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('search_empty_body'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(QubaPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: p.muted),
            const SizedBox(height: 16),
            Text(
              tr('search_no_results'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('try_different_words'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
