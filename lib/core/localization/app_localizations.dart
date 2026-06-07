import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
    Locale('te'),
    Locale('ml'),
    Locale('kn'),
    Locale('pa'),
    Locale('bn'),
    Locale('or'),
    Locale('as'),
  ];

  static const languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'ml': 'മലയാളം',
    'kn': 'ಕನ್ನಡ',
    'pa': 'ਪੰਜਾਬੀ',
    'bn': 'বাংলা',
    'or': 'ଓଡ଼ିଆ',
    'as': 'অসমীয়া',
  };

  static const _values = <String, Map<String, String>>{
    'en': {
      'tagline': 'Score every ball. Anywhere.',
      'startMatch': 'Start Match',
      'matchHistory': 'Match History',
      'watchLive': 'Watch Live Match',
      'matchCode': 'Enter match code',
      'find': 'Find',
      'cloudBackup': 'Cloud backup',
      'online': 'Online',
      'offline': 'Offline - saved locally',
      'syncing': 'Syncing...',
      'continueMatch': 'Continue Match',
      'language': 'Language',
      'developedBy': 'Developed by K.K. & Co.',
      'poweredBy': 'Powered by KK Bharat',
      'liveScoreboard': 'Live Scoreboard',
      'invalidCode': 'Match code not found.',
      'batting': 'Batting',
      'bowling': 'Bowling',
      'overs': 'Overs',
      'striker': 'Striker',
      'nonStriker': 'Non-striker',
      'bowler': 'Bowler',
      'lastOver': 'Last over',
    },
    'hi': {
      'tagline': 'हर गेंद का स्कोर, कहीं भी।',
      'startMatch': 'मैच शुरू करें',
      'matchHistory': 'मैच इतिहास',
      'watchLive': 'लाइव मैच देखें',
      'matchCode': 'मैच कोड दर्ज करें',
      'find': 'खोजें',
      'cloudBackup': 'क्लाउड बैकअप',
      'online': 'ऑनलाइन',
      'offline': 'ऑफलाइन - फोन में सुरक्षित',
      'syncing': 'सिंक हो रहा है...',
      'continueMatch': 'मैच जारी रखें',
      'language': 'भाषा',
      'developedBy': 'डेवलपर K.K. एंड कंपनी',
      'poweredBy': 'KK Bharat द्वारा संचालित',
      'liveScoreboard': 'लाइव स्कोरबोर्ड',
      'invalidCode': 'मैच कोड नहीं मिला।',
      'batting': 'बल्लेबाजी',
      'bowling': 'गेंदबाजी',
      'overs': 'ओवर',
      'striker': 'स्ट्राइकर',
      'nonStriker': 'नॉन-स्ट्राइकर',
      'bowler': 'गेंदबाज',
      'lastOver': 'पिछला ओवर',
    },
    'ta': {
      'tagline': 'ஒவ்வொரு பந்தையும் எங்கும் பதிவு செய்யுங்கள்.',
      'startMatch': 'போட்டியை தொடங்கு',
      'matchHistory': 'போட்டி வரலாறு',
      'watchLive': 'நேரலை போட்டி',
      'matchCode': 'போட்டி குறியீடு',
      'find': 'தேடு',
      'cloudBackup': 'கிளவுட் காப்பு',
      'online': 'இணையத்தில்',
      'offline': 'இணையமில்லை - உள்ளூரில் சேமிப்பு',
      'syncing': 'ஒத்திசைக்கிறது...',
      'continueMatch': 'போட்டியை தொடர்க',
      'language': 'மொழி',
      'developedBy': 'K.K. & Co. உருவாக்கியது',
      'poweredBy': 'KK Bharat ஆதரவு',
      'liveScoreboard': 'நேரலை ஸ்கோர்போர்டு',
      'invalidCode': 'போட்டி குறியீடு கிடைக்கவில்லை.',
    },
    'te': {
      'tagline': 'ప్రతి బంతిని ఎక్కడైనా స్కోర్ చేయండి.',
      'startMatch': 'మ్యాచ్ ప్రారంభించండి',
      'matchHistory': 'మ్యాచ్ చరిత్ర',
      'watchLive': 'లైవ్ మ్యాచ్ చూడండి',
      'matchCode': 'మ్యాచ్ కోడ్',
      'find': 'వెతకండి',
      'cloudBackup': 'క్లౌడ్ బ్యాకప్',
      'online': 'ఆన్‌లైన్',
      'offline': 'ఆఫ్‌లైన్ - ఫోన్‌లో భద్రం',
      'syncing': 'సింక్ అవుతోంది...',
      'continueMatch': 'మ్యాచ్ కొనసాగించండి',
      'language': 'భాష',
      'developedBy': 'K.K. & Co. అభివృద్ధి',
      'poweredBy': 'KK Bharat ద్వారా',
      'liveScoreboard': 'లైవ్ స్కోర్‌బోర్డ్',
      'invalidCode': 'మ్యాచ్ కోడ్ కనుగొనబడలేదు.',
    },
    'ml': {
      'tagline': 'ഓരോ പന്തും എവിടെയും സ്കോർ ചെയ്യുക.',
      'startMatch': 'മത്സരം ആരംഭിക്കുക',
      'matchHistory': 'മത്സര ചരിത്രം',
      'watchLive': 'തത്സമയ മത്സരം',
      'matchCode': 'മാച്ച് കോഡ്',
      'find': 'കണ്ടെത്തുക',
      'cloudBackup': 'ക്ലൗഡ് ബാക്കപ്പ്',
      'online': 'ഓൺലൈൻ',
      'offline': 'ഓഫ്‌ലൈൻ - ഫോണിൽ സൂക്ഷിച്ചു',
      'syncing': 'സിങ്ക് ചെയ്യുന്നു...',
      'continueMatch': 'മത്സരം തുടരുക',
      'language': 'ഭാഷ',
      'developedBy': 'K.K. & Co. വികസിപ്പിച്ചത്',
      'poweredBy': 'KK Bharat നൽകുന്നു',
      'liveScoreboard': 'തത്സമയ സ്കോർബോർഡ്',
      'invalidCode': 'മാച്ച് കോഡ് കണ്ടെത്തിയില്ല.',
    },
    'kn': {
      'tagline': 'ಪ್ರತಿ ಚೆಂಡಿನ ಸ್ಕೋರ್ ಎಲ್ಲೆಡೆ.',
      'startMatch': 'ಪಂದ್ಯ ಪ್ರಾರಂಭಿಸಿ',
      'matchHistory': 'ಪಂದ್ಯ ಇತಿಹಾಸ',
      'watchLive': 'ಲೈವ್ ಪಂದ್ಯ ನೋಡಿ',
      'matchCode': 'ಪಂದ್ಯ ಕೋಡ್',
      'find': 'ಹುಡುಕಿ',
      'cloudBackup': 'ಕ್ಲೌಡ್ ಬ್ಯಾಕಪ್',
      'online': 'ಆನ್‌ಲೈನ್',
      'offline': 'ಆಫ್‌ಲೈನ್ - ಫೋನ್‌ನಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ',
      'syncing': 'ಸಿಂಕ್ ಆಗುತ್ತಿದೆ...',
      'continueMatch': 'ಪಂದ್ಯ ಮುಂದುವರಿಸಿ',
      'language': 'ಭಾಷೆ',
      'developedBy': 'K.K. & Co. ಅಭಿವೃದ್ಧಿ',
      'poweredBy': 'KK Bharat ಮೂಲಕ',
      'liveScoreboard': 'ಲೈವ್ ಸ್ಕೋರ್‌ಬೋರ್ಡ್',
      'invalidCode': 'ಪಂದ್ಯ ಕೋಡ್ ಸಿಗಲಿಲ್ಲ.',
    },
    'pa': {
      'tagline': 'ਹਰ ਗੇਂਦ ਦਾ ਸਕੋਰ, ਕਿਤੇ ਵੀ।',
      'startMatch': 'ਮੈਚ ਸ਼ੁਰੂ ਕਰੋ',
      'matchHistory': 'ਮੈਚ ਇਤਿਹਾਸ',
      'watchLive': 'ਲਾਈਵ ਮੈਚ ਵੇਖੋ',
      'matchCode': 'ਮੈਚ ਕੋਡ',
      'find': 'ਲੱਭੋ',
      'cloudBackup': 'ਕਲਾਉਡ ਬੈਕਅੱਪ',
      'online': 'ਆਨਲਾਈਨ',
      'offline': 'ਆਫਲਾਈਨ - ਫੋਨ ਵਿੱਚ ਸੁਰੱਖਿਅਤ',
      'syncing': 'ਸਿੰਕ ਹੋ ਰਿਹਾ ਹੈ...',
      'continueMatch': 'ਮੈਚ ਜਾਰੀ ਰੱਖੋ',
      'language': 'ਭਾਸ਼ਾ',
      'developedBy': 'K.K. & Co. ਵੱਲੋਂ ਤਿਆਰ',
      'poweredBy': 'KK Bharat ਦੁਆਰਾ',
      'liveScoreboard': 'ਲਾਈਵ ਸਕੋਰਬੋਰਡ',
      'invalidCode': 'ਮੈਚ ਕੋਡ ਨਹੀਂ ਮਿਲਿਆ।',
    },
    'bn': {
      'tagline': 'প্রতিটি বলের স্কোর, যেকোনো জায়গায়।',
      'startMatch': 'ম্যাচ শুরু করুন',
      'matchHistory': 'ম্যাচ ইতিহাস',
      'watchLive': 'লাইভ ম্যাচ দেখুন',
      'matchCode': 'ম্যাচ কোড',
      'find': 'খুঁজুন',
      'cloudBackup': 'ক্লাউড ব্যাকআপ',
      'online': 'অনলাইন',
      'offline': 'অফলাইন - ফোনে সংরক্ষিত',
      'syncing': 'সিঙ্ক হচ্ছে...',
      'continueMatch': 'ম্যাচ চালিয়ে যান',
      'language': 'ভাষা',
      'developedBy': 'K.K. & Co. নির্মিত',
      'poweredBy': 'KK Bharat দ্বারা',
      'liveScoreboard': 'লাইভ স্কোরবোর্ড',
      'invalidCode': 'ম্যাচ কোড পাওয়া যায়নি।',
    },
    'or': {
      'tagline': 'ପ୍ରତ୍ୟେକ ବଲ୍‌ର ସ୍କୋର, ସବୁଠାରେ।',
      'startMatch': 'ମ୍ୟାଚ୍ ଆରମ୍ଭ କରନ୍ତୁ',
      'matchHistory': 'ମ୍ୟାଚ୍ ଇତିହାସ',
      'watchLive': 'ଲାଇଭ୍ ମ୍ୟାଚ୍ ଦେଖନ୍ତୁ',
      'matchCode': 'ମ୍ୟାଚ୍ କୋଡ୍',
      'find': 'ଖୋଜନ୍ତୁ',
      'cloudBackup': 'କ୍ଲାଉଡ୍ ବ୍ୟାକଅପ୍',
      'online': 'ଅନଲାଇନ୍',
      'offline': 'ଅଫଲାଇନ୍ - ଫୋନ୍‌ରେ ସଂରକ୍ଷିତ',
      'syncing': 'ସିଙ୍କ ହେଉଛି...',
      'continueMatch': 'ମ୍ୟାଚ୍ ଜାରି ରଖନ୍ତୁ',
      'language': 'ଭାଷା',
      'developedBy': 'K.K. & Co. ଦ୍ୱାରା ବିକଶିତ',
      'poweredBy': 'KK Bharat ଦ୍ୱାରା',
      'liveScoreboard': 'ଲାଇଭ୍ ସ୍କୋରବୋର୍ଡ',
      'invalidCode': 'ମ୍ୟାଚ୍ କୋଡ୍ ମିଳିଲା ନାହିଁ।',
    },
    'as': {
      'tagline': 'প্ৰতিটো বলৰ স্ক’ৰ, যিকোনো ঠাইত।',
      'startMatch': 'মেচ আৰম্ভ কৰক',
      'matchHistory': 'মেচ ইতিহাস',
      'watchLive': 'লাইভ মেচ চাওক',
      'matchCode': 'মেচ ক’ড',
      'find': 'বিচাৰক',
      'cloudBackup': 'ক্লাউড বেকআপ',
      'online': 'অনলাইন',
      'offline': 'অফলাইন - ফোনত সংৰক্ষিত',
      'syncing': 'চিংক হৈ আছে...',
      'continueMatch': 'মেচ অব্যাহত ৰাখক',
      'language': 'ভাষা',
      'developedBy': 'K.K. & Co. দ্বাৰা নিৰ্মিত',
      'poweredBy': 'KK Bharat দ্বাৰা',
      'liveScoreboard': 'লাইভ স্ক’ৰবৰ্ড',
      'invalidCode': 'মেচ ক’ড পোৱা নগ’ল।',
    },
  };

  String text(String key) =>
      _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (value) => value.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationContext on BuildContext {
  String tr(String key) => AppLocalizations.of(this).text(key);
}
