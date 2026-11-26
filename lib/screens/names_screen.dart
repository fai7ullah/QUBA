import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio.dart';
import '../content.dart';
import '../decor.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// The 99 Names of Allah: decorated header, search, and a uniform
/// 3-column grid of equal liquid-glass cards. Tap a card for its
/// meaning; tap its play button to hear the name recited (bundled
/// human pronunciation — see assets/names/LICENSE.txt) through the
/// app-wide bottom player.
class NamesScreen extends StatefulWidget {
  const NamesScreen({super.key});

  @override
  State<NamesScreen> createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<(int, AllahName)> get _filtered {
    final q = _query.trim().toLowerCase();
    final entries = [
      for (var i = 0; i < names99.length; i++) (i + 1, names99[i]),
    ];
    if (q.isEmpty) return entries;
    return entries
        .where(
          (e) =>
              e.$2.transliteration.toLowerCase().contains(q) ||
              e.$2.meaning.toLowerCase().contains(q) ||
              tr('name_meaning_${e.$1}').toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleName(int number) {
    final audio = AudioService.instance;
    if (audio.currentName.value == number) {
      unawaited(audio.togglePause());
    } else {
      unawaited(audio.playName(number));
    }
  }

  Future<void> _showName(int number, AllahName name) async {
    final p = QubaPalette.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: p.cardBorder, width: 1.4),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              trf('name_of_99', {'n': number}),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: p.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name.arabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 44,
                height: 1.6,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name.transliteration,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: p.emerald,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('name_meaning_$number'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: p.muted, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _toggleName(number);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(tr('play')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final filtered = _filtered;
    final audio = AudioService.instance;

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(p),
                const SizedBox(height: 14),
                QubaSearchField(
                  controller: _controller,
                  hint: tr('search_names_hint'),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 10),
                _countDivider(p, filtered.length),
                const SizedBox(height: 10),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 44,
                                color: p.muted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('no_names_found'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr('try_different_spelling'),
                                style: TextStyle(fontSize: 14, color: p.muted),
                              ),
                            ],
                          ),
                        )
                      : AnimatedBuilder(
                          animation: audio.sessionListenable,
                          builder: (context, _) => GridView.builder(
                            padding: EdgeInsets.only(
                              bottom: audio.hasActiveSession ? 104 : 16,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 132,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final number = filtered[i].$1;
                              final name = filtered[i].$2;
                              return _nameCard(p, number, name);
                            },
                          ),
                        ),
                ),
                Text(
                  tr('names_audio_credit'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: p.muted),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 46,
                  child: CustomPaint(
                    painter: _MosqueSilhouettePainter(
                      silhouette: p.emerald.withValues(alpha: 0.28),
                      wave: p.emerald.withValues(alpha: 0.55),
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Decorated header: back button, mosque ornament, title, and the
  /// "Asma ul-Husna" pill between two ornamented lines, with hanging
  /// lanterns at the top corner.
  Widget _header(QubaPalette p) {
    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                GlassCard(
                  radius: 22,
                  padding: const EdgeInsets.all(9),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: p.emerald,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 64,
              height: 36,
              child: CustomPaint(
                painter: ArchLogoPainter(outline: p.emerald, dome: p.emerald),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tr('names99_title'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: p.dark ? p.ink : const Color(0xFF0B3D2A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _pillLine(p),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0E7A46), Color(0xFF075B43)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF075B43).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    tr('asma_ul_husna'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                _pillLine(p),
              ],
            ),
          ],
        ),
        // Hanging lanterns (code-drawn, decorative only).
        PositionedDirectional(
          top: 0,
          end: 2,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomPaint(
                  size: const Size(24, 52),
                  painter: const _LanternPainter(),
                ),
                const SizedBox(width: 6),
                CustomPaint(
                  size: const Size(30, 68),
                  painter: const _LanternPainter(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillLine(QubaPalette p) {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.2,
              color: p.emerald.withValues(alpha: 0.45),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: p.emerald,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countDivider(QubaPalette p, int count) {
    return Row(
      children: [
        Text(
          _query.trim().isEmpty
              ? trf('names_count', {'n': names99.length})
              : trf('names_found', {'n': count}),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: p.dark ? p.ink : const Color(0xFF0B3D2A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.emerald.withValues(alpha: 0.5),
                  p.emerald.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        CustomPaint(
          size: const Size(24, 24),
          painter: Star8Painter(
            fill: p.gold.withValues(alpha: 0.16),
            stroke: p.gold,
            strokeWidth: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _nameCard(QubaPalette p, int number, AllahName name) {
    final audio = AudioService.instance;
    final isCurrent = audio.currentName.value == number;
    return GlassCard(
      key: ValueKey('name-card-$number'),
      radius: 22,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      onTap: () => _showName(number, name),
      child: Stack(
        children: [
          Column(
            children: [
              _numberBadge(p, number),
              const SizedBox(height: 4),
              // Fixed-height Arabic slot: the name can never overlap
              // the transliteration below it.
              SizedBox(
                height: 42,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name.arabic,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 25,
                        height: 1.35,
                        color: p.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  name.transliteration,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: p.dark ? p.muted : const Color(0xFF14532D),
                  ),
                ),
              ),
              const Spacer(),
              // Small gold ornament at the card bottom.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 16,
                    height: 1,
                    color: const Color(0xFFC9A45C).withValues(alpha: 0.7),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CustomPaint(
                      size: const Size(11, 11),
                      painter: Star8Painter(
                        fill: const Color(0xFFC9A45C).withValues(alpha: 0.25),
                        stroke: const Color(0xFFC9A45C),
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 1,
                    color: const Color(0xFFC9A45C).withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: StreamBuilder<bool>(
              stream: audio.player.playingStream,
              initialData: audio.player.playing,
              builder: (context, snap) {
                final playing = isCurrent && (snap.data ?? false);
                return IconButton(
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: isCurrent
                        ? p.emerald
                        : (p.dark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.75)),
                    foregroundColor: isCurrent ? p.onEmerald : p.emerald,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  tooltip: playing ? tr('pause') : tr('play'),
                  onPressed: () => _toggleName(number),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberBadge(QubaPalette p, int number) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(30, 30),
            painter: Star8Painter(
              fill: p.emerald,
              stroke: Colors.white.withValues(alpha: 0.85),
              strokeWidth: 1.2,
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: p.onEmerald,
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple hanging lantern (gold outline, warm glow), code-drawn.
class _LanternPainter extends CustomPainter {
  const _LanternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const gold = Color(0xFFB8862B);
    final stroke = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    // Chain.
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h * 0.18), stroke);
    // Cap.
    final cap = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..quadraticBezierTo(w / 2, h * 0.14, w * 0.7, h * 0.3)
      ..close();
    canvas.drawPath(cap, Paint()..color = gold);
    // Glass body with glow.
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.3, w * 0.78, h * 0.78),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFE9B0), Color(0xFFF2B01E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(body, stroke);
    canvas.drawLine(Offset(w / 2, h * 0.3), Offset(w / 2, h * 0.78), stroke);
    // Base + finial.
    canvas.drawLine(
      Offset(w * 0.3, h * 0.84),
      Offset(w * 0.7, h * 0.84),
      stroke,
    );
    canvas.drawCircle(Offset(w / 2, h * 0.92), 1.8, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(covariant _LanternPainter oldDelegate) => false;
}

/// Mosque-silhouette footer band: domes and minarets over a green
/// wave, code-drawn.
class _MosqueSilhouettePainter extends CustomPainter {
  const _MosqueSilhouettePainter({
    required this.silhouette,
    required this.wave,
  });
  final Color silhouette;
  final Color wave;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = silhouette;
    final base = h * 0.72;

    void dome(double cx, double r) {
      final path = Path()
        ..moveTo(cx - r, base)
        ..cubicTo(cx - r, base - r * 0.9, cx + r, base - r * 0.9, cx + r, base)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawLine(
        Offset(cx, base - r * 0.95),
        Offset(cx, base - r * 1.25),
        Paint()
          ..color = silhouette
          ..strokeWidth = 1.6,
      );
    }

    void minaret(double x, double top) {
      canvas.drawRect(Rect.fromLTRB(x - 2, top, x + 2, base), paint);
      final cap = Path()
        ..moveTo(x - 4, top)
        ..lineTo(x, top - 7)
        ..lineTo(x + 4, top)
        ..close();
      canvas.drawPath(cap, paint);
    }

    // Skyline body.
    canvas.drawRect(Rect.fromLTRB(0, base, w, h), paint);
    dome(w * 0.5, 26);
    dome(w * 0.32, 15);
    dome(w * 0.68, 15);
    dome(w * 0.14, 10);
    dome(w * 0.86, 10);
    minaret(w * 0.06, h * 0.3);
    minaret(w * 0.24, h * 0.38);
    minaret(w * 0.76, h * 0.38);
    minaret(w * 0.94, h * 0.3);

    // Green wave over the bottom.
    final wavePath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.82)
      ..cubicTo(w * 0.25, h * 0.66, w * 0.4, h * 0.92, w * 0.62, h * 0.84)
      ..cubicTo(w * 0.8, h * 0.78, w * 0.9, h * 0.88, w, h * 0.8)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wavePath, Paint()..color = wave);
  }

  @override
  bool shouldRepaint(covariant _MosqueSilhouettePainter oldDelegate) =>
      oldDelegate.silhouette != silhouette || oldDelegate.wave != wave;
}
