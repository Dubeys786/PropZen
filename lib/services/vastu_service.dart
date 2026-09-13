import 'package:flutter/foundation.dart';

class VastuRoomSuggestion {
  final String roomName;
  final String idealDirection;
  final String currentDirection;
  final String status; // 'Ideal', 'Good', 'Correction Suggested'
  final String advice;

  const VastuRoomSuggestion({
    required this.roomName,
    required this.idealDirection,
    required this.currentDirection,
    required this.status,
    required this.advice,
  });
}

class VastuAnalysisReport {
  final int overallScore; // e.g. 90/100
  final String entranceDirection;
  final String facingDirection;
  final String summary;
  final List<VastuRoomSuggestion> roomSuggestions;
  final List<String> improvementTips;
  final String disclaimer;

  const VastuAnalysisReport({
    required this.overallScore,
    required this.entranceDirection,
    required this.facingDirection,
    required this.summary,
    required this.roomSuggestions,
    required this.improvementTips,
    this.disclaimer = 'Vastu guidance is provided as cultural and architectural advisory information. Individual layouts may vary based on structural blueprints and master site planning.',
  });
}

class VastuService extends ChangeNotifier {
  VastuService._internal();
  static final VastuService instance = VastuService._internal();
  factory VastuService() => instance;

  // =========================================================================
  // 1. GENERATE VASTU ANALYSIS
  // =========================================================================
  VastuAnalysisReport analyzeVastu({
    required double plotWidth,
    required double plotLength,
    required String propertyType,
    required String direction, // 'North', 'East', 'North-East', 'South', 'West'
    required String entranceDirection,
    List<String> rooms = const ['Master Bedroom', 'Kitchen', 'Living Room', 'Pooja Room'],
  }) {
    int score = 88;
    final List<VastuRoomSuggestion> suggestions = [];
    final List<String> tips = [];

    // Entrance Scoring
    final entUpper = entranceDirection.toUpperCase();
    if (entUpper.contains('NE') || entUpper.contains('NORTH-EAST') || entUpper.contains('EAST') || entUpper.contains('NORTH')) {
      score += 6;
      tips.add('Main entrance in $entranceDirection brings positive morning solar energy and prosperity.');
    } else {
      score -= 4;
      tips.add('For $entranceDirection entrance, place a brass Swastik or auspicious threshold marker.');
    }

    // Room placements
    suggestions.add(const VastuRoomSuggestion(
      roomName: 'Master Bedroom',
      idealDirection: 'South-West (Nairutya)',
      currentDirection: 'South-West',
      status: 'Ideal',
      advice: 'Promotes stability, grounding, and peaceful sleep. Position headboard towards South.',
    ));

    suggestions.add(const VastuRoomSuggestion(
      roomName: 'Kitchen (Agni Sthana)',
      idealDirection: 'South-East (Agneya)',
      currentDirection: 'South-East',
      status: 'Ideal',
      advice: 'Cook facing East. Keep water sink separated from cooking stove by at least 2 feet.',
    ));

    suggestions.add(const VastuRoomSuggestion(
      roomName: 'Pooja / Meditation Corner',
      idealDirection: 'North-East (Ishanya)',
      currentDirection: 'North-East',
      status: 'Ideal',
      advice: 'Keep light-filled, clean, and elevated from the floor.',
    ));

    suggestions.add(const VastuRoomSuggestion(
      roomName: 'Living & Drawing Room',
      idealDirection: 'North / East / North-West',
      currentDirection: 'East',
      status: 'Good',
      advice: 'Welcome guests facing East or North. Place heavy furniture along South and West walls.',
    ));

    tips.add('Ensure maximum open space and cross-ventilation windows along the North and East facades.');
    tips.add('Keep the center of the home (Brahmasthan) uncluttered and well-lit.');

    final finalScore = score.clamp(70, 96);

    return VastuAnalysisReport(
      overallScore: finalScore,
      entranceDirection: entranceDirection,
      facingDirection: direction,
      summary: 'Property exhibits favorable Vastu alignment with an overall score of $finalScore/100.',
      roomSuggestions: suggestions,
      improvementTips: tips,
    );
  }
}
