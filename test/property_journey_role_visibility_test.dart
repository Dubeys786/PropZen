import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

final Uint8List _kTransparentImage = Uint8List.fromList([
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

  group('PropZen My Property Journey Role Visibility Suite', () {
    testWidgets('1. Guest / Logged-Out user: My Property Journey is completely hidden', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Explicitly unauthenticated
      UserSession.logout();

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Section header and badge must NOT appear
      expect(find.text('My Property Journey'), findsNothing);
      expect(find.text('Continuous Journey'), findsNothing);

      // Journey cards must NOT appear
      expect(find.text('Searches'), findsNothing);
      expect(find.text('Saved Deals'), findsNothing);
      expect(find.text('Visit Feedback'), findsNothing);
      expect(find.text('AI Re-Match'), findsNothing);
      expect(find.text('Negotiations'), findsNothing);
      expect(find.text('Deal Rooms'), findsNothing);
      expect(find.text('Documents'), findsNothing);
      expect(find.text('Payments'), findsNothing);
      expect(find.text('Deals'), findsNothing);
    });

    testWidgets('2. Authenticated Buyer user: My Property Journey is visible with all 10 cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Rahul Sharma',
        email: 'rahul.buyer@propzen.in',
        phone: '9876543210',
        role: 'Buyer',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Section header and badge MUST appear
      expect(find.text('My Property Journey'), findsOneWidget);
      expect(find.text('Continuous Journey'), findsOneWidget);

      // Verify all 10 cards are present
      expect(find.text('Searches'), findsOneWidget);
      expect(find.text('Saved Deals'), findsOneWidget);
      expect(find.text('Site Visits'), findsWidgets);
      expect(find.text('Visit Feedback'), findsOneWidget);
      expect(find.text('AI Re-Match'), findsOneWidget);
      expect(find.text('Negotiations'), findsOneWidget);
      expect(find.text('Deal Rooms'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Payments'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
    });

    testWidgets('3. Authenticated Dealer user: My Property Journey is completely hidden', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Apex Realtors',
        email: 'partner@apexrealty.com',
        phone: '9811223344',
        role: 'DEALER',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Section must NOT be visible for Dealer
      expect(find.text('My Property Journey'), findsNothing);
      expect(find.text('Continuous Journey'), findsNothing);

      // But Dealer Portal shortcut MUST be visible
      expect(find.text('Dealer Partner Portal'), findsOneWidget);
    });

    testWidgets('4. Authenticated Admin user: My Property Journey is completely hidden', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Super Admin',
        email: 'dubeysakshi618@gmail.com',
        phone: '9988776655',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Section must NOT be visible for Admin
      expect(find.text('My Property Journey'), findsNothing);
      expect(find.text('Continuous Journey'), findsNothing);

      // But Command Center MUST be visible
      expect(find.text('PropZen Command Center'), findsOneWidget);
    });

    testWidgets('5. Dynamic session state change: toggles visibility dynamically', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.logout();

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Starts hidden as guest
      expect(find.text('My Property Journey'), findsNothing);

      // Log in as buyer
      UserSession.login(
        name: 'Priya Buyer',
        email: 'priya@propzen.in',
        role: 'Buyer',
        isEmailVerified: true,
      );
      await tester.pumpAndSettle();

      // Now visible
      expect(find.text('My Property Journey'), findsOneWidget);

      // Log out
      UserSession.logout();
      await tester.pumpAndSettle();

      // Immediately hidden again
      expect(find.text('My Property Journey'), findsNothing);
    });
  });
}
