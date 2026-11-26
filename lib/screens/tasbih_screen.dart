import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Tasbih counter: six phrases, a big circular tap area with a
/// progress ring, selectable targets (33 / 100 / custom), and
/// per-phrase lifetime totals kept in app state.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  /// (totals key, Arabic, transliteration)
  static const List<(String, String, String)> _phrases = [
    ('subhanallah', 'سُبْحَانَ اللهِ', 'SubhanAllah'),
    ('alhamdulillah', 'الْحَمْدُ لِلَّهِ', 'Alhamdulillah'),
    ('allahuakbar', 'اللهُ أَكْبَرُ', 'Allahu Akbar'),
    ('astaghfirullah', 'أَسْتَغْفِرُ اللهَ', 'Astaghfirullah'),
    ('lailahaillallah', 'لَا إِلَهَ إِلَّا اللهُ', 'La ilaha illallah'),
    (
      'subhanallahiwabihamdihi',
      'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
      'SubhanAllahi wa bihamdihi',
    ),
  ];

  int _selected = 0;
  int _sessionCount = 0;

  void _tap() {
    final target = appState.tasbihTarget;
    final next = _sessionCount + 1;
    if (next == target || next % 33 == 0) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    appState.addTasbihTotal(_phrases[_selected].$1, 1);
    setState(() => _sessionCount = next);
  }

  void _selectPhrase(int i) {
    if (i == _selected) return;
    setState(() {
      _selected = i;
      _sessionCount = 0;
    });
  }

  void _setTarget(int target) {
    appState.update(() => appState.tasbihTarget = target);
  }

  Future<void> _customTargetDialog() async {
    final p = QubaPalette.of(context);
    final controller = TextEditingController(text: '${appState.tasbihTarget}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(tr('custom_target')),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: tr('target_hint'),
            labelText: tr('count_label'),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(int.tryParse(v.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text.trim())),
            child: Text(tr('set')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value >= 1 && value <= 10000) {
      _setTarget(value);
    } else if (value != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('target_range_error'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              final target = appState.tasbihTarget;
              final progress = target > 0
                  ? (_sessionCount / target).clamp(0.0, 1.0)
                  : 0.0;
              final reached = _sessionCount >= target && target > 0;
              final phrase = _phrases[_selected];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitleRow(
                      title: tr('tasbih'),
                      subtitle: tr('dhikr_counter'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < _phrases.length; i++)
                          _chip(
                            p,
                            _phrases[i].$3,
                            i == _selected,
                            () => _selectPhrase(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 264,
                            height: 264,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: p.cardBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                reached ? p.gold : p.emerald,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _tap,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: Container(
                                  width: 232,
                                  height: 232,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.cardFill,
                                    border: Border.all(
                                      color: p.cardBorder,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: p.shadow,
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          phrase.$2,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'AmiriQuran',
                                            fontSize: 27,
                                            height: 1.6,
                                            color: p.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_sessionCount',
                                        style: TextStyle(
                                          fontSize: 46,
                                          fontWeight: FontWeight.w800,
                                          color: p.emerald,
                                        ),
                                      ),
                                      Text(
                                        reached
                                            ? tr('target_reached')
                                            : trf('of_target_tap', {
                                                'n': target,
                                              }),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: reached ? p.gold : p.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(p, '33', target == 33, () => _setTarget(33)),
                        const SizedBox(width: 8),
                        _chip(p, '100', target == 100, () => _setTarget(100)),
                        const SizedBox(width: 8),
                        _chip(
                          p,
                          target != 33 && target != 100
                              ? trf('custom_n', {'n': target})
                              : tr('custom'),
                          target != 33 && target != 100,
                          _customTargetDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(tr('reset_session')),
                        onPressed: _sessionCount == 0
                            ? null
                            : () => setState(() => _sessionCount = 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionLabel(tr('lifetime_totals')),
                    const SizedBox(height: 10),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (var i = 0; i < _phrases.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: p.gold.withValues(alpha: 0.25),
                              ),
                            ListTile(
                              leading: Icon(
                                Icons.fingerprint_rounded,
                                color: i == _selected ? p.emerald : p.gold,
                              ),
                              title: Text(
                                _phrases[i].$3,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                              subtitle: Text(
                                _phrases[i].$2,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'AmiriQuran',
                                  fontSize: 16,
                                ),
                              ),
                              trailing: Text(
                                '${appState.tasbihTotals[_phrases[i].$1] ?? 0}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: p.emerald,
                                ),
                              ),
                              onTap: () => _selectPhrase(i),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chip(QubaPalette p, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? p.activeFill : p.cardFill,
          border: Border.all(color: selected ? p.gold : p.cardBorder, width: 1),
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
