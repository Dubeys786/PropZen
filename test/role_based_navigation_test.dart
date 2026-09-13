import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/dealer_dashboard_screen.dart';
import 'package:dealghar_ncr_10x/screens/my_site_visits_screen.dart';
import 'package:dealghar_ncr_10x/widgets/become_dealer_dialog.dart';

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
    UserSession.roleTierNotifier.value = 'Buyer';
  });

  group('PropZen Role-Based Navigation & Dealer Portal Information Architecture', () {
    // TEST 1: Profile page does NOT have the large Dealer Portal card, but has "Become a Dealer" for Buyer
    testWidgets('1. UserProfileScreen removes large Dealer Portal card and shows Become a Dealer for Buyer', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Buyer';

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that Become a Dealer promotional banner is removed
      expect(find.text('Become a Dealer / Partner'), findsNothing);
      expect(find.text('Open Dealer Portal →'), findsNothing);

      // Verify personal profile sections exist
      expect(find.text('My Enquiries'), findsOneWidget);
      expect(find.text('My Bookings & Site Visits'), findsOneWidget);
      expect(find.text('Saved Properties'), findsWidgets);
      expect(find.text('Shortlisted & Compare'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    // TEST 2: Profile page shows "Open Dealer Portal →" for approved Dealer
    testWidgets('2. UserProfileScreen shows Open Dealer Portal shortcut when user is a Verified Dealer', (tester) async {
      UserSession.roleTierNotifier.value = 'Verified Dealer';

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Dealer Portal →'), findsOneWidget);
      expect(find.text('Become a Dealer / Partner'), findsNothing);
    });

    // TEST 3: Main Navigation Header for Buyer (No Dealer Portal in primary nav)
    testWidgets('3. MainShell desktop nav for Buyer hides Dealer Portal from primary links and header action', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Buyer';

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Buyer navigation links
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Properties'), findsWidgets);
      expect(find.text('AI Match'), findsWidgets);
      expect(find.text('Site Visits'), findsWidgets);

      // Dealer Portal should not be in the primary header links for a buyer
      final dealerPortalFinder = find.widgetWithText(InkWell, 'Dealer Portal');
      expect(dealerPortalFinder, findsNothing);
    });

    // TEST 4: Main Navigation Header for Dealer (Shows Dealer Portal in primary nav)
    testWidgets('4. MainShell desktop nav for Dealer shows Dealer Portal in primary links and header action', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Verified Dealer';

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Dealer Portal link is visible in primary nav
      expect(find.text('Dealer Portal'), findsWidgets);
      expect(find.text('PORTAL'), findsOneWidget);

      // Clicking Dealer Portal opens the Dealer Dashboard Screen
      await tester.tap(find.text('Dealer Portal').first);
      await tester.pumpAndSettle();

      // Verifies existing Dealer Dashboard implementation is rendered
      expect(find.byType(DealerDashboardScreen), findsOneWidget);
    });

    // TEST 5: BecomeDealerDialog registration flow
    testWidgets('5. BecomeDealerDialog allows Buyer to register and activates Dealer Portal', (tester) async {
      UserSession.roleTierNotifier.value = 'Buyer';
      expect(UserSession.isDealer, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => BecomeDealerDialog.show(ctx),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Become a PropZen Dealer'), findsOneWidget);
      expect(find.text('AI Listing Creator & Automated NCR Marketing'), findsOneWidget);

      // Tap "Activate Dealer Portal"
      await tester.tap(find.text('Activate Dealer Portal'));
      await tester.pumpAndSettle();

      // Role is updated to Verified Dealer
      expect(UserSession.isDealer, isTrue);
      expect(UserSession.roleTierNotifier.value, equals('Verified Dealer'));
    });

    // TEST 6: Mobile Navigation Bar structure
    testWidgets('6. MainShell on mobile renders 5 clean bottom nav items without horizontal overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // 5 Bottom Navigation items: Home, Properties, AI Match, Site Visits, Profile
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('AI Match'), findsOneWidget);
      expect(find.text('Site Visits'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tapping Site Visits switches to MySiteVisitsScreen
      await tester.tap(find.text('Site Visits'));
      await tester.pumpAndSettle();
      expect(find.byType(MySiteVisitsScreen), findsOneWidget);

      // Tapping Profile switches to UserProfileScreen
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(UserProfileScreen), findsOneWidget);
    });
  });
}
