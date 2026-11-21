import 'package:flutter/material.dart';

import '../app_state.dart';
import '../i18n.dart';
import '../sync/backup_service.dart';
import '../sync/sync_config.dart';
import '../sync/sync_service.dart';
import '../theme.dart';
import '../widgets.dart';

/// Cloud sync + local backup & restore.
///
/// * When the Supabase project is not configured yet ([SyncConfig]
///   still has empty URL/key), the sync section explains that and
///   shows the setup steps as plain text. No sign-in form, no network.
/// * When configured, it shows the sign-in form (or the signed-in
///   account), a Sync now button and the last-sync time.
/// * The Backup & restore section is always available: it works
///   fully offline with no account needed.
///
/// Everything here is offline-safe: every operation returns a result
/// object and failures show as snackbars, never crashes.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  DateTime? _lastSync;
  String? _email;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final last = await SyncService.instance.lastSyncAt();
    if (!mounted) return;
    setState(() {
      _lastSync = last;
      _email = SyncService.instance.currentUserEmail;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _run(Future<SyncResult> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await op();
      _snack(result.message);
    } finally {
      if (mounted) setState(() => _busy = false);
      _refreshStatus();
    }
  }

  Future<void> _runBackup(Future<BackupResult> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await op();
      _snack(result.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _lastSyncText() {
    if (_lastSync == null) return tr('sync_never');
    final local = _lastSync!.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return trf('sync_last_sync', {
      'time': '${local.day}/${local.month}/${local.year} $hh:$mm',
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = QubaPalette.of(context);
    final configured = SyncConfig.isConfigured;
    return Scaffold(
      body: QubaBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitleRow(
                      title: tr('sync_title'),
                      subtitle: tr('sync_subtitle'),
                    ),
                    const SizedBox(height: 16),
                    if (!configured) _notSetupCard(p) else _accountCard(p),
                    const SizedBox(height: 20),
                    SectionLabel(tr('backup_title')),
                    const SizedBox(height: 4),
                    Text(
                      tr('backup_subtitle'),
                      style: TextStyle(fontSize: 13.5, color: p.muted),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _runBackup(
                                      BackupService.instance.exportToFile),
                            icon: const Icon(Icons.upload_rounded),
                            label: Text(
                              tr('backup_export'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: p.emerald,
                              foregroundColor: p.onEmerald,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _runBackup(BackupService
                                    .instance.importFromPicker),
                            icon: const Icon(Icons.download_rounded),
                            label: Text(
                              tr('backup_import'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Not configured: explanation + setup steps (plain text, no network)
  // ------------------------------------------------------------------

  Widget _notSetupCard(QubaPalette p) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: p.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('sync_not_setup'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr('sync_account_note'),
            style: TextStyle(fontSize: 14, color: p.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            tr('sync_setup_title'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 8),
          _step(p, '1', tr('sync_step_1')),
          const SizedBox(height: 6),
          _step(p, '2', tr('sync_step_2')),
          const SizedBox(height: 6),
          _step(p, '3', tr('sync_step_3')),
        ],
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

  // ------------------------------------------------------------------
  // Configured: sign-in form / account + Sync now
  // ------------------------------------------------------------------

  Widget _accountCard(QubaPalette p) {
    final signedIn = _email != null;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (signedIn) ...[
            Row(
              children: [
                Icon(Icons.account_circle_rounded,
                    size: 28, color: p.emerald),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trf('sync_signed_in_as', {'email': _email!}),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _lastSyncText(),
              style: TextStyle(fontSize: 13.5, color: p.muted),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(SyncService.instance.syncNow),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                _busy ? tr('sync_syncing') : tr('sync_now'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: p.emerald,
                foregroundColor: p.onEmerald,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed:
                  _busy ? null : () => _run(SyncService.instance.signOut),
              child: Text(
                tr('sync_sign_out'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: tr('sync_email'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('sync_password'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => SyncService.instance.signIn(
                        _emailController.text,
                        _passwordController.text,
                      )),
              style: FilledButton.styleFrom(
                backgroundColor: p.emerald,
                foregroundColor: p.onEmerald,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                tr('sync_sign_in'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => SyncService.instance.signUp(
                        _emailController.text,
                        _passwordController.text,
                      )),
              child: Text(
                tr('sync_sign_up'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('sync_account_note'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.muted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
