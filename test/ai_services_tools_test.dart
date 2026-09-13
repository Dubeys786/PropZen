import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/ai_service_tool_data.dart';
import 'package:dealghar_ncr_10x/services/ai_tools_service.dart';
import 'package:dealghar_ncr_10x/widgets/ai_tools/visual_2d_floor_plan_canvas.dart';
import 'package:dealghar_ncr_10x/screens/all_features_screen.dart';
import 'package:dealghar_ncr_10x/screens/ai_tool_detail_screen.dart';

void main() {
  group('AI Services & Tools Comprehensive Unit & Widget Tests', () {
    test('AiServiceRegistry has all required services and categories', () {
      expect(AiServiceRegistry.categories, containsAll([
        'Home Design',
        'Interior Design',
        'Exterior Design',
        'Vastu Consultancy',
        'Property Visualization',
        'Document Verification',
        'Loan Consultancy',
        'Construction Support',
        'Community Forum',
      ]));

      // Verify all 12+ tools exist
      final floorPlan = AiServiceRegistry.getById('ai_floor_plan');
      expect(floorPlan, isNotNull);
      expect(floorPlan!.title, equals('AI Floor Plan'));
      expect(floorPlan.allCategories, contains('Home Design'));

      final homeDesigner = AiServiceRegistry.getById('ai_home_designer');
      expect(homeDesigner, isNotNull);
      expect(homeDesigner!.title, equals('AI Home Designer'));

      final interior = AiServiceRegistry.getById('ai_interior_designer');
      expect(interior, isNotNull);
      expect(interior!.allCategories, contains('Interior Design'));

      final exterior = AiServiceRegistry.getById('ai_facade_designer');
      expect(exterior, isNotNull);
      expect(exterior!.allCategories, contains('Exterior Design'));

      final vastu = AiServiceRegistry.getById('ai_vastu');
      expect(vastu, isNotNull);
      expect(vastu!.allCategories, contains('Vastu Consultancy'));

      final drone = AiServiceRegistry.getById('ai_drone_tour');
      expect(drone, isNotNull);
      expect(drone!.allCategories, contains('Drone Tour'));

      final doc = AiServiceRegistry.getById('ai_document_verification');
      expect(doc, isNotNull);
      expect(doc!.allCategories, contains('Document Verification'));

      final loan = AiServiceRegistry.getById('ai_loan_consultancy');
      expect(loan, isNotNull);
      expect(loan!.allCategories, contains('Loan Consultancy'));

      final construction = AiServiceRegistry.getById('ai_construction_estimator');
      expect(construction, isNotNull);
      expect(construction!.allCategories, contains('Construction Support'));

      final forum = AiServiceRegistry.getById('ai_customer_forum');
      expect(forum, isNotNull);
      expect(forum!.allCategories, contains('Community Forum'));
    });

    test('AiToolsService generates distinct outputs for each tool', () async {
      // 1. Floor Plan
      final fpRes = await AiToolsService.instance.executeTool(
        toolType: 'ai_floor_plan',
        params: {'plotWidth': '30', 'plotLength': '60', 'facing': 'North', 'bedrooms': '3 BHK'},
        delayMs: 0,
      );
      expect(fpRes['status'], equals('success'));
      expect(fpRes['metrics'], isNotNull);
      expect(fpRes['rooms'], isNotNull);
      expect((fpRes['rooms'] as List).isNotEmpty, isTrue);

      // 2. Home Loan
      final loanRes = await AiToolsService.instance.executeTool(
        toolType: 'ai_loan_consultancy',
        params: {'propertyPrice': '2.00', 'downPaymentPct': '20%', 'monthlyIncome': '3.0', 'loanDuration': '20 Years', 'interestRate': '8.50'},
        delayMs: 0,
      );
      expect(loanRes['status'], equals('success'));
      expect(loanRes['monthlyEmi'], isNotNull);
      expect(loanRes['bankOffers'], isNotNull);

      // 3. Construction
      final constRes = await AiToolsService.instance.executeTool(
        toolType: 'ai_construction_estimator',
        params: {'builtUpArea': '2400', 'qualityTier': 'Premium Grade (₹2,150/sq.ft.)'},
        delayMs: 0,
      );
      expect(constRes['status'], equals('success'));
      expect(constRes['totalCost'], isNotNull);
      expect(constRes['breakdown'], isNotNull);

      // 4. Forum
      final forumRes = await AiToolsService.instance.executeTool(
        toolType: 'ai_customer_forum',
        params: {'topicCategory': 'All Topics'},
        delayMs: 0,
      );
      expect(forumRes['status'], equals('success'));
      expect(forumRes['threads'], isNotNull);
    });

    testWidgets('Visual2dFloorPlanCanvas renders correctly with dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Visual2dFloorPlanCanvas(
              plotWidth: 35.0,
              plotLength: 60.0,
              facing: 'North-East',
              floors: 'Double Story (G+1)',
              bhk: '3 BHK',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Vastu Score: 94% Compliant'), findsOneWidget);
      expect(find.text('Save Plan'), findsOneWidget);
    });

    testWidgets('AiToolDetailScreen renders and executes floor plan analysis', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AiToolDetailScreen(toolType: 'ai_floor_plan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Floor Plan'), findsWidgets);
      expect(find.text('Generate 2D Floor Plan'), findsOneWidget);

      // Tap generate button
      await tester.tap(find.text('Generate 2D Floor Plan'));
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Check results
      expect(find.text('AI FLOOR PLAN REPORT'), findsOneWidget);
      expect(find.text('INTERACTIVE 2D CAD'), findsOneWidget);
      expect(find.textContaining('Vastu Score: 94% Compliant'), findsOneWidget);
      expect(find.text('AI-Generated Conceptual Floor Plan'), findsOneWidget);
    });

    testWidgets('AllFeaturesScreen category chip filter switches displayed tools', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state has clean prompt (NO INPUT = NO RESULTS)
      expect(find.text('No results yet'), findsOneWidget);
      expect(find.text('CAD READY'), findsNothing);

      // Tap 'Home Design' chip specifically
      final homeDesignChip = find.widgetWithText(ChoiceChip, 'Home Design');
      await tester.ensureVisible(homeDesignChip);
      await tester.tap(homeDesignChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('CAD READY'), findsOneWidget);
      expect(find.text('LOWEST EMI'), findsNothing);

      // Tap 'Loan Consultancy' chip specifically
      final loanChip = find.widgetWithText(ChoiceChip, 'Loan Consultancy');
      await tester.ensureVisible(loanChip);
      await tester.tap(loanChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('LOWEST EMI'), findsOneWidget);
      expect(find.text('CAD READY'), findsNothing);
    });
  });
}
