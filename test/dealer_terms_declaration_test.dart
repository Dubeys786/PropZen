import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/post_property_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_terms_screen.dart';
import 'package:dealghar_ncr_10x/screens/admin_property_review_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_properties_screen.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

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
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;
  @override
  bool bufferOutput = true;

  @override
  void write(Object? obj) {}
  @override
  void add(List<int> data) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}

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
  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get persistentConnection => true;
  @override
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

  setUp(() {
    PropertyStateService.instance.clearDealerProperties();
  });

  group('Dealer Terms & Conditions & Property Declaration System Tests', () {
    // 1. Step 7 contains "Before You Submit" card with 6 unchecked declarations by default
    testWidgets('1. Step 7 shows Before You Submit card with 6 unchecked declarations by default', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PostPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 7 (Preview)
      for (int i = 0; i < 6; i++) {
        final nextBtn = find.text('Continue');
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // Check card presence
      expect(find.text('Before You Submit'), findsOneWidget);
      expect(find.text('Terms & Conditions & Declaration'), findsOneWidget);
      expect(find.text('Read Propzen Dealer Terms & Conditions (v1.0)'), findsOneWidget);
      expect(find.text('View Terms'), findsOneWidget);

      // Verify all 6 checkboxes are present and unchecked
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(checkboxes.length, greaterThanOrEqualTo(6));
      for (final cb in checkboxes) {
        expect(cb.value, isFalse);
      }

      // Submit button says "Submit Property"
      expect(find.text('Submit Property'), findsOneWidget);
    });

    // 2. Attempting to submit when checkboxes are unchecked blocks submission with error message
    testWidgets('2. Attempting to submit without accepting all declarations is blocked', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PostPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 7
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Tap Submit Property
      final submitBtn = find.text('Submit Property');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Error message is displayed
      expect(find.text('Please accept all required declarations before submitting your property.'), findsWidgets);

      // Verify no property was submitted
      expect(PropertyStateService.instance.dealerProperties.isEmpty, isTrue);
    });

    // 3. Partial acceptance (e.g. 4 of 6 declarations) still blocks submission
    testWidgets('3. Partial acceptance of 4 declarations still blocks submission', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PostPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 7
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Check only first 4 declarations
      final d1 = find.textContaining('authentic, correct, and not misleading');
      await tester.ensureVisible(d1);
      await tester.tap(d1);
      await tester.pumpAndSettle();

      final d2 = find.textContaining('legally authorized by the owner');
      await tester.ensureVisible(d2);
      await tester.tap(d2);
      await tester.pumpAndSettle();

      final d3 = find.textContaining('copyright or have valid permission');
      await tester.ensureVisible(d3);
      await tester.tap(d3);
      await tester.pumpAndSettle();

      final d4 = find.textContaining('genuine current market valuation');
      await tester.ensureVisible(d4);
      await tester.tap(d4);
      await tester.pumpAndSettle();

      // Tap Submit Property
      final submitBtn = find.text('Submit Property');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Still blocked
      expect(find.text('Please accept all required declarations before submitting your property.'), findsWidgets);
      expect(PropertyStateService.instance.dealerProperties.isEmpty, isTrue);
    });

    // 4. View Terms opens full-screen DealerTermsAndConditionsScreen with 16 sections
    testWidgets('4. View Terms opens full-screen DealerTermsAndConditionsScreen with 16 sections', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PostPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 7
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Tap "View Terms"
      await tester.tap(find.text('View Terms'));
      await tester.pumpAndSettle();

      // DealerTermsAndConditionsScreen is opened
      expect(find.byType(DealerTermsAndConditionsScreen), findsOneWidget);
      expect(find.text('Dealer Terms & Conditions'), findsOneWidget);
      expect(find.textContaining('Version 1.0'), findsWidgets);
      expect(find.textContaining('1. Property Information Accuracy'), findsOneWidget);
      expect(find.text('I Understand'), findsOneWidget);

      // Tap "I Understand" -> returns to PostPropertyScreen
      await tester.tap(find.text('I Understand'));
      await tester.pumpAndSettle();

      expect(find.byType(DealerTermsAndConditionsScreen), findsNothing);
      expect(find.byType(PostPropertyScreen), findsOneWidget);

      // Verify checkboxes are NOT auto-checked merely by viewing terms
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      for (final cb in checkboxes) {
        expect(cb.value, isFalse);
      }
    });

    // 5. Accepting all 6 declarations allows submission with status = pending and terms metadata
    testWidgets('5. Accepting all declarations enables submission, sets status=pending and stores terms version', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PostPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 7
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Check all 6 declarations with ensureVisible
      final d1 = find.textContaining('authentic, correct, and not misleading');
      await tester.ensureVisible(d1);
      await tester.tap(d1);
      await tester.pumpAndSettle();

      final d2 = find.textContaining('legally authorized by the owner');
      await tester.ensureVisible(d2);
      await tester.tap(d2);
      await tester.pumpAndSettle();

      final d3 = find.textContaining('copyright or have valid permission');
      await tester.ensureVisible(d3);
      await tester.tap(d3);
      await tester.pumpAndSettle();

      final d4 = find.textContaining('genuine current market valuation');
      await tester.ensureVisible(d4);
      await tester.tap(d4);
      await tester.pumpAndSettle();

      final d5 = find.textContaining('Propzen Admin will review this listing');
      await tester.ensureVisible(d5);
      await tester.tap(d5);
      await tester.pumpAndSettle();

      final d6 = find.textContaining('Propzen Dealer Terms & Conditions and Privacy Policy');
      await tester.ensureVisible(d6);
      await tester.tap(d6);
      await tester.pumpAndSettle();

      // Submit
      final submitBtn = find.text('Submit Property');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Property submitted modal shown
      expect(find.text('Submitted for Review'), findsOneWidget);
      expect(find.textContaining('Pending Admin Approval'), findsOneWidget);

      // Verify PropertyStateService stored property with status = pending and terms metadata
      final submitted = PropertyStateService.instance.dealerProperties.first;
      expect(submitted['status'], equals('pending'));
      expect(submitted['terms_accepted'], isTrue);
      expect(submitted['terms_version'], equals('1.0'));
      expect(submitted['declaration_accuracy_accepted'], isTrue);
      expect(submitted['declaration_authorization_accepted'], isTrue);
      expect(submitted['declaration_content_rights_accepted'], isTrue);
      expect(submitted['declaration_pricing_accepted'], isTrue);
      expect(submitted['declaration_review_accepted'], isTrue);
      expect(submitted['declaration_terms_accepted'], isTrue);
    });

    // 6. Admin Property Review Screen displays "Dealer Declaration" card with accepted terms and items
    testWidgets('6. Admin Property Review displays Dealer Declaration card with version and items', (WidgetTester tester) async {
      const samplePendingProperty = Property(
        id: 'PROP-DLR-TEST-101',
        title: 'ATS Greens Paradiso',
        sector: 'Sector Chi 4',
        city: 'Greater Noida',
        category: 'Residential',
        propertyType: 'Flat',
        askingPriceCr: 1.45,
        fairValueCr: 1.40,
        pricePerSqft: 7500,
        score10x: 9.2,
        rentalYieldPercent: 4.6,
        sqft: 1950,
        bhk: '3 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=600&q=80',
        status: 'pending',
        dealerId: 'DLR-9810394068',
        dealerName: 'Rajesh Varma',
        termsAccepted: true,
        termsVersion: '1.0',
        termsAcceptedAt: '19 Aug 2026, 10:42 AM',
        termsAcceptedBy: 'Rajesh Varma',
        declarationAccuracyAccepted: true,
        declarationAuthorizationAccepted: true,
        declarationContentRightsAccepted: true,
        declarationPricingAccepted: true,
        declarationReviewAccepted: true,
        declarationTermsAccepted: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminPropertyReviewScreen(property: samplePendingProperty),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dealer Declaration card
      expect(find.text('Dealer Declaration'), findsOneWidget);
      expect(find.text('✓ Terms Accepted'), findsOneWidget);
      expect(find.text('Terms Version: 1.0'), findsOneWidget);
      expect(find.textContaining('Accepted: 19 Aug 2026'), findsOneWidget);
      expect(find.text('✓ Information accuracy'), findsOneWidget);
      expect(find.text('✓ Ownership/authorization'), findsOneWidget);
      expect(find.text('✓ Content rights'), findsOneWidget);
      expect(find.text('✓ Pricing accuracy'), findsOneWidget);
      expect(find.text('✓ Review/approval consent'), findsOneWidget);
      expect(find.text('✓ Terms & conditions agreement'), findsOneWidget);
    });

    // 7. Dealer My Properties displays Terms Version and Submission Terms dialog
    testWidgets('7. Dealer My Properties displays Terms Version and opens Submission Terms dialog', (WidgetTester tester) async {
      PropertyStateService.instance.addDealerProperty({
        'id': 'PROP-DLR-TEST-202',
        'title': 'Skyline Grandeur',
        'sector': 'Sector 150',
        'city': 'Noida',
        'price_cr': 3.25,
        'status': 'pending',
        'terms_version': '1.0',
        'terms_accepted': true,
        'terms_accepted_at': '19 Aug 2026, 10:42 AM',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DealerPropertiesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check card terms badge
      expect(find.text('Terms: v1.0'), findsOneWidget);
      expect(find.text('Submission Terms →'), findsOneWidget);

      // Tap Submission Terms →
      await tester.tap(find.text('Submission Terms →'));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Submission Terms'), findsOneWidget);
      expect(find.text('Version 1.0'), findsOneWidget);
      expect(find.text('✓ Accepted'), findsOneWidget);
      expect(find.textContaining('Information accuracy confirmed'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Version 1.0'), findsNothing);
    });
  });
}
