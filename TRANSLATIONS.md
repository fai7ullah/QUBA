# QUBA Quran translations — sources & licences

QUBA is a commercial product (Play Store distribution, premium planned).
That decides the rule for every translation bundled here:

> **A translation ships ONLY if it is public domain.** Tanzil's blanket
> term (tanzil.net/trans/) allows its translations "for non-commercial
> purposes only" unless permission is obtained — that does NOT cover
> QUBA. The Quran TEXT itself is CC BY 3.0 (fine with attribution), but
> each translation is a separate copyrighted work, so each one below
> was checked on its translator's death date and the copyright term of
> the translator's home country.
>
> **Life+70 caveat, stated plainly:** the two translations shipped in
> round 3 are public domain under the life+50 terms of Pakistan and
> Iran, but under a life+70 term (US, UK, EU) they would still be in
> copyright — Jalandhari until 2041, Ghomshei until 2043/2045. This is
> a known, accepted position for this app; it is not hidden. If QUBA
> ever needs a translation that is public domain under life+70 as well,
> Junagarhi (Urdu, below) is the verified backup.

## Shipped

### English — Marmaduke Pickthall (`en.pickthall`)
- Translator: Marmaduke Pickthall (1875–1936, died 19 May 1936).
- Licence: public domain everywhere — life+50 expired 1986, life+70
  expired 2006.
- Location: inside `assets/quran/quran_bundle.json` (the `en` field of
  each ayah), NOT a separate file. It was already bundled before round 3
  and was the default English option until phase 2, when Yusuf Ali
  (below) became the default; Pickthall stays selectable.
- Served by `TranslationRepository` from `QuranRepository`.

### English — Abdullah Yusuf Ali (`en.yusufali`) — DEFAULT since phase 2
- Translator: Abdullah Yusuf Ali (1872–1953, died 10 December 1953).
- Source: AlQuran Cloud edition `en.yusufali` —
  https://api.alquran.cloud/v1/quran/en.yusufali
- File: `assets/quran/trans_en_yusufali.json` — 922,149 bytes,
  MD5 `ed3b470a07c764a3c71b4d80ec0bd158`.
- Licence: PUBLIC DOMAIN everywhere — life+50 expired 2003, life+70
  expired 2023. No life+70 caveat applies.
- Made the default English translation in phase 2 (2026-11-21) at the
  owner's request: he asked for Sahih International, which is
  copyrighted (see below), and accepted Yusuf Ali as the public-domain
  alternative. Existing installs migrate once from Pickthall to Yusuf
  Ali (see `AppState.load`); Pickthall stays available in the picker.

### Tafsir — Tafsir al-Jalalayn (Arabic)
- Authors: Jalal ad-Din al-Mahalli (d. 1459) and Jalal ad-Din
  as-Suyuti (d. 1505).
- Source: fawazahmed0/quran-api edition `ara-jalaladdinalmah`
  (sourced by that repo from Tanzil) —
  https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-jalaladdinalmah.min.json
- File: `assets/tafsir/jalalayn.json` — 1,917,281 bytes,
  MD5 `a6fcbaeffb52f8aea39e110d4f46b170`.
- Licence: PUBLIC DOMAIN. A 15th-century text; Tanzil's
  non-commercial terms govern the translations it hosts and cannot
  create copyright in a public-domain text, and a faithful
  transcription of a public-domain text carries no new copyright.
- Verified: exactly 114 surahs, exactly 6,236 ayahs, per-surah counts
  match the Uthmani bundle with 0 mismatches, 0 empty texts.

### Hadith — the six books (Arabic only)
- Source: fawazahmed0/hadith-api (branch `1`), Arabic editions
  `ara-{bukhari,muslim,abudawud,tirmidhi,nasai,ibnmajah}` —
  https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-<book>.min.json
  Chapter ranges for placing unreferenced hadiths came from the same
  repo's `info.json` (`section_details`).
- Repo licence: The Unlicense (public domain dedication) — covers the
  repo author's work. The classical Arabic matn is public domain
  (authors died 9th–10th century CE).
- Files: `assets/hadith/{bukhari,muslim,abudawud,tirmidhi,nasai,ibnmajah}.json`
  — 34,153 hadiths total (bukhari 7,580; muslim 7,360; abudawud 5,272;
  tirmidhi 3,924; nasai 5,679; ibnmajah 4,338). Every shipped Arabic
  text is byte-identical to the source (checked on ALL entries).
- **English translations NOT shipped** (see "Not shipped" below):
  every hadith has `"en": null` and the app shows an "Arabic only"
  note. The English display/search code exists and is tested — dormant
  until a licensed translation ships.
- **379 entries dropped**: the upstream source has entries with empty
  `""` text (bukhari 9, muslim 203, abudawud 2, tirmidhi 74, nasai 86,
  ibnmajah 5); they cannot ship as empty hadith. The gaps are upstream
  defects (confirmed in the source's per-hadith endpoints too), not
  conversion losses — full list in `build-outputs/DATA-REPORT.md`.
  Notably Muslim's Introduction (1–92) is almost entirely missing
  upstream (only 3, 4, 15 survive) and Nasai is missing an 82-hadith
  consecutive block (3857–3938).
- Chapter titles: `title_en` from the source's section names (short
  descriptive titles, e.g. "Revelation", "Belief"); `title_ar` is `""`
  throughout — the source provides no Arabic chapter titles.
- Grades: from the source, preferring Al-Albani where present
  (e.g. "Sahih (Al-Albani)"); null throughout for Bukhari/Muslim (the
  Sahihain carry no grades in the source).

### Adhan notification sound (CC0)
- File: `android/app/src/main/res/raw/athan_adhan.mp3` — 2,465,167
  bytes, MD5 `4069f1fe2e938d3c4520c105eafa88e5`, 154.02 s, 128 kbps.
- Source: Wikimedia Commons, "Beautiful adhan"
  (File:Beautiful_adhan.ogg), by Adam-synagda, 29 April 2022 —
  https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg
- Licence: **CC0 1.0 Universal** (public domain dedication), verified
  in the file's Commons metadata. No attribution legally required.
  Converted OGG Vorbis → MP3 for Android raw-resource use (CC0
  permits the conversion). A complete Adhan, single voice.
- Note: 154 s is long for a notification sound; Android may cut long
  notification sounds short. Whether the full Adhan plays must be
  verified on-device (see NEXT-UPDATE.md round 4 item 4).

### Audio reciters (streamed, not bundled)
- The 17 reciters stream verse-by-verse MP3s from cdn.islamic.network
  (see `lib/reciters.dart`); no audio files are bundled. Per AlQuran
  Cloud's terms, the recitations are licensed to Islamic Network for
  free non-commercial redistribution; QUBA streams (does not
  redistribute) them, as it already did for the round-3 four.
  Thirteen reciters were added in phase 2 after HEAD-verifying all six
  probe ayahs (1, 8, 262, 293, 3000, 6236) at one bitrate each; the
  full 170-edition probe table is in `build-outputs/DATA-REPORT.md`.
  Not available on this CDN (403 at every bitrate): Aziz Alili,
  Abdullah Awad al-Juhani, Ibrahim Walk (English translation audio,
  not a reciter), Abdul Basit Mujawwad, Saud al-Shuraim (alternate
  id — the shipped `ar.saoodshuraym` remains the Shuraim edition).

### Urdu — Fateh Muhammad Jalandhari (`ur.jalandhry`)
- Translator: Fateh Muhammad Jalandhari (1895–1971, died 21 April 1971).
  (Wikipedia lists the same scholar under the name Muhammad Ali
  Jalandhari, 1895 – 21 April 1971, author of the Urdu translation
  *Fātiḥ al-Ḥamīd*, first published 1960.)
- Source: AlQuran Cloud edition `ur.jalandhry` —
  https://api.alquran.cloud/v1/quran/ur.jalandhry
- File: `assets/quran/trans_ur_jalandhry.json` — 1,429,132 bytes,
  MD5 `696c128d15606f473601699f5e0ae1a8`.
- Licence: PUBLIC DOMAIN. Pakistan copyright is life + 50 years, so
  Jalandhari's copyright expired at the end of 2021.
- Life+70 caveat: under a life+70 term he would still be in copyright
  until 2041. See the caveat at the top of this file.

### Persian / Dari — Mahdi Elahi Ghomshei (`fa.ghomshei`)
- Translator: Mahdi Elahi Ghomshei (1901 – died 15 May 1973, Qom, per
  Wikipedia; Encyclopaedia Iranica gives 1354 Š./1975, Tehran).
- Source: AlQuran Cloud edition `fa.ghomshei` —
  https://api.alquran.cloud/v1/quran/fa.ghomshei
- File: `assets/quran/trans_fa_ghomshei.json` — 1,560,825 bytes,
  MD5 `b460f9decf866559886bea86213fc2c3`.
- Licence: PUBLIC DOMAIN. Iran copyright is life + 50 years. On the
  1973 date the term expired at the end of 2023; on the later 1975
  date it expired at the end of 2025. **Conservative reading: even
  taking the later (1975) death date, the work is public domain by
  November 2026.** The 1973/1975 discrepancy is documented here rather
  than resolved, because it does not change the conclusion.
- Life+70 caveat: under a life+70 term he would still be in copyright
  until 2043 (1973 date) or 2045 (1975 date). See the caveat at the
  top of this file.

## Verification (round 3, 2026-11-17)

Both files were downloaded from AlQuran Cloud and converted to the
compact shape `{"surahs": [{"number": n, "ayahs": ["...", ...]}, ...]}`
(the same shape as `quran_indopak.json`, minus the surah name). Each
file was verified against `assets/quran/quran_bundle.json`:

- exactly 114 surahs, exactly 6,236 ayahs total;
- per-surah ayah counts match the Uthmani bundle — **0 mismatches**;
- every ayah text non-empty — **0 empty ayahs**.

`test/translation_test.dart` re-checks all of this from the real files
on disk on every run, plus spot-checks (1:1, 2:255) and the
`TranslationRepository` API.

## Verification (phase 2, 2026-11-21)

- Yusuf Ali: exactly 114 surahs, exactly 6,236 ayahs, per-surah counts
  match — **0 mismatches**, **0 empty ayahs**. Re-checked by
  `test/translation_test.dart` on every run.
- Jalalayn: same checks, **0 mismatches**, **0 empty texts**.
  Re-checked by `test/tafsir_test.dart`.
- Hadith: every shipped Arabic text byte-identical to the source;
  `total` equals the entry count per file; entries in ascending number
  order within each chapter. Re-checked by `test/hadith_test.dart`.
- Adhan: ffprobe duration/bitrate/size + full ffmpeg decode + volume
  and silence analysis (no silence gap ≥ 2 s; continuous voice).

## Not shipped (phase 2 additions)

### Hadith — English translations (all six books)
- SKIPPED (Arabic-only shipped). The English editions are the
  sunnah.com translations. Sunnah.com's About page (§8 "Reproduction,
  Copying, Scraping") states: *"We do not permit the scraping of our
  data, nor mass reproduction of entire books or collections on other
  websites"* — only individual hadith for teaching/presentation are
  permitted. The translations are modern Darussalam ones (e.g. Muhammad
  Muhsin Khan for Bukhari, d. 2021). No licence allowing commercial
  app distribution of the full English texts could be verified.

### Tafsir — Yusuf Ali commentary (English)
- SKIPPED. The commentary text itself is public domain (Yusuf Ali
  d. 1953) but no clean machine-readable per-ayah source exists:
  quranlab/quran-tafsir on HuggingFace has no Yusuf Ali config, and
  archive.org holds only a scanned/OCR book (djvu text, not structured
  per-ayah; the footnotes are not keyed per ayah). A careful
  transcription/OCR project is a future option — not done, not faked.
  The Tafsir screen shows Jalalayn only until then.

### Word-by-word Quran analysis
- NOT SHIPPED — no bundleable licensed source exists. Every candidate
  fails the licence rule for a bundled file in a commercial app:
  1. Quranic Arabic Corpus (corpus.quran.com): GNU GPL licence with a
     no-change clause (forbids the format conversion), email-gated
     download, and its morphology file has NO English glosses at all
     (only Arabic form + Buckwalter transliteration + grammar tags).
  2. Quran.com API v4: returns the right shape, but the Quran
     Foundation Developer Terms forbid redistribution and impose a
     one-week storage limit; worse, the English glosses are the Shaikh
     & Khatri word-by-word translation (2007, living authors), whose
     own book states commercial use is strictly not allowed.
  3. Tanzil transliteration: listed under "non-commercial purposes
     only" — no commercial-use licence verifiable.
  4. fawazahmed0/quran-api: 492 editions, none word-level.
  Compliant future paths (not data files): fetch from api.quran.com
  at runtime and display without bundling (display-only use is
  allowed; mind the one-week cache limit); Quran Foundation Content
  Sync (permits longer storage, needs a Developer Console account);
  or written permission from the rights holders. The word-by-word
  screen, repository and i18n keys stay in the tree, hidden from the
  UI until data exists — see `lib/screens/extras_screen.dart`.

### Persian / Dari — Mohammad Mahdi Fooladvand (`fa.fooladvand`)
- SKIPPED. Modern translator; his Persian translation was published in
  1994 and he is described as "the late" in recent scholarship, but no
  death date could be found (verified by search, 2026-11-17). Under any
  plausible reading he is still in copyright — even a death in the
  2000s would keep the work under copyright into the 2050s+ on a
  life+50 term. No free licence was found; only Tanzil's
  non-commercial terms cover it, which does not cover QUBA.

### Pashto — Abdul Wali (`ps.abdulwali`)
- SKIPPED. Contemporary translator: his Pashto Quran appears in
  *Tafsir Ahsan al-Kalam* (Darussalam, 2009 edition). No death date,
  and no licence allowing commercial app distribution was found. No
  other Pashto translation exists on AlQuran Cloud. The owner may seek
  permission from Darussalam if a Pashto translation is wanted later.

### English — Sahih International (`en.sahih`)
- SKIPPED. Copyrighted work (first published 1997, Jeddah team). No
  verifiable licence permitting commercial app distribution was found.
  The official site saheehinternational.com is defunct — the domain
  now serves a slot-gambling site — so there is no rights-holder
  contact to ask.

## Verified public-domain backup (not shipped this round)

### Urdu — Muhammad Junagarhi (`ur.junagarhi`)
- Translator: Muhammad Junagarhi (1890–1941, died March 1941).
- Public domain everywhere: life+50 expired 1991, life+70 expired
  2011. Kept as the backup Urdu translation if a life+70-safe option
  is ever needed; not bundled in round 3.
