import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/site_visit_booking_screen.dart';
import 'package:dealghar_ncr_10x/widgets/enquiry_auth_dialog.dart';

final _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() {
    UserSession.logout();
  });

  tearDown(() {
    UserSession.logout();
  });

  group('Property Enquiry & Book Site Visit Authentication Flow Tests', () {
    final stateService = PropertyStateService.instance;
    final propATS = stateService.allProperties.firstWhere(
      (p) => p.id == 'prop_ats_happytrails',
      orElse: () => stateService.allProperties.first,
    );
    final propGaur = stateService.allProperties.firstWhere(
      (p) => p.id == 'prop_gaur_city',
      orElse: () => stateService.allProperties[1],
    );

    test('TEST 1: UserSession defaults to unauthenticated and empty strings (Zero fake hardcoding)', () {
      expect(UserSession.isLoggedIn, isFalse);
      expect(UserSession.isEmailVerified, isFalse);
      expect(UserSession.isAuthenticated, isFalse);
      expect(UserSession.fullName, isEmpty);
      expect(UserSession.mobileNumber, isEmpty);
      expect(UserSession.email, isEmpty);
    });

    testWidgets('TEST 2: Logged-out user clicking "Enquire Now" opens Auth & Verification Modal first', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Enquire Now
      final enquireBtn = find.text('Enquire Now').first;
      await tester.tap(enquireBtn);
      await tester.pumpAndSettle();

      // Verify Auth Dialog appears with verification prompt
      expect(find.byType(EnquiryAuthDialog), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.textContaining('Verification required to continue with Property Enquiry'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('TEST 3: Logged-out user clicking "Book a Site Visit" triggers Auth Modal before Booking Form', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Book a Site Visit
      final visitBtn = find.text('Book a Site Visit').first;
      await tester.tap(visitBtn);
      await tester.pumpAndSettle();

      // Verify Auth Dialog appears with Book a Site Visit label
      expect(find.byType(EnquiryAuthDialog), findsOneWidget);
      expect(find.textContaining('Verification required to continue with Book a Site Visit'), findsOneWidget);
    });

    testWidgets('TEST 4: Creating Account & OTP Verification logs user in and proceeds to Enquiry Form with verified credentials', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Enquire Now
      await tester.tap(find.text('Enquire Now').first);
      await tester.pumpAndSettle();

      // Switch to Create Account
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Enter Real User Credentials
      await tester.enterText(find.widgetWithText(TextField, 'Enter your full name'), 'Rohan Mehta');
      await tester.enterText(find.widgetWithText(TextField, 'Enter 10-digit mobile number'), '9876543210');
      await tester.enterText(find.widgetWithText(TextField, 'Enter your email address'), 'rohan.mehta@example.com');
      await tester.pumpAndSettle();

      // Click Send OTP
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      // OTP Verification Screen
      expect(find.text('Verification required to continue'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsWidgets);

      // Enter 4-digit code (e.g. 1 2 3 4)
      final otpFields = find.byType(TextField);
      expect(otpFields, findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
      }
      await tester.pumpAndSettle();

      // Click Verify & Continue
      await tester.tap(find.text('Verify & Continue'));
      await tester.pumpAndSettle();

      // Verify user session is now authenticated
      expect(UserSession.isLoggedIn, isTrue);
      expect(UserSession.isEmailVerified, isTrue);
      expect(UserSession.fullName, equals('Rohan Mehta'));
      expect(UserSession.mobileNumber, equals('9876543210'));
      expect(UserSession.email, equals('rohan.mehta@example.com'));

      // Verify Enquiry Form is automatically opened with verified credentials
      expect(find.text('Enquire About Property'), findsOneWidget);
      expect(find.text('Rohan Mehta'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('rohan.mehta@example.com'), findsOneWidget);
      expect(find.textContaining('ATS HomeKraft Happy Trails'), findsWidgets);
    });

    testWidgets('TEST 5: Authenticated user directly opens Enquiry Form without auth dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-authenticate user
      UserSession.login(
        fullName: 'Kavita Iyer',
        mobile: '9812345678',
        email: 'kavita.iyer@example.com',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propGaur),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Enquire Now
      await tester.tap(find.text('Enquire Now').first);
      await tester.pumpAndSettle();

      // Directly opens Enquiry Form without EnquiryAuthDialog
      expect(find.byType(EnquiryAuthDialog), findsNothing);
      expect(find.text('Enquire About Property'), findsOneWidget);
      expect(find.text('Kavita Iyer'), findsOneWidget);
      expect(find.text('9812345678'), findsOneWidget);
      expect(find.text('kavita.iyer@example.com'), findsOneWidget);
      expect(find.textContaining('Gaur City'), findsWidgets);
    });

    testWidgets('TEST 6: Authenticated user directly opens SiteVisitBookingScreen with prefilled profile and dynamic property', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Pre-authenticate user
      UserSession.login(
        fullName: 'Deepak Sharma',
        mobile: '9899988877',
        email: 'deepak.sharma@example.com',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: propATS),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Book a Site Visit
      await tester.tap(find.text('Book a Site Visit').first);
      await tester.pumpAndSettle();

      // Directly navigates to SiteVisitBookingScreen
      expect(find.byType(SiteVisitBookingScreen), findsOneWidget);
      expect(find.text('Deepak Sharma'), findsOneWidget);
      expect(find.text('9899988877'), findsOneWidget);
      expect(find.text('deepak.sharma@example.com'), findsOneWidget);
      expect(find.textContaining('ATS HomeKraft Happy Trails'), findsWidgets);
    });
  });
}
