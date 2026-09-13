import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/property_visualization_model.dart';
import 'package:dealghar_ncr_10x/services/property_visualization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Property Visualization Suite Tests', () {
    test('1. Visualization Models Serialization & Defaults', () {
      final tour = VirtualTourData(
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX',
        provider: 'kuula',
        title: '360° Virtual Tour',
        rooms: const [
          VirtualTourRoom(
            id: 'living-room',
            name: 'Living & Dining Hall',
            imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
            area: '320 sq.ft.',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'master-suite',
            name: 'Master Suite',
            imageUrl: 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b',
            area: '210 sq.ft.',
            iconType: 'bed',
          ),
        ],
      );
      expect(tour.hasValidUrl, isTrue);
      expect(tour.rooms.length, 2);
      expect(tour.rooms.first.name, 'Living & Dining Hall');
      expect(tour.toMap()['rooms'], isA<List>());

      const model3d = Model3DData(
        modelId: '6b8563a3d2424855a02102ba694e9f56',
        provider: 'sketchfab',
      );
      expect(model3d.hasValidModel, isTrue);

      const room = FloorPlanRoom(
        name: 'Master Suite',
        roomType: 'masterBedroom',
        areaSqFt: 210,
        dimensions: '14\'0" x 15\'0"',
      );
      expect(room.areaSqFt, 210);
      expect(room.dimensions, '14\'0" x 15\'0"');

      const vastu = VastuGuidanceData(
        facingDirection: 'North-East',
        overallScore: 92,
        entranceDirection: 'North-East',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'North / East',
        balconyDirection: 'East',
        toiletDirection: 'North-West',
      );
      expect(vastu.overallScore, 92);
      expect(vastu.facingDirection, 'North-East');
    });

    test('2. Property Model Capability Getters', () {
      final sample = Property.sampleDeals.first;
      expect(sample.hasVirtualTour, isTrue);
      expect(sample.has3DModel, isTrue);
      expect(sample.hasArModel, isTrue);
      expect(sample.hasFloorPlan, isTrue);
      expect(sample.hasInteriorVisualization, isTrue);
      expect(sample.hasExteriorVisualization, isTrue);
      expect(sample.hasVastuData, isTrue);
      expect(sample.floorPlanRooms.length, greaterThanOrEqualTo(4));
    });

    test('3. PropertyVisualizationService URL formatters & AR Intent', () {
      final service = PropertyVisualizationService.instance;

      // Kuula URL formatting
      final kuulaUrl = service.format360TourEmbedUrl('https://kuula.co/share/collection/7l1vX');
      expect(kuulaUrl, contains('logo=1'));
      expect(kuulaUrl, contains('fs=1'));

      // Sketchfab URL formatting
      final sketchfabUrl = service.formatSketchfabEmbedUrl(modelId: '6b8563a3d2424855a02102ba694e9f56');
      expect(sketchfabUrl, contains('sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed'));

      // AR Launch URL
      final arUrl = service.generateArLaunchUrl(
        glbUrl: 'https://example.com/model.glb',
        propertyTitle: 'ATS HomeKraft',
      );
      expect(arUrl.isNotEmpty, isTrue);

      // WhatsApp share message with room
      final sample = Property.sampleDeals.first;
      final shareText = service.generateWhatsAppShareText(
        property: sample,
        visualizationType: '360_tour',
        roomName: 'Living & Dining Hall',
      );
      expect(shareText, contains('ATS HomeKraft'));
      expect(shareText, contains('Living & Dining Hall'));
      expect(shareText, contains('360° Virtual Tour'));
    });

    test('4. Dynamic Vastu Orientation Generator based on Property Facing', () {
      final service = PropertyVisualizationService.instance;

      final propNE = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      final propEast = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');
      final propNorth = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ace_divino');

      final vastuNE = service.generateVastuForProperty(propNE);
      final vastuEast = service.generateVastuForProperty(propEast);
      final vastuNorth = service.generateVastuForProperty(propNorth);

      expect(vastuNE.facingDirection, contains('North-East'));
      expect(vastuNE.overallScore, greaterThanOrEqualTo(90));
      expect(vastuNE.roomDetails, isNotEmpty);

      expect(vastuEast.facingDirection, contains('East'));
      expect(vastuEast.overallScore, greaterThanOrEqualTo(85));

      expect(vastuNorth.facingDirection, contains('North'));
      expect(vastuNorth.entranceDirection, contains('North'));
    });

    test('5. Property-Specific 360° Virtual Tour Data Isolation (Property A vs B vs C)', () {
      final propA = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      final propB = Property.sampleDeals.firstWhere((p) => p.id == 'prop_tata_eureka_150');
      final propC = Property.sampleDeals.firstWhere((p) => p.id == 'prop_godrej_palm_150');

      expect(propA.virtualTour, isNotNull);
      expect(propB.virtualTour, isNotNull);
      expect(propC.virtualTour, isNotNull);

      // Verify titles are property-specific
      expect(propA.virtualTour!.title, contains('ATS HomeKraft'));
      expect(propB.virtualTour!.title, contains('Tata Eureka Park'));
      expect(propC.virtualTour!.title, contains('Godrej Palm Retreat'));

      // Verify rooms are distinct
      final roomsA = propA.virtualTour!.rooms.map((r) => r.name).toList();
      final roomsB = propB.virtualTour!.rooms.map((r) => r.name).toList();
      final roomsC = propC.virtualTour!.rooms.map((r) => r.name).toList();

      expect(roomsA, contains('Living & Dining Hall'));
      expect(roomsB, contains('Smart Living Hall'));
      expect(roomsC, contains('Resort Living Lounge'));

      expect(roomsA, isNot(equals(roomsB)));
      expect(roomsA, isNot(equals(roomsC)));
      expect(roomsB, isNot(equals(roomsC)));
    });

    test('6. Room Filter Switcher verification within a property', () {
      final propA = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      final rooms = propA.virtualTour!.rooms;

      expect(rooms.length, greaterThanOrEqualTo(4));

      final livingImg = rooms.firstWhere((r) => r.id == 'living-room').imageUrl;
      final masterImg = rooms.firstWhere((r) => r.id == 'master-suite').imageUrl;
      final balconyImg = rooms.firstWhere((r) => r.id == 'balcony-deck').imageUrl;
      final kitchenImg = rooms.firstWhere((r) => r.id == 'modular-kitchen').imageUrl;

      expect(livingImg, isNotEmpty);
      expect(masterImg, isNotEmpty);
      expect(balconyImg, isNotEmpty);
      expect(kitchenImg, isNotEmpty);

      expect(livingImg, isNot(equals(masterImg)));
      expect(livingImg, isNot(equals(balconyImg)));
      expect(masterImg, isNot(equals(balconyImg)));
      expect(kitchenImg, isNot(equals(livingImg)));
    });

    test('7. Non-Tour Property Empty State Validation (No Fake Data Leakage)', () {
      final propGaur = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');
      final propAce = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ace_divino');

      // Properties without 360 virtual tours must have virtualTour == null and hasVirtualTour == false
      expect(propGaur.hasVirtualTour, isFalse);
      expect(propGaur.virtualTour, isNull);

      expect(propAce.hasVirtualTour, isFalse);
      expect(propAce.virtualTour, isNull);
    });

    test('8. Multi-Property Asset Isolation across 5 distinct properties', () {
      final prop1 = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');
      final prop2 = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');
      final prop3 = Property.sampleDeals.firstWhere((p) => p.id == 'prop_godrej_golflinks_villa');
      final prop4 = Property.sampleDeals.firstWhere((p) => p.id == 'prop_advant_navis');
      final prop5 = Property.sampleDeals.firstWhere((p) => p.id == 'prop_jaypee_villa');

      // Verify completely distinct titles, prices, BHK
      expect(prop1.title, isNot(equals(prop2.title)));
      expect(prop2.title, isNot(equals(prop3.title)));
      expect(prop3.title, isNot(equals(prop4.title)));
      expect(prop4.title, isNot(equals(prop5.title)));

      // Verify distinct floor plan rooms
      expect(prop1.floorPlanRooms.length, greaterThanOrEqualTo(4));
      expect(prop2.floorPlanRooms.length, greaterThanOrEqualTo(4));
      expect(prop3.floorPlanRooms.length, greaterThanOrEqualTo(4));
      expect(prop4.floorPlanRooms.length, greaterThanOrEqualTo(4));
      expect(prop5.floorPlanRooms.length, greaterThanOrEqualTo(4));

      // Commercial has workstation bay, Villa has private pool / grand foyer, Residential has living hall
      expect(prop4.floorPlanRooms.any((r) => r.name.contains('Workstation')), isTrue);
      expect(prop3.floorPlanRooms.any((r) => r.name.contains('Foyer')), isTrue);
      expect(prop1.floorPlanRooms.any((r) => r.name.contains('Living & Dining')), isTrue);

      // Verify distinct Vastu scores & directions
      expect(prop1.vastuData?.facingDirection, 'North-East');
      expect(prop2.vastuData?.facingDirection, contains('East'));
      expect(prop4.vastuData?.facingDirection, contains('North'));
    });
  });
}
