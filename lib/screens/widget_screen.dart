import 'package:flutter/material.dart';

import '../app_state.dart';
import '../homewidget/home_widget_service.dart';
import '../i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Home-screen widget setup (Extras → Home widget): an enable toggle,
/// how to add the widget from the launcher, a manual refresh button,
/// and the honest note that the countdown can lag by up to 30 minutes
/// (an Android platform limit, not a bug — see HomeWidgetService).
///
/// The widget itself is native code (QubaWidgetProvider.kt); this
/// screen only controls whether the app pushes data to it.
class WidgetScreen extends StatefulWidget {
  const WidgetScreen({super.key});

  @override
  State<WidgetScreen> createState() => _WidgetScreenState();
}

class _WidgetScreenState extends State<WidgetScreen> {
  bool _enabled = true;
  bool _loaded = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    HomeWidgetService.enabled.then((v) {
      if (mounted) {
        setState(() {
          _enabled = v;
          _loaded = true;
        });
      }
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await HomeWidgetService.setEnabled(value);
    if (value) await HomeWidgetService.update(appState);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await HomeWidgetService.update(appState);
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('widget_refreshed'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              TitleRow(
                title: tr('home_widget'),
                subtitle: tr('widget_subtitle'),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(Icons.widgets_rounded,
                          size: 28, color: p.emerald),
                      title: Text(
                        tr('widget_enable'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(tr('widget_enable_desc')),
                      value: _enabled,
                      onChanged: _loaded ? _toggle : null,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _refreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          tr('widget_refresh'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _refreshing ? null : _refresh,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('widget_how'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _step(p, '1', tr('widget_step_1')),
                    const SizedBox(height: 10),
                    _step(p, '2', tr('widget_step_2')),
                    const SizedBox(height: 10),
                    _step(p, '3', tr('widget_step_3')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('widget_note'),
                style: TextStyle(fontSize: 13, color: p.muted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(QubaPalette p, String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.activeFill,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.emerald,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: p.ink, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
