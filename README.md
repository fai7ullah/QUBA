# QUBA — Quran, Athan & Prayer Times (Flutter)

![QUBA logo](assets/images/quba_logo.png)

A complete, offline-first Islamic companion app: Quran reader with audio,
on-device prayer times with Athan alerts, Qibla compass, Hijri calendar,
Khatma plan, Duas, 99 Names of Allah, Tasbih, Quran search, and daily
verse / dua / hadith — in English, Pashto, Dari and Urdu.

This is the Flutter rebuild (v1.0) of the native Android QUBA app
(v0.4). The design follows the owner's reference screenshots and written
design spec exactly: **Cream Liquid Glass + Modern Islamic Aesthetic**
— creamy ivory `#F8F0E5`, emerald `#075B43`, gold `#C9A45C`, real
frosted-glass cards (`BackdropFilter` blur), and a deep emerald-black
dark mode.

## Run it

Requires Flutter **3.47.9** (stable) / Dart **3.13.7** or newer.

```bash
flutter pub get
flutter run
```

Build installable files:

```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Android (Play Store)
flutter build ipa --release        # iOS (needs a Mac + Apple Developer account)
```

> **Sandbox note:** the Gradle daemon is broken in the sandbox this
> project was built in, so `flutter build apk` cannot complete there.
> The project itself is complete and verified with `flutter analyze`
> and `flutter test` (see below); build it on a normal machine or CI.

## What is inside

| Area | Details |
|---|---|
| Quran | 114 surahs, 6,236 ayahs — Uthmani Arabic (Tanzil) + Pickthall English, bundled and verified (SHA-256 `9665930b…a0a1f`). Fully offline. |
| Audio | Mishary Alafasy per-surah MP3, Islamic Network CDN. Streams, or downloads per surah for offline listening. |
| Prayer times | Calculated **on the device** (ported PrayTimes algorithm, MWL default + Hanafi Asr; Karachi method optional). Verified against Aladhan for Kabul to the minute. No internet needed. |
| Athan alerts | Exact-alarm notifications, scheduled 7 days ahead, restored after reboot. Per-prayer bell toggles. |
| Qibla | Live compass (device sensors) + great-circle bearing to the Kaaba. Kabul bearing verified: 250.77°. |
| Hijri calendar | Month view (Kuwaiti civil algorithm) with Ramadan, the two Eids, Arafah, Ashura and Laylat al-Qadr marked. |
| Khatma | 7 / 30 / 90-day finish-the-Quran plans with daily portions and progress tracking. |
| Duas | 26 duas, each with Arabic, transliteration, English and its source. Quran-sourced duas load their Arabic from the verified bundled text at runtime. |
| 99 Names | The full list (Tirmidhi 3507 order) with transliteration and meaning. |
| Tasbih | Counter with 6 phrases, targets, haptics, lifetime totals. |
| Search | Quran search — Arabic (diacritic-insensitive) and English. |
| Daily content | Verse + dua + hadith rotating by day (17 Forty-Nawawi hadith). |
| Languages | App UI in English, Pashto, Dari and Urdu, with RTL layout. **Note:** the Pashto/Dari/Urdu strings are drafts awaiting the owner's correction. |

## Project structure

```
lib/
  main.dart            App entry + shell (floating glass bottom nav, 4 tabs)
  theme.dart           Design tokens: exact spec palette, light/dark themes,
                       geometric pattern + 8-point-star painters
  widgets.dart         Shared glass components: GlassCard (real blur),
                       GoldDivider, PrayerMedallion, PrayerScheduleCard,
                       FeatureChip, GlassButton, TitleRow, ArchImage
  prayer_calc.dart     Ported prayer-time math (PrayTimes) + Hijri + Qibla
  prayer_service.dart  Prayer times for the app (uses prayer_calc)
  data.dart            Quran repository (bundled JSON) + search
  content.dart         99 Names, Duas, Hadith, daily verses (ported, verified)
  i18n.dart            EN/PS/FA/UR UI strings (drafts for PS/FA/UR)
  app_state.dart       Settings + reading state (SharedPreferences)
  audio.dart           Per-surah streaming + offline downloads
  notifications.dart   Exact-alarm Athan scheduling
  screens/
    home_screen.dart      Reference Home: Next Prayer, schedule,
                          Continue Reading, quick buttons, chips, Today card
    prayer_screen.dart    Day browsing + reminder toggles
    quran_screen.dart     Surah list + bookmarks + search entry
    reader_screen.dart    Verse-by-verse reader + audio bar
    qibla_screen.dart     Live Qibla compass
    calendar_screen.dart  Hijri month calendar
    khatma_screen.dart    Khatma plans
    duas_screen.dart      Duas library
    names_screen.dart     99 Names
    tasbih_screen.dart    Tasbih counter
    search_screen.dart    Quran search
    settings_screen.dart  Theme, language, calculation, location, reminders
assets/
  quran/quran_bundle.json   Verified Quran text (114 surahs / 6,236 ayahs)
  images/mosque_arch.webp   Next Prayer card thumbnail (warm golden mosque)
  images/quran_rehal.webp   Continue Reading thumbnail (Quran on rehal)
  images/quba_logo.png      Official logo (master, for icon + README only)
  fonts/AmiriQuran-Regular.ttf
android/  Android scaffolding — package com.quba.app, launcher icons
          (adaptive + legacy) generated from the official logo
ios/      iOS scaffolding — bundle id com.quba.app, AppIcon set
test/
  prayer_accuracy_test.dart  Prayer/Qibla/Hijri verification vs known values
  widget_test.dart           Quran bundle load: 114 surahs / 6,236 ayahs
```

## Design rules (from the owner)

- The reference screenshots are the source of truth — no redesign.
- **No in-app QUBA header.** The owner ordered the header block (logo +
  wordmark + "Your Islamic Companion" + skyline) removed from the whole
  app. Screens start directly with content. This is the one deliberate
  deviation from the reference screenshots. The logo lives on as the
  **launcher icon** only.
- Liquid glass must be **real**: `BackdropFilter` + `ImageFilter.blur`.
  (The native v0.3 live-blur attempt broke on the owner's phone and was
  removed; Flutter's `BackdropFilter` is the proper solution.)
- No emojis as icons — Material icons and drawn glyphs only.
- Every visible button works. No placeholder screens.

## Verification

```bash
flutter analyze        # must pass with zero errors
flutter test           # prayer accuracy + Quran bundle checks
```

Verified in this repo:

- Prayer port vs the native app's Aladhan-checked Kabul values
  (2026-11-11, MWL + Hanafi): **all six prayers exact to the minute**
  (Fajr 04:56, Sunrise 06:22, Dhuhr 11:37, Asr 15:14, Maghrib 16:52,
  Isha 18:13). Karachi + summer dates within tolerance.
- Qibla bearing Kabul **250.77°**; Hijri 2026-11-12 = 1 Jumada
  al-Akhirah 1448.
- Quran bundle loads: **114 surahs / 6,236 ayahs**, spot-checked
  (Al-Fatiha 1:1, Ayat al-Kursi 2:255, Al-Ikhlas 112:1, Pickthall).

Not verified here (no device/emulator in this sandbox): on-device
visual match, compass sensor behaviour, exact-alarm delivery on
battery-aggressive phones, RTL layouts on a real phone. The owner's
eyes on his own phone remain the real test.

## Regenerating the launcher icon

The icon comes from the official logo (`assets/images/quba_logo.png`,
cropped to the artwork tile on cream in
`assets/images/quba_logo_icon.png`):

```bash
dart run flutter_launcher_icons
```

## Content & licences

- Quran Arabic: Tanzil `quran-uthmani` (King Fahd Complex text).
- English translation: Mohammed Marmaduke Pickthall (public domain) —
  test build only; the release translation set is a pending decision.
- Audio: Mishary Alafasy recordings via the Islamic Network CDN.
- Duas and hadith carry their sources in the app (see
  `lib/content.dart`). Nothing is AI-generated: Quran text is verified
  by checksum, and every dua/hadith entry cites its collection.
