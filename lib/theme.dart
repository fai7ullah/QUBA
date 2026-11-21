import 'dart:math' as math;

import 'package:flutter/material.dart';

/// QUBA design tokens — Umar's exact spec ("Premium Islamic App UI
/// Redesign — Cream Liquid Glass + Modern Islamic Aesthetic").
///
/// Light: creamy ivory #F8F0E5, emerald #075B43, gold #C9A45C.
/// Dark: deep emerald-black with the same gold accents.
class QubaColors {
  // Brand (shared by both themes)
  static const emerald = Color(0xFF075B43);
  static const emeraldDeep = Color(0xFF064735);
  static const emeraldBright = Color(0xFF2E9E7B);
  static const gold = Color(0xFFC9A45C);
  static const champagne = Color(0xFFE8D6B5);

  // Light (creamy) — exact spec values
  static const creamBg = Color(0xFFF8F0E5);
  static const creamSecondary = Color(0xFFFFF9F0);
  static const creamCard = Color(0x8CFFFFFF); // rgba(255,255,255,0.55)
  static const creamBorder = Color(0xD9FFFFFF); // rgba(255,255,255,0.85)
  static const inkText = Color(0xFF252B26);
  static const inkMuted = Color(0xFF77786F);
  static const mintActive = Color(0xE6D8F0E0);
  static const mintActiveText = emerald;

  // Dark (emerald-black)
  static const nightBg = Color(0xFF04241C);
  static const nightSecondary = Color(0xFF062E24);
  static const nightCard = Color(0x8C0A3C2C);
  static const nightBorder = Color(0x29FFFFFF);
  static const nightText = Color(0xFFF4EFE3);
  static const nightMuted = Color(0xFF9DB8AB);
  static const nightActive = Color(0x2E34D399);
  static const nightActiveText = Color(0xFF6EE7B7);
}

/// Resolved palette for the current brightness. Every screen reads its
/// colors through [QubaPalette.of] so light/dark stay consistent.
class QubaPalette {
  const QubaPalette({
    required this.dark,
    required this.bg,
    required this.bgSecondary,
    required this.cardFill,
    required this.cardBorder,
    required this.ink,
    required this.muted,
    required this.emerald,
    required this.emeraldDeep,
    required this.gold,
    required this.champagne,
    required this.activeFill,
    required this.activeText,
    required this.shadow,
    required this.onEmerald,
  });

  final bool dark;
  final Color bg;
  final Color bgSecondary;
  final Color cardFill;
  final Color cardBorder;
  final Color ink;
  final Color muted;
  final Color emerald;
  final Color emeraldDeep;
  final Color gold;
  final Color champagne;
  final Color activeFill;
  final Color activeText;
  final Color shadow;
  final Color onEmerald;

  static const lightPalette = QubaPalette(
    dark: false,
    bg: QubaColors.creamBg,
    bgSecondary: QubaColors.creamSecondary,
    cardFill: QubaColors.creamCard,
    cardBorder: QubaColors.creamBorder,
    ink: QubaColors.inkText,
    muted: QubaColors.inkMuted,
    emerald: QubaColors.emerald,
    emeraldDeep: QubaColors.emeraldDeep,
    gold: QubaColors.gold,
    champagne: QubaColors.champagne,
    activeFill: QubaColors.mintActive,
    activeText: QubaColors.mintActiveText,
    shadow: Color(0x1A064735),
    onEmerald: Colors.white,
  );

  static const darkPalette = QubaPalette(
    dark: true,
    bg: QubaColors.nightBg,
    bgSecondary: QubaColors.nightSecondary,
    cardFill: QubaColors.nightCard,
    cardBorder: QubaColors.nightBorder,
    ink: QubaColors.nightText,
    muted: QubaColors.nightMuted,
    emerald: QubaColors.emeraldBright,
    emeraldDeep: QubaColors.emeraldDeep,
    gold: QubaColors.gold,
    champagne: QubaColors.champagne,
    activeFill: QubaColors.nightActive,
    activeText: QubaColors.nightActiveText,
    shadow: Color(0x59000000),
    onEmerald: Colors.white,
  );

  static QubaPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkPalette
          : lightPalette;
}

ThemeData qubaLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: QubaColors.emerald,
      brightness: Brightness.light,
      primary: QubaColors.emerald,
      secondary: QubaColors.gold,
      surface: QubaColors.creamSecondary,
    ),
    scaffoldBackgroundColor: QubaColors.creamBg,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    cardTheme: CardThemeData(
      color: QubaColors.creamCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: QubaColors.creamBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: QubaColors.creamBg,
      foregroundColor: QubaColors.inkText,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: QubaColors.gold.withValues(alpha: 0.25),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? QubaColors.emerald : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? QubaColors.emerald.withValues(alpha: 0.35)
            : null,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: QubaColors.creamSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: QubaColors.creamSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
  );
}

ThemeData qubaDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: QubaColors.emeraldBright,
      brightness: Brightness.dark,
      primary: QubaColors.emeraldBright,
      secondary: QubaColors.gold,
      surface: QubaColors.nightSecondary,
    ),
    scaffoldBackgroundColor: QubaColors.nightBg,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    cardTheme: CardThemeData(
      color: QubaColors.nightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: QubaColors.nightBorder),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: QubaColors.nightBg,
      foregroundColor: QubaColors.nightText,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: QubaColors.gold.withValues(alpha: 0.25),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? QubaColors.gold : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? QubaColors.gold.withValues(alpha: 0.35)
            : null,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: QubaColors.nightSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: QubaColors.nightSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
  );
}

/// A filled 8-point star (two overlapping squares), used for the gold
/// divider ornament and the prayer medallions.
class Star8Painter extends CustomPainter {
  Star8Painter({required this.fill, this.stroke, this.strokeWidth = 0});
  final Color fill;
  final Color? stroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    for (final rot in [0.0, math.pi / 4]) {
      final square = Path();
      for (int i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 - math.pi / 4;
        final px = cx + r * math.cos(a);
        final py = cy + r * math.sin(a);
        if (i == 0) {
          square.moveTo(px, py);
        } else {
          square.lineTo(px, py);
        }
      }
      square.close();
      path.addPath(square, Offset.zero);
    }
    canvas.drawPath(
        path, Paint()..color = fill..style = PaintingStyle.fill);
    if (stroke != null && strokeWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant Star8Painter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth;
}
