import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../i18n.dart';
import '../testmode/test_mode.dart';
import '../theme.dart';
import '../widgets.dart';

/// Memorisation test mode: pick a surah + ayah range + mode, then quiz
/// yourself. Two modes (see lib/testmode/test_mode.dart):
/// * Hide words — masked words are tappable chips; tap one, then say
///   whether you knew it or reveal it.
/// * Next ayah — recall the next ayah, show the answer, mark yourself.
class TestModeScreen extends StatefulWidget {
  const TestModeScreen({super.key});

  @override
  State<TestModeScreen> createState() => _TestModeScreenState();
}

class _TestModeScreenState extends State<TestModeScreen> {
  final _startController = TextEditingController(text: '1');
  final _endController = TextEditingController(text: '7');
  int _surah = 1;
  TestMode _mode = TestMode.hideWords;

  TestSession? _session;
  bool _finished = false;

  /// Word index of the masked word the user tapped (hideWords mode),
  /// awaiting a "Knew it" / "Reveal" choice. -1 = none selected.
  int _selectedWord = -1;

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Surah get _surahData => QuranRepository.instance.surah(_surah);

  String _arabicOf(int ayah) =>
      QuranRepository.instance.arabicText(_surah, ayah);

  void _start() {
    final repo = QuranRepository.instance;
    if (!repo.loaded) return;
    final count = _surahData.ayahCount;
    final start = int.tryParse(_startController.text.trim()) ?? -1;
    var end = int.tryParse(_endController.text.trim()) ?? -1;
    if (start < 1 || end < 1 || start > count || end > count || start > end) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('test_range_error'))));
      return;
    }
    if (_mode == TestMode.nextAyah) {
      // The last ayah of a surah has no next ayah to recall.
      end = end > count - 1 ? count - 1 : end;
      if (start > end) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('test_no_next_ayah'))));
        return;
      }
    }
    setState(() {
      _session = TestSession(
        surah: _surah,
        startAyah: start,
        endAyah: end,
        mode: _mode,
      );
      _finished = false;
      _selectedWord = -1;
    });
  }

  void _backToSetup() {
    setState(() {
      _session = null;
      _finished = false;
      _selectedWord = -1;
    });
  }

  void _retry() {
    setState(() {
      _session?.reset();
      _finished = false;
      _selectedWord = -1;
    });
  }

  void _nextAyah() {
    final session = _session;
    if (session == null) return;
    setState(() {
      _selectedWord = -1;
      if (!session.next()) _finished = true;
    });
  }

  void _previousAyah() {
    final session = _session;
    if (session == null) return;
    setState(() {
      _selectedWord = -1;
      session.previous();
    });
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
              if (!QuranRepository.instance.loaded) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitleRow(
                      title: tr('test_title'),
                      subtitle: tr('test_subtitle'),
                    ),
                    const SizedBox(height: 16),
                    if (_session == null)
                      _setup(p)
                    else if (_finished)
                      _summary(p)
                    else
                      _quiz(p),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Setup
  // ------------------------------------------------------------------

  Widget _setup(QubaPalette p) {
    final surahs = QuranRepository.instance.surahs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(tr('test_choose_surah')),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButton<int>(
            value: _surah,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final s in surahs)
                DropdownMenuItem(
                  value: s.number,
                  child: Text(
                    '${s.number}. ${s.nameEnglish}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.ink),
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              final count = QuranRepository.instance.surah(v).ayahCount;
              setState(() {
                _surah = v;
                _startController.text = '1';
                _endController.text = '$count';
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _numberField(
                p,
                label: tr('test_start_ayah'),
                controller: _startController,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _numberField(
                p,
                label: tr('test_end_ayah'),
                controller: _endController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionLabel(tr('test_mode_type')),
        const SizedBox(height: 8),
        _modeCard(
          p,
          mode: TestMode.hideWords,
          icon: Icons.visibility_off_rounded,
          title: tr('test_mode_hide_words'),
          desc: tr('test_mode_hide_words_desc'),
        ),
        const SizedBox(height: 10),
        _modeCard(
          p,
          mode: TestMode.nextAyah,
          icon: Icons.skip_next_rounded,
          title: tr('test_mode_next_ayah'),
          desc: tr('test_mode_next_ayah_desc'),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(tr('test_start')),
          style: FilledButton.styleFrom(
            backgroundColor: p.emerald,
            foregroundColor: p.onEmerald,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(
    QubaPalette p, {
    required String label,
    required TextEditingController controller,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard(
    QubaPalette p, {
    required TestMode mode,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final selected = _mode == mode;
    return GlassCard(
      onTap: () => setState(() => _mode = mode),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? p.emerald : p.activeFill,
            ),
            child: Icon(icon, color: selected ? p.onEmerald : p.emerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 13, color: p.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? p.emerald : p.muted,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Quiz
  // ------------------------------------------------------------------

  Widget _quiz(QubaPalette p) {
    final session = _session!;
    final surah = _surahData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trf('test_progress', {
                  'current': session.position,
                  'total': session.totalAyahs,
                }),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${tr('test_score')}: ${session.correctCount}/${session.answeredCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: p.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: session.progress,
            minHeight: 8,
            backgroundColor: p.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(p.emerald),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${surah.number}. ${surah.nameEnglish} — ${session.currentAyah}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 10),
        if (session.mode == TestMode.hideWords)
          _hideWordsCard(p, session)
        else
          _nextAyahCard(p, session),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: session.isFirst ? null : _previousAyah,
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(
                  tr('test_previous'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _nextAyah,
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(
                  tr('test_next'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: p.emerald,
                  foregroundColor: p.onEmerald,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _backToSetup,
            child: Text(tr('test_change_setup')),
          ),
        ),
      ],
    );
  }

  Widget _hideWordsCard(QubaPalette p, TestSession session) {
    final ayah = session.currentAyah;
    final arabic = _arabicOf(ayah);
    final words = TestSession.splitWords(arabic);
    final masked = session.maskedIndices(ayah, arabic);
    final selectedMark = _selectedWord >= 0
        ? session.markOf(ayah, _selectedWord)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < words.length; i++)
                      _wordChip(
                        p,
                        session,
                        ayah,
                        words[i],
                        i,
                        masked.contains(i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('test_tap_hidden'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
            ],
          ),
        ),
        // "Knew it" / "Reveal" for the selected masked word.
        if (_selectedWord >= 0 && selectedMark == null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      session.markKnew(ayah, _selectedWord);
                      _selectedWord = -1;
                    });
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    tr('test_knew_it'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.emerald,
                    foregroundColor: p.onEmerald,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      session.revealWord(ayah, _selectedWord);
                      _selectedWord = -1;
                    });
                  },
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(
                    tr('test_reveal'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _wordChip(
    QubaPalette p,
    TestSession session,
    int ayah,
    String word,
    int index,
    bool masked,
  ) {
    final mark = masked ? session.markOf(ayah, index) : null;
    final selected = _selectedWord == index;
    final hidden = masked && mark == null;
    final Color bg;
    final Color fg;
    if (hidden) {
      bg = selected ? p.gold : p.activeFill;
      fg = selected ? p.onEmerald : p.emerald;
    } else if (mark == WordMark.knew) {
      bg = p.activeFill;
      fg = p.emerald;
    } else if (mark == WordMark.revealed) {
      bg = p.cardFill;
      fg = p.muted;
    } else {
      bg = Colors.transparent;
      fg = p.ink;
    }
    return GestureDetector(
      onTap: hidden ? () => setState(() => _selectedWord = index) : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: hidden ? 6 : 2,
          horizontal: hidden ? 12 : 2,
        ),
        decoration: hidden || mark != null
            ? BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: selected ? Border.all(color: p.gold, width: 2) : null,
              )
            : null,
        child: Text(
          hidden ? '• • •' : word,
          style: TextStyle(
            fontFamily: hidden
                ? null
                : QuranRepository.instance.arabicFontFamily,
            fontSize: hidden ? 16 : 24,
            fontWeight: hidden ? FontWeight.w800 : FontWeight.normal,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _nextAyahCard(QubaPalette p, TestSession session) {
    final ayah = session.currentAyah;
    final mark = session.nextAyahMark(ayah);
    final showAnswer = session.answerShown || mark != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Text(
            _arabicOf(ayah),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: QuranRepository.instance.arabicFontFamily,
              fontSize: 26,
              height: 1.9,
              color: p.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('test_recall_next'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              if (!showAnswer)
                FilledButton.icon(
                  onPressed: () => setState(session.showAnswer),
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(
                    tr('test_show_answer'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.emerald,
                    foregroundColor: p.onEmerald,
                  ),
                )
              else ...[
                Text(
                  _arabicOf(ayah + 1),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: QuranRepository.instance.arabicFontFamily,
                    fontSize: 26,
                    height: 1.9,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 12),
                if (mark == null)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              setState(() => session.markNextAyah(true)),
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            tr('test_correct'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: p.emerald,
                            foregroundColor: p.onEmerald,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => session.markNextAyah(false)),
                          icon: const Icon(Icons.close_rounded),
                          label: Text(
                            tr('test_wrong'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    mark ? tr('test_correct') : tr('test_wrong'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: mark ? p.emerald : p.gold,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Summary
  // ------------------------------------------------------------------

  Widget _summary(QubaPalette p) {
    final session = _session!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Column(
            children: [
              Icon(Icons.emoji_events_rounded, size: 56, color: p.gold),
              const SizedBox(height: 12),
              Text(
                tr('test_finished'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trf('test_finished_score', {
                  'score': session.correctCount,
                  'total': session.answeredCount,
                }),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: p.muted),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: session.score,
                  minHeight: 10,
                  backgroundColor: p.cardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(p.emerald),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.replay_rounded),
          label: Text(tr('test_try_again')),
          style: FilledButton.styleFrom(
            backgroundColor: p.emerald,
            foregroundColor: p.onEmerald,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _backToSetup,
          child: Text(tr('test_change_setup')),
        ),
      ],
    );
  }
}
