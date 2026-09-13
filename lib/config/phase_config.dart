import 'package:flutter/foundation.dart';

/// Defines the staging phases for PropZen's product roadmap
enum LaunchPhase {
  phase1DiwaliLaunch,
  phase2Visualization,
  phase3MediaAutomation,
  phase4SuperApp;

  String get displayName {
    switch (this) {
      case LaunchPhase.phase1DiwaliLaunch:
        return 'Phase 1: Diwali Launch (Trust-First MVP)';
      case LaunchPhase.phase2Visualization:
        return 'Phase 2: 3D Visualization (3-Month Update)';
      case LaunchPhase.phase3MediaAutomation:
        return 'Phase 3: AI Media & YouTube Automation (6-Month Update)';
      case LaunchPhase.phase4SuperApp:
        return 'Phase 4: Real Estate Super App (Future)';
    }
  }
}

class PhaseConfig {
  /// Current active launch phase of the deployment
  static const LaunchPhase currentPhase = LaunchPhase.phase1DiwaliLaunch;

  /// Default feature flag configurations across phases
  static const Map<String, bool> defaultFlags = {
    // 🟢 Phase 1: Core Launch Features (ENABLED ON DAY 1)
    'property_listing': true,
    'wati_followup': true,
    'legal_verification': true,
    'automatic_pincode': true,
    'area_discovery_base': true,
    'admin_verification_center': true,
    'analytics_telemetry': true,

    // 🟡 Phase 2: 3D Visualization (TARGET ~3 MONTHS)
    'vastu_3d': false,
    'visualizer_3d': false,
    'interior_theme_visualizer': false,

    // 🔵 Phase 3: AI Media & Automation (TARGET ~6 MONTHS)
    'propzen_reporter': false,
    'youtube_automation': false,
    'ai_voice_videos': false,

    // 🟣 Future Modular Extensions
    'loan_comparison': true, // Staged modularly
    'supplier_directory': true,
    'forum_community': true,
    'nri_hub': true,
    'multi_region_scaling': true,
    'construction_tracking': true,
  };
}
