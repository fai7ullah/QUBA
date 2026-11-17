import 'package:flutter_test/flutter_test.dart';

import 'package:quba/data.dart';
import 'package:quba/juz_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Juz data: 30 juz, contiguous, covering all 6,236 verses', () async {
    final repo = QuranRepository.instance;
    await repo.load();

    expect(juzList.length, 30);
    for (var i = 0; i < 30; i++) {
      expect(juzList[i].number, i + 1);
    }
    // First juz starts at 1:1, last ends at 114:6.
    expect(juzList.first.startSurah, 1);
    expect(juzList.first.startAyah, 1);
    expect(juzList.last.endSurah, 114);
    expect(juzList.last.endAyah, 6);
    // Contiguous: each juz starts exactly one verse after the previous ends.
    for (var i = 1; i < 30; i++) {
      final prevEnd = repo.globalIndexOf(
          juzList[i - 1].endSurah, juzList[i - 1].endAyah);
      final start =
          repo.globalIndexOf(juzList[i].startSurah, juzList[i].startAyah);
      expect(start, prevEnd + 1, reason: 'juz ${i + 1} must follow juz $i');
    }
    // Total coverage is the whole Quran.
    final first =
        repo.globalIndexOf(juzList.first.startSurah, juzList.first.startAyah);
    final last = repo.globalIndexOf(
        juzList.last.endSurah, juzList.last.endAyah);
    expect(last - first + 1, 6236);
  });

  test('Juz ranges match the verified standard boundaries', () {
    // The reference app's screenshots agree for juz 1, 2 and 5; its
    // juz 3/4 split (3:91 / 3:92) is off by one — the standard split
    // (and the meta file) is 3:92 / 3:93, and that is what we ship.
    void check(int n, int ss, int sa, int es, int ea) {
      final j = juzList[n - 1];
      expect(j.startSurah, ss, reason: 'juz $n start surah');
      expect(j.startAyah, sa, reason: 'juz $n start ayah');
      expect(j.endSurah, es, reason: 'juz $n end surah');
      expect(j.endAyah, ea, reason: 'juz $n end ayah');
    }

    check(1, 1, 1, 2, 141);
    check(2, 2, 142, 2, 252);
    check(3, 2, 253, 3, 92);
    check(4, 3, 93, 4, 23);
    check(5, 4, 24, 4, 147);
    check(22, 33, 31, 36, 27);
    check(30, 78, 1, 114, 6);
  });

  test('juzOf lookups at the boundaries', () {
    expect(juzOf(1, 1), 1);
    expect(juzOf(2, 141), 1);
    expect(juzOf(2, 142), 2);
    expect(juzOf(3, 92), 3);
    expect(juzOf(3, 93), 4);
    expect(juzOf(4, 23), 4);
    expect(juzOf(4, 24), 5);
    expect(juzOf(33, 31), 22);
    expect(juzOf(36, 27), 22);
    expect(juzOf(36, 28), 23);
    expect(juzOf(114, 6), 30);
  });
}
