import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';

/// Per-surah audio: Mishary Alafasy via the Islamic Network CDN
/// (EveryAyah mirror). Streams when online; a surah can be downloaded
/// once and then plays fully offline from the app documents folder.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<int?> currentSurah = ValueNotifier(null);
  final ValueNotifier<int?> downloadingSurah = ValueNotifier(null);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0);

  static String streamUrl(int surah) =>
      'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$surah.mp3';

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
