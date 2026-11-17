import 'app_state.dart'; // for the global appState singleton

/// UI strings in English (default), Pashto, Dari/Farsi, Urdu and Arabic.
///
/// Every user-visible string in the app lives here — UI chrome, settings,
/// dialogs, notifications, and the short data labels shown in the UI
/// (prayer names, month/weekday names, notable days, the 99 Names'
/// meanings, surah meanings, juz names, dua titles and categories).
///
/// NOT translated here (separate features / kept as-is): the Quran
/// translation (Pickthall English), dua and hadith full texts,
/// transliterations (Latin-script Arabic), the brand "QUBA", proper names,
/// and the Arabic Quran text itself.
///
/// Translations were researched from standard published wording (Urdu
/// surah-meaning and Asma-ul-Husna lists, standard Persian/Dari and
/// Pashto Islamic terms) in simple, everyday wording.
class QubaStrings {
  static const List<String> langs = ['en', 'ps', 'fa', 'ur', 'ar'];
  static const Map<String, String> langNames = {'en': 'English', 'ps': 'پښتو', 'fa': 'دری', 'ur': 'اردو', 'ar': 'العربية'};

  static const Map<String, Map<String, String>> _strings = {
    // ---- Original 32 keys (kept, values revised where better wording exists) ----
    "home": {'en': "Home", 'ps': "کور", 'fa': "خانه", 'ur': "ہوم", 'ar': "الرئيسية"},
    "quran": {'en': "Quran", 'ps': "قرآن", 'fa': "قرآن", 'ur': "قرآن", 'ar': "القرآن"},
    "prayer": {'en': "Prayer", 'ps': "لمونځ", 'fa': "نماز", 'ur': "نماز", 'ar': "الصلاة"},
    "duas": {'en': "Duas", 'ps': "دعاګانې", 'fa': "دعاها", 'ur': "دعائیں", 'ar': "الأدعية"},
    "more": {'en': "More", 'ps': "نور", 'fa': "بیشتر", 'ur': "مزید", 'ar': "المزيد"},
    "settings": {'en': "Settings", 'ps': "ترتیبات", 'fa': "تنظیمات", 'ur': "ترتیبات", 'ar': "الإعدادات"},
    "tagline": {'en': "Your Islamic Companion", 'ps': "ستاسو اسلامي ملګری", 'fa': "همراه اسلامی شما", 'ur': "آپ کا اسلامی ساتھی", 'ar': "رفيقك الإسلامي"},
    "greeting": {'en': "Assalamu alaikum", 'ps': "السلام علیکم", 'fa': "سلام علیکم", 'ur': "السلام علیکم", 'ar': "السلام عليكم"},
    "next_prayer": {'en': "NEXT PRAYER", 'ps': "راتلونکی لمونځ", 'fa': "نماز بعدی", 'ur': "اگلی نماز", 'ar': "الصلاة القادمة"},
    "in": {'en': "in", 'ps': "په", 'fa': "در", 'ur': "میں", 'ar': "بعد"},
    "today": {'en': "Today", 'ps': "نن", 'fa': "امروز", 'ur': "آج", 'ar': "اليوم"},
    "continue_reading": {'en': "CONTINUE READING", 'ps': "لوستل دوام ورکړئ", 'fa': "ادامهٔ مطالعه", 'ur': "پڑھنا جاری رکھیں", 'ar': "متابعة القراءة"},
    "today_card": {'en': "TODAY", 'ps': "نن", 'fa': "امروز", 'ur': "آج", 'ar': "اليوم"},
    "verse_of_day": {'en': "Verse of the day", 'ps': "د نن ورځې آیت", 'fa': "آیهٔ امروز", 'ur': "آج کی آیت", 'ar': "آية اليوم"},
    "dua_of_day": {'en': "Dua of the day", 'ps': "د نن ورځې دعا", 'fa': "دعای امروز", 'ur': "آج کی دعا", 'ar': "دعاء اليوم"},
    "hadith_of_day": {'en': "Hadith of the day", 'ps': "د نن ورځې حدیث", 'fa': "حدیث امروز", 'ur': "آج کی حدیث", 'ar': "حديث اليوم"},
    "qibla": {'en': "Qibla", 'ps': "قبله", 'fa': "قبله", 'ur': "قبلہ", 'ar': "القبلة"},
    "calendar": {'en': "Calendar", 'ps': "کلیزه", 'fa': "تقویم", 'ur': "کیلنڈر", 'ar': "التقويم"},
    "khatma": {'en': "Khatma plan", 'ps': "د ختمې پلان", 'fa': "برنامهٔ ختم", 'ur': "ختم کا منصوبہ", 'ar': "خطة الختمة"},
    "tasbih": {'en': "Tasbih", 'ps': "تسبیح", 'fa': "تسبیح", 'ur': "تسبیح", 'ar': "التسبيح"},
    "names99": {'en': "99 Names", 'ps': "د الله ۹۹ نومونه", 'fa': "۹۹ نام الله", 'ur': "اللہ کے 99 نام", 'ar': "الأسماء الـ99"},
    "search_surah": {'en': "Search surah…", 'ps': "سورت ولټوئ…", 'fa': "جستجوی سوره…", 'ur': "سورت تلاش کریں…", 'ar': "ابحث عن سورة…"},
    "search_quran": {'en': "Search the Quran", 'ps': "په قرآن کې لټون", 'fa': "جستجو در قرآن", 'ur': "قرآن میں تلاش", 'ar': "ابحث في القرآن"},
    "appearance": {'en': "Appearance", 'ps': "بڼه", 'fa': "ظاهر", 'ur': "ظاہری شکل", 'ar': "المظهر"},
    "language": {'en': "Language", 'ps': "ژبه", 'fa': "زبان", 'ur': "زبان", 'ar': "اللغة"},
    "calculation": {'en': "Calculation", 'ps': "محاسبه", 'fa': "محاسبه", 'ur': "حساب", 'ar': "الحساب"},
    "location": {'en': "Location", 'ps': "ځای", 'fa': "مکان", 'ur': "مقام", 'ar': "الموقع"},
    "reminders": {'en': "Prayer reminders", 'ps': "د لمانځه یادونې", 'fa': "یادآوری نماز", 'ur': "نماز کی یاد دہانی", 'ar': "تذكيرات الصلاة"},
    "about": {'en': "About QUBA", 'ps': "د QUBA په اړه", 'fa': "دربارهٔ قبا", 'ur': "قبا کے بارے میں", 'ar': "عن قُبا"},
    "verses": {'en': "verses", 'ps': "آیتونه", 'fa': "آیات", 'ur': "آیات", 'ar': "آيات"},
    "of_quran": {'en': "% of the Quran", 'ps': "٪ د قرآن", 'fa': "٪ از قرآن", 'ur': "قرآن کا ٪", 'ar': "٪ من القرآن"},
    "loading": {'en': "Loading the Quran…", 'ps': "قرآن لېږدول کېږي…", 'fa': "قرآن در حال بارگذاری…", 'ur': "قرآن لوڈ ہو رہا ہے…", 'ar': "جارٍ تحميل القرآن…"},
    "start_fatihah": {'en': "Start with Al-Fatihah", 'ps': "له الفاتحې پیل وکړئ", 'fa': "با فاتحه شروع کنید", 'ur': "الفاتحہ سے شروع کریں", 'ar': "ابدأ بسورة الفاتحة"},

    // ---- Generic ----
    "cancel": {'en': "Cancel", 'ps': "لغوه کړه", 'fa': "لغو", 'ur': "منسوخ کریں", 'ar': "إلغاء"},
    "set": {'en': "Set", 'ps': "وټاکئ", 'fa': "ثبت", 'ur': "سیٹ کریں", 'ar': "تعيين"},
    "go": {'en': "Go", 'ps': "ځه", 'fa': "برو", 'ur': "جائیں", 'ar': "اذهب"},
    "close": {'en': "Close", 'ps': "بند کړئ", 'fa': "بستن", 'ur': "بند کریں", 'ar': "إغلاق"},
    "go_to": {'en': "Go to", 'ps': "ورشئ", 'fa': "برو به", 'ur': "جائیں", 'ar': "اذهب إلى"},

    // ---- Settings ----
    "theme": {'en': "Theme", 'ps': "تم", 'fa': "تم", 'ur': "تھیم", 'ar': "السمة"},
    "theme_auto": {'en': "Auto", 'ps': "اتومات", 'fa': "خودکار", 'ur': "خودکار", 'ar': "تلقائي"},
    "theme_light": {'en': "Light", 'ps': "روښانه", 'fa': "روشن", 'ur': "روشن", 'ar': "فاتح"},
    "theme_dark": {'en': "Dark", 'ps': "تیاره", 'fa': "تیره", 'ur': "تاریک", 'ar': "داكن"},
    "mushaf_style": {'en': "Mushaf style", 'ps': "د مصحف بڼه", 'fa': "سبک مصحف", 'ur': "مصحف کا انداز", 'ar': "نمط المصحف"},
    "madani": {'en': "Madani", 'ps': "مدني", 'fa': "مدنی", 'ur': "مدنی", 'ar': "مدني"},
    "indopak": {'en': "IndoPak", 'ps': "انډوپاک", 'fa': "هندوپاک", 'ur': "انڈوپاک", 'ar': "هندي باكستاني"},
    "indopak_unavailable": {'en': "IndoPak text not available", 'ps': "د انډوپاک متن نشته", 'fa': "متن هندوپاک در دسترس نیست", 'ur': "انڈوپاک متن دستیاب نہیں", 'ar': "النص الهندي الباكستاني غير متوفر"},
    "arabic_text_size": {'en': "Arabic text size", 'ps': "د عربي متن اندازه", 'fa': "اندازهٔ متن عربی", 'ur': "عربی متن کا سائز", 'ar': "حجم النص العربي"},
    "arabic_text_size_n": {'en': "Arabic text size: {n}", 'ps': "د عربي متن اندازه: {n}", 'fa': "اندازهٔ متن عربی: {n}", 'ur': "عربی متن کا سائز: {n}", 'ar': "حجم النص العربي: {n}"},
    "show_translation": {'en': "Show translation", 'ps': "ژباړه وښایاست", 'fa': "نمایش ترجمه", 'ur': "ترجمہ دکھائیں", 'ar': "إظهار الترجمة"},
    "translation_pickthall": {'en': "English — Pickthall", 'ps': "انګلیسي — پکتال", 'fa': "انگلیسی — پیکتال", 'ur': "انگریزی — پکتھال", 'ar': "الإنجليزية — بيكثال"},
    "show_english_translation": {'en': "Show English translation (Pickthall)", 'ps': "انګلیسي ژباړه وښایاست (پکتال)", 'fa': "نمایش ترجمهٔ انگلیسی (پیکتال)", 'ur': "انگریزی ترجمہ دکھائیں (پکتھال)", 'ar': "إظهار الترجمة الإنجليزية (بيكثال)"},
    "asr_hanafi_sub": {'en': "Shadow = twice the object (default)", 'ps': "سیوری = د څیز دوه برابره (تلواله)", 'fa': "سایه = دو برابر جسم (پیش‌فرض)", 'ur': "سایہ = چیز سے دوگنا (طے شدہ)", 'ar': "الظل = ضعف الجسم (افتراضي)"},
    "asr_shafii_sub": {'en': "Shadow = the object itself", 'ps': "سیوری = څیز په خپله", 'fa': "سایه = خود جسم", 'ur': "سایہ = چیز کے برابر", 'ar': "الظل = الجسم نفسه"},
    "madhab_hanafi": {'en': "Hanafi", 'ps': "حنفي", 'fa': "حنفی", 'ur': "حنفی", 'ar': "حنفي"},
    "madhab_shafii": {'en': "Shafi'i", 'ps': "شافعي", 'fa': "شافعی", 'ur': "شافعی", 'ar': "شافعي"},
    "use_my_location": {'en': "Use my location", 'ps': "زما ځای وکاروئ", 'fa': "از مکان من استفاده کن", 'ur': "میرا مقام استعمال کریں", 'ar': "استخدام موقعي"},
    "kabul_default": {'en': "Kabul default", 'ps': "کابل (تلواله)", 'fa': "کابل (پیش‌فرض)", 'ur': "کابل (طے شدہ)", 'ar': "كابول (افتراضي)"},
    "loc_kabul_default": {'en': "Kabul (default)", 'ps': "کابل (تلواله)", 'fa': "کابل (پیش‌فرض)", 'ur': "کابل (طے شدہ)", 'ar': "كابول (افتراضي)"},
    "loc_my_gps": {'en': "My location (GPS)", 'ps': "زما ځای (GPS)", 'fa': "مکان من (GPS)", 'ur': "میرا مقام (GPS)", 'ar': "موقعي (GPS)"},
    "loc_permission_denied": {'en': "Location permission not granted — keeping current location", 'ps': "د ځای اجازه ورنه کړل شوه — اوسنی ځای ساتل کېږي", 'fa': "اجازهٔ دسترسی به مکان داده نشد — مکان فعلی حفظ شد", 'ur': "مقام کی اجازت نہیں ملی — موجودہ مقام برقرار ہے", 'ar': "لم يُمنح إذن الوصول إلى الموقع — سيُبقى على الموقع الحالي"},
    "loc_updated_gps": {'en': "Location updated from GPS", 'ps': "ځای د GPS څخه تازه شو", 'fa': "مکان از GPS به‌روز شد", 'ur': "مقام GPS سے اپ ڈیٹ ہو گیا", 'ar': "تم تحديث الموقع من GPS"},
    "loc_error": {'en': "Could not get location: {error}", 'ps': "ځای ترلاسه نه شو: {error}", 'fa': "دریافت مکان ممکن نشد: {error}", 'ur': "مقام حاصل نہیں ہو سکا: {error}", 'ar': "تعذّر الحصول على الموقع: {error}"},
    "exact_alarm_note": {'en': "Athan alerts need the exact-alarm permission. On OPPO, Samsung and Xiaomi phones also allow QUBA to run in the background (battery settings) so alerts are not delayed.", 'ps': "د اذان خبرتیاوې د دقیق الارم اجازې ته اړتیا لري. په OPPO، Samsung او Xiaomi تلیفونونو کې QUBA ته په شالید کې د چلېدو اجازه هم ورکړئ (د بیټرۍ ترتیبات) ترڅو خبرتیاوې ونه ځنډېږي.", 'fa': "هشدارهای اذان به اجازهٔ هشدار دقیق نیاز دارند. در گوشی‌های OPPO، سامسونگ و شیائومی همچنین اجازه دهید قبا در پس‌زمینه اجرا شود (تنظیمات باتری) تا هشدارها با تأخیر نرسند.", 'ur': "اذان کی اطلاعات کے لیے درست الارم کی اجازت ضروری ہے۔ OPPO، سام سنگ اور شیاومی فونز پر قبا کو پس منظر میں چلنے کی اجازت بھی دیں (بیٹری کی ترتیبات) تاکہ اطلاعات دیر سے نہ آئیں۔", 'ar': "تحتاج تنبيهات الأذان إلى إذن التنبيه الدقيق. وعلى هواتف OPPO وSamsung وXiaomi اسمح أيضاً لتطبيق قُبا بالعمل في الخلفية (إعدادات البطارية) حتى لا تتأخر التنبيهات."},
    "allow_exact_alarms": {'en': "Allow exact alarms", 'ps': "دقیق الارمونه اجازه ورکړئ", 'fa': "اجازهٔ هشدار دقیق", 'ur': "درست الارم کی اجازت دیں", 'ar': "السماح بالتنبيهات الدقيقة"},
    "exact_alarms_allowed": {'en': "Exact alarms allowed", 'ps': "دقیق الارمونه اجازه ورکړل شول", 'fa': "هشدار دقیق مجاز شد", 'ur': "درست الارم کی اجازت مل گئی", 'ar': "تم السماح بالتنبيهات الدقيقة"},
    "exact_alarm_denied": {'en': "Exact-alarm permission was not granted", 'ps': "د دقیق الارم اجازه ورنه کړل شوه", 'fa': "اجازهٔ هشدار دقیق داده نشد", 'ur': "درست الارم کی اجازت نہیں ملی", 'ar': "لم يُمنح إذن التنبيه الدقيق"},
    "features": {'en': "Features", 'ps': "ځانګړتیاوې", 'fa': "ویژگی‌ها", 'ur': "خصوصیات", 'ar': "الميزات"},
    "about_text": {'en': "Quran text: Uthmani script, Tanzil edition via AlQuran Cloud (quran-uthmani) — 114 surahs, 6,236 verses, verified.\nTranslations: Pickthall (English), Jalandhari (Urdu), Ghomshei (Dari) — all public domain.\nAudio: Mishary Alafasy, Abdul Basit Abdul Samad, Maher Al Muaiqly, Saud Al-Shuraim — Islamic Network / EveryAyah CDN.\nPrayer times: calculated on this device (ported PrayTimes algorithm).\n\nBundled Quran data SHA-256:", 'ps': "د قرآن متن: عثماني رسم الخط، تنزیل نسخه د AlQuran Cloud له لارې (quran-uthmani) — 114 سورتونه، 6,236 آیتونه، تایید شوي.\nژباړې: پکتال (انګلیسي)، جالندھري (اردو)، قمشه‌اي (دري) — ټولې عامه ملکیت.\nغږ: مشاري العفاسي، عبدالباسط عبدالصمد، ماهر المعيقلي، سعود الشريم — اسلامي شبکه / EveryAyah CDN.\nد لمانځه وختونه: په دې وسیله حسابېږي (د PrayTimes الګوریتم).\n\nد قرآن ډاټا SHA-256:", 'fa': "متن قرآن: رسم‌الخط عثمانی، نسخهٔ تنزیل از طریق AlQuran Cloud ‏(quran-uthmani) — 114 سوره، 6,236 آیه، تأییدشده.\nترجمه‌ها: پیکتال (انگلیسی)، جالندهری (اردو)، قمشه‌ای (دری) — همه مالکیت عمومی.\nصدا: مشاری العفاسی، عبدالباسط عبدالصمد، ماهر المعیقلی، سعود الشریم — شبکهٔ اسلامی / EveryAyah CDN.\nاوقات نماز: روی همین دستگاه محاسبه می‌شود (الگوریتم PrayTimes).\n\nSHA-256 داده‌های قرآن:", 'ur': "قرآن کا متن: عثمانی رسم الخط، تنزیل ایڈیشن بذریعہ AlQuran Cloud ‏(quran-uthmani) — 114 سورتیں، 6,236 آیات، تصدیق شدہ۔\nتراجم: پکتھال (انگریزی)، جالندھری (اردو)، قمشئی (دری) — سب عوامی ملکیت۔\nآڈیو: مشاری العفاسی، عبدالباسط عبدالصمد، ماہر المعقلی، سعود الشریم — اسلامک نیٹ ورک / EveryAyah CDN۔\nنماز کے اوقات: اسی ڈیوائس پر حساب ہوتے ہیں (PrayTimes الگورتھم)۔\n\nقرآن ڈیٹا کا SHA-256:", 'ar': "نص القرآن: بالرسم العثماني، طبعة تنزيل عبر AlQuran Cloud ‏(quran-uthmani) — 114 سورة، 6,236 آية، موثَّقة.\nالترجمات: بيكثال (الإنجليزية)، جالندهري (الأردية)، قمشئي (الدارية) — كلها ملكية عامة.\nالصوت: مشاري العفاسي، عبد الباسط عبد الصمد، ماهر المعيقلي، سعود الشريم — الشبكة الإسلامية / EveryAyah CDN.\nأوقات الصلاة: تُحسب على هذا الجهاز (خوارزمية PrayTimes المنقولة).\n\nSHA-256 لبيانات القرآن المضمَّنة:"},

    // ---- Prayer names (display form of the stored English keys) ----
    "prayer_fajr": {'en': "Fajr", 'ps': "فجر", 'fa': "فجر", 'ur': "فجر", 'ar': "الفجر"},
    "prayer_sunrise": {'en': "Sunrise", 'ps': "د لمر ختو", 'fa': "طلوع آفتاب", 'ur': "طلوع آفتاب", 'ar': "الشروق"},
    "prayer_dhuhr": {'en': "Dhuhr", 'ps': "ماسپښین", 'fa': "ظهر", 'ur': "ظہر", 'ar': "الظهر"},
    "prayer_asr": {'en': "Asr", 'ps': "مازیګر", 'fa': "عصر", 'ur': "عصر", 'ar': "العصر"},
    "prayer_maghrib": {'en': "Maghrib", 'ps': "ماښام", 'fa': "مغرب", 'ur': "مغرب", 'ar': "المغرب"},
    "prayer_isha": {'en': "Isha", 'ps': "ماسختن", 'fa': "عشاء", 'ur': "عشاء", 'ar': "العشاء"},

    // ---- Hijri months (1..12) ----
    "hijri_month_1": {'en': "Muharram", 'ps': "محرم", 'fa': "محرم", 'ur': "محرم", 'ar': "محرم"},
    "hijri_month_2": {'en': "Safar", 'ps': "صفر", 'fa': "صفر", 'ur': "صفر", 'ar': "صفر"},
    "hijri_month_3": {'en': "Rabi al-Awwal", 'ps': "ربیع الاول", 'fa': "ربیع‌الاول", 'ur': "ربیع الاول", 'ar': "ربيع الأول"},
    "hijri_month_4": {'en': "Rabi al-Thani", 'ps': "ربیع الثاني", 'fa': "ربیع‌الثانی", 'ur': "ربیع الثانی", 'ar': "ربيع الآخر"},
    "hijri_month_5": {'en': "Jumada al-Ula", 'ps': "جمادی الاولی", 'fa': "جمادی‌الاول", 'ur': "جمادی الاولی", 'ar': "جمادى الأولى"},
    "hijri_month_6": {'en': "Jumada al-Akhirah", 'ps': "جمادی الثانیه", 'fa': "جمادی‌الثانی", 'ur': "جمادی الثانیہ", 'ar': "جمادى الآخرة"},
    "hijri_month_7": {'en': "Rajab", 'ps': "رجب", 'fa': "رجب", 'ur': "رجب", 'ar': "رجب"},
    "hijri_month_8": {'en': "Shaban", 'ps': "شعبان", 'fa': "شعبان", 'ur': "شعبان", 'ar': "شعبان"},
    "hijri_month_9": {'en': "Ramadan", 'ps': "رمضان", 'fa': "رمضان", 'ur': "رمضان", 'ar': "رمضان"},
    "hijri_month_10": {'en': "Shawwal", 'ps': "شوال", 'fa': "شوال", 'ur': "شوال", 'ar': "شوال"},
    "hijri_month_11": {'en': "Dhul-Qadah", 'ps': "ذوالقعده", 'fa': "ذی‌القعده", 'ur': "ذوالقعدہ", 'ar': "ذو القعدة"},
    "hijri_month_12": {'en': "Dhul-Hijjah", 'ps': "ذوالحجه", 'fa': "ذی‌الحجه", 'ur': "ذوالحجہ", 'ar': "ذو الحجة"},

    // ---- Hijri date templates ----
    "hijri_date": {'en': "{day} {month} {year} AH", 'ps': "{day} {month} {year} هـ.ق", 'fa': "{day} {month} {year} هـ.ق", 'ur': "{day} {month} {year} ہجری", 'ar': "{day} {month} {year} هـ"},
    "hijri_month_year": {'en': "{month} {year} AH", 'ps': "{month} {year} هـ.ق", 'fa': "{month} {year} هـ.ق", 'ur': "{month} {year} ہجری", 'ar': "{month} {year} هـ"},

    // ---- Gregorian months, full (1..12). Dari uses the Afghan transliterated forms. ----
    "greg_month_1": {'en': "January", 'ps': "جنوري", 'fa': "جنوری", 'ur': "جنوری", 'ar': "يناير"},
    "greg_month_2": {'en': "February", 'ps': "فبروري", 'fa': "فبروری", 'ur': "فروری", 'ar': "فبراير"},
    "greg_month_3": {'en': "March", 'ps': "مارچ", 'fa': "مارچ", 'ur': "مارچ", 'ar': "مارس"},
    "greg_month_4": {'en': "April", 'ps': "اپرېل", 'fa': "اپریل", 'ur': "اپریل", 'ar': "أبريل"},
    "greg_month_5": {'en': "May", 'ps': "مې", 'fa': "می", 'ur': "مئی", 'ar': "مايو"},
    "greg_month_6": {'en': "June", 'ps': "جون", 'fa': "جون", 'ur': "جون", 'ar': "يونيو"},
    "greg_month_7": {'en': "July", 'ps': "جولای", 'fa': "جولای", 'ur': "جولائی", 'ar': "يوليو"},
    "greg_month_8": {'en': "August", 'ps': "اګست", 'fa': "اگست", 'ur': "اگست", 'ar': "أغسطس"},
    "greg_month_9": {'en': "September", 'ps': "سپټمبر", 'fa': "سپتمبر", 'ur': "ستمبر", 'ar': "سبتمبر"},
    "greg_month_10": {'en': "October", 'ps': "اکتوبر", 'fa': "اکتوبر", 'ur': "اکتوبر", 'ar': "أكتوبر"},
    "greg_month_11": {'en': "November", 'ps': "نومبر", 'fa': "نومبر", 'ur': "نومبر", 'ar': "نوفمبر"},
    "greg_month_12": {'en': "December", 'ps': "ډسمبر", 'fa': "دسمبر", 'ur': "دسمبر", 'ar': "ديسمبر"},

    // ---- Gregorian months, short (1..12) ----
    "greg_month_short_1": {'en': "Jan", 'ps': "جنوري", 'fa': "جنوری", 'ur': "جنوری", 'ar': "يناير"},
    "greg_month_short_2": {'en': "Feb", 'ps': "فبروري", 'fa': "فبروری", 'ur': "فروری", 'ar': "فبراير"},
    "greg_month_short_3": {'en': "Mar", 'ps': "مارچ", 'fa': "مارچ", 'ur': "مارچ", 'ar': "مارس"},
    "greg_month_short_4": {'en': "Apr", 'ps': "اپرېل", 'fa': "اپریل", 'ur': "اپریل", 'ar': "أبريل"},
    "greg_month_short_5": {'en': "May", 'ps': "مې", 'fa': "می", 'ur': "مئی", 'ar': "مايو"},
    "greg_month_short_6": {'en': "Jun", 'ps': "جون", 'fa': "جون", 'ur': "جون", 'ar': "يونيو"},
    "greg_month_short_7": {'en': "Jul", 'ps': "جولای", 'fa': "جولای", 'ur': "جولائی", 'ar': "يوليو"},
    "greg_month_short_8": {'en': "Aug", 'ps': "اګست", 'fa': "اگست", 'ur': "اگست", 'ar': "أغسطس"},
    "greg_month_short_9": {'en': "Sep", 'ps': "سپټمبر", 'fa': "سپتمبر", 'ur': "ستمبر", 'ar': "سبتمبر"},
    "greg_month_short_10": {'en': "Oct", 'ps': "اکتوبر", 'fa': "اکتوبر", 'ur': "اکتوبر", 'ar': "أكتوبر"},
    "greg_month_short_11": {'en': "Nov", 'ps': "نومبر", 'fa': "نومبر", 'ur': "نومبر", 'ar': "نوفمبر"},
    "greg_month_short_12": {'en': "Dec", 'ps': "ډسمبر", 'fa': "دسمبر", 'ur': "دسمبر", 'ar': "ديسمبر"},

    // ---- Weekdays, short word (1 = Monday .. 7 = Sunday, Dart weekday convention) ----
    "weekday_1": {'en': "Mon", 'ps': "دوشنبه", 'fa': "دوشنبه", 'ur': "پیر", 'ar': "الاثنين"},
    "weekday_2": {'en': "Tue", 'ps': "سه شنبه", 'fa': "سه‌شنبه", 'ur': "منگل", 'ar': "الثلاثاء"},
    "weekday_3": {'en': "Wed", 'ps': "چهارشنبه", 'fa': "چهارشنبه", 'ur': "بدھ", 'ar': "الأربعاء"},
    "weekday_4": {'en': "Thu", 'ps': "پنجشنبه", 'fa': "پنجشنبه", 'ur': "جمعرات", 'ar': "الخميس"},
    "weekday_5": {'en': "Fri", 'ps': "جمعه", 'fa': "جمعه", 'ur': "جمعہ", 'ar': "الجمعة"},
    "weekday_6": {'en': "Sat", 'ps': "شنبه", 'fa': "شنبه", 'ur': "ہفتہ", 'ar': "السبت"},
    "weekday_7": {'en': "Sun", 'ps': "یکشنبه", 'fa': "یکشنبه", 'ur': "اتوار", 'ar': "الأحد"},

    // ---- Weekday abbreviations for the calendar grid header (single letters in Dari/Pashto, as Afghan calendars print them; short words in Urdu) ----
    "weekday_abbr_1": {'en': "Mon", 'ps': "د", 'fa': "د", 'ur': "پیر", 'ar': "ا"},
    "weekday_abbr_2": {'en': "Tue", 'ps': "س", 'fa': "س", 'ur': "منگل", 'ar': "ث"},
    "weekday_abbr_3": {'en': "Wed", 'ps': "چ", 'fa': "چ", 'ur': "بدھ", 'ar': "أ"},
    "weekday_abbr_4": {'en': "Thu", 'ps': "پ", 'fa': "پ", 'ur': "جمرات", 'ar': "خ"},
    "weekday_abbr_5": {'en': "Fri", 'ps': "ج", 'fa': "ج", 'ur': "جمعہ", 'ar': "ج"},
    "weekday_abbr_6": {'en': "Sat", 'ps': "ش", 'fa': "ش", 'ur': "ہفتہ", 'ar': "س"},
    "weekday_abbr_7": {'en': "Sun", 'ps': "ی", 'fa': "ی", 'ur': "اتوار", 'ar': "ح"},

    // ---- Calendar notable days ----
    "notable_new_year": {'en': "Islamic New Year", 'ps': "اسلامي نوی کال", 'fa': "سال نوی اسلامی", 'ur': "اسلامی نیا سال", 'ar': "رأس السنة الهجرية"},
    "notable_ashura": {'en': "Ashura", 'ps': "عاشورا", 'fa': "عاشورا", 'ur': "عاشورا", 'ar': "عاشوراء"},
    "notable_mawlid": {'en': "Prophet's Birthday (Mawlid)", 'ps': "د پیغمبر ﷺ زوکړه (میلاد)", 'fa': "میلاد پیامبر ﷺ", 'ur': "جشن میلاد النبی ﷺ", 'ar': "المولد النبوي"},
    "notable_miraj": {'en': "Laylat al-Mi'raj", 'ps': "د معراج شپه", 'fa': "شب معراج", 'ur': "شب معراج", 'ar': "ليلة المعراج"},
    "notable_baraah": {'en': "Laylat al-Bara'ah", 'ps': "د براءت شپه", 'fa': "شب برات", 'ur': "شب برات", 'ar': "ليلة البراءة"},
    "notable_ramadan_begins": {'en': "Ramadan begins", 'ps': "رمضان پیلېږي", 'fa': "آغاز رمضان", 'ur': "رمضان کا آغاز", 'ar': "بداية رمضان"},
    "notable_qadr": {'en': "Laylat al-Qadr", 'ps': "د قدر شپه", 'fa': "شب قدر", 'ur': "شب قدر", 'ar': "ليلة القدر"},
    "notable_eid_fitr": {'en': "Eid al-Fitr", 'ps': "کوچنی اختر", 'fa': "عید فطر", 'ur': "عید الفطر", 'ar': "عيد الفطر"},
    "notable_arafah": {'en': "Day of Arafah", 'ps': "د عرفې ورځ", 'fa': "روز عرفه", 'ur': "یوم عرفہ", 'ar': "يوم عرفة"},
    "notable_eid_adha": {'en': "Eid al-Adha", 'ps': "لوی اختر", 'fa': "عید قربان", 'ur': "عید الاضحی", 'ar': "عيد الأضحى"},
    "notable_days": {'en': "Notable days", 'ps': "مهمې ورځې", 'fa': "روزهای مهم", 'ur': "اہم دن", 'ar': "أيام بارزة"},
    "calendar_note": {'en': "This is the civil (Kuwaiti algorithm) Hijri calendar. Dates may differ by a day from moon-sighting calendars.", 'ps': "دا مدني (کویټي الګوریتم) هجري کلیزه ده. نېټې ښايي د سپوږمۍ لیدلو کلیزو څخه یوه ورځ توپیر ولري.", 'fa': "این تقویم هجری مدنی (الگوریتم کویتی) است. تاریخ‌ها ممکن است یک روز با تقویم‌های رؤیت هلال تفاوت داشته باشند.", 'ur': "یہ سول (کویتی الگورتھم) ہجری کیلنڈر ہے۔ تاریخوں میں چاند دیکھنے والے کیلنڈروں سے ایک دن کا فرق ہو سکتا ہے۔", 'ar': "هذا هو التقويم الهجري المدني (خوارزمية الكويت). قد تختلف التواريخ بيوم عن تقاويم رؤية الهلال."},

    // ---- Prayer screen ----
    "prayer_info": {'en': "On this device — no internet needed.\nMethod: {method} • Asr: {madhab}\nLocation: {location} ({coords})", 'ps': "په دې وسیله — انټرنېټ ته اړتیا نشته.\nطریقه: {method} • مازیګر: {madhab}\nځای: {location} ({coords})", 'fa': "روی همین دستگاه — بدون نیاز به اینترنت.\nروش: {method} • عصر: {madhab}\nمکان: {location} ({coords})", 'ur': "اسی ڈیوائس پر — انٹرنیٹ کی ضرورت نہیں۔\nطریقہ: {method} • عصر: {madhab}\nمقام: {location} ({coords})", 'ar': "على هذا الجهاز — لا حاجة إلى الإنترنت.\nالطريقة: {method} • العصر: {madhab}\nالموقع: {location} ({coords})"},
    "prayer_bell_hint": {'en': "Use the bell switches to choose which prayers alert you. Alerts use exact alarms and are re-scheduled automatically.", 'ps': "د زنګ سویچونه وکاروئ ترڅو وټاکئ چې کوم لمونځونه مو خبر کړي. خبرتیاوې دقیق الارمونه کاروي او په اتومات ډول بیا ځلېږي.", 'fa': "با کلیدهای زنگ انتخاب کنید کدام نمازها به شما هشدار دهند. هشدارها از هشدار دقیق استفاده می‌کنند و خودکار دوباره تنظیم می‌شوند.", 'ur': "گھنٹی کے سوئچ سے منتخب کریں کہ کون سی نمازیں آپ کو آگاہ کریں۔ اطلاعات درست الارم استعمال کرتی ہیں اور خودکار طور پر دوبارہ ترتیب دی جاتی ہیں۔", 'ar': "استخدم مفاتيح الجرس لاختيار الصلوات التي تنبّهك. تستخدم التنبيهات منبّهات دقيقة ويُعاد جدولتها تلقائياً."},

    // ---- Qibla ----
    "facing_qibla": {'en': "You are facing Qibla", 'ps': "تاسو د قبلې لور ته یاست", 'fa': "شما رو به قبله هستید", 'ur': "آپ قبلے کی طرف ہیں", 'ar': "أنت متجه نحو القبلة"},
    "turn_to_qibla": {'en': "Turn until the gold marker reaches the top", 'ps': "وګرځئ ترڅو طلایي نښه پورته ورسېږي", 'fa': "بچرخید تا نشان طلایی به بالا برسد", 'ur': "گھومیں جب تک سنہری نشان اوپر نہ آ جائے", 'ar': "دُر حتى يصل المؤشر الذهبي إلى الأعلى"},
    "compass_unavailable": {'en': "Compass not available — move your phone in a figure-8 to calibrate, or use the bearing below.", 'ps': "قطب نما نشته — د سمولو لپاره خپل تلیفون د 8 په شکل وګرځوئ، یا لاندې زاویه وکاروئ.", 'fa': "قطب‌نما در دسترس نیست — برای کالیبره کردن گوشی را به شکل عدد ۸ حرکت دهید، یا از زاویهٔ زیر استفاده کنید.", 'ur': "کمپاس دستیاب نہیں — کیلیبریٹ کرنے کے لیے فون کو 8 کی شکل میں گھمائیں، یا نیچے دی گئی سمت استعمال کریں۔", 'ar': "البوصلة غير متوفرة — حرّك هاتفك على شكل رقم 8 للمعايرة، أو استخدم الاتجاه أدناه."},
    "qibla_direction": {'en': "Qibla direction", 'ps': "د قبلې لور", 'fa': "جهت قبله", 'ur': "قبلے کی سمت", 'ar': "اتجاه القبلة"},
    "distance_makkah": {'en': "Distance to Makkah", 'ps': "تر مکې واټن", 'fa': "فاصله تا مکه", 'ur': "مکہ تک فاصلہ", 'ar': "المسافة إلى مكة"},
    "from": {'en': "From", 'ps': "له", 'fa': "از", 'ur': "سے", 'ar': "من"},
    "your_heading": {'en': "Your heading", 'ps': "ستاسو لور", 'fa': "جهت شما", 'ur': "آپ کی سمت", 'ar': "اتجاهك"},
    "qibla_hint": {'en': "Hold the phone flat and turn slowly. The bearing is calculated on this device from your location — no internet needed.", 'ps': "تلیفون هوار ونیسئ او ورو وګرځئ. زاویه په دې وسیله ستاسو له ځای څخه حسابېږي — انټرنېټ ته اړتیا نشته.", 'fa': "گوشی را صاف نگه دارید و آهسته بچرخید. زاویه روی همین دستگاه از روی مکان شما محاسبه می‌شود — بدون نیاز به اینترنت.", 'ur': "فون سیدھا پکڑیں اور آہستہ گھومیں۔ سمت اسی ڈیوائس پر آپ کے مقام سے حساب ہوتی ہے — انٹرنیٹ کی ضرورت نہیں۔", 'ar': "أمسك الهاتف مستوياً ودُر ببطء. يُحسب الاتجاه على هذا الجهاز من موقعك — لا حاجة إلى الإنترنت."},

    // ---- Reader / Quran ----
    "choose_surah": {'en': "Choose surah", 'ps': "سورت وټاکئ", 'fa': "سوره را انتخاب کنید", 'ur': "سورت منتخب کریں", 'ar': "اختر سورة"},
    "choose_juz": {'en': "Choose juz", 'ps': "پاره وټاکئ", 'fa': "جزء را انتخاب کنید", 'ur': "پارہ منتخب کریں", 'ar': "اختر جزءاً"},
    "download_failed": {'en': "Download failed — check connection", 'ps': "ډاونلوډ ناکام شو — اړیکه وګورئ", 'fa': "دانلود ناموفق بود — اتصال را بررسی کنید", 'ur': "ڈاؤن لوڈ ناکام ہوا — کنکشن چیک کریں", 'ar': "فشل التنزيل — تحقق من الاتصال"},
    "share_verse": {'en': "Share this verse", 'ps': "دا آیت شریک کړئ", 'fa': "این آیه را به اشتراک بگذارید", 'ur': "یہ آیت شیئر کریں", 'ar': "شارك هذه الآية"},
    "remove_bookmark": {'en': "Remove bookmark", 'ps': "نښه لرې کړئ", 'fa': "نشان را حذف کنید", 'ur': "بک مارک ہٹائیں", 'ar': "إزالة العلامة"},
    "bookmark_verse": {'en': "Bookmark this verse", 'ps': "دا آیت نښه کړئ", 'fa': "این آیه را نشان کنید", 'ur': "اس آیت کو بک مارک کریں", 'ar': "ضع علامة على هذه الآية"},
    "bookmark": {'en': "Bookmark", 'ps': "نښه کړئ", 'fa': "نشان کردن", 'ur': "بک مارک کریں", 'ar': "علامة"},
    "bookmarked": {'en': "Bookmarked", 'ps': "نښه شو", 'fa': "نشان شد", 'ur': "بک مارک ہو گیا", 'ar': "تم وضع العلامة"},
    "bookmark_removed": {'en': "Bookmark removed", 'ps': "نښه لرې شوه", 'fa': "نشان حذف شد", 'ur': "بک مارک ہٹا دیا گیا", 'ar': "أُزيلت العلامة"},
    "prev_verse": {'en': "Previous verse", 'ps': "پخوانی آیت", 'fa': "آیهٔ قبلی", 'ur': "پچھلی آیت", 'ar': "الآية السابقة"},
    "next_verse": {'en': "Next verse", 'ps': "راتلونکی آیت", 'fa': "آیهٔ بعدی", 'ur': "اگلی آیت", 'ar': "الآية التالية"},
    "play": {'en': "Play", 'ps': "غږول", 'fa': "پخش", 'ur': "چلائیں", 'ar': "تشغيل"},
    "pause": {'en': "Pause", 'ps': "ودرول", 'fa': "توقف", 'ur': "روکیں", 'ar': "إيقاف مؤقت"},
    "stop": {'en': "Stop", 'ps': "بندول", 'fa': "توقف کامل", 'ur': "بند کریں", 'ar': "إيقاف"},
    "juz_n": {'en': "Juz: {n}", 'ps': "پاره: {n}", 'fa': "جزء: {n}", 'ur': "پارہ: {n}", 'ar': "الجزء: {n}"},
    "ayat": {'en': "Ayat", 'ps': "آیت", 'fa': "آیه", 'ur': "آیت", 'ar': "آيات"},
    "ayah": {'en': "Ayah", 'ps': "آیت", 'fa': "آیه", 'ur': "آیت", 'ar': "آية"},
    "surah": {'en': "Surah", 'ps': "سورت", 'fa': "سوره", 'ur': "سورت", 'ar': "سورة"},
    "juz": {'en': "Juz", 'ps': "پاره", 'fa': "جزء", 'ur': "پارہ", 'ar': "جزء"},
    "bookmarks": {'en': "Bookmarks", 'ps': "نښې", 'fa': "نشان‌ها", 'ur': "بک مارکس", 'ar': "العلامات"},
    "no_bookmarks": {'en': "No bookmarks yet. Tap the bookmark on any verse in the reader to save your place here.", 'ps': "تر اوسه هېڅ نښه نشته. په لوستونکي کې پر کوم آیت چې د نښې تڼۍ وټپوئ، خپل ځای به دلته خوندي شي.", 'fa': "هنوز نشانی ندارید. در صفحهٔ خواندن، روی نشان هر آیه بزنید تا جای شما اینجا ذخیره شود.", 'ur': "ابھی کوئی بک مارک نہیں۔ ریڈر میں کسی آیت پر بک مارک دبائیں تو آپ کی جگہ یہاں محفوظ ہو جائے گی۔", 'ar': "لا توجد علامات بعد. اضغط على العلامة في أي آية في القارئ لحفظ موضعك هنا."},
    "continue": {'en': "Continue", 'ps': "دوام ورکړئ", 'fa': "ادامه", 'ur': "جاری رکھیں", 'ar': "متابعة"},
    "play_surah": {'en': "Play {name}", 'ps': "{name} وغږوئ", 'fa': "پخش {name}", 'ur': "{name} چلائیں", 'ar': "تشغيل {name}"},
    "verses_count": {'en': "{n} verses", 'ps': "{n} آیتونه", 'fa': "{n} آیه", 'ur': "{n} آیات", 'ar': "{n} آيات"},

    // ---- Search ----
    "search_hint": {'en': "Search in Arabic or English…", 'ps': "په عربي یا انګلیسي کې لټون…", 'fa': "جستجو به عربی یا انگلیسی…", 'ur': "عربی یا انگریزی میں تلاش کریں…", 'ar': "ابحث بالعربية أو الإنجليزية…"},
    "showing_first_n": {'en': "Showing the first {n} results", 'ps': "لومړۍ {n} پایلې ښودل کېږي", 'fa': "نمایش {n} نتیجهٔ اول", 'ur': "پہلے {n} نتائج دکھائے جا رہے ہیں", 'ar': "عرض أول {n} نتيجة"},
    "verses_found_one": {'en': "{n} verse found", 'ps': "{n} آیت وموندل شو", 'fa': "{n} آیه یافت شد", 'ur': "{n} آیت ملی", 'ar': "تم العثور على {n} آية"},
    "verses_found_other": {'en': "{n} verses found", 'ps': "{n} آیتونه وموندل شول", 'fa': "{n} آیه یافت شد", 'ur': "{n} آیات ملیں", 'ar': "تم العثور على {n} آيات"},
    "search_empty_body": {'en': "Type Arabic or English words above — for example “mercy” or “الرحمن”. Arabic search ignores diacritics, so you can type without tashkeel.", 'ps': "پورته عربي یا انګلیسي ټکي ولیکئ — د بېلګې په توګه “mercy” یا “الرحمن”. عربي لټون اعراب نه ګوري، نو تاسو کولای شئ پرته له تشکیله ولیکئ.", 'fa': "بالا واژه‌های عربی یا انگلیسی بنویسید — برای نمونه «mercy» یا «الرحمن». جستجوی عربی اعراب را نادیده می‌گیرد، پس می‌توانید بدون تشکیلی بنویسید.", 'ur': "اوپر عربی یا انگریزی الفاظ لکھیں — مثال کے طور پر “mercy” یا “الرحمن”۔ عربی تلاش اعراب کو نظر انداز کرتی ہے، اس لیے آپ بغیر تشکیلی لکھ سکتے ہیں۔", 'ar': "اكتب كلمات عربية أو إنجليزية أعلاه — مثلاً “mercy” أو “الرحمن”. البحث بالعربية يتجاهل الحركات، لذا يمكنك الكتابة دون تشكيل."},
    "no_verses_found": {'en': "No verses found", 'ps': "هېڅ آیت ونه موندل شو", 'fa': "هیچ آیه‌ای یافت نشد", 'ur': "کوئی آیت نہیں ملی", 'ar': "لم يُعثر على آيات"},
    "try_different_words": {'en': "Try different words, or check the spelling.", 'ps': "نور ټکي وازمایئ، یا املا وګورئ.", 'fa': "واژه‌های دیگری را امتحان کنید یا املا را بررسی کنید.", 'ur': "مختلف الفاظ آزمائیں، یا املا چیک کریں۔", 'ar': "جرّب كلمات مختلفة، أو تحقق من الإملاء."},

    // ---- Home ----
    "verse_of": {'en': "verse {n} of {total}", 'ps': "آیت {n} له {total} څخه", 'fa': "آیهٔ {n} از {total}", 'ur': "آیت {n} از {total}", 'ar': "الآية {n} من {total}"},
    "pct_of_quran": {'en': "{pct}% of the Quran", 'ps': "د قرآن {pct}٪", 'fa': "{pct}٪ از قرآن", 'ur': "قرآن کا {pct}٪", 'ar': "{pct}٪ من القرآن"},

    // ---- Duas (screen strings) ----
    "duas_with_sources": {'en': "{n} duas with sources", 'ps': "{n} دعاګانې له سرچینو سره", 'fa': "{n} دعا با منبع", 'ur': "{n} دعائیں ماخذ کے ساتھ", 'ar': "{n} أدعية مع مصادرها"},
    "duas_count": {'en': "{n} duas", 'ps': "{n} دعاګانې", 'fa': "{n} دعا", 'ur': "{n} دعائیں", 'ar': "{n} أدعية"},
    "duas_in_category": {'en': "{n} duas in {category}", 'ps': "{n} دعاګانې په {category} کې", 'fa': "{n} دعا در {category}", 'ur': "{category} میں {n} دعائیں", 'ar': "{n} أدعية في {category}"},

    // ---- Dua categories (key = the English category text stored in content.dart) ----
    "All": {'en': "All", 'ps': "ټول", 'fa': "همه", 'ur': "سب", 'ar': "الكل"},
    "Morning & Evening": {'en': "Morning & Evening", 'ps': "سهار او ماښام", 'fa': "صبح و عصر", 'ur': "صبح و شام", 'ar': "الصباح والمساء"},
    "Sleep": {'en': "Sleep", 'ps': "خوب", 'fa': "خواب", 'ur': "نیند", 'ar': "النوم"},
    "Home": {'en': "Home", 'ps': "کور", 'fa': "خانه", 'ur': "گھر", 'ar': "المنزل"},
    "Eating": {'en': "Eating", 'ps': "خوړل", 'fa': "غذا خوردن", 'ur': "کھانا", 'ar': "الطعام"},
    "Family": {'en': "Family", 'ps': "کورنۍ", 'fa': "خانواده", 'ur': "خاندان", 'ar': "العائلة"},
    "Forgiveness": {'en': "Forgiveness", 'ps': "بخښنه", 'fa': "آمرزش", 'ur': "مغفرت", 'ar': "المغفرة"},
    "General": {'en': "General", 'ps': "عمومي", 'fa': "عمومی", 'ur': "عام", 'ar': "عام"},

    // ---- Dua titles (key = the English title stored in content.dart) ----
    "Ayat al-Kursi": {'en': "Ayat al-Kursi", 'ps': "آیت الکرسي", 'fa': "آیةالکرسی", 'ur': "آیت الکرسی", 'ar': "آية الكرسي"},
    "Al-Ikhlas, Al-Falaq, An-Nas": {'en': "Al-Ikhlas, Al-Falaq, An-Nas", 'ps': "الاخلاص، الفلق، الناس", 'fa': "اخلاص، فلق، ناس", 'ur': "اخلاص، فلق، ناس", 'ar': "الإخلاص والفلق والناس"},
    "Glory be to Allah and praise Him": {'en': "Glory be to Allah and praise Him", 'ps': "سبحان الله او حمد یې", 'fa': "تسبیح و حمد خدا", 'ur': "اللہ کی تسبیح اور حمد", 'ar': "سبحان الله وبحمده"},
    "None has the right to be worshipped but Allah": {'en': "None has the right to be worshipped but Allah", 'ps': "له الله پرته هېڅوک د عبادت وړ نه دی", 'fa': "هیچ معبودی جز الله نیست", 'ur': "اللہ کے سوا کوئی معبود نہیں", 'ar': "لا إله إلا الله"},
    "Protection from all harm": {'en': "Protection from all harm", 'ps': "له هر زیان څخه ساتنه", 'fa': "پناه از هر شر", 'ur': "ہر شر سے حفاظت", 'ar': "الحماية من كل شر"},
    "I seek refuge in the perfect words of Allah": {'en': "I seek refuge in the perfect words of Allah", 'ps': "د الله په بشپړو کلمو پناه غواړم", 'fa': "پناه به کلمات کامل خدا", 'ur': "اللہ کے کامل کلمات کی پناہ", 'ar': "أعوذ بكلمات الله التامات"},
    "Allah is enough for me": {'en': "Allah is enough for me", 'ps': "الله راته بس دی", 'fa': "خدا برایم کافی است", 'ur': "اللہ میرے لیے کافی ہے", 'ar': "حسبي الله"},
    "I am pleased with Allah as my Lord": {'en': "I am pleased with Allah as my Lord", 'ps': "له الله څخه د خپل رب په توګه خوښ یم", 'fa': "از خدا به عنوان پروردگارم راضی‌ام", 'ur': "میں اللہ کو اپنا رب مان کر راضی ہوں", 'ar': "رضيت بالله رباً"},
    "Glory be to Allah, as many times as His creation": {'en': "Glory be to Allah, as many times as His creation", 'ps': "سبحان الله، د هغه د مخلوقاتو په شمېر", 'fa': "تسبیح خدا به شمارهٔ آفریدگانش", 'ur': "اللہ کی تسبیح، اس کی مخلوق کی تعداد کے برابر", 'ar': "سبحان الله عدد خلقه"},
    "Before sleeping": {'en': "Before sleeping", 'ps': "تر خوبه مخکې", 'fa': "پیش از خواب", 'ur': "سونے سے پہلے", 'ar': "قبل النوم"},
    "Protect me from Your punishment": {'en': "Protect me from Your punishment", 'ps': "له خپل عذاب څخه مې وساته", 'fa': "مرا از عذابت حفظ کن", 'ur': "مجھے اپنے عذاب سے بچا", 'ar': "قني عذابك"},
    "On waking up": {'en': "On waking up", 'ps': "له خوبه راپاڅېدو پر مهال", 'fa': "هنگام بیدار شدن", 'ur': "جاگنے پر", 'ar': "عند الاستيقاظ"},
    "Entering the home": {'en': "Entering the home", 'ps': "کور ته ننوتل", 'fa': "ورود به خانه", 'ur': "گھر میں داخل ہوتے وقت", 'ar': "دخول المنزل"},
    "Leaving the home": {'en': "Leaving the home", 'ps': "له کوره وتل", 'fa': "خروج از خانه", 'ur': "گھر سے نکلتے وقت", 'ar': "الخروج من المنزل"},
    "Before eating": {'en': "Before eating", 'ps': "تر خوړلو مخکې", 'fa': "پیش از غذا", 'ur': "کھانے سے پہلے", 'ar': "قبل الأكل"},
    "After eating": {'en': "After eating", 'ps': "تر خوړلو وروسته", 'fa': "پس از غذا", 'ur': "کھانے کے بعد", 'ar': "بعد الأكل"},
    "For my parents": {'en': "For my parents", 'ps': "زما د مور او پلار لپاره", 'fa': "برای پدر و مادرم", 'ur': "میرے والدین کے لیے", 'ar': "لوالديّ"},
    "For our family": {'en': "For our family", 'ps': "زموږ د کورنۍ لپاره", 'fa': "برای خانواده‌مان", 'ur': "ہمارے خاندان کے لیے", 'ar': "لعائلتنا"},
    "We have wronged ourselves": {'en': "We have wronged ourselves", 'ps': "موږ پر ځان ظلم کړی دی", 'fa': "ما بر خود ستم کردیم", 'ur': "ہم نے اپنے آپ پر ظلم کیا", 'ar': "ظلمنا أنفسنا"},
    "Sayyidul Istighfar — the master of seeking forgiveness": {'en': "Sayyidul Istighfar — the master of seeking forgiveness", 'ps': "سید الاستغفار — د بخښنې غوښتلو سردار", 'fa': "سید الاستغفار — سرور استغفار", 'ur': "سید الاستغفار — استغفار کا سردار", 'ar': "سيد الاستغفار — سيد طلب المغفرة"},
    "I ask You for beneficial knowledge": {'en': "I ask You for beneficial knowledge", 'ps': "له تا څخه ګټور علم غواړم", 'fa': "از تو دانش سودمند می‌خواهم", 'ur': "میں تجھ سے نفع بخش علم مانگتا ہوں", 'ar': "أسألك علماً نافعاً"},
    "Make my heart firm": {'en': "Make my heart firm", 'ps': "زما زړه ټینګ کړه", 'fa': "دلم را استوار کن", 'ur': "میرے دل کو ثابت قدم رکھ", 'ar': "ثبّت قلبي"},
    "Help me to remember You": {'en': "Help me to remember You", 'ps': "ستا په یادولو کې مې مرسته وکړه", 'fa': "مرا در یاد خودت یاری کن", 'ur': "تیری یاد میں میری مدد فرما", 'ar': "أعنّي على ذكرك"},
    "Our Lord, give us good in this world": {'en': "Our Lord, give us good in this world", 'ps': "ای زموږ ربه، په دې دنیا کې موږ ته ښه راکړه", 'fa': "پروردگارا، در این دنیا به ما نیکی عطا کن", 'ur': "اے ہمارے رب، ہمیں دنیا میں بھلائی دے", 'ar': "ربنا آتنا في الدنيا حسنة"},
    "My Lord, increase me in knowledge": {'en': "My Lord, increase me in knowledge", 'ps': "ای زما ربه، زما علم زیات کړه", 'fa': "پروردگارا، دانشم را بیفزا", 'ur': "اے میرے رب، میرا علم بڑھا دے", 'ar': "رب زدني علماً"},
    "There is no might nor power except with Allah": {'en': "There is no might nor power except with Allah", 'ps': "له الله پرته هېڅ ځواک او قدرت نشته", 'fa': "هیچ توان و قدرتی جز با خدا نیست", 'ur': "اللہ کے سوا کوئی طاقت و قوت نہیں", 'ar': "لا حول ولا قوة إلا بالله"},

    // ---- 99 Names screen ----
    "asma_ul_husna": {'en': "Asma ul-Husna", 'ps': "اسماء الحسنی", 'fa': "اسماء الحسنی", 'ur': "اسماء الحسنی", 'ar': "أسماء الله الحسنى"},
    "search_names_hint": {'en': "Search by name or meaning…", 'ps': "د نوم یا معنې له مخې لټون…", 'fa': "جستجو با نام یا معنا…", 'ur': "نام یا معنی سے تلاش کریں…", 'ar': "ابحث بالاسم أو المعنى…"},
    "names_count": {'en': "{n} names", 'ps': "{n} نومونه", 'fa': "{n} نام", 'ur': "{n} نام", 'ar': "{n} أسماء"},
    "names_found": {'en': "{n} names found", 'ps': "{n} نومونه وموندل شول", 'fa': "{n} نام یافت شد", 'ur': "{n} نام ملے", 'ar': "تم العثور على {n} أسماء"},
    "no_names_found": {'en': "No names found", 'ps': "هېڅ نوم ونه موندل شو", 'fa': "هیچ نامی یافت نشد", 'ur': "کوئی نام نہیں ملا", 'ar': "لم يُعثر على أسماء"},
    "try_different_spelling": {'en': "Try a different spelling", 'ps': "بله املا وازمایئ", 'fa': "املای دیگری را امتحان کنید", 'ur': "مختلف املا آزمائیں", 'ar': "جرّب إملاءً مختلفاً"},
    "name_of_99": {'en': "Name {n} of 99", 'ps': "نوم {n} له 99 څخه", 'fa': "نام {n} از 99", 'ur': "نام {n} از 99", 'ar': "الاسم {n} من 99"},

    // ---- Khatma ----
    "end_plan_title": {'en': "End plan?", 'ps': "پلان پای ته ورسوئ؟", 'fa': "برنامه را پایان دهم؟", 'ur': "منصوبہ ختم کریں؟", 'ar': "إنهاء الخطة؟"},
    "end_plan_body": {'en': "Your reading position is kept — only the plan is removed.", 'ps': "ستاسو د لوستلو ځای ساتل کېږي — یوازې پلان لرې کېږي.", 'fa': "جای خواندن شما حفظ می‌شود — فقط برنامه حذف می‌شود.", 'ur': "آپ کی پڑھنے کی جگہ محفوظ رہتی ہے — صرف منصوبہ ہٹایا جاتا ہے۔", 'ar': "يُحفظ موضع قراءتك — تُزال الخطة فقط."},
    "end_plan": {'en': "End plan", 'ps': "پلان پای ته ورسوئ", 'fa': "پایان برنامه", 'ur': "منصوبہ ختم کریں", 'ar': "إنهاء الخطة"},
    "khatma_subtitle": {'en': "Finish the whole Quran", 'ps': "ټول قرآن پای ته ورسوئ", 'fa': "کل قرآن را تمام کنید", 'ur': "پورا قرآن مکمل کریں", 'ar': "أتمم القرآن كله"},
    "khatma_intro": {'en': "Set a goal and read a little every day", 'ps': "یو هدف وټاکئ او هره ورځ لږ ولولئ", 'fa': "هدفی بگذارید و هر روز کمی بخوانید", 'ur': "ایک ہدف مقرر کریں اور ہر روز تھوڑا پڑھیں", 'ar': "حدّد هدفاً واقرأ قليلاً كل يوم"},
    "khatma_explainer": {'en': "Your plan starts from where you are reading now ({position}) and divides the remaining verses evenly across the days you choose.", 'ps': "ستاسو پلان له هغه ځایه پیلېږي چېرته چې تاسو اوس لوستل کوئ ({position}) او پاتې آیتونه په مساوي ډول پر هغو ورځو وېشي چې تاسو یې ټاکئ.", 'fa': "برنامهٔ شما از جایی که اکنون می‌خوانید ({position}) آغاز می‌شود و آیات باقی‌مانده را به‌تساوی میان روزهایی که انتخاب می‌کنید تقسیم می‌کند.", 'ur': "آپ کا منصوبہ وہیں سے شروع ہوتا ہے جہاں آپ اب پڑھ رہے ہیں ({position}) اور باقی آیات کو آپ کے منتخب کردہ دنوں میں برابر تقسیم کرتا ہے۔", 'ar': "تبدأ خطتك من حيث تقرأ الآن ({position}) وتقسّم الآيات المتبقية بالتساوي على الأيام التي تختارها."},
    "choose_plan": {'en': "Choose your plan", 'ps': "خپل پلان وټاکئ", 'fa': "برنامه‌تان را انتخاب کنید", 'ur': "اپنا منصوبہ منتخب کریں", 'ar': "اختر خطتك"},
    "days_count": {'en': "{n} days", 'ps': "{n} ورځې", 'fa': "{n} روز", 'ur': "{n} دن", 'ar': "{n} أيام"},
    "plan_rates": {'en': "7 days ≈ {v7} verses a day · 30 days ≈ {v30} a day · 90 days ≈ {v90} a day", 'ps': "7 ورځې ≈ په ورځ کې {v7} آیتونه · 30 ورځې ≈ په ورځ کې {v30} · 90 ورځې ≈ په ورځ کې {v90}", 'fa': "7 روز ≈ {v7} آیه در روز · 30 روز ≈ {v30} در روز · 90 روز ≈ {v90} در روز", 'ur': "7 دن ≈ روزانہ {v7} آیات · 30 دن ≈ روزانہ {v30} · 90 دن ≈ روزانہ {v90}", 'ar': "7 أيام ≈ {v7} آيات في اليوم · 30 يوماً ≈ {v30} في اليوم · 90 يوماً ≈ {v90} في اليوم"},
    "day_plan": {'en': "{n}-day plan", 'ps': "{n} ورځنی پلان", 'fa': "برنامهٔ {n} روزه", 'ur': "{n} دن کا منصوبہ", 'ar': "خطة {n} أيام"},
    "complete": {'en': "complete", 'ps': "بشپړ", 'fa': "کامل", 'ur': "مکمل", 'ar': "مكتمل"},
    "plan_complete": {'en': "Plan complete — you finished the Quran", 'ps': "پلان بشپړ شو — تاسو قرآن پای ته ورساوه", 'fa': "برنامه کامل شد — قرآن را تمام کردید", 'ur': "منصوبہ مکمل ہو گیا — آپ نے قرآن ختم کر لیا", 'ar': "اكتملت الخطة — أتممت القرآن"},
    "on_track": {'en': "You are on track", 'ps': "تاسو په لار یاست", 'fa': "در مسیر هستید", 'ur': "آپ درست راستے پر ہیں", 'ar': "أنت على المسار الصحيح"},
    "behind_by": {'en': "Behind by {n} verses", 'ps': "له {n} آیتونو څخه وروسته یاست", 'fa': "{n} آیه عقب هستید", 'ur': "{n} آیات پیچھے ہیں", 'ar': "متأخر بـ {n} آيات"},
    "verses_read_in_plan": {'en': "{read} of {remaining} verses read in this plan", 'ps': "په دې پلان کې له {remaining} څخه {read} آیتونه لوستل شوي", 'fa': "{read} آیه از {remaining} آیه در این برنامه خوانده شده", 'ur': "اس منصوبے میں {remaining} میں سے {read} آیات پڑھی گئیں", 'ar': "قُرئ {read} من {remaining} آية في هذه الخطة"},
    "todays_portion": {'en': "Today's portion", 'ps': "د نن ورځې برخه", 'fa': "سهم امروز", 'ur': "آج کا حصہ", 'ar': "ورد اليوم"},
    "read_todays_portion": {'en': "Read today's portion", 'ps': "د نن ورځې برخه ولولئ", 'fa': "سهم امروز را بخوانید", 'ur': "آج کا حصہ پڑھیں", 'ar': "اقرأ ورد اليوم"},
    "stat_day": {'en': "Day", 'ps': "ورځ", 'fa': "روز", 'ur': "دن", 'ar': "اليوم"},
    "stat_of_days": {'en': "{n} of {total}", 'ps': "{n} له {total} څخه", 'fa': "{n} از {total}", 'ur': "{n} از {total}", 'ar': "{n} من {total}"},
    "stat_daily_portion": {'en': "Daily portion", 'ps': "ورځنۍ برخه", 'fa': "سهم روزانه", 'ur': "روزانہ حصہ", 'ar': "الورد اليومي"},
    "stat_days_remaining": {'en': "Days remaining", 'ps': "پاتې ورځې", 'fa': "روزهای باقی‌مانده", 'ur': "باقی دن", 'ar': "الأيام المتبقية"},

    // ---- Tasbih ----
    "dhikr_counter": {'en': "Dhikr counter", 'ps': "د ذکر شمېرونکی", 'fa': "شمارندهٔ ذکر", 'ur': "ذکر کا کاؤنٹر", 'ar': "عدّاد الذكر"},
    "target_reached": {'en': "Target reached", 'ps': "هدف ته ورسېدل", 'fa': "به هدف رسیدید", 'ur': "ہدف حاصل ہو گیا", 'ar': "تم بلوغ الهدف"},
    "of_target_tap": {'en': "of {n} — tap to count", 'ps': "له {n} څخه — د شمېرلو لپاره وټپوئ", 'fa': "از {n} — برای شمردن بزنید", 'ur': "{n} میں سے — گننے کے لیے دبائیں", 'ar': "من {n} — اضغط للعدّ"},
    "custom_target": {'en': "Custom target", 'ps': "ځانګړی هدف", 'fa': "هدف دلخواه", 'ur': "اپنی مرضی کا ہدف", 'ar': "هدف مخصص"},
    "target_hint": {'en': "e.g. 500", 'ps': "بېلګه: 500", 'fa': "مثلاً 500", 'ur': "مثلاً 500", 'ar': "مثلاً 500"},
    "count_label": {'en': "Count", 'ps': "شمېر", 'fa': "شمارش", 'ur': "گنتی", 'ar': "العدّ"},
    "target_range_error": {'en': "Enter a target between 1 and 10,000", 'ps': "د 1 او 10,000 ترمنځ یو هدف ولیکئ", 'fa': "هدفی میان 1 تا 10,000 وارد کنید", 'ur': "1 سے 10,000 کے درمیان ہدف لکھیں", 'ar': "أدخل هدفاً بين 1 و10,000"},
    "custom": {'en': "Custom", 'ps': "ځانګړی", 'fa': "دلخواه", 'ur': "اپنی مرضی", 'ar': "مخصص"},
    "custom_n": {'en': "Custom: {n}", 'ps': "ځانګړی: {n}", 'fa': "دلخواه: {n}", 'ur': "اپنی مرضی: {n}", 'ar': "مخصص: {n}"},
    "reset_session": {'en': "Reset session", 'ps': "ناسته بیا پیل کړئ", 'fa': "شروع دوبارهٔ جلسه", 'ur': "سیشن دوبارہ شروع کریں", 'ar': "إعادة بدء الجلسة"},
    "lifetime_totals": {'en': "Lifetime totals", 'ps': "ټول وخت شمېرې", 'fa': "مجموع کل", 'ur': "کل مجموعہ", 'ar': "المجاميع الكلية"},

    // ---- Mushaf ----
    "enter_page_range": {'en': "Enter a page from 1 to {total}", 'ps': "له 1 څخه تر {total} پورې یوه پاڼه ولیکئ", 'fa': "صفحه‌ای از 1 تا {total} وارد کنید", 'ur': "1 سے {total} تک صفحہ لکھیں", 'ar': "أدخل صفحة من 1 إلى {total}"},
    "page_number": {'en': "Page number", 'ps': "د پاڼې شمېره", 'fa': "شمارهٔ صفحه", 'ur': "صفحہ نمبر", 'ar': "رقم الصفحة"},
    "jump_surah": {'en': "Jump to the first page of a surah", 'ps': "د یوې سورتې لومړۍ پاڼې ته ورشئ", 'fa': "به نخستین صفحهٔ یک سوره بروید", 'ur': "کسی سورت کے پہلے صفحے پر جائیں", 'ar': "اذهب إلى أول صفحة في سورة"},
    "jump_juz": {'en': "Jump to the first page of a juz'", 'ps': "د یوې پارې لومړۍ پاڼې ته ورشئ", 'fa': "به نخستین صفحهٔ یک جزء بروید", 'ur': "کسی پارے کے پہلے صفحے پر جائیں", 'ar': "اذهب إلى أول صفحة في جزء"},
    "mushaf_unavailable": {'en': "Mushaf pages are not available yet.", 'ps': "د مصحف پاڼې تر اوسه نشته.", 'fa': "صفحات مصحف هنوز در دسترس نیستند.", 'ur': "مصحف کے صفحات ابھی دستیاب نہیں۔", 'ar': "صفحات المصحف غير متوفرة بعد."},
    "hizb_n": {'en': "Hizb {n}", 'ps': "حزب {n}", 'fa': "حزب {n}", 'ur': "حزب {n}", 'ar': "الحزب {n}"},

    // ---- Notifications ----
    "notif_channel": {'en': "Prayer Athan alerts", 'ps': "د لمانځه اذان خبرتیاوې", 'fa': "هشدارهای اذان نماز", 'ur': "نماز اذان کی اطلاعات", 'ar': "تنبيهات الأذان للصلوات"},
    "notif_channel_desc": {'en': "Athan alert at each prayer time", 'ps': "د هر لمانځه په وخت کې د اذان خبرتیا", 'fa': "هشدار اذان در هر وقت نماز", 'ur': "ہر نماز کے وقت اذان کی اطلاع", 'ar': "تنبيه الأذان عند كل وقت صلاة"},
    "notif_title": {'en': "QUBA — {prayer}", 'ps': "QUBA — {prayer}", 'fa': "QUBA — {prayer}", 'ur': "QUBA — {prayer}", 'ar': "قُبا — {prayer}"},
    "notif_body": {'en': "It is time for {prayer} prayer", 'ps': "د {prayer} لمانځه وخت دی", 'fa': "وقت نماز {prayer} است", 'ur': "{prayer} کی نماز کا وقت ہے", 'ar': "حان وقت صلاة {prayer}"},

    // ---- Widgets ----
    "reminder_on": {'en': "Reminder on", 'ps': "یادونه روانه ده", 'fa': "یادآوری روشن است", 'ur': "یاد دہانی جاری ہے", 'ar': "التذكير مفعّل"},
    "reminder_off": {'en': "Reminder off", 'ps': "یادونه بنده ده", 'fa': "یادآوری خاموش است", 'ur': "یاد دہانی بند ہے", 'ar': "التذكير معطّل"},

    // ---- 99 Names meanings (1..99, same order as content.dart names99; English values match content.dart exactly) ----
    "name_meaning_1": {'en': "The God — the only One worthy of worship", 'ps': "الله — یوازې هغه د عبادت وړ دی", 'fa': "خدا — تنها معبود شایستهٔ پرستش", 'ur': "اللہ — عبادت کے لائق واحد ذات", 'ar': "الله — الإله الوحيد المستحق للعبادة"},
    "name_meaning_2": {'en': "The Most Merciful", 'ps': "تر ټولو مهربان", 'fa': "بخشنده‌ترین", 'ur': "نہایت رحم کرنے والا", 'ar': "شديد الرحمة"},
    "name_meaning_3": {'en': "The Most Kind", 'ps': "ډېر مهربان", 'fa': "بسیار مهربان", 'ur': "بار بار رحم فرمانے والا", 'ar': "كثير الرحمة"},
    "name_meaning_4": {'en': "The King, the Sovereign", 'ps': "پاچا، واکمن", 'fa': "پادشاه، فرمانروا", 'ur': "بادشاہ، حقیقی حاکم", 'ar': "الملك، الحاكم"},
    "name_meaning_5": {'en': "The Most Holy", 'ps': "تر ټولو سپېڅلی", 'fa': "پاک‌ترین", 'ur': "پاک ذات", 'ar': "المنزَّه عن كل نقص"},
    "name_meaning_6": {'en': "The Source of Peace", 'ps': "د سولې سرچینه", 'fa': "سرچشمهٔ سلامتی", 'ur': "سلامتی دینے والا", 'ar': "مصدر السلام والأمان"},
    "name_meaning_7": {'en': "The Giver of Faith and Safety", 'ps': "د ایمان او امن ورکوونکی", 'fa': "بخشندهٔ ایمان و امنیت", 'ur': "امن و ایمان دینے والا", 'ar': "واهب الإيمان والأمان"},
    "name_meaning_8": {'en': "The Guardian, the Overseer", 'ps': "ساتونکی، څارونکی", 'fa': "نگهبان، ناظر", 'ur': "نگہبان", 'ar': "الحافظ، الرقيب"},
    "name_meaning_9": {'en': "The Almighty", 'ps': "تر ټولو ځواکمن", 'fa': "توانای مطلق", 'ur': "زبردست، غالب", 'ar': "القوي الغالب"},
    "name_meaning_10": {'en': "The Irresistible, the Restorer", 'ps': "نه ماتېدونکی، جوړوونکی", 'fa': "شکست‌ناپذیر، جبران‌کننده", 'ur': "زور آور", 'ar': "الذي لا يُقهر، الجابر"},
    "name_meaning_11": {'en': "The Supreme, the Majestic", 'ps': "تر ټولو لوی، جلال لرونکی", 'fa': "برتر، باشکوه", 'ur': "بڑائی والا", 'ar': "العظيم المتكبر"},
    "name_meaning_12": {'en': "The Creator", 'ps': "پیدا کوونکی", 'fa': "آفریننده", 'ur': "پیدا کرنے والا", 'ar': "الخالق"},
    "name_meaning_13": {'en': "The Originator", 'ps': "له هېڅ څخه پیدا کوونکی", 'fa': "پدیدآورنده", 'ur': "بغیر نمونے کے پیدا کرنے والا", 'ar': "المبدع من العدم"},
    "name_meaning_14": {'en': "The Fashioner of Forms", 'ps': "د بڼو جوړوونکی", 'fa': "صورت‌بخش", 'ur': "صورت بنانے والا", 'ar': "المصوِّر للأشكال"},
    "name_meaning_15": {'en': "The Great Forgiver", 'ps': "ډېر بخښونکی", 'fa': "بسیار آمرزنده", 'ur': "بار بار معاف کرنے والا", 'ar': "كثير المغفرة"},
    "name_meaning_16": {'en': "The Irresistible Subduer", 'ps': "نه ماتېدونکی غلبه کوونکی", 'fa': "چیرهٔ شکست‌ناپذیر", 'ur': "غالب، زیر کرنے والا", 'ar': "القاهر الذي لا يُغلب"},
    "name_meaning_17": {'en': "The Supreme Bestower", 'ps': "ډېر ورکوونکی", 'fa': "بخشندهٔ بزرگ", 'ur': "بے حساب عطا کرنے والا", 'ar': "كثير العطاء"},
    "name_meaning_18": {'en': "The Provider", 'ps': "رزق ورکوونکی", 'fa': "روزی‌رسان", 'ur': "رزق دینے والا", 'ar': "الرازق"},
    "name_meaning_19": {'en': "The Opener, the Judge", 'ps': "پرانیستونکی، فیصله کوونکی", 'fa': "گشاینده، داور", 'ur': "فیصلہ کرنے والا، کھولنے والا", 'ar': "الفاتح، الحاكم"},
    "name_meaning_20": {'en': "The All-Knowing", 'ps': "پر هر څه پوه", 'fa': "دانای همه‌چیز", 'ur': "سب کچھ جاننے والا", 'ar': "العالم بكل شيء"},
    "name_meaning_21": {'en': "The Withholder", 'ps': "راټولوونکی", 'fa': "گیرنده، تنگ‌کننده", 'ur': "روکنے، تنگ کرنے والا", 'ar': "القابض"},
    "name_meaning_22": {'en': "The Extender", 'ps': "پراخوونکی", 'fa': "گشاینده", 'ur': "کشادگی دینے والا", 'ar': "الباسط"},
    "name_meaning_23": {'en': "The Abaser", 'ps': "ټیټوونکی", 'fa': "پست‌کننده", 'ur': "پست کرنے والا", 'ar': "الخافض"},
    "name_meaning_24": {'en': "The Exalter", 'ps': "لوړوونکی", 'fa': "بلندکننده", 'ur': "بلند کرنے والا", 'ar': "الرافع"},
    "name_meaning_25": {'en': "The Giver of Honour", 'ps': "د عزت ورکوونکی", 'fa': "عزت‌بخش", 'ur': "عزت دینے والا", 'ar': "المعزّ"},
    "name_meaning_26": {'en': "The Giver of Dishonour", 'ps': "د ذلت ورکوونکی", 'fa': "ذلت‌بخش", 'ur': "ذلت دینے والا", 'ar': "المذلّ"},
    "name_meaning_27": {'en': "The All-Hearing", 'ps': "پر هر څه اورېدونکی", 'fa': "شنوای همه‌چیز", 'ur': "سننے والا", 'ar': "السميع لكل شيء"},
    "name_meaning_28": {'en': "The All-Seeing", 'ps': "پر هر څه لیدونکی", 'fa': "بینای همه‌چیز", 'ur': "دیکھنے والا", 'ar': "البصير بكل شيء"},
    "name_meaning_29": {'en': "The Impartial Judge", 'ps': "بې پرې قاضي", 'fa': "داور بی‌طرف", 'ur': "منصف، فیصلہ کرنے والا", 'ar': "الحكم العادل"},
    "name_meaning_30": {'en': "The Utterly Just", 'ps': "بشپړ عادل", 'fa': "کاملاً عادل", 'ur': "انصاف کرنے والا", 'ar': "العدل المطلق"},
    "name_meaning_31": {'en': "The Subtle, the Gentle", 'ps': "نازک، مهربان", 'fa': "لطیف، مهربان", 'ur': "باریک بین، مہربان", 'ar': "اللطيف، الرفيق"},
    "name_meaning_32": {'en': "The All-Aware", 'ps': "له هر څه خبر", 'fa': "آگاه از همه‌چیز", 'ur': "خبر رکھنے والا", 'ar': "الخبير بكل شيء"},
    "name_meaning_33": {'en': "The Forbearing", 'ps': "زغمونکی", 'fa': "بردبار", 'ur': "بردبار", 'ar': "الحليم"},
    "name_meaning_34": {'en': "The Magnificent", 'ps': "تر ټولو لوی", 'fa': "بزرگ", 'ur': "عظمت والا", 'ar': "العظيم"},
    "name_meaning_35": {'en': "The All-Forgiving", 'ps': "ډېر بخښونکی", 'fa': "بسیار آمرزنده", 'ur': "بخشنے والا", 'ar': "الذي يغفر الذنوب"},
    "name_meaning_36": {'en': "The Most Appreciative", 'ps': "تر ټولو قدر کوونکی", 'fa': "قدردان‌ترین", 'ur': "قدردان", 'ar': "الشاكر لعباده"},
    "name_meaning_37": {'en': "The Most High", 'ps': "تر ټولو لوړ", 'fa': "بلندمرتبه‌ترین", 'ur': "بلند مرتبہ", 'ar': "العليّ"},
    "name_meaning_38": {'en': "The Most Great", 'ps': "تر ټولو لوی", 'fa': "بزرگ‌ترین", 'ur': "سب سے بڑا", 'ar': "الكبير"},
    "name_meaning_39": {'en': "The Preserver", 'ps': "ساتونکی", 'fa': "نگهدارنده", 'ur': "حفاظت کرنے والا", 'ar': "الحافظ"},
    "name_meaning_40": {'en': "The Sustainer", 'ps': "رزق رسوونکی", 'fa': "روزی‌رسان", 'ur': "روزی رساں", 'ar': "الذي يرزق كل مخلوق"},
    "name_meaning_41": {'en': "The Reckoner", 'ps': "حساب اخیستونکی", 'fa': "حساب‌گیر", 'ur': "حساب لینے والا", 'ar': "الذي يحاسب العباد"},
    "name_meaning_42": {'en': "The Majestic One", 'ps': "د جلال خاوند", 'fa': "باشکوه", 'ur': "جلال و بزرگی والا", 'ar': "ذو الجلال"},
    "name_meaning_43": {'en': "The Most Generous", 'ps': "تر ټولو سخي", 'fa': "بخشنده‌ترین", 'ur': "کرم کرنے والا", 'ar': "الكريم"},
    "name_meaning_44": {'en': "The Watchful", 'ps': "څارونکی", 'fa': "نگهبان", 'ur': "نگرانی کرنے والا", 'ar': "الرقيب"},
    "name_meaning_45": {'en': "The Responsive", 'ps': "ځواب ورکوونکی", 'fa': "اجابت‌کننده", 'ur': "دعائیں قبول کرنے والا", 'ar': "المجيب"},
    "name_meaning_46": {'en': "The All-Encompassing", 'ps': "پر هر څه پراخ", 'fa': "فراگیر همه‌چیز", 'ur': "وسعت والا", 'ar': "الواسع"},
    "name_meaning_47": {'en': "The All-Wise", 'ps': "تر ټولو حکیم", 'fa': "حکیم‌ترین", 'ur': "حکمت والا", 'ar': "الحكيم"},
    "name_meaning_48": {'en': "The Most Loving", 'ps': "تر ټولو مینه کوونکی", 'fa': "دوست‌دارترین", 'ur': "محبت کرنے والا", 'ar': "الودود"},
    "name_meaning_49": {'en': "The Glorious", 'ps': "د عظمت خاوند", 'fa': "باشکوه", 'ur': "بزرگی والا", 'ar': "المجيد"},
    "name_meaning_50": {'en': "The Resurrector", 'ps': "بیا راژوندی کوونکی", 'fa': "برانگیزاننده", 'ur': "مردوں کو اٹھانے والا", 'ar': "الباعث"},
    "name_meaning_51": {'en': "The Witness", 'ps': "شاهد", 'fa': "گواه", 'ur': "گواہ", 'ar': "الشهيد"},
    "name_meaning_52": {'en': "The Absolute Truth", 'ps': "بشپړ حق", 'fa': "حق مطلق", 'ur': "حق، سچائی", 'ar': "الحق"},
    "name_meaning_53": {'en': "The Trustee, the Disposer", 'ps': "وکیل، کار جوړوونکی", 'fa': "وکیل، کارگزار", 'ur': "کارساز", 'ar': "الوكيل، المدبِّر"},
    "name_meaning_54": {'en': "The All-Strong", 'ps': "تر ټولو ځواکمن", 'fa': "نیرومندترین", 'ur': "طاقتور", 'ar': "القوي"},
    "name_meaning_55": {'en': "The Firm, the Steadfast", 'ps': "ټینګ، نه ټکان خورونکی", 'fa': "استوار", 'ur': "مضبوط", 'ar': "المتين الثابت"},
    "name_meaning_56": {'en': "The Protecting Friend", 'ps': "ساتونکی دوست", 'fa': "دوست نگهبان", 'ur': "دوست، مددگار", 'ar': "الوليّ الحافظ"},
    "name_meaning_57": {'en': "The Praiseworthy", 'ps': "د ستاینې وړ", 'fa': "شایستهٔ ستایش", 'ur': "تعریف کے لائق", 'ar': "المستحق للحمد"},
    "name_meaning_58": {'en': "The Counter of All Things", 'ps': "د هر څه شمېرونکی", 'fa': "شمارندهٔ همه‌چیز", 'ur': "شمار کرنے والا", 'ar': "الذي أحصى كل شيء"},
    "name_meaning_59": {'en': "The Originator", 'ps': "پیل کوونکی", 'fa': "آغازکننده", 'ur': "پہلی بار پیدا کرنے والا", 'ar': "المبدئ"},
    "name_meaning_60": {'en': "The Restorer", 'ps': "بیرته راګرځوونکی", 'fa': "بازگرداننده", 'ur': "دوبارہ پیدا کرنے والا", 'ar': "المعيد"},
    "name_meaning_61": {'en': "The Giver of Life", 'ps': "د ژوند ورکوونکی", 'fa': "زنده‌کننده", 'ur': "زندگی دینے والا", 'ar': "المحيي"},
    "name_meaning_62": {'en': "The Bringer of Death", 'ps': "د مرګ راوړونکی", 'fa': "میراننده", 'ur': "موت دینے والا", 'ar': "المميت"},
    "name_meaning_63": {'en': "The Ever-Living", 'ps': "تل ژوندی", 'fa': "همیشه زنده", 'ur': "زندہ", 'ar': "الحيّ الذي لا يموت"},
    "name_meaning_64": {'en': "The Self-Subsisting Sustainer", 'ps': "په خپله ولاړ ساتونکی", 'fa': "برپادارندهٔ هستی", 'ur': "قائم رکھنے والا", 'ar': "القيّوم"},
    "name_meaning_65": {'en': "The Perceiver, the Finder", 'ps': "موندوونکی", 'fa': "یابنده", 'ur': "پانے والا", 'ar': "الواجد"},
    "name_meaning_66": {'en': "The Illustrious, the Noble", 'ps': "لوی، عزتمند", 'fa': "باشکوه، والا", 'ur': "بزرگ، شان والا", 'ar': "الماجد"},
    "name_meaning_67": {'en': "The One", 'ps': "یو", 'fa': "یگانه", 'ur': "ایک، یکتا", 'ar': "الواحد"},
    "name_meaning_68": {'en': "The Eternal Refuge", 'ps': "تل پاتې پناه", 'fa': "پناه ابدی", 'ur': "بے نیاز", 'ar': "الصمد"},
    "name_meaning_69": {'en': "The Capable", 'ps': "قادر", 'fa': "توانا", 'ur': "قدرت والا", 'ar': "القادر"},
    "name_meaning_70": {'en': "The Powerful", 'ps': "بشپړ ځواکمن", 'fa': "توانای کامل", 'ur': "پوری قدرت والا", 'ar': "المقتدر"},
    "name_meaning_71": {'en': "The Promoter", 'ps': "مخکې کوونکی", 'fa': "پیش‌اندازنده", 'ur': "آگے بڑھانے والا", 'ar': "المقدِّم"},
    "name_meaning_72": {'en': "The Delayer", 'ps': "ځنډوونکی", 'fa': "پس‌اندازنده", 'ur': "پیچھے کرنے والا", 'ar': "المؤخِّر"},
    "name_meaning_73": {'en': "The First", 'ps': "لومړی", 'fa': "نخستین", 'ur': "سب سے پہلا", 'ar': "الأول"},
    "name_meaning_74": {'en': "The Last", 'ps': "وروستی", 'fa': "واپسین", 'ur': "سب کے بعد", 'ar': "الآخر"},
    "name_meaning_75": {'en': "The Manifest", 'ps': "څرګند", 'fa': "آشکار", 'ur': "ظاہر", 'ar': "الظاهر"},
    "name_meaning_76": {'en': "The Hidden", 'ps': "پټ", 'fa': "پنهان", 'ur': "پوشیدہ سے واقف", 'ar': "الباطن"},
    "name_meaning_77": {'en': "The Governor", 'ps': "واکمن، سرپرست", 'fa': "فرمانروا، سرپرست", 'ur': "حاکم، سرپرست", 'ar': "الوالي"},
    "name_meaning_78": {'en': "The Self-Exalted", 'ps': "تر ټولو لوړ", 'fa': "برتر از همه", 'ur': "سب سے بلند", 'ar': "المتعالي"},
    "name_meaning_79": {'en': "The Source of Goodness", 'ps': "د ښېګڼې سرچینه", 'fa': "سرچشمهٔ نیکی", 'ur': "نیکی کرنے والا", 'ar': "البرّ"},
    "name_meaning_80": {'en': "The Acceptor of Repentance", 'ps': "د توبې قبلوونکی", 'fa': "پذیرندهٔ توبه", 'ur': "توبہ قبول کرنے والا", 'ar': "التوّاب"},
    "name_meaning_81": {'en': "The Avenger", 'ps': "بدله اخیستونکی", 'fa': "انتقام‌گیرنده", 'ur': "بدلہ لینے والا", 'ar': "المنتقم"},
    "name_meaning_82": {'en': "The Pardoner", 'ps': "بخښونکی", 'fa': "بخشاینده", 'ur': "معاف کرنے والا", 'ar': "العفوّ"},
    "name_meaning_83": {'en': "The Most Kind", 'ps': "تر ټولو مهربان", 'fa': "مهربان‌ترین", 'ur': "نہایت شفیق", 'ar': "شديد الرأفة"},
    "name_meaning_84": {'en': "Master of the Kingdom", 'ps': "د واک خاوند", 'fa': "فرمانروای جهان", 'ur': "بادشاہی کا مالک", 'ar': "مالك الملك"},
    "name_meaning_85": {'en': "Lord of Majesty and Honour", 'ps': "د جلال او عزت خاوند", 'fa': "خداوند جلال و بزرگواری", 'ur': "جلال و اکرام والا", 'ar': "ذو الجلال والإكرام"},
    "name_meaning_86": {'en': "The Equitable", 'ps': "انصاف کوونکی", 'fa': "دادگر", 'ur': "انصاف کرنے والا", 'ar': "المقسط"},
    "name_meaning_87": {'en': "The Gatherer", 'ps': "راټولوونکی", 'fa': "گردآورنده", 'ur': "جمع کرنے والا", 'ar': "الجامع"},
    "name_meaning_88": {'en': "The Self-Sufficient", 'ps': "بې نیازه", 'fa': "بی‌نیاز", 'ur': "بے نیاز، غنی", 'ar': "الغنيّ"},
    "name_meaning_89": {'en': "The Enricher", 'ps': "شتمن کوونکی", 'fa': "بی‌نیازکننده", 'ur': "غنی کرنے والا", 'ar': "المغني"},
    "name_meaning_90": {'en': "The Preventer", 'ps': "مخنیوی کوونکی", 'fa': "بازدارنده", 'ur': "روکنے، بچانے والا", 'ar': "المانع"},
    "name_meaning_91": {'en': "The Distresser", 'ps': "د زیان رسوونکی", 'fa': "زیان‌رساننده", 'ur': "نقصان پہنچانے پر قادر", 'ar': "الضارّ"},
    "name_meaning_92": {'en': "The Benefactor", 'ps': "ګټه رسوونکی", 'fa': "سودرساننده", 'ur': "نفع دینے والا", 'ar': "النافع"},
    "name_meaning_93": {'en': "The Light", 'ps': "رڼا", 'fa': "نور", 'ur': "نور", 'ar': "النور"},
    "name_meaning_94": {'en': "The Guide", 'ps': "لارښود", 'fa': "هدایت‌کننده", 'ur': "ہدایت دینے والا", 'ar': "الهادي"},
    "name_meaning_95": {'en': "The Incomparable Originator", 'ps': "بې ساري پیدا کوونکی", 'fa': "پدیدآورندهٔ بی‌مانند", 'ur': "انوکھا پیدا کرنے والا", 'ar': "البديع"},
    "name_meaning_96": {'en': "The Everlasting", 'ps': "تل پاتې", 'fa': "همیشه باقی", 'ur': "ہمیشہ باقی رہنے والا", 'ar': "الباقي"},
    "name_meaning_97": {'en': "The Inheritor", 'ps': "وارث", 'fa': "وارث", 'ur': "وارث", 'ar': "الوارث"},
    "name_meaning_98": {'en': "The Guide to Rightness", 'ps': "سمې لارې ته لارښود", 'fa': "راهنمای راه راست", 'ur': "راہ دکھانے والا", 'ar': "الرشيد"},
    "name_meaning_99": {'en': "The Patient", 'ps': "زغمونکی", 'fa': "صبور", 'ur': "صبر کرنے والا", 'ar': "الصبور"},

    // ---- Surah meanings (1..114; English values match quran_bundle.json englishNameTranslation exactly) ----
    "surah_meaning_1": {'en': "The Opening", 'ps': "پیل", 'fa': "گشایش", 'ur': "کھولنے والی", 'ar': "الفاتحة"},
    "surah_meaning_2": {'en': "The Cow", 'ps': "غوا", 'fa': "گاو", 'ur': "گائے", 'ar': "البقرة"},
    "surah_meaning_3": {'en': "The Family of Imraan", 'ps': "د عمران کورنۍ", 'fa': "خاندان عمران", 'ur': "عمران کی اولاد", 'ar': "آل عمران"},
    "surah_meaning_4": {'en': "The Women", 'ps': "ښځې", 'fa': "زنان", 'ur': "عورتیں", 'ar': "النساء"},
    "surah_meaning_5": {'en': "The Table", 'ps': "دسترخوان", 'fa': "سفره", 'ur': "دسترخوان", 'ar': "المائدة"},
    "surah_meaning_6": {'en': "The Cattle", 'ps': "څاروي", 'fa': "چهارپایان", 'ur': "چوپائے، مویشی", 'ar': "الأنعام"},
    "surah_meaning_7": {'en': "The Heights", 'ps': "لوړ ځایونه", 'fa': "بلندی‌ها", 'ur': "بلند مقامات", 'ar': "الأعراف"},
    "surah_meaning_8": {'en': "The Spoils of War", 'ps': "د جګړې غنیمت", 'fa': "غنایم جنگی", 'ur': "مالِ غنیمت", 'ar': "الأنفال"},
    "surah_meaning_9": {'en': "The Repentance", 'ps': "توبه", 'fa': "توبه", 'ur': "توبہ، رجوع", 'ar': "التوبة"},
    "surah_meaning_10": {'en': "Jonas", 'ps': "یونس", 'fa': "یونس", 'ur': "یونس", 'ar': "يونس"},
    "surah_meaning_11": {'en': "Hud", 'ps': "هود", 'fa': "هود", 'ur': "ہود", 'ar': "هود"},
    "surah_meaning_12": {'en': "Joseph", 'ps': "یوسف", 'fa': "یوسف", 'ur': "یوسف", 'ar': "يوسف"},
    "surah_meaning_13": {'en': "The Thunder", 'ps': "تندر", 'fa': "رعد", 'ur': "گرج", 'ar': "الرعد"},
    "surah_meaning_14": {'en': "Abraham", 'ps': "ابراهیم", 'fa': "ابراهیم", 'ur': "ابراہیم", 'ar': "إبراهيم"},
    "surah_meaning_15": {'en': "The Rock", 'ps': "ډبره", 'fa': "صخره", 'ur': "حجر", 'ar': "الحجر"},
    "surah_meaning_16": {'en': "The Bee", 'ps': "مچۍ", 'fa': "زنبور عسل", 'ur': "شہد کی مکھی", 'ar': "النحل"},
    "surah_meaning_17": {'en': "The Night Journey", 'ps': "د شپې سفر", 'fa': "سفر شبانه", 'ur': "رات کا سفر", 'ar': "الإسراء"},
    "surah_meaning_18": {'en': "The Cave", 'ps': "غار", 'fa': "غار", 'ur': "غار", 'ar': "الكهف"},
    "surah_meaning_19": {'en': "Mary", 'ps': "مریم", 'fa': "مریم", 'ur': "مریم", 'ar': "مريم"},
    "surah_meaning_20": {'en': "Taa-Haa", 'ps': "طه", 'fa': "طه", 'ur': "طٰہٰ", 'ar': "طه"},
    "surah_meaning_21": {'en': "The Prophets", 'ps': "پیغمبران", 'fa': "پیامبران", 'ur': "انبیاء", 'ar': "الأنبياء"},
    "surah_meaning_22": {'en': "The Pilgrimage", 'ps': "حج", 'fa': "حج", 'ur': "حج", 'ar': "الحج"},
    "surah_meaning_23": {'en': "The Believers", 'ps': "مومنان", 'fa': "مؤمنان", 'ur': "ایمان والے", 'ar': "المؤمنون"},
    "surah_meaning_24": {'en': "The Light", 'ps': "رڼا", 'fa': "نور", 'ur': "روشنی", 'ar': "النور"},
    "surah_meaning_25": {'en': "The Criterion", 'ps': "فرقان", 'fa': "فرقان", 'ur': "حق و باطل میں فرق کرنے والا", 'ar': "الفرقان"},
    "surah_meaning_26": {'en': "The Poets", 'ps': "شاعران", 'fa': "شاعران", 'ur': "شاعر", 'ar': "الشعراء"},
    "surah_meaning_27": {'en': "The Ant", 'ps': "میږی", 'fa': "مورچه", 'ur': "چیونٹی", 'ar': "النمل"},
    "surah_meaning_28": {'en': "The Stories", 'ps': "کیسې", 'fa': "داستان‌ها", 'ur': "قصے", 'ar': "القصص"},
    "surah_meaning_29": {'en': "The Spider", 'ps': "غڼې", 'fa': "عنکبوت", 'ur': "مکڑی", 'ar': "العنكبوت"},
    "surah_meaning_30": {'en': "The Romans", 'ps': "رومیان", 'fa': "رومیان", 'ur': "رومی سلطنت", 'ar': "الروم"},
    "surah_meaning_31": {'en': "Luqman", 'ps': "لقمان", 'fa': "لقمان", 'ur': "لقمان", 'ar': "لقمان"},
    "surah_meaning_32": {'en': "The Prostration", 'ps': "سجده", 'fa': "سجده", 'ur': "سجدہ کرنا", 'ar': "السجدة"},
    "surah_meaning_33": {'en': "The Clans", 'ps': "ډلې", 'fa': "گروه‌ها", 'ur': "گروہ", 'ar': "الأحزاب"},
    "surah_meaning_34": {'en': "Sheba", 'ps': "سبا", 'fa': "سبا", 'ur': "سبا", 'ar': "سبأ"},
    "surah_meaning_35": {'en': "The Originator", 'ps': "پیدا کوونکی", 'fa': "آفریننده", 'ur': "پیدا کرنے والا", 'ar': "فاطر"},
    "surah_meaning_36": {'en': "Yaseen", 'ps': "یاسین", 'fa': "یس", 'ur': "یٰسٓ", 'ar': "يس"},
    "surah_meaning_37": {'en': "Those drawn up in Ranks", 'ps': "صف جوړوونکي", 'fa': "صف‌بستگان", 'ur': "صف باندھنے والے", 'ar': "الصافات"},
    "surah_meaning_38": {'en': "The letter Saad", 'ps': "د ص توری", 'fa': "حرف ص", 'ur': "حرف ص", 'ar': "ص"},
    "surah_meaning_39": {'en': "The Groups", 'ps': "ډلې", 'fa': "گروه‌ها", 'ur': "گروہ در گروہ", 'ar': "الزمر"},
    "surah_meaning_40": {'en': "The Forgiver", 'ps': "بخښونکی", 'fa': "آمرزنده", 'ur': "بخشنے والا", 'ar': "غافر"},
    "surah_meaning_41": {'en': "Explained in detail", 'ps': "په تفصیل بیان شوې", 'fa': "شرح داده‌شده", 'ur': "واضح طور پر بیان کی گئی", 'ar': "فُصِّلت"},
    "surah_meaning_42": {'en': "Consultation", 'ps': "مشوره", 'fa': "مشورت", 'ur': "مشورہ", 'ar': "الشورى"},
    "surah_meaning_43": {'en': "Ornaments of gold", 'ps': "د سرو زرو زیور", 'fa': "زر و زیور", 'ur': "سونا، زینت", 'ar': "الزخرف"},
    "surah_meaning_44": {'en': "The Smoke", 'ps': "لوګی", 'fa': "دود", 'ur': "دھواں", 'ar': "الدخان"},
    "surah_meaning_45": {'en': "Crouching", 'ps': "په ګونډو ناست", 'fa': "زانو زده", 'ur': "گھٹنوں کے بل گرے ہوئے", 'ar': "الجاثية"},
    "surah_meaning_46": {'en': "The Dunes", 'ps': "د شګو غونډۍ", 'fa': "تپه‌های شن", 'ur': "ریت والے علاقے", 'ar': "الأحقاف"},
    "surah_meaning_47": {'en': "Muhammad", 'ps': "محمد", 'fa': "محمد", 'ur': "محمد ﷺ", 'ar': "محمد"},
    "surah_meaning_48": {'en': "The Victory", 'ps': "بریا", 'fa': "پیروزی", 'ur': "فتح، کامیابی", 'ar': "الفتح"},
    "surah_meaning_49": {'en': "The Inner Apartments", 'ps': "کوټې", 'fa': "حجره‌ها", 'ur': "حجرے، کمرے", 'ar': "الحجرات"},
    "surah_meaning_50": {'en': "The letter Qaaf", 'ps': "د ق توری", 'fa': "حرف ق", 'ur': "حرف ق", 'ar': "ق"},
    "surah_meaning_51": {'en': "The Winnowing Winds", 'ps': "خوروونکې بادونه", 'fa': "بادهای پراکنده‌کننده", 'ur': "بکھیرنے والی ہوائیں", 'ar': "الذاريات"},
    "surah_meaning_52": {'en': "The Mount", 'ps': "غر", 'fa': "کوه طور", 'ur': "طور پہاڑ", 'ar': "الطور"},
    "surah_meaning_53": {'en': "The Star", 'ps': "ستوری", 'fa': "ستاره", 'ur': "ستارہ", 'ar': "النجم"},
    "surah_meaning_54": {'en': "The Moon", 'ps': "سپوږمۍ", 'fa': "ماه", 'ur': "چاند", 'ar': "القمر"},
    "surah_meaning_55": {'en': "The Beneficent", 'ps': "ډېر مهربان", 'fa': "بخشنده", 'ur': "بے حد رحم فرمانے والا", 'ar': "الرحمن"},
    "surah_meaning_56": {'en': "The Inevitable", 'ps': "راتلونکې", 'fa': "واقعه", 'ur': "ہونے والی، قیامت", 'ar': "الواقعة"},
    "surah_meaning_57": {'en': "The Iron", 'ps': "اوسپنه", 'fa': "آهن", 'ur': "لوہا", 'ar': "الحديد"},
    "surah_meaning_58": {'en': "The Pleading Woman", 'ps': "بحث کوونکې ښځه", 'fa': "زن مجادله‌کننده", 'ur': "بحث کرنے والی خاتون", 'ar': "المجادلة"},
    "surah_meaning_59": {'en': "The Exile", 'ps': "شړل", 'fa': "تبعید", 'ur': "جمع کرنا", 'ar': "الحشر"},
    "surah_meaning_60": {'en': "She that is to be examined", 'ps': "ازمېل شوې ښځه", 'fa': "زن آزموده", 'ur': "امتحان لینے والی", 'ar': "الممتحنة"},
    "surah_meaning_61": {'en': "The Ranks", 'ps': "صفونه", 'fa': "صف", 'ur': "صف باندھنے والے", 'ar': "الصف"},
    "surah_meaning_62": {'en': "Friday", 'ps': "جمعه", 'fa': "جمعه", 'ur': "جمعہ کا دن", 'ar': "الجمعة"},
    "surah_meaning_63": {'en': "The Hypocrites", 'ps': "منافقان", 'fa': "منافقان", 'ur': "منافق لوگ", 'ar': "المنافقون"},
    "surah_meaning_64": {'en': "Mutual Disillusion", 'ps': "دوه اړخیزه تاوان", 'fa': "زیان متقابل", 'ur': "خسارے کا دن", 'ar': "التغابن"},
    "surah_meaning_65": {'en': "Divorce", 'ps': "طلاق", 'fa': "طلاق", 'ur': "طلاق", 'ar': "الطلاق"},
    "surah_meaning_66": {'en': "The Prohibition", 'ps': "حرامول", 'fa': "تحریم", 'ur': "حرام کرنا", 'ar': "التحريم"},
    "surah_meaning_67": {'en': "The Sovereignty", 'ps': "واکمني", 'fa': "فرمانروایی", 'ur': "بادشاہی", 'ar': "الملك"},
    "surah_meaning_68": {'en': "The Pen", 'ps': "قلم", 'fa': "قلم", 'ur': "قلم", 'ar': "القلم"},
    "surah_meaning_69": {'en': "The Reality", 'ps': "حقیقت", 'fa': "حقیقت", 'ur': "ثابت ہونے والی، حقیقت", 'ar': "الحاقة"},
    "surah_meaning_70": {'en': "The Ascending Stairways", 'ps': "پورته کېدونکې زینې", 'fa': "نردبان‌های صعود", 'ur': "چڑھنے کی راہیں", 'ar': "المعارج"},
    "surah_meaning_71": {'en': "Noah", 'ps': "نوح", 'fa': "نوح", 'ur': "نوح", 'ar': "نوح"},
    "surah_meaning_72": {'en': "The Jinn", 'ps': "پېریان", 'fa': "جن", 'ur': "جنات", 'ar': "الجن"},
    "surah_meaning_73": {'en': "The Enshrouded One", 'ps': "په څادر کې نغښتی", 'fa': "جامه به خود پیچیده", 'ur': "چادر اوڑھنے والا", 'ar': "المزمل"},
    "surah_meaning_74": {'en': "The Cloaked One", 'ps': "په څادر کې پټ", 'fa': "جامه به خود پیچیده", 'ur': "چادر لپیٹنے والا", 'ar': "المدثر"},
    "surah_meaning_75": {'en': "The Resurrection", 'ps': "قیامت", 'fa': "قیامت", 'ur': "قیامت", 'ar': "القيامة"},
    "surah_meaning_76": {'en': "Man", 'ps': "انسان", 'fa': "انسان", 'ur': "انسان", 'ar': "الإنسان"},
    "surah_meaning_77": {'en': "The Emissaries", 'ps': "استول شوي", 'fa': "فرستادگان", 'ur': "بھیجی جانے والی ہوائیں", 'ar': "المرسلات"},
    "surah_meaning_78": {'en': "The Announcement", 'ps': "لوی خبر", 'fa': "خبر بزرگ", 'ur': "بڑی خبر", 'ar': "النبأ"},
    "surah_meaning_79": {'en': "Those who drag forth", 'ps': "راویستونکي", 'fa': "فرشتگان جان‌گیر", 'ur': "سختی سے کھینچنے والے", 'ar': "النازعات"},
    "surah_meaning_80": {'en': "He frowned", 'ps': "تریو شو", 'fa': "رو ترش کرد", 'ur': "تیوری چڑھانا", 'ar': "عبس"},
    "surah_meaning_81": {'en': "The Overthrowing", 'ps': "تاوول", 'fa': "در هم پیچیده شدن", 'ur': "لپیٹ دینا", 'ar': "التكوير"},
    "surah_meaning_82": {'en': "The Cleaving", 'ps': "چاودل", 'fa': "شکافته شدن", 'ur': "پھٹ جانا", 'ar': "الانفطار"},
    "surah_meaning_83": {'en': "Defrauding", 'ps': "په تول کې کموونکي", 'fa': "کم‌فروشان", 'ur': "ناپ تول میں کمی کرنے والے", 'ar': "المطففين"},
    "surah_meaning_84": {'en': "The Splitting Open", 'ps': "څېرېدل", 'fa': "شکافته شدن", 'ur': "شق ہونا، پھٹنا", 'ar': "الانشقاق"},
    "surah_meaning_85": {'en': "The Constellations", 'ps': "برجونه", 'fa': "برج‌ها", 'ur': "آسمانی برج", 'ar': "البروج"},
    "surah_meaning_86": {'en': "The Morning Star", 'ps': "سهارنی ستوری", 'fa': "ستارهٔ شب", 'ur': "چمکتا تارا", 'ar': "الطارق"},
    "surah_meaning_87": {'en': "The Most High", 'ps': "تر ټولو لوړ", 'fa': "بلندمرتبه‌ترین", 'ur': "سب سے بلند", 'ar': "الأعلى"},
    "surah_meaning_88": {'en': "The Overwhelming", 'ps': "پوښونکې", 'fa': "فراگیرنده", 'ur': "چھا جانے والی آفت", 'ar': "الغاشية"},
    "surah_meaning_89": {'en': "The Dawn", 'ps': "سهار", 'fa': "سپیده‌دم", 'ur': "فجر", 'ar': "الفجر"},
    "surah_meaning_90": {'en': "The City", 'ps': "ښار", 'fa': "شهر", 'ur': "شہر", 'ar': "البلد"},
    "surah_meaning_91": {'en': "The Sun", 'ps': "لمر", 'fa': "خورشید", 'ur': "سورج", 'ar': "الشمس"},
    "surah_meaning_92": {'en': "The Night", 'ps': "شپه", 'fa': "شب", 'ur': "رات", 'ar': "الليل"},
    "surah_meaning_93": {'en': "The Morning Hours", 'ps': "سهار وخت", 'fa': "چاشت", 'ur': "چمکتا دن", 'ar': "الضحى"},
    "surah_meaning_94": {'en': "The Consolation", 'ps': "د سینې پراخول", 'fa': "گشایش سینه", 'ur': "شرح صدر", 'ar': "الشرح"},
    "surah_meaning_95": {'en': "The Fig", 'ps': "انځر", 'fa': "انجیر", 'ur': "انجیر", 'ar': "التين"},
    "surah_meaning_96": {'en': "The Clot", 'ps': "د وینې ټوټه", 'fa': "لختهٔ خون", 'ur': "خون کا لوتھڑا", 'ar': "العلق"},
    "surah_meaning_97": {'en': "The Power, Fate", 'ps': "قدرت، تقدیر", 'fa': "قدر، سرنوشت", 'ur': "تقدیر، عظمت والی رات", 'ar': "القدر"},
    "surah_meaning_98": {'en': "The Evidence", 'ps': "څرګند ثبوت", 'fa': "دلیل آشکار", 'ur': "واضح دلیل", 'ar': "البينة"},
    "surah_meaning_99": {'en': "The Earthquake", 'ps': "زلزله", 'fa': "زلزله", 'ur': "زلزلہ", 'ar': "الزلزلة"},
    "surah_meaning_100": {'en': "The Chargers", 'ps': "منډې وهونکي آسونه", 'fa': "اسبان تازنده", 'ur': "دوڑنے والے گھوڑے", 'ar': "العاديات"},
    "surah_meaning_101": {'en': "The Calamity", 'ps': "ناورین", 'fa': "کوبنده", 'ur': "ہولناک آواز", 'ar': "القارعة"},
    "surah_meaning_102": {'en': "Competition", 'ps': "سیالي", 'fa': "فزون‌خواهی", 'ur': "زیادتی کی حرص", 'ar': "التكاثر"},
    "surah_meaning_103": {'en': "The Declining Day, Epoch", 'ps': "وخت", 'fa': "عصر", 'ur': "زمانہ", 'ar': "العصر"},
    "surah_meaning_104": {'en': "The Traducer", 'ps': "غیبت کوونکی", 'fa': "عیب‌جو", 'ur': "طعن کرنے والا", 'ar': "الهمزة"},
    "surah_meaning_105": {'en': "The Elephant", 'ps': "هاتی", 'fa': "فیل", 'ur': "ہاتھی", 'ar': "الفيل"},
    "surah_meaning_106": {'en': "Quraysh", 'ps': "قریش", 'fa': "قریش", 'ur': "قریش قبیلہ", 'ar': "قريش"},
    "surah_meaning_107": {'en': "Almsgiving", 'ps': "مرسته", 'fa': "ماعون", 'ur': "معمولی مدد", 'ar': "الماعون"},
    "surah_meaning_108": {'en': "Abundance", 'ps': "ډېروالی", 'fa': "کوثر", 'ur': "خیرِ کثیر", 'ar': "الكوثر"},
    "surah_meaning_109": {'en': "The Disbelievers", 'ps': "کافران", 'fa': "کافران", 'ur': "انکار کرنے والے", 'ar': "الكافرون"},
    "surah_meaning_110": {'en': "Divine Support", 'ps': "مرسته", 'fa': "یاری", 'ur': "مدد، فتح", 'ar': "النصر"},
    "surah_meaning_111": {'en': "The Palm Fibre", 'ps': "د خرما تار", 'fa': "ریسمان بافته", 'ur': "بٹی ہوئی رسی", 'ar': "المسد"},
    "surah_meaning_112": {'en': "Sincerity", 'ps': "اخلاص", 'fa': "اخلاص", 'ur': "توحید، خالص عقیدہ", 'ar': "الإخلاص"},
    "surah_meaning_113": {'en': "The Dawn", 'ps': "سهار", 'fa': "سپیده‌دم", 'ur': "فجر، صبح کی روشنی", 'ar': "الفلق"},
    "surah_meaning_114": {'en': "Mankind", 'ps': "خلک", 'fa': "مردم", 'ur': "لوگ، انسان", 'ar': "الناس"},

    // ---- Juz names (1..30; English = the transliterated para name from juz_data.dart, ps/fa/ur = the Arabic-script form) ----
    "juz_name_1": {'en': "Alaf Lam Meem", 'ps': "الم", 'fa': "الم", 'ur': "الم", 'ar': "الم"},
    "juz_name_2": {'en': "Sayaqool", 'ps': "سیقول", 'fa': "سیقول", 'ur': "سیقول", 'ar': "سيقول"},
    "juz_name_3": {'en': "Tilkal Rusull", 'ps': "تلک الرسل", 'fa': "تلک الرسل", 'ur': "تلک الرسل", 'ar': "تلك الرسل"},
    "juz_name_4": {'en': "Lan Tana Loo", 'ps': "لن تنالوا", 'fa': "لن تنالوا", 'ur': "لن تنالوا", 'ar': "لن تنالوا"},
    "juz_name_5": {'en': "Wal Mohsanat", 'ps': "والمحصنات", 'fa': "والمحصنات", 'ur': "والمحصنات", 'ar': "والمحصنات"},
    "juz_name_6": {'en': "La Yuhibbullah", 'ps': "لا یحب الله", 'fa': "لا یحب الله", 'ur': "لا یحب اللہ", 'ar': "لا يحب الله"},
    "juz_name_7": {'en': "Wa Iza Samiu", 'ps': "واذا سمعوا", 'fa': "واذا سمعوا", 'ur': "واذا سمعوا", 'ar': "وإذا سمعوا"},
    "juz_name_8": {'en': "Wa Lau Annana", 'ps': "ولو اننا", 'fa': "ولو اننا", 'ur': "ولو اننا", 'ar': "ولو أننا"},
    "juz_name_9": {'en': "Qalal Mala", 'ps': "قال الملا", 'fa': "قال الملا", 'ur': "قال الملا", 'ar': "قال الملأ"},
    "juz_name_10": {'en': "Wa'lamu", 'ps': "واعلموا", 'fa': "واعلموا", 'ur': "واعلموا", 'ar': "واعلموا"},
    "juz_name_11": {'en': "Ya'taziroon", 'ps': "یعتذرون", 'fa': "یعتذرون", 'ur': "یعتذرون", 'ar': "يعتذرون"},
    "juz_name_12": {'en': "Wa Mamin Daabbah", 'ps': "وما من دابۃ", 'fa': "وما من دابۃ", 'ur': "وما من دابۃ", 'ar': "وما من دابة"},
    "juz_name_13": {'en': "Wa Ma Ubarri", 'ps': "وما ابرئ", 'fa': "وما ابرئ", 'ur': "وما ابرئ", 'ar': "وما أبرئ"},
    "juz_name_14": {'en': "Rubama", 'ps': "ربما", 'fa': "ربما", 'ur': "ربما", 'ar': "ربما"},
    "juz_name_15": {'en': "Subhanallazi", 'ps': "سبحان الذی", 'fa': "سبحان الذی", 'ur': "سبحان الذی", 'ar': "سبحان الذي"},
    "juz_name_16": {'en': "Qal Alam", 'ps': "قال الم", 'fa': "قال الم", 'ur': "قال الم", 'ar': "قال ألم"},
    "juz_name_17": {'en': "Iqtaraba", 'ps': "اقترب", 'fa': "اقترب", 'ur': "اقترب", 'ar': "اقترب"},
    "juz_name_18": {'en': "Qad Aflaha", 'ps': "قد افلح", 'fa': "قد افلح", 'ur': "قد افلح", 'ar': "قد أفلح"},
    "juz_name_19": {'en': "Wa Qalallazina", 'ps': "وقال الذین", 'fa': "وقال الذین", 'ur': "وقال الذین", 'ar': "وقال الذين"},
    "juz_name_20": {'en': "Amman Khalaq", 'ps': "امن خلق", 'fa': "امن خلق", 'ur': "امن خلق", 'ar': "أمن خلق"},
    "juz_name_21": {'en': "Utlu Ma Uhiya", 'ps': "اتل ما اوحی", 'fa': "اتل ما اوحی", 'ur': "اتل ما اوحی", 'ar': "اتل ما أوحي"},
    "juz_name_22": {'en': "Wa Man Yaqnut", 'ps': "ومن یقنت", 'fa': "ومن یقنت", 'ur': "ومن یقنت", 'ar': "ومن يقنت"},
    "juz_name_23": {'en': "Wa Maliya", 'ps': "وما لی", 'fa': "وما لی", 'ur': "وما لی", 'ar': "وما لي"},
    "juz_name_24": {'en': "Faman Azlam", 'ps': "فمن اظلم", 'fa': "فمن اظلم", 'ur': "فمن اظلم", 'ar': "فمن أظلم"},
    "juz_name_25": {'en': "Ilaihi Yuraddu", 'ps': "الیہ یرد", 'fa': "الیہ یرد", 'ur': "الیہ یرد", 'ar': "إليه يرد"},
    "juz_name_26": {'en': "Ha Mim", 'ps': "حم", 'fa': "حم", 'ur': "حم", 'ar': "حم"},
    "juz_name_27": {'en': "Qal Fama Khadbakum", 'ps': "قال فما خطبکم", 'fa': "قال فما خطبکم", 'ur': "قال فما خطبکم", 'ar': "قال فما خطبكم"},
    "juz_name_28": {'en': "Qad Sami'allah", 'ps': "قد سمع الله", 'fa': "قد سمع الله", 'ur': "قد سمع اللہ", 'ar': "قد سمع الله"},
    "juz_name_29": {'en': "Tabarakallazi", 'ps': "تبارک الذی", 'fa': "تبارک الذی", 'ur': "تبارک الذی", 'ar': "تبارك الذي"},
    "juz_name_30": {'en': "Amma", 'ps': "عم", 'fa': "عم", 'ur': "عم", 'ar': "عم"},
    // --- Round 3: reciters ---
    "reciter": {'en': "Reciter", 'ps': "قاري", 'fa': "قاری", 'ur': "قاری", 'ar': "القارئ"},
    "reciter_name_alafasy": {'en': "Mishary Rashid al-Afasy", 'ps': "مشاري راشد العفاسي", 'fa': "مشاری راشد العفاسی", 'ur': "مشاری راشد العفاسی", 'ar': "مشاري راشد العفاسي"},
    "reciter_name_abdulbasit": {'en': "Abdul Basit Abdul Samad", 'ps': "عبدالباسط عبدالصمد", 'fa': "عبدالباسط عبدالصمد", 'ur': "عبدالباسط عبدالصمد", 'ar': "عبد الباسط عبد الصمد"},
    "reciter_name_mahermuaiqly": {'en': "Maher Al Muaiqly", 'ps': "ماهر المعيقلي", 'fa': "ماهر المعیقلی", 'ur': "ماہر المعقلی", 'ar': "ماهر المعيقلي"},
    "reciter_name_shuraym": {'en': "Saud Al-Shuraim", 'ps': "سعود الشريم", 'fa': "سعود الشریم", 'ur': "سعود الشریم", 'ar': "سعود الشريم"},
    // --- Round 3: translations ---
    "translation": {'en': "Translation", 'ps': "ژباړه", 'fa': "ترجمه", 'ur': "ترجمہ", 'ar': "الترجمة"},
    "translation_none": {'en': "Arabic only", 'ps': "یوازې عربي", 'fa': "فقط عربی", 'ur': "صرف عربی", 'ar': "العربية فقط"},
    "translation_jalandhry": {'en': "Urdu — Fateh Muhammad Jalandhari", 'ps': "اردو — فتح محمد جالندھري", 'fa': "اردو — فتح محمد جالندهری", 'ur': "اردو — فتح محمد جالندھری", 'ar': "الأردية — فتح محمد جالندهري"},
    "translation_ghomshei": {'en': "Dari — Mahdi Elahi Ghomshei", 'ps': "دري — مهدي الهي قمشه‌اي", 'fa': "دری — مهدی الهی قمشه‌ای", 'ur': "دری — مہدی الہی قمشئی", 'ar': "الفارسية (الدارية) — مهدي إلهي قمشئي"},
    "translation_unavailable": {'en': "Translation not available", 'ps': "ژباړه نشته", 'fa': "ترجمه در دسترس نیست", 'ur': "ترجمہ دستیاب نہیں", 'ar': "الترجمة غير متوفرة"},
    // --- Round 3: prayer log ---
    "prayer_log": {'en': "Prayer log", 'ps': "د لمانځه ریکارډ", 'fa': "ثبت نماز", 'ur': "نماز کا ریکارڈ", 'ar': "سجل الصلوات"},
    "prayed": {'en': "Prayed", 'ps': "ولمځل شو", 'fa': "خوانده شد", 'ur': "پڑھی گئی", 'ar': "صُلِّيت"},
    "mark_prayed": {'en': "Mark as prayed", 'ps': "ولمځل شو په نښه کړه", 'fa': "به‌عنوان خوانده‌شده علامت بزن", 'ur': "پڑھی ہوئی نشان زد کریں", 'ar': "وضع علامة «صُلِّيت»"},
    "this_week": {'en': "This week", 'ps': "دا اونۍ", 'fa': "این هفته", 'ur': "اس ہفتے", 'ar': "هذا الأسبوع"},
    "prayers_today": {'en': "Prayers today", 'ps': "نن لمونځونه", 'fa': "نمازهای امروز", 'ur': "آج کی نمازیں", 'ar': "صلوات اليوم"},
    "prayers_prayed_count": {'en': "{count} of 5 prayed", 'ps': "{count} له 5 څخه ولمځل شول", 'fa': "{count} از 5 خوانده شد", 'ur': "5 میں سے {count} پڑھی گئیں", 'ar': "{count} من 5 صُلِّيت"},
    // --- Round 3: notes ---
    "notes": {'en': "Notes", 'ps': "یادښتونه", 'fa': "یادداشت‌ها", 'ur': "نوٹس", 'ar': "الملاحظات"},
    "note": {'en': "Note", 'ps': "یادښت", 'fa': "یادداشت", 'ur': "نوٹ", 'ar': "ملاحظة"},
    "add_note": {'en': "Add note", 'ps': "یادښت اضافه کړه", 'fa': "افزودن یادداشت", 'ur': "نوٹ شامل کریں", 'ar': "إضافة ملاحظة"},
    "edit_note": {'en': "Edit note", 'ps': "یادښت سمول", 'fa': "ویرایش یادداشت", 'ur': "نوٹ میں ترمیم کریں", 'ar': "تعديل الملاحظة"},
    "note_hint": {'en': "Write your note here…", 'ps': "خپل یادښت دلته ولیکه…", 'fa': "یادداشت خود را اینجا بنویسید…", 'ur': "اپنا نوٹ یہاں لکھیں…", 'ar': "اكتب ملاحظتك هنا…"},
    "delete_note": {'en': "Delete note", 'ps': "یادښت ړنګ کړه", 'fa': "حذف یادداشت", 'ur': "نوٹ حذف کریں", 'ar': "حذف الملاحظة"},
    "no_notes": {'en': "No notes yet", 'ps': "تر اوسه هېڅ یادښت نشته", 'fa': "هنوز یادداشتی نیست", 'ur': "ابھی کوئی نوٹ نہیں", 'ar': "لا توجد ملاحظات بعد"},
    // --- Round 3: memorisation ---
    "repeat_verse": {'en': "Repeat verse", 'ps': "آیت تکرار کړه", 'fa': "تکرار آیه", 'ur': "آیت دہرائیں", 'ar': "تكرار الآية"},
    "repeat_off": {'en': "Off", 'ps': "بند", 'fa': "خاموش", 'ur': "بند", 'ar': "إيقاف"},
    "repeat_1x": {'en': "Once", 'ps': "یو ځل", 'fa': "یک بار", 'ur': "ایک بار", 'ar': "مرة واحدة"},
    "repeat_3x": {'en': "3 times", 'ps': "3 ځله", 'fa': "3 بار", 'ur': "3 بار", 'ar': "3 مرات"},
    "repeat_5x": {'en': "5 times", 'ps': "5 ځله", 'fa': "5 بار", 'ur': "5 بار", 'ar': "5 مرات"},
    "repeat_loop": {'en': "Loop", 'ps': "تکرار", 'fa': "تکرار", 'ur': "دہرائیں", 'ar': "تكرار مستمر"},
    "repeat_range": {'en': "Repeat a range", 'ps': "یو حد تکرار کړه", 'fa': "تکرار یک بازه", 'ur': "ایک رینج دہرائیں", 'ar': "تكرار مجموعة آيات"},
    "range_from": {'en': "From verse", 'ps': "له آیت څخه", 'fa': "از آیه", 'ur': "آیت سے", 'ar': "من الآية"},
    "range_to": {'en': "To verse", 'ps': "تر آیت پورې", 'fa': "تا آیه", 'ur': "آیت تک", 'ar': "إلى الآية"},
    "repeat_range_clear": {'en': "Clear range", 'ps': "حد پاک کړه", 'fa': "پاک کردن بازه", 'ur': "رینج صاف کریں", 'ar': "مسح المجموعة"},
    // --- Round 3: sleep timer ---
    "sleep_timer": {'en': "Sleep timer", 'ps': "د خوب ټایمر", 'fa': "تایمر خواب", 'ur': "نیند کا ٹائمر", 'ar': "مؤقت النوم"},
    "sleep_off": {'en': "Off", 'ps': "بند", 'fa': "خاموش", 'ur': "بند", 'ar': "إيقاف"},
    "sleep_5": {'en': "5 minutes", 'ps': "5 دقیقې", 'fa': "5 دقیقه", 'ur': "5 منٹ", 'ar': "5 دقائق"},
    "sleep_10": {'en': "10 minutes", 'ps': "10 دقیقې", 'fa': "10 دقیقه", 'ur': "10 منٹ", 'ar': "10 دقائق"},
    "sleep_15": {'en': "15 minutes", 'ps': "15 دقیقې", 'fa': "15 دقیقه", 'ur': "15 منٹ", 'ar': "15 دقيقة"},
    "sleep_30": {'en': "30 minutes", 'ps': "30 دقیقې", 'fa': "30 دقیقه", 'ur': "30 منٹ", 'ar': "30 دقيقة"},
    "sleep_60": {'en': "60 minutes", 'ps': "60 دقیقې", 'fa': "60 دقیقه", 'ur': "60 منٹ", 'ar': "60 دقيقة"},
    "sleep_end_surah": {'en': "End of surah", 'ps': "د سورت پای", 'fa': "پایان سوره", 'ur': "سورت کے اختتام پر", 'ar': "نهاية السورة"},
    "sleep_timer_set": {'en': "Sleep timer set", 'ps': "د خوب ټایمر وټاکل شو", 'fa': "تایمر خواب تنظیم شد", 'ur': "نیند کا ٹائمر مقرر ہوگیا", 'ar': "تم ضبط مؤقت النوم"},
    // --- Round 3: onboarding ---
    "onboard_welcome": {'en': "Welcome to QUBA", 'ps': "قوبا ته ښه راغلاست", 'fa': "به قبا خوش آمدید", 'ur': "قوبا میں خوش آمدید", 'ar': "مرحباً بك في قُبا"},
    "onboard_welcome_body": {'en': "Your Quran, prayer times and Athan — all in one place, working fully offline.", 'ps': "ستاسو قرآن، د لمانځه وختونه او اذان — ټول په یو ځای کې، په بشپړ ډول له انټرنېټ پرته کار کوي.", 'fa': "قرآن، اوقات نماز و اذان شما — همه در یک جا، کاملاً آفلاین کار می‌کند.", 'ur': "آپ کا قرآن، نماز کے اوقات اور اذان — سب ایک جگہ، مکمل طور پر آف لائن کام کرتا ہے۔", 'ar': "قرآنك وأوقات الصلاة والأذان — كلها في مكان واحد، وتعمل دون إنترنت تماماً."},
    "onboard_language": {'en': "Choose your language", 'ps': "خپله ژبه وټاکئ", 'fa': "زبان خود را انتخاب کنید", 'ur': "اپنی زبان منتخب کریں", 'ar': "اختر لغتك"},
    "onboard_location": {'en': "Your location", 'ps': "ستاسو ځای", 'fa': "موقعیت شما", 'ur': "آپ کا مقام", 'ar': "موقعك"},
    "onboard_location_body": {'en': "QUBA uses your location only to calculate prayer times and the Qibla direction. You can change it later in Settings.", 'ps': "قوبا ستاسو ځای یوازې د لمانځه وختونو او قبلې لوري لپاره کاروي. وروسته یې په تنظیماتو کې بدلولی شئ.", 'fa': "قبا از موقعیت شما فقط برای محاسبهٔ اوقات نماز و جهت قبله استفاده می‌کند. بعداً می‌توانید آن را در تنظیمات تغییر دهید.", 'ur': "قوبا آپ کا مقام صرف نماز کے اوقات اور قبلہ کی سمت معلوم کرنے کے لیے استعمال کرتا ہے۔ آپ اسے بعد میں ترتیبات میں بدل سکتے ہیں۔", 'ar': "يستخدم قُبا موقعك فقط لحساب أوقات الصلاة واتجاه القبلة. يمكنك تغييره لاحقاً من الإعدادات."},
    "onboard_location_gps": {'en': "Use my location", 'ps': "زما ځای وکاروه", 'fa': "استفاده از موقعیت من", 'ur': "میرا مقام استعمال کریں", 'ar': "استخدم موقعي"},
    "onboard_location_default": {'en': "Use Kabul for now", 'ps': "اوس کابل وکاروه", 'fa': "فعلاً کابل", 'ur': "ابھی کابل استعمال کریں", 'ar': "استخدم كابول الآن"},
    "onboard_calc": {'en': "Prayer calculation", 'ps': "د لمانځه حساب", 'fa': "محاسبهٔ نماز", 'ur': "نماز کا حساب", 'ar': "حساب الصلاة"},
    "onboard_calc_body": {'en': "Choose how prayer times are calculated. The default works for Afghanistan and most of the world.", 'ps': "وټاکئ چې د لمانځه وختونه څنګه حساب شي. ډیفالټ د افغانستان او نړۍ ډېرو برخو لپاره کار کوي.", 'fa': "انتخاب کنید اوقات نماز چگونه محاسبه شود. پیش‌فرض برای افغانستان و بیشتر نقاط جهان مناسب است.", 'ur': "منتخب کریں کہ نماز کے اوقات کیسے حساب ہوں۔ پہلے سے طے شدہ افغانستان اور دنیا کے بیشتر حصوں کے لیے کام کرتا ہے۔", 'ar': "اختر طريقة حساب أوقات الصلاة. الافتراضي مناسب لأفغانستان ومعظم أنحاء العالم."},
    "onboard_athan": {'en': "Athan notifications", 'ps': "د اذان خبرتیاوې", 'fa': "اعلان‌های اذان", 'ur': "اذان کی اطلاعات", 'ar': "تنبيهات الأذان"},
    "onboard_athan_body": {'en': "QUBA can notify you at each prayer time. You can change this anytime in Settings.", 'ps': "قوبا کولی شي په هر لمانځه کې تاسو خبر کړي. دا هر وخت په تنظیماتو کې بدلولی شئ.", 'fa': "قبا می‌تواند در هر وقت نماز به شما اطلاع دهد. هر زمان می‌توانید این را در تنظیمات تغییر دهید.", 'ur': "قوبا ہر نماز کے وقت آپ کو اطلاع دے سکتا ہے۔ آپ اسے کسی بھی وقت ترتیبات میں بدل سکتے ہیں۔", 'ar': "يمكن لقُبا تنبيهك عند كل وقت صلاة. يمكنك تغيير ذلك في أي وقت من الإعدادات."},
    "onboard_athan_on": {'en': "Turn on Athan", 'ps': "اذان فعال کړه", 'fa': "روشن کردن اذان", 'ur': "اذان آن کریں", 'ar': "تفعيل الأذان"},
    "onboard_skip": {'en': "Skip", 'ps': "تېر شه", 'fa': "رد کردن", 'ur': "چھوڑیں", 'ar': "تخطي"},
    "onboard_next": {'en': "Next", 'ps': "بل", 'fa': "بعدی", 'ur': "آگے", 'ar': "التالي"},
    "onboard_done": {'en': "Start reading", 'ps': "لوستل پیل کړه", 'fa': "شروع خواندن", 'ur': "پڑھنا شروع کریں", 'ar': "ابدأ القراءة"},
    // --- Round 3: reading streak ---
    "day_streak": {'en': "Day streak", 'ps': "د ورځو لړۍ", 'fa': "رشتهٔ روزها", 'ur': "دنوں کی لڑی", 'ar': "سلسلة الأيام"},
    "streak_days": {'en': "{count} day streak", 'ps': "{count} ورځو لړۍ", 'fa': "رشتهٔ {count} روزه", 'ur': "{count} دنوں کی لڑی", 'ar': "سلسلة {count} أيام"},
    "read_today": {'en': "Read today", 'ps': "نن ولوله", 'fa': "امروز خوانده شد", 'ur': "آج پڑھا گیا", 'ar': "قُرئ اليوم"},
    // --- Round 3: Ramadan timetable ---
    "ramadan_timetable": {'en': "Ramadan timetable", 'ps': "د روژې مهالوېش", 'fa': "جدول رمضان", 'ur': "رمضان کا ٹائم ٹیبل", 'ar': "جدول رمضان"},
    "suhoor": {'en': "Suhoor", 'ps': "سحري", 'fa': "سحری", 'ur': "سحری", 'ar': "السحور"},
    "iftar": {'en': "Iftar", 'ps': "افطار", 'fa': "افطار", 'ur': "افطار", 'ar': "الإفطار"},
    "ramadan_day": {'en': "Ramadan {day}", 'ps': "روژه {day}", 'fa': "رمضان {day}", 'ur': "رمضان {day}", 'ar': "رمضان {day}"},
    "fasting_hours": {'en': "Fasting {hours}", 'ps': "روژه {hours}", 'fa': "روزه {hours}", 'ur': "روزہ {hours}", 'ar': "الصيام {hours}"},
    "ramadan_next": {'en': "Next Ramadan", 'ps': "راتلونکې روژه", 'fa': "رمضان آینده", 'ur': "اگلا رمضان", 'ar': "رمضان القادم"},
    // --- Round 3: per-verse downloads ---
    "downloading_verses": {'en': "Downloading verses…", 'ps': "آیتونه ډاونلوډېږي…", 'fa': "در حال دانلود آیات…", 'ur': "آیات ڈاؤن لوڈ ہو رہی ہیں…", 'ar': "جارٍ تنزيل الآيات…"},
    "download_verses": {'en': "Download verses", 'ps': "آیتونه ډاونلوډ کړه", 'fa': "دانلود آیات", 'ur': "آیات ڈاؤن لوڈ کریں", 'ar': "تنزيل الآيات"},
    "verses_downloaded": {'en': "Verses downloaded", 'ps': "آیتونه ډاونلوډ شول", 'fa': "آیات دانلود شد", 'ur': "آیات ڈاؤن لوڈ ہوگئیں", 'ar': "تم تنزيل الآيات"},
    "save": {'en': "Save", 'ps': "خوندي کړه", 'fa': "ذخیره", 'ur': "محفوظ کریں", 'ar': "حفظ"},
    "delete": {'en': "Delete", 'ps': "ړنګ کړه", 'fa': "حذف", 'ur': "حذف کریں", 'ar': "حذف"},
    "player_options": {'en': "Player options", 'ps': "د غږولو انتخابونه", 'fa': "گزینه‌های پخش", 'ur': "پلے کے اختیارات", 'ar': "خيارات التشغيل"},
  };

  /// The full dictionary (test-visible; also used by tools that audit coverage).
  static Map<String, Map<String, String>> get all => _strings;

  static bool isRtl(String lang) => lang != 'en';

  /// Returns the string for [lang], falling back to English, then to the key itself.
  static String get(String lang, String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[lang] ?? entry['en'] ?? key;
  }

  /// Like [get], then replaces `{name}` placeholders with [args] values.
  /// A placeholder with no matching arg is left as-is.
  static String format(String lang, String key,
      [Map<String, Object> args = const {}]) {
    var value = get(lang, key);
    for (final e in args.entries) {
      value = value.replaceAll('{${e.key}}', e.value.toString());
    }
    return value;
  }
}

/// Shortcut: translate with the current app language.
String tr(String key) => QubaStrings.get(appState.lang, key);

/// Shortcut: translate with `{name}` placeholders replaced from [args].
/// A placeholder with no matching arg is left as-is.
String trf(String key, [Map<String, Object> args = const {}]) =>
    QubaStrings.format(appState.lang, key, args);

/// Display translation for a stored English prayer name ('Fajr', 'Sunrise',
/// 'Dhuhr', 'Asr', 'Maghrib', 'Isha'). Unknown names pass through unchanged.
String trPrayer(String englishName) {
  switch (englishName) {
    case 'Fajr':
      return tr('prayer_fajr');
    case 'Sunrise':
      return tr('prayer_sunrise');
    case 'Dhuhr':
      return tr('prayer_dhuhr');
    case 'Asr':
      return tr('prayer_asr');
    case 'Maghrib':
      return tr('prayer_maghrib');
    case 'Isha':
      return tr('prayer_isha');
    default:
      return englishName;
  }
}

/// Display translation for a stored location label. Only the two known
/// stored values are translated; anything else passes through unchanged.
String trLocation(String stored) {
  switch (stored) {
    case 'Kabul (default)':
      return tr('loc_kabul_default');
    case 'My location (GPS)':
      return tr('loc_my_gps');
    default:
      return stored;
  }
}
