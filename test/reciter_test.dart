import 'package:flutter_test/flutter_test.dart';

import 'package:quba/app_state.dart';
import 'package:quba/i18n.dart';
import 'package:quba/reciters.dart';

void main() {
  group('reciters', () {
    test('seventeen reciters ship, Alafasy first (the default)', () {
      expect(reciters.length, 17);
      expect(reciters.first.id, 'ar.alafasy');
      expect(
        reciters.map((r) => r.id).toList(),
        [
          'ar.alafasy',
          'ar.abdulsamad',
          'ar.mahermuaiqly',
          'ar.saoodshuraym',
          // Phase 2 (2026-11-21): thirteen more, all verified complete
          // on the CDN (6 probe ayahs each, 200 at one bitrate).
          'ar.husary',
          'ar.husarymujawwad',
          'ar.minshawi',
          'ar.minshawimujawwad',
          'ar.hudhaify',
          'ar.abdurrahmaansudais',
          'ar.shaatree',
          'ar.muhammadjibreel',
          'ar.muhammadayyoub',
          'ar.hanirifai',
          'ar.ahmedajamy',
          'ar.aymanswoaid',
          'ar.abdullahbasfar',
        ],
      );
    });

    test('every reciter has a unique id and a name key', () {
      expect(reciters.map((r) => r.id).toSet().length, 17);
      expect(reciters.map((r) => r.nameKey).toSet().length, 17);
      expect(reciters.map((r) => r.shortNameKey).toSet().length, 17);
      for (final r in reciters) {
        expect(r.nameKey, startsWith('reciter_name_'));
        expect(r.shortNameKey, startsWith('reciter_short_'));
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
      // Phase 2 additions: 128kbps editions and 64kbps-only editions.
      expect(reciterById('ar.husary').ayahUrl(1),
          'https://cdn.islamic.network/quran/audio/128/ar.husary/1.mp3');
      expect(reciterById('ar.minshawi').ayahUrl(6236),
          'https://cdn.islamic.network/quran/audio/128/ar.minshawi/6236.mp3');
      expect(reciterById('ar.hanirifai').ayahUrl(262),
          'https://cdn.islamic.network/quran/audio/64/ar.hanirifai/262.mp3');
      expect(reciterById('ar.abdurrahmaansudais').ayahUrl(3000),
          'https://cdn.islamic.network/quran/audio/64/ar.abdurrahmaansudais/3000.mp3');
      expect(reciterById('ar.minshawimujawwad').ayahUrl(8),
          'https://cdn.islamic.network/quran/audio/64/ar.minshawimujawwad/8.mp3');
    });

    test('only Alafasy has whole-surah files', () {
      expect(reciterById('ar.alafasy').hasWholeSurahFiles, isTrue);
      for (final r in reciters) {
        if (r.id != 'ar.alafasy') {
          expect(r.hasWholeSurahFiles, isFalse, reason: r.id);
        }
      }
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
