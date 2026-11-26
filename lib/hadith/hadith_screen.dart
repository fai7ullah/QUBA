import 'dart:async';

import 'package:flutter/material.dart';

import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'hadith_repo.dart';

/// Hadith library: the six authentic collections, browsable by book and
/// chapter, searchable in Arabic or English.
///
/// Books load lazily — the list shows the six well-known titles at
/// once, and each book's chapters load when it is first opened (or when
/// a search needs every book). A book whose file is missing or invalid
/// simply reports itself unavailable; the rest of the library keeps
/// working.
class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

/// Canonical display names for the six books, shown in the list before
/// a book's file has loaded (the file's own titles take over after).
/// (English title, Arabic title.)
const Map<String, (String, String)> _knownBooks = {
  'bukhari': ('Sahih al-Bukhari', 'صحيح البخاري'),
  'muslim': ('Sahih Muslim', 'صحيح مسلم'),
  'abudawud': ('Sunan Abi Dawud', 'سنن أبي داود'),
  'tirmidhi': ('Jami at-Tirmidhi', 'جامع الترمذي'),
  'nasai': ('Sunan an-Nasai', 'سنن النسائي'),
  'ibnmajah': ('Sunan Ibn Majah', 'سنن ابن ماجه'),
};

class _HadithScreenState extends State<HadithScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _searchGen = 0;

  bool _searching = false;
  List<Hadith>? _results;
  String? _loadingBook;

  @override
  void initState() {
    super.initState();
    _loadBooksInBackground();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the six books one at a time in the background so the list
  /// fills in with counts as each file parses. Tapping a book never
  /// waits on this: [_openBook] loads that book directly (the
  /// repository shares one in-flight load per book).
  Future<void> _loadBooksInBackground() async {
    final repo = HadithRepository.instance;
    for (final id in HadithRepository.bookIds) {
      await repo.loadBook(id);
      if (!mounted) return;
      setState(() {});
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = null;
        _searching = false;
      });
      return;
    }
    final gen = ++_searchGen;
    setState(() => _searching = true);
    // Search needs every book loaded; this is a no-op for books that
    // are already in memory.
    await HadithRepository.instance.loadAll();
    if (!mounted || gen != _searchGen) return;
    setState(() {
      _results = HadithRepository.instance.search(q);
      _searching = false;
    });
  }

  Future<void> _openBook(String id) async {
    final repo = HadithRepository.instance;
    if (!repo.isLoaded(id)) {
      setState(() => _loadingBook = id);
      await repo.loadBook(id);
      if (!mounted) return;
      setState(() => _loadingBook = null);
    }
    final book = repo.book(id);
    if (!mounted) return;
    if (book == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('hadith_unavailable'))));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HadithChaptersScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final searching = _searchController.text.trim().isNotEmpty;
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleRow(
                  title: tr('hadith_title'),
                  subtitle: tr('hadith_subtitle'),
                ),
                const SizedBox(height: 16),
                QubaSearchField(
                  controller: _searchController,
                  hint: tr('hadith_search_hint'),
                  onChanged: _onQueryChanged,
                  onSubmitted: _runSearch,
                ),
                const SizedBox(height: 16),
                if (_searching)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          tr('hadith_loading'),
                          style: TextStyle(fontSize: 14, color: p.muted),
                        ),
                      ],
                    ),
                  )
                else if (searching)
                  Expanded(child: _searchResults(p))
                else
                  Expanded(child: _bookList(p)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchResults(QubaPalette p) {
    final results = _results;
    if (results == null) {
      // Query typed but no search has completed yet.
      return Center(
        child: Text(
          tr('hadith_search_empty'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, color: p.muted, height: 1.5),
        ),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('hadith_no_results'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('hadith_no_results_body'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: p.muted, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trf('hadith_results', {'n': results.length}),
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: p.muted,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 28),
            itemCount: results.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HadithCard(hadith: results[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookList(QubaPalette p) {
    final repo = HadithRepository.instance;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 28),
      itemCount: HadithRepository.bookIds.length,
      itemBuilder: (context, i) {
        final id = HadithRepository.bookIds[i];
        final book = repo.book(id);
        final known = _knownBooks[id]!;
        final titleEn = book?.titleEn ?? known.$1;
        final titleAr = book?.titleAr ?? known.$2;
        final loading = _loadingBook == id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            onTap: () => _openBook(id),
            child: Row(
              children: [
                RosetteNumber(number: i + 1, size: 46),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titleAr,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 16,
                          color: p.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (book != null)
                        Text(
                          trf('hadith_count', {'n': book.total}),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.emerald,
                          ),
                        )
                      else if (repo.loadAttempted(id))
                        Text(
                          tr('hadith_unavailable'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.muted,
                          ),
                        )
                      else
                        Text(
                          tr('hadith_loading'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: p.muted,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Chapter list for one book. Private: only [HadithScreen] pushes it.
class _HadithChaptersScreen extends StatelessWidget {
  const _HadithChaptersScreen({required this.book});
  final HadithBook book;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleRow(
                  title: book.titleEn,
                  subtitle: trf('hadith_count', {'n': book.total}),
                ),
                const SizedBox(height: 16),
                SectionLabel(tr('hadith_chapters')),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 28),
                    itemCount: book.chapters.length,
                    itemBuilder: (context, i) {
                      final chapter = book.chapters[i];
                      final title = chapter.titleEn.isNotEmpty
                          ? chapter.titleEn
                          : trf('hadith_chapter_n', {'n': chapter.number});
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _HadithListScreen(
                                book: book,
                                chapter: chapter,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              RosetteNumber(number: chapter.number, size: 42),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.ink,
                                      ),
                                    ),
                                    if (chapter.titleAr.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        chapter.titleAr,
                                        textDirection: TextDirection.rtl,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'AmiriQuran',
                                          fontSize: 15,
                                          color: p.muted,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      trf('hadith_count', {
                                        'n': chapter.hadiths.length,
                                      }),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: p.emerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: p.muted,
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
}

/// Hadith list for one chapter. Private: only [_HadithChaptersScreen]
/// pushes it.
class _HadithListScreen extends StatelessWidget {
  const _HadithListScreen({required this.book, required this.chapter});
  final HadithBook book;
  final HadithChapter chapter;

  @override
  Widget build(BuildContext context) {
    final title = chapter.titleEn.isNotEmpty
        ? chapter.titleEn
        : trf('hadith_chapter_n', {'n': chapter.number});
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleRow(title: title, subtitle: book.titleEn),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 28),
                    itemCount: chapter.hadiths.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HadithCard(hadith: chapter.hadiths[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One hadith: Arabic matn (RTL) + English when present + grade chip +
/// reference. Shared by the chapter list and the search results.
class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith});
  final Hadith hadith;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final arabicFont = QuranRepository.instance.arabicFontFamily;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hadith.ref,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.gold,
                  ),
                ),
              ),
              if (hadith.grade != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.activeFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.gold.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      // Grades carry a scholar attribution in
                      // parentheses ("Sahih (Al-Albani)", sometimes a
                      // much longer name); the chip shows only the
                      // short verdict, like the mini-player's short
                      // reciter names (build-12).
                      hadith.grade!.split(' (').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.activeText,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hadith.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: arabicFont,
              fontSize: 22,
              height: 1.9,
              color: p.ink,
            ),
          ),
          if (hadith.english != null) ...[
            const SizedBox(height: 12),
            GoldDivider(),
            const SizedBox(height: 12),
            Text(
              hadith.english!,
              style: TextStyle(fontSize: 14.5, color: p.muted, height: 1.55),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              tr('hadith_arabic_only'),
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: p.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
