import 'package:flutter/material.dart';

import '../content.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Duas library: filter by category, tap a card to expand it and read
/// the transliteration, English meaning and source. Quran-sourced duas
/// load their Arabic from the verified bundled Quran text.
class DuasScreen extends StatefulWidget {
  const DuasScreen({super.key});

  @override
  State<DuasScreen> createState() => _DuasScreenState();
}

class _DuasScreenState extends State<DuasScreen> {
  String _category = 'All';
  Dua? _expanded;

  List<Dua> get _filtered => _category == 'All'
      ? duas
      : duas.where((d) => d.category == _category).toList();

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final filtered = _filtered;

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleRow(
                  title: tr('duas'),
                  subtitle: '${duas.length} duas with sources',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in duaCategories)
                      _chip(p, c, c == _category),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _category == 'All'
                      ? '${filtered.length} duas'
                      : '${filtered.length} duas in $_category',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 28),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final dua = filtered[i];
                      final expanded = _expanded == dua;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          onTap: () => setState(() =>
                              _expanded = expanded ? null : dua),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dua.title,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    expanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: p.muted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dua.category,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.emerald,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                duaArabic(dua),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 24,
                                  height: 1.9,
                                  color: p.ink,
                                ),
                              ),
                              if (expanded) ...[
                                const SizedBox(height: 14),
                                GoldDivider(),
                                const SizedBox(height: 14),
                                Text(
                                  dua.transliteration,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontStyle: FontStyle.italic,
                                    color: p.ink,
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  dua.english,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: p.muted,
                                    height: 1.55,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.book_rounded,
                                        size: 16, color: p.gold),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        dua.source,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: p.gold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  dua.source,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(QubaPalette p, String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() {
        _category = label;
        _expanded = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? p.activeFill : p.cardFill,
          border: Border.all(
            color: selected ? p.gold : p.cardBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? p.activeText : p.ink,
          ),
        ),
      ),
    );
  }
}
