import 'package:shared_preferences/shared_preferences.dart';

/// Daily Ramadan goals checklist, persisted per day in SharedPreferences
/// under keys this file owns (`ramadan_goals_yyyy-MM-dd`). Kept out of
/// AppState on purpose: it is Ramadan-only state, not app state.
/// Never throws — every call is guarded, and a storage failure just
/// means the checklist does not persist for that day.
class RamadanGoals {
  static const List<String> goalKeys = [
    'quran',
    'taraweeh',
    'charity',
    'dua',
    'dhikr',
  ];

  static String keyFor(DateTime date) =>
      'ramadan_goals_${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// The goals ticked off on [date] (empty when none were saved).
  static Future<Set<String>> load(DateTime date) async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList(keyFor(date)) ?? const [])
          .where((g) => goalKeys.contains(g))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> save(DateTime date, Set<String> done) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(keyFor(date), done.toList());
    } catch (_) {
      // Storage failure: the checklist just does not persist.
    }
  }

  /// Toggle one goal for [date]; returns the new done-set.
  static Future<Set<String>> toggle(DateTime date, String goal) async {
    final done = await load(date);
    if (!done.remove(goal)) done.add(goal);
    await save(date, done);
    return done;
  }
}
