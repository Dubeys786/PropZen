/// Central Social Media & Messaging Configuration for PropZen
class SocialConfig {
  /// Instagram profile / official page URL
  /// Official PropZen Instagram profile
  static const String instagramUrl = 'https://www.instagram.com/propz_en/?hl=en';

  /// WhatsApp Contact Number (Format: Country Code + Phone Number without '+' or special characters)
  /// Example for India (+91 98103 94068): '919810394068'
  /// Leave empty string '' if not yet configured.
  static const String whatsappNumber = '919810394068';

  /// Default WhatsApp Pre-filled message sent when user opens chat
  static const String whatsappDefaultMessage = 'Hi PropZen! I would like to inquire about properties and site visits.';

  /// Generates the official WhatsApp click-to-chat URL: https://wa.me/<NUMBER>?text=<MESSAGE>
  static String get whatsappChatUrl {
    final cleanNumber = whatsappNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.isEmpty) {
      // Fallback placeholder when no number is configured
      return 'https://wa.me/';
    }
    final encodedMsg = Uri.encodeComponent(whatsappDefaultMessage);
    return 'https://wa.me/$cleanNumber?text=$encodedMsg';
  }

  /// Helper flag to check if a specific WhatsApp number is configured
  static bool get isWhatsAppConfigured {
    final clean = whatsappNumber.replaceAll(RegExp(r'\D'), '');
    return clean.isNotEmpty;
  }
}
