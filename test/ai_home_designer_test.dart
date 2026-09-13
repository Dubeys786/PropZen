import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/ai_home_project.dart';
import 'package:dealghar_ncr_10x/services/ai_home_designer_service.dart';
import 'package:dealghar_ncr_10x/theme/responsive_layout.dart';

void main() {
  group('AI Home & Vastu Designer - Models & Parametric Engine', () {
    test('AiHomeProject default initialization and JSON round-trip', () {
      final project = AiHomeProject.defaultProject(name: '20x50 Modern Villa');

      expect(project.projectName, '20x50 Modern Villa');
      expect(project.plotWidth, 20.0);
      expect(project.plotLength, 50.0);
      expect(project.plotUnit, PlotUnit.feet);
      expect(project.roadDirection, CompassDirection.north);
      expect(project.entranceDirection, CompassDirection.northEast);
      expect(project.bedrooms, 3);
      expect(project.formattedPlotDimensions, '20 × 50 ft (1000 sq ft)');
      expect(project.totalPlotAreaSqft, 1000.0);

      final json = project.toMap();
      final revived = AiHomeProject.fromMap(json);

      expect(revived.id, project.id);
      expect(revived.projectName, project.projectName);
      expect(revived.plotWidth, project.plotWidth);
      expect(revived.plotLength, project.plotLength);
      expect(revived.roadDirection, project.roadDirection);
      expect(revived.bedrooms, project.bedrooms);
    });

    test('PropZenParametricEngine generates complete floor plans with Vastu rules', () async {
      final engine = PropZenParametricEngine();
      final project = AiHomeProject.defaultProject(name: 'Vastu Test Project').copyWith(
        plotWidth: 30.0,
        plotLength: 60.0,
        roadDirection: CompassDirection.east,
        entranceDirection: CompassDirection.northEast,
        bedrooms: 4,
        bathrooms: 4,
      );

      final groundFloor = await engine.generateFloorPlan(project);

      expect(groundFloor.floorNumber, 0);
      expect(groundFloor.totalBuiltUpAreaSqft, greaterThan(1000));
      expect(groundFloor.vastuScore, inInclusiveRange(70, 100));
      expect(groundFloor.rooms.isNotEmpty, true);
      expect(groundFloor.vastuInsights.isNotEmpty, true);

      // Verify Vastu zones
      final pooja = groundFloor.rooms.where((r) => r.type == 'pooja');
      if (pooja.isNotEmpty) {
        expect(pooja.first.vastuZone.contains('NE') || pooja.first.vastuZone.contains('Ishanya'), true);
      }

      final kitchen = groundFloor.rooms.where((r) => r.type == 'kitchen');
      if (kitchen.isNotEmpty) {
        expect(kitchen.first.vastuZone.contains('SE') || kitchen.first.vastuZone.contains('Agni'), true);
      }

      final masterBed = groundFloor.rooms.where((r) => r.type == 'bedroom');
      if (masterBed.isNotEmpty) {
        expect(masterBed.first.vastuZone.isNotEmpty, true);
      }
    });

    test('PropZenParametricEngine generates 3 facade elevation variants', () async {
      final engine = PropZenParametricEngine();
      final project = AiHomeProject.defaultProject(name: 'Facade Test Project');
      final facades = await engine.generateFacades(project);

      expect(facades.length, 3);
      expect(facades[0].variantName.contains('Design A'), true);
      expect(facades[1].variantName.contains('Design B'), true);
      expect(facades[2].variantName.contains('Design C'), true);

      for (final f in facades) {
        expect(f.exteriorMaterials.isNotEmpty, true);
        expect(f.lightingHighlights.isNotEmpty, true);
        expect(f.tags.isNotEmpty, true);
      }
    });

    test('PropZenParametricEngine generates room interior specifications', () async {
      final engine = PropZenParametricEngine();
      final project = AiHomeProject.defaultProject(name: 'Interior Test Project');
      final interiors = await engine.generateInteriors(project);

      expect(interiors.length, greaterThanOrEqualTo(4));
      final livingRoom = interiors.firstWhere((i) => i.roomName.contains('Living'));
      expect(livingRoom.furniture.isNotEmpty, true);
      expect(livingRoom.lighting.isNotEmpty, true);
      expect(livingRoom.wallDesign.isNotEmpty, true);
      expect(livingRoom.flooring.isNotEmpty, true);
      expect(livingRoom.ceiling.isNotEmpty, true);
      expect(livingRoom.decor.isNotEmpty, true);
    });

    test('PropZenParametricEngine generates 3D walkthrough keyframes', () async {
      final engine = PropZenParametricEngine();
      final project = AiHomeProject.defaultProject(name: 'Walkthrough Test Project');
      final walkthrough = await engine.generateWalkthrough(project);

      expect(walkthrough.durationSeconds, 45);
      expect(walkthrough.cameraKeyframes.length, greaterThanOrEqualTo(4));
    });

    test('AiHomeDesignerService full generation & project lifecycle', () async {
      final service = AiHomeDesignerService.instance;
      final initial = AiHomeProject.defaultProject(name: 'Lifecycle Test Project');

      // 1. Generate full design
      final generated = await service.generateCompleteDesign(initial);
      expect(generated.status, 'generated');
      expect(generated.floorPlans.isNotEmpty, true);
      expect(generated.facadeDesigns.length, 3);
      expect(generated.interiorDesigns.isNotEmpty, true);
      expect(generated.walkthrough != null, true);

      // 2. Save project
      final saved = await service.saveProject(generated);
      expect(saved, true);

      // 3. Fetch user projects
      final projects = await service.fetchUserProjects(generated.userId);
      expect(projects.any((p) => p.id == generated.id), true);

      // 4. Duplicate project
      final duplicated = await service.duplicateProject(generated);
      expect(duplicated.projectName, '${generated.projectName} (Copy)');
      expect(duplicated.id != generated.id, true);

      // 5. Generate safe share link
      final shareLink = service.generateShareLink(generated);
      expect(shareLink.contains('propzen.ai/share/design/'), true);

      // 6. Delete projects
      await service.deleteProject(duplicated.id);
      await service.deleteProject(generated.id);
    });

    test('Interactive Layout Modifier updates room dimensions', () async {
      final service = AiHomeDesignerService.instance;
      final project = await service.generateCompleteDesign(
        AiHomeProject.defaultProject(name: 'Layout Modify Test'),
      );

      final modified = await service.modifyProjectLayout(
        project,
        'Move kitchen to North-East and make living room bigger',
      );

      expect(modified.status, 'customized');
      expect(modified.floorPlans.first.architecturalNote.contains('Modified based on prompt'), true);
    });
  });

  group('Responsive System Breakpoints', () {
    test('ResponsiveLayout Breakpoints verify mobile, tablet, and desktop bounds', () {
      expect(ResponsiveLayout.mobileBreakpoint, 600.0);
      expect(ResponsiveLayout.tabletBreakpoint, 1024.0);
      expect(ResponsiveLayout.largeDesktopBreakpoint, 1440.0);
      expect(ResponsiveLayout.maxContentWidth, 1280.0);
    });
  });
}
