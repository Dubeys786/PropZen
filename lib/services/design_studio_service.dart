import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/design_studio_models.dart';
import 'supabase_service.dart';

class DesignStudioService extends ChangeNotifier {
  DesignStudioService._internal() {
    _initDefaultProjects();
  }
  static final DesignStudioService instance = DesignStudioService._internal();
  factory DesignStudioService() => instance;

  final List<DesignProjectModel> _projects = [];
  List<DesignProjectModel> get projects => List.unmodifiable(_projects);

  final List<DesignJobModel> _jobs = [];
  List<DesignJobModel> get jobs => List.unmodifiable(_jobs);

  void _initDefaultProjects() {
    _projects.addAll([
      DesignProjectModel(
        id: 'PRJ-DEFAULT-01',
        userId: 'usr_active',
        title: 'Luxury 3BHK East-Facing Villa',
        projectType: 'Independent Villa',
        plotWidth: 30.0,
        plotLength: 60.0,
        plotArea: 1800.0,
        facingDirection: 'East',
        entranceDirection: 'North-East',
        vastuAnalysis: const VastuAnalysisResult(
          overallScore: 92,
          ratingGrade: 'Excellent (Ishanya & Agni Aligned)',
          directionSummary: 'Auspicious East orientation with optimal sunrise solar illumination.',
          entranceAnalysis: 'Positioned in North-East (Ishanya Pad 3-4), attracting prosperity.',
          kitchenPlacement: 'South-East (Agneya zone) aligned with Vastu fire quadrant.',
          masterBedroomPlacement: 'South-West (Nairutya zone) ensuring stability and sound sleep.',
          livingDiningPlacement: 'North-East open hall maximizing positive prana flow.',
          waterAndPoojaPlacement: 'North-East corner with dedicated marble mandir alcove.',
          favorableAspects: [
            'Maximum window openings on North and East facades.',
            'Heavy structural columns positioned in South and West perimeters.',
          ],
          remediesAndRecommendations: [
            'Maintain lightweight furniture in North-East living lounge.',
          ],
          disclaimer: 'Vastu guidance is advisory and not architectural, structural or legal advice.',
        ),
        rooms: [
          DesignRoomItem(
            id: 'RM-01',
            name: 'Living & Dining Hall',
            roomType: 'living',
            widthFt: 18.0,
            lengthFt: 22.0,
            xPos: 0.05,
            yPos: 0.05,
            doorsCount: 2,
            windowsCount: 3,
            vastuZone: 'North-East',
            color: const Color(0xFF4F46E5),
          ),
          DesignRoomItem(
            id: 'RM-02',
            name: 'Modular Kitchen',
            roomType: 'kitchen',
            widthFt: 12.0,
            lengthFt: 14.0,
            xPos: 0.65,
            yPos: 0.05,
            doorsCount: 1,
            windowsCount: 2,
            vastuZone: 'South-East',
            color: const Color(0xFFE11D48),
          ),
          DesignRoomItem(
            id: 'RM-03',
            name: 'Master Bedroom',
            roomType: 'bedroom',
            widthFt: 16.0,
            lengthFt: 18.0,
            xPos: 0.05,
            yPos: 0.55,
            doorsCount: 1,
            windowsCount: 2,
            vastuZone: 'South-West',
            color: const Color(0xFF059669),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  // =========================================================================
  // 1. CALCULATE VASTU ANALYSIS
  // =========================================================================
  VastuAnalysisResult analyzeVastu(VastuInputModel input) {
    final facing = input.facingDirection.trim().toLowerCase();
    int score = 75;
    String rating = 'Good';

    if (facing.contains('north-east') || facing.contains('east') || facing.contains('north')) {
      score += 17;
      rating = 'Excellent (Auspicious Orientation)';
    } else if (facing.contains('north-west') || facing.contains('west')) {
      score += 8;
      rating = 'Balanced (Vayu / Varuna Zone)';
    } else {
      score += 2;
      rating = 'Action Recommended (Energy Balancing Required)';
    }

    return VastuAnalysisResult(
      overallScore: score,
      ratingGrade: rating,
      directionSummary: 'Calculated for ${input.plotWidth.toStringAsFixed(0)} × ${input.plotLength.toStringAsFixed(0)} ft (${input.plotAreaSqft.toStringAsFixed(0)} sq.ft.) plot with ${input.facingDirection} facing facade.',
      entranceAnalysis: 'Main entrance facing ${input.entranceDirection}. Auspicious energy pathway with natural ventilation.',
      kitchenPlacement: 'Recommended in South-East (Agni corner) or North-West secondary zone.',
      masterBedroomPlacement: 'Recommended in South-West (Nairutya corner) for grounding and restful sleep.',
      livingDiningPlacement: 'Recommended in North-East or East open zone for natural lighting and circulation.',
      waterAndPoojaPlacement: 'Recommended in North-East corner (Ishanya zone).',
      favorableAspects: [
        'Optimal ${input.plotWidth > 25 ? "wide" : "compact"} frontage allowing clear architectural zoning.',
        'High natural light penetration on primary ${input.facingDirection} facade.',
      ],
      remediesAndRecommendations: [
        'Ensure water storage/boring is positioned in North or North-East quadrant.',
        'Keep central Brahmasthan clear of heavy load-bearing structural pillars.',
      ],
      disclaimer: 'Vastu guidance is advisory and not architectural, structural or legal advice.',
    );
  }

  // =========================================================================
  // 2. PROJECT CRUD
  // =========================================================================
  Future<bool> saveProject(DesignProjectModel project) async {
    _projects.removeWhere((p) => p.id == project.id);
    _projects.insert(0, project);
    notifyListeners();
    return true;
  }

  Future<bool> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    notifyListeners();
    return true;
  }

  // =========================================================================
  // 3. ASYNC DESIGN JOBS
  // =========================================================================
  Future<DesignJobModel> createDesignJob({
    required String userId,
    required String jobType,
    String? inputUrl,
    Map<String, dynamic>? parameters,
  }) async {
    final job = DesignJobModel(
      id: 'DJOB-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      jobType: jobType,
      inputUrl: inputUrl,
      parameters: parameters ?? {},
      status: 'PROCESSING',
      createdAt: DateTime.now(),
    );

    _jobs.insert(0, job);
    notifyListeners();
    return job;
  }
}
