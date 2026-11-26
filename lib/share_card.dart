import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Draws a verse / dua as a styled 4:5 image (cream, gold frame, QUBA
/// footer) and shares it. Drawn directly onto a canvas — no widget tree,
/// no screenshotting — so it works on any screen and any text length:
/// the Arabic and the translation are shrunk to fit, and only truncated
/// (with an ellipsis) as a last resort.
class ShareCard {
  ShareCard._();

  static const double width = 1080;
  static const double height = 1350;

  static const Color _gold = Color(0xFF2E9E5B);
  static const Color _emerald = Color(0xFF0B7A3B);
  static const Color _ink = Color(0xFF252B26);
  static const Color _muted = Color(0xFF5E625A);

  /// Renders the card to PNG bytes. Returns null if rendering failed.
  static Future<Uint8List?> render({
    required String arabic,
    required String body,
    required String reference,
    bool bodyRtl = false,
    String arabicFont = 'AmiriQuran',
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas =
          Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
      _paint(canvas, arabic.trim(), body.trim(), reference.trim(), bodyRtl,
          arabicFont);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static TextPainter _layout(
    String text,
    TextStyle style, {
    required double maxWidth,
    required TextDirection dir,
    int? maxLines,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
      textAlign: TextAlign.center,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    )..layout(maxWidth: maxWidth);
    return tp;
  }

  /// Largest font size in [min]..[max] (step 2) whose laid-out height
  /// fits [maxHeight]; if even [min] does not fit, returns [min].
  static TextPainter _fit(
    String text, {
    required double max,
    required double min,
    required double maxWidth,
    required double maxHeight,
    required TextDirection dir,
    required TextStyle Function(double size) style,
  }) {
    var size = max;
    while (size > min) {
      final tp = _layout(text, style(size), maxWidth: maxWidth, dir: dir);
      if (tp.height <= maxHeight) return tp;
      size -= 2;
    }
    // Minimum size: cap the lines so the text can never overflow.
    final probe = _layout(text, style(min), maxWidth: maxWidth, dir: dir);
    if (probe.height <= maxHeight) return probe;
    final lineHeight = probe.computeLineMetrics().isEmpty
        ? min * 1.5
        : probe.computeLineMetrics().first.height;
    final lines = math.max(1, (maxHeight / lineHeight).floor());
    return _layout(text, style(min),
        maxWidth: maxWidth, dir: dir, maxLines: lines);
  }

  static void _paint(Canvas canvas, String arabic, String body,
      String reference, bool bodyRtl, String arabicFont) {
    const full = Rect.fromLTWH(0, 0, width, height);

    // Background.
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF4FBF6), Color(0xFFDDF1E5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(full),
    );

    // Gold frame.
    final outer = RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 36, width - 72, height - 72),
        const Radius.circular(44));
    canvas.drawRRect(
      outer,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final inner = RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 58, width - 116, height - 116),
        const Radius.circular(30));
    canvas.drawRRect(
      inner,
      Paint()
        ..color = _gold.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Top ornament: line - 8-point star - line.
    const cx = width / 2;
    const topY = 150.0;
    final line = Paint()
      ..color = _gold
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(cx - 230, topY), const Offset(cx - 44, topY), line);
    canvas.drawLine(const Offset(cx + 44, topY), const Offset(cx + 230, topY), line);
    final star = Path();
    for (final rot in const [0.0, math.pi / 4]) {
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 - math.pi / 4;
        final pt = Offset(cx + 26 * math.cos(a), topY + 26 * math.sin(a));
        if (i == 0) {
          star.moveTo(pt.dx, pt.dy);
        } else {
          star.lineTo(pt.dx, pt.dy);
        }
      }
      star.close();
    }
    canvas.drawPath(star, Paint()..color = _gold.withValues(alpha: 0.2));
    canvas.drawPath(
      star,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Text block, vertically centred between the ornament and the footer.
    const textWidth = width - 2 * 130;
    const areaTop = 215.0;
    const areaBottom = 1130.0;
    const gap = 44.0;

    TextPainter? arabicTp;
    if (arabic.isNotEmpty) {
      arabicTp = _fit(
        arabic,
        max: 70,
        min: 30,
        maxWidth: textWidth,
        maxHeight: body.isEmpty ? 800 : 520,
        dir: TextDirection.rtl,
        style: (s) => TextStyle(
          fontFamily: arabicFont,
          fontSize: s,
          height: 1.9,
          color: _ink,
        ),
      );
    }
    final refTp = _layout(
      reference,
      const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: _gold,
      ),
      maxWidth: textWidth,
      dir: TextDirection.ltr,
      maxLines: 2,
    );
    final used = (arabicTp == null ? 0 : arabicTp.height + gap) +
        refTp.height +
        (body.isEmpty ? 0 : gap);
    final bodyMax = math.max(120.0, areaBottom - areaTop - used);
    TextPainter? bodyTp;
    if (body.isNotEmpty) {
      bodyTp = _fit(
        body,
        max: 40,
        min: 24,
        maxWidth: textWidth,
        maxHeight: math.min(bodyMax, 360),
        dir: bodyRtl ? TextDirection.rtl : TextDirection.ltr,
        style: (s) => TextStyle(fontSize: s, height: 1.5, color: _muted),
      );
    }
    final total = (arabicTp == null ? 0 : arabicTp.height + gap) +
        (bodyTp == null ? 0 : bodyTp.height + gap) +
        refTp.height;
    var y = areaTop + math.max(0, (areaBottom - areaTop - total) / 2);
    if (arabicTp != null) {
      arabicTp.paint(canvas, Offset((width - arabicTp.width) / 2, y));
      y += arabicTp.height + gap;
    }
    if (bodyTp != null) {
      bodyTp.paint(canvas, Offset((width - bodyTp.width) / 2, y));
      y += bodyTp.height + gap;
    }
    refTp.paint(canvas, Offset((width - refTp.width) / 2, y));

    // Footer: QUBA wordmark.
    final brand = _layout(
      'QUBA',
      const TextStyle(
        fontFamily: 'serif',
        fontSize: 54,
        fontWeight: FontWeight.w700,
        letterSpacing: 6,
        color: _emerald,
      ),
      maxWidth: textWidth,
      dir: TextDirection.ltr,
    );
    brand.paint(canvas, Offset((width - brand.width) / 2, 1160));
    canvas.drawLine(const Offset(cx - 160, 1240), const Offset(cx + 160, 1240),
        Paint()
          ..color = _gold.withValues(alpha: 0.6)
          ..strokeWidth = 1.5);
  }

  /// Renders and shares the card as an image, with [fallbackText] as the
  /// message. If the image cannot be made or written, shares the text
  /// alone, so tapping Share always does something useful.
  static Future<void> share({
    required String arabic,
    required String body,
    required String reference,
    required String fallbackText,
    bool bodyRtl = false,
    String arabicFont = 'AmiriQuran',
  }) async {
    final bytes = await render(
      arabic: arabic,
      body: body,
      reference: reference,
      bodyRtl: bodyRtl,
      arabicFont: arabicFont,
    );
    if (bytes != null) {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/quba_share_card.png');
        await file.writeAsBytes(bytes, flush: true);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: fallbackText),
        );
        return;
      } catch (_) {
        // fall through to the plain-text share
      }
    }
    await SharePlus.instance.share(ShareParams(text: fallbackText));
  }
}
