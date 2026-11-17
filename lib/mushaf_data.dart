import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'app_state.dart';
import 'data.dart';

/// Arabic-Indic numerals, as in the mushaf: 78 -> "٧٨".
String toArabicIndic(int n) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    buf.write(c >= 48 && c <= 57 ? digits[c - 48] : s[i]);
  }
  return buf.toString();
}

/// One mushaf pagination: an ordered list of page-start indices
/// (zero-based global ayah positions) plus a name.
///
/// Both layouts share this one form, so every query runs down the same
/// code path:
/// - Madani (Uthmani, 604 pages) — from assets/quran/quran_meta.json,
///   which already stores zero-based global start indices.
/// - IndoPak 15-line / Qudratullah (610 pages) — from
///   assets/quran/quran_indopak_pages.json, whose [surah, ayah] ranges
///   are converted to global start indices when loaded.
class MushafLayout {
  const MushafLayout({required this.name, required this.pageStarts});

  /// 'madani' or 'indopak'.
  final String name;

  /// Zero-based global ayah index of each page's first ayah, in order.
  final List<int> pageStarts;

  int get totalPages => pageStarts.length;

  /// The ayah range of [page] (1-based, clamped) as zero-based global
  /// indices: [start] inclusive, [end] exclusive.
  ({int start, int end}) pageRange(int page) {
    final p = page.clamp(1, totalPages);
    final start = pageStarts[p - 1];
    final end = p < totalPages ? pageStarts[p] : MushafData.totalAyahs;
    return (start: start, end: end);
  }

  /// The 1-based page holding zero-based global ayah [global0].
  int pageOfGlobal(int global0) {
    final g = global0.clamp(0, MushafData.totalAyahs - 1);
    return MushafData.lastIndexLE(pageStarts, g) + 1;
  }
}

/// True mushaf pagination for the reader, in BOTH layouts the app
/// supports — Madani 604-page and IndoPak 15-line 610-page.
///
/// Juz and hizb boundaries are ayah-based, so they are shared: one
/// 30-entry juz list and one 60-entry hizb list (zero-based global ayah
/// indices, from quran_meta.json) serve both layouts; only the page
/// breaks differ.
///
/// Every query takes an optional [MushafLayout] and defaults to the
/// ACTIVE layout — the one matching the user's Mushaf style
/// ([AppState.mushafStyle]), falling back to Madani when the IndoPak
/// file is missing. Pass a layout explicitly to query the other one
/// (the style-switch test does this).
///
/// All indices into the meta arrays are ZERO-based global ayah positions
/// (0..6235); all page/juz/hizb numbers in the API are ONE-based, as a
/// reader counts them. [QuranRepository.globalIndexOf] is 1-based, so
/// the conversions here subtract/add 1 at the boundary — take care.
class MushafData {
  MushafData._();
  static final MushafData instance = MushafData._();

  static const int totalAyahs = 6236;
  static const int totalJuz = 30;
  static const int totalHizb = 60;
  static const int madaniPages = 604;
  static const int indopakPages = 610;

  MushafLayout? _madani;
  MushafLayout? _indopak;
  List<int>? _juzStarts;
  List<int>? _hizbStarts;

  /// True once the Madani layout (required) has loaded.
  bool get loaded => _madani != null;

  /// The Madani 604-page layout. Throws StateError until [load].
  MushafLayout get madani {
    _checkLoaded();
    return _madani!;
  }

  /// The IndoPak 610-page layout, or null when its file is missing or
  /// invalid (the reader then falls back to Madani).
  MushafLayout? get indopak => _indopak;

  /// True when the IndoPak layout loaded and verified.
  bool get indopakAvailable => _indopak != null;

  /// The 30 juz-start indices (0-based global ayah), for tests.
  List<int> get juzStarts => List.unmodifiable(_juzStarts ?? const []);

  /// The 60 hizb-start indices (0-based global ayah), for tests.
  List<int> get hizbStarts => List.unmodifiable(_hizbStarts ?? const []);

  /// The layout for a Mushaf style name ('madani' | 'indopak'):
  /// IndoPak only when its file actually loaded, Madani otherwise.
  MushafLayout layoutFor(String style) {
    _checkLoaded();
    if (style == 'indopak' && _indopak != null) return _indopak!;
    return _madani!;
  }

  /// The layout matching the user's current Mushaf style.
  MushafLayout get activeLayout => layoutFor(appState.mushafStyle);

  /// Page count of the active layout (604 Madani, 610 IndoPak).
  int get totalPages => activeLayout.totalPages;

  /// Loads both layouts: Madani from the meta asset (required — throws
  /// when the asset is not in the bundle) and IndoPak from its pages
  /// asset (optional — any failure leaves [_indopak] null so the
  /// reader falls back to Madani, mirroring [QuranRepository]'s
  /// handling of the IndoPak text).
  Future<void> load() async {
    if (loaded) return;
    final raw = await rootBundle.loadString('assets/quran/quran_meta.json');
    loadFromJsonString(raw);
    await _loadIndoPakFromBundle();
  }

  Future<void> _loadIndoPakFromBundle() async {
    try {
      final raw =
          await rootBundle.loadString('assets/quran/quran_indopak_pages.json');
      await loadIndoPakFromJsonString(raw);
    } catch (_) {
      _indopak = null;
    }
  }

  /// Parses Madani meta JSON (used by [load], and by tests when the
  /// asset is not in the bundle so it is read from the source file
  /// instead). Validates the counts; throws FormatException on
  /// anything that is not a 604-page / 30-juz / 60-hizb meta file.
  void loadFromJsonString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    List<int> ints(String key) => (json[key] as List<dynamic>)
        .map((e) => (e as num).toInt())
        .toList();
    final pages = ints('pages');
    final juz = ints('juz');
    final hizb = ints('hizb');
    final total = (json['total'] as num).toInt();
    if (pages.length != madaniPages ||
        juz.length != totalJuz ||
        hizb.length != totalHizb ||
        total != totalAyahs ||
        pages.first != 0 ||
        juz.first != 0 ||
        hizb.first != 0) {
      throw const FormatException(
          'quran_meta.json must hold 604 pages, 30 juz, 60 hizb, 6236 ayahs');
    }
    _madani = MushafLayout(name: 'madani', pageStarts: pages);
    _juzStarts = juz;
    _hizbStarts = hizb;
  }

  /// Parses the IndoPak pages file and converts its [surah, ayah]
  /// ranges to zero-based global page starts (needs the repository
  /// loaded for the conversion, so it awaits [QuranRepository.load]).
  /// Validates the file hard: 610 ranges, pages 1..610 in order,
  /// gapless coverage from 1:1 to 114:6 — any break throws
  /// FormatException and the layout stays unavailable.
  Future<void> loadIndoPakFromJsonString(String raw) async {
    final repo = QuranRepository.instance;
    await repo.load();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final totalPages = (json['totalPages'] as num?)?.toInt() ?? 0;
    final ranges = json['pageRanges'] as List<dynamic>? ?? const [];
    if (totalPages != indopakPages || ranges.length != indopakPages) {
      throw const FormatException(
          'quran_indopak_pages.json must hold 610 page ranges');
    }
    final starts = <int>[];
    var prevEndGlobal = -1; // 0-based global of the previous range's end
    for (var i = 0; i < ranges.length; i++) {
      final m = ranges[i] as Map<String, dynamic>;
      final page = (m['page'] as num).toInt();
      if (page != i + 1) {
        throw const FormatException(
            'quran_indopak_pages.json: pages must run 1..610 in order');
      }
      final from = m['from'] as List<dynamic>;
      final to = m['to'] as List<dynamic>;
      final startGlobal = repo.globalIndexOf(
              (from[0] as num).toInt(), (from[1] as num).toInt()) -
          1;
      final endGlobal = repo.globalIndexOf(
              (to[0] as num).toInt(), (to[1] as num).toInt()) -
          1;
      if (endGlobal < startGlobal || startGlobal != prevEndGlobal + 1) {
        throw FormatException(
            'quran_indopak_pages.json: page $page breaks gapless coverage');
      }
      starts.add(startGlobal);
      prevEndGlobal = endGlobal;
    }
    if (prevEndGlobal != totalAyahs - 1) {
      throw const FormatException(
          'quran_indopak_pages.json: last page must end at 114:6');
    }
    _indopak = MushafLayout(name: 'indopak', pageStarts: starts);
  }

  /// Index of the last entry in [sorted] that is <= [value]
  /// (binary search; [sorted] must be ascending and non-empty).
  static int lastIndexLE(List<int> sorted, int value) {
    var lo = 0;
    var hi = sorted.length - 1;
    var ans = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (sorted[mid] <= value) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  void _checkLoaded() {
    if (!loaded) {
      throw StateError(
          'MushafData not loaded — await MushafData.instance.load() first');
    }
  }

  MushafLayout _layout(MushafLayout? layout) => layout ?? activeLayout;

  /// The ayah range of [page] (1-based, clamped) as zero-based global
  /// indices: [start] inclusive, [end] exclusive.
  ({int start, int end}) pageRange(int page, [MushafLayout? layout]) =>
      _layout(layout).pageRange(page);

  /// The 1-based page holding zero-based global ayah [global0].
  int pageOfGlobal(int global0, [MushafLayout? layout]) =>
      _layout(layout).pageOfGlobal(global0);

  /// The 1-based page holding [surah]:[ayah].
  int pageOf(int surah, int ayah, [MushafLayout? layout]) {
    final global0 =
        QuranRepository.instance.globalIndexOf(surah, ayah) - 1;
    return pageOfGlobal(global0, layout);
  }

  /// The first page of [juz] (1-based, clamped to 1..30).
  int pageOfJuz(int juz, [MushafLayout? layout]) {
    _checkLoaded();
    final j = juz.clamp(1, totalJuz);
    return _layout(layout).pageOfGlobal(_juzStarts![j - 1]);
  }

  /// The juz (1..30) containing the first ayah of [page].
  int juzOfPage(int page, [MushafLayout? layout]) {
    _checkLoaded();
    final start = _layout(layout).pageRange(page).start;
    return lastIndexLE(_juzStarts!, start) + 1;
  }

  /// The hizb (1..60) containing the first ayah of [page].
  int hizbOfPage(int page, [MushafLayout? layout]) {
    _checkLoaded();
    final start = _layout(layout).pageRange(page).start;
    return lastIndexLE(_hizbStarts!, start) + 1;
  }

  /// The (surah, ayah) pairs on [page], in Quran order.
  /// Plain positional records: `$1` is the surah, `$2` the ayah.
  List<(int, int)> pageAyahs(int page, [MushafLayout? layout]) {
    final repo = QuranRepository.instance;
    final r = _layout(layout).pageRange(page);
    final out = <(int, int)>[];
    var sa = repo.surahAyahForGlobal(r.start + 1);
    var surah = sa[0];
    var ayah = sa[1];
    for (var g = r.start; g < r.end; g++) {
      out.add((surah, ayah));
      if (ayah < repo.surah(surah).ayahCount) {
        ayah++;
      } else {
        surah++;
        ayah = 1;
      }
    }
    return out;
  }

  /// The (surah, ayah) of the first ayah on [page].
  (int, int) firstAyahOfPage(int page, [MushafLayout? layout]) {
    final sa = QuranRepository.instance
        .surahAyahForGlobal(_layout(layout).pageRange(page).start + 1);
    return (sa[0], sa[1]);
  }
}
