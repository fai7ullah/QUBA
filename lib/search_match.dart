import 'data.dart';
import 'i18n.dart';
import 'juz_data.dart';

/// Forgiving surah/juz matching for Quran search: case, hyphens,
/// apostrophes and spaces are ignored, common transliteration
/// spellings fold together (Yaseen / Yasin / Ya-Sin), Arabic names
/// match without tashkeel, and numbers match surah/juz numbers.

String _asciiDigits(String s) {
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final e = eastern.indexOf(ch);
    final p = persian.indexOf(ch);
    if (e >= 0) {
      b.write(e);
    } else if (p >= 0) {
      b.write(p);
    } else {
      b.write(ch);
    }
  }
  return b.toString();
}

/// Compact folded Latin form: letters/digits only, long-vowel
/// spellings folded (aa→a, ee→i, oo/ou→u), trailing -h dropped.
String foldLatin(String s) {
  var t = _asciiDigits(s.toLowerCase());
  t = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  t = t
      .replaceAll('aa', 'a')
      .replaceAll('ee', 'i')
      .replaceAll('oo', 'u')
      .replaceAll('ou', 'u')
      .replaceAll('ph', 'f');
  if (t.length > 3 && t.endsWith('h')) t = t.substring(0, t.length - 1);
  return t;
}

const _articles = [
  'adh',
  'ash',
  'ath',
  'al',
  'ar',
  'an',
  'as',
  'at',
  'az',
  'ad',
];

/// Folded variants of a name: the full form plus the form without
/// its Arabic article (al-/ar-/ash-…), when that leaves a real word.
Set<String> _latinVariants(String s) {
  final f = foldLatin(s);
  final out = {f};
  for (final a in _articles) {
    if (f.startsWith(a) && f.length - a.length >= 3) {
      out.add(f.substring(a.length));
    }
  }
  return out;
}

/// 0 exact, 1 prefix, 2 contains, null no match.
int? _latinScore(String query, Iterable<String> candidates) {
  final q = foldLatin(query);
  if (q.isEmpty) return null;
  int? best;
  for (final c in candidates) {
    for (final v in _latinVariants(c)) {
      int? score;
      if (v == q) {
        score = 0;
      } else if (v.startsWith(q)) {
        score = 1;
      } else if (v.contains(q) || q.contains(v)) {
        score = 2;
      }
      if (score != null && (best == null || score < best)) best = score;
    }
  }
  return best;
}

String _arabicCompact(String s) =>
    QuranRepository.normalizeArabic(s).replaceAll(RegExp(r'\s+'), '');

/// 0 exact, 1 prefix, 2 contains, null no match (Arabic script).
int? _arabicScore(String query, Iterable<String> candidates) {
  final q = _arabicCompact(query);
  if (q.isEmpty) return null;
  int? best;
  for (final c in candidates) {
    var v = _arabicCompact(c);
    // Surah names are bundled with the سورة prefix.
    if (v.startsWith('سوره')) v = v.substring(4);
    int? score;
    if (v == q) {
      score = 0;
    } else if (v.startsWith(q)) {
      score = 1;
    } else if (v.contains(q) || q.contains(v)) {
      score = 2;
    }
    if (score != null && (best == null || score < best)) best = score;
  }
  return best;
}

/// Common alternate spellings keyed by surah number (folded forms).
const _surahAliases = <int, List<String>>{
  1: ['fatiha', 'opening'],
  2: ['baqara', 'cow'],
  3: ['imran', 'aleimran'],
  17: ['isra', 'baniisrail'],
  18: ['kahf', 'cave'],
  19: ['mariam'],
  36: ['yasin', 'yasine'],
  55: ['rahman'],
  56: ['waqia'],
  67: ['mulk', 'tabarak'],
  78: ['naba', 'amma'],
  97: ['qadr'],
  108: ['kauthar'],
  112: ['ikhlas'],
};

/// Arabic alternate spellings keyed by surah number.
const _surahArabicAliases = <int, List<String>>{
  36: ['ياسين'],
};

/// The number in a query like "36", "surah 36" or "juz 5", plus
/// whether a surah/juz word was present. Null when not numeric.
({int number, bool surahWord, bool juzWord})? _numberQuery(String query) {
  final t = _asciiDigits(query.toLowerCase()).trim();
  final surahWord =
      t.contains('surah') ||
      t.contains('sura') ||
      t.contains('chapter') ||
      query.contains('سورة') ||
      query.contains('سوره');
  final juzWord =
      t.contains('juz') ||
      t.contains('para') ||
      t.contains('part') ||
      query.contains('جزء') ||
      query.contains('پاره') ||
      query.contains('پارہ');
  final digits = RegExp(r'\d+').firstMatch(t)?.group(0);
  if (digits == null) return null;
  // A verse reference like 2:255 is not a surah/juz number query.
  if (t.contains(':')) return null;
  final rest = t
      .replaceAll(digits, '')
      .replaceAll(RegExp(r'(surah|sura|chapter|juz|para|part)'), '')
      .trim();
  if (rest.isNotEmpty && !surahWord && !juzWord) return null;
  return (number: int.parse(digits), surahWord: surahWord, juzWord: juzWord);
}

/// Surahs matching [query], best matches first (at most [limit]).
List<Surah> matchSurahs(String query, List<Surah> surahs, {int limit = 12}) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final num = _numberQuery(q);
  final scored = <(int, int, Surah)>[]; // (score, number, surah)
  for (final s in surahs) {
    int? score;
    if (num != null && !num.juzWord && num.number == s.number) {
      score = 0;
    }
    score ??= _latinScore(q, [
      s.nameEnglish,
      s.meaning,
      ...?_surahAliases[s.number],
    ]);
    score ??= _arabicScore(q, [
      s.nameArabic,
      ...?_surahArabicAliases[s.number],
    ]);
    if (score != null) scored.add((score, s.number, s));
  }
  scored.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });
  return [for (final e in scored.take(limit)) e.$3];
}

/// Juz matching [query], best matches first (at most [limit]).
List<JuzInfo> matchJuz(String query, List<JuzInfo> juz, {int limit = 12}) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final num = _numberQuery(q);
  final scored = <(int, int, JuzInfo)>[];
  for (final j in juz) {
    int? score;
    if (num != null && !num.surahWord && num.number == j.number) {
      score = 0;
    }
    score ??= _latinScore(q, [
      j.name,
      QubaStrings.get('en', 'juz_name_${j.number}'),
    ]);
    score ??= _arabicScore(q, [
      for (final lang in QubaStrings.langs)
        QubaStrings.get(lang, 'juz_name_${j.number}'),
    ]);
    if (score != null) scored.add((score, j.number, j));
  }
  scored.sort((a, b) {
    final byScore = a.$1.compareTo(b.$1);
    return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
  });
  return [for (final e in scored.take(limit)) e.$3];
}
