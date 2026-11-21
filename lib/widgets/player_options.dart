import 'package:flutter/material.dart';

import '../app_state.dart';
import '../audio.dart';
import '../data.dart';
import '../i18n.dart';
import '../reciters.dart';
import '../theme.dart';

/// Player options bottom sheet: reciter, verse repeat (memorisation),
/// repeat a range of verses, and the sleep timer. Opened from the reader
/// mini-player and the mushaf top bar while audio plays (reciter and
/// sleep timer are also usable with nothing playing).
Future<void> showPlayerOptionsSheet(BuildContext context) {
  final audio = AudioService.instance;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _PlayerOptionsSheet(audio: audio),
  );
}

class _PlayerOptionsSheet extends StatefulWidget {
  const _PlayerOptionsSheet({required this.audio});
  final AudioService audio;

  @override
  State<_PlayerOptionsSheet> createState() => _PlayerOptionsSheetState();
}

class _PlayerOptionsSheetState extends State<_PlayerOptionsSheet> {
  late int _rangeFrom;
  late int _rangeTo;

  @override
  void initState() {
    super.initState();
    final audio = widget.audio;
    final range = audio.repeatRange.value;
    final ayah = audio.currentAyah.value ?? 1;
    _rangeFrom = range?.$1 ?? ayah;
    _rangeTo = range?.$2 ?? ayah;
  }

  String _mmss(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final audio = widget.audio;
    final surah = audio.currentSurah.value;
    final ayahCount = surah == null
        ? 0
        : QuranRepository.instance.surah(surah).ayahCount;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading(context, p, Icons.record_voice_over_rounded,
                    tr('reciter')),
                ...reciters.map((r) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr(r.nameKey)),
                      value: r.id,
                      groupValue: appState.reciterId,
                      onChanged: (v) {
                        if (v != null) appState.setReciter(v);
                      },
                    )),
                const Divider(height: 20),
                _heading(context, p, Icons.repeat_rounded,
                    tr('repeat_verse')),
                const SizedBox(height: 8),
                ValueListenableBuilder<VerseRepeatMode>(
                  valueListenable: audio.repeatMode,
                  builder: (context, mode, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context, p, tr('repeat_off'),
                          mode == VerseRepeatMode.off,
                          () => audio.setVerseRepeatMode(VerseRepeatMode.off)),
                      _chip(context, p, tr('repeat_1x'),
                          mode == VerseRepeatMode.once,
                          () => audio.setVerseRepeatMode(VerseRepeatMode.once)),
                      _chip(context, p, tr('repeat_3x'),
                          mode == VerseRepeatMode.three,
                          () => audio.setVerseRepeatMode(VerseRepeatMode.three)),
                      _chip(context, p, tr('repeat_5x'),
                          mode == VerseRepeatMode.five,
                          () => audio.setVerseRepeatMode(VerseRepeatMode.five)),
                      _chip(context, p, tr('repeat_loop'),
                          mode == VerseRepeatMode.loop,
                          () => audio.setVerseRepeatMode(VerseRepeatMode.loop)),
                    ],
                  ),
                ),
                if (surah != null) ...[
                  const SizedBox(height: 16),
                  _heading(context, p, Icons.repeat_on_rounded,
                      tr('repeat_range')),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<(int, int)?>(
                    valueListenable: audio.repeatRange,
                    // Steppers on their own row, the button full-width
                    // below: the two steppers (2 x ~116px) plus the
                    // button (min 64px + a long label like Arabic
                    // "تكرار مجموعة آيات") overflowed a single Row at
                    // every phone width (352px needed in 280px at
                    // 320px screens) — the squeeze defect class.
                    builder: (context, range, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            _stepper(
                              context,
                              p,
                              label: tr('range_from'),
                              value: _rangeFrom,
                              min: 1,
                              max: ayahCount,
                              onChanged: (v) =>
                                  setState(() => _rangeFrom = v),
                            ),
                            const SizedBox(width: 12),
                            _stepper(
                              context,
                              p,
                              label: tr('range_to'),
                              value: _rangeTo,
                              min: 1,
                              max: ayahCount,
                              onChanged: (v) =>
                                  setState(() => _rangeTo = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            audio.setRepeatRange(_rangeFrom, _rangeTo);
                            setState(() {});
                          },
                          child: Text(
                            range == null ? tr('repeat_range') : tr('save'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (audio.repeatRange.value != null)
                    TextButton(
                      onPressed: () {
                        audio.clearRepeatRange();
                        setState(() {});
                      },
                      child: Text(tr('repeat_range_clear')),
                    ),
                ],
                const Divider(height: 20),
                _heading(
                    context, p, Icons.bedtime_rounded, tr('sleep_timer')),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: audio.sleepSecondsLeft,
                  builder: (context, left, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context, p, tr('sleep_off'), left == 0,
                          () => audio.cancelSleepTimer()),
                      _chip(context, p, tr('sleep_5'), false,
                          () => audio.setSleepTimer(
                              const Duration(minutes: 5))),
                      _chip(context, p, tr('sleep_10'), false,
                          () => audio.setSleepTimer(
                              const Duration(minutes: 10))),
                      _chip(context, p, tr('sleep_15'), false,
                          () => audio.setSleepTimer(
                              const Duration(minutes: 15))),
                      _chip(context, p, tr('sleep_30'), false,
                          () => audio.setSleepTimer(
                              const Duration(minutes: 30))),
                      _chip(context, p, tr('sleep_60'), false,
                          () => audio.setSleepTimer(
                              const Duration(minutes: 60))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<bool>(
                  valueListenable: audio.sleepEndOfSurah,
                  builder: (context, endOfSurah, _) => Row(
                    children: [
                      Expanded(child: Text(tr('sleep_end_surah'))),
                      Switch(
                        value: endOfSurah,
                        onChanged: (v) => audio.setSleepEndOfSurah(v),
                      ),
                    ],
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: audio.sleepSecondsLeft,
                  builder: (context, left, _) {
                    if (left <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${tr('sleep_timer_set')} — ${_mmss(left)}',
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(
      BuildContext context, QubaPalette p, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: p.emerald),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, QubaPalette p, String label,
      bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: p.emerald.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? p.emerald : p.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _stepper(
    BuildContext context,
    QubaPalette p, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: p.muted)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: p.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tightened to 40px (like the mini-player buttons) so
              // two steppers fit side by side at 320px screens.
              // shrinkWrap is required: without it Material 3 pads
              // the button back to the 48px tap target and the
              // constraints do nothing (see the mini-player note).
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 40, minHeight: 40),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 40, minHeight: 40),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
