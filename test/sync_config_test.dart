import 'package:flutter_test/flutter_test.dart';

import 'package:quba/sync/sync_config.dart';

/// Sync config defaults: no Supabase project exists yet, so the URL
/// and key are empty and the sync layer must stay a no-op.
/// (When Umar creates the project and pastes real values, this test
/// is expected to change with the config.)
void main() {
  test('unconfigured by default: empty URL and key', () {
    expect(SyncConfig.supabaseUrl, isEmpty);
    expect(SyncConfig.supabaseAnonKey, isEmpty);
    expect(SyncConfig.isConfigured, isFalse);
  });

  test('table name is user_data', () {
    expect(SyncConfig.tableName, 'user_data');
  });
}
