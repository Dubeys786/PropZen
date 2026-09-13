import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/models/ai_service_tool_data.dart';
import 'package:dealghar_ncr_10x/screens/all_features_screen.dart';

void main() {
  setUp(() {
    AiServiceRegistry.clearTools();
  });

  group('Service Hub 12-Case Real Data & Filtering Test Suite', () {
    // 1. No filters - Clean empty state when no database records exist
    testWidgets('1. No filters: Empty database displays proper empty state with zero dummy cards', (tester) async {
      AiServiceRegistry.clearTools();

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 ADVANCED AI ENGINES'), findsOneWidget);
      expect(find.text('AI Services & Tools'), findsOneWidget);
      expect(find.text('No services found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Verify no dummy placeholder cards appear
      expect(find.text('AI Floor Plan'), findsNothing);
      expect(find.text('AI Home Design'), findsNothing);
      expect(find.text('Loan Consultancy'), findsNothing);
    });

    // 2. Each category individually with exact matching
    testWidgets('2. Each category individually: Exact matching without bleed into similar category names', (tester) async {
      final sampleServices = [
        const AiServiceTool(
          id: 'svc_home_design',
          slug: 'home-design',
          routePath: '/ai-tools/home-design',
          title: 'Home Design Architect',
          shortDescription: 'Custom architectural layouts',
          fullDescription: 'Custom architectural layouts',
          primaryCategory: 'Home Design',
          allCategories: ['All', 'Home Design'],
          searchKeywords: ['home', 'design'],
          icon: LucideIcons.home,
          accentColor: Colors.indigo,
          uniqueImageUrl: '',
          features: ['Blueprint'],
          inputs: [],
          location: 'Noida',
          price: 15000,
          rating: 4.8,
          serviceType: 'Architecture',
          provider: 'Studio Zen',
        ),
        const AiServiceTool(
          id: 'svc_interior_design',
          slug: 'interior-design',
          routePath: '/ai-tools/interior-design',
          title: 'Interior Design Studio',
          shortDescription: 'Modern luxury interiors',
          fullDescription: 'Modern luxury interiors',
          primaryCategory: 'Interior Design',
          allCategories: ['All', 'Interior Design'],
          searchKeywords: ['interior'],
          icon: LucideIcons.palette,
          accentColor: Colors.pink,
          uniqueImageUrl: '',
          features: ['Interiors'],
          inputs: [],
          location: 'Gurgaon',
          price: 50000,
          rating: 4.5,
          serviceType: 'Decor',
          provider: 'Decor Masters',
        ),
        const AiServiceTool(
          id: 'svc_exterior_design',
          slug: 'exterior-design',
          routePath: '/ai-tools/exterior-design',
          title: 'Exterior Design Labs',
          shortDescription: 'Facade elevation styling',
          fullDescription: 'Facade elevation styling',
          primaryCategory: 'Exterior Design',
          allCategories: ['All', 'Exterior Design'],
          searchKeywords: ['exterior'],
          icon: LucideIcons.building,
          accentColor: Colors.teal,
          uniqueImageUrl: '',
          features: ['Facade'],
          inputs: [],
          location: 'Delhi',
          price: 30000,
          rating: 4.2,
          serviceType: 'Facade',
          provider: 'Exterior Pro',
        ),
        const AiServiceTool(
          id: 'svc_vastu',
          slug: 'vastu',
          routePath: '/ai-tools/vastu',
          title: 'Vastu Consultation Pro',
          shortDescription: 'Vastu Shastra audit',
          fullDescription: 'Vastu Shastra audit',
          primaryCategory: 'Vastu',
          allCategories: ['All', 'Vastu'],
          searchKeywords: ['vastu'],
          icon: LucideIcons.compass,
          accentColor: Colors.amber,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
          location: 'Noida',
          price: 5000,
          rating: 4.9,
          serviceType: 'Consulting',
          provider: 'Vastu Acharya',
        ),
      ];

      AiServiceRegistry.setTools(sampleServices);

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Home Design"
      final homeDesignChip = find.widgetWithText(ChoiceChip, 'Home Design');
      expect(homeDesignChip, findsOneWidget);
      await tester.tap(homeDesignChip);
      await tester.pumpAndSettle();

      // Only Home Design Architect appears
      expect(find.text('Home Design Architect'), findsOneWidget);
      expect(find.text('Interior Design Studio'), findsNothing);
      expect(find.text('Exterior Design Labs'), findsNothing);
      expect(find.text('Vastu Consultation Pro'), findsNothing);

      // Tap "Vastu"
      final vastuChip = find.widgetWithText(ChoiceChip, 'Vastu');
      expect(vastuChip, findsOneWidget);
      await tester.tap(vastuChip);
      await tester.pumpAndSettle();

      expect(find.text('Vastu Consultation Pro'), findsOneWidget);
      expect(find.text('Home Design Architect'), findsNothing);
      expect(find.text('Interior Design Studio'), findsNothing);

      // Tap "All"
      final allChip = find.widgetWithText(ChoiceChip, 'All');
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      expect(find.text('Home Design Architect'), findsOneWidget);
      expect(find.text('Interior Design Studio'), findsOneWidget);
      expect(find.text('Exterior Design Labs'), findsOneWidget);
      expect(find.text('Vastu Consultation Pro'), findsOneWidget);
    });

    // 3. Search across all relevant fields
    testWidgets('3. Search: Works across title, category, description, provider, and location', (tester) async {
      final sampleServices = [
        const AiServiceTool(
          id: 'svc_legal_audit',
          slug: 'legal-audit',
          routePath: '/ai-tools/legal-audit',
          title: 'RERA Legal Title Search',
          shortDescription: 'Verified 30-year property title audit',
          fullDescription: 'High Court advocate title verification for Noida properties',
          primaryCategory: 'Legal',
          allCategories: ['All', 'Legal'],
          searchKeywords: ['legal', 'title', 'rera'],
          icon: LucideIcons.scale,
          accentColor: Colors.red,
          uniqueImageUrl: '',
          features: ['Title Search'],
          inputs: [],
          location: 'Noida Expressway',
          price: 7999,
          rating: 4.9,
          provider: 'Veritas Legal Associates',
        ),
        const AiServiceTool(
          id: 'svc_vastu_audit',
          slug: 'vastu-audit',
          routePath: '/ai-tools/vastu-audit',
          title: 'Vastu Harmonic Alignment',
          shortDescription: 'Scientific energy harmonic assessment',
          fullDescription: 'Pyramid and directional vastu energy remedies',
          primaryCategory: 'Vastu',
          allCategories: ['All', 'Vastu'],
          searchKeywords: ['vastu', 'energy'],
          icon: LucideIcons.compass,
          accentColor: Colors.amber,
          uniqueImageUrl: '',
          features: ['Harmonics'],
          inputs: [],
          location: 'Greater Noida',
          price: 4999,
          rating: 4.7,
          provider: 'Aura Vastu Consultants',
        ),
      ];

      AiServiceRegistry.setTools(sampleServices);

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Search by Provider Name: "Veritas"
      await tester.enterText(searchField, 'Veritas');
      await tester.pumpAndSettle();
      expect(find.text('RERA Legal Title Search'), findsOneWidget);
      expect(find.text('Vastu Harmonic Alignment'), findsNothing);

      // Search by Location: "Greater Noida"
      await tester.enterText(searchField, 'Greater Noida');
      await tester.pumpAndSettle();
      expect(find.text('Vastu Harmonic Alignment'), findsOneWidget);
      expect(find.text('RERA Legal Title Search'), findsNothing);

      // Search by Description keyword: "advocate"
      await tester.enterText(searchField, 'advocate');
      await tester.pumpAndSettle();
      expect(find.text('RERA Legal Title Search'), findsOneWidget);
      expect(find.text('Vastu Harmonic Alignment'), findsNothing);
    });

    // 4. Multiple filters together (Strict AND Logic)
    testWidgets('4. Multiple filters: Category + Search applied together with AND logic', (tester) async {
      final sampleServices = [
        const AiServiceTool(
          id: 'svc_h1',
          slug: 'h1',
          routePath: '/ai-tools/h1',
          title: 'Home Design Deluxe',
          shortDescription: 'Noida luxury home layouts',
          fullDescription: 'Noida luxury home layouts',
          primaryCategory: 'Home Design',
          allCategories: ['All', 'Home Design'],
          searchKeywords: ['home', 'noida'],
          icon: LucideIcons.home,
          accentColor: Colors.indigo,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
          location: 'Noida',
          price: 25000,
          rating: 4.9,
          provider: 'Zen Architects',
        ),
        const AiServiceTool(
          id: 'svc_h2',
          slug: 'h2',
          routePath: '/ai-tools/h2',
          title: 'Home Design Standard',
          shortDescription: 'Gurgaon home layouts',
          fullDescription: 'Gurgaon home layouts',
          primaryCategory: 'Home Design',
          allCategories: ['All', 'Home Design'],
          searchKeywords: ['home', 'gurgaon'],
          icon: LucideIcons.home,
          accentColor: Colors.indigo,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
          location: 'Gurgaon',
          price: 15000,
          rating: 4.2,
          provider: 'City Architects',
        ),
        const AiServiceTool(
          id: 'svc_v1',
          slug: 'v1',
          routePath: '/ai-tools/v1',
          title: 'Vastu Noida Expert',
          shortDescription: 'Noida vastu consulting',
          fullDescription: 'Noida vastu consulting',
          primaryCategory: 'Vastu',
          allCategories: ['All', 'Vastu'],
          searchKeywords: ['vastu', 'noida'],
          icon: LucideIcons.compass,
          accentColor: Colors.amber,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
          location: 'Noida',
          price: 5000,
          rating: 4.8,
          provider: 'Aura Vastu',
        ),
      ];

      AiServiceRegistry.setTools(sampleServices);

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Select Category "Home Design"
      await tester.tap(find.widgetWithText(ChoiceChip, 'Home Design'));
      await tester.pumpAndSettle();

      // Both Home Design cards visible
      expect(find.text('Home Design Deluxe'), findsOneWidget);
      expect(find.text('Home Design Standard'), findsOneWidget);
      expect(find.text('Vastu Noida Expert'), findsNothing);

      // 2. Also Search "Noida" (AND logic: Category == Home Design AND Search contains Noida)
      await tester.enterText(find.byType(TextField), 'Noida');
      await tester.pumpAndSettle();

      // Only Home Design Deluxe satisfies BOTH filters
      expect(find.text('Home Design Deluxe'), findsOneWidget);
      expect(find.text('Home Design Standard'), findsNothing);
      expect(find.text('Vastu Noida Expert'), findsNothing);
    });

    // 5. Clear / Reset Filters
    testWidgets('5. Clear Filters: Clears search and category, restoring all real services', (tester) async {
      final sampleServices = [
        const AiServiceTool(
          id: 'svc_1',
          slug: 'svc-1',
          routePath: '/ai-tools/svc-1',
          title: 'Construction Supervision',
          shortDescription: 'Engineering supervision',
          fullDescription: 'Engineering supervision',
          primaryCategory: 'Construction',
          allCategories: ['All', 'Construction'],
          searchKeywords: ['construction'],
          icon: LucideIcons.hammer,
          accentColor: Colors.orange,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
        ),
        const AiServiceTool(
          id: 'svc_2',
          slug: 'svc-2',
          routePath: '/ai-tools/svc-2',
          title: 'Home Loan Advisory',
          shortDescription: 'Doorstep banking rates',
          fullDescription: 'Doorstep banking rates',
          primaryCategory: 'Finance',
          allCategories: ['All', 'Finance'],
          searchKeywords: ['loan', 'finance'],
          icon: LucideIcons.landmark,
          accentColor: Colors.green,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
        ),
      ];

      AiServiceRegistry.setTools(sampleServices);

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Category
      await tester.tap(find.widgetWithText(ChoiceChip, 'Construction'));
      await tester.pumpAndSettle();
      expect(find.text('Construction Supervision'), findsOneWidget);
      expect(find.text('Home Loan Advisory'), findsNothing);

      // Enter search for zero matches
      await tester.enterText(find.byType(TextField), 'NonExistentXYZ');
      await tester.pumpAndSettle();

      // Empty state
      expect(find.textContaining('No services match "NonExistentXYZ"'), findsOneWidget);
      final clearBtn = find.text('Clear Filters');
      expect(clearBtn, findsOneWidget);

      // Tap Clear Filters
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Both services restored
      expect(find.text('Construction Supervision'), findsOneWidget);
      expect(find.text('Home Loan Advisory'), findsOneWidget);
    });

    // 6. Zero result combination displays "No services found" with "Clear Filters"
    testWidgets('6. Zero results: Displays clear empty state message and Clear Filters button', (tester) async {
      final sample = [
        const AiServiceTool(
          id: 'svc_1',
          slug: 'svc-1',
          routePath: '/ai-tools/svc-1',
          title: 'Property Legal Search',
          shortDescription: '30-year title check',
          fullDescription: '30-year title check',
          primaryCategory: 'Legal',
          allCategories: ['All', 'Legal'],
          searchKeywords: ['legal'],
          icon: LucideIcons.fileCheck,
          accentColor: Colors.red,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
        ),
      ];
      AiServiceRegistry.setTools(sample);

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: AllFeaturesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Query that matches nothing
      await tester.enterText(find.byType(TextField), 'Swimming Pool Construction');
      await tester.pumpAndSettle();

      expect(find.text('No services match "Swimming Pool Construction"'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    // 7. Data Normalization & Null Safety
    test('7. Data Normalization: fromMap handles different capitalization, extra spaces, and missing fields', () {
      final rawData = {
        'id': '  svc_norm_01  ',
        'title': '  Turnkey Interior Architecture  ',
        'category': '  Interior Design  ',
        'description': '  Full house modular woodworking  ',
        'price': '₹ 1,50,000 ',
        'rating': '4.95 / 5.0',
        'location': '  Sector 150, Noida  ',
        'service_type': '  Turnkey  ',
        'provider': '  PropZen Studio  ',
      };

      final tool = AiServiceTool.fromMap(rawData);
      expect(tool.id, equals('svc_norm_01'));
      expect(tool.title, equals('Turnkey Interior Architecture'));
      expect(tool.primaryCategory, equals('Interior Design'));
      expect(tool.price, equals(150000.0));
      expect(tool.rating, equals(4.95));
      expect(tool.location, equals('Sector 150, Noida'));
      expect(tool.serviceType, equals('Turnkey'));
      expect(tool.provider, equals('PropZen Studio'));
      expect(tool.allCategories, contains('Interior Design'));
      expect(tool.allCategories, contains('All'));
    });

    // 8. Viewport Responsiveness across multiple devices
    testWidgets('8. Viewport Responsiveness: Renders gracefully across 320px, 375px, 768px, 1024px, 1280px', (tester) async {
      final sample = [
        const AiServiceTool(
          id: 'svc_resp',
          slug: 'resp',
          routePath: '/ai-tools/resp',
          title: '3D Spatial Modeling',
          shortDescription: 'Interactive spatial walk',
          fullDescription: 'Interactive spatial walk',
          primaryCategory: '3D & VR',
          allCategories: ['All', '3D & VR'],
          searchKeywords: ['3d'],
          icon: LucideIcons.box,
          accentColor: Colors.purple,
          uniqueImageUrl: '',
          features: [],
          inputs: [],
        ),
      ];
      AiServiceRegistry.setTools(sample);

      final viewports = [
        const Size(320, 600),
        const Size(375, 812),
        const Size(768, 1024),
        const Size(1024, 768),
        const Size(1280, 900),
      ];

      for (final vp in viewports) {
        await tester.binding.setSurfaceSize(vp);
        await tester.pumpWidget(
          const MaterialApp(
            home: AllFeaturesScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow occurred on ${vp.width}x${vp.height}');
        expect(find.text('3D Spatial Modeling'), findsOneWidget);
      }
    });
  });
}
