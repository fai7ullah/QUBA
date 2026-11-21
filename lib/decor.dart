import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'i18n.dart';
import 'theme.dart';

/// Brand art for QUBA, drawn with code: the header (arch logo mark +
/// wordmark) and the prayer medallions.
///
/// Round 4 (2026-11-21): the mosque skyline, crescent moon, birds,
/// olive branch and bottom green waves were REMOVED at the owner's
/// request — the background is plain now. Only the logo mark and the
/// functional prayer medallions remain.

const Color _gold = Color(0xFFC9A45C);

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// "QUBA — Your Islamic Companion" header: the arch logo mark, the
/// wordmark + tagline, and the glass settings button. Plain and simple
/// (Round 4, 2026-11-21): the mosque skyline, crescent moon, birds and
/// olive branch were removed at the owner's request.
class QubaHeader extends StatelessWidget {
  const QubaHeader({super.key, required this.onSettings});
  final VoidCallback onSettings;

  /// Height of the header below the status bar.
  static const double _body = 100;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final mq = MediaQuery.of(context);
    // The tab body sits inside a top SafeArea (main.dart), so the
    // status-bar space is already accounted for above this header and
    // padding.top reads 0 here: the header keeps its exact height.
    final inset = mq.padding.top;
    final h = _body + inset;
    final ink = p.dark ? p.ink : p.emeraldDeep;

    return SizedBox(
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Logo mark.
          Positioned(
            left: 26,
            top: inset + 20,
            width: 50,
            height: 53,
            child: CustomPaint(
              painter: ArchLogoPainter(
                outline: p.dark ? p.emerald : p.emeraldDeep,
                dome: p.emerald,
              ),
            ),
          ),
          // Wordmark + tagline (always laid out left-to-right: it is a brand).
          Positioned(
            left: 92,
            top: inset + 25,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUBA',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 38,
                      height: 1.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tr('tagline'),
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14.5,
                      color: p.dark ? p.muted : const Color(0xFF3B3F38),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Settings button.
          Positioned(
            right: 13,
            top: inset + 1,
            width: 43,
            height: 43,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSettings,
                child: Ink(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.dark
                        ? p.activeFill
                        : Colors.white.withValues(alpha: 0.62),
                    border: Border.all(color: p.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 23,
                    color: p.dark ? p.activeText : p.emeraldDeep,
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

/// True when the interface language is English.
bool get appLangIsEnglish => appState.lang == 'en';

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

/// Pointed-arch logo mark: green arch outline, dome, door and gold base.
class ArchLogoPainter extends CustomPainter {
  const ArchLogoPainter({required this.outline, required this.dome});
  final Color outline;
  final Color dome;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final arch = Path()
      ..moveTo(w * 0.06, h * 0.92)
      ..lineTo(w * 0.06, h * 0.50)
      ..cubicTo(w * 0.06, h * 0.26, w * 0.34, h * 0.30, w * 0.5, h * 0.03)
      ..cubicTo(w * 0.66, h * 0.30, w * 0.94, h * 0.26, w * 0.94, h * 0.50)
      ..lineTo(w * 0.94, h * 0.92);
    canvas.drawPath(arch, stroke);

    // Dome.
    final domePath = Path()
      ..moveTo(w * 0.26, h * 0.64)
      ..cubicTo(w * 0.26, h * 0.34, w * 0.74, h * 0.34, w * 0.74, h * 0.64)
      ..close();
    canvas.drawPath(domePath, Paint()..color = dome);
    canvas.drawLine(
      Offset(w * 0.5, h * 0.42),
      Offset(w * 0.5, h * 0.33),
      Paint()
        ..color = _gold
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    // Body with a gold door.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.64, w * 0.78, h * 0.90),
      const Radius.circular(2),
    );
    canvas.drawRRect(body, Paint()..color = dome);
    final door = Path()
      ..moveTo(w * 0.42, h * 0.90)
      ..lineTo(w * 0.42, h * 0.76)
      ..quadraticBezierTo(w * 0.42, h * 0.68, w * 0.5, h * 0.68)
      ..quadraticBezierTo(w * 0.58, h * 0.68, w * 0.58, h * 0.76)
      ..lineTo(w * 0.58, h * 0.90)
      ..close();
    canvas.drawPath(door, Paint()..color = _gold);
    // Gold base line.
    canvas.drawLine(
      Offset(0, h * 0.95),
      Offset(w, h * 0.95),
      Paint()
        ..color = _gold
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant ArchLogoPainter old) =>
      old.outline != outline || old.dome != dome;
}

/// Scalloped (8-lobed) medallion badge: cream rim, emerald face.
class MedallionPainter extends CustomPainter {
  const MedallionPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    Path scallop(double radius) {
      final path = Path();
      const n = 128;
      for (var i = 0; i <= n; i++) {
        final a = 2 * math.pi * i / n;
        final rr = radius * (0.94 + 0.06 * math.cos(8 * a));
        final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      return path..close();
    }

    // Shadow.
    canvas.drawPath(
      scallop(r).shift(const Offset(0, 1.2)),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Rim.
    canvas.drawPath(
      scallop(r),
      Paint()..color = dark ? const Color(0xFFCFC3A3) : const Color(0xFFF1E8D2),
    );
    canvas.drawPath(
      scallop(r),
      Paint()
        ..color = _gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // Face.
    final face = scallop(r * 0.86);
    canvas.drawPath(
      face,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0F7054), Color(0xFF064735)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      face,
      Paint()
        ..color = _gold.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant MedallionPainter old) => old.dark != dark;
}

/// Gold glyph for a prayer medallion: 'fajr' (sun on the horizon) or 'ring'
/// (the gold sun-ring used for Sunrise, Asr, Maghrib and Isha).
class PrayerGlyphPainter extends CustomPainter {
  const PrayerGlyphPainter({required this.kind, required this.color});
  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = size.center(Offset.zero);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    if (kind == 'fajr') {
      final center = Offset(c.dx, c.dy + w * 0.14);
      final r = w * 0.24;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), math.pi,
          math.pi, true, fill);
      canvas.drawLine(Offset(c.dx - w * 0.40, center.dy),
          Offset(c.dx + w * 0.40, center.dy), stroke);
      for (var i = 0; i < 5; i++) {
        final a = math.pi + i * math.pi / 4;
        canvas.drawLine(
          Offset(center.dx + math.cos(a) * r * 1.35,
              center.dy + math.sin(a) * r * 1.35),
          Offset(center.dx + math.cos(a) * r * 1.8,
              center.dy + math.sin(a) * r * 1.8),
          stroke,
        );
      }
      return;
    }

    // Ring with a little rising sun inside.
    canvas.drawCircle(c, w * 0.38, stroke);
    final inner = Offset(c.dx, c.dy + w * 0.08);
    canvas.drawArc(Rect.fromCircle(center: inner, radius: w * 0.17), math.pi,
        math.pi, true, fill);
    canvas.drawLine(Offset(c.dx - w * 0.2, inner.dy),
        Offset(c.dx + w * 0.2, inner.dy), stroke..strokeWidth = w * 0.06);
    canvas.drawLine(Offset(c.dx, c.dy - w * 0.26),
        Offset(c.dx, c.dy - w * 0.17), stroke);
  }

  @override
  bool shouldRepaint(covariant PrayerGlyphPainter old) =>
      old.kind != kind || old.color != color;
}
