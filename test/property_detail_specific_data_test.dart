import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';

void main() {
  group('Property Detail Real & Property-Specific Data Test Suite', () {
    // 1. Property A: ATS HomeKraft Happy Trails (2 BHK, Noida Extension)
    testWidgets('1. Property A (ATS Homekraft) renders its own unique infrastructure and 2 BHK layout', (tester) async {
      final propA = Property.sampleDeals.firstWhere((p) => p.id == 'prop_ats_happytrails');

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propA, propertyId: propA.id),
        ),
      );
      await tester.pumpAndSettle();

      // Title and location
      expect(find.text('ATS HomeKraft Happy Trails'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Sector 10, Noida Extension'), findsAtLeastNWidgets(1));

      // Specific Nearby Infrastructure & Distances for Property A
      expect(find.text('Gaur City Mall'), findsOneWidget);
      expect(find.text('2.5 km'), findsOneWidget);
      expect(find.text('Sector 52 Metro'), findsOneWidget);
      expect(find.text('8.0 km'), findsOneWidget);
      expect(find.text('Fortis Hospital'), findsOneWidget);
      expect(find.text('9.5 km'), findsOneWidget);
      expect(find.text('FNG Expressway'), findsOneWidget);
      expect(find.text('3.8 km'), findsOneWidget);

      // Property A should NOT have Property C/D's landmarks
      expect(find.text('Jewar International Airport'), findsNothing);
      expect(find.text('Sector 148 Metro'), findsNothing);
      expect(find.text('Shaheed Bhagat Singh Park'), findsNothing);

      // Property A 2 BHK Layout
      expect(find.text('2 BHK • 1150 Sq. Ft.'), findsOneWidget);
      expect(find.text('2 BHK'), findsAtLeastNWidgets(1));
      expect(find.text('1150 Sq. Ft.'), findsAtLeastNWidgets(1));
      expect(find.text('2D CAD BLUEPRINT SPECIFICATION — ATS HOMEKRAFT HAPPY TRAILS'), findsOneWidget);
    });

    // 2. Property B: Gaur City (3 BHK, Noida Extension)
    testWidgets('2. Property B (Gaur City) renders its own unique infrastructure and 3 BHK layout', (tester) async {
      final propB = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_city');

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propB, propertyId: propB.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gaur City'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Sector 4, Noida Extension'), findsAtLeastNWidgets(1));

      // Specific Nearby Infrastructure & Distances for Property B
      expect(find.text('Gaur City Mall'), findsOneWidget);
      expect(find.text('100 m'), findsOneWidget);
      expect(find.text('Char Murti Chowk'), findsOneWidget);
      expect(find.text('500 m'), findsOneWidget);
      expect(find.text('Sector 52 Metro'), findsOneWidget);
      expect(find.text('7.2 km'), findsOneWidget);
      expect(find.text('NH-24 Expressway'), findsOneWidget);
      expect(find.text('5.0 km'), findsOneWidget);

      // Property B should NOT show Property A's specific distance (2.5 km for Gaur City Mall)
      expect(find.text('2.5 km'), findsNothing);

      // Property B 3 BHK Layout
      expect(find.text('3 BHK • 1450 Sq. Ft.'), findsOneWidget);
      expect(find.text('1450 Sq. Ft.'), findsAtLeastNWidgets(1));
      expect(find.text('2D CAD BLUEPRINT SPECIFICATION — GAUR CITY'), findsOneWidget);
    });

    // 3. Property C: Tata Eureka Park (2 BHK Smart Automation, Sector 150)
    testWidgets('3. Property C (Tata Eureka Park) renders Sector 150 specific infrastructure & distances', (tester) async {
      final propC = Property.sampleDeals.firstWhere((p) => p.id == 'prop_tata_eureka_150');

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propC, propertyId: propC.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tata Eureka Park'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Sector 150'), findsAtLeastNWidgets(1));

      // Sector 150 specific landmarks
      expect(find.text('Sector 148 Metro'), findsOneWidget);
      expect(find.text('1.5 km'), findsOneWidget);
      expect(find.text('Shaheed Bhagat Singh Park'), findsOneWidget);
      expect(find.text('600 m'), findsOneWidget);
      expect(find.text('Noida Expressway'), findsOneWidget);
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('Jewar Airport Link'), findsOneWidget);
      expect(find.text('30 km'), findsOneWidget);

      // Layout
      expect(find.text('2 BHK • 1250 Sq. Ft.'), findsOneWidget);
      expect(find.text('2D CAD BLUEPRINT SPECIFICATION — TATA EUREKA PARK'), findsOneWidget);
    });

    // 4. Property D: Gaur Yamuna City (3 BHK, Yamuna Expressway)
    testWidgets('4. Property D (Gaur Yamuna City) renders Yamuna Expressway infrastructure and F1/Jewar distances', (tester) async {
      final propD = Property.sampleDeals.firstWhere((p) => p.id == 'prop_gaur_yamuna_city');

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propD, propertyId: propD.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gaur Yamuna City'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Sector 19, Yamuna Expressway'), findsAtLeastNWidgets(1));

      // Yamuna Expressway landmarks
      expect(find.text('Jewar International Airport'), findsOneWidget);
      expect(find.text('18 km'), findsOneWidget);
      expect(find.text('Buddh International F1 Circuit'), findsOneWidget);
      expect(find.text('3.5 km'), findsOneWidget);
      expect(find.text('Eastern Peripheral Expressway'), findsOneWidget);
      expect(find.text('5.2 km'), findsOneWidget);
      expect(find.text('Galgotias University'), findsOneWidget);
      expect(find.text('6.8 km'), findsOneWidget);

      // Layout
      expect(find.text('3 BHK • 1550 Sq. Ft.'), findsOneWidget);
      expect(find.text('2D CAD BLUEPRINT SPECIFICATION — GAUR YAMUNA CITY'), findsOneWidget);
    });

    // 5. Property E: Godrej Golf Links Villa (4 BHK Villa, Greater Noida)
    testWidgets('5. Property E (Godrej Golf Links Villa) renders luxury villa layout and golf-side distances', (tester) async {
      final propE = Property.sampleDeals.firstWhere((p) => p.id == 'prop_godrej_golflinks_villa');

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propE, propertyId: propE.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Godrej Golf Links Villa'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Sector 27'), findsAtLeastNWidgets(1));

      // Landmarks
      expect(find.text('Pari Chowk'), findsOneWidget);
      expect(find.text('2.0 km'), findsOneWidget);
      expect(find.text('Jaypee Greens Golf Course'), findsOneWidget);
      expect(find.text('3.2 km'), findsOneWidget);
      expect(find.text('Alpha 1 Metro'), findsOneWidget);
      expect(find.text('2.5 km'), findsOneWidget);
      expect(find.text('Yatharth Hospital'), findsOneWidget);
      expect(find.text('3.0 km'), findsOneWidget);

      // Villa Layout & Grand Master Suite
      expect(find.text('4 BHK • 3200 Sq. Ft.'), findsOneWidget);
      expect(find.text('Grand Master Suite'), findsOneWidget);
      expect(find.text('Grand Double-Height Living'), findsOneWidget);
      expect(find.text('2D CAD BLUEPRINT SPECIFICATION — GODREJ GOLF LINKS VILLA'), findsOneWidget);
    });

    // 6. Missing Infrastructure & Missing Floor Plan Empty States
    testWidgets('6. Property with empty infrastructure and missing floor plan displays proper unavailable notices without copying data', (tester) async {
      const customProp = Property(
        id: 'prop_custom_bare',
        title: 'Custom Unfurnished Studio',
        sector: 'Sector 62',
        city: 'Noida',
        category: 'Residential',
        propertyType: 'Studio Apartment',
        askingPriceCr: 0.35,
        fairValueCr: 0.35,
        pricePerSqft: 7000,
        score10x: 8.5,
        rentalYieldPercent: 5.5,
        sqft: 0,
        carpetAreaSqft: 0,
        bhk: 'Studio',
        imageUrl: '',
        galleryImages: [],
        amenities: [],
        nearby: {},
      );

      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: customProp, propertyId: customProp.id),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "Information not available" appears for empty infrastructure & amenities
      expect(find.text('Information not available'), findsAtLeastNWidgets(1));

      // Verify "Floor plan not available" appears when no sqft and no floor plan URL exist
      expect(find.text('Floor plan not available'), findsOneWidget);

      // Confirm no fake landmarks or fake room dimensions leaked
      expect(find.text('Metro Station (Aqua / Blue Line)'), findsNothing);
      expect(find.text('Gaur City Mall'), findsNothing);
    });

    // 7. Property ID Resolution via propertyId parameter
    testWidgets('7. PropertyDetailsScreen fetches and resolves property strictly by propertyId', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: PropertyDetailsScreen(propertyId: 'prop_advant_navis'),
        ),
      );
      await tester.pumpAndSettle();

      // Advant Navis Commercial Office
      expect(find.text('Advant Navis Business Park'), findsAtLeastNWidgets(1));
      expect(find.text('Sector 142 Metro Station'), findsOneWidget);
      expect(find.text('50 m'), findsOneWidget);
      expect(find.text('Commercial Office • 1200 Sq. Ft.'), findsOneWidget);
      expect(find.text('Main Workstation Hall'), findsOneWidget);
    });
  });
}
