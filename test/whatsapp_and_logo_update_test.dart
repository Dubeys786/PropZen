import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/widgets/propzen_brand_header.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/screens/help_support_screen.dart';
import 'package:dealghar_ncr_10x/models/dealer.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/property_details_screen.dart';
import 'package:dealghar_ncr_10x/widgets/floating_social_buttons.dart';

class _MockHttpOverrides extends HttpOverrides {
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
  void addAuthentication(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();

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

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static final List<int> _kTransparentImage = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();

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
    HttpOverrides.global = _MockHttpOverrides();
  });
  group('WhatsApp Number and PropZen Logo Verification Suite', () {
    test('1. Logo asset exists and is accessible at assets/propzen_logo.png', () {
      final logoFile = File('assets/propzen_logo.png');
      expect(logoFile.existsSync(), isTrue);
      expect(logoFile.lengthSync(), greaterThan(10000));
    });

    test('2. Dealer models default to +91 98103 94068 for whatsapp and phone', () {
      const dealer = Dealer(
        id: 'dlr_test',
        name: 'Rajesh Varma',
        agency: 'Propzen Elite Deals',
        photoUrl: '',
        reraNumber: 'UPRERA123',
        experienceYears: 10,
        location: 'Sector 150',
        city: 'Noida',
        areasServed: ['Sector 150'],
        activeListingsCount: 5,
        rating: 4.9,
        reviewCount: 20,
        specialization: 'Luxury Apartments',
      );
      expect(dealer.whatsapp, equals('+91 98103 94068'));
      expect(dealer.phone, equals('+91 98103 94068'));
    });

    testWidgets('3. PropzenBrandHeader renders new logo with BoxFit.contain without distortion', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PropzenBrandHeader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      final imgWidget = tester.widget<Image>(find.byType(Image));
      expect((imgWidget.image as AssetImage).assetName, equals('assets/propzen_logo.png'));
      expect(imgWidget.fit, equals(BoxFit.contain));
    });

    testWidgets('4. Help & Support screen shows +91 98103 94068 and WhatsApp CTA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+91 98103 94068'), findsOneWidget);
      expect(find.text('WhatsApp Chat'), findsOneWidget);
    });

    testWidgets('5. PropertyDetailsScreen displays Direct Advisor Desk with +91 98103 94068', (tester) async {
      final prop = Property.sampleDeals.first;
      await tester.binding.setSurfaceSize(const Size(1400, 3000));
      await tester.pumpWidget(
        MaterialApp(
          home: PropertyDetailsScreen(property: prop, propertyId: prop.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Direct Advisor Desk (+91 98103 94068)'), findsOneWidget);
      expect(find.text('WhatsApp Support • Instant Response'), findsOneWidget);
    });

    testWidgets('6. MainShell top navigation bar renders PropZen logo and floating WhatsApp button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MainShell(),
          ),
        ),
      );
      await tester.pump();

      // Top logo
      expect(find.byType(Image), findsWidgets);
      // Floating Social Media Buttons (Instagram & WhatsApp)
      expect(find.byType(FloatingSocialButtons), findsOneWidget);
      expect(find.byKey(const Key('floating_whatsapp_button')), findsOneWidget);
      expect(find.byKey(const Key('floating_instagram_button')), findsOneWidget);
    });
  });
}
