import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'i18n.dart';
import 'prayer_service.dart';
import 'theme.dart';

/// Shared QUBA widgets — the liquid-glass design system.
/// Every screen is built from these so light/dark stay consistent.

/// Full-screen background: plain spec background color only.
/// (Phase 2, round 4 item 5: all code-drawn decorations removed at the
/// owner's request — mosque skyline, crescent, birds, branch, waves,
/// and the geometric star pattern. The background is just the colour.)
class QubaBackground extends StatelessWidget {
  const QubaBackground({super.key, required this.child});
  final Widget child;

  Widget _blob(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    if (p.dark) {
      return Container(color: p.bg, child: child);
    }
    // Soft mint wash with a few pale-green glows: the glass cards blur
    // these, which is what gives the frosted look.
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF9F3), Color(0xFFE3F3EA), Color(0xFFF1FAF5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
              top: -90,
              right: -80,
              child: _blob(const Color(0x4D6FCF97), 300)),
          Positioned(
              top: 330,
              left: -140,
              child: _blob(const Color(0x40A8E6C1), 320)),
          Positioned(
              bottom: -110,
              right: -60,
              child: _blob(const Color(0x4D5CC48A), 320)),
          child,
        ],
      ),
    );
  }
}

/// A true frosted-glass card: [BackdropFilter] blur over whatever is
/// behind the card, translucent fill, white glass border, soft shadow and
/// a light reflection along the top edge — the reference design's glass.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 30,
    this.onTap,
    this.blur = 20,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: p.dark ? p.shadow : Colors.green.withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            children: [
              Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: p.cardFill,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: p.cardBorder, width: 1),
                ),
                child: child,
              ),
              // Light reflection along the top edge.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 46,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: p.dark ? 0.10 : 0.35),
                          Colors.white.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Gold line — 8-point star — gold line, as between the Next Prayer card
/// and the prayer schedule in the reference.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    Widget line(bool fadeStart) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: fadeStart
                    ? [p.gold.withValues(alpha: 0.0), p.gold.withValues(alpha: 0.8)]
                    : [p.gold.withValues(alpha: 0.8), p.gold.withValues(alpha: 0.0)],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 44),
      child: Row(
        children: [
          line(true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(28, 28),
                    painter: Star8Painter(
                      fill: p.gold.withValues(alpha: 0.16),
                      stroke: p.gold,
                      strokeWidth: 1.3,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(18, 18),
                    painter: Star8Painter(
                      fill: Colors.transparent,
                      stroke: p.gold,
                      strokeWidth: 1.1,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.gold, width: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          line(false),
        ],
      ),
    );
  }
}

/// Material icon for each prayer, matching the reference medallions.
IconData prayerIcon(String name) {
  switch (name) {
    case 'Fajr':
      return Icons.wb_twilight_rounded;
    case 'Sunrise':
      return Icons.wb_sunny_rounded;
    case 'Dhuhr':
      return Icons.wb_sunny_rounded;
    case 'Asr':
      return Icons.wb_cloudy_rounded;
    case 'Maghrib':
      return Icons.wb_twilight_rounded;
    case 'Isha':
      return Icons.nightlight_round;
    default:
      return Icons.mosque_rounded;
  }
}

/// Glyph kind for each prayer's medallion, matching the reference:
/// Fajr = sun on the horizon, Dhuhr = mosque, the rest = gold sun-ring.
String prayerKind(String name) {
  switch (name) {
    case 'Fajr':
      return 'fajr';
    case 'Dhuhr':
      return 'mosque';
    default:
      return 'ring';
  }
}

/// Round frosted-glass medallion holding a coloured prayer icon (sun
/// glyphs in orange, night in green), as in the reference. Pass [kind]
/// (see [prayerKind]) for the prayer glyphs, or [icon] for any other icon.
class PrayerMedallion extends StatelessWidget {
  const PrayerMedallion({
    super.key,
    this.icon = Icons.mosque_rounded,
    this.kind,
    this.size = 44,
    this.prayer,
  });
  final IconData icon;
  final String? kind;
  final double size;

  /// Prayer name ('Fajr' ...): picks that prayer's icon and colour.
  final String? prayer;

  static const Color _sun = Color(0xFFF58A1F);
  static const Color _green = Color(0xFF0B7A3B);

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    IconData glyph = icon;
    Color color = p.dark ? p.activeText : _green;
    if (prayer != null) {
      glyph = prayerIcon(prayer!);
      switch (prayer) {
        case 'Fajr':
        case 'Isha':
          color = p.dark ? p.activeText : _green;
          break;
        default:
          color = _sun;
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: p.dark
              ? [const Color(0x3334D399), const Color(0x1A34D399)]
              : [Colors.white.withValues(alpha: 0.95), const Color(0xFFE2F2E8)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: p.dark ? 0.2 : 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(glyph, size: size * 0.56, color: color),
    );
  }
}

/// Reminder state icon: gold bell when on, grey bell in a red
/// "prohibited" sign when off — as in the reference.
class NotifyIcon extends StatelessWidget {
  const NotifyIcon({super.key, required this.on, this.size = 30});
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (on) {
      return Icon(
        Icons.notifications_rounded,
        size: size,
        color: const Color(0xFFF2B01E),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.notifications_rounded,
            size: size * 0.66,
            color: const Color(0xFFB7B2A6),
          ),
          Icon(
            Icons.block_rounded,
            size: size,
            color: const Color(0xFFE5484D),
          ),
        ],
      ),
    );
  }
}

/// Thin gold double-line rosette (8-point star) with a number in the
/// middle — the surah/juz medallion of the redesigned Quran tab, and the
/// mini-player badge in the reader.
class RosetteNumber extends StatelessWidget {
  const RosetteNumber({super.key, required this.number, this.size = 46});
  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: Star8Painter(
              fill: Colors.transparent,
              stroke: p.gold,
              strokeWidth: 1.2,
            ),
          ),
          CustomPaint(
            size: Size(size * 0.72, size * 0.72),
            painter: Star8Painter(
              fill: Colors.transparent,
              stroke: p.gold.withValues(alpha: 0.6),
              strokeWidth: 1.0,
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small-caps letterspaced section label ("NEXT PRAYER",
/// "CONTINUE READING").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.align = TextAlign.start});
  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.6,
        color: p.dark ? p.activeText : p.emerald,
      ),
    );
  }
}

/// One of the three glass quick buttons on Home (Quran / Prayer / Settings).
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Expanded(
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: p.dark ? p.activeText : p.emeraldDeep),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small glass pill used for the Home feature chips
/// (Qibla, Tasbih, Duas, 99 Names, Khatma, Calendar).
class FeatureChip extends StatelessWidget {
  const FeatureChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: p.gold),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim sub-screen header: glass back button + title + subtitle.
/// No background, no QUBA header block (removed by the owner's order).
class TitleRow extends StatelessWidget {
  const TitleRow({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Row(
      children: [
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(8),
          onTap: () => Navigator.of(context).maybePop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: p.emerald,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Glass search field.
class QubaSearchField extends StatelessWidget {
  const QubaSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyle(color: p.ink, fontSize: 15.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: p.muted),
          prefixIcon: Icon(Icons.search_rounded, color: p.muted),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

/// Pointed Islamic-arch clip, as around the mosque thumbnail in the
/// Next Prayer card.
class ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, h * 0.34);
    path.cubicTo(0, h * 0.10, w * 0.26, h * 0.12, w * 0.5, 0);
    path.cubicTo(w * 0.74, h * 0.12, w, h * 0.10, w, h * 0.34);
    path.lineTo(w, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ArchFillPainter extends CustomPainter {
  _ArchFillPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ArchClipper().getClip(size),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ArchFillPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The six-row prayer schedule card from the reference: star medallion,
/// name, thin gold divider, bell toggle, time. The next prayer row gets
/// the mint-glass highlight and a dot. Shared by Home and Prayer screens.
class PrayerScheduleCard extends StatelessWidget {
  const PrayerScheduleCard({
    super.key,
    required this.entries,
    required this.nextName,
    required this.onToggle,
    this.onViewAll,
  });
  final List<PrayerEntry> entries;
  final String? nextName;
  final Future<void> Function(String name, bool enabled) onToggle;

  /// When set, the card shows a "Prayer Times  View All →" header.
  final VoidCallback? onViewAll;

  static const double _rowHeight = 50;

  Widget _header(BuildContext context, QubaPalette p) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          Icon(Icons.mosque_rounded, size: 34, color: p.emerald),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('prayer_times'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: p.emerald,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('view_all'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: p.emerald,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    rtl
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded,
                    size: 22,
                    color: p.emerald,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return GlassCard(
      radius: 30,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          if (onViewAll != null) ...[
            _header(context, p),
            Divider(
              height: 1,
              thickness: 1,
              indent: 14,
              endIndent: 14,
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
          for (var i = 0; i < entries.length; i++) ...[
            _row(context, entries[i], entries[i].name == nextName),
            if (i != entries.length - 1)
              // No divider next to the highlighted row, as in the reference.
              if (entries[i].name != nextName &&
                  entries[i + 1].name != nextName)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 14,
                  endIndent: 14,
                  color: Colors.black.withValues(alpha: 0.08),
                )
              else
                const SizedBox(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PrayerEntry e, bool isNext) {
    final p = QubaPalette.of(context);
    final notify = appState.prayerNotify[e.name] ?? false;
    final textColor =
        isNext ? (p.dark ? p.activeText : p.emerald) : p.ink;
    final row = Row(
      children: [
        const SizedBox(width: 10),
        // Dot slot (kept on every row so medallions line up).
        SizedBox(
          width: 10,
          child: isNext
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.dark ? p.activeText : p.emerald,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        PrayerMedallion(prayer: e.name, size: 36),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            trPrayer(e.name),
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        Container(width: 1, height: 26, color: Colors.black.withValues(alpha: 0.08)),
        SizedBox(
          width: 58,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: NotifyIcon(on: notify, size: 28),
            tooltip: notify ? tr('reminder_on') : tr('reminder_off'),
            onPressed: () => onToggle(e.name, !notify),
          ),
        ),
        SizedBox(
          width: 84,
          child: Text(
            PrayerService.formatTime(e.time),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isNext ? FontWeight.w800 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 14),
      ],
    );
    return Container(
      height: _rowHeight,
      decoration: isNext
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: p.dark
                    ? [p.activeFill, p.activeFill]
                    : const [Color(0xFFD3F0DE), Color(0xFFBFE8CF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(_rowHeight / 2),
              border: Border.all(
                color: p.dark
                    ? p.activeText.withValues(alpha: 0.4)
                    : const Color(0xFFA7DDBE),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E9E7B).withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: row,
    );
  }
}

/// An image clipped into a gold-bordered Islamic arch.
class ArchImage extends StatelessWidget {
  const ArchImage({
    super.key,
    required this.image,
    required this.width,
    required this.height,
  });
  final Widget image;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _ArchFillPainter(p.gold)),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: ClipPath(
                clipper: ArchClipper(),
                child: image,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
