import 'package:flutter_test/flutter_test.dart';

import 'package:quba/content.dart';
import 'package:quba/data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('duaArabic resolves a quranRef ayah range (20:25-28)', () async {
    final repo = QuranRepository.instance;
    await repo.load();

    final dua = duas.firstWhere((d) => d.quranRef == '20:25-28');
    final text = duaArabic(dua);
    // All four verses, joined: verse 25 starts "Rabbi ishrah" and
    // verse 28 ends "yafqahu qawli".
    expect(text, contains(repo.arabicText(20, 25)));
    expect(text, contains(repo.arabicText(20, 26)));
    expect(text, contains(repo.arabicText(20, 27)));
    expect(text, contains(repo.arabicText(20, 28)));
    expect(text, isNotEmpty);
  });

  test('duaArabic still resolves single-ayah and whole-surah refs', () async {
    final repo = QuranRepository.instance;
    await repo.load();

    final single = duas.firstWhere((d) => d.quranRef == '2:255');
    expect(duaArabic(single), repo.arabicText(2, 255));

    final surahs = duas.firstWhere((d) => d.quranRef == '112,113,114');
    final surahText = duaArabic(surahs);
    expect(surahText, contains(repo.arabicText(112, 1)));
    expect(surahText, contains(repo.arabicText(113, 1)));
    expect(surahText, contains(repo.arabicText(114, 1)));
  });

  test('every Quran-sourced dua resolves to non-empty Arabic', () async {
    final repo = QuranRepository.instance;
    await repo.load();

    for (final d in duas.where((d) => d.quranRef != null)) {
      expect(
        duaArabic(d).trim(),
        isNotEmpty,
        reason: 'dua "${d.title}" ref ${d.quranRef}',
      );
    }
  });

  test('dua library counts: 58 duas, 19 categories + All', () {
    expect(duas.length, 58);
    expect(duaCategories.length, 20);
    expect(duaCategories.first, 'All');
    // Every dua's category is listed.
    for (final d in duas) {
      expect(duaCategories, contains(d.category), reason: 'dua "${d.title}"');
    }
    // No duplicate titles.
    final titles = duas.map((d) => d.title).toList();
    expect(titles.toSet().length, titles.length);
  });
}
