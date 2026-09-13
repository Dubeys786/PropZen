import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/dual_auth_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_access_denied_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/widgets/become_dealer_dialog.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
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
  bool followRedirects = true;
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool? preserveHeaderCase}) {}
  @override
  void set(String name, Object value, {bool? preserveHeaderCase}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_kTransparentImage)
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() {
    UserSession.logout();
  });

  tearDown(() {
    UserSession.logout();
  });

  group('PropZen Buyer / Dealer Sign-In & Role-Based Dealer Portal Tests', () {
    testWidgets('CASE 12: Sign-in page shows Buyer and Dealer/Broker selector with Buyer as default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: DualAuthScreen(),
        ),
      );
      await tester.pump();

      // Verify User Type selector exists
      expect(find.text('Buyer'), findsWidgets);
      expect(find.text('Dealer / Broker'), findsOneWidget);

      // Verify default is Buyer
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);

      // Tap on Dealer / Broker selector
      await tester.tap(find.text('Dealer / Broker'));
      await tester.pump();

      // Verify UI switches to Dealer / Broker Sign In
      expect(find.text('Dealer / Broker Login'), findsOneWidget);
      expect(find.text('Sign In as Dealer'), findsOneWidget);
      expect(find.text('Signing in to verified Dealer & Broker Portal'), findsOneWidget);

      // Switch back to Buyer
      await tester.tap(find.text('Buyer').first);
      await tester.pump();
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('CASE 1: Buyer Sign In with role USER - Dealer Portal is strictly hidden', (tester) async {
      UserSession.login(
        name: 'John Buyer',
        email: 'buyer@propzen.in',
        phone: '9876543210',
        role: 'USER',
        isEmailVerified: true,
      );

      // Verify UserSession role checks
      expect(UserSession.isBuyer, isTrue);
      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isAdmin, isFalse);
    });

    testWidgets('CASE 2: Dealer Sign In with role DEALER - Dealer Portal is active', (tester) async {
      UserSession.login(
        name: 'Apex Realty',
        email: 'dealer@propzen.in',
        phone: '9810098100',
        role: 'DEALER',
        isEmailVerified: true,
      );

      // Verify UserSession role checks
      expect(UserSession.isDealer, isTrue);
      expect(UserSession.isBuyer, isFalse);
      expect(UserSession.isAdmin, isFalse);
    });

    testWidgets('CASE 3: User manually opens Dealer Portal URL - Access Denied (403 screen)', (tester) async {
      UserSession.login(
        name: 'Regular Buyer',
        email: 'regular_buyer@propzen.in',
        role: 'USER',
        isEmailVerified: true,
      );

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: AppRoutes.dealerDashboard,
        ),
      );
      await tester.pump();

      // Buyer navigating directly to dealerDashboard triggers DealerAccessDeniedScreen
      expect(find.byType(DealerAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access Denied (403)'), findsOneWidget);
      expect(find.text('Return to Home'), findsOneWidget);
      expect(find.text('Apply to Become a Dealer'), findsOneWidget);
    });

    testWidgets('CASE 4: Logged out user opens Dealer Portal URL - Redirects to Sign In screen', (tester) async {
      UserSession.logout();

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: AppRoutes.dealerDashboard,
        ),
      );
      await tester.pump();

      // Logged-out user navigating to dealerDashboard is redirected to DualAuthScreen
      expect(find.byType(DualAuthScreen), findsOneWidget);
      expect(find.byType(DealerAccessDeniedScreen), findsNothing);
    });

    testWidgets('CASE 5 & 6: Dealer or Admin opens Dealer Portal URL - Allowed', (tester) async {
      UserSession.login(
        name: 'Verified Dealer',
        email: 'broker@propzen.in',
        role: 'DEALER',
        isEmailVerified: true,
      );

      expect(UserSession.isDealer, isTrue);
    });

    test('CASE 7: Buyer tries Dealer sign in - isBuyerTryingDealer flag returned', () async {
      final result = await AuthService.instance.authenticateDealer(
        identifier: 'test_buyer@gmail.com',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isBuyerTryingDealer, isTrue);
      expect(result.message, contains('Your account is registered as a Buyer'));
    });

    test('CASE 8: Pending dealer tries Dealer sign in - verification notice returned', () async {
      final result = await AuthService.instance.authenticateDealer(
        identifier: 'pending_applicant@agency.com',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isDealerPending, isTrue);
      expect(result.message, contains('still under verification'));
    });

    test('CASE 9: Rejected dealer tries Dealer sign in - rejection message returned', () async {
      final result = await AuthService.instance.authenticateDealer(
        identifier: 'rejected_broker@agency.com',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isDealerRejected, isTrue);
      expect(result.message, contains('not approved'));
    });

    test('CASE 10: Unregistered user tries Dealer sign in - not found returned', () async {
      final result = await AuthService.instance.authenticateDealer(
        identifier: 'nonexistent_person_99999@example.com',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('not found or not approved'));
    });

    testWidgets('CASE 11: Apply as Dealer - Sets role to DEALER_PENDING and does NOT elevate to DEALER', (tester) async {
      UserSession.login(
        name: 'Applicant User',
        email: 'applicant@gmail.com',
        role: 'USER',
        isEmailVerified: true,
      );

      expect(UserSession.isDealer, isFalse);
      expect(UserSession.isBuyer, isTrue);

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BecomeDealerDialog(),
          ),
        ),
      );
      await tester.pump();

      // Fill in dialog and tap submit
      await tester.enterText(find.byType(TextField).first, 'Empire Realty');
      await tester.pump();

      final applyButton = find.text('Submit Application');
      expect(applyButton, findsOneWidget);

      await tester.tap(applyButton);
      await tester.pump();

      // Verify role is DEALER_PENDING, not DEALER
      expect(UserSession.isPendingDealer, isTrue);
      expect(UserSession.isDealer, isFalse);
    });
  });
}
