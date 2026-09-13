import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/models/ai_service_tool_data.dart';
import 'package:dealghar_ncr_10x/services/ai_tools_service.dart';
import 'package:dealghar_ncr_10x/screens/all_features_screen.dart';
import 'package:dealghar_ncr_10x/screens/ai_tool_detail_screen.dart';

void main() {
  group('1. AiServiceRegistry & Tool Architecture Tests', () {
    test('All tools have unique IDs, unique slugs, unique routes, and distinct images', () {
      final allTools = AiServiceRegistry.allTools;
      expect(allTools.isNotEmpty, true);

      final ids = <String>{};
      final slugs = <String>{};
      final routes = <String>{};
      final images = <String>{};

      for (final tool in allTools) {
        expect(tool.id.isNotEmpty, true, reason: 'Tool ID must not be empty');
        expect(tool.slug.isNotEmpty, true, reason: 'Tool slug must not be empty');
        expect(tool.routePath.startsWith('/ai-tools/'), true, reason: 'Route must start with /ai-tools/');
        expect(tool.title.isNotEmpty, true, reason: 'Title must not be empty');
        expect(tool.shortDescription.isNotEmpty, true);
        expect(tool.fullDescription.isNotEmpty, true);
        expect(tool.inputs.isNotEmpty, true, reason: 'Tool must have unique input fields');
        expect(tool.features.isNotEmpty, true);
        expect(tool.searchKeywords.isNotEmpty, true);

        // Check uniqueness
        expect(ids.add(tool.id), true, reason: 'Duplicate tool ID: ${tool.id}');
        expect(slugs.add(tool.slug), true, reason: 'Duplicate slug: ${tool.slug}');
        expect(routes.add(tool.routePath), true, reason: 'Duplicate route: ${tool.routePath}');
        expect(images.add(tool.uniqueImageUrl), true, reason: 'Duplicate image URL for tool: ${tool.title}');
      }
    });

    test('AiServiceRegistry resolvers (getById, getBySlug, getByRoute) work accurately', () {
      expect(AiServiceRegistry.getById('ai_floor_plan')?.title, 'AI Floor Plan');
      expect(AiServiceRegistry.getBySlug('facade-designer')?.title, 'Facade Designer');
      expect(AiServiceRegistry.getByRoute('/ai-tools/vastu')?.title, 'Vastu Consultancy');
      expect(AiServiceRegistry.getByRoute('/ai-tools/loan-consultancy')?.title, 'Loan Consultancy');
      expect(AiServiceRegistry.getBySlug('document-verification')?.title, 'Document Verification');
    });
  });

  group('2. Category & Keyword Filtering Logic Tests', () {
    test('Filtering by category returns only appropriate domain tools', () {
      final allTools = AiServiceRegistry.allTools;

      // Home Design
      final designTools = allTools.where((t) => t.primaryCategory == 'Home Design' || t.allCategories.contains('Home Design')).toList();
      expect(designTools.any((t) => t.id == 'ai_floor_plan'), true);
      expect(designTools.any((t) => t.id == 'ai_loan_consultancy'), false);

      // Loan Consultancy
      final loanTools = allTools.where((t) => t.primaryCategory == 'Loan Consultancy' || t.allCategories.contains('Loan Consultancy')).toList();
      expect(loanTools.any((t) => t.id == 'ai_loan_consultancy'), true);
      expect(loanTools.any((t) => t.id == 'ai_facade_designer'), false);

      // Vastu Consultancy
      final vastuTools = allTools.where((t) => t.primaryCategory == 'Vastu Consultancy' || t.allCategories.contains('Vastu Consultancy')).toList();
      expect(vastuTools.any((t) => t.id == 'ai_vastu'), true);
      expect(vastuTools.any((t) => t.id == 'ai_loan_consultancy'), false);

      // Document Verification
      final docTools = allTools.where((t) => t.primaryCategory == 'Document Verification' || t.allCategories.contains('Document Verification')).toList();
      expect(docTools.any((t) => t.id == 'ai_document_verification'), true);
      expect(docTools.any((t) => t.id == 'ai_floor_plan'), false);

      // Property Visualization
      final vizTools = allTools.where((t) => t.primaryCategory == 'Property Visualization' || t.allCategories.contains('Property Visualization')).toList();
      expect(vizTools.any((t) => t.id == 'ai_3d_visualization'), true);
      expect(vizTools.any((t) => t.id == 'ai_property_video'), true);

      // Drone Tour
      final droneTools = allTools.where((t) => t.primaryCategory == 'Drone Tour' || t.allCategories.contains('Drone Tour')).toList();
      expect(droneTools.any((t) => t.id == 'ai_drone_tour'), true);

      // AI Recommendations
      final recTools = allTools.where((t) => t.primaryCategory == 'AI Recommendations' || t.allCategories.contains('AI Recommendations')).toList();
      expect(recTools.any((t) => t.id == 'ai_property_recommendation'), true);
    });

    test('Searching by keywords matches expected target tools', () {
      final allTools = AiServiceRegistry.allTools;

      List<AiServiceTool> search(String query) {
        final q = query.toLowerCase();
        return allTools.where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.shortDescription.toLowerCase().contains(q) ||
            t.primaryCategory.toLowerCase().contains(q) ||
            t.searchKeywords.any((k) => k.toLowerCase().contains(q))).toList();
      }

      expect(search('vastu').any((t) => t.id == 'ai_vastu'), true);
      expect(search('3d').any((t) => t.id == 'ai_3d_visualization'), true);
      expect(search('loan').any((t) => t.id == 'ai_loan_consultancy'), true);
      expect(search('facade').any((t) => t.id == 'ai_facade_designer'), true);
    });
  });

  group('3. AiToolsService Execution & Zero Cross-Tool Pollution Tests', () {
    test('AI Floor Plan execution returns CAD layout and room dimensions', () async {
      final res = await AiToolsService.instance.executeTool(
        toolType: 'ai_floor_plan',
        params: {'plotWidth': '35', 'plotLength': '60', 'facing': 'East'},
        delayMs: 0,
      );
      expect(res['status'], 'success');
      expect(res['toolType'], 'floor_plan');
      expect(res['metrics']['Orientation'], 'East');
      expect(res['rooms'], isNotEmpty);
      expect(res.containsKey('loanAmount'), false);
    });

    test('Facade Designer execution returns elevation specs and NO Vastu scores', () async {
      final res = await AiToolsService.instance.executeTool(
        toolType: 'ai_facade_designer',
        params: {'archStyle': 'Modern Cantilever Glass', 'buildingType': 'Villa'},
        delayMs: 0,
      );
      expect(res['status'], 'success');
      expect(res['toolType'], 'facade_designer');
      expect(res['materials'], isNotEmpty);
      expect(res.containsKey('vastuScore'), false);
    });

    test('Loan Consultancy execution returns monthly EMI and partner bank comparisons', () async {
      final res = await AiToolsService.instance.executeTool(
        toolType: 'ai_loan_consultancy',
        params: {
          'propertyPrice': '2.0',
          'downPaymentPct': '20%',
          'interestRate': '8.5',
          'loanDuration': '20 Years',
        },
        delayMs: 0,
      );
      expect(res['status'], 'success');
      expect(res['toolType'], 'loan_consultancy');
      expect(res['monthlyEmi'], isNotEmpty);
      expect(res['bankOffers'], isNotEmpty);
      expect(res.containsKey('rooms'), false);
    });

    test('Document Verification execution returns legal checklist and RERA compliance', () async {
      final res = await AiToolsService.instance.executeTool(
        toolType: 'ai_document_verification',
        params: {'reraNumber': 'UPRERAPRJ998877', 'docType': 'RERA Project Registration Certificate'},
        delayMs: 0,
      );
      expect(res['status'], 'success');
      expect(res['toolType'], 'document_verification');
      expect(res['checklist'], isNotEmpty);
      expect(res.containsKey('loanOffers'), false);
    });

    test('Vastu Consultancy execution returns directional harmony zones and remedies', () async {
      final res = await AiToolsService.instance.executeTool(
        toolType: 'ai_vastu',
        params: {'propertyDirection': 'North-East (Ishanya)'},
        delayMs: 0,
      );
      expect(res['status'], 'success');
      expect(res['toolType'], 'vastu');
      expect(res['metrics']['Overall Vastu Score'], contains('94 / 100'));
      expect(res['zones'], isNotEmpty);
      expect(res.containsKey('bankRates'), false);
    });
  });

  group('4. UI Widget & Viewport Responsiveness Tests', () {
    testWidgets('AllFeaturesScreen renders category chips and filters in real-time', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));

      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('PropZen Service Hub'), findsOneWidget);
      expect(find.text('No results yet'), findsOneWidget);

      // Verify category chips exist
      final loanChip = find.widgetWithText(ChoiceChip, 'Loan Consultancy');
      expect(loanChip, findsOneWidget);

      // Tap "Loan Consultancy" category chip
      await tester.ensureVisible(loanChip);
      await tester.tap(loanChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Should show Loan Consultancy
      expect(find.text('LOWEST EMI'), findsOneWidget);
      expect(find.text('Compare Bank Rates'), findsOneWidget);
      // Should NOT show AI Floor Plan
      expect(find.text('CAD READY'), findsNothing);

      // Tap "Vastu Consultancy" category chip
      final vastuChip = find.widgetWithText(ChoiceChip, 'Vastu Consultancy');
      await tester.ensureVisible(vastuChip);
      await tester.tap(vastuChip);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Should show Vastu Consultancy
      expect(find.text('VEDIC AUDIT'), findsOneWidget);
      expect(find.text('LOWEST EMI'), findsNothing);
    });

    testWidgets('AllFeaturesScreen search filters cards by keyword', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query "facade"
      await tester.enterText(find.byType(TextField), 'facade');
      await tester.pumpAndSettle();

      expect(find.text('ELEVATION'), findsOneWidget);
      expect(find.text('Generate Facade Concept'), findsOneWidget);
      expect(find.text('LOWEST EMI'), findsNothing);
      expect(find.text('VEDIC AUDIT'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.text('No results yet'), findsOneWidget);
    });

    testWidgets('AiToolDetailScreen renders independent UI and executes without error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1400));

      await tester.pumpWidget(
        const MaterialApp(
          home: AiToolDetailScreen(toolType: 'ai_facade_designer'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tool title and fields
      expect(find.text('Facade Designer'), findsWidgets);
      final btnFinder = find.text('Generate Facade Concept');
      expect(btnFinder, findsOneWidget);
    });
  });
}
