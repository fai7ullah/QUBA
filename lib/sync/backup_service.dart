import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../i18n.dart';
import 'sync_payload.dart';

/// The outcome of one backup operation. [ok] is false for every
/// failure (bad file, no file chosen, share-sheet error) and [message]
/// is a translated, user-facing explanation. Nothing in this file
/// ever throws.
class BackupResult {
  const BackupResult(this.ok, this.message);
  final bool ok;
  final String message;
}

/// Local backup & restore: export the user's data to a JSON file and
/// import it back. Works fully offline, no account needed — the
/// fallback for users who never set up cloud sync.
///
/// File format (same payload shape as cloud sync, plus a header):
/// ```json
/// {
///   "format": "quba-backup",
///   "version": 1,
///   "exported_at": "2026-11-21T12:00:00.000Z",
///   "data": { ...SyncPayload... }
/// }
/// ```
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String formatName = 'quba-backup';
  static const int formatVersion = 1;

  /// Build the backup JSON for [state].
  static String buildBackupJson(AppState state) {
    final map = {
      'format': formatName,
      'version': formatVersion,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'data': SyncPayload.toJson(state),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Validate [json] and apply it to [state] (defaults to the global
  /// app state). Returns `ok: false` for malformed JSON, a wrong
  /// format/version, a missing `data` object, or a payload with no
  /// usable field — never throws on bad input.
  static BackupResult restoreFromJson(String json, [AppState? state]) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        return BackupResult(false, tr('backup_invalid'));
      }
      if (decoded['format'] != formatName ||
          decoded['version'] != formatVersion) {
        return BackupResult(false, tr('backup_invalid'));
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        return BackupResult(false, tr('backup_invalid'));
      }
      final applied = SyncPayload.apply(state ?? appState, data);
      if (!applied) return BackupResult(false, tr('backup_invalid'));
      return BackupResult(true, tr('backup_imported'));
    } catch (_) {
      return BackupResult(false, tr('backup_invalid'));
    }
  }

  /// Write the backup to a temp file and open the system share sheet
  /// so the user can save it (Files, Drive, WhatsApp, …).
  Future<BackupResult> exportToFile([AppState? state]) async {
    try {
      final s = state ?? appState;
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp = '${now.year.toString().padLeft(4, '0')}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';
      final file = File('${dir.path}/quba-backup-$stamp.json');
      await file.writeAsString(buildBackupJson(s));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'QUBA backup',
        ),
      );
      return BackupResult(true, tr('backup_exported'));
    } catch (_) {
      return BackupResult(false, tr('backup_failed'));
    }
  }

  /// Let the user pick a `.json` backup file and restore it.
  /// file_picker v13 API: [FilePicker.pickFile] returns a single
  /// [PlatformFile] (null on cancel); bytes are read with
  /// [PlatformFile.readAsBytes] (the old `withData` flag is gone).
  Future<BackupResult> importFromPicker([AppState? state]) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null) {
        return BackupResult(false, tr('backup_no_file'));
      }
      String? text;
      if (picked.path != null) {
        text = await File(picked.path!).readAsString();
      } else {
        final bytes = await picked.readAsBytes();
        if (bytes.isNotEmpty) text = utf8.decode(bytes);
      }
      if (text == null) return BackupResult(false, tr('backup_failed'));
      return restoreFromJson(text, state);
    } catch (_) {
      return BackupResult(false, tr('backup_failed'));
    }
  }
}
