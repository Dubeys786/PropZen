import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/screens/site_visit_booking_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_site_visits_screen.dart';
import 'package:dealghar_ncr_10x/screens/my_site_visits_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/services/site_visit_booking_service.dart';
import 'package:dealghar_ncr_10x/services/propzen_ai_agent_service.dart';
import 'package:dealghar_ncr_10x/widgets/enquiry_auth_dialog.dart';

// 1x1 transparent PNG bytes for Flutter test image decoding
final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();
  @override
  List<Cookie> get cookies => [];
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => [];
  @override
  bool get persistentConnection => false;
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) async => this;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  const propertyA = Property(
    id: 'PROP-NCR-A-101',
    title: 'DLF The Arbour Sector 63',
    sector: 'Sector 63',
    city: 'Gurugram',
    category: 'Residential',
    propertyType: 'Flat',
    askingPriceCr: 7.80,
    fairValueCr: 7.65,
    pricePerSqft: 19750,
    score10x: 9.4,
    rentalYieldPercent: 4.8,
    sqft: 3950,
    bhk: '4 BHK',
    imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    isVerified: true,
  );

  setUp(() {
    UserSession.logout();
    PropertyStateService.instance.clearScheduledVisits();
  });

  group('Book a Site Visit Flow & Property Association Tests', () {
    // SCENARIO A: Guest → Property Details → Book a Site Visit → Sign In → Site Visit Form → Submit
    testWidgets('SCENARIO A: Guest clicks Book a Site Visit, signs in, lands on Site Visit Form and submits', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: propertyA),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Guest clicks "Book a Site Visit"
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      // 2. Sign In dialog is shown
      expect(find.byType(EnquiryAuthDialog), findsOneWidget);

      // 3. User logs in & verifies
      UserSession.login(
        name: 'Aakash Verma',
        userEmail: 'aakash@example.com',
        phone: '9810394068',
        role: 'Verified Buyer',
        isEmailVerified: true,
      );

      // Close auth dialog as completed
      Navigator.of(tester.element(find.byType(EnquiryAuthDialog))).pop();
      await tester.pumpAndSettle();

      // 4. Click Book a Site Visit as verified user -> Opens SiteVisitBookingScreen
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      expect(find.byType(SiteVisitBookingScreen), findsOneWidget);
      expect(find.text('DLF The Arbour Sector 63'), findsWidgets);

      // 5. Submit site visit form
      await tester.ensureVisible(find.text('Confirm Site Visit'));
      await tester.tap(find.text('Confirm Site Visit'));
      await tester.pumpAndSettle();

      // 6. Verification confirmation shown
      expect(find.text('Site Visit Requested Successfully'), findsOneWidget);
      expect(find.textContaining('DLF The Arbour Sector 63'), findsWidgets);
      expect(PropertyStateService.instance.scheduledVisits.first['propertyId'], equals('PROP-NCR-A-101'));
    });

    // SCENARIO B: Logged-in verified user → Property Details → Book a Site Visit → Site Visit Form → Submit
    testWidgets('SCENARIO B: Verified user navigates directly to Site Visit Form and submits', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi@example.com',
        phone: '9810394068',
        role: 'Verified Buyer',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: propertyA),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Click "Book a Site Visit" directly
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      // 2. Direct Site Visit Booking Screen opens
      expect(find.byType(EnquiryAuthDialog), findsNothing);
      expect(find.byType(SiteVisitBookingScreen), findsOneWidget);
      expect(find.text('DLF The Arbour Sector 63'), findsWidgets);

      // 3. Submit
      await tester.ensureVisible(find.text('Confirm Site Visit'));
      await tester.tap(find.text('Confirm Site Visit'));
      await tester.pumpAndSettle();

      expect(find.text('Site Visit Requested Successfully'), findsOneWidget);
    });

    // SCENARIO C: Guest cancels Sign In and safely returns to Property Details screen
    testWidgets('SCENARIO C: Guest cancels Sign In and safely returns to Property Details screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: propertyA),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Click "Book a Site Visit"
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      expect(find.byType(EnquiryAuthDialog), findsOneWidget);

      // 2. Cancel/Dismiss Sign In
      Navigator.of(tester.element(find.byType(EnquiryAuthDialog))).pop();
      await tester.pumpAndSettle();

      // 3. User remains on same Property Details page
      expect(find.byType(PropertyDetailsScreen), findsOneWidget);
      expect(find.text('DLF The Arbour Sector 63', skipOffstage: false), findsWidgets);
      expect(find.text('₹7.8 Cr', skipOffstage: false), findsWidgets);
    });

    // SCENARIO D: Site Visit Form opened for Property A saves Property A ID
    testWidgets('SCENARIO D: Site Visit Form for Property A saves Property A ID in PropertyStateService', (WidgetTester tester) async {
      UserSession.login(
        name: 'Aakash Verma',
        userEmail: 'aakash@example.com',
        phone: '9810394068',
        role: 'Verified Buyer',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SiteVisitBookingScreen(property: propertyA),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm Site Visit'));
      await tester.tap(find.text('Confirm Site Visit'));
      await tester.pumpAndSettle();

      final visits = PropertyStateService.instance.scheduledVisits;
      expect(visits.isNotEmpty, isTrue);
      expect(visits.first['propertyId'], equals('PROP-NCR-A-101'));
      expect(visits.first['propertyTitle'], equals('DLF The Arbour Sector 63'));
    });

    // SCENARIO E: Stepper Control - Visitor Count (default: 1, min: 1, max: 10, no 0 allowed)
    testWidgets('SCENARIO E: Stepper controls Visitor Count between 1 and 10 and prevents 0 visitors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SiteVisitBookingScreen(property: propertyA),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure stepper is visible
      final minusBtn = find.byTooltip('Decrease visitors');
      final plusBtn = find.byTooltip('Increase visitors');
      await tester.ensureVisible(plusBtn);

      // Default visitor count is 1
      expect(find.text('1 person attending'), findsOneWidget);

      // Tap decrease at minimum (1) -> stays 1
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();
      expect(find.text('1 person attending'), findsOneWidget);

      // Tap increase button 2 times -> becomes 3
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      expect(find.text('2 people attending'), findsOneWidget);

      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      expect(find.text('3 people attending'), findsOneWidget);
    });

    // SCENARIO F: Cab Required Segmented Toggle & Live Summary Update
    testWidgets('SCENARIO F: Cab Required toggle changes between Yes and No and reflects in live summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SiteVisitBookingScreen(property: propertyA),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Cab section
      final yesBtn = find.text('Yes');
      final noBtn = find.text('No');
      await tester.ensureVisible(yesBtn);

      // Default is No (Cab Not Required)
      expect(find.textContaining('🚫 Cab Not Required'), findsWidgets);

      // Tap 'Yes'
      await tester.tap(yesBtn);
      await tester.pumpAndSettle();

      // Live summary updates to 'Yes (🚕 Cab Required)'
      expect(find.textContaining('🚕 Cab Required'), findsWidgets);

      // Tap 'No'
      await tester.tap(noBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('🚫 Cab Not Required'), findsWidgets);
    });

    // SCENARIO G: Full Custom Booking with 3 Visitors and Cab Required = Yes
    testWidgets('SCENARIO G: Full booking with 3 visitors and Cab=Yes saves boolean and integer correctly', (WidgetTester tester) async {
      UserSession.login(
        name: 'Aman Sharma',
        userEmail: 'aman.sharma@example.com',
        phone: '9810394068',
        role: 'Verified Buyer',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SiteVisitBookingScreen(property: propertyA),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Set visitors to 3
      final plusBtn = find.byTooltip('Increase visitors');
      await tester.ensureVisible(plusBtn);
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      // 2. Set Cab Required to Yes
      final yesBtn = find.text('Yes');
      await tester.ensureVisible(yesBtn);
      await tester.tap(yesBtn);
      await tester.pumpAndSettle();

      // 3. Submit
      await tester.ensureVisible(find.text('Confirm Site Visit'));
      await tester.tap(find.text('Confirm Site Visit'));
      await tester.pumpAndSettle();

      // 4. Success dialog shows 3 Visitors and Cab: Required
      expect(find.text('Site Visit Requested Successfully'), findsOneWidget);
      expect(find.textContaining('3 Visitors'), findsWidgets);
      expect(find.textContaining('🚕 Cab Required'), findsWidgets);
      expect(find.text('Pending Confirmation'), findsWidgets);

      // 5. Verify PropertyStateService stored exact values
      final visit = PropertyStateService.instance.scheduledVisits.first;
      expect(visit['visitor_count'], equals(3));
      expect(visit['cab_required'], isTrue);
      expect(visit['status'], equals('Pending Confirmation'));
    });

    // SCENARIO H: Dealer / Admin Site Visits view shows Visitor Count and Cab Badges
    testWidgets('SCENARIO H: Dealer Site Visits Screen shows 3 Visitors, Cab Required badge and details', (WidgetTester tester) async {
      // Add a custom visit to state
      PropertyStateService.instance.addScheduledVisit(
        propertyId: 'PROP-NCR-A-101',
        propertyTitle: 'Skyline Heights',
        sector: 'Sector 150',
        date: '25 August 2026',
        time: '11:00 AM',
        name: 'Aman Sharma',
        phone: '9810394068',
        email: 'aman.sharma@example.com',
        visitorCount: 3,
        cabRequired: true,
        status: 'Pending Confirmation',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DealerSiteVisitsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify listing shows 3 Visitors and Cab Required
      expect(find.textContaining('Skyline Heights'), findsWidgets);
      expect(find.text('👥 3 Visitors'), findsOneWidget);
      expect(find.text('🚕 Cab Required'), findsOneWidget);

      // Tap Inspect / Actions -> Opens detail dialog
      await tester.tap(find.text('Inspect / Actions').first);
      await tester.pumpAndSettle();

      expect(find.text('Site Visit Details'), findsOneWidget);
      expect(find.text('Number of Visitors:'), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text('Confirm Visit'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Cancel Visit'), findsOneWidget);
    });

    // SCENARIO I: User My Site Visits Screen shows Visitor Count and Cab Badge
    testWidgets('SCENARIO I: My Site Visits Screen displays user bookings with visitor count and cab status', (WidgetTester tester) async {
      PropertyStateService.instance.addScheduledVisit(
        propertyId: 'PROP-NCR-B-202',
        propertyTitle: 'Godrej Palm Retreat',
        sector: 'Sector 150',
        date: '28 August 2026',
        time: '02:00 PM',
        name: 'Sakshi Sharma',
        phone: '9810394068',
        email: 'sakshi@example.com',
        visitorCount: 2,
        cabRequired: false,
        status: 'Confirmed',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MySiteVisitsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Godrej Palm Retreat'), findsWidgets);
      expect(find.text('2 Visitors'), findsOneWidget);
      expect(find.text('🚫 Cab Not Required'), findsOneWidget);
    });

    // SCENARIO J: SiteVisitBookingService creates booking, generates ID, and updates scheduled visits
    test('SCENARIO J: SiteVisitBookingService creates valid booking and updates scheduled visits', () async {
      final res = await SiteVisitBookingService.instance.bookSiteVisit(
        propertyId: 'prop_ace_starlit_150',
        propertyTitle: 'Ace Starlit Residences',
        sector: 'Sector 150',
        visitDate: '2026-09-01',
        timeSlot: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
        clientName: 'Rahul Verma',
        clientPhone: '9876543210',
        clientEmail: 'rahul@propzen.ai',
      );

      expect(res.isSuccess, isTrue);
      expect(res.bookingId, isNotNull);
      expect(res.bookingId, startsWith('VISIT-'));

      final allVisits = PropertyStateService.instance.scheduledVisits;
      expect(allVisits.any((v) => v['property_id'] == 'prop_ace_starlit_150' && v['phone'] == '9876543210'), isTrue);
    });

    // SCENARIO K: SiteVisitBookingService rejects duplicate booking
    test('SCENARIO K: SiteVisitBookingService detects and rejects duplicate booking', () async {
      final firstRes = await SiteVisitBookingService.instance.bookSiteVisit(
        propertyId: 'prop_ace_starlit_150',
        propertyTitle: 'Ace Starlit Residences',
        sector: 'Sector 150',
        visitDate: '2026-09-01',
        timeSlot: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
        clientName: 'Rahul Verma',
        clientPhone: '9876543210',
      );
      expect(firstRes.isSuccess, isTrue);

      final resDuplicate = await SiteVisitBookingService.instance.bookSiteVisit(
        propertyId: 'prop_ace_starlit_150',
        propertyTitle: 'Ace Starlit Residences',
        sector: 'Sector 150',
        visitDate: '2026-09-01',
        timeSlot: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
        clientName: 'Rahul Verma',
        clientPhone: '9876543210',
      );

      expect(resDuplicate.isDuplicate, isTrue);
      expect(resDuplicate.isSuccess, isFalse);
    });

    // SCENARIO L: SiteVisitBookingService rejects unreasonable time slots (e.g. 7 AM)
    test('SCENARIO L: SiteVisitBookingService rejects unreasonable hours (e.g. 7 AM)', () async {
      final resUnavailable = await SiteVisitBookingService.instance.bookSiteVisit(
        propertyId: 'prop_test_123',
        propertyTitle: 'Test Apartment',
        visitDate: '2026-09-02',
        timeSlot: '7 AM',
        clientPhone: '9812345678',
      );

      expect(resUnavailable.isSlotUnavailable, isTrue);
      expect(resUnavailable.isSuccess, isFalse);
    });

    // SCENARIO M: Voice Agent Complete Site Visit Multi-turn Conversation & Booking
    test('SCENARIO M: PropZen Voice Agent executes multi-turn site visit booking conversation with confirmation', () async {
      final aiService = PropzenAiAgentService.instance;
      aiService.clearSession();

      // Step 1: User requests site visit
      final step1 = await aiService.processDialogue('Is property ki site visit book karni hai');
      expect(step1.flowType, 'siteVisit');
      expect(aiService.context.siteVisitStage, SiteVisitStage.collectingDate);

      // Step 2: User provides date
      final step2 = await aiService.processDialogue('Kal');
      expect(aiService.context.siteVisitStage, SiteVisitStage.collectingTime);

      // Step 3: User provides time
      final step3 = await aiService.processDialogue('11 baje');
      expect(aiService.context.visitTime, '11:00 AM');

      // Step 4: User provides visitors and cab
      final step4 = await aiService.processDialogue('Hum 2 log hain aur cab chahiye');
      expect(aiService.context.visitorCount, 2);
      expect(aiService.context.cabRequired, isTrue);
      expect(aiService.context.siteVisitStage, SiteVisitStage.confirming);
      expect(step4.speechResponse, contains('confirm'));

      // Step 5: User confirms booking
      final step5 = await aiService.processDialogue('Haan confirm kar do');
      expect(aiService.context.siteVisitStage, SiteVisitStage.booked);
      expect(aiService.context.bookingId, isNotNull);
      expect(step5.speechResponse, contains('successfully book ho gayi hai'));
      expect(step5.speechResponse, contains(aiService.context.bookingId!));
    });
  });
}
