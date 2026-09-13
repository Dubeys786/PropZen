class VoiceBridge {
  static bool get isSupported => false;
  static Future<bool> checkPermission() async => true;
  static bool startListening(
    String lang,
    void Function(String text, bool isFinal) onResult,
    void Function(String error) onError,
    void Function() onDone,
  ) => false;
  static void stopListening() {}
  static bool speak(String text, String lang, void Function() onEnd) => false;
  static void stopSpeaking() {}
}
