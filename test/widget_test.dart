import 'package:flutter_test/flutter_test.dart';

import 'package:quba/data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bundled Quran data: 114 surahs, 6,236 verses, spot checks', () async {
    final repo = QuranRepository.instance;
    await repo.load();
    expect(repo.surahs.length, 114);
    final total = repo.surahs.fold<int>(0, (sum, s) => sum + s.ayahCount);
    expect(total, 6236);
    // Al-Fatiha 1:1 is the Bismillah itself. Compared by exact codepoints
    // (Uthmani spelling is codepoint-sensitive; literals can be normalized
    // differently by editors).
    final bismillah = String.fromCharCodes(const [
      0x628, 0x650, 0x633, 0x652, 0x645, 0x650, 0x20, 0x671, 0x644, 0x644,
      0x651, 0x64e, 0x647, 0x650, 0x20, 0x671, 0x644, 0x631, 0x651, 0x64e,
      0x62d, 0x652, 0x645, 0x64e, 0x670, 0x646, 0x650, 0x20, 0x671, 0x644,
      0x631, 0x651, 0x64e, 0x62d, 0x650, 0x64a, 0x645, 0x650
    ]);
    expect(repo.surah(1).ayahs[0].arabic, bismillah);
    // Ayat al-Kursi 2:255 — first 24 codepoints.
    final kursiPrefix = String.fromCharCodes(const [
      0x671, 0x644, 0x644, 0x651, 0x64e, 0x647, 0x64f, 0x20, 0x644, 0x64e,
      0x627, 0x653, 0x20, 0x625, 0x650, 0x644, 0x64e, 0x670, 0x647, 0x64e,
      0x20, 0x625, 0x650, 0x644
    ]);
    expect(repo.surah(2).ayahs[254].arabic.substring(0, 24), kursiPrefix);
    // Surah 112:1 after Bismillah normalization.
    final ikhlas1 = String.fromCharCodes(const [
      0x642, 0x64f, 0x644, 0x652, 0x20, 0x647, 0x64f, 0x648, 0x64e, 0x20,
      0x671, 0x644, 0x644, 0x651, 0x64e, 0x647, 0x64f, 0x20, 0x623, 0x64e,
      0x62d, 0x64e, 0x62f, 0x64c
    ]);
    expect(repo.surah(112).ayahs[0].arabic, ikhlas1);
    // Pickthall alignment spot check.
    expect(repo.surah(1).ayahs[0].english,
        'In the name of Allah, the Beneficent, the Merciful.');
  });
}
