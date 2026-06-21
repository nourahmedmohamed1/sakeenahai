import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static String currentLang = 'ar'; // اللغة الافتراضية

  // خريطة الترجمة الشاملة لكل نصوص التطبيق والرسائل الصوتية
  static final Map<String, Map<String, String>> translations = {
    // شريط التنقل السفلي والعناوين
    'app_title': {
      'ar': 'سَكينة AI — المساعد الذكي للحاج',
      'en': 'Sakeenah AI — Smart Hajj Advisor',
      'ur': 'سکینہ AI — سمارٹ حج ایڈوائزر',
      'bn': 'সাকিনাহ AI — স্মার্ট হজ উপদেষ্টা',
      'tr': 'Sakeenah AI — Akıllı Hac Danışmanı'
    },
    'tab_home': {
      'ar': 'الرئيسية',
      'en': 'Home',
      'ur': 'ہوم',
      'bn': 'হোম',
      'tr': 'Ana Sayfa'
    },
    'tab_tawaf': {
      'ar': 'الطواف والسعي',
      'en': 'Tawaf & Sa\'ee',
      'ur': 'طواف و سعی',
      'bn': 'তওয়াফ ও সাঈ',
      'tr': 'Tavaf & Sa\'y'
    },
    'tab_map': {
      'ar': 'المسار الآمن',
      'en': 'Safe Route',
      'ur': 'محفوظ راستہ',
      'bn': 'নিরাপদ রুট',
      'tr': 'Güvenli Rota'
    },
    'tab_emergency': {
      'ar': 'نداء الطوارئ',
      'en': 'Emergency SOS',
      'ur': 'ہنگامی امداد',
      'bn': 'জরুরী এসওএস',
      'tr': 'Acil Durum SOS'
    },

    // شاشة المسار الآمن والـ GPS
    'loc_loading': {
      'ar': 'جاري تحديد موقعك...',
      'en': 'Locating you...',
      'ur': 'آپ کا مقام معلوم کیا جا رہا ہے...',
      'bn': 'আপনার অবস্থান চিহ্নিত করা হচ্ছে...',
      'tr': 'Konumunuz belirleniyor...'
    },
    'loc_perm_denied': {
      'ar': 'يرجى تفعيل صلاحية الموقع من الإعدادات.',
      'en': 'Please enable location permission from settings.',
      'ur': 'براہ کرم سیٹنگز سے لوکیشن کی اجازت فعال کریں۔',
      'bn': 'অনুগ্রহ করে সেটিংস থেকে লোকেশন পারমিশন চালু করুন।',
      'tr': 'Lütfen ayarlardan konum iznini etkinleştirin.'
    },
    'no_points_type': {
      'ar': 'لا توجد نقاط من هذا النوع.',
      'en': 'No points found for this category.',
      'ur': 'اس زمرے کے لیے کوئی مقامات نہیں ملے۔',
      'bn': 'এই বিভাগে কোনো স্থান পাওয়া যায়নি।',
      'tr': 'Bu kategori için nokta bulunamadı.'
    },
    'nearest_point': {
      'ar': 'أقرب نقطة: ',
      'en': 'Nearest point: ',
      'ur': 'قریب ترین مقام: ',
      'bn': 'নিকটবর্তী স্থান: ',
      'tr': 'En yakın nokta: '
    },
    'distance': {
      'ar': 'المسافة: ',
      'en': 'Distance: ',
      'ur': 'فاصلہ: ',
      'bn': 'দূরত্ব: ',
      'tr': 'Mesafe: '
    },
    'km': {'ar': 'كم', 'en': 'km', 'ur': 'کلومیٹر', 'bn': 'কিমি', 'tr': 'km'},
    'meter': {
      'ar': 'متر',
      'en': 'meters',
      'ur': 'میٹر',
      'bn': 'মিটার',
      'tr': 'metre'
    },

    // الفلاتر ونقاط الخدمات
    'filter_all': {
      'ar': 'الكل',
      'en': 'All',
      'ur': 'سب',
      'bn': 'সব',
      'tr': 'Hepsi'
    },
    'filter_hospital': {
      'ar': 'مستشفى',
      'en': 'Hospital',
      'ur': 'ہسپتال',
      'bn': 'হাসপাতাল',
      'tr': 'Hastane'
    },
    'filter_ambulance': {
      'ar': 'إسعاف',
      'en': 'Ambulance',
      'ur': 'ایمبولینس',
      'bn': 'অ্যাম্বুলেন্স',
      'tr': 'Ambulans'
    },
    'filter_water': {
      'ar': 'مياه',
      'en': 'Water',
      'ur': 'پانی',
      'bn': 'পানি',
      'tr': 'Su'
    },
    'filter_shade': {
      'ar': 'ظل',
      'en': 'Shade',
      'ur': 'سایہ',
      'bn': 'ছায়া',
      'tr': 'Gölgelik'
    },

    // شاشة الملف الطبي
    'med_title': {
      'ar': 'الملف الطبي للرعاية',
      'en': 'Medical Care Profile',
      'ur': 'طبی معلومات',
      'bn': 'চিকিৎসা প্রোফাইল',
      'tr': 'Tıbbi Profil'
    },
    'med_name': {
      'ar': 'الاسم الكامل',
      'en': 'Full Name',
      'ur': 'پورا نام',
      'bn': 'পূর্ণ নাম',
      'tr': 'Adı Soyadı'
    },
    'med_blood': {
      'ar': 'فصيلة الدم',
      'en': 'Blood Type',
      'ur': 'بلڈ گروپ',
      'bn': 'রক্তের গ্রুপ',
      'tr': 'Kan Grubu'
    },
    'med_id': {
      'ar': 'الرقم القومي / جواز السفر',
      'en': 'National ID / Passport',
      'ur': 'قومی شناختی کارڈ / پاسپورٹ',
      'bn': 'জাতীয় পরিচয়পত্র / পাসপোর্ট',
      'tr': 'T.C. No / Pasaport'
    },
    'med_address': {
      'ar': 'عنوان السكن في مكة',
      'en': 'Makkah Residence Address',
      'ur': 'مکہ میں رہائش کا پتہ',
      'bn': 'মক্কার আবাসনের ঠিকানা',
      'tr': 'Mekke Konaklama Adresi'
    },
    'med_phone': {
      'ar': 'رقم تواصل للطوارئ',
      'en': 'Emergency Contact Number',
      'ur': 'ہنگامی رابطہ نمبر',
      'bn': 'জরুরী যোগাযোগ নম্বর',
      'tr': 'Acil Durum İletişim Numarası'
    },
    'med_chronic': {
      'ar': 'أمراض مزمنة (سكر/ضغط)',
      'en': 'Chronic Diseases (Diabetes/Blood Pressure)',
      'ur': 'دائمہ بیماریاں (ذیابیطس/بلڈ پریشر)',
      'bn': 'দীর্ঘস্থায়ী রোগ (ডায়াবেটিস/রক্তচাপ)',
      'tr': 'Kronik Hastalıklar (Şeker/Tansiyon)'
    },
    'med_notes': {
      'ar': 'ملاحظات هامة للسلامة',
      'en': 'Important Safety Notes',
      'ur': 'اہم حفاظتی نوٹ',
      'bn': 'গুরুত্বপূর্ণ নিরাপত্তা নোট',
      'tr': 'Önemli Güvenlik Notları'
    },
    'save_btn': {
      'ar': 'حفظ التغييرات',
      'en': 'Save Changes',
      'ur': 'تبدیلیاں محفوظ کریں',
      'bn': 'পরিবর্তন সংরক্ষণ করুন',
      'tr': 'Değişiklikleri Kaydet'
    },
    'save_success': {
      'ar': 'تم حفظ البيانات بنجاح',
      'en': 'Data saved successfully',
      'ur': 'معلومات کامیابی سے محفوظ ہو گئیں',
      'bn': 'তথ্য সফলভাবে সংরক্ষিত হয়েছে',
      'tr': 'Bilgiler başarıyla kaydedildi'
    },

    // Tawaf & Sai enhancements
    'btn_tawaf': {'ar': 'طواف 🕋', 'en': 'Tawaf 🕋'},
    'btn_sai': {'ar': 'سعي ⛰️', 'en': 'Sa\'ee ⛰️'},
    'calc_method': {'ar': 'كيفية الحساب:', 'en': 'Calculation Method:'},
    'auto_counter': {'ar': 'عداد آلي 🤖', 'en': 'Auto Counter 🤖'},
    'manual_counter': {'ar': 'مرئي يدوي 📋', 'en': 'Manual 📋'},
    'auto_sai_title': {'ar': 'عداد أشواط السعي التلقائي', 'en': 'Automatic Sa\'ee Counter'},
    'auto_tawaf_title': {'ar': 'عداد أشواط الطواف التلقائي', 'en': 'Automatic Tawaf Counter'},
    'shawt_word': {'ar': 'شوط', 'en': 'Round'},
    'congrats_msg': {'ar': '🎉 تقبّل الله منك!', 'en': '🎉 May Allah accept it from you!'},
    'steps_label': {'ar': 'الخطوات: ', 'en': 'Steps: '},
    'dir_safa_marwa': {'ar': '⬅️ متجه من الصفا إلى المروة', 'en': '⬅️ Safa to Marwah'},
    'dir_marwa_safa': {'ar': '➡️ متجه من المروة إلى الصفا', 'en': '➡️ Marwah to Safa'},
    'record_shawt': {'ar': 'تسجيل شوط', 'en': 'Record Round'},
    'reset_btn': {'ar': 'إعادة ضبط', 'en': 'Reset'},
    'duaa_shawt': {'ar': 'دعاء الشوط', 'en': 'Duaa for Round'},
    'audio_stopped_note': {
      'ar': 'تم إيقاف التلاوة الصوتية الآلية للدعاء ليتسنى لك مناجاة الله براحة.',
      'en': 'Automatic background audio for Duaa is muted so you can converse with Allah comfortably.'
    },
    'reset_all_btn': {'ar': 'إعادة ضبط جميع الأشواط', 'en': 'Reset All Rounds'},
    'shawt_prefix': {'ar': 'الشوط', 'en': 'Round'},
    'safa_to_marwa': {'ar': 'من الصفا إلى المروة', 'en': 'Safa to Marwah'},
    'marwa_to_safa': {'ar': 'من المروة إلى الصفا', 'en': 'Marwah to Safa'},
    
    // محاكاة الخريطة والموقع
    'loc_real': {'ar': 'GPS حقيقي 📍', 'en': 'Real GPS 📍'},
    'loc_makkah': {'ar': 'محاكاة مكة 🕋', 'en': 'Makkah Simul 🕋'},
    'loc_picked': {'ar': 'النقطة المحددة 🎯', 'en': 'Picked Spot 🎯'},
    'pick_map_prompt': {'ar': 'اضغط على الخريطة لتحديد موقعك الوهمي.', 'en': 'Tap on the map to set your mocked location.'},
    'service_points': {'ar': 'نقاط الخدمة', 'en': 'Service Points'},
    
    // شاشات أخرى
    'select_lang': {
      'ar': 'اختر اللغة',
      'en': 'Select Language',
      'ur': 'زبان منتخب کریں',
      'bn': 'ভাষা নির্বাচন করুন',
      'tr': 'Dil Seçin'
    },
  };

  // تحميل اللغة المحفوظة عند فتح التطبيق
  static Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLang = prefs.getString('lang') ?? 'ar';
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    currentLang = lang;
  }

  static String translate(String key) {
    return translations[key]?[currentLang] ?? translations[key]!['ar']!;
  }

  // دالة ذكية لإرجاع كود لغة الصوت (TTS) بناءً على اختيار الحاج الحالي
  static String getTtsLanguageCode() {
    switch (currentLang) {
      case 'en':
        return 'en-US';
      case 'ur':
        return 'ur-PK';
      case 'bn':
        return 'bn-BD';
      case 'tr':
        return 'tr-TR';
      case 'ar':
      default:
        return 'ar';
    }
  }
}
