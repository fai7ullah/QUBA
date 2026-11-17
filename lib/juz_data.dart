/// The 30 juz (parts) of the Quran: traditional name + first/last ayah.
///
/// Boundaries are the standard ones, verified against the native app's
/// quran_meta.json (juz starts, 0-based global ayah index) AND the
/// well-known juz-start list — all 30 starts match both sources exactly.
/// Every juz's end is the ayah before the next juz's start; juz 30 ends
/// at 114:6. Together the 30 juz cover all 6,236 verses exactly once.
///
/// NOTE — the reference app's screenshots show juz 3 ending at 3:91 and
/// juz 4 starting at 3:92. That is off by one ayah: the standard split
/// (and the meta file) is juz 3 = 2:253–3:92, juz 4 = 3:93–4:23.
/// 3:92 IS "Lan Tanaaloo" (لَن تَنَالُوا) — the verse juz 4 is named
/// after — so the reference app's ranges are wrong and are NOT copied here.
///
/// Juz names follow the traditional South Asian para names, using the
/// reference screenshots' spellings where shown (juz 1–5). Juz 22 is
/// "Wa Man Yaqnut" from its first ayah 33:31 (وَمَن يَقْنُتْ), verified
/// against the bundled Arabic text.
class JuzInfo {
  const JuzInfo({
    required this.number,
    required this.name,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
  });
  final int number;
  final String name;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
}

/// All 30 juz in order.
const List<JuzInfo> juzList = [
  JuzInfo(
      number: 1,
      name: 'Alaf Lam Meem',
      startSurah: 1,
      startAyah: 1,
      endSurah: 2,
      endAyah: 141),
  JuzInfo(
      number: 2,
      name: 'Sayaqool',
      startSurah: 2,
      startAyah: 142,
      endSurah: 2,
      endAyah: 252),
  JuzInfo(
      number: 3,
      name: 'Tilkal Rusull',
      startSurah: 2,
      startAyah: 253,
      endSurah: 3,
      endAyah: 92),
  JuzInfo(
      number: 4,
      name: 'Lan Tana Loo',
      startSurah: 3,
      startAyah: 93,
      endSurah: 4,
      endAyah: 23),
  JuzInfo(
      number: 5,
      name: 'Wal Mohsanat',
      startSurah: 4,
      startAyah: 24,
      endSurah: 4,
      endAyah: 147),
  JuzInfo(
      number: 6,
      name: 'La Yuhibbullah',
      startSurah: 4,
      startAyah: 148,
      endSurah: 5,
      endAyah: 81),
  JuzInfo(
      number: 7,
      name: 'Wa Iza Samiu',
      startSurah: 5,
      startAyah: 82,
      endSurah: 6,
      endAyah: 110),
  JuzInfo(
      number: 8,
      name: 'Wa Lau Annana',
      startSurah: 6,
      startAyah: 111,
      endSurah: 7,
      endAyah: 87),
  JuzInfo(
      number: 9,
      name: 'Qalal Mala',
      startSurah: 7,
      startAyah: 88,
      endSurah: 8,
      endAyah: 40),
  JuzInfo(
      number: 10,
      name: "Wa'lamu",
      startSurah: 8,
      startAyah: 41,
      endSurah: 9,
      endAyah: 92),
  JuzInfo(
      number: 11,
      name: "Ya'taziroon",
      startSurah: 9,
      startAyah: 93,
      endSurah: 11,
      endAyah: 5),
  JuzInfo(
      number: 12,
      name: 'Wa Mamin Daabbah',
      startSurah: 11,
      startAyah: 6,
      endSurah: 12,
      endAyah: 52),
  JuzInfo(
      number: 13,
      name: 'Wa Ma Ubarri',
      startSurah: 12,
      startAyah: 53,
      endSurah: 14,
      endAyah: 52),
  JuzInfo(
      number: 14,
      name: 'Rubama',
      startSurah: 15,
      startAyah: 1,
      endSurah: 16,
      endAyah: 128),
  JuzInfo(
      number: 15,
      name: 'Subhanallazi',
      startSurah: 17,
      startAyah: 1,
      endSurah: 18,
      endAyah: 74),
  JuzInfo(
      number: 16,
      name: 'Qal Alam',
      startSurah: 18,
      startAyah: 75,
      endSurah: 20,
      endAyah: 135),
  JuzInfo(
      number: 17,
      name: 'Iqtaraba',
      startSurah: 21,
      startAyah: 1,
      endSurah: 22,
      endAyah: 78),
  JuzInfo(
      number: 18,
      name: 'Qad Aflaha',
      startSurah: 23,
      startAyah: 1,
      endSurah: 25,
      endAyah: 20),
  JuzInfo(
      number: 19,
      name: 'Wa Qalallazina',
      startSurah: 25,
      startAyah: 21,
      endSurah: 27,
      endAyah: 55),
  JuzInfo(
      number: 20,
      name: 'Amman Khalaq',
      startSurah: 27,
      startAyah: 56,
      endSurah: 29,
      endAyah: 45),
  JuzInfo(
      number: 21,
      name: 'Utlu Ma Uhiya',
      startSurah: 29,
      startAyah: 46,
      endSurah: 33,
      endAyah: 30),
  JuzInfo(
      number: 22,
      name: 'Wa Man Yaqnut',
      startSurah: 33,
      startAyah: 31,
      endSurah: 36,
      endAyah: 27),
  JuzInfo(
      number: 23,
      name: 'Wa Maliya',
      startSurah: 36,
      startAyah: 28,
      endSurah: 39,
      endAyah: 31),
  JuzInfo(
      number: 24,
      name: 'Faman Azlam',
      startSurah: 39,
      startAyah: 32,
      endSurah: 41,
      endAyah: 46),
  JuzInfo(
      number: 25,
      name: 'Ilaihi Yuraddu',
      startSurah: 41,
      startAyah: 47,
      endSurah: 45,
      endAyah: 37),
  JuzInfo(
      number: 26,
      name: 'Ha Mim',
      startSurah: 46,
      startAyah: 1,
      endSurah: 51,
      endAyah: 30),
  JuzInfo(
      number: 27,
      name: 'Qal Fama Khadbakum',
      startSurah: 51,
      startAyah: 31,
      endSurah: 57,
      endAyah: 29),
  JuzInfo(
      number: 28,
      name: "Qad Sami'allah",
      startSurah: 58,
      startAyah: 1,
      endSurah: 66,
      endAyah: 12),
  JuzInfo(
      number: 29,
      name: 'Tabarakallazi',
      startSurah: 67,
      startAyah: 1,
      endSurah: 77,
      endAyah: 50),
  JuzInfo(
      number: 30,
      name: 'Amma',
      startSurah: 78,
      startAyah: 1,
      endSurah: 114,
      endAyah: 6),
];

/// The juz number (1–30) containing [surah]:[ayah].
int juzOf(int surah, int ayah) {
  for (final j in juzList) {
    final afterStart = surah > j.startSurah ||
        (surah == j.startSurah && ayah >= j.startAyah);
    final beforeEnd =
        surah < j.endSurah || (surah == j.endSurah && ayah <= j.endAyah);
    if (afterStart && beforeEnd) return j.number;
  }
  return 30;
}
