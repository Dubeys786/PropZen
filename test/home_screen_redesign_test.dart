import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/screens/find_my_perfect_property_screen.dart';
import 'package:dealghar_ncr_10x/screens/property_search_screen.dart';
import 'package:dealghar_ncr_10x/screens/ai_advisor_chat_screen.dart';

// 1x1 transparent PNG to satisfy flutter_test NetworkImage resolution
final List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
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
  void addAuthenticate(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpClientRequest();
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse();
  }
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

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
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('PropZen HomeScreen UI & Functional Tests', () {
    testWidgets('1. Hero Section & Main Headings Render Accurately', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Main Heading & Subtitle
      expect(find.text('Find Your Perfect Property, Smarter.'), findsOneWidget);
      expect(find.text('AI-powered property discovery, verification and site visits — all in one place.'), findsOneWidget);

      // Verify Search Bar and CTAs
      expect(find.text('Find My Perfect Property'), findsWidgets);
      expect(find.text('Explore Properties'), findsWidgets);
      expect(find.text('Talk to PropZen AI'), findsOneWidget);
      expect(find.text('Search by location, project or property type'), findsOneWidget);
    });

    testWidgets('2. AI Property Advisor Card Renders with Live Button', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not sure what property is right for you?'), findsOneWidget);
      expect(find.text('Tell PropZen your budget and preferences. Our AI will find the best matches for you.'), findsOneWidget);

      final askAiBtnText = find.text('Ask AI Advisor');
      expect(askAiBtnText, findsOneWidget);

      await tester.ensureVisible(askAiBtnText);
      await tester.tap(askAiBtnText);
      await tester.pumpAndSettle();

      // Navigated to AI Advisor Chat
      expect(find.byType(AiAdvisorChatScreen), findsOneWidget);
    });

    testWidgets('3. Featured Properties, Smart Discovery, & Trust Sections Render', (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Featured Properties
      expect(find.text('Featured Properties'), findsOneWidget);
      expect(find.text('View All'), findsWidgets);

      // Smart Discovery ("Explore Properties Your Way")
      expect(find.text('Explore Properties Your Way'), findsOneWidget);
      expect(find.text('2 BHK'), findsOneWidget);
      expect(find.text('3 BHK'), findsOneWidget);
      expect(find.text('Luxury Villas'), findsOneWidget);
      expect(find.text('Ready to Move'), findsWidgets);
      expect(find.text('Commercial'), findsWidgets);
      expect(find.text('Plots'), findsOneWidget);
      expect(find.text('Noida'), findsOneWidget);
      expect(find.text('Greater Noida'), findsOneWidget);
      expect(find.text('Yamuna Expressway'), findsOneWidget);
      expect(find.text('Noida Extension'), findsOneWidget);

      // Why Choose PropZen
      expect(find.text('Why Choose PropZen?'), findsOneWidget);
      expect(find.text('AI-Powered Discovery'), findsOneWidget);
      expect(find.text('Property Verification'), findsOneWidget);
      expect(find.text('Smart Site Visits'), findsOneWidget);
      expect(find.text('Complete Deal Journey'), findsOneWidget);
    });

    testWidgets('4. Powered by AI, Service Hub, How It Works, & Dealer CTA Render', (tester) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Powered by PropZen AI
      expect(find.text('Powered by PropZen AI'), findsOneWidget);
      expect(find.text('AI Property Advisor'), findsOneWidget);
      expect(find.text('AI Voice Agent'), findsOneWidget);
      expect(find.text('AI Property Matching'), findsOneWidget);
      expect(find.text('AI Listing Creator'), findsOneWidget);
      expect(find.text('AI Lead Scoring'), findsOneWidget);
      expect(find.text('AI Property Verification'), findsOneWidget);

      // PropZen Service Hub
      expect(find.text('PropZen Service Hub'), findsOneWidget);
      expect(find.text('Home Design'), findsOneWidget);
      expect(find.text('Interior Design'), findsOneWidget);
      expect(find.text('Exterior Design'), findsOneWidget);
      expect(find.text('Vastu Consultancy'), findsOneWidget);
      expect(find.text('Document Verification'), findsOneWidget);
      expect(find.text('Loan Consultancy'), findsOneWidget);
      expect(find.text('Construction Support'), findsOneWidget);
      expect(find.text('3D Visualization'), findsOneWidget);
      expect(find.text('Explore All Services'), findsOneWidget);

      // How PropZen Works
      expect(find.text('How PropZen Works'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(find.text('Visit'), findsOneWidget);
      expect(find.text('04'), findsOneWidget);
      expect(find.text('Decide'), findsOneWidget);

      // Know Your Locality & Removal of Dealer CTA
      expect(find.text('Know Your Locality'), findsOneWidget);
      expect(find.text('Explore Locality'), findsOneWidget);
      expect(find.text('For Dealers & Brokers'), findsNothing);

      // Final CTA
      expect(find.text('Your Next Property Starts Here.'), findsOneWidget);
      expect(find.text('Discover smarter. Verify confidently. Visit easily.'), findsOneWidget);
    });

    testWidgets('5. Smart Category Click (e.g. 2 BHK) routes to PropertySearchScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final twoBhkChip = find.text('2 BHK');
      expect(twoBhkChip, findsOneWidget);

      await tester.ensureVisible(twoBhkChip);
      await tester.tap(twoBhkChip);
      await tester.pumpAndSettle();

      expect(find.byType(PropertySearchScreen), findsOneWidget);
    });

    testWidgets('6. Find My Perfect Property button routes correctly', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final findBtnText = find.text('Find My Perfect Property').first;
      expect(findBtnText, findsOneWidget);

      await tester.ensureVisible(findBtnText);
      await tester.tap(findBtnText);
      await tester.pumpAndSettle();

      expect(find.byType(FindMyPerfectPropertyScreen), findsOneWidget);
    });
  });
}
