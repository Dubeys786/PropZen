import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/ai_service_tool_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Service Hub & Property Separation Tests', () {
    test('1. Default Services State - All 9 Services Present without Prior Input', () {
      final allTools = AiServiceRegistry.allTools;

      // Verify that all 9 required core services exist in registry
      expect(allTools.length, greaterThanOrEqualTo(9));

      final expectedCategories = [
        'Home Design',
        'Interior Design',
        'Exterior Design',
        'Property Visualization',
        'Vastu Consultancy',
        'Document Verification',
        'Loan Consultancy',
        'Construction Support',
        'Drone Tour',
      ];

      for (final cat in expectedCategories) {
        final hasCat = allTools.any((t) =>
            t.primaryCategory.toLowerCase() == cat.toLowerCase() ||
            t.allCategories.any((c) => c.toLowerCase() == cat.toLowerCase()));
        expect(hasCat, isTrue, reason: 'Expected service category "$cat" to be present in default services.');
      }
    });

    test('2. Search Filtering for Vastu, Interior, and Loan', () {
      final allTools = AiServiceRegistry.allTools;

      // Search "Vastu"
      final vastuResults = allTools.where((t) =>
          t.title.toLowerCase().contains('vastu') ||
          t.primaryCategory.toLowerCase().contains('vastu') ||
          t.searchKeywords.any((k) => k.contains('vastu'))).toList();
      expect(vastuResults, isNotEmpty);
      expect(vastuResults.any((t) => t.title.toLowerCase().contains('vastu')), isTrue);

      // Search "Interior"
      final interiorResults = allTools.where((t) =>
          t.title.toLowerCase().contains('interior') ||
          t.primaryCategory.toLowerCase().contains('interior') ||
          t.searchKeywords.any((k) => k.contains('interior'))).toList();
      expect(interiorResults, isNotEmpty);
      expect(interiorResults.any((t) => t.primaryCategory.toLowerCase().contains('interior')), isTrue);

      // Search "Loan"
      final loanResults = allTools.where((t) =>
          t.title.toLowerCase().contains('loan') ||
          t.primaryCategory.toLowerCase().contains('loan') ||
          t.searchKeywords.any((k) => k.contains('loan'))).toList();
      expect(loanResults, isNotEmpty);
      expect(loanResults.any((t) => t.title.toLowerCase().contains('loan')), isTrue);

      // Search non-existent
      final noResults = allTools.where((t) =>
          t.title.toLowerCase().contains('xyznonexistentquery999') ||
          t.searchKeywords.any((k) => k.contains('xyznonexistentquery999'))).toList();
      expect(noResults, isEmpty);
    });

    test('3. Category Filter Chips Exact Matching', () {
      final allTools = AiServiceRegistry.allTools;

      // Filter: Home Design
      final homeDesign = allTools.where((t) =>
          t.primaryCategory == 'Home Design' || t.allCategories.contains('Home Design')).toList();
      expect(homeDesign, isNotEmpty);

      // Filter: Document Verification
      final docVerify = allTools.where((t) =>
          t.primaryCategory == 'Document Verification' || t.allCategories.contains('Document Verification')).toList();
      expect(docVerify, isNotEmpty);
      expect(docVerify.first.id, 'ai_document_verification');

      // Filter: Drone Tour
      final drone = allTools.where((t) =>
          t.primaryCategory == 'Drone Tour' || t.allCategories.contains('Drone Tour')).toList();
      expect(drone, isNotEmpty);
      expect(drone.first.id, 'ai_drone_tour');
    });

    test('4. Property-Specific Tools Data Isolation from Generic Services', () {
      final sample = Property.sampleDeals.first;

      // Property models contain property-specific visualization capability flags
      expect(sample.hasVirtualTour, isTrue);
      expect(sample.has3DModel, isTrue);
      expect(sample.hasArModel, isTrue);
      expect(sample.hasFloorPlan, isTrue);
      expect(sample.hasVastuData, isTrue);

      // Generic services (Loan, Document Check, Drone, BOQ) are separate platform services
      final loanTool = AiServiceRegistry.getById('ai_loan_consultancy');
      final docTool = AiServiceRegistry.getById('ai_document_verification');
      final boqTool = AiServiceRegistry.getById('ai_construction_estimator');

      expect(loanTool, isNotNull);
      expect(docTool, isNotNull);
      expect(boqTool, isNotNull);

      expect(loanTool!.primaryCategory, 'Loan Consultancy');
      expect(docTool!.primaryCategory, 'Document Verification');
      expect(boqTool!.primaryCategory, 'Construction Support');
    });
  });
}
