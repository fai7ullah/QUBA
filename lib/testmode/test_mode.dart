import 'dart:math' as math;

/// Memorisation test mode — pure Dart session logic (no Flutter, no I/O).
/// The screen supplies the Arabic text of each ayah; this class owns the
/// masking, the scoring and the navigation through the chosen range.
///
/// Two modes:
/// * [TestMode.hideWords] — a fraction of each ayah's words are masked.
///   For every masked word the user taps "I knew it" (recalled) or
///   "Reveal" (not recalled). Score = knew / answered.
/// * [TestMode.nextAyah] — ayah N is shown, ayah N+1 is hidden. The user
///   taps "Show answer", then marks themself correct or wrong.
///   Score = correct / answered.
///
/// Masking is deterministic per ayah (seeded Random on surah + ayah), so
/// a session is stable across rebuilds: the same ayah always hides the
/// same words.
enum TestMode { hideWords, nextAyah }

/// What the user did with one masked word: recalled it, or had to reveal it.
enum WordMark { knew, revealed }

class TestSession {
  TestSession({
    required this.surah,
    required this.startAyah,
    required this.endAyah,
    this.mode = TestMode.hideWords,
    this.maskFraction = 0.4,
  })  : assert(startAyah >= 1),
        assert(endAyah >= startAyah);

  final int surah;
  final int startAyah;
  final int endAyah;
  final TestMode mode;

  /// Fraction of each ayah's words to mask (hideWords mode only).
  final double maskFraction;

  int _index = 0;

  /// ayah -> (word index -> mark). Only the FIRST mark per word counts:
  /// a revealed word can never later be marked "knew".
  final Map<int, Map<int, WordMark>> _wordMarks = {};

  /// ayah -> masked word indices, cached per ayah (the text of an ayah
  /// never changes inside a session, so the cache is safe).
  final Map<int, List<int>> _maskedCache = {};
  final Map<int, int> _maskedWordCount = {};

  /// nextAyah mode: ayah -> true when the user marked themself correct.
  final Map<int, bool> _nextAyahMarks = {};

  bool _answerShown = false;

  // ------------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------------

  int get currentAyah => startAyah + _index;
  int get totalAyahs => endAyah - startAyah + 1;
  int get position => _index + 1;
  double get progress => totalAyahs <= 0 ? 0 : position / totalAyahs;
  bool get isFirst => _index == 0;
  bool get isLast => _index == totalAyahs - 1;

  /// Move to the next ayah. Returns false at the end of the range.
  bool next() {
    if (isLast) return false;
    _index++;
    _answerShown = false;
    return true;
  }

  /// Move to the previous ayah. Returns false at the start of the range.
  bool previous() {
    if (isFirst) return false;
    _index--;
    _answerShown = false;
    return true;
  }

  /// Restart the session from the first ayah, clearing all marks.
  void reset() {
    _index = 0;
    _wordMarks.clear();
    _nextAyahMarks.clear();
    _answerShown = false;
  }

  // ------------------------------------------------------------------
  // hideWords
  // ------------------------------------------------------------------

  static List<String> splitWords(String arabic) => arabic
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  /// Masked word indices for one ayah, sorted ascending. Deterministic:
  /// the seed depends only on surah + ayah, so the same ayah always
  /// hides the same words. At least one word always stays visible (for
  /// context) unless the ayah is a single word, in which case nothing
  /// is masked.
  List<int> maskedIndices(int ayah, String arabic) {
    final words = splitWords(arabic);
    final cached = _maskedCache[ayah];
    if (cached != null && _maskedWordCount[ayah] == words.length) {
      return cached;
    }
    final indices = List<int>.generate(words.length, (i) => i);
    final seed = surah * 1000003 + ayah * 9176 + 12345;
    indices.shuffle(math.Random(seed));
    var count = (words.length * maskFraction).ceil();
    if (words.length > 1) {
      count = count.clamp(1, words.length - 1);
    } else {
      count = 0;
    }
    final masked = indices.take(count).toList()..sort();
    _maskedCache[ayah] = masked;
    _maskedWordCount[ayah] = words.length;
    return masked;
  }

  bool isMasked(int ayah, String arabic, int wordIndex) =>
      maskedIndices(ayah, arabic).contains(wordIndex);

  WordMark? markOf(int ayah, int wordIndex) =>
      _wordMarks[ayah]?[wordIndex];

  /// Record that the user recalled the word. Ignored if the word was
  /// already marked (a revealed word can never become "knew").
  void markKnew(int ayah, int wordIndex) {
    final marks = _wordMarks.putIfAbsent(ayah, () => {});
    marks.putIfAbsent(wordIndex, () => WordMark.knew);
  }

  /// Record that the user had to reveal the word. Ignored if the word
  /// was already marked.
  void revealWord(int ayah, int wordIndex) {
    final marks = _wordMarks.putIfAbsent(ayah, () => {});
    marks.putIfAbsent(wordIndex, () => WordMark.revealed);
  }

  int get knewCount => _wordMarks.values
      .expand((m) => m.values)
      .where((v) => v == WordMark.knew)
      .length;

  int get revealedCount => _wordMarks.values
      .expand((m) => m.values)
      .where((v) => v == WordMark.revealed)
      .length;

  int get wordsAnswered => knewCount + revealedCount;

  double get wordsScore =>
      wordsAnswered == 0 ? 0 : knewCount / wordsAnswered;

  // ------------------------------------------------------------------
  // nextAyah
  // ------------------------------------------------------------------

  bool get answerShown => _answerShown;

  void showAnswer() => _answerShown = true;

  /// Mark the current ayah's recall correct/wrong. Only the first mark
  /// per ayah counts.
  void markNextAyah(bool correct) {
    _nextAyahMarks.putIfAbsent(currentAyah, () => correct);
  }

  bool? nextAyahMark(int ayah) => _nextAyahMarks[ayah];

  int get nextCorrectCount =>
      _nextAyahMarks.values.where((v) => v).length;

  int get nextWrongCount =>
      _nextAyahMarks.values.where((v) => !v).length;

  int get nextAyahAnswered => _nextAyahMarks.length;

  double get nextAyahScore =>
      nextAyahAnswered == 0 ? 0 : nextCorrectCount / nextAyahAnswered;

  // ------------------------------------------------------------------
  // Unified score (follows the session's mode)
  // ------------------------------------------------------------------

  int get correctCount =>
      mode == TestMode.hideWords ? knewCount : nextCorrectCount;

  int get wrongCount =>
      mode == TestMode.hideWords ? revealedCount : nextWrongCount;

  int get answeredCount =>
      mode == TestMode.hideWords ? wordsAnswered : nextAyahAnswered;

  double get score =>
      answeredCount == 0 ? 0 : correctCount / answeredCount;
}
