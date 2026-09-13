/// Centralized PropZen AI Female Voice Agent Configuration
/// Single source of truth for voice persona, gender, rate, pitch, and language settings.
class PropzenVoiceConfig {
  /// Name of the AI assistant persona
  static const String assistantName = 'PropZen AI Assistant';

  /// Voice gender - strictly Female
  static const String voiceGender = 'Female';

  /// Default Speech-to-Text & Text-to-Speech Language Code
  /// 'hi-IN' provides optimal phonetic rendering for Indian Hindi + Hinglish + Indian English.
  static const String defaultLanguageCode = 'hi-IN';

  /// Secondary language code for English real-estate dialogues
  static const String englishLanguageCode = 'en-IN';

  /// Conversational speech rate (1.0 = normal, moderate conversational speed)
  static const double speechRate = 1.0;

  /// Conversational speech pitch (1.15 = natural warm female vocal range)
  static const double speechPitch = 1.15;

  /// High-priority Indian Female TTS Voice Name Tokens across OS/Browsers
  static const List<String> preferredFemaleVoiceKeywords = [
    // Top-tier Microsoft Neural Indian Female Voices (Edge / Windows 10 & 11)
    'swara',     // Microsoft Swara Online (Natural) - Hindi (India)
    'neerja',    // Microsoft Neerja Online (Natural) - English (India)
    'kalpana',   // Microsoft Kalpana - Hindi (India)
    'heera',     // Microsoft Heera - English (India)
    'ananya',    // Microsoft Ananya - Hindi (India)
    'priya',     // Microsoft Priya - English (India)
    // Google Chrome / Android Neural Female Voices
    'google हिन्दी', // Google Hindi Female
    'google hindi',
    'google en-in female',
    'sangeeta',
    // Apple Safari / macOS / iOS Indian Female Voices
    'lekha',     // Apple Lekha - Hindi Female
    'kavya',     // Apple Kavya - Hindi Female
    'aditi',     // Apple Aditi - Indian English/Hindi Female
    'veena',     // Apple Veena - Indian English Female
    // Global Natural Female Fallbacks
    'zira',
    'aria',
    'jenny',
    'samantha',
    'female',
  ];

  /// Strict blacklist of male voice tokens to guarantee no male voice is ever selected
  static const List<String> blacklistedMaleKeywords = [
    'david',
    'mark',
    'george',
    'ravi',
    'madhur',
    'hemant',
    'rishi',
    'guy',
    'stefan',
    'prabhat',
    'male',
    'richard',
    'james',
    'en-in-x-cda-local',
  ];

  static List<String> get femaleVoiceTokens => preferredFemaleVoiceKeywords;
}

typedef VoiceConfig = PropzenVoiceConfig;
