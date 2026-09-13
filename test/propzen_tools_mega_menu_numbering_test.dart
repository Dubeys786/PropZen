import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_tools_mega_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final expectedFinanceItems = [
    '1. Home Loan EMI',
    '2. Home Affordability',
    '3. Loan Eligibility',
    '4. Rent vs Buy',
    '5. Stamp Duty Calculator',
    '6. Registration Cost',
    '7. Total Purchase Cost',
    '8. Property ROI',
    '9. Rental Yield',
    '10. Loan Amortization',
  ];

  final expectedCreditItems = [
    '1. Credit Score Center',
    '2. Credit Score Education',
    '3. Home Loan Readiness',
    '4. Down Payment Planner',
  ];

  final expectedPropertyItems = [
    '1. Property Cost Calculator',
    '2. Interior Cost Calculator',
    '3. Renovation Calculator',
    '4. Vastu Tool',
    '5. Document Checklist',
    '6. Verification Guide',
  ];

  final expectedCityItems = [
    '1. Area Guide',
    '2. Connectivity Explorer',
    '3. Metro Connectivity',
    '4. Airport Connectivity',
    '5. Railway Connectivity',
    '6. Highway Connectivity',
    '7. Schools Nearby',
    '8. Hospitals Nearby',
    '9. Shopping & Lifestyle',
    '10. Upcoming Infrastructure',
    '11. City Property Trends',
    '12. Commute Calculator',
  ];

  final expectedTravelItems = [
    '1. Explore India',
    '2. Premium Destinations',
    '3. Weekend Getaways',
    '4. Nearby Attractions',
    '5. Travel Planner',
    '6. Luxury Places',
    '7. Destination Guide',
  ];

  final disallowedCarriedOverPrefixes = [
    '11. Credit Score Center',
    '12. Credit Score Education',
    '13. Home Loan Readiness',
    '14. Down Payment Planner',
    '15. Property Cost Calculator',
    '16. Interior Cost Calculator',
    '17. Renovation Calculator',
    '18. Vastu Tool',
    '19. Document Checklist',
    '20. Verification Guide',
    '21. Area Guide',
    '22. Connectivity Explorer',
    '23. Metro Connectivity',
    '24. Airport Connectivity',
    '25. Railway Connectivity',
    '26. Highway Connectivity',
    '27. Schools Nearby',
    '28. Hospitals Nearby',
    '29. Shopping & Lifestyle',
    '30. Upcoming Infrastructure',
    '31. City Property Trends',
    '32. Commute Calculator',
    '33. Explore India',
    '34. Premium Destinations',
    '35. Weekend Getaways',
    '36. Nearby Attractions',
    '37. Travel Planner',
    '38. Luxury Places',
    '39. Destination Guide',
  ];

  group('PropZen Tools & Intelligence Directory Independent Numbering Tests', () {
    testWidgets('Desktop view renders independent 1..N numbering for all 5 categories', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenToolsMegaMenu(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category headers exist
      expect(find.text('FINANCE'), findsOneWidget);
      expect(find.text('CREDIT & MONEY'), findsOneWidget);
      expect(find.text('PROPERTY'), findsOneWidget);
      expect(find.text('CITY INTELLIGENCE'), findsOneWidget);
      expect(find.text('TRAVEL & LIFESTYLE'), findsOneWidget);

      // Verify Finance items (1 to 10)
      for (final item in expectedFinanceItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present');
      }

      // Verify Credit & Money items (1 to 4)
      for (final item in expectedCreditItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present starting from 1');
      }

      // Verify Property items (1 to 6)
      for (final item in expectedPropertyItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present starting from 1');
      }

      // Verify City Intelligence items (1 to 12)
      for (final item in expectedCityItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present starting from 1');
      }

      // Verify Travel & Lifestyle items (1 to 7)
      for (final item in expectedTravelItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present starting from 1');
      }

      // Verify that none of the old carried-over sequential numbers (11..39) exist
      for (final disallowed in disallowedCarriedOverPrefixes) {
        expect(find.text(disallowed), findsNothing, reason: 'Carried-over number "$disallowed" must not exist');
      }
    });

    testWidgets('Mobile view renders independent 1..N numbering for all 5 categories', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenToolsMegaMenu(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category headers exist on mobile
      expect(find.text('FINANCE'), findsOneWidget);
      expect(find.text('CREDIT & MONEY'), findsOneWidget);
      expect(find.text('PROPERTY'), findsOneWidget);
      expect(find.text('CITY INTELLIGENCE'), findsOneWidget);
      expect(find.text('TRAVEL & LIFESTYLE'), findsOneWidget);

      // Verify all items in all 5 categories on mobile
      for (final item in expectedFinanceItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present on mobile');
      }
      for (final item in expectedCreditItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present on mobile starting from 1');
      }
      for (final item in expectedPropertyItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present on mobile starting from 1');
      }
      for (final item in expectedCityItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present on mobile starting from 1');
      }
      for (final item in expectedTravelItems) {
        expect(find.text(item), findsOneWidget, reason: '$item must be present on mobile starting from 1');
      }

      // None of the old carried-over numbers appear on mobile
      for (final disallowed in disallowedCarriedOverPrefixes) {
        expect(find.text(disallowed), findsNothing, reason: 'Carried-over number "$disallowed" must not exist on mobile');
      }
    });
  });
}
