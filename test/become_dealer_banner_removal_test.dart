import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/global_search_service.dart';

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
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  setUp(() {
    UserSession.logout();
    UserSession.roleTierNotifier.value = 'Buyer';
  });

  group('Become a Dealer / Partner Banner Removal Verification', () {
    testWidgets('1. Mobile: Promotional banner is completely removed from UserProfileScreen', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Buyer';

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Become a Dealer / Partner'), findsNothing);
      expect(find.text('Join 500+ Top NCR Brokers & Unlock AI Lead Tools'), findsNothing);
      expect(find.text('Apply Now →'), findsNothing);

      // Verify personal profile sections exist
      expect(find.text('My Enquiries'), findsOneWidget);
    });

    testWidgets('2. Tablet: Promotional banner is completely removed from UserProfileScreen', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Buyer';

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Become a Dealer / Partner'), findsNothing);
      expect(find.text('Join 500+ Top NCR Brokers & Unlock AI Lead Tools'), findsNothing);
      expect(find.text('Apply Now →'), findsNothing);
    });

    testWidgets('3. Desktop: Promotional banner is completely removed from UserProfileScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Buyer';

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Become a Dealer / Partner'), findsNothing);
      expect(find.text('Join 500+ Top NCR Brokers & Unlock AI Lead Tools'), findsNothing);
      expect(find.text('Apply Now →'), findsNothing);
    });

    testWidgets('4. Verified Dealer: Shows Dealer Partner Portal shortcut and NOT the promotional banner', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      UserSession.roleTierNotifier.value = 'Verified Dealer';

      await tester.pumpWidget(
        const MaterialApp(
          home: UserProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open Dealer Portal →'), findsOneWidget);
      expect(find.text('Become a Dealer / Partner'), findsNothing);
      expect(find.text('Apply Now →'), findsNothing);
    });

    test('5. Dealer registration capability remains functional in search index', () {
      final results = GlobalSearchService.instance.search('dealer');
      final titles = results.map((e) => e.title).toList();
      expect(titles.contains('Become a Dealer / Partner'), isTrue);
    });
  });
}
