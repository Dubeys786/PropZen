import 'package:flutter/foundation.dart';
import '../models/construction_model.dart';
import '../models/property.dart';

class ConstructionService extends ChangeNotifier {
  ConstructionService._internal() {
    _initDefaultProjects();
  }
  static final ConstructionService instance = ConstructionService._internal();
  factory ConstructionService() => instance;

  final Map<String, ConstructionProjectModel> _projects = {};

  void _initDefaultProjects() {
    final now = DateTime.now();
    _projects['prop_mahagun'] = ConstructionProjectModel(
      projectId: 'proj_mahagun_01',
      propertyId: 'prop_mahagun',
      projectName: 'Mahagun Manorialle Luxury Tower',
      builderName: 'Mahagun India Ltd',
      overallProgress: 76.5,
      currentPhase: ConstructionPhase.electrical,
      startDate: now.subtract(const Duration(days: 450)),
      expectedCompletionDate: now.add(const Duration(days: 210)),
      lastUpdatedAt: now.subtract(const Duration(days: 3)),
      nextMilestone: 'Tower A 28th Floor High-Voltage Electrical Conduiting',
      updates: [
        ConstructionUpdateModel(
          updateId: 'up_01',
          projectId: 'proj_mahagun_01',
          phase: ConstructionPhase.structure,
          title: 'Tower A & B RCC Superstructure Completed',
          description: 'All 34 residential floors casting completed and certified by third-party structural audit team.',
          progressPercentage: 100.0,
          photos: [
            'https://images.unsplash.com/photo-1541888946425-d0fbb18f15f6?w=600',
            'https://images.unsplash.com/photo-1590486803833-1c5dc8ddd4c8?w=600',
          ],
          uploadedBy: 'Er. Sandeep Tyagi (Lead Site Engineer)',
          verifiedBy: 'Quality Assurance Board',
          verificationStatus: 'APPROVED',
          capturedAt: now.subtract(const Duration(days: 20)),
          createdAt: now.subtract(const Duration(days: 19)),
        ),
        ConstructionUpdateModel(
          updateId: 'up_02',
          projectId: 'proj_mahagun_01',
          phase: ConstructionPhase.brickwork,
          title: 'Internal AAC Block Masonry Completed till 30th Floor',
          description: 'Precision autoclaved aerated concrete blocks placed with crack-resistant polymer mortar.',
          progressPercentage: 92.0,
          photos: [
            'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=600',
          ],
          uploadedBy: 'Er. Sandeep Tyagi (Lead Site Engineer)',
          verifiedBy: 'Mahagun Quality Audit',
          verificationStatus: 'APPROVED',
          capturedAt: now.subtract(const Duration(days: 10)),
          createdAt: now.subtract(const Duration(days: 9)),
        ),
        ConstructionUpdateModel(
          updateId: 'up_03',
          projectId: 'proj_mahagun_01',
          phase: ConstructionPhase.electrical,
          title: 'Concealed Conduit Laying & Main DB Installation in Progress',
          description: 'Fire-resistant conduit installation ongoing across floors 18 to 26. Copper grounding verified.',
          progressPercentage: 68.0,
          photos: [
            'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600',
          ],
          uploadedBy: 'Er. Sandeep Tyagi (Lead Site Engineer)',
          verifiedBy: 'Mahagun Quality Audit',
          verificationStatus: 'APPROVED',
          capturedAt: now.subtract(const Duration(days: 3)),
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ],
    );
  }

  ConstructionProjectModel getProjectForProperty(Property property) {
    if (_projects.containsKey(property.id)) {
      return _projects[property.id]!;
    }

    final now = DateTime.now();
    final proj = ConstructionProjectModel(
      projectId: 'proj_${property.id}',
      propertyId: property.id,
      projectName: property.title,
      builderName: property.builderName.isNotEmpty ? property.builderName : 'Authorized Developer',
      overallProgress: 65.0,
      currentPhase: ConstructionPhase.brickwork,
      startDate: now.subtract(const Duration(days: 300)),
      expectedCompletionDate: now.add(const Duration(days: 360)),
      lastUpdatedAt: now.subtract(const Duration(days: 5)),
      nextMilestone: 'Superstructure Slab Casting Milestone',
      updates: [
        ConstructionUpdateModel(
          updateId: 'up_default_1',
          projectId: 'proj_${property.id}',
          phase: ConstructionPhase.foundation,
          title: 'Deep Pile Raft Foundation Completed',
          description: 'Substructure engineering verified with soil stability index certification.',
          progressPercentage: 100.0,
          photos: [
            'https://images.unsplash.com/photo-1541888946425-d0fbb18f15f6?w=600',
          ],
          uploadedBy: 'Certified Structural Engineer',
          verifiedBy: 'Quality Assurance Board',
          verificationStatus: 'APPROVED',
          capturedAt: now.subtract(const Duration(days: 30)),
          createdAt: now.subtract(const Duration(days: 29)),
        ),
      ],
    );

    _projects[property.id] = proj;
    return proj;
  }

  void submitEngineerUpdate({
    required String projectId,
    required ConstructionPhase phase,
    required String title,
    required String description,
    required double progress,
    required List<String> photos,
    required String engineerName,
  }) {
    final update = ConstructionUpdateModel(
      updateId: 'up_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      phase: phase,
      title: title,
      description: description,
      progressPercentage: progress,
      photos: photos,
      uploadedBy: engineerName,
      verificationStatus: 'APPROVED', // Admin verified in demo flow
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    for (final k in _projects.keys) {
      if (_projects[k]!.projectId == projectId) {
        final old = _projects[k]!;
        final list = List<ConstructionUpdateModel>.from(old.updates)..insert(0, update);
        _projects[k] = ConstructionProjectModel(
          projectId: old.projectId,
          propertyId: old.propertyId,
          projectName: old.projectName,
          builderName: old.builderName,
          overallProgress: progress > old.overallProgress ? progress : old.overallProgress,
          currentPhase: phase,
          startDate: old.startDate,
          expectedCompletionDate: old.expectedCompletionDate,
          lastUpdatedAt: DateTime.now(),
          nextMilestone: old.nextMilestone,
          updates: list,
        );
        break;
      }
    }
    notifyListeners();
  }
}
