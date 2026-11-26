import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio.dart';
import '../content.dart';
import '../data.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';
import 'player_options.dart';

/// Tracks whether the visible route is the root (Shell tabs) or a
/// pushed screen, and whether a modal (dialog / bottom sheet) is on
/// top — the app-wide player sits above the bottom nav on tab screens,
/// at the screen bottom on pushed screens, and hides while a modal is
/// open so it never covers a dialog's or sheet's own controls.
class QubaRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> atRoot = ValueNotifier(true);
  final ValueNotifier<bool> modalOpen = ValueNotifier(false);
  final Set<Route<dynamic>> _pages = {};
  final Set<Route<dynamic>> _modals = {};

  void _sync() {
    final atRootValue = _pages.length <= 1;
    final modalValue = _modals.isNotEmpty;
    void apply() {
      atRoot.value = atRootValue;
      modalOpen.value = modalValue;
    }

    // NavigatorObserver callbacks can fire during the build phase
    // (the initial route push); notifying listeners then would call
    // setState during build. Defer to after the frame in that case.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _pages.add(route);
    if (route is PopupRoute) _modals.add(route);
    _sync();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _modals.remove(route);
    _sync();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _modals.remove(route);
    _sync();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _pages.remove(oldRoute);
      _modals.remove(oldRoute);
    }
    if (newRoute is PageRoute) _pages.add(newRoute);
    if (newRoute is PopupRoute) _modals.add(newRoute);
    _sync();
  }
}

/// App-wide bottom player overlay (MaterialApp.builder): while a
/// recitation session is active the player stays visible on every tab
/// and pushed screen, with play/pause and a close button that stops
/// the recitation and hides it. Plain in-app playback only — no
/// lock-screen controls (removed in build-11 at the owner's order).
class QubaPlayerOverlay extends StatelessWidget {
  const QubaPlayerOverlay({
    super.key,
    required this.routeObserver,
    required this.child,
    this.navigatorKey,
  });

  final QubaRouteObserver routeObserver;
  final Widget child;

  /// The app Navigator's key: the player floats above the Navigator,
  /// so opening the options sheet must go through this key's context
  /// (the player's own context has no Navigator ancestor).
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final audio = AudioService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([
        audio.sessionListenable,
        routeObserver.atRoot,
        routeObserver.modalOpen,
      ]),
      builder: (context, _) {
        final show = audio.hasActiveSession && !routeObserver.modalOpen.value;
        final bottomInset = MediaQuery.of(context).padding.bottom;
        return Stack(
          children: [
            child,
            if (show)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottomInset + (routeObserver.atRoot.value ? 86 : 12),
                child: Material(
                  type: MaterialType.transparency,
                  child: DefaultTextStyle(
                    // The player floats outside the Navigator's
                    // Scaffolds, so it needs its own Material +
                    // text style (otherwise text falls back to the
                    // debug monospace style and buttons lose ink).
                    style: Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle(),
                    child: _GlobalPlayerBar(navigatorKey: navigatorKey),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GlobalPlayerBar extends StatelessWidget {
  const _GlobalPlayerBar({this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final audio = AudioService.instance;
    final nameNumber = audio.currentName.value;
    final surahNumber = audio.currentSurah.value;
    final ayah = audio.currentAyah.value;
    final ayahMode = surahNumber != null && ayah != null;

    final String title;
    final String subtitle;
    final Widget badge;
    if (nameNumber != null) {
      final name = names99[nameNumber - 1];
      title = name.transliteration;
      subtitle = tr('name_meaning_$nameNumber');
      badge = _NumberBadge(number: nameNumber);
    } else {
      final surah = QuranRepository.instance.surah(surahNumber!);
      title = ayahMode ? '${surah.nameEnglish}: $ayah' : surah.nameEnglish;
      subtitle = audio.currentReciter.value.shortName;
      badge = RosetteNumber(number: surah.number, size: 34);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: p.dark
                ? p.shadow
                : const Color(0xFF2E9E7B).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: p.dark
                          ? [const Color(0xCC0E4A38), const Color(0xB3083528)]
                          : [
                              Colors.white.withValues(alpha: 0.52),
                              const Color(0xFFE4F5EA).withValues(alpha: 0.44),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: p.dark
                          ? Colors.white.withValues(alpha: 0.28)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
                    child: Row(
                      children: [
                        badge,
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 32px shrink-wrapped buttons keep the text
                        // column wide enough for the full title at
                        // 390px (the 2026-11-18 vertical-text defect).
                        if (ayahMode)
                          _playerButton(
                            icon: Icons.skip_previous_rounded,
                            iconSize: 24,
                            color: p.ink,
                            label: tr('prev_verse'),
                            onPressed: audio.playPrevAyah,
                          ),
                        StreamBuilder<bool>(
                          stream: audio.player.playingStream,
                          initialData: audio.player.playing,
                          builder: (context, snap) {
                            final playing = snap.data ?? false;
                            return _playerButton(
                              icon: playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              iconSize: 26,
                              color: p.ink,
                              label: playing ? tr('pause') : tr('play'),
                              onPressed: audio.togglePause,
                            );
                          },
                        ),
                        if (ayahMode)
                          _playerButton(
                            icon: Icons.skip_next_rounded,
                            iconSize: 24,
                            color: p.ink,
                            label: tr('next_verse'),
                            onPressed: audio.playNextAyah,
                          ),
                        if (nameNumber == null)
                          _playerButton(
                            icon: Icons.tune_rounded,
                            iconSize: 22,
                            color: p.muted,
                            label: tr('player_options'),
                            onPressed: () => showPlayerOptionsSheet(
                              navigatorKey?.currentContext ?? context,
                            ),
                          ),
                        _playerButton(
                          icon: Icons.close_rounded,
                          iconSize: 22,
                          color: p.muted,
                          label: tr('stop'),
                          onPressed: audio.stop,
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<Duration>(
                    stream: audio.player.positionStream,
                    builder: (context, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final dur = audio.player.duration;
                      final value = (dur != null && dur.inMilliseconds > 0)
                          ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                              0.0,
                              1.0,
                            )
                          : 0.0;
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 3,
                        backgroundColor: p.emerald.withValues(alpha: 0.15),
                        color: p.emerald,
                      );
                    },
                  ),
                ],
              ),
              // Specular glass highlight along the top edge.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 34,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: p.dark ? 0.16 : 0.55),
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
  }

  Widget _playerButton({
    required IconData icon,
    required double iconSize,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    // No Tooltip here: the player floats above the Navigator (in
    // MaterialApp.builder), outside its Overlay, and Tooltip asserts
    // without an Overlay ancestor. Semantics carries the label.
    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        icon: Icon(icon),
        iconSize: iconSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        color: color,
        onPressed: onPressed,
      ),
    );
  }
}

/// Green rosette badge with the name's number (99 Names player).
class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(38, 38),
            painter: Star8Painter(
              fill: p.emerald,
              stroke: Colors.white.withValues(alpha: 0.85),
              strokeWidth: 1.2,
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: p.onEmerald,
            ),
          ),
        ],
      ),
    );
  }
}
