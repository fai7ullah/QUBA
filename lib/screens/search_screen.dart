import 'package:flutter/material.dart';

import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Quran search: Arabic (diacritic-insensitive) or English, as you type.
/// Tap a result to open it in the reader.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.onOpenReader});
  final void Function(int surah, int ayah) onOpenReader;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<SearchHit> _results = [];
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final query = value.trim();
    setState(() {
      _query = query;
      _results = query.isEmpty
          ? const []
          : QuranRepository.instance.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final searching = _query.isNotEmpty;

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
                  subtitle: '6,236 verses',
                ),
                const SizedBox(height: 16),
                QubaSearchField(
                  controller: _controller,
                  hint: 'Search in Arabic or English…',
                  autofocus: true,
                  onChanged: _onChanged,
                ),
                const SizedBox(height: 12),
                if (searching)
                  Text(
                    _results.length >= 200
                        ? 'Showing the first 200 results'
                        : '${_results.length} '
                            '${_results.length == 1 ? 'verse' : 'verses'} found',
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
                          : _results.isEmpty
                              ? _emptyState(p)
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 28),
                                  itemCount: _results.length,
                                  itemBuilder: (context, i) {
                                    final hit = _results[i];
                                    final surah = repo.surah(hit.surah);
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: GlassCard(
                                        onTap: () => widget.onOpenReader(
                                            hit.surah, hit.ayah),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${surah.nameEnglish} • Ayah ${hit.ayah}',
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: p.emerald,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  size: 14,
                                                  color: p.muted,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              hit.arabic,
                                              textDirection:
                                                  TextDirection.rtl,
                                              textAlign: TextAlign.right,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'AmiriQuran',
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
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: p.muted,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
              'Search the Quran',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type Arabic or English words above — for example '
              '“mercy” or “الرحمن”. Arabic search ignores diacritics, '
              'so you can type without tashkeel.',
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
              'No verses found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different words, or check the spelling.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: p.muted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
