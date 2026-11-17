import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'i18n.dart';
import 'theme.dart';

/// Decorative art for the Home screen, drawn with code so the app needs no
/// extra image assets: the mosque skyline, crescent, birds, olive branch,
/// the arch logo mark, the bottom green waves and the prayer medallions.

const Color _gold = Color(0xFFC9A45C);

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// "QUBA — Your Islamic Companion" header with the mosque skyline, crescent
/// moon, birds, branch and the glass settings button.
class QubaHeader extends StatelessWidget {
  const QubaHeader({super.key, required this.onSettings});
  final VoidCallback onSettings;

  /// Height of the header below the status bar.
  static const double _body = 156;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final mq = MediaQuery.of(context);
    // The reference is drawn edge-to-edge with a ~24dp status bar.
    final inset = mq.padding.top > 0 ? mq.padding.top : 24.0;
    final w = mq.size.width;
    final skyW = w * 0.52;
    final skyH = skyW * 205 / 433;
    final h = _body + inset;
    final ink = p.dark ? p.ink : p.emeraldDeep;

    return SizedBox(
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft warm glow behind the skyline.
          Positioned(
            right: -40,
            top: 20,
            width: w * 0.8,
            height: h - 20,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.35, 0.2),
                    radius: 0.75,
                    colors: [
                      (p.dark ? const Color(0x2234D399) : const Color(0x55FFE3A8)),
                      const Color(0x00FFE3A8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Olive branch, top-left.
          Positioned(
            left: 0,
            top: 0,
            width: 84,
            height: 170,
            child: IgnorePointer(
              child: CustomPaint(painter: BranchPainter(dark: p.dark)),
            ),
          ),
          // Mosque skyline, fading in from the left.
          Positioned(
            right: 0,
            bottom: 0,
            width: skyW,
            height: skyH,
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                  stops: [0.0, 0.3],
                ).createShader(rect),
                child: CustomPaint(painter: SkylinePainter(dark: p.dark)),
              ),
            ),
          ),
          // Crescent moon.
          Positioned(
            right: w * 0.185,
            top: inset + 28,
            width: 40,
            height: 40,
            child: const IgnorePointer(
              child: CustomPaint(painter: CrescentPainter()),
            ),
          ),
          // Birds.
          Positioned(
            right: w * 0.40,
            top: inset + 59,
            width: 44,
            height: 24,
            child: IgnorePointer(
              child: CustomPaint(painter: BirdsPainter(dark: p.dark)),
            ),
          ),
          // Logo mark.
          Positioned(
            left: 26,
            top: inset + 24,
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
            top: inset + 29,
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
                    appLangIsEnglish ? 'Your Islamic Companion' : tr('tagline'),
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

/// Gold crescent moon with a soft glow.
class CrescentPainter extends CustomPainter {
  const CrescentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final outer = Path()
      ..addOval(Rect.fromCircle(center: c, radius: r * 0.92));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: c.translate(r * 0.46, -r * 0.30), radius: r * 0.80));
    final crescent = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      crescent,
      Paint()
        ..color = _gold.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF3DC9A), Color(0xFFC9A45C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CrescentPainter old) => false;
}

/// Three small birds.
class BirdsPainter extends CustomPainter {
  const BirdsPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dark ? const Color(0xFF9DB8AB) : const Color(0xFF7D8480)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    void bird(double x, double y, double s) {
      final path = Path()
        ..moveTo(x - 6 * s, y)
        ..quadraticBezierTo(x - 3 * s, y - 4 * s, x, y)
        ..quadraticBezierTo(x + 3 * s, y - 4 * s, x + 6 * s, y);
      canvas.drawPath(path, paint);
    }

    bird(6, 18, 0.8);
    bird(24, 7, 1.0);
    bird(38, 6, 0.8);
  }

  @override
  bool shouldRepaint(covariant BirdsPainter old) => old.dark != dark;
}

/// Olive-green leafy branch reaching in from the top-left corner.
class BranchPainter extends CustomPainter {
  const BranchPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final stem = Path()
      ..moveTo(-8, size.height * 0.02)
      ..quadraticBezierTo(
          size.width * 0.55, size.height * 0.10, size.width * 0.92, size.height * 0.85);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF8A7556).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    final metric = stem.computeMetrics().first;
    const count = 15;
    for (var i = 1; i <= count; i++) {
      final t = metric.length * i / (count + 1);
      final tan = metric.getTangentForOffset(t);
      if (tan == null) continue;
      final side = i.isEven ? 1.0 : -1.0;
      final len = 17.0 - (i / count) * 5;
      canvas.save();
      canvas.translate(tan.position.dx, tan.position.dy);
      canvas.rotate(tan.angle + side * 0.85);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.32, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.32, 0, 0)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..color = (i % 3 == 0
                  ? const Color(0xFF9DB27A)
                  : const Color(0xFF6F8F55))
              .withValues(alpha: dark ? 0.35 : 0.55),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant BranchPainter old) => old.dark != dark;
}

/// The mosque skyline: three minarets, a teal central dome and smaller
/// domes, drawn in a 433 x 205 design space and scaled to fit.
class SkylinePainter extends CustomPainter {
  const SkylinePainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 433.0);

    final light = dark ? const Color(0xFF3F6E5F) : const Color(0xFFF6E7C6);
    final deep = dark ? const Color(0xFF214A3E) : const Color(0xFFDCBC80);
    const tealA = Color(0xFF4A9792);
    const tealB = Color(0xFF1D5C62);

    Shader body(Rect r) => LinearGradient(
          colors: [light, deep],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(r);
    Shader teal(Rect r) => const LinearGradient(
          colors: [tealA, tealB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(r);
    final goldPaint = Paint()..color = _gold;

    void minaret(double cx, double top, double w, double base) {
      // Shaft.
      final shaft = Rect.fromLTRB(cx - w / 2, top + 62, cx + w / 2, base);
      canvas.drawRect(shaft, Paint()..shader = body(shaft));
      // Windows.
      final slit = Paint()
        ..color = (dark ? const Color(0x55000000) : const Color(0x338A6A2E));
      for (var i = 0; i < 3; i++) {
        final y = top + 70 + i * 26.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 2.2, y, 4.4, 15),
            const Radius.circular(2.2),
          ),
          slit,
        );
      }
      // Upper lantern.
      final up = Rect.fromLTRB(cx - w * 0.40, top + 32, cx + w * 0.40, top + 56);
      canvas.drawRect(up, Paint()..shader = body(up));
      // Balcony.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - w * 0.80, top + 54, cx + w * 0.80, top + 63),
          const Radius.circular(3),
        ),
        goldPaint,
      );
      // Teal cap.
      final cap = Path()
        ..moveTo(cx - w * 0.46, top + 34)
        ..quadraticBezierTo(cx - w * 0.62, top + 14, cx, top + 4)
        ..quadraticBezierTo(cx + w * 0.62, top + 14, cx + w * 0.46, top + 34)
        ..close();
      canvas.drawPath(cap, Paint()..shader = teal(cap.getBounds()));
      // Finial.
      canvas.drawLine(
        Offset(cx, top + 5),
        Offset(cx, top - 8),
        Paint()
          ..color = _gold
          ..strokeWidth = 1.8,
      );
      canvas.drawCircle(Offset(cx, top - 9), 2.2, goldPaint);
    }

    void smallDome(double cx, double baseY, double r) {
      final wall = Rect.fromLTRB(cx - r * 0.9, baseY, cx + r * 0.9, baseY + r * 1.1);
      canvas.drawRect(wall, Paint()..shader = body(wall));
      final d = Path()
        ..moveTo(cx - r, baseY)
        ..cubicTo(cx - r, baseY - r * 1.5, cx + r, baseY - r * 1.5, cx + r, baseY)
        ..close();
      canvas.drawPath(d, Paint()..shader = teal(d.getBounds()));
      canvas.drawLine(
        Offset(cx, baseY - r * 1.15),
        Offset(cx, baseY - r * 1.6),
        Paint()
          ..color = _gold
          ..strokeWidth = 1.4,
      );
    }

    // Distant low buildings (left).
    for (final d in const [
      [20.0, 178.0, 13.0],
      [58.0, 172.0, 17.0],
      [100.0, 176.0, 14.0],
    ]) {
      smallDome(d[0], d[1], d[2]);
    }

    // Far-right minaret (partly cropped by the edge).
    minaret(392, 78, 20, 205);
    // Main block of the mosque.
    final block = Rect.fromLTRB(166, 165, 308, 205);
    canvas.drawRect(block, Paint()..shader = body(block));
    // Side domes.
    smallDome(186, 160, 15);
    smallDome(292, 160, 15);
    smallDome(334, 172, 12);
    smallDome(120, 168, 12);

    // Tall minarets.
    minaret(148, 12, 28, 205);
    minaret(304, 24, 28, 205);

    // Central drum.
    final drum = Rect.fromLTRB(200, 140, 272, 170);
    canvas.drawRect(drum, Paint()..shader = body(drum));
    final arch = Paint()
      ..color = (dark ? const Color(0x66000000) : const Color(0x448A6A2E));
    for (var i = 0; i < 5; i++) {
      final x = 208.0 + i * 13.5;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, 146, 7, 16),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        arch,
      );
    }
    canvas.drawRect(
      Rect.fromLTRB(198, 138, 274, 143),
      goldPaint,
    );
    // Central dome.
    final dome = Path()
      ..moveTo(196, 140)
      ..cubicTo(196, 78, 276, 78, 276, 140)
      ..close();
    canvas.drawPath(dome, Paint()..shader = teal(dome.getBounds()));
    // Dome highlight.
    canvas.drawPath(
      Path()
        ..moveTo(210, 120)
        ..cubicTo(214, 98, 232, 90, 244, 92),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    // Finial + crescent.
    canvas.drawLine(
      const Offset(236, 100),
      const Offset(236, 80),
      Paint()
        ..color = _gold
        ..strokeWidth = 2,
    );
    canvas.drawCircle(const Offset(236, 78), 3, goldPaint);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: const Offset(236, 70), radius: 6)),
      Path()..addOval(Rect.fromCircle(center: const Offset(238.5, 68.5), radius: 5)),
    );
    canvas.drawPath(crescent, goldPaint);
    // Gate.
    final gate = Path()
      ..moveTo(226, 205)
      ..lineTo(226, 182)
      ..quadraticBezierTo(226, 170, 236, 170)
      ..quadraticBezierTo(246, 170, 246, 182)
      ..lineTo(246, 205)
      ..close();
    canvas.drawPath(
      gate,
      Paint()..color = dark ? const Color(0xFF0B2E24) : const Color(0xFFB98F43),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SkylinePainter old) => old.dark != dark;
}

/// Green waves in both lower corners plus faint dome silhouettes, sitting
/// behind the bottom navigation bar.
class BottomDecorPainter extends CustomPainter {
  const BottomDecorPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Faint domes.
    final dp = Paint()
      ..color = dark ? const Color(0x14FFFFFF) : const Color(0x22B59A63);
    void dome(double cx, double baseY, double r) {
      final d = Path()
        ..moveTo(cx - r, baseY)
        ..cubicTo(cx - r, baseY - r * 1.7, cx + r, baseY - r * 1.7, cx + r, baseY)
        ..close();
      canvas.drawPath(d, dp);
      canvas.drawRect(
        Rect.fromLTRB(cx - r * 0.07, baseY - r * 2.5, cx + r * 0.07, baseY - r * 1.2),
        dp,
      );
      canvas.drawRect(Rect.fromLTRB(cx - r * 0.8, baseY, cx + r * 0.8, h), dp);
    }

    dome(w * 0.30, h * 0.62, 20);
    dome(w * 0.50, h * 0.50, 26);
    dome(w * 0.70, h * 0.62, 20);
    dome(w * 0.18, h * 0.72, 11);
    dome(w * 0.82, h * 0.72, 11);

    // Green waves.
    void wave(bool left) {
      canvas.save();
      if (!left) {
        canvas.translate(w, 0);
        canvas.scale(-1, 1);
      }
      final band = Path()
        ..moveTo(0, h * 0.04)
        ..cubicTo(w * 0.14, h * 0.05, w * 0.30, h * 0.32, w * 0.46, h * 0.58)
        ..lineTo(w * 0.46, h * 0.80)
        ..cubicTo(w * 0.30, h * 0.56, w * 0.12, h * 0.34, 0, h * 0.30)
        ..close();
      canvas.drawPath(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: dark
                ? const [Color(0xFF0A5A43), Color(0xFF063A2C)]
                : const [Color(0xFF0B6B4F), Color(0xFF064735)],
          ).createShader(Rect.fromLTWH(0, 0, w * 0.5, h)),
      );
      final edge = Path()
        ..moveTo(0, h * 0.04)
        ..cubicTo(w * 0.14, h * 0.05, w * 0.30, h * 0.32, w * 0.46, h * 0.58);
      canvas.drawPath(
        edge,
        Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    wave(true);
    wave(false);
  }

  @override
  bool shouldRepaint(covariant BottomDecorPainter old) => old.dark != dark;
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
