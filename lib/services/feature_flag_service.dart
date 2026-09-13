import 'package:flutter/foundation.dart';
import '../config/phase_config.dart';

class FeatureFlagService extends ChangeNotifier {
  FeatureFlagService._internal() {
    _flags.addAll(PhaseConfig.defaultFlags);
  }
  static final FeatureFlagService instance = FeatureFlagService._internal();
  factory FeatureFlagService() => instance;

  final Map<String, bool> _flags = {};
  LaunchPhase _activePhase = PhaseConfig.currentPhase;

  LaunchPhase get activePhase => _activePhase;
  Map<String, bool> get allFlags => Map.unmodifiable(_flags);

  /// Checks if a feature is enabled
  bool isFeatureEnabled(String flagKey) {
    return _flags[flagKey] ?? false;
  }

  /// Toggles or sets a feature flag at runtime (e.g. from Admin Panel or backend sync)
  void setFeatureFlag(String flagKey, bool isEnabled) {
    _flags[flagKey] = isEnabled;
    notifyListeners();
  }

  /// Sets the active launch phase and applies corresponding default flags
  void setLaunchPhase(LaunchPhase phase) {
    _activePhase = phase;
    switch (phase) {
      case LaunchPhase.phase1DiwaliLaunch:
        _flags['vastu_3d'] = false;
        _flags['visualizer_3d'] = false;
        _flags['interior_theme_visualizer'] = false;
        _flags['propzen_reporter'] = false;
        _flags['youtube_automation'] = false;
        _flags['ai_voice_videos'] = false;
        break;
      case LaunchPhase.phase2Visualization:
        _flags['vastu_3d'] = true;
        _flags['visualizer_3d'] = true;
        _flags['interior_theme_visualizer'] = true;
        _flags['propzen_reporter'] = false;
        _flags['youtube_automation'] = false;
        _flags['ai_voice_videos'] = false;
        break;
      case LaunchPhase.phase3MediaAutomation:
      case LaunchPhase.phase4SuperApp:
        _flags['vastu_3d'] = true;
        _flags['visualizer_3d'] = true;
        _flags['interior_theme_visualizer'] = true;
        _flags['propzen_reporter'] = true;
        _flags['youtube_automation'] = true;
        _flags['ai_voice_videos'] = true;
        break;
    }
    notifyListeners();
  }
}
