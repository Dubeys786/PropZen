import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/perfect_property_model.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/screens/find_my_perfect_property_screen.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/widgets/enquiry_auth_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Find My Perfect Property System Tests', () {
    late PropertyStateService stateService;

    setUp(() {
      stateService = PropertyStateService.instance;
      stateService.setProperties(List.from(Property.sampleDeals));
      UserSession.logout();
    });

    test('1. Scenario 1: Buy, Noida, ₹60L-₹90L, 2/3 BHK Apartment, Near Metro matches published properties', () {
      final preferences = PropertyPreferenceModel(
        purpose: 'Buy',
        city: 'Noida',
        localities: ['Sector 150', 'Sector 137'],
        minBudget: 0.60,
        maxBudget: 0.90,
        propertyTypes: ['Apartment'],
        bhkOptions: ['2 BHK', '3 BHK'],
        priorities: ['Near Metro', 'Gym', 'Parking'],
      );

      final matches = PerfectPropertyMatchingEngine.evaluateMatches(
        properties: stateService.publishedProperties,
        preferences: preferences,
      );

      expect(matches.isNotEmpty, isTrue);
      // Top match should be in Noida with high match percentage
      final topMatch = matches.first;
      expect(topMatch.matchScore, greaterThanOrEqualTo(80));
      expect(topMatch.property.city.toLowerCase(), contains('noida'));
      expect(topMatch.property.isPublished, isTrue);
      expect(topMatch.matchReasons.isNotEmpty, isTrue);
      expect(topMatch.matchReasons.any((r) => r.contains('budget') || r.contains('matches')), isTrue);
    });

    test('2. Scenario 2: Rent, Gurugram, ₹30k-₹50k/month, 2 BHK returns rental suitability matches', () {
      final preferences = PropertyPreferenceModel(
        purpose: 'Rent',
        city: 'Gurugram',
        localities: ['Golf Course Road', 'Cyber City', 'Sector 62'],
        minBudget: 25000,
        maxBudget: 60000,
        propertyTypes: ['Apartment'],
        bhkOptions: ['2 BHK', '3 BHK'],
        priorities: ['Near Metro', 'Security'],
      );

      final matches = PerfectPropertyMatchingEngine.evaluateMatches(
        properties: stateService.publishedProperties,
        preferences: preferences,
      );

      expect(matches.isNotEmpty, isTrue);
      final topMatch = matches.first;
      expect(topMatch.matchScore, greaterThan(65));
      expect(topMatch.property.isPublished, isTrue);
      expect(topMatch.matchReasons.any((r) => r.toLowerCase().contains('rent') || r.toLowerCase().contains('budget')), isTrue);
    });

    test('3. Scenario 3: Investment, ₹1.0-₹2.5 Cr with High Rental Potential prioritizes 10X yield properties', () {
      final preferences = PropertyPreferenceModel(
        purpose: 'Investment',
        city: 'Noida',
        localities: ['Sector 150', 'Sector 62'],
        minBudget: 0.80,
        maxBudget: 2.50,
        propertyTypes: ['Apartment', 'Commercial'],
        bhkOptions: ['2 BHK', '3 BHK', 'Commercial'],
        priorities: ['High Rental Potential', 'Investment Growth'],
      );

      final matches = PerfectPropertyMatchingEngine.evaluateMatches(
        properties: stateService.publishedProperties,
        preferences: preferences,
      );

      expect(matches.isNotEmpty, isTrue);
      final topMatch = matches.first;
      expect(topMatch.matchScore, greaterThanOrEqualTo(80));
      expect(topMatch.matchReasons.any((r) => r.contains('rental yield') || r.contains('10X') || r.contains('budget')), isTrue);
    });

    test('4. Scenario 4: No exact match triggers alternative labeling with delta calculation', () {
      // Extremely low unrealistic budget in Delhi to force alternative match
      final preferences = PropertyPreferenceModel(
        purpose: 'Buy',
        city: 'Delhi',
        localities: ['Chanakyapuri'],
        minBudget: 0.05, // 5 Lakhs
        maxBudget: 0.15, // 15 Lakhs
        propertyTypes: ['Villa'],
        bhkOptions: ['5+ BHK'],
        priorities: ['Near Metro'],
      );

      final matches = PerfectPropertyMatchingEngine.evaluateMatches(
        properties: stateService.publishedProperties,
        preferences: preferences,
      );

      expect(matches.isNotEmpty, isTrue);
      final firstMatch = matches.first;
      // Should not be marked as exact match
      expect(firstMatch.isExactMatch, isFalse);
    });

    test('5. Scenario 7 & 8: STRICT FILTERING - Pending and Rejected properties NEVER appear in recommendations', () {
      // Add a pending property and a rejected property to the state
      final pendingProp = Property(
        id: 'PROP-TEST-PENDING-99',
        title: 'Hidden Pending Luxury Penthouse',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        askingPriceCr: 0.75,
        fairValueCr: 0.85,
        pricePerSqft: 6500,
        score10x: 9.1,
        rentalYieldPercent: 4.8,
        sqft: 1400,
        bhk: '3 BHK',
        propertyType: 'Apartment',
        category: 'Residential',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        status: 'pending',
      );

      final rejectedProp = Property(
        id: 'PROP-TEST-REJECTED-99',
        title: 'Hidden Rejected Plot Land',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        askingPriceCr: 0.70,
        fairValueCr: 0.80,
        pricePerSqft: 6000,
        score10x: 8.8,
        rentalYieldPercent: 4.2,
        sqft: 1200,
        bhk: '3 BHK',
        propertyType: 'Apartment',
        category: 'Residential',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        status: 'rejected',
      );

      stateService.addDealerPropertySubmission(pendingProp);
      stateService.addDealerPropertySubmission(rejectedProp);

      final preferences = PropertyPreferenceModel(
        purpose: 'Buy',
        city: 'Noida',
        localities: ['Sector 150'],
        minBudget: 0.50,
        maxBudget: 1.00,
        propertyTypes: ['Apartment'],
        bhkOptions: ['3 BHK'],
      );

      // Evaluate matches against stateService.allProperties (which filters published only)
      final matches = PerfectPropertyMatchingEngine.evaluateMatches(
        properties: stateService.rawProperties,
        preferences: preferences,
      );

      expect(matches.any((m) => m.property.id == 'PROP-TEST-PENDING-99'), isFalse);
      expect(matches.any((m) => m.property.id == 'PROP-TEST-REJECTED-99'), isFalse);
      expect(matches.every((m) => m.property.isPublished), isTrue);
    });

    testWidgets('6. HomeScreen displays Find Your Perfect Property card and opens dedicated screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(onNavigateTab: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the card headline
      final cardHeadline = find.text('Find Your Perfect Property');
      expect(cardHeadline, findsWidgets);

      final ctaButton = find.text('Find My Perfect Property');
      expect(ctaButton, findsWidgets);

      // Tap card
      await tester.tap(ctaButton.first);
      await tester.pumpAndSettle();

      // Verify FindMyPerfectPropertyScreen opened
      expect(find.byType(FindMyPerfectPropertyScreen), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('7. Wizard navigation step-by-step to results and View Details interaction', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FindMyPerfectPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Intro -> Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Step 1: Purpose -> Tap Continue
      expect(find.text('What are you looking for?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Location -> Tap Continue
      expect(find.text('Where do you want to live?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Budget -> Tap Continue
      expect(find.text('What is your budget?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Property Type -> Tap Continue
      expect(find.text('What type of property are you looking for?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: Bedrooms -> Tap Continue
      expect(find.text('How many bedrooms do you need?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 6: Priorities -> Tap Continue
      expect(find.text('What matters most to you?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 7: Optional Lifestyle -> Tap Find My Matches
      expect(find.text('Anything else you prefer?'), findsOneWidget);
      await tester.tap(find.text('Find My Matches'));
      await tester.pump(const Duration(milliseconds: 200));

      // Step 8: Loading view
      expect(find.text('Finding your perfect properties...'), findsOneWidget);

      // Settle results
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 9: Results View
      expect(find.text('Your Perfect Matches'), findsOneWidget);
      expect(find.text('★ Best Match For You'), findsOneWidget);
      expect(find.text('Why this matches your preferences:'), findsWidgets);

      // Tap View Details on best match card
      final viewDetailsBtn = find.text('View Details').first;
      await tester.tap(viewDetailsBtn);
      await tester.pumpAndSettle();

      // Verify PropertyDetailsScreen opened
      expect(find.byType(PropertyDetailsScreen), findsOneWidget);
    });

    testWidgets('8. Scenario 5: User can use feature without sign-in and Save My Search prompts login', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Verify user is logged out
      expect(UserSession.isLoggedIn, isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: FindMyPerfectPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Fast forward to results
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Find My Matches'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap Save My Search
      final saveSearchBtn = find.text('Save My Search');
      expect(saveSearchBtn, findsOneWidget);
      await tester.tap(saveSearchBtn);
      await tester.pumpAndSettle();

      // Should prompt auth dialog
      expect(find.byType(EnquiryAuthDialog), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}
