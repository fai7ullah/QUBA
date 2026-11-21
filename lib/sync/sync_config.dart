/// Central cloud-sync configuration.
///
/// The Supabase project does NOT exist yet — Umar creates it on his
/// .fs account (his main account is at the 2-project free limit), runs
/// the setup SQL, then pastes the project URL and anon key here.
/// Until then both values stay EMPTY and [isConfigured] is false, which
/// makes the whole sync layer a no-op: the app works fully offline and
/// nothing ever touches the network for sync.
class SyncConfig {
  /// Supabase project URL, e.g. https://xyzcompany.supabase.co
  static const String supabaseUrl = '';

  /// Supabase anon (public) key for the project.
  static const String supabaseAnonKey = '';

  /// The one table sync uses: one row per user, whole state as JSON.
  static const String tableName = 'user_data';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
