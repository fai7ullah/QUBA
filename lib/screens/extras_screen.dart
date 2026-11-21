import 'package:flutter/material.dart';

import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Extras tab (Round 4, 2026-11-21): the fifth bottom tab, between Quran
/// and Settings. It holds every extra tool in one place — the six
/// everyday tools (Qibla, Tasbih, Duas, 99 Names, Khatma, Calendar) and
/// all Phase 2 features (Hadith, Tafsir, test mode, Ramadan, home
/// widget). Phase 2 features live here, never as their own bottom tabs.
///
/// LAYOUT (redesigned 2026-11-21, owner's words: "All the cards should
/// be one size and like in a list... It should be like a professional
/// good looking"): a clean vertical LIST of UNIFORM rows — every row
/// exactly the same height, same padding, same alignment. NO grid, NO
/// mixed sizes, NO featured rows. Each row: tinted icon in a fixed
/// 44x44 rounded square, title + one short description line, chevron.
/// Rows are grouped into sections (Everyday Tools / Study / More),
/// one GlassCard per section, thin dividers between rows.
///
/// Cloud sync was REMOVED (2026-11-21, owner's order) — there is no
/// sync tile anymore. Word-by-word is NOT listed: no licensed word
/// data exists to ship (phase 2, 2026-11-21 — see TRANSLATIONS.md).
/// Its screen, repository and i18n keys stay in the tree; restore the
/// row below (and the reader button) the moment a licensed
/// wordbyword.json lands.
///
/// Taps go through [onOpenFeature] with the same keys main.dart's
/// _featureScreen switch understands.
class ExtrasScreen extends StatelessWidget {
  const ExtrasScreen({super.key, required this.onOpenFeature});
  final void Function(String key) onOpenFeature;

  /// (icon, label key, description key, tint colour, feature key).
  /// One entry per row; every row renders identically.
  static const _rows = [
    // Everyday Tools
    (Icons.explore_rounded, 'qibla', 'qibla_desc',
        Color(0xFF075B43), 'qibla'),
    (Icons.blur_circular_rounded, 'tasbih', 'tasbih_desc',
        Color(0xFF7B1FA2), 'tasbih'),
    (Icons.volunteer_activism_rounded, 'duas', 'duas_desc',
        Color(0xFFC9A45C), 'duas'),
    (Icons.auto_awesome_rounded, 'names99', 'names99_desc',
        Color(0xFF1565C0), 'names'),
    (Icons.flag_rounded, 'khatma', 'khatma_desc', Color(0xFFEF6C00),
        'khatma'),
    (Icons.calendar_month_rounded, 'calendar', 'calendar_desc',
        Color(0xFF00838F), 'calendar'),
    // Study
    (Icons.library_books_rounded, 'hadith', 'hadith_desc',
        Color(0xFF6D4C41), 'hadith'),
    (Icons.text_snippet_rounded, 'tafsir', 'tafsir_desc',
        Color(0xFF2E7D32), 'tafsir'),
    // Word-by-word row hidden: no licensed word data (phase 2).
    // Restore when wordbyword.json ships:
    // (Icons.spellcheck_rounded, 'word_by_word', 'word_by_word_desc',
    //     Color(0xFF5D4037), 'wbw'),
    (Icons.quiz_rounded, 'test_mode', 'test_mode_desc',
        Color(0xFFC2185B), 'testmode'),
    // More
    (Icons.nightlight_round_rounded, 'ramadan_mode', 'ramadan_mode_desc',
        Color(0xFF283593), 'ramadan'),
    (Icons.widgets_rounded, 'home_widget', 'home_widget_desc',
        Color(0xFF546E7A), 'widget'),
  ];

  /// Row index ranges per section (into [_rows]).
  static const _sections = [
    ('extras_everyday', 0, 6),
    ('extras_study', 6, 9),
    ('extras_more', 9, 11),
  ];

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return ListView(
      // NOT primary: see home_screen.dart — each tab owns its scroll
      // state instead of sharing the route's PrimaryScrollController.
      primary: false,
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
        for (final s in _sections) ...[
          const SizedBox(height: 22),
          SectionLabel(tr(s.$1)),
          const SizedBox(height: 8),
          GlassCard(
            radius: 22,
            padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Column(
              children: [
                for (var i = s.$2; i < s.$3; i++) ...[
                  if (i > s.$2)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: p.gold.withValues(alpha: 0.22),
                    ),
                  _row(context, _rows[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// One uniform menu row: fixed 64px height, tinted 44x44 icon
  /// square, title + one-line description, chevron. Title and
  /// description ellipsize — long translations (e.g. Arabic) clip
  /// gracefully instead of overflowing or going vertical.
  Widget _row(
    BuildContext context,
    (IconData, String, String, Color, String) row,
  ) {
    final p = QubaPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onOpenFeature(row.$5),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: row.$4.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(row.$1, size: 24, color: row.$4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(row.$2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(row.$3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
