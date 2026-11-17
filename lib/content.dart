import 'data.dart'; // QuranRepository

/// Curated Islamic content for QUBA (ported from the native app's
/// ContentData.java — same entries, same order, same wording).
///
/// CONTENT RULE (from the plan): every entry carries a source
/// reference. Quran-sourced duas load their Arabic from the verified
/// bundled Quran text at runtime (see [Dua.quranRef] and [duaArabic]).
/// Hadith Arabic is included only for the famous, short wordings the
/// author is confident about; nothing is invented.

class AllahName {
  const AllahName(this.arabic, this.transliteration, this.meaning);
  final String arabic, transliteration, meaning;
}

/// The 99 Names of Allah. Order follows the well-known list from
/// Jami' at-Tirmidhi 3507, with "Allah" itself as the first name
/// (the standard counting).
const List<AllahName> names99 = [
  AllahName("اللَّهُ", "Allah", "The God — the only One worthy of worship"),
  AllahName("الرَّحْمَنُ", "Ar-Rahman", "The Most Merciful"),
  AllahName("الرَّحِيمُ", "Ar-Rahim", "The Most Kind"),
  AllahName("الْمَلِكُ", "Al-Malik", "The King, the Sovereign"),
  AllahName("الْقُدُّوسُ", "Al-Quddus", "The Most Holy"),
  AllahName("السَّلَامُ", "As-Salam", "The Source of Peace"),
  AllahName("الْمُؤْمِنُ", "Al-Mu'min", "The Giver of Faith and Safety"),
  AllahName("الْمُهَيْمِنُ", "Al-Muhaymin", "The Guardian, the Overseer"),
  AllahName("الْعَزِيزُ", "Al-Aziz", "The Almighty"),
  AllahName("الْجَبَّارُ", "Al-Jabbar", "The Irresistible, the Restorer"),
  AllahName("الْمُتَكَبِّرُ", "Al-Mutakabbir", "The Supreme, the Majestic"),
  AllahName("الْخَالِقُ", "Al-Khaliq", "The Creator"),
  AllahName("الْبَارِئُ", "Al-Bari", "The Originator"),
  AllahName("الْمُصَوِّرُ", "Al-Musawwir", "The Fashioner of Forms"),
  AllahName("الْغَفَّارُ", "Al-Ghaffar", "The Great Forgiver"),
  AllahName("الْقَهَّارُ", "Al-Qahhar", "The Irresistible Subduer"),
  AllahName("الْوَهَّابُ", "Al-Wahhab", "The Supreme Bestower"),
  AllahName("الرَّزَّاقُ", "Ar-Razzaq", "The Provider"),
  AllahName("الْفَتَّاحُ", "Al-Fattah", "The Opener, the Judge"),
  AllahName("الْعَلِيمُ", "Al-Alim", "The All-Knowing"),
  AllahName("الْقَابِضُ", "Al-Qabid", "The Withholder"),
  AllahName("الْبَاسِطُ", "Al-Basit", "The Extender"),
  AllahName("الْخَافِضُ", "Al-Khafid", "The Abaser"),
  AllahName("الرَّافِعُ", "Ar-Rafi", "The Exalter"),
  AllahName("الْمُعِزُّ", "Al-Mu'izz", "The Giver of Honour"),
  AllahName("الْمُذِلُّ", "Al-Mudhill", "The Giver of Dishonour"),
  AllahName("السَّمِيعُ", "As-Sami", "The All-Hearing"),
  AllahName("الْبَصِيرُ", "Al-Basir", "The All-Seeing"),
  AllahName("الْحَكَمُ", "Al-Hakam", "The Impartial Judge"),
  AllahName("الْعَدْلُ", "Al-Adl", "The Utterly Just"),
  AllahName("اللَّطِيفُ", "Al-Latif", "The Subtle, the Gentle"),
  AllahName("الْخَبِيرُ", "Al-Khabir", "The All-Aware"),
  AllahName("الْحَلِيمُ", "Al-Halim", "The Forbearing"),
  AllahName("الْعَظِيمُ", "Al-Azim", "The Magnificent"),
  AllahName("الْغَفُورُ", "Al-Ghafur", "The All-Forgiving"),
  AllahName("الشَّكُورُ", "Ash-Shakur", "The Most Appreciative"),
  AllahName("الْعَلِيُّ", "Al-Aliyy", "The Most High"),
  AllahName("الْكَبِيرُ", "Al-Kabir", "The Most Great"),
  AllahName("الْحَفِيظُ", "Al-Hafiz", "The Preserver"),
  AllahName("الْمُقِيتُ", "Al-Muqit", "The Sustainer"),
  AllahName("الْحَسِيبُ", "Al-Hasib", "The Reckoner"),
  AllahName("الْجَلِيلُ", "Al-Jalil", "The Majestic One"),
  AllahName("الْكَرِيمُ", "Al-Karim", "The Most Generous"),
  AllahName("الرَّقِيبُ", "Ar-Raqib", "The Watchful"),
  AllahName("الْمُجِيبُ", "Al-Mujib", "The Responsive"),
  AllahName("الْوَاسِعُ", "Al-Wasi", "The All-Encompassing"),
  AllahName("الْحَكِيمُ", "Al-Hakim", "The All-Wise"),
  AllahName("الْوَدُودُ", "Al-Wadud", "The Most Loving"),
  AllahName("الْمَجِيدُ", "Al-Majid", "The Glorious"),
  AllahName("الْبَاعِثُ", "Al-Ba'ith", "The Resurrector"),
  AllahName("الشَّهِيدُ", "Ash-Shahid", "The Witness"),
  AllahName("الْحَقُّ", "Al-Haqq", "The Absolute Truth"),
  AllahName("الْوَكِيلُ", "Al-Wakil", "The Trustee, the Disposer"),
  AllahName("الْقَوِيُّ", "Al-Qawiyy", "The All-Strong"),
  AllahName("الْمَتِينُ", "Al-Matin", "The Firm, the Steadfast"),
  AllahName("الْوَلِيُّ", "Al-Waliyy", "The Protecting Friend"),
  AllahName("الْحَمِيدُ", "Al-Hamid", "The Praiseworthy"),
  AllahName("الْمُحْصِي", "Al-Muhsi", "The Counter of All Things"),
  AllahName("الْمُبْدِئُ", "Al-Mubdi", "The Originator"),
  AllahName("الْمُعِيدُ", "Al-Mu'id", "The Restorer"),
  AllahName("الْمُحْيِي", "Al-Muhyi", "The Giver of Life"),
  AllahName("الْمُمِيتُ", "Al-Mumit", "The Bringer of Death"),
  AllahName("الْحَيُّ", "Al-Hayy", "The Ever-Living"),
  AllahName("الْقَيُّومُ", "Al-Qayyum", "The Self-Subsisting Sustainer"),
  AllahName("الْوَاجِدُ", "Al-Wajid", "The Perceiver, the Finder"),
  AllahName("الْمَاجِدُ", "Al-Maajid", "The Illustrious, the Noble"),
  AllahName("الْوَاحِدُ", "Al-Wahid", "The One"),
  AllahName("الصَّمَدُ", "As-Samad", "The Eternal Refuge"),
  AllahName("الْقَادِرُ", "Al-Qadir", "The Capable"),
  AllahName("الْمُقْتَدِرُ", "Al-Muqtadir", "The Powerful"),
  AllahName("الْمُقَدِّمُ", "Al-Muqaddim", "The Promoter"),
  AllahName("الْمُؤَخِّرُ", "Al-Mu'akhkhir", "The Delayer"),
  AllahName("الْأَوَّلُ", "Al-Awwal", "The First"),
  AllahName("الْآخِرُ", "Al-Akhir", "The Last"),
  AllahName("الظَّاهِرُ", "Az-Zahir", "The Manifest"),
  AllahName("الْبَاطِنُ", "Al-Batin", "The Hidden"),
  AllahName("الْوَالِي", "Al-Wali", "The Governor"),
  AllahName("الْمُتَعَالِي", "Al-Muta'ali", "The Self-Exalted"),
  AllahName("الْبَرُّ", "Al-Barr", "The Source of Goodness"),
  AllahName("التَّوَّابُ", "At-Tawwab", "The Acceptor of Repentance"),
  AllahName("الْمُنْتَقِمُ", "Al-Muntaqim", "The Avenger"),
  AllahName("الْعَفُوُّ", "Al-Afuww", "The Pardoner"),
  AllahName("الرَّؤُوفُ", "Ar-Ra'uf", "The Most Kind"),
  AllahName("مَالِكُ الْمُلْكِ", "Malik-ul-Mulk", "Master of the Kingdom"),
  AllahName("ذُو الْجَلَالِ وَالْإِكْرَامِ", "Dhul-Jalali-wal-Ikram", "Lord of Majesty and Honour"),
  AllahName("الْمُقْسِطُ", "Al-Muqsit", "The Equitable"),
  AllahName("الْجَامِعُ", "Al-Jami", "The Gatherer"),
  AllahName("الْغَنِيُّ", "Al-Ghaniyy", "The Self-Sufficient"),
  AllahName("الْمُغْنِي", "Al-Mughni", "The Enricher"),
  AllahName("الْمَانِعُ", "Al-Mani", "The Preventer"),
  AllahName("الضَّارُّ", "Ad-Darr", "The Distresser"),
  AllahName("النَّافِعُ", "An-Nafi", "The Benefactor"),
  AllahName("النُّورُ", "An-Nur", "The Light"),
  AllahName("الْهَادِي", "Al-Hadi", "The Guide"),
  AllahName("الْبَدِيعُ", "Al-Badi", "The Incomparable Originator"),
  AllahName("الْبَاقِي", "Al-Baqi", "The Everlasting"),
  AllahName("الْوَارِثُ", "Al-Warith", "The Inheritor"),
  AllahName("الرَّشِيدُ", "Ar-Rashid", "The Guide to Rightness"),
  AllahName("الصَّبُورُ", "As-Sabur", "The Patient"),
];

class Dua {
  const Dua({required this.title, required this.category, required this.arabic, required this.transliteration, required this.english, required this.source, this.quranRef});
  final String title, category, arabic, transliteration, english, source;
  final String? quranRef; // "2:255" single ayah, "112,113,114" whole surahs (comma list)
}

const List<String> duaCategories = ["All", "Morning & Evening", "Sleep", "Home", "Eating", "Family", "Forgiveness", "General"];

const List<Dua> duas = [
  Dua(title: "Ayat al-Kursi", category: "Morning & Evening", arabic: "", transliteration: "Allahu la ilaha illa Huwal-Hayyul-Qayyum…", english: "The Verse of the Throne — the greatest verse of the Quran; recited morning and evening and after every prayer.", source: "Quran 2:255", quranRef: "2:255"),
  // NOTE: Java had quranRef "112" here, but this dua covers surahs
  // 112, 113 and 114 — the Dart ref lists all three so duaArabic
  // returns the full text of all three surahs.
  Dua(title: "Al-Ikhlas, Al-Falaq, An-Nas", category: "Morning & Evening", arabic: "", transliteration: "Qul huwallahu ahad… (Surah 112), Qul a'udhu bi rabbil-falaq… (113), Qul a'udhu bi rabbin-nas… (114)", english: "The three short surahs of protection, recited three times morning and evening.", source: "Quran 112, 113, 114", quranRef: "112,113,114"),
  Dua(title: "Glory be to Allah and praise Him", category: "Morning & Evening", arabic: "سُبْحَانَ اللهِ وَبِحَمْدِهِ", transliteration: "SubhanAllahi wa bihamdihi", english: "Glory be to Allah and praise be to Him. (Recite 100 times morning and evening.)", source: "Sahih al-Bukhari 6405; Sahih Muslim 2691"),
  Dua(title: "None has the right to be worshipped but Allah", category: "Morning & Evening", arabic: "لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", transliteration: "La ilaha illallahu wahdahu la sharika lah, lahul-mulku wa lahul-hamdu wa huwa 'ala kulli shay'in qadir", english: "None has the right to be worshipped but Allah alone, without partner. To Him belongs the kingdom and all praise, and He has power over all things. (Recite 100 times a day.)", source: "Sahih al-Bukhari 3293; Sahih Muslim 2691"),
  Dua(title: "Protection from all harm", category: "Morning & Evening", arabic: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", transliteration: "Bismillahil-ladhi la yadurru ma'a-smihi shay'un fil-ardi wa la fis-sama'i wa huwas-sami'ul-'alim", english: "In the name of Allah, with whose name nothing on earth or in heaven can cause harm, and He is the All-Hearing, the All-Knowing. (Recite 3 times.)", source: "Sunan Abi Dawud 5088; Jami' at-Tirmidhi 3388; Hisnul Muslim 86"),
  Dua(title: "I seek refuge in the perfect words of Allah", category: "Morning & Evening", arabic: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ", transliteration: "A'udhu bi kalimatillahit-tammati min sharri ma khalaq", english: "I seek refuge in the perfect words of Allah from the evil of what He has created. (Recite 3 times.)", source: "Sahih Muslim 2708"),
  Dua(title: "Allah is enough for me", category: "Morning & Evening", arabic: "", transliteration: "Hasbiyallahu la ilaha illa Huwa, 'alayhi tawakkaltu wa Huwa Rabbul-'arshil-'azim", english: "Allah is enough for me; there is no god but Him. In Him I put my trust, and He is the Lord of the Mighty Throne. (Recite 7 times.)", source: "Quran 9:129", quranRef: "9:129"),
  Dua(title: "I am pleased with Allah as my Lord", category: "Morning & Evening", arabic: "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا", transliteration: "Raditu billahi rabban, wa bil-islami dinan, wa bi Muhammadin sallallahu 'alayhi wa sallam nabiyyan", english: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (peace be upon him) as my Prophet. (Recite 3 times.)", source: "Sunan Abi Dawud 5072; Jami' at-Tirmidhi 3389"),
  Dua(title: "Glory be to Allah, as many times as His creation", category: "Morning & Evening", arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ", transliteration: "SubhanAllahi wa bihamdihi, 'adada khalqihi, wa rida nafsihi, wa zinata 'arshihi, wa midada kalimatihi", english: "Glory be to Allah and praise be to Him, as many times as the number of His creation, as much as pleases Him, as much as the weight of His Throne, and as much as the ink of His words. (Recite 3 times.)", source: "Sahih Muslim 2726"),
  Dua(title: "Before sleeping", category: "Sleep", arabic: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا", transliteration: "Bismika Allahumma amutu wa ahya", english: "In Your name, O Allah, I die and I live.", source: "Sahih al-Bukhari 6314"),
  Dua(title: "Protect me from Your punishment", category: "Sleep", arabic: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ", transliteration: "Allahumma qini 'adhabaka yawma tab'athu 'ibadak", english: "O Allah, protect me from Your punishment on the day You resurrect Your servants.", source: "Sunan Abi Dawud 5045"),
  Dua(title: "On waking up", category: "Sleep", arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ", transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur", english: "All praise is for Allah who gave us life after He caused us to die, and to Him is the resurrection.", source: "Sahih al-Bukhari 6314"),
  Dua(title: "Entering the home", category: "Home", arabic: "بِسْمِ اللَّهِ وَلَجْنَا، وَبِسْمِ اللَّهِ خَرَجْنَا، وَعَلَى رَبِّنَا تَوَكَّلْنَا", transliteration: "Bismillahi walajna, wa bismillahi kharajna, wa 'ala Rabbina tawakkalna", english: "In the name of Allah we enter, in the name of Allah we leave, and upon our Lord we place our trust.", source: "Sunan Abi Dawud 5096; Hisnul Muslim 18"),
  Dua(title: "Leaving the home", category: "Home", arabic: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", transliteration: "Bismillahi tawakkaltu 'alallah, la hawla wa la quwwata illa billah", english: "In the name of Allah, I place my trust in Allah; there is no might nor power except with Allah.", source: "Sunan Abi Dawud 5095; Jami' at-Tirmidhi 3426; Hisnul Muslim 16"),
  Dua(title: "Before eating", category: "Eating", arabic: "بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ", transliteration: "Bismillahi wa 'ala barakatillah", english: "In the name of Allah, and with the blessing of Allah.", source: "Hisnul Muslim 66 (from Abu Dawud, Ibn Majah)"),
  Dua(title: "After eating", category: "Eating", arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ", transliteration: "Alhamdu lillahil-ladhi at'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah", english: "All praise is for Allah who fed me this and provided it for me, without any power or strength from me.", source: "Sunan Abi Dawud 4023; Jami' at-Tirmidhi 3458; Sunan Ibn Majah 3285"),
  Dua(title: "For my parents", category: "Family", arabic: "", transliteration: "Rabbir-hamhuma kama rabbayani saghira", english: "My Lord, have mercy on them (my parents) as they raised me when I was small.", source: "Quran 17:24", quranRef: "17:24"),
  Dua(title: "For our family", category: "Family", arabic: "", transliteration: "Rabbana hab lana min azwajina wa dhurriyyatina qurrata a'yunin waj'alna lil-muttaqina imama", english: "Our Lord, grant us from our spouses and our offspring comfort to our eyes, and make us leaders of the righteous.", source: "Quran 25:74", quranRef: "25:74"),
  Dua(title: "We have wronged ourselves", category: "Forgiveness", arabic: "", transliteration: "Rabbana zalamna anfusana wa in lam taghfir lana wa tarhamna lanakunanna minal-khasirin", english: "Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy on us, we will surely be among the losers.", source: "Quran 7:23", quranRef: "7:23"),
  Dua(title: "Sayyidul Istighfar — the master of seeking forgiveness", category: "Forgiveness", arabic: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ", transliteration: "Allahumma anta Rabbi la ilaha illa anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu, a'udhu bika min sharri ma sana'tu, abu'u laka bini'matika 'alayya, wa abu'u laka bidhanbi faghfir li fa'innahu la yaghfiru adh-dhunuba illa anta", english: "O Allah, You are my Lord; there is no god but You. You created me and I am Your servant, and I keep Your covenant and promise as best I can. I seek refuge in You from the evil of what I have done. I acknowledge Your blessing upon me, and I acknowledge my sin — so forgive me, for no one forgives sins but You.", source: "Sahih al-Bukhari 6306"),
  Dua(title: "I ask You for beneficial knowledge", category: "General", arabic: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا، وَرِزْقًا طَيِّبًا، وَعَمَلًا مُتَقَبَّلًا", transliteration: "Allahumma inni as'aluka 'ilman nafi'an, wa rizqan tayyiban, wa 'amalan mutaqabbala", english: "O Allah, I ask You for beneficial knowledge, good provision, and accepted deeds.", source: "Sunan Ibn Majah 925"),
  Dua(title: "Make my heart firm", category: "General", arabic: "يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ", transliteration: "Ya muqallibal-qulub, thabbit qalbi 'ala dinik", english: "O Turner of hearts, make my heart firm upon Your religion.", source: "Jami' at-Tirmidhi 3522"),
  Dua(title: "Help me to remember You", category: "General", arabic: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", transliteration: "Allahumma a'inni 'ala dhikrika, wa shukrika, wa husni 'ibadatik", english: "O Allah, help me to remember You, to thank You, and to worship You in the best way.", source: "Sunan Abi Dawud 1522"),
  Dua(title: "Our Lord, give us good in this world", category: "General", arabic: "", transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar", english: "Our Lord, give us good in this world and good in the Hereafter, and protect us from the punishment of the Fire.", source: "Quran 2:201", quranRef: "2:201"),
  Dua(title: "My Lord, increase me in knowledge", category: "General", arabic: "", transliteration: "Rabbi zidni 'ilma", english: "My Lord, increase me in knowledge.", source: "Quran 20:114", quranRef: "20:114"),
  Dua(title: "There is no might nor power except with Allah", category: "General", arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ الْعَلِيِّ الْعَظِيمِ", transliteration: "La hawla wa la quwwata illa billahil-'aliyyil-'azim", english: "There is no might nor power except with Allah, the Most High, the Most Great.", source: "Sahih al-Bukhari 4205; Sahih Muslim 2704"),
];

class Hadith {
  const Hadith(this.arabic, this.english, this.reference);
  final String arabic, english, reference;
}

/// Forty Nawawi — famous short wordings only.
const List<Hadith> hadiths = [
  Hadith("إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى", "Actions are but by intentions, and every person shall have only what they intended.", "Forty Nawawi 1 · Sahih al-Bukhari 1; Sahih Muslim 1907"),
  Hadith("بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ: شَهَادَةِ أَنْ لَا إِلَهَ إِلَّا اللَّهُ وَأَنَّ مُحَمَّدًا رَسُولُ اللَّهِ، وَإِقَامِ الصَّلَاةِ، وَإِيتَاءِ الزَّكَاةِ، وَحَجِّ الْبَيْتِ، وَصَوْمِ رَمَضَانَ", "Islam is built upon five: testifying that there is no god but Allah and that Muhammad is the Messenger of Allah, establishing prayer, giving zakat, pilgrimage to the House, and fasting Ramadan.", "Forty Nawawi 3 · Sahih al-Bukhari 8; Sahih Muslim 16"),
  Hadith("مَنْ أَحْدَثَ فِي أَمْرِنَا هَذَا مَا لَيْسَ مِنْهُ فَهُوَ رَدٌّ", "Whoever introduces into this matter of ours something that is not part of it, it will be rejected.", "Forty Nawawi 5 · Sahih al-Bukhari 2697; Sahih Muslim 1718"),
  Hadith("إِنَّ الْحَلَالَ بَيِّنٌ وَإِنَّ الْحَرَامَ بَيِّنٌ، وَبَيْنَهُمَا أُمُورٌ مُشْتَبِهَاتٌ لَا يَعْلَمُهُنَّ كَثِيرٌ مِنَ النَّاسِ، فَمَنِ اتَّقَى الشُّبُهَاتِ اسْتَبْرَأَ لِدِينِهِ وَعِرْضِهِ، وَمَنْ وَقَعَ فِي الشُّبُهَاتِ وَقَعَ فِي الْحَرَامِ", "The lawful is clear and the unlawful is clear, and between them are doubtful matters that many people do not know. Whoever avoids the doubtful has protected his religion and his honour; whoever falls into the doubtful falls into the unlawful.", "Forty Nawawi 6 · Sahih al-Bukhari 52; Sahih Muslim 1599 (excerpt)"),
  Hadith("الدِّينُ النَّصِيحَةُ", "Religion is sincere advice. (To Allah, His Book, His Messenger, the leaders of the Muslims and their common folk.)", "Forty Nawawi 7 · Sahih Muslim 55"),
  Hadith("إِنَّ اللَّهَ طَيِّبٌ لَا يَقْبَلُ إِلَّا طَيِّبًا", "Allah is Pure and accepts only that which is pure.", "Forty Nawawi 10 · Sahih Muslim 1015"),
  Hadith("مِنْ حُسْنِ إِسْلَامِ الْمَرْءِ تَرْكُهُ مَا لَا يَعْنِيهِ", "Part of the excellence of a person's Islam is leaving what does not concern him.", "Forty Nawawi 12 · Jami' at-Tirmidhi 2317"),
  Hadith("لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ", "None of you truly believes until he loves for his brother what he loves for himself.", "Forty Nawawi 13 · Sahih al-Bukhari 13; Sahih Muslim 45"),
  Hadith("مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ، وَمَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيُكْرِمْ جَارَهُ، وَمَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيُكْرِمْ ضَيْفَهُ", "Whoever believes in Allah and the Last Day, let him speak good or remain silent; let him honour his neighbour; let him honour his guest.", "Forty Nawawi 15 · Sahih al-Bukhari 6018; Sahih Muslim 47"),
  Hadith("اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ", "Fear Allah wherever you are, follow a bad deed with a good deed and it will wipe it out, and treat people with good character.", "Forty Nawawi 18 · Jami' at-Tirmidhi 1987"),
  Hadith("احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ", "Be mindful of Allah and He will protect you; be mindful of Allah and you will find Him before you.", "Forty Nawawi 19 · Jami' at-Tirmidhi 2516 (excerpt)"),
  Hadith("قُلْ آمَنْتُ بِاللَّهِ ثُمَّ اسْتَقِمْ", "Say: I believe in Allah — then remain steadfast.", "Forty Nawawi 21 · Sahih Muslim 38"),
  Hadith("الطُّهُورُ شَطْرُ الْإِيمَانِ، وَالْحَمْدُ لِلَّهِ تَمْلَأُ الْمِيزَانَ، وَسُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ تَمْلَآنِ مَا بَيْنَ السَّمَاوَاتِ وَالْأَرْضِ", "Purity is half of faith, 'Alhamdulillah' fills the scale, and 'SubhanAllah' and 'Alhamdulillah' fill what is between the heavens and the earth.", "Forty Nawawi 23 · Sahih Muslim 223 (excerpt)"),
  Hadith("يَا عِبَادِي إِنِّي حَرَّمْتُ الظُّلْمَ عَلَى نَفْسِي وَجَعَلْتُهُ بَيْنَكُمْ مُحَرَّمًا فَلَا تَظَالَمُوا", "O My servants, I have forbidden oppression for Myself and I have made it forbidden among you — so do not oppress one another.", "Forty Nawawi 24 · Sahih Muslim 2577 (excerpt, hadith qudsi)"),
  Hadith("مَنْ رَأَى مِنْكُمْ مُنْكَرًا فَلْيُغَيِّرْهُ بِيَدِهِ، فَإِنْ لَمْ يَسْتَطِعْ فَبِلِسَانِهِ، فَإِنْ لَمْ يَسْتَطِعْ فَبِقَلْبِهِ، وَذَلِكَ أَضْعَفُ الْإِيمَانِ", "Whoever among you sees an evil, let him change it with his hand; if he cannot, then with his tongue; if he cannot, then with his heart — and that is the weakest of faith.", "Forty Nawawi 34 · Sahih Muslim 49"),
  Hadith("لَا تَحَاسَدُوا، وَلَا تَنَاجَشُوا، وَلَا تَبَاغَضُوا، وَلَا تَدَابَرُوا، وَلَا يَبِعْ بَعْضُكُمْ عَلَى بَيْعِ بَعْضٍ، وَكُونُوا عِبَادَ اللَّهِ إِخْوَانًا", "Do not envy one another, do not outbid one another, do not hate one another, do not turn away from one another, and do not undercut one another in trade. Be servants of Allah, brothers.", "Forty Nawawi 35 · Sahih Muslim 2564 (excerpt)"),
  Hadith("كُنْ فِي الدُّنْيَا كَأَنَّكَ غَرِيبٌ أَوْ عَابِرُ سَبِيلٍ", "Be in this world as though you were a stranger or a traveller passing through.", "Forty Nawawi 40 · Sahih al-Bukhari 6416"),
];

/// Daily verse rotation: [surah, ayah] references into the bundled Quran.
const List<List<int>> dailyVerses = [
  [2, 152],
  [2, 186],
  [2, 255],
  [3, 139],
  [13, 28],
  [39, 53],
  [65, 3],
  [94, 6],
  [2, 153],
  [29, 45],
  [3, 8],
  [93, 4],
  [2, 286],
  [55, 60],
  [1, 5],
];

/// Index into a rotating list for a given day (day-of-year based).
int dayIndex(int size, DateTime now) {
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  return dayOfYear % size;
}

/// Resolves a dua's Arabic text: if quranRef is set, load from the
/// verified bundled Quran text (single ayah "S:A", or whole surahs
/// "S1,S2" joined with spaces); otherwise return dua.arabic.
/// Falls back to dua.arabic if the Quran bundle is not loaded yet or
/// a reference is out of range.
String duaArabic(Dua dua) {
  final ref = dua.quranRef;
  if (ref == null) return dua.arabic;
  try {
    final repo = QuranRepository.instance;
    if (!repo.loaded) return dua.arabic;
    if (ref.contains(':')) {
      final parts = ref.split(':');
      final surah = repo.surah(int.parse(parts[0]));
      return surah.ayahs[int.parse(parts[1]) - 1].arabic;
    }
    final surahTexts = <String>[];
    for (final n in ref.split(',')) {
      final surah = repo.surah(int.parse(n.trim()));
      surahTexts.add(surah.ayahs.map((a) => a.arabic).join(' '));
    }
    return surahTexts.join(' ');
  } catch (_) {
    return dua.arabic;
  }
}
