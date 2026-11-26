import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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

const Color _gold = Color(0xFF2E9E5B);

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// "QUBA — Your Islamic Companion" header, as in the reference: a wide
/// frosted-glass pill (logo tile, thin divider, wordmark + tagline) and a
/// round glass settings button beside it.
class QubaHeader extends StatelessWidget {
  const QubaHeader({super.key, required this.onSettings});
  final VoidCallback onSettings;

  static const double _pill = 76;

  static BoxDecoration _glass(QubaPalette p, {bool circle = false, double radius = 38}) =>
      BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        color: p.dark ? p.cardFill : Colors.white.withValues(alpha: 0.55),
        border: Border.all(color: p.cardBorder),
        boxShadow: [
          BoxShadow(
            color: p.dark ? p.shadow : Colors.green.withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final ink = p.dark ? p.ink : p.emerald;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
      child: SizedBox(
        height: _pill,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: _glass(p),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                const Color(0xFFD7EFE0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9)),
                          ),
                          child: CustomPaint(
                            painter: ArchLogoPainter(
                              outline: p.dark ? p.emerald : p.emeraldDeep,
                              dome: p.emerald,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 1.5,
                          height: 40,
                          color: p.emerald.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 14),
                        // The brand is always laid out left-to-right.
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'QUBA',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 40,
                                      height: 1.0,
                                      fontWeight: FontWeight.w800,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    tr('tagline'),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: p.dark ? p.muted : p.emerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onSettings,
                    child: Ink(
                      width: 62,
                      height: 62,
                      decoration: _glass(p, circle: true),
                      child: Icon(
                        Icons.settings_rounded,
                        size: 32,
                        color: p.dark ? p.activeText : p.emerald,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
