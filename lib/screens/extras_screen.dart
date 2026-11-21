import 'package:flutter/material.dart';

import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Extras tab (Round 4, 2026-11-21): the fifth bottom tab, between Quran
/// and Settings. It holds every extra tool in one place — the six
/// everyday tools (Qibla, Tasbih, Duas, 99 Names, Khatma, Calendar) and
/// all Phase 2 features (Hadith, Tafsir, test mode, Ramadan, home
/// widget, cloud sync). Phase 2 features live here, never as their own
/// bottom tabs.
///
/// Word-by-word is NOT listed: no licensed word data exists to ship
/// (phase 2, 2026-11-21 — see TRANSLATIONS.md). Its screen, repository
/// and i18n keys stay in the tree; restore the tile below (and the
/// reader button) the moment a licensed wordbyword.json lands.
///
/// Taps go through [onOpenFeature] with the same keys main.dart's
/// _featureScreen switch understands.
class ExtrasScreen extends StatelessWidget {
  const ExtrasScreen({super.key, required this.onOpenFeature});
  final void Function(String key) onOpenFeature;

  static const _tiles = [
    (Icons.explore_rounded, 'qibla', 'qibla'),
    (Icons.blur_circular_rounded, 'tasbih', 'tasbih'),
    (Icons.volunteer_activism_rounded, 'duas', 'duas'),
    (Icons.auto_awesome_rounded, 'names99', 'names'),
    (Icons.flag_rounded, 'khatma', 'khatma'),
    (Icons.calendar_month_rounded, 'calendar', 'calendar'),
    (Icons.library_books_rounded, 'hadith', 'hadith'),
    (Icons.text_snippet_rounded, 'tafsir', 'tafsir'),
    // Word-by-word tile hidden: no licensed word data (phase 2).
    // Restore when wordbyword.json ships:
    // (Icons.spellcheck_rounded, 'word_by_word', 'wbw'),
    (Icons.quiz_rounded, 'test_mode', 'testmode'),
    (Icons.nightlight_round_rounded, 'ramadan_mode', 'ramadan'),
    (Icons.widgets_rounded, 'home_widget', 'widget'),
    (Icons.cloud_sync_rounded, 'cloud_sync', 'sync'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
      children: [
        Text(
          tr('extras'),
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('extras_subtitle'),
          style: TextStyle(fontSize: 14, color: p.muted),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final t in _tiles)
              GlassCard(
                radius: 22,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                onTap: () => onOpenFeature(t.$3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$1, size: 30, color: p.emerald),
                    const SizedBox(height: 10),
                    // Labels wrap to two lines max; long translations
                    // (e.g. Arabic) ellipsize instead of overflowing.
                    Text(
                      tr(t.$2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
