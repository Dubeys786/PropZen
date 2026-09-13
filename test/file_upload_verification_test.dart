import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property_document.dart';
import 'package:dealghar_ncr_10x/services/supabase_storage_service.dart';
import 'package:dealghar_ncr_10x/screens/post_property_screen.dart';

final _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
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
  Future<HttpClientRequest> postUrl(Uri url) async => _MockHttpClientRequest();
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
  void add(List<int> data) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  void write(Object? obj) {}
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
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get persistentConnection => true;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode('{"Key":"property-documents/test.pdf"}')).listen(
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
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('File Upload & Supabase Storage Verification Tests', () {
    test('TEST 1: PropertyDocument model formats sizes and determines file types accurately', () {
      final docPdf = PropertyDocument(
        id: 'doc_1',
        fileName: 'RERA_certificate.pdf',
        fileSizeBytes: 2456789, // ~2.3 MB
        mimeType: 'application/pdf',
        documentType: 'rera',
        storagePath: 'usr_1/prop_1/rera/RERA_certificate.pdf',
        fileUrl: 'https://eemxylswyvhsyzllcsnp.supabase.co/storage/v1/object/public/property-documents/usr_1/prop_1/rera/RERA_certificate.pdf',
        uploadedAt: DateTime.now(),
      );

      expect(docPdf.isPdf, isTrue);
      expect(docPdf.isImage, isFalse);
      expect(docPdf.formattedSize, '2.3 MB');

      final docSmall = PropertyDocument(
        id: 'doc_2',
        fileName: 'floorplan.png',
        fileSizeBytes: 450 * 1024, // 450 KB
        mimeType: 'image/png',
        documentType: 'floor_plan',
        storagePath: 'usr_1/prop_1/floor-plan/floorplan.png',
        fileUrl: 'https://eemxylswyvhsyzllcsnp.supabase.co/storage/v1/object/public/property-documents/usr_1/prop_1/floor-plan/floorplan.png',
        uploadedAt: DateTime.now(),
      );

      expect(docSmall.isImage, isTrue);
      expect(docSmall.formattedSize, '450.0 KB');
    });

    test('TEST 2: SupabaseStorageService resolves correct MIME types for allowed formats', () {
      expect(SupabaseStorageService.resolveMimeType('RERA_certificate.pdf'), 'application/pdf');
      expect(SupabaseStorageService.resolveMimeType('photo1.jpg'), 'image/jpeg');
      expect(SupabaseStorageService.resolveMimeType('photo2.jpeg'), 'image/jpeg');
      expect(SupabaseStorageService.resolveMimeType('blueprint.png'), 'image/png');
      expect(SupabaseStorageService.resolveMimeType('render.webp'), 'image/webp');
      expect(SupabaseStorageService.resolveMimeType('document.txt'), 'application/octet-stream');
    });

    test('TEST 3: SupabaseStorageService uploads binary bytes and returns structured UploadResult', () async {
      final testBytes = Uint8List.fromList(utf8.encode('%PDF-1.4 Mock RERA Certificate bytes'));
      final result = await SupabaseStorageService.instance.uploadBinary(
        bucket: SupabaseStorageService.documentsBucket,
        path: 'test_user/test_prop/rera/RERA_certificate.pdf',
        bytes: testBytes,
        contentType: 'application/pdf',
        userId: 'usr_test_101',
        propertyId: 'PROP-TEST-001',
        documentType: 'RERA Registration Certificate',
        fileName: 'RERA_certificate.pdf',
      );

      expect(result.isSuccess, isTrue);
      expect(result.storagePath, 'test_user/test_prop/rera/RERA_certificate.pdf');
      expect(result.fileUrl, contains('property-documents/test_user/test_prop/rera/RERA_certificate.pdf'));
    });

    testWidgets('TEST 4: PostPropertyScreen Step 6 renders clickable RERA, Floor Plan and Photo upload cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PostPropertyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Step 6: Documents (Step 1 -> 2 -> 3 -> 4 -> 5 -> 6)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }

      // Verify Step 6 header and upload cards
      expect(find.text('Verification Documents & RERA'), findsOneWidget);
      expect(find.text('RERA Registration Certificate'), findsOneWidget);
      expect(find.text('Master Floor Plan (2D/3D Blueprint)'), findsOneWidget);
      expect(find.textContaining('Property Photos'), findsOneWidget);
      expect(find.text('Add Photos'), findsOneWidget);
    });
  });
}
