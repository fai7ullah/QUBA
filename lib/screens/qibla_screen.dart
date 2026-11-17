import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../prayer_calc.dart';
import '../theme.dart';
import '../widgets.dart';

/// Qibla compass: a dial that turns with the phone's heading, with a gold
/// Kaaba marker at the true Qibla bearing for the current location.
/// Falls back to a static bearing + calibration note when the device
/// has no compass or the sensor gives no heading.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  bool _compassUnavailable = false;
  bool _wasAligned = false;

  double get _bearing => QiblaMath.bearing(appState.lat, appState.lng);

  /// Great-circle distance to the Kaaba in kilometres (haversine).
  double get _distanceKm {
    const earthRadiusKm = 6371.0;
    final lat1 = appState.lat * math.pi / 180;
    final lat2 = QiblaMath.kaabaLat * math.pi / 180;
    final dLat = lat2 - lat1;
    final dLng = (QiblaMath.kaabaLng - appState.lng) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthRadiusKm * math.asin(math.sqrt(a));
  }

  bool _isAligned(double heading) {
    var diff = (heading - _bearing).abs() % 360;
    if (diff > 180) diff = 360 - diff;
    return diff < 5;
  }

  @override
  void initState() {
    super.initState();
    final stream = FlutterCompass.events;
    if (stream == null) {
      _compassUnavailable = true;
      return;
    }
    _sub = stream.listen(
      (event) {
        final heading = event.heading;
        if (heading == null) return;
        final aligned = _isAligned(heading);
        if (aligned && !_wasAligned) {
          HapticFeedback.heavyImpact();
        }
        setState(() {
          _heading = heading;
          _wasAligned = aligned;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _compassUnavailable = true);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final bearing = _bearing;
    final heading = _heading;
    final live = !_compassUnavailable && heading != null;
    final aligned = live && _isAligned(heading);

    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TitleRow(
                    title: tr('qibla'),
                    subtitle: appState.locationName,
                  ),
                  const SizedBox(height: 24),
                  // Compass dial: rotates with the heading so the gold
                  // Kaaba marker sits at the top when facing Qibla.
                  Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GlassCard(
                            radius: 140,
                            padding: EdgeInsets.zero,
                            child: Transform.rotate(
                              angle: -(heading ?? 0) * math.pi / 180,
                              child: CustomPaint(
                                size: const Size(280, 280),
                                painter: _CompassRosePainter(
                                  bearing: bearing,
                                  palette: p,
                                ),
                              ),
                            ),
                          ),
                          // Fixed marker: the top of the phone.
                          Positioned(
                            top: 6,
                            child: Icon(
                              Icons.navigation_rounded,
                              size: 26,
                              color: aligned ? p.emerald : p.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (aligned)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: p.emerald, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are facing Qibla',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: p.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (live)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.explore_rounded,
                              color: p.gold, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Turn until the gold marker reaches the top',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: p.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.compass_calibration_rounded,
                              color: p.gold, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Compass not available — move your phone in a '
                              'figure-8 to calibrate, or use the bearing below.',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: p.ink,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      children: [
                        _infoRow(
                          p,
                          Icons.navigation_rounded,
                          'Qibla direction',
                          '${bearing.toStringAsFixed(1)}° '
                          '${QiblaMath.compassPoint(bearing)}',
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          p,
                          Icons.straighten_rounded,
                          'Distance to Makkah',
                          '${_distanceKm.round()} km',
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          p,
                          Icons.location_on_rounded,
                          'From',
                          appState.locationName,
                        ),
                        if (live) ...[
                          const SizedBox(height: 12),
                          _infoRow(
                            p,
                            Icons.explore_rounded,
                            'Your heading',
                            '${heading.toStringAsFixed(0)}° '
                            '${QiblaMath.compassPoint(heading)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hold the phone flat and turn slowly. The bearing is '
                    'calculated on this device from your location — no '
                    'internet needed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(QubaPalette p, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: p.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 14.5, color: p.muted)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
      ],
    );
  }
}

/// Compass rose: outer ring, tick marks, cardinal letters and the gold
/// Kaaba marker (diamond + guide line) at the Qibla bearing. Drawn
/// north-up; the parent rotates the whole dial by the live heading.
class _CompassRosePainter extends CustomPainter {
  _CompassRosePainter({required this.bearing, required this.palette});
  final double bearing;
  final QubaPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Outer ring.
    canvas.drawCircle(
      c,
      r - 10,
      Paint()
        ..color = palette.gold.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      c,
      r - 26,
      Paint()
        ..color = palette.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tick marks every 6°, longer every 30°.
    for (var deg = 0; deg < 360; deg += 6) {
      final a = (deg - 90) * math.pi / 180;
      final major = deg % 30 == 0;
      final r1 = r - (major ? 26 : 19);
      final r2 = r - 12;
      canvas.drawLine(
        Offset(c.dx + r1 * math.cos(a), c.dy + r1 * math.sin(a)),
        Offset(c.dx + r2 * math.cos(a), c.dy + r2 * math.sin(a)),
        Paint()
          ..color = major
              ? palette.gold
              : palette.muted.withValues(alpha: 0.5)
          ..strokeWidth = major ? 2 : 1,
      );
    }

    // Cardinal letters.
    const cardinals = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - 90) * math.pi / 180;
      final pos = Offset(
        c.dx + (r - 46) * math.cos(a),
        c.dy + (r - 46) * math.sin(a),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: cardinals[i],
          style: TextStyle(
            color: i == 0 ? palette.emerald : palette.muted,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Guide line from the centre to the Qibla marker.
    final ba = (bearing - 90) * math.pi / 180;
    final markerPos = Offset(
      c.dx + (r - 72) * math.cos(ba),
      c.dy + (r - 72) * math.sin(ba),
    );
    canvas.drawLine(
      c,
      markerPos,
      Paint()
        ..color = palette.gold.withValues(alpha: 0.55)
        ..strokeWidth = 1.5,
    );

    // Gold diamond Kaaba marker.
    const ms = 11.0;
    final diamond = Path()
      ..moveTo(markerPos.dx, markerPos.dy - ms)
      ..lineTo(markerPos.dx + ms, markerPos.dy)
      ..lineTo(markerPos.dx, markerPos.dy + ms)
      ..lineTo(markerPos.dx - ms, markerPos.dy)
      ..close();
    canvas.drawPath(diamond, Paint()..color = palette.gold);
    canvas.drawCircle(markerPos, 3.5, Paint()..color = palette.emeraldDeep);

    // Centre dot.
    canvas.drawCircle(c, 5, Paint()..color = palette.emerald);
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..color = palette.emerald.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter oldDelegate) =>
      oldDelegate.bearing != bearing || oldDelegate.palette != palette;
}
