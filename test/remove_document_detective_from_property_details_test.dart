import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/widgets/ai_property_verification_widget.dart';

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
  reraId: 'RC/REP/HARERA/GGM/680/412/2023/24',
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('Removal of AI Document Detective from Property Details Page', () {
    testWidgets('1. AiPropertyVerificationWidget desktop: contains NO AI Document Detective UI elements', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiPropertyVerificationWidget(property: testProperty),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure "AI Document Detective" text is completely absent
      expect(find.text('AI Document Detective'), findsNothing);
      expect(find.text('1. AI Document Detective'), findsNothing);
      expect(find.textContaining('Document Detective'), findsNothing);

      // Ensure "Check Now" or "Choose File & Scan" buttons/options are completely absent
      expect(find.text('Check Now'), findsNothing);
      expect(find.text('Choose File & Scan'), findsNothing);
      expect(find.text('Upload Property Documents for AI Analysis'), findsNothing);

      // Ensure remaining sections are properly rendered and renumbered
      expect(find.text('AI Property Verification Intelligence'), findsOneWidget);
      expect(find.text('1. Government & Official Record Checks'), findsOneWidget);
      expect(find.text('2. Property History Timeline'), findsOneWidget);
      expect(find.text('3. AI Clarification Inquiries & Discrepancies'), findsOneWidget);
      expect(find.text('4. Real-Time Property Alert Monitor'), findsOneWidget);
      expect(find.text('5. True Property Cost Calculator'), findsOneWidget);
    });

    testWidgets('2. AiPropertyVerificationWidget tablet: renders cleanly without Document Detective', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiPropertyVerificationWidget(property: testProperty),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Document Detective'), findsNothing);
      expect(find.text('Check Now'), findsNothing);
      expect(find.text('1. Government & Official Record Checks'), findsOneWidget);
      expect(find.text('2. Property History Timeline'), findsOneWidget);
    });

    testWidgets('3. AiPropertyVerificationWidget mobile: renders cleanly without Document Detective', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiPropertyVerificationWidget(property: testProperty),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Document Detective'), findsNothing);
      expect(find.text('Check Now'), findsNothing);
      expect(find.text('1. Government & Official Record Checks'), findsOneWidget);
      expect(find.text('2. Property History Timeline'), findsOneWidget);
    });
  });
}
