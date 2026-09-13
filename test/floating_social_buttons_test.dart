import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/config/social_config.dart';
import 'package:dealghar_ncr_10x/widgets/floating_social_buttons.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
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
    return Stream<List<int>>.value(_kTransparentImage).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();
  group('PropZen Floating Social Icons & Configuration Tests', () {
    // TEST 1: SocialConfig Configuration Variables & URLs
    test('1. SocialConfig contains centralized Instagram and WhatsApp configurations', () {
      // Instagram configuration
      expect(SocialConfig.instagramUrl, isNotEmpty);
      expect(SocialConfig.instagramUrl, equals('https://www.instagram.com/propz_en/?hl=en'));

      // WhatsApp configuration
      expect(SocialConfig.whatsappNumber, isNotEmpty);
      expect(SocialConfig.whatsappNumber, equals('919810394068'));
      expect(SocialConfig.isWhatsAppConfigured, isTrue);

      // WhatsApp Click-to-Chat URL
      expect(SocialConfig.whatsappChatUrl, contains('https://wa.me/919810394068'));
      expect(SocialConfig.whatsappChatUrl, contains('text='));
    });

    // TEST 2: FloatingSocialButtons widget renders Instagram on top and WhatsApp below
    testWidgets('2. FloatingSocialButtons renders Instagram on top and WhatsApp below in vertical order', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingSocialButtons(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find both buttons
      final instagramFinder = find.byKey(const Key('floating_instagram_button'));
      final whatsappFinder = find.byKey(const Key('floating_whatsapp_button'));

      expect(instagramFinder, findsOneWidget);
      expect(whatsappFinder, findsOneWidget);

      // Check vertical ordering: Instagram top position must be less than WhatsApp top position (Instagram above WhatsApp)
      final instagramTop = tester.getTopLeft(instagramFinder).dy;
      final whatsappTop = tester.getTopLeft(whatsappFinder).dy;

      expect(instagramTop, lessThan(whatsappTop), reason: 'Instagram must be positioned above WhatsApp');

      // Check icons
      expect(find.byIcon(LucideIcons.instagram), findsOneWidget);
      expect(find.byType(WhatsAppOutlineWidget), findsOneWidget);
    });

    // TEST 3: Accessibility Semantics & Tooltips
    testWidgets('3. Floating social buttons provide accessible semantics labels and tooltips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingSocialButtons(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tooltips
      expect(find.byTooltip('Open PropZen Instagram'), findsOneWidget);
      expect(find.byTooltip('Chat with PropZen on WhatsApp'), findsOneWidget);

      // Semantics
      expect(find.bySemanticsLabel('Open PropZen Instagram'), findsOneWidget);
      expect(find.bySemanticsLabel('Chat with PropZen on WhatsApp'), findsOneWidget);
    });

    // TEST 4: Responsive Sizing on Desktop, Tablet, and Mobile
    testWidgets('4. Responsive sizing adapts button sizes smoothly for Desktop, Tablet, and Mobile', (tester) async {
      // A. Desktop (width >= 1024)
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingSocialButtons(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final desktopIgSize = tester.getSize(find.byKey(const Key('floating_instagram_button')));
      expect(desktopIgSize.width, equals(46.0));
      expect(desktopIgSize.height, equals(46.0));

      // B. Tablet (600 <= width < 1024)
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingSocialButtons(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tabletIgSize = tester.getSize(find.byKey(const Key('floating_instagram_button')));
      expect(tabletIgSize.width, equals(42.0));
      expect(tabletIgSize.height, equals(42.0));

      // C. Mobile (width < 600)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingSocialButtons(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mobileIgSize = tester.getSize(find.byKey(const Key('floating_instagram_button')));
      expect(mobileIgSize.width, equals(40.0));
      expect(mobileIgSize.height, equals(40.0));
    });

    // TEST 5: Integration in MainShell
    testWidgets('5. MainShell integrates FloatingSocialButtons without obscuring navigation on mobile', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify FloatingSocialButtons exists in MainShell
      expect(find.byType(FloatingSocialButtons), findsOneWidget);
      expect(find.byKey(const Key('floating_instagram_button')), findsOneWidget);
      expect(find.byKey(const Key('floating_whatsapp_button')), findsOneWidget);

      // Verify BottomNavigationBar remains visible on Mobile
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Floating buttons should sit above the bottom navigation bar
      final socialButtonsBottom = tester.getBottomRight(find.byType(FloatingSocialButtons)).dy;
      final bottomNavTop = tester.getTopLeft(find.byType(BottomNavigationBar)).dy;

      expect(socialButtonsBottom, lessThanOrEqualTo(bottomNavTop + 20),
          reason: 'Floating social buttons must sit cleanly positioned above or aligned with bottom nav');
    });

    // TEST 6: Tap Handlers trigger without error
    testWidgets('6. Tapping Instagram and WhatsApp buttons triggers url launch handlers safely', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingSocialButtons(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Instagram
      await tester.tap(find.byKey(const Key('floating_instagram_button')));
      await tester.pump();

      // Tap WhatsApp
      await tester.tap(find.byKey(const Key('floating_whatsapp_button')));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // TEST 7: UserProfileScreen Floating Social Buttons Layout & Styling
    testWidgets('7. UserProfileScreen renders a single vertically stacked floating social container (Instagram top, WhatsApp below, equal circular size, proper gap)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify exactly ONE instance of FloatingSocialButtons exists (no duplicates)
      expect(find.byType(FloatingSocialButtons), findsOneWidget);
      final igFinder = find.byKey(const Key('floating_instagram_button'));
      final waFinder = find.byKey(const Key('floating_whatsapp_button'));
      expect(igFinder, findsOneWidget);
      expect(waFinder, findsOneWidget);

      // 2. Instagram MUST be at the top, WhatsApp directly BELOW
      final igTop = tester.getTopLeft(igFinder).dy;
      final waTop = tester.getTopLeft(waFinder).dy;
      expect(igTop, lessThan(waTop), reason: 'Instagram button must be placed above WhatsApp');

      // 3. Clear vertical gap between 12-16px (14px on desktop)
      final igBottom = tester.getBottomRight(igFinder).dy;
      final verticalGap = waTop - igBottom;
      expect(verticalGap, inInclusiveRange(12.0, 16.0), reason: 'Vertical gap between social buttons must be 12-16px');

      // 4. Both buttons must have the same circular size
      final igSize = tester.getSize(igFinder);
      final waSize = tester.getSize(waFinder);
      expect(igSize.width, equals(waSize.width));
      expect(igSize.height, equals(waSize.height));
      expect(igSize.width, equals(igSize.height), reason: 'Buttons must be square/circular');

      // 5. Both buttons must be aligned to the same right edge
      final igRight = tester.getBottomRight(igFinder).dx;
      final waRight = tester.getBottomRight(waFinder).dx;
      expect(igRight, equals(waRight), reason: 'Both buttons must align to the exact same right edge');

      // 6. Safe right and bottom margins (approx 20-24px on desktop)
      final screenWidth = 1280.0;
      final screenHeight = 800.0;
      final waBottom = tester.getBottomRight(waFinder).dy;
      final rightMargin = screenWidth - waRight;
      final bottomMargin = screenHeight - waBottom;
      expect(rightMargin, inInclusiveRange(20.0, 24.0), reason: 'Right margin must be approximately 20-24px');
      expect(bottomMargin, inInclusiveRange(20.0, 24.0), reason: 'Bottom margin must be approximately 20-24px');
    });

    // TEST 8: Deduplication in MainShell on Profile Tab
    testWidgets('8. MainShell suppresses FAB on Profile tab so UserProfileScreen has no duplicate overlapping buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // On tab 0 (Home), exactly one instance exists from MainShell
      expect(find.byType(FloatingSocialButtons), findsOneWidget);

      // Switch to tab 4 (Profile)
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        await tester.tap(find.text('Profile'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // After switching to Profile tab, there must still be EXACTLY ONE FloatingSocialButtons
        expect(find.byType(FloatingSocialButtons), findsOneWidget);
        expect(find.byKey(const Key('floating_instagram_button')), findsOneWidget);
        expect(find.byKey(const Key('floating_whatsapp_button')), findsOneWidget);
      }
    });
  });
}
