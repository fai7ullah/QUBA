import 'package:flutter/material.dart';

import '../content.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// The 99 Names of Allah: a searchable 3-column grid; tap a name to
/// see its meaning in a dialog.
class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<(int, AllahName)> get _filtered {
    final q = _query.trim().toLowerCase();
    final entries = [
      for (var i = 0; i < names99.length; i++) (i + 1, names99[i]),
    ];
    if (q.isEmpty) return entries;
    return entries
        .where((e) =>
            e.$2.transliteration.toLowerCase().contains(q) ||
            e.$2.meaning.toLowerCase().contains(q) ||
            tr('name_meaning_${e.$1}').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _showName(int number, AllahName name) async {
    final p = QubaPalette.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trf('name_of_99', {'n': number}),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: p.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.arabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 44,
                height: 1.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name.transliteration,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: p.emerald,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('name_meaning_$number'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: p.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

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
                  title: tr('names99'),
                  subtitle: tr('asma_ul_husna'),
                ),
                const SizedBox(height: 16),
                QubaSearchField(
                  controller: _controller,
                  hint: tr('search_names_hint'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Text(
                  _query.trim().isEmpty
                      ? trf('names_count', {'n': names99.length})
                      : trf('names_found', {'n': filtered.length}),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 44, color: p.muted),
                              const SizedBox(height: 12),
                              Text(
                                tr('no_names_found'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('try_different_spelling'),
                                style: TextStyle(
                                    fontSize: 14, color: p.muted),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.only(bottom: 28),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.92,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final number = filtered[i].$1;
                            final name = filtered[i].$2;
                            return GlassCard(
                              radius: 18,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 6),
                              onTap: () => _showName(number, name),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$number',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.gold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      name.arabic,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'AmiriQuran',
                                        fontSize: 22,
                                        height: 1.5,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name.transliteration,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: p.muted,
                                    ),
                                  ),
                                ],
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
}
