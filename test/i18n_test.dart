import 'package:flutter_test/flutter_test.dart';

import 'package:quba/app_state.dart';
import 'package:quba/content.dart';
import 'package:quba/i18n.dart';

void main() {
  group('i18n dictionary completeness', () {
    test('every key has all 5 languages present and non-empty', () {
      for (final e in QubaStrings.all.entries) {
        for (final lang in QubaStrings.langs) {
          expect(e.value[lang], isNotNull,
              reason: 'key ${e.key} missing $lang');
          expect(e.value[lang]!.trim(), isNotEmpty,
              reason: 'key ${e.key} empty for $lang');
        }
      }
    });

    test('the 99 name-meaning keys all exist', () {
      for (var i = 1; i <= 99; i++) {
        expect(QubaStrings.all.containsKey('name_meaning_$i'), isTrue);
      }
    });

    test('the 114 surah-meaning keys all exist', () {
      for (var i = 1; i <= 114; i++) {
        expect(QubaStrings.all.containsKey('surah_meaning_$i'), isTrue);
      }
    });

    test('the 30 juz-name keys all exist', () {
      for (var i = 1; i <= 30; i++) {
        expect(QubaStrings.all.containsKey('juz_name_$i'), isTrue);
      }
    });

    test('English name meanings match content.dart exactly', () {
      for (var i = 0; i < names99.length; i++) {
        expect(
          QubaStrings.get('en', 'name_meaning_${i + 1}'),
          names99[i].meaning,
          reason: 'name ${i + 1}',
        );
      }
    });

    test('dua title and category keys all exist', () {
      for (final d in duas) {
        expect(QubaStrings.all.containsKey(d.title), isTrue,
            reason: 'dua title ${d.title}');
      }
      for (final c in duaCategories) {
        expect(QubaStrings.all.containsKey(c), isTrue,
            reason: 'category $c');
      }
    });

    test('placeholders are consistent across languages', () {
      final ph = RegExp(r'\{(\w+)\}');
      for (final e in QubaStrings.all.entries) {
        final en = ph.allMatches(e.value['en']!).map((m) => m[1]).toSet();
        for (final lang in ['ps', 'fa', 'ur', 'ar']) {
          final other =
              ph.allMatches(e.value[lang]!).map((m) => m[1]).toSet();
          expect(other, en, reason: 'key ${e.key} in $lang');
        }
      }
    });
  });

  group('trf formatting', () {
    test('substitutes placeholders', () {
      expect(trf('verses_count', {'n': 7}), '7 verses');
      expect(trf('juz_n', {'n': 3}), 'Juz: 3');
      expect(
        trf('verses_read_in_plan', {'read': 10, 'remaining': 100}),
        '10 of 100 verses read in this plan',
      );
    });

    test('a missing arg leaves the placeholder as-is', () {
      expect(trf('verses_count'), '{n} verses');
      expect(trf('verses_read_in_plan', {'read': 10}),
          '10 of {remaining} verses read in this plan');
    });

    test('an unknown key falls back to the key itself', () {
      expect(tr('no_such_key_xyz'), 'no_such_key_xyz');
      expect(trf('no_such_key_xyz', {'n': 1}), 'no_such_key_xyz');
    });
  });

  group('tr lookups per language', () {
    test("tr('settings') in ps/fa/ur", () {
      appState.lang = 'ps';
      expect(tr('settings'), 'ترتیبات');
      appState.lang = 'fa';
      expect(tr('settings'), 'تنظیمات');
      appState.lang = 'ur';
      expect(tr('settings'), 'ترتیبات');
      appState.lang = 'en';
      expect(tr('settings'), 'Settings');
    });

    test('spot-checks in all three languages', () {
      appState.lang = 'ps';
      expect(tr('prayer_fajr'), 'فجر');
      expect(tr('prayer_dhuhr'), 'ماسپښین');
      expect(tr('hijri_month_9'), 'رمضان');
      expect(tr('greg_month_1'), 'جنوري');
      expect(tr('surah_meaning_1'), 'پیل');
      expect(tr('juz_name_2'), 'سیقول');
      expect(tr('name_meaning_2'), 'تر ټولو مهربان');
      expect(tr('Before eating'), 'تر خوړلو مخکې');
      expect(tr('Morning & Evening'), 'سهار او ماښام');
      appState.lang = 'fa';
      expect(tr('prayer_dhuhr'), 'ظهر');
      expect(tr('hijri_month_9'), 'رمضان');
      expect(tr('surah_meaning_1'), 'گشایش');
      expect(tr('juz_name_2'), 'سیقول');
      expect(tr('name_meaning_2'), 'بخشنده‌ترین');
      expect(tr('Before eating'), 'پیش از غذا');
      appState.lang = 'ur';
      expect(tr('prayer_dhuhr'), 'ظہر');
      expect(tr('hijri_month_9'), 'رمضان');
      expect(tr('surah_meaning_1'), 'کھولنے والی');
      expect(tr('juz_name_2'), 'سیقول');
      expect(tr('name_meaning_2'), 'نہایت رحم کرنے والا');
      expect(tr('Before eating'), 'کھانے سے پہلے');
      appState.lang = 'en';
    });

    test('spot-checks in Arabic', () {
      appState.lang = 'ar';
      expect(tr('settings'), 'الإعدادات');
      expect(tr('prayer_fajr'), 'الفجر');
      expect(tr('hijri_month_9'), 'رمضان');
      expect(tr('surah_meaning_1'), 'الفاتحة');
      expect(tr('juz_name_2'), 'سيقول');
      expect(tr('name_meaning_2'), 'شديد الرحمة');
      expect(tr('Before eating'), 'قبل الأكل');
      appState.lang = 'en';
    });

    test('trPrayer maps stored English names', () {
      appState.lang = 'ur';
      expect(trPrayer('Fajr'), 'فجر');
      expect(trPrayer('Dhuhr'), 'ظہر');
      expect(trPrayer('Sunrise'), 'طلوع آفتاب');
      expect(trPrayer('Unknown'), 'Unknown');
      appState.lang = 'en';
      expect(trPrayer('Fajr'), 'Fajr');
    });

    test('trLocation maps the two known stored values', () {
      appState.lang = 'ps';
      expect(trLocation('Kabul (default)'), 'کابل (تلواله)');
      expect(trLocation('My location (GPS)'), 'زما ځای (GPS)');
      expect(trLocation('Herat'), 'Herat');
      appState.lang = 'en';
      expect(trLocation('Kabul (default)'), 'Kabul (default)');
    });
  });
}
