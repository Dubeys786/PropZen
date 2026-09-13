import 'dart:async';
import 'package:flutter/foundation.dart';
import 'voice_bridge.dart';
import '../config/voice_config.dart';

enum VoiceAgentState {
  idle,
  requestingPermission,
  listening,
  thinking,
  speaking,
  error,
}

class PropzenVoiceService {
  PropzenVoiceService._();
  static final PropzenVoiceService instance = PropzenVoiceService._();

  final ValueNotifier<VoiceAgentState> stateNotifier = ValueNotifier(VoiceAgentState.idle);
  final ValueNotifier<String> liveTranscriptNotifier = ValueNotifier('');
  final ValueNotifier<String> lastSpokenAiResponseNotifier = ValueNotifier('');
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Request mic permission and start speech recognition
  Future<bool> startListening({
    String languageCode = PropzenVoiceConfig.defaultLanguageCode, // 'hi-IN'
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
    required VoidCallback onDone,
  }) async {
    stateNotifier.value = VoiceAgentState.requestingPermission;
    liveTranscriptNotifier.value = '';
    errorMessageNotifier.value = null;

    if (!VoiceBridge.isSupported) {
      // Non-web/test fallback
      stateNotifier.value = VoiceAgentState.listening;
      return true;
    }

    try {
      final hasPermission = await VoiceBridge.checkPermission();
      if (!hasPermission) {
        stateNotifier.value = VoiceAgentState.error;
        errorMessageNotifier.value = 'Microphone permission was denied. Please allow microphone access.';
        onError('Microphone permission denied');
        return false;
      }

      stateNotifier.value = VoiceAgentState.listening;

      final success = VoiceBridge.startListening(
        languageCode,
        (text, isFinal) {
          liveTranscriptNotifier.value = text;
          onResult(text, isFinal);
        },
        (errorStr) {
          stateNotifier.value = VoiceAgentState.error;
          errorMessageNotifier.value = errorStr;
          onError(errorStr);
        },
        () {
          if (stateNotifier.value == VoiceAgentState.listening) {
            stateNotifier.value = VoiceAgentState.idle;
          }
          onDone();
        },
      );

      if (!success) {
        stateNotifier.value = VoiceAgentState.error;
        errorMessageNotifier.value = 'Speech recognition engine could not be started.';
        onError('Voice engine unavailable');
        return false;
      }

      return true;
    } catch (e) {
      stateNotifier.value = VoiceAgentState.error;
      errorMessageNotifier.value = e.toString();
      onError(e.toString());
      return false;
    }
  }

  /// Stop listening
  void stopListening() {
    VoiceBridge.stopListening();
    if (stateNotifier.value == VoiceAgentState.listening || stateNotifier.value == VoiceAgentState.requestingPermission) {
      stateNotifier.value = VoiceAgentState.idle;
    }
  }

  bool isTestMode = false;
  Timer? _simulationTimer;

  /// Read text aloud using the Unified Global Indian Female Text-to-Speech Voice
  Future<void> speak(String text, {String? languageCode, VoidCallback? onCompleted}) async {
    if (text.trim().isEmpty) {
      onCompleted?.call();
      return;
    }

    final effectiveLang = languageCode ?? PropzenVoiceConfig.defaultLanguageCode;

    _simulationTimer?.cancel();
    stateNotifier.value = VoiceAgentState.speaking;
    lastSpokenAiResponseNotifier.value = text;

    if (!VoiceBridge.isSupported) {
      // Non-web simulation
      if (isTestMode) {
        stateNotifier.value = VoiceAgentState.idle;
        onCompleted?.call();
        return;
      }
      final completer = Completer<void>();
      _simulationTimer = Timer(Duration(milliseconds: (text.length * 20).clamp(100, 1500)), () {
        if (stateNotifier.value == VoiceAgentState.speaking) {
          stateNotifier.value = VoiceAgentState.idle;
        }
        onCompleted?.call();
        if (!completer.isCompleted) completer.complete();
      });
      return completer.future;
    }

    try {
      final success = VoiceBridge.speak(text, effectiveLang, () {
        if (stateNotifier.value == VoiceAgentState.speaking) {
          stateNotifier.value = VoiceAgentState.idle;
        }
        onCompleted?.call();
      });
      if (!success) {
        stateNotifier.value = VoiceAgentState.idle;
        onCompleted?.call();
      }
    } catch (e) {
      debugPrint('[VoiceService] TTS Speak error: $e');
      stateNotifier.value = VoiceAgentState.idle;
      onCompleted?.call();
    }
  }

  /// Stop speaking / interrupt immediately
  void stopSpeaking() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    VoiceBridge.stopSpeaking();
    if (stateNotifier.value == VoiceAgentState.speaking) {
      stateNotifier.value = VoiceAgentState.idle;
    }
  }

  /// Stop everything (listening & speaking)
  void stopAll() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    stopListening();
    stopSpeaking();
    stateNotifier.value = VoiceAgentState.idle;
  }
}
