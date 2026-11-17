import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';
import 'data.dart';

/// Audio: Mishary Alafasy via the Islamic Network CDN (EveryAyah mirror).
///
/// Two modes share one player:
/// - Per-ayah streaming: one mp3 per verse
///   (audio/128/ar.alafasy/{global ayah number}.mp3), auto-advancing to
///   the next verse of the surah. [currentAyah] is set while it plays.
/// - Whole-surah file: audio-surah/128/ar.alafasy/{surah}.mp3, streamed
///   when online, or played from the app documents folder when the surah
///   was downloaded once. [currentAyah] is null in this mode.
///
/// Streams need the internet; a downloaded surah plays fully offline.
class AudioService {
  AudioService._() {
    // Auto-advance: when a verse finishes, play the next verse of the
    // same surah; at the last verse (or when a whole-surah file ends)
    // clear the now-playing state so the mini-player disappears.
    player.playerStateStream.listen((state) {
      if (state.processingState != ProcessingState.completed) return;
      final surah = currentSurah.value;
      final ayah = currentAyah.value;
      if (surah != null && ayah != null) {
        final count = QuranRepository.instance.surah(surah).ayahCount;
        if (ayah < count) {
          playAyah(surah, ayah + 1);
          return;
        }
      }
      stop();
    });
  }
  static final AudioService instance = AudioService._();

  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<int?> currentSurah = ValueNotifier(null);

  /// The verse currently playing in per-ayah mode, or null when a
  /// whole-surah file is playing (or nothing is playing).
  final ValueNotifier<int?> currentAyah = ValueNotifier(null);
  final ValueNotifier<int?> downloadingSurah = ValueNotifier(null);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0);

  static String streamUrl(int surah) =>
      'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surah.mp3';

  static String ayahUrl(int globalAyahIndex) =>
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyahIndex.mp3';

  Future<File> _localFile(int surah) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);
    return File('${audioDir.path}/surah_$surah.mp3');
  }

  Future<bool> isDownloaded(int surah) async {
    final f = await _localFile(surah);
    return f.exists();
  }

  Future<void> playSurah(int surah) async {
    try {
      currentSurah.value = surah;
      currentAyah.value = null;
      final f = await _localFile(surah);
      if (await f.exists()) {
        await player.setFilePath(f.path);
      } else {
        await player.setUrl(streamUrl(surah));
      }
      await player.play();
    } catch (e) {
      debugPrint('QUBA audio error: $e');
      currentSurah.value = null;
      currentAyah.value = null;
    }
  }

  /// Plays one verse (streamed) and auto-advances through the surah.
  Future<void> playAyah(int surah, int ayah) async {
    try {
      currentSurah.value = surah;
      currentAyah.value = ayah;
      final global = QuranRepository.instance.globalIndexOf(surah, ayah);
      await player.setUrl(ayahUrl(global));
      await player.play();
    } catch (e) {
      debugPrint('QUBA audio error: $e');
      currentSurah.value = null;
      currentAyah.value = null;
    }
  }

  /// Next verse in per-ayah mode; does nothing at the surah's last verse.
  Future<void> playNextAyah() async {
    final surah = currentSurah.value;
    final ayah = currentAyah.value;
    if (surah == null || ayah == null) return;
    final count = QuranRepository.instance.surah(surah).ayahCount;
    if (ayah < count) await playAyah(surah, ayah + 1);
  }

  /// Previous verse in per-ayah mode; does nothing at the first verse.
  Future<void> playPrevAyah() async {
    final surah = currentSurah.value;
    final ayah = currentAyah.value;
    if (surah == null || ayah == null) return;
    if (ayah > 1) await playAyah(surah, ayah - 1);
  }

  /// Pause if playing, resume if paused. No-op when nothing is loaded.
  Future<void> togglePause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> toggle(int surah) async {
    if (currentSurah.value == surah) {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } else {
      await playSurah(surah);
    }
  }

  Future<void> stop() async {
    await player.stop();
    currentSurah.value = null;
    currentAyah.value = null;
  }

  Future<bool> downloadSurah(int surah) async {
    if (downloadingSurah.value != null) return false;
    downloadingSurah.value = surah;
    downloadProgress.value = 0;
    try {
      final req = http.Request('GET', Uri.parse(streamUrl(surah)));
      final res = await http.Client().send(req);
      if (res.statusCode != 200) return false;
      final total = res.contentLength ?? 0;
      final f = await _localFile(surah);
      final sink = f.openWrite();
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) downloadProgress.value = received / total;
      }
      await sink.close();
      appState.markDownloaded(surah);
      return true;
    } catch (e) {
      debugPrint('QUBA download error: $e');
      return false;
    } finally {
      downloadingSurah.value = null;
      downloadProgress.value = 0;
    }
  }

  Future<void> deleteDownload(int surah) async {
    final f = await _localFile(surah);
    if (await f.exists()) await f.delete();
    appState.unmarkDownloaded(surah);
  }
}
