import 'i18n.dart';

/// One reciter whose verse-by-verse audio ships in QUBA.
///
/// All four are served by the Islamic Network CDN (EveryAyah mirror) at
/// `https://cdn.islamic.network/quran/audio/{bitrate}/{id}/{global}.mp3`.
/// Each edition was verified by hand (HEAD requests on ayahs 1, 8, 262,
/// 293, 3000 and 6236 — all 200) before shipping in round 3.
///
/// Bitrates differ per edition: Alafasy and Maher Al Muaiqly serve
/// 128kbps; Abdul Basit and Saud Al-Shuraim serve 64kbps only (128kbps
/// returns 403 — the API's own audio URL for those editions points at
/// the /64/ path). The whole-surah files (audio-surah/...) exist only
/// for Alafasy, so the other three download verse-by-verse.
///
/// Notes on the two substituted picks: Saad Al-Ghamdi is NOT on this
/// CDN at all (nor are Minshawi or Juhani), so Saud Al-Shuraim takes
/// his place. And the CDN's Abdul Basit edition is his Murattal
/// recording, not Mujawwad: its Basmala file is ~6.5s long, matching
/// Husary Murattal pace (~5s) rather than Husary Mujawwad (~10.5s).
/// The UI therefore makes no style claim — just the reciter's name.
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

/// The four shipped reciters, in picker order.
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
];

/// The reciter for a stored edition id; unknown ids fall back to Alafasy.
Reciter reciterById(String id) =>
    reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
