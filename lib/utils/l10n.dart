/// Supported interface languages for SevaSetu (V1: English, हिंदी, मराठी).
enum AppLanguage {
  english('English', 'en'),
  hindi('हिंदी', 'hi'),
  marathi('मराठी', 'mr');

  const AppLanguage(this.nativeName, this.code);

  final String nativeName;
  final String code;
}

/// Look up a translated string for the active language.
///
/// The dictionary currently covers app chrome — navigation, headings,
/// status labels and common actions — which is the visible multilingual
/// surface in V1. Adding a language is one new [AppLanguage] entry plus a
/// map for each key.
class L10n {
  L10n._();

  static String tr(AppLanguage lang, String key, [String fallback = '']) {
    final table = _strings[key];
    if (table == null) return fallback.isEmpty ? key : fallback;
    return table[lang] ?? table[AppLanguage.english] ?? key;
  }

  static String list(AppLanguage lang, String prefix) {
    final map = <String, String>{};
    _strings.forEach((key, table) {
      if (key.startsWith('$prefix.')) map[key] = table[lang] ?? '';
    });
    return map.isEmpty ? '' : map.values.join(' ');
  }

  static const Map<String, Map<AppLanguage, String>> _strings = {
    // ---- Navigation tabs ----
    'nav.home': {
      AppLanguage.english: 'Home',
      AppLanguage.hindi: 'होम',
      AppLanguage.marathi: 'होम',
    },
    'nav.services': {
      AppLanguage.english: 'Services',
      AppLanguage.hindi: 'सेवाएँ',
      AppLanguage.marathi: 'सेवा',
    },
    'nav.journey': {
      AppLanguage.english: 'My Journey',
      AppLanguage.hindi: 'मेरी यात्रा',
      AppLanguage.marathi: 'माझा प्रवास',
    },
    'nav.documents': {
      AppLanguage.english: 'Documents',
      AppLanguage.hindi: 'दस्तावेज़',
      AppLanguage.marathi: 'कागदपत्रे',
    },
    'nav.applications': {
      AppLanguage.english: 'Applications',
      AppLanguage.hindi: 'आवेदन',
      AppLanguage.marathi: 'अर्ज',
    },

    // ---- Common actions ----
    'action.continue': {
      AppLanguage.english: 'Continue',
      AppLanguage.hindi: 'जारी रखें',
      AppLanguage.marathi: 'पुढे जा',
    },
    'action.getStarted': {
      AppLanguage.english: 'Get Started',
      AppLanguage.hindi: 'शुरू करें',
      AppLanguage.marathi: 'सुरू करा',
    },
    'action.skip': {
      AppLanguage.english: 'Skip',
      AppLanguage.hindi: 'छोड़ें',
      AppLanguage.marathi: 'वगळा',
    },
    'action.back': {
      AppLanguage.english: 'Back',
      AppLanguage.hindi: 'वापस',
      AppLanguage.marathi: 'मागे',
    },
    'action.view': {
      AppLanguage.english: 'View',
      AppLanguage.hindi: 'देखें',
      AppLanguage.marathi: 'पहा',
    },
    'action.viewDetails': {
      AppLanguage.english: 'View Details',
      AppLanguage.hindi: 'विवरण देखें',
      AppLanguage.marathi: 'तपशील पहा',
    },
    'action.upload': {
      AppLanguage.english: 'Upload',
      AppLanguage.hindi: 'अपलोड करें',
      AppLanguage.marathi: 'अपलोड करा',
    },
    'action.replace': {
      AppLanguage.english: 'Replace',
      AppLanguage.hindi: 'बदलें',
      AppLanguage.marathi: 'बदला',
    },
    'action.verify': {
      AppLanguage.english: 'Check Validity',
      AppLanguage.hindi: 'वैधता जांचें',
      AppLanguage.marathi: 'वैधता तपासा',
    },
    'action.download': {
      AppLanguage.english: 'Download',
      AppLanguage.hindi: 'डाउनलोड करें',
      AppLanguage.marathi: 'डाउनलोड करा',
    },
    'action.resolved': {
      AppLanguage.english: 'Mark Resolved',
      AppLanguage.hindi: 'हल हुआ',
      AppLanguage.marathi: 'निराकरण झाले',
    },
    'action.retry': {
      AppLanguage.english: 'Try Again',
      AppLanguage.hindi: 'फिर से प्रयास करें',
      AppLanguage.marathi: 'पुन्हा प्रयत्न करा',
    },
    'action.cancel': {
      AppLanguage.english: 'Cancel',
      AppLanguage.hindi: 'रद्द करें',
      AppLanguage.marathi: 'रद्द करा',
    },
    'action.save': {
      AppLanguage.english: 'Save',
      AppLanguage.hindi: 'सहेजें',
      AppLanguage.marathi: 'जतन करा',
    },
    'action.edit': {
      AppLanguage.english: 'Edit',
      AppLanguage.hindi: 'संपादित करें',
      AppLanguage.marathi: 'संपादित करा',
    },
    'action.language': {
      AppLanguage.english: 'Language',
      AppLanguage.hindi: 'भाषा',
      AppLanguage.marathi: 'भाषा',
    },
    'action.notifications': {
      AppLanguage.english: 'Notifications',
      AppLanguage.hindi: 'सूचनाएँ',
      AppLanguage.marathi: 'सूचना',
    },
    'action.profile': {
      AppLanguage.english: 'Profile',
      AppLanguage.hindi: 'प्रोफ़ाइल',
      AppLanguage.marathi: 'प्रोफाइल',
    },
    'action.viewAll': {
      AppLanguage.english: 'View all',
      AppLanguage.hindi: 'सभी देखें',
      AppLanguage.marathi: 'सर्व पहा',
    },

    // ---- Document status ----
    'doc.verified': {
      AppLanguage.english: 'Verified',
      AppLanguage.hindi: 'सत्यापित',
      AppLanguage.marathi: 'प्रमाणित',
    },
    'doc.available': {
      AppLanguage.english: 'Available',
      AppLanguage.hindi: 'उपलब्ध',
      AppLanguage.marathi: 'उपलब्ध',
    },
    'doc.expiringSoon': {
      AppLanguage.english: 'Expiring Soon',
      AppLanguage.hindi: 'जल्द समाप्त होगा',
      AppLanguage.marathi: 'लवकरच कालबाह्य',
    },
    'doc.expired': {
      AppLanguage.english: 'Expired',
      AppLanguage.hindi: 'समाप्त',
      AppLanguage.marathi: 'कालबाह्य',
    },
    'doc.invalid': {
      AppLanguage.english: 'Invalid',
      AppLanguage.hindi: 'अमान्य',
      AppLanguage.marathi: 'अवैध',
    },
    'doc.verificationRequired': {
      AppLanguage.english: 'Verification Required',
      AppLanguage.hindi: 'सत्यापन आवश्यक',
      AppLanguage.marathi: 'पडताळणी आवश्यक',
    },
    'doc.missing': {
      AppLanguage.english: 'Missing',
      AppLanguage.hindi: 'अनुपलब्ध',
      AppLanguage.marathi: 'गहाळ',
    },
    'doc.valid': {
      AppLanguage.english: 'Valid',
      AppLanguage.hindi: 'मान्य',
      AppLanguage.marathi: 'वैध',
    },
    'doc.validUntil': {
      AppLanguage.english: 'Valid until',
      AppLanguage.hindi: 'मान्य है',
      AppLanguage.marathi: 'पर्यंत वैध',
    },
    'doc.lifetime': {
      AppLanguage.english: 'Lifetime validity',
      AppLanguage.hindi: 'आजीवन मान्य',
      AppLanguage.marathi: 'जीवनभर वैध',
    },
    'doc.noExpiry': {
      AppLanguage.english: 'No expiry',
      AppLanguage.hindi: 'कोई समाप्ति नहीं',
      AppLanguage.marathi: 'कालबाह्यता नाही',
    },

    // ---- Readiness ----
    'ready': {
      AppLanguage.english: 'Ready',
      AppLanguage.hindi: 'तैयार',
      AppLanguage.marathi: 'तयार',
    },
    'notReady': {
      AppLanguage.english: 'Needs Attention',
      AppLanguage.hindi: 'ध्यान देने की ज़रूरत',
      AppLanguage.marathi: 'लक्ष द्या',
    },
    'appReady': {
      AppLanguage.english: 'Application Ready',
      AppLanguage.hindi: 'आवेदन तैयार',
      AppLanguage.marathi: 'अर्ज तयार',
    },

    // ---- Greetings ----
    'greet.morning': {
      AppLanguage.english: 'Good Morning',
      AppLanguage.hindi: 'सुप्रभात',
      AppLanguage.marathi: 'शुभ सकाळ',
    },
    'greet.afternoon': {
      AppLanguage.english: 'Good Afternoon',
      AppLanguage.hindi: 'नमस्ते',
      AppLanguage.marathi: 'शुभ दुपार',
    },
    'greet.evening': {
      AppLanguage.english: 'Good Evening',
      AppLanguage.hindi: 'शुभ संध्या',
      AppLanguage.marathi: 'शुभ संध्याकाळ',
    },

    // ---- Home ----
    'home.subtitle': {
      AppLanguage.english: 'How can SevaSetu help you today?',
      AppLanguage.hindi: 'आज सेवासेतु आपकी कैसे मदद कर सकता है?',
      AppLanguage.marathi: 'आज सेवासेतु तुम्हाला कशी मदत करू शकते?',
    },
    'home.searchPlaceholder': {
      AppLanguage.english: 'What government service are you looking for?',
      AppLanguage.hindi: 'आप कौन सी सरकारी सेवा ढूंढ रहे हैं?',
      AppLanguage.marathi: 'तुम्ही कोणती शासकीय सेवा शोधत आहात?',
    },
    'home.findService': {
      AppLanguage.english: 'Find My Service',
      AppLanguage.hindi: 'मेरी सेवा खोजें',
      AppLanguage.marathi: 'माझी सेवा शोधा',
    },
    'home.readinessTitle': {
      AppLanguage.english: 'How ready are you to apply?',
      AppLanguage.hindi: 'आप आवेदन के लिए कितने तैयार हैं?',
      AppLanguage.marathi: 'तुम्ही अर्जासाठी किती तयार आहात?',
    },
    'home.quickActions': {
      AppLanguage.english: 'Quick Actions',
      AppLanguage.hindi: 'त्वरित कार्य',
      AppLanguage.marathi: 'जलद कृती',
    },
    'home.recommended': {
      AppLanguage.english: 'Recommended for You',
      AppLanguage.hindi: 'आपके लिए अनुशंसित',
      AppLanguage.marathi: 'तुमच्यासाठी शिफारस',
    },
  };
}
