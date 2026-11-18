import 'package:flutter_test/flutter_test.dart';

import 'package:quba/app_state.dart';
import 'package:quba/i18n.dart';
import 'package:quba/reciters.dart';

void main() {
  group('reciters', () {
    test('four reciters ship, Alafasy first (the default)', () {
      expect(reciters.length, 4);
      expect(reciters.first.id, 'ar.alafasy');
      expect(
        reciters.map((r) => r.id).toList(),
        [
          'ar.alafasy',
          'ar.abdulsamad',
          'ar.mahermuaiqly',
          'ar.saoodshuraym',
        ],
      );
    });

    test('every reciter has a unique id and a name key', () {
      expect(reciters.map((r) => r.id).toSet().length, 4);
      expect(reciters.map((r) => r.nameKey).toSet().length, 4);
      for (final r in reciters) {
        expect(r.nameKey, startsWith('reciter_name_'));
      }
    });

    test('per-ayah URL patterns (bitrate differs per edition)', () {
      // Alafasy and Maher Al Muaiqly serve 128kbps; Abdul Basit and
      // Shuraim serve 64kbps only (128kbps returns 403 on the CDN).
      // Ayah 1 = Al-Fatiha 1:1, ayah 6236 = the last verse (114:6).
      expect(reciterById('ar.alafasy').ayahUrl(1),
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3');
      expect(reciterById('ar.alafasy').ayahUrl(6236),
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6236.mp3');
      expect(reciterById('ar.mahermuaiqly').ayahUrl(262),
          'https://cdn.islamic.network/quran/audio/128/ar.mahermuaiqly/262.mp3');
      expect(reciterById('ar.abdulsamad').ayahUrl(1),
          'https://cdn.islamic.network/quran/audio/64/ar.abdulsamad/1.mp3');
      expect(reciterById('ar.saoodshuraym').ayahUrl(3000),
          'https://cdn.islamic.network/quran/audio/64/ar.saoodshuraym/3000.mp3');
    });

    test('only Alafasy has whole-surah files', () {
      expect(reciterById('ar.alafasy').hasWholeSurahFiles, isTrue);
      expect(reciterById('ar.abdulsamad').hasWholeSurahFiles, isFalse);
      expect(reciterById('ar.mahermuaiqly').hasWholeSurahFiles, isFalse);
      expect(reciterById('ar.saoodshuraym').hasWholeSurahFiles, isFalse);
      expect(reciterById('ar.alafasy').surahUrl(2),
          'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/2.mp3');
    });

    test('unknown ids fall back to Alafasy', () {
      expect(reciterById('ar.nosuchreciter').id, 'ar.alafasy');
      expect(reciterById('').id, 'ar.alafasy');
    });

    test('every reciter has a short name for the mini-player', () {
      // Regression: the mini-player showed the full name with no
      // maxLines, and it rendered vertically (2026-11-18). The short
      // name must exist, be non-empty, and be shorter than the full
      // name in every UI language.
      for (final r in reciters) {
        for (final lang in QubaStrings.langs) {
          appState.lang = lang;
          expect(r.shortName, isNotEmpty);
          expect(r.shortName.length, lessThan(r.name.length));
        }
      }
      appState.lang = 'en';
    });
  });
}
