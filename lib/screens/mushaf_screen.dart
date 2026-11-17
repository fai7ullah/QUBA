import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../audio.dart';
import '../data.dart';
import '../i18n.dart';
import '../juz_data.dart';
import '../mushaf_data.dart';
import '../theme.dart';
import '../widgets.dart';

/// Mushaf-page reader: the true Madani 604-page layout (or the IndoPak
/// 15-line 610-page layout when the user's Mushaf style is IndoPak),
/// matching the reference screenshots — ornate gold surah banner,
/// centered Basmala, continuous justified Arabic with gold ayah-end
/// medallions, and a bottom bar with the page number + "Hizb N"
/// alternating sides by odd/even page.
///
/// Opened from a Juz row: `MushafScreen(initialPage: pageOfJuz(juz))`.
/// The Surah rows keep opening the per-ayah card reader
/// ([ReaderScreen]); this screen is juz-reading only.
///
/// Arabic text always comes from [QuranRepository.arabicText] (never
/// [Ayah.arabic] directly) so the Madani/IndoPak style switch changes
/// both the text and the pagination together.

// ---------------------------------------------------------------------------
// Layout constants (shared with the fit measurement in mushaf_test.dart).
// ---------------------------------------------------------------------------

/// Font-size search for the auto-fit: largest first, 1sp steps.
const double kMushafMaxFontSize = 30;
const double kMushafMinFontSize = 18;

/// Arabic line-height multiplier (Amiri's tall glyphs + the medallions,
/// which at 1.45x the text size fit inside a 1.6x line box).
const double kMushafLineHeight = 1.6;

/// Medallion size relative to the text size (native MushafArt: 1.45x).
const double kMushafMedallionScale = 1.45;

/// Gold surah banner height (native: 64dp).
const double kMushafBannerHeight = 64;

/// Gaps inside a page, in logical pixels.
const double kMushafGapAfterBanner = 10;
const double kMushafGapAfterBasmala = 8;
const double kMushafGapBeforeBanner = 16; // mid-page surah start

/// Page chrome: horizontal padding each side, vertical padding each
/// side, the grey surah-name line, and the bottom bar.
const double kMushafPagePadding = 24;
const double kMushafPageVerticalPadding = 12;
const double kMushafLabelHeight = 24;
const double kMushafBottomBarHeight = 36;

/// Top bar height (back + title + bookmark), below the SafeArea.
const double kMushafTopBarHeight = 56;

/// Assumed phone for the fit measurement (see mushaf_test.dart):
/// 390x844 logical, 44pt top inset.
const double kMushafTestScreenWidth = 390;
const double kMushafTestScreenHeight = 844;
const double kMushafTestSafeTop = 44;

// ---------------------------------------------------------------------------
// Page content model + measurement (shared by the screen and the tests).
// ---------------------------------------------------------------------------

/// One run of a mushaf page: an optional surah banner (+ Basmala line)
/// followed by a run of verses of that surah, up to the next surah start
/// or the page end. A page is one chunk when it holds no surah start, or
/// several when a surah ends mid-page and the next one begins.
class MushafChunk {
  const MushafChunk({this.bannerSurah, required this.ayahs});

  /// Surah whose banner (+ Basmala line, unless surah 1 or 9) opens this
  /// chunk, or null when the chunk continues a surah from the previous
  /// page.
  final int? bannerSurah;

  /// (surah, ayah) pairs, in Quran order.
  final List<(int, int)> ayahs;

  bool get hasBasmala =>
      bannerSurah != null && hasBasmalaHeader(bannerSurah!);
}

/// Splits a mushaf page (1-based, in [layout] or the active layout)
/// into chunks at surah boundaries.
List<MushafChunk> mushafPageChunks(int page, [MushafLayout? layout]) {
  final ayahs = MushafData.instance.pageAyahs(page, layout);
  final chunks = <MushafChunk>[];
  var current = <(int, int)>[];
  int? banner;
  void flush() {
    if (current.isEmpty && banner == null) return;
    chunks.add(MushafChunk(bannerSurah: banner, ayahs: current));
    current = <(int, int)>[];
    banner = null;
  }

  for (final (surah, ayah) in ayahs) {
    if (ayah == 1) {
      // A surah starts here: flush the previous chunk and open a new
      // one with this surah's banner — including at the page's first ayah.
      flush();
      banner = surah;
    }
    current.add((surah, ayah));
  }
  flush();
  return chunks;
}

/// A tap recognizer that also reports a long press: holding still for
/// [kLongPressTimeout] fires [onLongPress] and swallows the tap that
/// follows on release. (A TextSpan takes only one recognizer, so tap and
/// long-press share this one; a swipe cancels the timer via onTapCancel.)
TapGestureRecognizer _ayahRecognizer({
  required VoidCallback onTap,
  VoidCallback? onLongPress,
}) {
  Timer? timer;
  var longPressed = false;
  return TapGestureRecognizer()
    ..onTapDown = (_) {
      longPressed = false;
      timer?.cancel();
      if (onLongPress != null) {
        timer = Timer(kLongPressTimeout, () {
          longPressed = true;
          onLongPress();
        });
      }
    }
    ..onTapCancel = () {
      timer?.cancel();
    }
    ..onTap = () {
      timer?.cancel();
      if (!longPressed) onTap();
    };
}

/// The inline spans for one chunk's verses: justified Arabic text with a
/// gold medallion after each verse. When [onTapAyah] is given the verse
/// spans get tap/long-press recognizers (collected into
/// [collectRecognizers] — the caller owns and must dispose them) and the
/// medallions get their own tap/long-press; otherwise the spans are
/// inert, for measurement.
///
/// The medallion [WidgetSpan]s need matching placeholder dimensions when
/// measured with a bare TextPainter — see [mushafChunkPlaceholders].
List<InlineSpan> mushafChunkSpans(
  MushafChunk chunk, {
  required double fontSize,
  required String fontFamily,
  required Color ink,
  bool dark = false,
  Color? highlightColor,
  (int, int)? playingAyah,
  void Function(int surah, int ayah)? onTapAyah,
  void Function(int surah, int ayah)? onLongPressAyah,
  List<GestureRecognizer>? collectRecognizers,
}) {
  final repo = QuranRepository.instance;
  final medallionSize = fontSize * kMushafMedallionScale;
  final spans = <InlineSpan>[];
  for (final (surah, ayah) in chunk.ayahs) {
    GestureRecognizer? recognizer;
    if (onTapAyah != null) {
      recognizer = _ayahRecognizer(
        onTap: () => onTapAyah(surah, ayah),
        onLongPress: onLongPressAyah == null
            ? null
            : () => onLongPressAyah(surah, ayah),
      );
      collectRecognizers?.add(recognizer);
    }
    spans.add(TextSpan(
      text: repo.arabicText(surah, ayah),
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: kMushafLineHeight,
        color: ink,
        backgroundColor:
            playingAyah == (surah, ayah) ? highlightColor : null,
      ),
      recognizer: recognizer,
    ));
    // A space each side of the medallion so it never touches the words.
    spans.add(const TextSpan(text: ' '));
    final medallion =
        AyahMedallion(number: ayah, size: medallionSize, dark: dark);
    spans.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: onTapAyah == null
          ? medallion
          : GestureDetector(
              onTap: () => onTapAyah(surah, ayah),
              onLongPress: onLongPressAyah == null
                  ? null
                  : () => onLongPressAyah(surah, ayah),
              child: medallion,
            ),
    ));
    spans.add(const TextSpan(text: ' '));
  }
  return spans;
}

/// Placeholder dimensions matching the medallion WidgetSpans in
/// [mushafChunkSpans], in document order — one per verse. The medallion
/// widget is exactly this size, so a TextPainter measurement with these
/// dimensions lays out exactly like the real RichText.
List<PlaceholderDimensions> mushafChunkPlaceholders(
    MushafChunk chunk, double fontSize) {
  final s = fontSize * kMushafMedallionScale;
  return List<PlaceholderDimensions>.filled(
    chunk.ayahs.length,
    PlaceholderDimensions(
      size: Size(s, s),
      alignment: PlaceholderAlignment.middle,
    ),
  );
}

/// Height of one chunk's verse text at [fontSize] in [maxWidth],
/// measured with a real TextPainter (real Quran font when loaded).
double _measureChunkTextHeight(
  MushafChunk chunk, {
  required double fontSize,
  required double maxWidth,
  required String fontFamily,
}) {
  final painter = TextPainter(
    text: TextSpan(
      children: mushafChunkSpans(
        chunk,
        fontSize: fontSize,
        fontFamily: fontFamily,
        ink: const Color(0xFF000000),
      ),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.justify,
  );
  painter.setPlaceholderDimensions(
      mushafChunkPlaceholders(chunk, fontSize));
  painter.layout(maxWidth: maxWidth);
  return painter.height;
}

/// Height of the centered Basmala line at [fontSize] in [maxWidth],
/// measured (it can wrap to two lines on narrow screens — measuring
/// keeps the fit honest instead of assuming one line).
double _measureBasmalaHeight({
  required double fontSize,
  required double maxWidth,
  required String fontFamily,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: QuranRepository.instance.bismillah,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: kMushafLineHeight,
        color: const Color(0xFF000000),
      ),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
  );
  painter.layout(maxWidth: maxWidth);
  return painter.height;
}

/// Height of one chunk (banner + Basmala + verse text + gaps), as the
/// screen builds it.
double _chunkHeight(
  MushafChunk chunk, {
  required double fontSize,
  required double maxWidth,
  required String fontFamily,
}) {
  var h = 0.0;
  if (chunk.bannerSurah != null) {
    h += kMushafBannerHeight + kMushafGapAfterBanner;
  }
  if (chunk.hasBasmala) {
    h += _measureBasmalaHeight(
            fontSize: fontSize, maxWidth: maxWidth, fontFamily: fontFamily) +
        kMushafGapAfterBasmala;
  }
  h += _measureChunkTextHeight(chunk,
      fontSize: fontSize, maxWidth: maxWidth, fontFamily: fontFamily);
  return h;
}

/// Total content height of a mushaf page at [fontSize] in [maxWidth]
/// (banners + Basmala lines + verse text + gaps, exactly as the screen
/// builds it — so the fit search below measures what the user sees).
double mushafPageHeight(
  int page, {
  required double fontSize,
  required double maxWidth,
  required String fontFamily,
  MushafLayout? layout,
}) {
  final chunks = mushafPageChunks(page, layout);
  var h = 0.0;
  for (var i = 0; i < chunks.length; i++) {
    if (i > 0) h += kMushafGapBeforeBanner;
    h += _chunkHeight(chunks[i],
        fontSize: fontSize, maxWidth: maxWidth, fontFamily: fontFamily);
  }
  return h;
}

/// Result of the auto-fit search for one page.
class MushafFit {
  const MushafFit({
    required this.fontSize,
    required this.scrolls,
    required this.contentHeight,
  });

  /// The chosen font size (largest that fits, or the minimum).
  final double fontSize;

  /// True when even the minimum size overflows: the page scrolls.
  final bool scrolls;

  /// Measured content height at [fontSize] (for vertical centering).
  final double contentHeight;
}

/// Picks the largest font size (from [kMushafMaxFontSize] down to
/// [kMushafMinFontSize] in 1sp steps) whose laid-out content fits in
/// [maxHeight]; falls back to the minimum size + scrolling when nothing
/// fits. The screen and the fit measurement test share this function, so
/// the reported counts are the counts the screen itself produces.
MushafFit fitMushafPage(
  int page, {
  required double maxWidth,
  required double maxHeight,
  required String fontFamily,
  MushafLayout? layout,
}) {
  final chunks = mushafPageChunks(page, layout);
  double lastH = 0;
  for (var size = kMushafMaxFontSize;
      size >= kMushafMinFontSize;
      size -= 1) {
    var h = 0.0;
    for (var i = 0; i < chunks.length; i++) {
      if (i > 0) h += kMushafGapBeforeBanner;
      h += _chunkHeight(chunks[i],
          fontSize: size, maxWidth: maxWidth, fontFamily: fontFamily);
    }
    lastH = h;
    if (h <= maxHeight) {
      return MushafFit(fontSize: size, scrolls: false, contentHeight: h);
    }
  }
  return MushafFit(
      fontSize: kMushafMinFontSize, scrolls: true, contentHeight: lastH);
}

/// Fit cache: one entry per page + layout + style + width + height, so a
/// page is only ever measured once per screen size.
final Map<String, MushafFit> _fitCache = {};

MushafFit _cachedFit(
    MushafLayout layout, int page, double maxWidth, double maxHeight,
    String fontFamily) {
  final key =
      '${layout.name}|$page|$fontFamily|${maxWidth.round()}|${maxHeight.round()}';
  return _fitCache.putIfAbsent(
      key,
      () => fitMushafPage(page,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          fontFamily: fontFamily,
          layout: layout));
}

// ---------------------------------------------------------------------------
// Ornaments (ported from the native MushafArt — same shapes, drawn in code).
// ---------------------------------------------------------------------------

/// Gold 8-point-rosette ayah-end medallion: two squares (one rotated
/// 45°), inner ring, four diagonal dots, Arabic-Indic numeral.
class AyahMedallion extends StatelessWidget {
  const AyahMedallion({
    super.key,
    required this.number,
    required this.size,
    this.dark = false,
  });
  final int number;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final label = toArabicIndic(number);
    // Two/three-digit numbers get a smaller numeral so they fit.
    // (Native: 0.62x / 0.52x / 0.44x of the text size; the medallion is
    // 1.45x the text size, hence these fractions of the medallion.)
    final scale = label.length == 1
        ? 0.42
        : label.length == 2
            ? 0.36
            : 0.30;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _MedallionPainter(dark: dark),
          ),
          Text(
            label,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontFamily: QuranRepository.instance.arabicFontFamily,
              fontSize: size * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8A6A2B),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFB78F3E);
    final fill = Paint()
      ..color = dark ? const Color(0xFF14291F) : const Color(0xFFFFFBF0)
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.04);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;
    // 8-point rosette: two squares, one rotated 45°. The native drawing
    // lets the rotated square's points overshoot the bounds by ~20%;
    // here the same shape is scaled to stay inside the box (square
    // half-side 0.68r, diamond tips at 0.96r) so medallions never paint
    // over the neighbouring words.
    final star = Path();
    final s = r * 0.68;
    star.moveTo(cx - s, cy - s);
    star.lineTo(cx + s, cy - s);
    star.lineTo(cx + s, cy + s);
    star.lineTo(cx - s, cy + s);
    star.close();
    final d = s * 1.4142;
    star.moveTo(cx, cy - d);
    star.lineTo(cx + d, cy);
    star.lineTo(cx, cy + d);
    star.lineTo(cx - d, cy);
    star.close();
    canvas.drawPath(star, fill);
    canvas.drawPath(star, ring);
    // Inner ring.
    canvas.drawCircle(Offset(cx, cy), r * 0.60, ring);
    // Small gold dots at the four diagonal points.
    final dot = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;
    final dd = r * 0.92 * 0.7071;
    final dr = math.max(1.5, r * 0.09);
    canvas.drawCircle(Offset(cx - dd, cy - dd), dr, dot);
    canvas.drawCircle(Offset(cx + dd, cy - dd), dr, dot);
    canvas.drawCircle(Offset(cx - dd, cy + dd), dr, dot);
    canvas.drawCircle(Offset(cx + dd, cy + dd), dr, dot);
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

/// Ornate gold surah header banner: central pointed-oval cartouche
/// (~58% wide) holding the surah's Arabic name, spiral-volute
/// flourishes each side, small diamonds where they meet the cartouche.
class SurahBanner extends StatelessWidget {
  const SurahBanner({super.key, required this.surah, this.dark = false});
  final int surah;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    return SizedBox(
      height: kMushafBannerHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _BannerPainter(dark: dark)),
          ),
          // The name sits inside the ~58%-wide cartouche; long names
          // shrink to fit rather than overflowing it.
          Center(
            child: FractionallySizedBox(
              widthFactor: 0.52,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  repo.surahNameArabic(surah),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: repo.arabicFontFamily,
                    fontSize: 21,
                    color: dark
                        ? const Color(0xFFF2EEE2)
                        : const Color(0xFF252B26),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  _BannerPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFB78F3E);
    final goldStroke = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final goldFill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;
    final panel = Paint()
      ..color = dark ? const Color(0xFF0F2A20) : const Color(0xFFFFFDF6)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final cy = h / 2;
    // Central cartouche: ~58% wide, pointed-oval (vesica) ends.
    final cw = w * 0.58;
    final ch = h * 0.78;
    final cx0 = (w - cw) / 2;
    final cx1 = (w + cw) / 2;
    final top = cy - ch / 2;
    final bot = cy + ch / 2;
    const tip = 14.0;
    Path cartouche(double inset) {
      final p = Path();
      p.moveTo(cx0 + tip, top + inset);
      p.lineTo(cx1 - tip, top + inset);
      p.quadraticBezierTo(cx1 + tip * 0.4 - inset, cy, cx1 - tip, bot - inset);
      p.lineTo(cx0 + tip, bot - inset);
      p.quadraticBezierTo(cx0 - tip * 0.4 + inset, cy, cx0 + tip, top + inset);
      p.close();
      return p;
    }

    canvas.drawPath(cartouche(0), panel);
    canvas.drawPath(cartouche(0), goldStroke);
    canvas.drawPath(
      cartouche(3),
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    // Flourishes: mirrored arabesque scrolls filling each side.
    _flourish(canvas, goldStroke, goldFill, 0, cx0 - 4, cy);
    _flourish(canvas, goldStroke, goldFill, w, cx1 + 4, cy);
    // Small diamonds where the flourishes meet the cartouche.
    _diamond(canvas, goldFill, cx0 - 2, cy, 3.5);
    _diamond(canvas, goldFill, cx1 + 2, cy, 3.5);
  }

  /// One side's scroll: a curling stem with three spiral volutes.
  void _flourish(Canvas canvas, Paint goldStroke, Paint goldFill,
      double fromX, double toX, double cy) {
    final span = (toX - fromX).abs();
    if (span < 10) return;
    final x0 = math.min(fromX, toX);
    final x1 = math.max(fromX, toX);
    // Main stem: a gentle S-curve.
    final stem = Path();
    stem.moveTo(x0, cy);
    stem.cubicTo(x0 + span * 0.3, cy - 10, x0 + span * 0.6, cy + 10, x1, cy);
    canvas.drawPath(stem, goldStroke);
    // Three volutes (spiral curls) along the stem.
    const fx = [0.22, 0.52, 0.80];
    const fr = [7.0, 5.5, 4.0];
    const fy = [-8.0, 8.0, -6.0];
    for (var i = 0; i < 3; i++) {
      final vx = x0 + span * fx[i];
      final vy = cy + fy[i];
      final vr = fr[i];
      final spiral = Path();
      // ~1.5 turns of an Archimedean spiral.
      for (var step = 0; step <= 24; step++) {
        final t = step / 24;
        final ang = t * math.pi * 3.0;
        final rr = vr * (1 - t * 0.75);
        final px = vx + math.cos(ang) * rr;
        final py = vy + math.sin(ang) * rr * 0.8;
        if (step == 0) {
          spiral.moveTo(px, py);
        } else {
          spiral.lineTo(px, py);
        }
      }
      canvas.drawPath(spiral, goldStroke);
    }
    // Small leaf diamonds on the stem.
    _diamond(canvas, goldFill, x0 + span * 0.36, cy - 4, 2.5);
    _diamond(canvas, goldFill, x0 + span * 0.66, cy + 4, 2.5);
  }

  void _diamond(Canvas canvas, Paint fill, double cx, double cy, double r) {
    final p = Path();
    p.moveTo(cx, cy - r);
    p.lineTo(cx + r, cy);
    p.lineTo(cx, cy + r);
    p.lineTo(cx - r, cy);
    p.close();
    canvas.drawPath(p, fill);
  }

  @override
  bool shouldRepaint(covariant _BannerPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

// ---------------------------------------------------------------------------
// The screen.
// ---------------------------------------------------------------------------

/// What the jump dialog returns: a page number, or a request to open one
/// of the two pickers.
enum _JumpTarget { surah, juz }

class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key, required this.initialPage});

  /// 1-based page in the ACTIVE layout (the parent passes
  /// `MushafData.instance.pageOfJuz(juz)` for a Juz row tap).
  final int initialPage;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  // Created once the layouts have loaded, so the initial page is clamped
  // to the ACTIVE layout's page count (610 IndoPak, not 604).
  PageController? _pageController;
  late int _page;
  late String _style;
  bool _ready = false;
  bool _loadFailed = false;

  /// Rebuilds the body on audio + app-state changes (playing highlight,
  /// bookmarks, Mushaf style switch).
  final Listenable _rebuildListenable = Listenable.merge([
    AudioService.instance.currentSurah,
    AudioService.instance.currentAyah,
    appState,
  ]);

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage.clamp(1, MushafData.madaniPages);
    _style = appState.mushafStyle;
    AudioService.instance.currentSurah.addListener(_onAudioChange);
    AudioService.instance.currentAyah.addListener(_onAudioChange);
    appState.addListener(_onAppStateChange);
    _ensureLoaded();
  }

  @override
  void dispose() {
    AudioService.instance.currentSurah.removeListener(_onAudioChange);
    AudioService.instance.currentAyah.removeListener(_onAudioChange);
    appState.removeListener(_onAppStateChange);
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded() async {
    try {
      await QuranRepository.instance.load();
      await MushafData.instance.load();
    } catch (e) {
      debugPrint('QUBA mushaf load error: $e');
    }
    if (!mounted) return;
    final ok =
        QuranRepository.instance.loaded && MushafData.instance.loaded;
    if (ok) {
      _page = widget.initialPage.clamp(1, MushafData.instance.totalPages);
      _pageController = PageController(initialPage: _page - 1);
    }
    setState(() {
      _ready = ok;
      _loadFailed = !ok;
    });
    if (ok) {
      final first = MushafData.instance.firstAyahOfPage(_page);
      appState.setLastRead(first.$1, first.$2);
    }
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    if (page == _page) return;
    setState(() => _page = page);
    final first = MushafData.instance.firstAyahOfPage(page);
    appState.setLastRead(first.$1, first.$2);
  }

  /// Auto-turn: when the playing verse is not on the current page,
  /// turn to its page (in the active layout).
  void _onAudioChange() {
    if (!mounted || !_ready) return;
    final audio = AudioService.instance;
    final surah = audio.currentSurah.value;
    final ayah = audio.currentAyah.value;
    if (surah == null || ayah == null) return;
    final target = MushafData.instance.pageOf(surah, ayah);
    final controller = _pageController;
    if (target != _page && controller != null && controller.hasClients) {
      controller.jumpToPage(target - 1);
    }
  }

  /// Mushaf style switch: keep the reader's place BY AYAH, not by page
  /// number — the first ayah of the current page (in the OLD layout)
  /// opens its page in the NEW layout (e.g. 78:1 is Madani p.582 but
  /// IndoPak p.586).
  void _onAppStateChange() {
    if (!mounted || !_ready) return;
    final style = appState.mushafStyle;
    if (style == _style) return;
    final oldLayout = MushafData.instance.layoutFor(_style);
    final first = MushafData.instance.firstAyahOfPage(_page, oldLayout);
    _style = style;
    final newPage = MushafData.instance.pageOf(first.$1, first.$2);
    if (newPage == _page) {
      setState(() {});
      return;
    }
    setState(() => _page = newPage);
    final controller = _pageController;
    if (controller != null && controller.hasClients) {
      controller.jumpToPage(newPage - 1);
    }
  }

  void _jumpToPage(int page) {
    final controller = _pageController;
    final target = page.clamp(1, MushafData.instance.totalPages);
    if (target == _page || controller == null || !controller.hasClients) {
      return;
    }
    controller.jumpToPage(target - 1);
  }

  Future<void> _showJumpDialog() async {
    final total = MushafData.instance.totalPages;
    final controller = TextEditingController();
    try {
      final choice = await showDialog<Object>(
        context: context,
        builder: (dialogContext) {
          var error = '';
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              void goToPage() {
                final n = int.tryParse(controller.text.trim());
                if (n == null || n < 1 || n > total) {
                  setDialogState(() =>
                      error = trf('enter_page_range', {'total': total}));
                  return;
                }
                Navigator.of(ctx).pop(n);
              }

              final p = QubaPalette.of(ctx);
              return AlertDialog(
                title: Text(tr('go_to')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) => goToPage(),
                            decoration: InputDecoration(
                              labelText: tr('page_number'),
                              hintText: '1–$total',
                              errorText: error.isEmpty ? null : error,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                            onPressed: goToPage, child: Text(tr('go'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          Icon(Icons.menu_book_rounded, color: p.emerald),
                      title: Text(tr('surah')),
                      subtitle: Text(tr('jump_surah')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () =>
                          Navigator.of(ctx).pop(_JumpTarget.surah),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.collections_bookmark_rounded,
                          color: p.emerald),
                      title: Text(tr('juz')),
                      subtitle: Text(tr('jump_juz')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(ctx).pop(_JumpTarget.juz),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (!mounted) return;
      if (choice is int) {
        _jumpToPage(choice);
      } else if (choice == _JumpTarget.surah) {
        final surah = await _pickSurah();
        if (surah != null && mounted) {
          _jumpToPage(MushafData.instance.pageOf(surah, 1));
        }
      } else if (choice == _JumpTarget.juz) {
        final juz = await _pickJuz();
        if (juz != null && mounted) {
          _jumpToPage(MushafData.instance.pageOfJuz(juz));
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<int?> _pickSurah() {
    final repo = QuranRepository.instance;
    final current = MushafData.instance.firstAyahOfPage(_page).$1;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final p = QubaPalette.of(ctx);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(tr('choose_surah'),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: repo.surahs.length,
                    itemBuilder: (ctx, i) {
                      final s = repo.surahs[i];
                      final isCurrent = s.number == current;
                      return ListTile(
                        leading: RosetteNumber(number: s.number, size: 40),
                        title: Text(s.nameEnglish,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            "${tr('surah_meaning_${s.number}')} • ${s.ayahCount} ${tr('verses')}"),
                        trailing: isCurrent
                            ? Icon(Icons.check_rounded, color: p.emerald)
                            : null,
                        tileColor: isCurrent ? p.activeFill : null,
                        onTap: () => Navigator.pop(ctx, s.number),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _pickJuz() {
    final repo = QuranRepository.instance;
    final current = MushafData.instance.juzOfPage(_page);
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final p = QubaPalette.of(ctx);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(tr('choose_juz'),
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: juzList.length,
                    itemBuilder: (ctx, i) {
                      final j = juzList[i];
                      final isCurrent = j.number == current;
                      return ListTile(
                        leading:
                            RosetteNumber(number: j.number, size: 40),
                        title: Text(tr('juz_name_${j.number}'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${repo.surah(j.startSurah).nameEnglish} '
                            '${j.startSurah}:${j.startAyah} — '
                            '${repo.surah(j.endSurah).nameEnglish} '
                            '${j.endSurah}:${j.endAyah}'),
                        trailing: isCurrent
                            ? Icon(Icons.check_rounded, color: p.emerald)
                            : null,
                        tileColor: isCurrent ? p.activeFill : null,
                        onTap: () => Navigator.pop(ctx, j.number),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Scaffold(
      // Plain page color (no geometric pattern): cream in light mode,
      // deep green-black in dark mode — as in the reference screenshots.
      body: Container(
        color: p.bg,
        child: SafeArea(
          child: _ready
              ? _body(context)
              : Center(
                  child: _loadFailed
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            tr('mushaf_unavailable'),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : CircularProgressIndicator(color: p.emerald),
                ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return AnimatedBuilder(
      animation: _rebuildListenable,
      builder: (context, _) {
        final audio = AudioService.instance;
        final playingSurah = audio.currentSurah.value;
        final playingAyah = audio.currentAyah.value;
        final playing = playingSurah != null && playingAyah != null
            ? (playingSurah, playingAyah)
            : null;
        return Column(
          children: [
            _topBar(context, playingSurah != null),
            Expanded(
              // Arabic book order: swipe left = next page, regardless of
              // the UI language.
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: MushafData.instance.totalPages,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => _MushafPage(
                    page: index + 1,
                    playingAyah: playing,
                    onJumpTap: _showJumpDialog,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    final p = QubaPalette.of(context);
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Icon(icon, size: 20, color: p.emerald),
    );
  }

  Widget _topBar(BuildContext context, bool audioActive) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final first = MushafData.instance.firstAyahOfPage(_page);
    final surahName = repo.surah(first.$1).nameEnglish;
    final bookmarked = appState.isBookmarked(first.$1, first.$2);
    final audio = AudioService.instance;
    return SizedBox(
      height: kMushafTopBarHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
          children: [
            _circleButton(Icons.arrow_back_ios_new_rounded,
                () => Navigator.of(context).maybePop()),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                surahName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ),
            // Compact audio controls while something plays (no
            // mini-player on this screen — the card reader has one).
            if (audioActive) ...[
              StreamBuilder<bool>(
                stream: audio.player.playingStream,
                initialData: audio.player.playing,
                builder: (context, snap) {
                  final playing = snap.data ?? false;
                  return _circleButton(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    audio.togglePause,
                  );
                },
              ),
              const SizedBox(width: 8),
              _circleButton(Icons.stop_rounded, audio.stop),
              const SizedBox(width: 8),
            ],
            _circleButton(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              () => appState.toggleBookmark(first.$1, first.$2),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One mushaf page.
// ---------------------------------------------------------------------------

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    required this.page,
    required this.playingAyah,
    required this.onJumpTap,
  });
  final int page;
  final (int, int)? playingAyah;
  final VoidCallback onJumpTap;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  /// Recognizers owned by the cached content below; disposed when the
  /// content is rebuilt or the page leaves the viewport.
  List<GestureRecognizer> _recognizers = [];
  String? _contentKey;
  Widget? _content;

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers = [];
    super.dispose();
  }

  void _onTapAyah(int surah, int ayah) {
    final audio = AudioService.instance;
    final isCurrent = audio.currentSurah.value == surah &&
        audio.currentAyah.value == ayah;
    if (isCurrent) {
      unawaited(audio.togglePause());
    } else {
      unawaited(audio.playAyah(surah, ayah));
    }
  }

  void _onLongPressAyah(int surah, int ayah) {
    if (!mounted) return;
    final was = appState.isBookmarked(surah, ayah);
    appState.toggleBookmark(surah, ayah);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(was ? tr('bookmark_removed') : tr('bookmarked')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final repo = QuranRepository.instance;
    final layout = MushafData.instance.activeLayout;
    final fontFamily = repo.arabicFontFamily;
    final first = MushafData.instance.firstAyahOfPage(widget.page, layout);
    final firstSurahName = repo.surah(first.$1).nameEnglish;
    final hizb = MushafData.instance.hizbOfPage(widget.page, layout);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = math.max(
            1.0, constraints.maxWidth - 2 * kMushafPagePadding);
        final maxHeight = math.max(
            1.0,
            constraints.maxHeight -
                kMushafLabelHeight -
                kMushafBottomBarHeight -
                2 * kMushafPageVerticalPadding);
        final fit =
            _cachedFit(layout, widget.page, maxWidth, maxHeight, fontFamily);
        // Short pages center their text block vertically when there is
        // spare space, as in the reference screenshots.
        final topPad = fit.scrolls
            ? 0.0
            : math.max(0.0, (maxHeight - fit.contentHeight) / 2);
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kMushafPagePadding,
            vertical: kMushafPageVerticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: kMushafLabelHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    firstSurahName,
                    style: TextStyle(fontSize: 15, color: p.muted),
                  ),
                ),
              ),
              Expanded(
                // Always a scroll view so a hair of measurement error
                // clips instead of overflowing; scrolling is only
                // enabled when the page genuinely needs it.
                child: SingleChildScrollView(
                  physics: fit.scrolls
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.only(top: topPad),
                    child: _buildContent(
                        context, p, layout, fit.fontSize, fontFamily),
                  ),
                ),
              ),
              SizedBox(
                height: kMushafBottomBarHeight,
                child: _bottomBar(context, p, hizb),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the page's content (banners + Basmala lines + verse text),
  /// cached per page + layout + style + size + playing verse so a
  /// rebuild that changes none of those reuses the same RichText and
  /// its recognizers.
  Widget _buildContent(BuildContext context, QubaPalette p,
      MushafLayout layout, double fontSize, String fontFamily) {
    final playing = widget.playingAyah;
    final key =
        '${layout.name}|${widget.page}|$fontSize|$fontFamily|${playing?.$1}:${playing?.$2}|${p.dark}';
    final cached = _content;
    if (_contentKey == key && cached != null) return cached;
    for (final r in _recognizers) {
      r.dispose();
    }
    final recognizers = <GestureRecognizer>[];
    final chunks = mushafPageChunks(widget.page, layout);
    // Yellow highlight on the playing verse, as in the card reader —
    // a deeper gold-olive in dark mode so the text stays readable.
    final highlight =
        p.dark ? const Color(0xFF7A6A1F) : const Color(0xFFFFF6A5);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < chunks.length; i++) ...[
          if (i > 0) const SizedBox(height: kMushafGapBeforeBanner),
          if (chunks[i].bannerSurah != null) ...[
            SurahBanner(surah: chunks[i].bannerSurah!, dark: p.dark),
            const SizedBox(height: kMushafGapAfterBanner),
          ],
          if (chunks[i].hasBasmala) ...[
            Text(
              QuranRepository.instance.bismillah,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: fontSize,
                height: kMushafLineHeight,
                color: p.ink,
              ),
            ),
            const SizedBox(height: kMushafGapAfterBasmala),
          ],
          RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            textScaler: TextScaler.noScaling,
            text: TextSpan(
              children: mushafChunkSpans(
                chunks[i],
                fontSize: fontSize,
                fontFamily: fontFamily,
                ink: p.ink,
                dark: p.dark,
                highlightColor: highlight,
                playingAyah: playing,
                onTapAyah: _onTapAyah,
                onLongPressAyah: _onLongPressAyah,
                collectRecognizers: recognizers,
              ),
            ),
          ),
        ],
      ],
    );
    _recognizers = recognizers;
    _contentKey = key;
    _content = content;
    return content;
  }

  /// Bottom bar: page number + "Hizb N", alternating sides by odd/even
  /// page — odd: Hizb left, number right; even: number left, Hizb
  /// right, as in the reference screenshots. Tapping the number opens
  /// the jump dialog.
  Widget _bottomBar(BuildContext context, QubaPalette p, int hizb) {
    final style = TextStyle(fontSize: 16, color: p.muted);
    final number = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onJumpTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text('${widget.page}', style: style),
      ),
    );
    final hizbLabel = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(trf('hizb_n', {'n': hizb}), style: style),
    );
    // Physical left/right (not start/end), so the alternation holds in
    // every UI language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: widget.page.isOdd
            ? [hizbLabel, const Spacer(), number]
            : [number, const Spacer(), hizbLabel],
      ),
    );
  }
}
