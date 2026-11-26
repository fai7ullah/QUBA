import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';
import 'data.dart';
import 'reciters.dart';

/// How one verse repeats (memorisation tool).
enum VerseRepeatMode {
  /// No repeat: play each verse once, auto-advance.
  off,

  /// Play the current verse once in total (same as off, kept for the UI).
  once,

  /// Play the current verse 3 times in total, then advance.
  three,

  /// Play the current verse 5 times in total, then advance.
  five,

  /// Repeat the current verse forever until stopped.
  loop,
}

/// Audio: eighteen reciters via the Islamic Network CDN (EveryAyah
/// mirror), plus the bundled 99 Names pronunciation clips.
/// See [Reciter] for the per-edition bitrates and which editions have
/// whole-surah files.
///
/// Quran modes share one player:
/// - Per-ayah: one mp3 per verse
///   (audio/{bitrate}/{edition}/{global ayah number}.mp3), auto-advancing
///   through the surah. [currentAyah] is set while it plays. Every
///   reciter except Yasser Al-Dosari supports this; for reciters
///   without whole-surah files this is also how "play surah" and
///   downloads work (verse by verse).
/// - Whole-surah file (Alafasy and Yasser Al-Dosari):
///   audio-surah/{bitrate}/{edition}/{surah}.mp3, streamed when online,
///   or played from the app documents folder when downloaded once.
///   [currentAyah] is null in this mode. Al-Dosari has no per-ayah
///   files, so a verse tap with him starts the whole surah.
///
/// Name mode: one bundled human pronunciation clip per name
/// (assets/names/name_NN.ogg — see assets/names/LICENSE.txt for the
/// source and CC BY-SA licences). [currentName] is set while it plays;
/// the clip is a few seconds, then the session ends and the player
/// hides. Name and Quran sessions replace each other.
///
/// Streams need the internet; a downloaded surah plays fully offline.
///
/// Plain in-app playback (just_audio), exactly as before round 3.
/// Lock-screen / notification controls were tried in round 3 via
/// just_audio_background but REMOVED at the owner's word on 2026-11-17:
/// its init call hangs on his OPPO (build-9 froze on the splash, and
/// build-10's timeout left the player routed into a dead service so no
/// verse played at all). Do NOT re-add just_audio_background without
/// his explicit word.
class AudioService {
  AudioService._() {
    sessionListenable = Listenable.merge([
      currentSurah,
      currentAyah,
      currentName,
      currentReciter,
    ]);
    // Auto-advance: when a verse finishes, honour the repeat settings
    // first (repeat mode, then range), then advance to the next verse
    // of the surah; at the last verse (or when a whole-surah file ends)
    // clear the now-playing state so the player disappears. A name
    // clip simply ends its session.
    player.playerStateStream.listen((state) {
      if (state.processingState != ProcessingState.completed) return;
      if (currentName.value != null) {
        stop();
        return;
      }
      final surah = currentSurah.value;
      final ayah = currentAyah.value;
      if (surah != null && ayah != null) {
        final count = QuranRepository.instance.surah(surah).ayahCount;
        // Sleep timer "end of surah": stop at the surah's last verse.
        if (sleepEndOfSurah.value && ayah >= count) {
          sleepEndOfSurah.value = false;
          stop();
          return;
        }
        // Repeat one verse.
        if (repeatMode.value == VerseRepeatMode.loop) {
          playAyah(surah, ayah);
          return;
        }
        if (_repeatLeft > 0) {
          _repeatLeft--;
          playAyah(surah, ayah);
          return;
        }
        // Repeat a range: advance inside it, wrap to its start.
        final range = repeatRange.value;
        if (range != null) {
          if (ayah < range.$2) {
            playAyah(surah, ayah + 1);
          } else {
            playAyah(surah, range.$1);
          }
          return;
        }
        if (ayah < count) {
          playAyah(surah, ayah + 1);
          return;
        }
      }
      stop();
    });
    // Follow the reciter setting: when it changes mid-playback, restart
    // the current verse with the new voice (or, from whole-surah mode,
    // restart the surah verse-by-verse with the new reciter).
    _lastReciterId = appState.reciterId;
    appState.addListener(() {
      final id = appState.reciterId;
      if (id == _lastReciterId) return;
      _lastReciterId = id;
      currentReciter.value = reciterById(id);
      if (currentName.value != null) return;
      final surah = currentSurah.value;
      final ayah = currentAyah.value;
      if (surah == null) return;
      if (ayah != null) {
        playAyah(surah, ayah);
      } else {
        playSurah(surah);
      }
    });
  }
  static final AudioService instance = AudioService._();

  final AudioPlayer player = AudioPlayer();
  final ValueNotifier<int?> currentSurah = ValueNotifier(null);

  /// The verse currently playing in per-ayah mode, or null when a
  /// whole-surah file is playing (or nothing is playing).
  final ValueNotifier<int?> currentAyah = ValueNotifier(null);

  /// The 99 Names entry (1–99) currently reciting, or null.
  final ValueNotifier<int?> currentName = ValueNotifier(null);

  /// Fires whenever the visible player session changes.
  late final Listenable sessionListenable;

  /// True while a Quran or name recitation session is active
  /// (playing or paused) — the app-wide player shows then.
  bool get hasActiveSession =>
      currentSurah.value != null || currentName.value != null;

  final ValueNotifier<int?> downloadingSurah = ValueNotifier(null);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0);

  /// The active reciter (follows appState.reciterId).
  final ValueNotifier<Reciter> currentReciter = ValueNotifier(
    reciterById(appState.reciterId),
  );

  /// Memorisation: how the current verse repeats.
  final ValueNotifier<VerseRepeatMode> repeatMode = ValueNotifier(
    VerseRepeatMode.off,
  );

  /// Memorisation: a verse range (start, end) within the current surah
  /// to loop, or null for no range.
  final ValueNotifier<(int, int)?> repeatRange = ValueNotifier(null);

  /// Sleep timer: seconds left (0 = off).
  final ValueNotifier<int> sleepSecondsLeft = ValueNotifier(0);

  /// Sleep timer: stop at the end of the current surah.
  final ValueNotifier<bool> sleepEndOfSurah = ValueNotifier(false);

  /// Plays of the current verse still owed by the repeat setting
  /// (excluding the play in progress).
  int _repeatLeft = 0;
  String _lastReciterId = 'ar.alafasy';
  Timer? _sleepCountdown;

  Reciter get _reciter => currentReciter.value;

  // ------------------------------------------------------------------
  // Local files.
  // ------------------------------------------------------------------

  Future<Directory> _audioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);
    return audioDir;
  }

  /// Whole-surah file for the current reciter. Alafasy keeps the
  /// legacy path (audio/surah_N.mp3) so downloads from earlier builds
  /// keep working; other whole-surah reciters get their own folder.
  Future<File> _localFile(int surah) async {
    final dir = await _audioDir();
    if (_reciter.id == 'ar.alafasy') {
      return File('${dir.path}/surah_$surah.mp3');
    }
    final reciterDir = Directory('${dir.path}/${_reciter.id}');
    if (!await reciterDir.exists()) {
      await reciterDir.create(recursive: true);
    }
    return File('${reciterDir.path}/surah_$surah.mp3');
  }

  /// One verse file for one reciter: audio/{edition}/a{global}.mp3.
  Future<File> _localAyahFile(String reciterId, int global) async {
    final dir = await _audioDir();
    final reciterDir = Directory('${dir.path}/$reciterId');
    if (!await reciterDir.exists()) {
      await reciterDir.create(recursive: true);
    }
    return File('${reciterDir.path}/a$global.mp3');
  }

  /// True when the surah is playable offline with the CURRENT reciter
  /// (checks the real files, not just the stored flag).
  Future<bool> isDownloaded(int surah) async {
    if (_reciter.hasWholeSurahFiles) {
      final f = await _localFile(surah);
      return f.exists();
    }
    final repo = QuranRepository.instance;
    final count = repo.surah(surah).ayahCount;
    for (var a = 1; a <= count; a++) {
      final f = await _localAyahFile(_reciter.id, repo.globalIndexOf(surah, a));
      if (!await f.exists()) return false;
    }
    return true;
  }

  /// Synchronous version for UI icons (trusts the stored flags).
  bool isDownloadedSync(int surah) {
    if (_reciter.id == 'ar.alafasy') {
      return appState.downloadedSurahs.contains(surah);
    }
    return appState.isSurahDownloadedFor(_reciter.id, surah);
  }

  // ------------------------------------------------------------------
  // Playback.
  // ------------------------------------------------------------------

  Future<void> playSurah(int surah) async {
    // Reciters without whole-surah files play the surah verse by
    // verse from ayah 1.
    if (!_reciter.hasWholeSurahFiles) {
      await playAyah(surah, 1);
      return;
    }
    try {
      currentName.value = null;
      currentSurah.value = surah;
      currentAyah.value = null;
      final f = await _localFile(surah);
      if (await f.exists()) {
        await player.setAudioSource(AudioSource.file(f.path));
      } else {
        await player.setAudioSource(
          AudioSource.uri(Uri.parse(_reciter.surahUrl(surah))),
        );
      }
      await player.play();
    } catch (e) {
      debugPrint('QUBA audio error: $e');
      currentSurah.value = null;
      currentAyah.value = null;
    }
  }

  /// Plays one verse (downloaded file first, else streamed) and
  /// auto-advances through the surah, honouring the repeat settings.
  Future<void> playAyah(int surah, int ayah) async {
    // Yasser Al-Dosari has no per-ayah files: a verse tap starts the
    // whole surah instead of requesting a URL the CDN rejects.
    if (!_reciter.supportsAyahFiles) {
      await playSurah(surah);
      return;
    }
    try {
      currentName.value = null;
      currentSurah.value = surah;
      currentAyah.value = ayah;
      _resetRepeatLeft();
      final repo = QuranRepository.instance;
      final global = repo.globalIndexOf(surah, ayah);
      final f = await _localAyahFile(_reciter.id, global);
      if (await f.exists()) {
        await player.setAudioSource(AudioSource.file(f.path));
      } else {
        await player.setAudioSource(
          AudioSource.uri(Uri.parse(_reciter.ayahUrl(global))),
        );
      }
      await player.play();
    } catch (e) {
      debugPrint('QUBA audio error: $e');
      currentSurah.value = null;
      currentAyah.value = null;
    }
  }

  /// Bundled pronunciation clip for 99 Names entry [number] (1–99).
  static String nameAssetPath(int number) =>
      'assets/names/name_${number.toString().padLeft(2, '0')}.ogg';

  /// Recites one of the 99 Names (bundled human pronunciation; see
  /// assets/names/LICENSE.txt). Replaces any Quran session.
  Future<void> playName(int number) async {
    try {
      currentSurah.value = null;
      currentAyah.value = null;
      currentName.value = number;
      await player.setAudioSource(AudioSource.asset(nameAssetPath(number)));
      await player.play();
    } catch (e) {
      debugPrint('QUBA audio error: $e');
      currentSurah.value = null;
      currentAyah.value = null;
      currentName.value = null;
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
    cancelSleepTimer();
    _repeatLeft = 0;
    // Clear the session first: close must hide the player at once,
    // even if the platform player's stop is slow to answer.
    currentSurah.value = null;
    currentAyah.value = null;
    currentName.value = null;
    try {
      await player.stop();
    } catch (_) {
      // The session is already cleared; nothing else to do.
    }
  }

  // ------------------------------------------------------------------
  // Memorisation (repeat).
  // ------------------------------------------------------------------

  void _resetRepeatLeft() {
    _repeatLeft = switch (repeatMode.value) {
      VerseRepeatMode.three => 2,
      VerseRepeatMode.five => 4,
      _ => 0,
    };
  }

  /// Set the verse-repeat mode; takes effect on the current verse too
  /// (its remaining repeats are re-counted).
  void setVerseRepeatMode(VerseRepeatMode mode) {
    repeatMode.value = mode;
    _resetRepeatLeft();
  }

  /// Loop verses [start]..[end] of the current surah (clamped to it).
  void setRepeatRange(int start, int end) {
    final surah = currentSurah.value;
    if (surah == null) return;
    final count = QuranRepository.instance.surah(surah).ayahCount;
    var s = start.clamp(1, count);
    var e = end.clamp(1, count);
    if (s > e) {
      final t = s;
      s = e;
      e = t;
    }
    repeatRange.value = (s, e);
  }

  void clearRepeatRange() => repeatRange.value = null;

  // ------------------------------------------------------------------
  // Sleep timer.
  // ------------------------------------------------------------------

  /// Stop playback after [duration]. Cancels any end-of-surah setting.
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepEndOfSurah.value = false;
    sleepSecondsLeft.value = duration.inSeconds;
    _sleepCountdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = sleepSecondsLeft.value - 1;
      if (left <= 0) {
        stop();
      } else {
        sleepSecondsLeft.value = left;
      }
    });
  }

  /// Stop playback at the end of the current surah (cancels a timed
  /// sleep timer). Has no effect in whole-surah mode beyond the normal
  /// end-of-file stop.
  void setSleepEndOfSurah(bool value) {
    if (value) cancelSleepTimer();
    sleepEndOfSurah.value = value;
  }

  void cancelSleepTimer() {
    _sleepCountdown?.cancel();
    _sleepCountdown = null;
    if (sleepSecondsLeft.value != 0) sleepSecondsLeft.value = 0;
  }

  // ------------------------------------------------------------------
  // Downloads.
  // ------------------------------------------------------------------

  Future<bool> downloadSurah(int surah) async {
    if (downloadingSurah.value != null) return false;
    if (_reciter.hasWholeSurahFiles) {
      return _downloadWholeSurah(surah);
    }
    return _downloadSurahVerses(surah);
  }

  Future<bool> _downloadWholeSurah(int surah) async {
    downloadingSurah.value = surah;
    downloadProgress.value = 0;
    try {
      final req = http.Request('GET', Uri.parse(_reciter.surahUrl(surah)));
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
      if (_reciter.id == 'ar.alafasy') {
        appState.markDownloaded(surah);
      } else {
        appState.markSurahDownloadedFor(_reciter.id, surah);
      }
      return true;
    } catch (e) {
      debugPrint('QUBA download error: $e');
      return false;
    } finally {
      downloadingSurah.value = null;
      downloadProgress.value = 0;
    }
  }

  /// Verse-by-verse download for reciters without whole-surah files.
  /// On any failure the files written in this attempt are removed so a
  /// surah is never left half-downloaded.
  Future<bool> _downloadSurahVerses(int surah) async {
    downloadingSurah.value = surah;
    downloadProgress.value = 0;
    final written = <File>[];
    final client = http.Client();
    try {
      final repo = QuranRepository.instance;
      final count = repo.surah(surah).ayahCount;
      for (var a = 1; a <= count; a++) {
        final global = repo.globalIndexOf(surah, a);
        final res = await client.get(Uri.parse(_reciter.ayahUrl(global)));
        if (res.statusCode != 200) return false;
        final f = await _localAyahFile(_reciter.id, global);
        await f.writeAsBytes(res.bodyBytes);
        written.add(f);
        downloadProgress.value = a / count;
      }
      appState.markSurahDownloadedFor(_reciter.id, surah);
      return true;
    } catch (e) {
      debugPrint('QUBA download error: $e');
      return false;
    } finally {
      client.close();
      if (downloadingSurah.value == surah &&
          !appState.isSurahDownloadedFor(_reciter.id, surah)) {
        for (final f in written) {
          try {
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
      }
      downloadingSurah.value = null;
      downloadProgress.value = 0;
    }
  }

  Future<void> deleteDownload(int surah) async {
    if (_reciter.hasWholeSurahFiles) {
      final f = await _localFile(surah);
      if (await f.exists()) await f.delete();
      if (_reciter.id == 'ar.alafasy') {
        appState.unmarkDownloaded(surah);
      } else {
        appState.unmarkSurahDownloadedFor(_reciter.id, surah);
      }
      return;
    }
    final repo = QuranRepository.instance;
    final count = repo.surah(surah).ayahCount;
    for (var a = 1; a <= count; a++) {
      final f = await _localAyahFile(_reciter.id, repo.globalIndexOf(surah, a));
      if (await f.exists()) await f.delete();
    }
    appState.unmarkSurahDownloadedFor(_reciter.id, surah);
  }
}
