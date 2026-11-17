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
  and stays the default English option.
- Served by `TranslationRepository` from `QuranRepository`.

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

## Not shipped

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
