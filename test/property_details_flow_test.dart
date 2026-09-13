import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/screens/site_visit_booking_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/widgets/enquiry_auth_dialog.dart';
import 'package:dealghar_ncr_10x/widgets/property_card.dart';

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

  const testProperty = Property(
    id: 'PROP-NCR-TEST-101',
    title: 'DLF The Arbour Luxury Residence',
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
  });

  group('Property Details & Enquire Now Authentication Flow Tests', () {
    // SCENARIO A: Guest → View Details → Property Details (No login prompted) → Enquire Now → Sign In
    testWidgets('SCENARIO A: Guest views property details without sign-in, then Enquire Now triggers Sign In', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyCard(
                property: testProperty,
                onTapReport: () {},
                onTapPhotos: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Unauthenticated guest taps Property Card to View Details
      await tester.tap(find.text('DLF The Arbour Luxury Residence'));
      await tester.pumpAndSettle();

      // 2. Full Property Details is shown WITHOUT any sign-in prompt
      expect(find.byType(PropertyDetailsScreen), findsOneWidget);
      expect(find.textContaining('DLF The Arbour Luxury Residence', skipOffstage: false), findsWidgets);
      expect(find.textContaining('₹7.8 Cr', skipOffstage: false), findsWidgets);
      expect(find.text('Book a Site Visit'), findsOneWidget);
      expect(find.byType(EnquiryAuthDialog), findsNothing);

      // 3. Guest clicks "Book a Site Visit" -> Sign In page / dialog is prompted
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      expect(find.byType(EnquiryAuthDialog), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets);
    });

    // SCENARIO B: Guest → View Details → Book a Site Visit → Sign In → successful login → same property's enquiry flow
    testWidgets("SCENARIO B: Guest logs in & verifies email, then proceeds to the same property's enquiry schedule", (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: testProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Guest clicks "Book a Site Visit"
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      expect(find.byType(EnquiryAuthDialog), findsOneWidget);

      // 2. Perform direct login with email verification
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@example.com',
        phone: '9810394068',
        role: 'Verified Buyer',
        isEmailVerified: true,
      );

      // Close auth modal as completed
      Navigator.of(tester.element(find.byType(EnquiryAuthDialog))).pop();
      await tester.pumpAndSettle();

      // 3. Now trigger Book a Site Visit as verified logged-in user
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      // 4. SiteVisitBookingScreen is open for the SAME property
      expect(find.byType(SiteVisitBookingScreen), findsOneWidget);
      expect(find.text('DLF The Arbour Luxury Residence'), findsWidgets);
      expect(find.text('Confirm Site Visit'), findsOneWidget);
    });

    // SCENARIO C: Verified logged-in user → View Details → Book a Site Visit → enquiry flow directly
    testWidgets('SCENARIO C: Verified logged-in user accesses enquiry flow directly without Sign In prompt', (WidgetTester tester) async {
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@example.com',
        phone: '9810394068',
        role: 'Verified Buyer',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: testProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click "Book a Site Visit" directly
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      // Direct Enquiry / Visit flow opens immediately
      expect(find.byType(EnquiryAuthDialog), findsNothing);
      expect(find.byType(SiteVisitBookingScreen), findsOneWidget);
      expect(find.text('DLF The Arbour Luxury Residence'), findsWidgets);
    });

    // SCENARIO D: Unverified logged-in user → View Details → Book a Site Visit → Email Verification
    testWidgets('SCENARIO D: Unverified logged-in user is prompted to verify email before enquiry proceeds', (WidgetTester tester) async {
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@example.com',
        phone: '9810394068',
        role: 'Buyer',
        isEmailVerified: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: testProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click "Book a Site Visit"
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      // Email/Auth Verification Dialog is shown
      expect(find.byType(EnquiryAuthDialog), findsOneWidget);
    });

    // SCENARIO E: Guest → View Details → Book a Site Visit → Sign In → Back → same Property Details page
    testWidgets('SCENARIO E: Guest cancels Sign In and safely returns to the same Property Details page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropertyDetailsScreen(property: testProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Click "Book a Site Visit"
      await tester.tap(find.text('Book a Site Visit'));
      await tester.pumpAndSettle();

      expect(find.byType(EnquiryAuthDialog), findsOneWidget);

      // 2. Dismiss / Back out of Sign In
      Navigator.of(tester.element(find.byType(EnquiryAuthDialog))).pop();
      await tester.pumpAndSettle();

      // 3. User remains on same Property Details page with selected property data intact
      expect(find.byType(PropertyDetailsScreen), findsOneWidget);
      expect(find.textContaining('DLF The Arbour Luxury Residence', skipOffstage: false), findsWidgets);
      expect(find.textContaining('₹7.8 Cr', skipOffstage: false), findsWidgets);
    });
  });
}
