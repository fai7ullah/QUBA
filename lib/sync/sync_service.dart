import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../i18n.dart';
import 'sync_config.dart';
import 'sync_payload.dart';

/// The outcome of one sync operation. [ok] is false for every failure
/// (unconfigured, offline, not signed in, server error) and [message]
/// is a translated, user-facing explanation. Nothing in this file ever
/// throws.
class SyncResult {
  const SyncResult(this.ok, this.message);
  final bool ok;
  final String message;
}

/// Optional cloud sync of bookmarks, notes, prayer log, streak,
/// khatma progress and tasbih totals — one row per user in the
/// `user_data` table (see the setup SQL in the build report).
///
/// OFFLINE-FIRST: the app works fully without an account and without
/// a configured project. When [SyncConfig.isConfigured] is false,
/// [init] returns immediately and every other method returns
/// `ok: false` with the "not set up yet" message — no crash, no
/// network. When the device is offline, Supabase throws and every
/// method returns `ok: false` with the failure message instead.
///
/// Conflict rule: last-write-wins by the row's `updated_at`. Download
/// applies the server row only when it is newer than the last sync;
/// upload always pushes the current local state with a fresh
/// `updated_at`.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  /// SharedPreferences keys this service owns.
  static const String lastSyncAtKey = 'sync_last_sync_at';
  static const String lastServerUpdatedAtKey = 'sync_last_server_updated_at';

  bool _initialized = false;
  bool get initialized => _initialized;

  /// Initialize Supabase. Returns immediately (no crash, no network)
  /// when the project is not configured yet.
  Future<SyncResult> init() async {
    if (!SyncConfig.isConfigured) {
      return SyncResult(false, tr('sync_not_setup'));
    }
    if (_initialized) return SyncResult(true, tr('sync_success'));
    try {
      await Supabase.initialize(
        url: SyncConfig.supabaseUrl,
        anonKey: SyncConfig.supabaseAnonKey,
      );
      _initialized = true;
      return SyncResult(true, tr('sync_success'));
    } catch (_) {
      return SyncResult(false, tr('sync_failed'));
    }
  }

  /// True only after a successful [init] with a configured project.
  bool get _ready => SyncConfig.isConfigured && _initialized;

  /// The signed-in user's email, or null when signed out / unconfigured.
  String? get currentUserEmail {
    try {
      if (!_ready) return null;
      return Supabase.instance.client.auth.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => currentUserEmail != null;

  /// When the last successful sync finished (local clock), or null.
  Future<DateTime?> lastSyncAt() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(lastSyncAtKey);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _stampLastSync() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          lastSyncAtKey, DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      // Non-fatal: the sync itself already succeeded.
    }
  }

  Future<DateTime?> _lastServerUpdatedAt() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(lastServerUpdatedAtKey);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeServerUpdatedAt(DateTime at) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          lastServerUpdatedAtKey, at.toUtc().toIso8601String());
    } catch (_) {
      // Non-fatal.
    }
  }

  // ------------------------------------------------------------------
  // Auth (email + password)
  // ------------------------------------------------------------------

  Future<SyncResult> signUp(String email, String password) async {
    if (!_ready) return SyncResult(false, tr('sync_not_setup'));
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) {
        return SyncResult(false, tr('sync_signup_failed'));
      }
      return SyncResult(true, tr('sync_signed_up'));
    } catch (_) {
      return SyncResult(false, tr('sync_signup_failed'));
    }
  }

  Future<SyncResult> signIn(String email, String password) async {
    if (!_ready) return SyncResult(false, tr('sync_not_setup'));
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) {
        return SyncResult(false, tr('sync_signin_failed'));
      }
      return SyncResult(true, tr('sync_success'));
    } catch (_) {
      return SyncResult(false, tr('sync_signin_failed'));
    }
  }

  Future<SyncResult> signOut() async {
    if (!_ready) return SyncResult(false, tr('sync_not_setup'));
    try {
      await Supabase.instance.client.auth.signOut();
      return SyncResult(true, tr('sync_signed_out'));
    } catch (_) {
      return SyncResult(false, tr('sync_failed'));
    }
  }

  // ------------------------------------------------------------------
  // Upload / download / sync-now
  // ------------------------------------------------------------------

  /// Push the current local state to the cloud (one upserted row).
  Future<SyncResult> upload([AppState? state]) async {
    final s = state ?? appState;
    if (!_ready) return SyncResult(false, tr('sync_not_setup'));
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return SyncResult(false, tr('sync_not_signed_in'));
      final now = DateTime.now().toUtc();
      await Supabase.instance.client.from(SyncConfig.tableName).upsert({
        'user_id': user.id,
        'data': SyncPayload.toJson(s),
        'updated_at': now.toIso8601String(),
      });
      await _storeServerUpdatedAt(now);
      await _stampLastSync();
      return SyncResult(true, tr('sync_success'));
    } catch (_) {
      return SyncResult(false, tr('sync_failed'));
    }
  }

  /// Pull the cloud row and apply it — only when the server copy is
  /// newer than the last one we saw (last-write-wins by `updated_at`).
  /// When there is no cloud row yet, that is not an error: it just
  /// means nothing was ever uploaded.
  Future<SyncResult> download([AppState? state]) async {
    final s = state ?? appState;
    if (!_ready) return SyncResult(false, tr('sync_not_setup'));
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return SyncResult(false, tr('sync_not_signed_in'));
      final row = await Supabase.instance.client
          .from(SyncConfig.tableName)
          .select('data, updated_at')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) {
        return SyncResult(true, tr('sync_no_cloud_data'));
      }
      final serverAt = DateTime.tryParse('${row['updated_at'] ?? ''}');
      final lastSeen = await _lastServerUpdatedAt();
      if (serverAt != null &&
          lastSeen != null &&
          !serverAt.isAfter(lastSeen)) {
        // Our local copy is already as new as the server's.
        await _stampLastSync();
        return SyncResult(true, tr('sync_success'));
      }
      final data = row['data'];
      if (data is! Map<String, dynamic>) {
        return SyncResult(false, tr('sync_failed'));
      }
      final applied = SyncPayload.apply(s, data);
      if (!applied) return SyncResult(false, tr('sync_failed'));
      if (serverAt != null) await _storeServerUpdatedAt(serverAt);
      await _stampLastSync();
      return SyncResult(true, tr('sync_success'));
    } catch (_) {
      return SyncResult(false, tr('sync_failed'));
    }
  }

  /// Download first (so a newer cloud copy wins), then upload the
  /// resulting local state. A failed download still attempts the
  /// upload only when the failure was "no cloud data yet" — any real
  /// error stops the sync so a bad read can never be overwritten.
  Future<SyncResult> syncNow([AppState? state]) async {
    final s = state ?? appState;
    final down = await download(s);
    if (!down.ok) return down;
    return upload(s);
  }
}
