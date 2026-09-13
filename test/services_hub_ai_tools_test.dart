import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/ai_service_tool_data.dart';
import 'package:dealghar_ncr_10x/services/ai_tools_service.dart';
import 'package:dealghar_ncr_10x/screens/all_features_screen.dart';
import 'package:dealghar_ncr_10x/screens/ai_tool_detail_screen.dart';
import 'package:dealghar_ncr_10x/screens/ai_home_designer_wizard_screen.dart';
import 'package:dealghar_ncr_10x/models/ai_home_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('24-Tool AI Services Hub & Result Depth Test Suite', () {
    // 1. Tool Registry Uniqueness & Completeness
    test('1. Exactly 24 AI tools exist with 100% unique IDs, titles, and unique image URLs', () {
      final tools = AiServiceRegistry.allTools;
      expect(tools.length, equals(24));

      final idSet = <String>{};
      final titleSet = <String>{};
      final imageUrlSet = <String>{};

      for (final tool in tools) {
        expect(tool.id.isNotEmpty, isTrue);
        expect(tool.title.isNotEmpty, isTrue);
        expect(tool.shortDescription.isNotEmpty, isTrue);
        expect(tool.fullDescription.isNotEmpty, isTrue);
        expect(tool.features.isNotEmpty, isTrue);
        expect(tool.badgeLabel.isNotEmpty, isTrue);
        expect(tool.uniqueImageUrl.startsWith('http'), isTrue);

        // Verify uniqueness
        expect(idSet.add(tool.id), isTrue, reason: 'Duplicate tool ID: ${tool.id}');
        expect(titleSet.add(tool.title), isTrue, reason: 'Duplicate tool Title: ${tool.title}');
        expect(imageUrlSet.add(tool.uniqueImageUrl), isTrue, reason: 'Duplicate tool Image: ${tool.uniqueImageUrl}');
      }
    });

    // 2. All 5 Categories are populated
    test('2. All categories have assigned AI tools', () {
      final categories = [
        'Design & 3D',
        'Discovery & Advisory',
        'Investment & Finance',
        'Legal & Verification',
        'Dealer & Marketing',
      ];

      for (final cat in categories) {
        final matching = AiServiceRegistry.allTools.where((t) => t.category == cat).toList();
        expect(matching.isNotEmpty, isTrue, reason: 'Category $cat has no tools');
      }
    });

    // 3. AiToolsService executes all 24 tools with structured parametric responses
    test('3. AiToolsService executes all 24 tools producing valid metrics, recommendations, and disclaimers', () async {
      for (final tool in AiServiceRegistry.allTools) {
        final res = await AiToolsService.instance.executeTool(
          toolType: tool.id,
          params: {for (final inp in tool.inputs) inp.key: inp.defaultValue},
          delayMs: 0,
        );

        expect(res['status'], equals('success'));
        expect(res['metrics'], isNotNull);
        expect(res['summary'], isNotNull);
        expect(res['previewUrl'], isNotNull);
        expect(res['disclaimer'], isNotNull);

        final recommendations = res['recommendations'] as List<dynamic>?;
        expect(recommendations, isNotNull);
        expect(recommendations!.isNotEmpty, isTrue);
      }
    });

    // 4. AllFeaturesScreen renders 24 tools and supports Category Filter Chips
    testWidgets('4. AllFeaturesScreen renders responsive grid and filters by category', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('AI Services & Tools'), findsOneWidget);
      expect(find.text('Smart AI tools to help you discover, design, verify and invest in property.'), findsOneWidget);
      expect(find.text('24 ADVANCED AI ENGINES'), findsOneWidget);

      // Verify category chips exist
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Design & 3D'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Discovery & Advisory'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Investment & Finance'), findsOneWidget);

      // Filter by 'Investment & Finance'
      await tester.tap(find.widgetWithText(ChoiceChip, 'Investment & Finance'));
      await tester.pumpAndSettle();

      expect(find.text('AI Property Valuator'), findsOneWidget);
      expect(find.text('AI Investment Analyzer'), findsOneWidget);
      expect(find.text('AI Loan & EMI Consultant'), findsOneWidget);
    });

    // 5. AllFeaturesScreen Search bar filters tools
    testWidgets('5. AllFeaturesScreen search bar finds tools by keyword', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Vastu');
      await tester.pumpAndSettle();

      expect(find.text('AI Vastu Consultant'), findsOneWidget);
      expect(find.text('AI Property Valuator'), findsNothing);
    });

    // 6. AiToolDetailScreen renders dynamic inputs and executes analysis
    testWidgets('6. AiToolDetailScreen renders hero banner, dynamic inputs and executes report', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: AiToolDetailScreen(toolType: 'ai_interior_designer'),
        ),
      );
      await tester.pumpAndSettle();

      // Tool title & guidance
      expect(find.text('AI Interior Designer'), findsWidgets);
      expect(find.text('How AI Interior Designer Works'), findsOneWidget);

      final genBtn = find.text('Generate Interior Concept');
      expect(genBtn, findsOneWidget);
      await tester.ensureVisible(genBtn);
      await tester.pumpAndSettle();

      // Trigger analysis
      await tester.tap(genBtn);
      await tester.pumpAndSettle(); // Finish calculation

      // Result screen components
      expect(find.text('AI INTELLIGENCE REPORT'), findsOneWidget);
      expect(find.text('AI Summary'), findsOneWidget);
      expect(find.text('Key Intelligence Metrics'), findsOneWidget);
      expect(find.text('Curated Color Palette'), findsOneWidget);
      expect(find.text('Recommended Materials & Finishes'), findsOneWidget);
      expect(find.text('AI Recommendations'), findsOneWidget);
      expect(find.text('Consult Expert'), findsOneWidget);
      expect(find.text('Run Again'), findsOneWidget);
    });

    // 7. AI Home Designer Wizard Step 9 displays full structured result specification
    testWidgets('7. AI Home Designer Wizard Step 9 displays AI DESIGN RESULT, insights, materials, and recommendations', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final project = AiHomeProject(
        id: 'PROJ-TEST-101',
        userId: 'USER-1',
        projectName: 'Villa Vista',
        plotLength: 50,
        plotWidth: 25,
        roadDirection: CompassDirection.north,
        entranceDirection: CompassDirection.northEast,
        bedrooms: 3,
        bathrooms: 3,
        floors: FloorOption.gPlus1,
        designStyle: HomeDesignStyle.modern,
        budgetRange: '₹ 45L - ₹ 65L',
        status: 'completed',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AiHomeDesignerWizardScreen(initialProject: project, initialStep: 8),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AI DESIGN RESULT specification
      expect(find.text('AI DESIGN RESULT'), findsOneWidget);
      expect(find.text('100% VASTU COMPLIANT'), findsOneWidget);
      expect(find.text('AI Design Summary'), findsOneWidget);
      expect(find.text('DESIGN INSIGHTS'), findsOneWidget);
      expect(find.text('Space Optimization: '), findsOneWidget);
      expect(find.text('RECOMMENDED MATERIALS'), findsOneWidget);
      expect(find.text('AI RECOMMENDATIONS'), findsOneWidget);
      expect(find.text('Use concealed storage to maximize floor area.'), findsOneWidget);
      expect(find.text('Save Design'), findsOneWidget);
      expect(find.text('Consult Expert'), findsOneWidget);
      expect(find.text('Generate Another'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
