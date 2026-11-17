import 'app_state.dart'; // for the global appState singleton

/// UI strings in English (default), Pashto, Dari/Farsi and Urdu
/// (ported from the native app's Strings.java — same keys, same values).
/// Arabic content (Quran, duas, names) is never translated here — this is
/// app-interface text only. PS/FA/UR strings are DRAFTS written in simple,
/// everyday wording; they await the owner's correction.
class QubaStrings {
  static const List<String> langs = ['en', 'ps', 'fa', 'ur'];
  static const Map<String, String> langNames = {'en': 'English', 'ps': 'پښتو', 'fa': 'دری', 'ur': 'اردو'};

  static const Map<String, Map<String, String>> _strings = {
    "home": {'en': "Home", 'ps': "کور", 'fa': "خانه", 'ur': "ہوم"},
    "quran": {'en': "Quran", 'ps': "قرآن", 'fa': "قرآن", 'ur': "قرآن"},
    "prayer": {'en': "Prayer", 'ps': "لمونځ", 'fa': "نماز", 'ur': "نماز"},
    "duas": {'en': "Duas", 'ps': "دعاګانې", 'fa': "دعاها", 'ur': "دعائیں"},
    "more": {'en': "More", 'ps': "نور", 'fa': "بیشتر", 'ur': "مزید"},
    "settings": {'en': "Settings", 'ps': "ترتیبات", 'fa': "تنظیمات", 'ur': "ترتیبات"},
    "tagline": {'en': "Your Islamic Companion", 'ps': "ستاسو اسلامي ملګری", 'fa': "همراه اسلامی شما", 'ur': "آپ کا اسلامی ساتھی"},
    "greeting": {'en': "Assalamu alaikum", 'ps': "السلام علیکم", 'fa': "سلام علیکم", 'ur': "السلام علیکم"},
    "next_prayer": {'en': "NEXT PRAYER", 'ps': "راتلونکی لمونځ", 'fa': "نماز بعدی", 'ur': "اگلی نماز"},
    "in": {'en': "in", 'ps': "په", 'fa': "در", 'ur': "میں"},
    "today": {'en': "Today", 'ps': "نن", 'fa': "امروز", 'ur': "آج"},
    "continue_reading": {'en': "CONTINUE READING", 'ps': "لوستل دوام ورکړئ", 'fa': "ادامهٔ مطالعه", 'ur': "پڑھنا جاری رکھیں"},
    "today_card": {'en': "TODAY", 'ps': "نن", 'fa': "امروز", 'ur': "آج"},
    "verse_of_day": {'en': "Verse of the day", 'ps': "د نن ورځې آیت", 'fa': "آیهٔ امروز", 'ur': "آج کی آیت"},
    "dua_of_day": {'en': "Dua of the day", 'ps': "د نن ورځې دعا", 'fa': "دعای امروز", 'ur': "آج کی دعا"},
    "hadith_of_day": {'en': "Hadith of the day", 'ps': "د نن ورځې حدیث", 'fa': "حدیث امروز", 'ur': "آج کی حدیث"},
    "qibla": {'en': "Qibla", 'ps': "قبله", 'fa': "قبله", 'ur': "قبلہ"},
    "calendar": {'en': "Calendar", 'ps': "کلیزه", 'fa': "تقویم", 'ur': "کیلنڈر"},
    "khatma": {'en': "Khatma plan", 'ps': "د ختمې پلان", 'fa': "برنامهٔ ختم", 'ur': "ختم کا منصوبہ"},
    "tasbih": {'en': "Tasbih", 'ps': "تسبیح", 'fa': "تسبیح", 'ur': "تسبیح"},
    "names99": {'en': "99 Names", 'ps': "د الله ۹۹ نومونه", 'fa': "۹۹ نام الله", 'ur': "اللہ کے 99 نام"},
    "search_surah": {'en': "Search surah…", 'ps': "سورت ولټوئ…", 'fa': "جستجوی سوره…", 'ur': "سورت تلاش کریں…"},
    "search_quran": {'en': "Search the Quran", 'ps': "په قرآن کې لټون", 'fa': "جستجو در قرآن", 'ur': "قرآن میں تلاش"},
    "appearance": {'en': "Appearance", 'ps': "بڼه", 'fa': "ظاهر", 'ur': "ظاہری شکل"},
    "language": {'en': "Language", 'ps': "ژبه", 'fa': "زبان", 'ur': "زبان"},
    "calculation": {'en': "Calculation", 'ps': "محاسبه", 'fa': "محاسبه", 'ur': "حساب"},
    "location": {'en': "Location", 'ps': "ځای", 'fa': "مکان", 'ur': "مقام"},
    "reminders": {'en': "Prayer reminders", 'ps': "د لمانځه یادونې", 'fa': "یادآوری نماز", 'ur': "نماز کی یاد دہانی"},
    "about": {'en': "About QUBA", 'ps': "د QUBA په اړه", 'fa': "دربارهٔ قبا", 'ur': "قبا کے بارے میں"},
    "verses": {'en': "verses", 'ps': "آیتونه", 'fa': "آیات", 'ur': "آیات"},
    "of_quran": {'en': "% of the Quran", 'ps': "٪ د قرآن", 'fa': "٪ از قرآن", 'ur': "قرآن کا ٪"},
    "loading": {'en': "Loading the Quran…", 'ps': "قرآن لېږدول کېږي…", 'fa': "قرآن در حال بارگذاری…", 'ur': "قرآن لوڈ ہو رہا ہے…"},
    "start_fatihah": {'en': "Start with Al-Fatihah", 'ps': "له الفاتحې پیل وکړئ", 'fa': "با فاتحه شروع کنید", 'ur': "الفاتحہ سے شروع کریں"},
  };

  static bool isRtl(String lang) => lang != 'en';

  /// Returns the string for [lang], falling back to English, then to the key itself.
  static String get(String lang, String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['en'] ?? key;
  }
}

/// Shortcut: translate with the current app language.
String tr(String key) => QubaStrings.get(appState.lang, key);
