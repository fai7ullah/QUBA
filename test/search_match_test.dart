import 'package:flutter_test/flutter_test.dart';

import 'package:quba/data.dart';
import 'package:quba/juz_data.dart';
import 'package:quba/search_match.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await QuranRepository.instance.load();
  });

  group('surah search', () {
    // Read inside each test: the repository loads in setUpAll, after
    // this group body has already run.
    List<Surah> surahs() => QuranRepository.instance.surahs;

    test('Yaseen variants all find Surah 36 first', () {
      for (final q in ['Yaseen', 'Yasin', 'Ya-Sin', 'ya sin', 'YASEEN']) {
        final hits = matchSurahs(q, surahs());
        expect(hits, isNotEmpty, reason: q);
        expect(hits.first.number, 36, reason: q);
      }
    });

    test('number and "surah N" queries find the surah', () {
      expect(matchSurahs('36', surahs()).first.number, 36);
      expect(matchSurahs('surah 36', surahs()).first.number, 36);
      expect(matchSurahs('2', surahs()).first.number, 2);
    });

    test('Arabic name finds the surah (with or without tashkeel)', () {
      expect(matchSurahs('يس', surahs()).first.number, 36);
      expect(matchSurahs('ياسين', surahs()).first.number, 36);
      expect(matchSurahs('الفاتحة', surahs()).first.number, 1);
    });

    test('common spellings and article-less names match', () {
      expect(matchSurahs('baqarah', surahs()).first.number, 2);
      expect(matchSurahs('kahf', surahs()).first.number, 18);
      expect(matchSurahs('rahman', surahs()).first.number, 55);
      expect(matchSurahs('ikhlas', surahs()).first.number, 112);
      expect(matchSurahs('fatiha', surahs()).first.number, 1);
    });

    test('empty query matches nothing', () {
      expect(matchSurahs('   ', surahs()), isEmpty);
    });
  });

  group('juz search', () {
    test('number forms find the juz', () {
      expect(matchJuz('5', juzList).first.number, 5);
      expect(matchJuz('juz 5', juzList).first.number, 5);
      expect(matchJuz('para 5', juzList).first.number, 5);
      expect(matchJuz('juz 30', juzList).first.number, 30);
    });

    test('juz names match', () {
      expect(matchJuz('amma', juzList).first.number, 30);
      expect(matchJuz('alaf lam meem', juzList).first.number, 1);
    });

    test('a surah-word query does not match juz numbers', () {
      expect(matchJuz('surah 5', juzList), isEmpty);
    });
  });
}
