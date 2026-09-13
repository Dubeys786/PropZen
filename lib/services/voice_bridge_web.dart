// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class VoiceBridge {
  static bool get isSupported => true;

  static Future<bool> checkPermission() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return true;
      final stream = await mediaDevices.getUserMedia({'audio': true});
      stream.getTracks().forEach((track) => track.stop());
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool startListening(
    String lang,
    void Function(String text, bool isFinal) onResult,
    void Function(String error) onError,
    void Function() onDone,
  ) {
    try {
      final voiceEngine = js.context['propzenVoiceEngine'];
      if (voiceEngine != null) {
        voiceEngine.callMethod('startListening', [
          lang,
          js.allowInterop((dynamic text, dynamic isFinal) {
            onResult(text?.toString() ?? '', isFinal == true);
          }),
          js.allowInterop((dynamic err) {
            onError(err?.toString() ?? 'Voice error');
          }),
          js.allowInterop(() {
            onDone();
          }),
        ]);
        return true;
      }
      return false;
    } catch (e) {
      onError(e.toString());
      return false;
    }
  }

  static void stopListening() {
    try {
      final voiceEngine = js.context['propzenVoiceEngine'];
      voiceEngine?.callMethod('stopListening');
    } catch (_) {}
  }

  static bool speak(String text, String lang, void Function() onEnd) {
    try {
      final voiceEngine = js.context['propzenVoiceEngine'];
      if (voiceEngine != null) {
        voiceEngine.callMethod('speak', [
          text,
          lang,
          js.allowInterop(() {
            onEnd();
          }),
        ]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void stopSpeaking() {
    try {
      final voiceEngine = js.context['propzenVoiceEngine'];
      voiceEngine?.callMethod('stopSpeaking');
    } catch (_) {}
  }
}
