# IndoPak Mushaf style — data, font, page breaks

QUBA offers a Mushaf style choice (Settings → Appearance → Mushaf style):
**Madani** (Uthmani script, default) or **IndoPak** (South Asian script).
The style switches the Arabic Quran text everywhere it is shown, and the
font used to render it. This file documents where the IndoPak data and
font came from, what was verified, and the known limits.

## Text: `assets/quran/quran_indopak.json`

- **Source:** AlQuran Cloud API edition `quran-indopak`
  (`https://api.alquran.cloud/v1/quran/quran-indopak`), which serves the
  **Tanzil** IndoPak text (Tanzil v1.1, Feb 2021). Tanzil's own download
  page (`https://tanzil.net/download/`) was tried first on 2026-11-17 but
  its direct file URLs return "File not found" / 404, so the AlQuran
  Cloud mirror of the same Tanzil text was used instead.
- **Tanzil terms of use** (`https://tanzil.net/download/`): verbatim
  copies may be copied and distributed, the text must not be changed,
  and the source (Tanzil Project) must be indicated with a link to
  tanzil.net. The text here is verbatim (only the per-ayah trailing
  newline the API adds was stripped).
- **Format:** `{"surahs": [{"number": 1, "name": "...",
  "ayahs": ["...", ...]}, ...]}` — the shape `QuranRepository` loads.
- **Verification (2026-11-17, script + `test/indopak_test.dart`):**
  - Exactly **114 surahs** and **6,236 ayahs**; per-surah ayah counts
    match `assets/quran/quran_bundle.json` (Uthmani) exactly.
  - 6,208 of 6,236 ayahs differ from the Uthmani text (28 short ayahs
    are identical — they contain none of the differing letters).
  - Spot-checks (exact codepoints, see the test):
    - 1:1 Basmala: `بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ` — sukun
      is U+06E1 (dotless head of khah ۡ), al-raheem ends with Farsi
      yeh U+06CC (ی).
    - 2:3: `ٱلصَّلَوٰةَ` — waw + superscript alef U+0670 (ٰ) + teh
      marbuta; `یُؤۡمِنُونَ` uses Farsi yeh U+06CC and U+06E1 sukun.
      (Note: the وٰ in الصلوٰة is also in the Uthmani text — the
      IndoPak markers in this verse are the ی and the ۡ.)
    - 2:255: `ٱلۡحَیُّ` with Farsi yeh U+06CC.
  - Distinctive codepoints in the text: U+06CC Farsi yeh ×22,024,
    U+06E1 dotless-khah sukun ×37,372, U+0670 superscript alef ×9,838,
    U+06E4 madda ×5,376, U+08F0–U+08F2 open tanwin, U+06D6–U+06ED
    small-high marks, plus U+200A hair space / U+2060 word joiner.
    The text contains **no** U+064A Arabic yeh, **no** U+06BE (ہ) and
    **no** U+06D2 (ے) — the Tanzil IndoPak encoding does not use them.
- **Known limit — surah names:** the source's Arabic surah names are
  in Uthmani spelling (identical to the Uthmani bundle, e.g.
  `سُورَةُ ٱلْفَاتِحَةِ`), not IndoPak spelling (e.g. الفاتحہ). They
  are used as-is because they come from the source; true IndoPak
  surah-name spellings were not available from this dataset. Cosmetic
  only — it affects the mushaf banner / surah name display in IndoPak
  mode.

## Font: `assets/fonts/IndoPakQuran-Regular.ttf`

- **Chosen font: Scheherazade New v4.500, Regular** (331,504 bytes,
  MD5 `c0e47a64bbbe47569e478e2dfe42618e`), by SIL Global.
- **Licence: SIL Open Font License 1.1** — free to use, embed and
  redistribute in an app, including commercially. The full licence
  ships beside the font at `assets/fonts/OFL-ScheherazadeNew.txt`.
  Reserved Font Names are "Scheherazade" and "SIL"; the font file
  itself is unmodified (only the pubspec family name is
  `IndoPakQuran`, which does not alter the font).
- **Source:** official SIL release
  `https://github.com/silnrsi/font-scheherazade/releases/tag/v4.500`
  (`ScheherazadeNew-4.500.zip`).
- **Why this font — coverage check (fontTools, 2026-11-17):** of the
  74 distinct codepoints the IndoPak text uses, Scheherazade New
  covers **all 74**, including U+06BE, U+06D2, U+06CC, U+0670 and
  the hair space / word joiner. It has GSUB + GPOS tables for
  correct Arabic shaping.
- **Fonts considered and rejected:**
  - **AlQalam / Al Qalam Quran Majeed — REJECTED on licence.** The
    AlQalam faces are "© Attari Qadri, Faisalabad, Pakistan, 2010.
    All Rights Reserved"; AlQalam Tafseer carries fsType 6
    (restricted embedding) and the font-licence aggregators flag
    "embedding is restricted — review the source license before
    commercial use". No clear licence permits redistribution inside
    an app, so it was not used.
  - **DigitalKhatt IndoPak** (DigitalKhatt/indopakfont, SIL OFL 1.1
    — a genuine IndoPak face) — **REJECTED on coverage.** It lacks
    13 of the 74 codepoints the Tanzil text needs, including the two
    most common IndoPak markers: U+06CC Farsi yeh (22,024 uses) and
    U+06E1 dotless-khah sukun (37,372 uses). It is built for the
    DigitalKhatt/QuranWBW text encoding, not Tanzil's, and would
    render tofu for every ی and ۡ.
  - **Noto Naskh Arabic** (SIL OFL 1.1) — acceptable backup: covers
    72 of 74 (lacks only the invisible U+200A/U+2060 formatting
    characters, which are harmless). Kept as the fallback if
    Scheherazade New ever proves unsuitable on-device.
  - The bundled **Amiri Quran** font also covers the IndoPak text
    (72 of 74 — lacks only U+2060), so even a font fallback would
    render the text; Scheherazade New was chosen for full coverage
    and its Quran-specific design.

## Page breaks: `assets/quran/quran_indopak_pages.json`

- **Dataset FOUND and bundled — no known-limit fallback needed.**
  The IndoPak 15-line (Qudratullah) print, **610 pages**, 15 lines
  per page, from the Quranic Universal Library (QUL) by Tarteel:
  `https://qul.tarteel.ai/mushaf_layouts/6` (layout "Indopak 15 lines
  - Qudratullah"). The 15-line print was chosen over the 16-line
  (548 pages) because every 15-line page ends on an ayah end, so
  page breaks are expressible as ayah ranges; most 16-line breaks
  fall mid-ayah.
- **Format:** `{"mushaf": "IndoPak 15-line (Qudratullah)",
  "linesPerPage": 15, "totalPages": 610, "source": "...",
  "pageRanges": [{"page": 1, "from": [1,1], "to": [1,7]}, ...]}`.
  No loader consumes this file yet — the parent wires it up.
- **Verification (2026-11-17, script + `test/indopak_test.dart`):**
  - 610 ranges, first page 1:1–1:7, last page 113:1–114:6.
  - Flattened, the ranges cover all 6,236 ayahs exactly once, in
    order, with no gaps and no duplicates.
  - Anchors cross-checked against independent published sources:
    2:255 (Ayat al-Kursi) on page 42; al-Mulk (67:1) opens page 562
    (matches Quran Loop's Qudratullah listing); juz 30 (78:1) opens
    page 586 (matches Her Quran Academy's para-30 range 586–610);
    juz 2 (2:142) opens page 22 (matches para 1 = 21 pages).
  - Cross-checked against QUL's other 610-page 15-line layout
    ("QPC Hafs Nastaleeq", layout 14): the two agree on 609 of 610
    pages; the single difference is layout 14's page 137, which
    starts at 6:73 — but 6:73 is already the last ayah of its page
    136, so layout 14 double-counts 6:73 (6,237 covered, 6,236
    unique). That is a data error in layout 14, and one more reason
    the Qudratullah layout (exact 6,236 coverage) was chosen.
  - One published source disagrees on one anchor: the Quran
    Foundation Page Layout API docs say 2:255 is on page 44 of
    their "IndoPak 15-line (mushaf 6)". Both QUL 610-page layouts
    put it on page 42 (page 42 is 2:253–2:256, and juz 3 starts on
    that page at 2:253). The QF docs' figure could not be verified
    — their API needs an x-auth-token/x-client-id account, which
    this task did not set up — so the QUL figure stands, and the
    discrepancy is recorded here rather than resolved.
  - Note: 7 of the 30 juz do NOT start on a fresh page in this
    print (juz 4, 7, 11, 14, 20, 21, 23 start mid-page). Some
    publishers' descriptions claim every juz starts fresh; that
    claim does not hold for the Qudratullah layout as published
    by QUL.

## Settings row

`lib/screens/settings_screen.dart`, Appearance card, under the Theme
row: "Mushaf style" with a two-segment control (Madani / IndoPak),
wired to `appState.mushafStyle`. If the IndoPak text failed to load
(`QuranRepository.instance.indopakAvailable == false`) the control
is disabled and shows the note "IndoPak text not available". UI
strings are hardcoded English for now — the translation round
covers them later.

## Pubspec entries the parent must add

```yaml
  assets:
    - assets/quran/quran_indopak.json
    - assets/quran/quran_indopak_pages.json
    - assets/fonts/OFL-ScheherazadeNew.txt   # OFL licence text for the font

  fonts:
    - family: IndoPakQuran
      fonts:
        - asset: assets/fonts/IndoPakQuran-Regular.ttf
```

## Not verified locally

- **No on-device run.** The font's visual rendering (shaping, mark
  placement, line height in the reader) has only been checked by
  codepoint coverage, not by looking at it on a phone. The Settings
  row's appearance likewise needs an on-device look.
- **No `flutter build apk`** (Gradle download fails in this
  sandbox, per task instructions).
- The Quran Foundation API page-44 figure for 2:255 (see above)
  could not be checked — it needs API credentials.
- The repository-level test (`QuranRepository` loading the IndoPak
  asset) currently SKIPS until the pubspec asset entry is added;
  after that it runs for real.
