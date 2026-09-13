import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/visualization_models.dart';

abstract class VisualizationProvider {
  String get providerName;
  bool get isConfigured;

  Future<VisualizationResultModel> generate3dLayout(VisualizationJobModel job);
}

class DefaultIsometric3dProvider implements VisualizationProvider {
  @override
  String get providerName => 'PropZen Built-in 3D Isometric Engine';

  @override
  bool get isConfigured => true;

  @override
  Future<VisualizationResultModel> generate3dLayout(VisualizationJobModel job) async {
    return VisualizationResultModel(
      id: 'VRES-${DateTime.now().millisecondsSinceEpoch}',
      jobId: job.id,
      propertyId: job.propertyId,
      modelUrl: 'https://propzen.ai/models/parametric_villa_twin.glb',
      thumbnailUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
      sceneType: 'isometric_architectural_twin',
      totalFloors: 2,
      cameraPositions: {
        'default': {'x': 45.0, 'y': 30.0, 'zoom': 1.0},
      },
      createdAt: DateTime.now(),
    );
  }
}

class ExternalCloud3dProvider implements VisualizationProvider {
  final bool configured;
  ExternalCloud3dProvider({this.configured = false});

  @override
  String get providerName => 'Cloud 3D Engine (Planner 5D / WebXR Stream)';

  @override
  bool get isConfigured => configured;

  @override
  Future<VisualizationResultModel> generate3dLayout(VisualizationJobModel job) async {
    if (!isConfigured) {
      throw StateError('3D visualization provider is not configured yet.');
    }
    return VisualizationResultModel(
      id: 'VRES-EXT-${DateTime.now().millisecondsSinceEpoch}',
      jobId: job.id,
      modelUrl: 'https://cloud.planner5d.com/v/sample_export.glb',
      createdAt: DateTime.now(),
    );
  }
}

class VisualizationService extends ChangeNotifier {
  VisualizationService._internal();
  static final VisualizationService instance = VisualizationService._internal();
  factory VisualizationService() => instance;

  VisualizationProvider _provider = DefaultIsometric3dProvider();
  VisualizationProvider get activeProvider => _provider;

  void setProvider(VisualizationProvider provider) {
    _provider = provider;
    notifyListeners();
  }

  final List<VisualizationJobModel> _jobs = [];
  List<VisualizationJobModel> get jobs => List.unmodifiable(_jobs);

  Future<VisualizationJobModel> request3dVisualization({
    required String userId,
    String? propertyId,
    String? designId,
    String jobType = '3d_floor_plan',
    Map<String, dynamic>? parameters,
  }) async {
    final job = VisualizationJobModel(
      id: 'VJOB-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      propertyId: propertyId,
      designId: designId,
      jobType: jobType,
      provider: _provider.providerName,
      status: 'PROCESSING',
      parameters: parameters ?? {},
      createdAt: DateTime.now(),
    );

    _jobs.insert(0, job);
    notifyListeners();
    return job;
  }
}
