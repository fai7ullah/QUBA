import 'i18n.dart';

/// One reciter whose verse-by-verse audio ships in QUBA.
///
/// All are served by the Islamic Network CDN (EveryAyah mirror) at
/// `https://cdn.islamic.network/quran/audio/{bitrate}/{id}/{global}.mp3`.
/// Each edition was verified by hand (HEAD requests on ayahs 1, 8, 262,
/// 293, 3000 and 6236 — all 200) before shipping: the first four in
/// round 3, the other thirteen in phase 2 (2026-11-21, 170 editions
/// probed — see build-outputs/DATA-REPORT.md).
///
/// Bitrates differ per edition: most serve 128kbps; Abdul Basit,
/// Saud Al-Shuraim, Hani Rifai, Ayman Sowaid, Abdullah Basfar,
/// Abdurrahmaan As-Sudais and Minshawi Mujawwad serve 64kbps only
/// (128kbps returns 403 — the API's own audio URL for those editions
/// points at the /64/ path). The whole-surah files (audio-surah/...)
/// exist only for Alafasy, so the others download verse-by-verse.
///
/// Notes on the substituted/unavailable picks: Saad Al-Ghamdi is NOT
/// on this CDN at all (nor are Aziz Alili, Abdullah Awad al-Juhani or
/// Ibrahim Walk — the last is English translation audio, not a Quran
/// reciter), so Saud Al-Shuraim takes Al-Ghamdi's place. Minshawi WAS
/// absent in round 3 but the CDN catalogue has grown since — he ships
/// in phase 2, Murattal and Mujawwad. And the CDN's Abdul Basit
/// edition is his Murattal recording, not Mujawwad: its Basmala file
/// is ~6.5s long, matching Husary Murattal pace (~5s) rather than
/// Husary Mujawwad (~10.5s). The UI therefore makes no style claim
/// for him — just the reciter's name. (The separate
/// ar.abdulbasitmurattal edition is the same reciter/style, so it is
/// not listed twice.) The `-2` editions are second recordings of the
/// same reciters and are not listed either — they sound near-identical
/// to the first recordings.
class Reciter {
  const Reciter({
    required this.id,
    required this.nameKey,
    required this.shortNameKey,
    required this.bitrate,
    required this.hasWholeSurahFiles,
  });

  /// AlQuran Cloud audio edition id, e.g. 'ar.alafasy'.
  final String id;

  /// i18n key for the display name (e.g. 'reciter_name_alafasy').
  final String nameKey;

  /// i18n key for the short name (surname, e.g. 'reciter_short_alafasy')
  /// used where the full name cannot fit — the mini-player.
  final String shortNameKey;

  /// The bitrate the CDN serves for this edition (128 or 64).
  final int bitrate;

  /// True only for Alafasy: the only edition with whole-surah files.
  final bool hasWholeSurahFiles;

  String get name => tr(nameKey);

  /// Short display name (surname) for tight spaces like the mini-player.
  String get shortName => tr(shortNameKey);

  String ayahUrl(int globalAyahIndex) =>
      'https://cdn.islamic.network/quran/audio/$bitrate/$id/$globalAyahIndex.mp3';

  String surahUrl(int surah) =>
      'https://cdn.islamic.network/quran/audio-surah/$bitrate/$id/$surah.mp3';
}

/// The shipped reciters, in picker order: the round-3 four first
/// (Alafasy is the default), then the thirteen added in phase 2.
const List<Reciter> reciters = [
  Reciter(
    id: 'ar.alafasy',
    nameKey: 'reciter_name_alafasy',
    shortNameKey: 'reciter_short_alafasy',
    bitrate: 128,
    hasWholeSurahFiles: true,
  ),
  Reciter(
    id: 'ar.abdulsamad',
    nameKey: 'reciter_name_abdulbasit',
    shortNameKey: 'reciter_short_abdulbasit',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.mahermuaiqly',
    nameKey: 'reciter_name_mahermuaiqly',
    shortNameKey: 'reciter_short_mahermuaiqly',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.saoodshuraym',
    nameKey: 'reciter_name_shuraym',
    shortNameKey: 'reciter_short_shuraym',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
  // --- Phase 2: thirteen more verified reciters ---
  Reciter(
    id: 'ar.husary',
    nameKey: 'reciter_name_husary',
    shortNameKey: 'reciter_short_husary',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.husarymujawwad',
    nameKey: 'reciter_name_husarymujawwad',
    shortNameKey: 'reciter_short_husarymujawwad',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.minshawi',
    nameKey: 'reciter_name_minshawi',
    shortNameKey: 'reciter_short_minshawi',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.minshawimujawwad',
    nameKey: 'reciter_name_minshawimujawwad',
    shortNameKey: 'reciter_short_minshawimujawwad',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.hudhaify',
    nameKey: 'reciter_name_hudhaify',
    shortNameKey: 'reciter_short_hudhaify',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.abdurrahmaansudais',
    nameKey: 'reciter_name_sudais',
    shortNameKey: 'reciter_short_sudais',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.shaatree',
    nameKey: 'reciter_name_shaatree',
    shortNameKey: 'reciter_short_shaatree',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.muhammadjibreel',
    nameKey: 'reciter_name_jibreel',
    shortNameKey: 'reciter_short_jibreel',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.muhammadayyoub',
    nameKey: 'reciter_name_ayyoub',
    shortNameKey: 'reciter_short_ayyoub',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.hanirifai',
    nameKey: 'reciter_name_rifai',
    shortNameKey: 'reciter_short_rifai',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.ahmedajamy',
    nameKey: 'reciter_name_ajamy',
    shortNameKey: 'reciter_short_ajamy',
    bitrate: 128,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.aymanswoaid',
    nameKey: 'reciter_name_sowaid',
    shortNameKey: 'reciter_short_sowaid',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
  Reciter(
    id: 'ar.abdullahbasfar',
    nameKey: 'reciter_name_basfar',
    shortNameKey: 'reciter_short_basfar',
    bitrate: 64,
    hasWholeSurahFiles: false,
  ),
];

/// The reciter for a stored edition id; unknown ids fall back to Alafasy.
Reciter reciterById(String id) =>
    reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
