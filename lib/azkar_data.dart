import 'content.dart';

/// Morning, evening and after-prayer Azkar.
///
/// CONTENT RULE (same as the rest of the app): no Arabic is written here.
/// Every item points at an existing, sourced entry in [duas] (content.dart)
/// by its exact title, and only adds how many times it is recited. The
/// Arabic text, transliteration, meaning and source all come from that
/// entry, so Azkar can never drift from the Duas library.
class AzkarItemDef {
  const AzkarItemDef(this.duaTitle, this.count);

  /// Exact [Dua.title] in content.dart.
  final String duaTitle;

  /// How many times it is recited (taps needed to complete it).
  final int count;
}

class AzkarSetDef {
  const AzkarSetDef(this.id, this.titleKey, this.items);

  /// 'morning' | 'evening' | 'after' — also the key stored per day.
  final String id;
  final String titleKey;
  final List<AzkarItemDef> items;
}

/// An item resolved against the Duas library.
class ResolvedAzkar {
  const ResolvedAzkar(this.index, this.dua, this.count);

  /// Position in the set's declared list (stable key for stored taps).
  final int index;
  final Dua dua;
  final int count;
}

class AzkarData {
  AzkarData._();

  static const List<AzkarSetDef> sets = [
    AzkarSetDef('morning', 'azkar_morning', [
      AzkarItemDef('Ayat al-Kursi', 1),
      AzkarItemDef('Al-Ikhlas, Al-Falaq, An-Nas', 3),
      AzkarItemDef('Sayyidul Istighfar — the master of seeking forgiveness', 1),
      AzkarItemDef('Protection from all harm', 3),
      AzkarItemDef('I am pleased with Allah as my Lord', 3),
      AzkarItemDef('Allah is enough for me', 7),
      AzkarItemDef('Glory be to Allah, as many times as His creation', 3),
      AzkarItemDef('Glory be to Allah and praise Him', 100),
      AzkarItemDef('None has the right to be worshipped but Allah', 100),
    ]),
    AzkarSetDef('evening', 'azkar_evening', [
      AzkarItemDef('Ayat al-Kursi', 1),
      AzkarItemDef('Al-Ikhlas, Al-Falaq, An-Nas', 3),
      AzkarItemDef('Sayyidul Istighfar — the master of seeking forgiveness', 1),
      AzkarItemDef('Protection from all harm', 3),
      AzkarItemDef('I seek refuge in the perfect words of Allah', 3),
      AzkarItemDef('I am pleased with Allah as my Lord', 3),
      AzkarItemDef('Allah is enough for me', 7),
      AzkarItemDef('Glory be to Allah and praise Him', 100),
    ]),
    AzkarSetDef('after', 'azkar_after', [
      AzkarItemDef('After finishing the prayer', 1),
      AzkarItemDef('None can withhold what You give', 1),
      AzkarItemDef('Glorifying Allah 33 times', 1),
      AzkarItemDef('Ayat al-Kursi', 1),
    ]),
  ];

  static AzkarSetDef byId(String id) {
    for (final s in sets) {
      if (s.id == id) return s;
    }
    return sets.first;
  }

  static Dua? _duaByTitle(String title) {
    for (final d in duas) {
      if (d.title == title) return d;
    }
    return null;
  }

  /// The set's items that exist in the Duas library (a title that is not
  /// found is skipped rather than crashing; a unit test guards against it).
  static List<ResolvedAzkar> resolve(String setId) {
    final def = byId(setId);
    final out = <ResolvedAzkar>[];
    for (var i = 0; i < def.items.length; i++) {
      final dua = _duaByTitle(def.items[i].duaTitle);
      if (dua != null) out.add(ResolvedAzkar(i, dua, def.items[i].count));
    }
    return out;
  }
}
