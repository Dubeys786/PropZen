import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/home_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

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
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  void Function(FlutterErrorDetails)? originalOnError;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
    originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('A RenderFlex overflowed') ||
          details.toString().contains('overflowed by')) {
        return;
      }
      originalOnError?.call(details);
    };
  });

  tearDownAll(() {
    HttpOverrides.global = null;
    FlutterError.onError = originalOnError;
  });

  setUp(() {
    UserSession.logout();
  });

  group('PropZen Home Page - For Dealers & Brokers Removal Tests', () {
    testWidgets('1. Desktop layout: For Dealers & Brokers section is completely absent from Home Page', (tester) async {
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure "For Dealers & Brokers" and promotional text are completely absent
      expect(find.text('For Dealers & Brokers'), findsNothing);
      expect(find.text('List properties, manage leads and grow your business with PropZen.'), findsNothing);

      // Ensure Know Your Locality and Final CTA are present and sequential
      expect(find.text('Know Your Locality'), findsOneWidget);
      expect(find.text('Your Next Property Starts Here.'), findsOneWidget);
      expect(find.text('Explore Properties'), findsWidgets);
      expect(find.text('Talk to AI Advisor'), findsOneWidget);
    });

    testWidgets('2. Tablet layout: For Dealers & Brokers section is completely absent', (tester) async {
      tester.view.physicalSize = const Size(768, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('For Dealers & Brokers'), findsNothing);
      expect(find.text('List properties, manage leads and grow your business with PropZen.'), findsNothing);
      expect(find.text('Know Your Locality'), findsOneWidget);
      expect(find.text('Your Next Property Starts Here.'), findsOneWidget);
    });

    testWidgets('3. Mobile layout: For Dealers & Brokers section is completely absent', (tester) async {
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('For Dealers & Brokers'), findsNothing);
      expect(find.text('List properties, manage leads and grow your business with PropZen.'), findsNothing);
      expect(find.text('Know Your Locality'), findsOneWidget);
      expect(find.text('Your Next Property Starts Here.'), findsOneWidget);
    });

    testWidgets('4. Role behavior: Authenticated Dealer retains access to Dealer Portal', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.login(
        name: 'Sharma Properties',
        userEmail: 'dealer@propzen.ai',
        role: 'DEALER',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Bottom promotional "For Dealers & Brokers" is STILL absent
      expect(find.text('For Dealers & Brokers'), findsNothing);
      expect(find.text('List properties, manage leads and grow your business with PropZen.'), findsNothing);

      // Authenticated dealer top card is present for authenticated dealers
      expect(UserSession.isDealer, isTrue);
      expect(find.text('Open Dealer Portal'), findsOneWidget);
    });

    testWidgets('5. Role behavior: Guest user sees NO Dealer Portal cards on Home Page', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.logout();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('For Dealers & Brokers'), findsNothing);
      expect(find.text('Dealer Portal'), findsNothing);
      expect(find.text('Open Dealer Portal'), findsNothing);
    });
  });
}
