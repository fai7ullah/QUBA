import '../app_state.dart';

/// The ONE JSON shape for user data, shared by cloud sync and local
/// backup/restore so the two can never drift apart:
///
/// ```json
/// {
///   "bookmarks": ["1:1", "2:255"],
///   "notes": {"2:255": "free text"},
///   "prayer_log": {"2026-11-21": ["Fajr", "Dhuhr"]},
///   "reading_days": [20750],
///   "khatma": {"days": 30, "start_global": 0, "start_day": 20750},
///   "tasbih_totals": {"subhanallah": 100},
///   "last_read": {"surah": 2, "ayah": 5}
/// }
/// ```
///
/// Settings (language, theme, location, reciter, translation) are
/// deliberately NOT synced: they are per-device choices. Downloads are
/// not synced either (they are files on the device).
class SyncPayload {
  /// Build the payload from [state]. Never throws.
  static Map<String, dynamic> toJson(AppState state) {
    try {
      return {
        'bookmarks': state.bookmarks.toList()..sort(),
        'notes': Map<String, String>.from(state.notes),
        'prayer_log': {
          for (final e in state.prayerLog.entries)
            e.key: e.value.toList()..sort(),
        },
        'reading_days': state.readingDays.toList()..sort(),
        'khatma': {
          'days': state.khatmaDays,
          'start_global': state.khatmaStartGlobal,
          'start_day': state.khatmaStartDay,
        },
        'tasbih_totals': Map<String, int>.from(state.tasbihTotals),
        'last_read': {
          'surah': state.lastReadSurah,
          'ayah': state.lastReadAyah,
        },
      };
    } catch (_) {
      return {};
    }
  }

  /// Apply a payload to [state] via [AppState.update] (so it is
  /// persisted + listeners are notified). Every field is optional and
  /// every value is validated — a malformed field is skipped, never
  /// fatal. Returns false only when [data] has no usable field at all.
  static bool apply(AppState state, Map<String, dynamic> data) {
    try {
      var appliedAny = false;

      final bookmarks = _stringList(data['bookmarks']);
      final notes = _stringMap(data['notes']);
      final prayerLog = _prayerLog(data['prayer_log']);
      final readingDays = _intList(data['reading_days']);
      final tasbihTotals = _intMap(data['tasbih_totals']);

      final khatma = data['khatma'];
      int? khatmaDays;
      int? khatmaStartGlobal;
      int? khatmaStartDay;
      if (khatma is Map<String, dynamic>) {
        khatmaDays = _asInt(khatma['days']);
        khatmaStartGlobal = _asInt(khatma['start_global']);
        khatmaStartDay = _asInt(khatma['start_day']);
      }

      final lastRead = data['last_read'];
      int? lastSurah;
      int? lastAyah;
      if (lastRead is Map<String, dynamic>) {
        final s = _asInt(lastRead['surah']);
        final a = _asInt(lastRead['ayah']);
        if (s != null && s >= 1 && s <= 114) lastSurah = s;
        if (a != null && a >= 1) lastAyah = a;
      }

      appliedAny = bookmarks != null ||
          notes != null ||
          prayerLog != null ||
          readingDays != null ||
          tasbihTotals != null ||
          khatmaDays != null ||
          lastSurah != null;
      if (!appliedAny) return false;

      state.update(() {
        if (bookmarks != null) state.bookmarks = bookmarks.toSet();
        if (notes != null) state.notes = notes;
        if (prayerLog != null) state.prayerLog = prayerLog;
        if (readingDays != null) state.readingDays = readingDays.toSet();
        if (tasbihTotals != null) state.tasbihTotals = tasbihTotals;
        if (khatmaDays != null) state.khatmaDays = khatmaDays;
        if (khatmaStartGlobal != null) {
          state.khatmaStartGlobal = khatmaStartGlobal;
        }
        if (khatmaStartDay != null) state.khatmaStartDay = khatmaStartDay;
        if (lastSurah != null) state.lastReadSurah = lastSurah;
        if (lastAyah != null) state.lastReadAyah = lastAyah;
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------
  // Defensive parsing helpers: wrong types become null (field skipped).
  // ------------------------------------------------------------------

  static List<String>? _stringList(dynamic v) {
    if (v is! List) return null;
    final out = <String>[];
    for (final e in v) {
      if (e is String) out.add(e);
    }
    return out;
  }

  static List<int>? _intList(dynamic v) {
    if (v is! List) return null;
    final out = <int>[];
    for (final e in v) {
      final n = _asInt(e);
      if (n != null) out.add(n);
    }
    return out;
  }

  static Map<String, String>? _stringMap(dynamic v) {
    if (v is! Map) return null;
    final out = <String, String>{};
    for (final e in v.entries) {
      if (e.key is String && e.value is String) out[e.key as String] = e.value as String;
    }
    return out;
  }

  static Map<String, int>? _intMap(dynamic v) {
    if (v is! Map) return null;
    final out = <String, int>{};
    for (final e in v.entries) {
      final n = _asInt(e.value);
      if (e.key is String && n != null) out[e.key as String] = n;
    }
    return out;
  }

  static Map<String, Set<String>>? _prayerLog(dynamic v) {
    if (v is! Map) return null;
    final out = <String, Set<String>>{};
    for (final e in v.entries) {
      if (e.key is! String || e.value is! List) continue;
      final prayers = <String>{};
      for (final p in e.value as List) {
        if (p is String) prayers.add(p);
      }
      if (prayers.isNotEmpty) out[e.key as String] = prayers;
    }
    return out;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}
