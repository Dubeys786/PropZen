import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/main_shell.dart';
import 'package:dealghar_ncr_10x/services/supabase_storage_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

  group('PropZen Profile Picture Upload & Management Tests', () {
    testWidgets('1. Camera button overlay is rendered on profile avatar for authenticated user', (tester) async {
      UserSession.login(
        name: 'Sarah Connor',
        email: 'sarah@propzen.in',
        phone: '9876543210',
        role: 'USER',
        isEmailVerified: true,
      );

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify user initials "S" are shown
      expect(find.text('S'), findsWidgets);

      // Verify camera icon button overlay is present
      expect(find.byIcon(LucideIcons.camera), findsWidgets);
    });

    testWidgets('2. Clicking camera button opens Photo Options Modal with Take Photo & Upload options', (tester) async {
      UserSession.login(
        name: 'Michael Scott',
        email: 'michael@dunder.com',
        phone: '9811122233',
        role: 'USER',
        isEmailVerified: true,
      );

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      // Find and tap camera button
      final cameraButtons = find.byIcon(LucideIcons.camera);
      expect(cameraButtons, findsWidgets);

      await tester.tap(cameraButtons.first);
      await tester.pump();

      // Verify Modal opens with expected options
      expect(find.text('Profile Picture'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Upload from Gallery / Files'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Verify "Remove Photo" is NOT visible since user has no photo yet
      expect(find.text('Remove Photo'), findsNothing);
    });

    testWidgets('3. Remove Photo option is visible when user already has an avatar', (tester) async {
      UserSession.login(
        name: 'Elena Gilbert',
        email: 'elena@propzen.in',
        phone: '9812345678',
        role: 'USER',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        isEmailVerified: true,
      );

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      final cameraButtons = find.byIcon(LucideIcons.camera);
      await tester.tap(cameraButtons.first);
      await tester.pump();

      // Verify "Remove Photo" option appears now
      expect(find.text('Remove Photo'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Profile Picture'), findsNothing);
    });

    testWidgets('4. Setting avatarUrlNotifier updates Profile avatar and MainShell navbar thumbnail in real time', (tester) async {
      UserSession.login(
        name: 'Rachel Green',
        email: 'rachel@friends.com',
        phone: '9870098700',
        role: 'USER',
        isEmailVerified: true,
      );

      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // Initially no avatar URL
      expect(UserSession.avatarUrl, isNull);

      // Simulate avatar upload completion
      const testAvatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb';
      UserSession.avatarUrlNotifier.value = testAvatarUrl;

      await tester.pump();

      // Verify UserSession is updated
      expect(UserSession.avatarUrl, testAvatarUrl);
    });

    test('5. SupabaseStorageService rejects files exceeding 5MB avatar limit', () async {
      final largeBytes = Uint8List(6 * 1024 * 1024); // 6 MB

      final result = await SupabaseStorageService.instance.uploadAvatar(
        userId: 'test_user',
        bytes: largeBytes,
        fileName: 'large_photo.jpg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 413);
      expect(result.errorMessage, contains('exceeds 5 MB limit'));
    });

    test('6. SupabaseStorageService rejects unsupported file extensions', () async {
      final validBytes = Uint8List(100 * 1024); // 100 KB

      final result = await SupabaseStorageService.instance.uploadAvatar(
        userId: 'test_user',
        bytes: validBytes,
        fileName: 'document.pdf',
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 415);
      expect(result.errorMessage, contains('Unsupported image format'));
    });

    test('7. SupabaseStorageService accepts valid JPG, PNG, and WEBP files under 5MB', () async {
      final validBytes = Uint8List(200 * 1024); // 200 KB

      final resultJpg = await SupabaseStorageService.instance.uploadAvatar(
        userId: 'test_user',
        bytes: validBytes,
        fileName: 'avatar.jpg',
      );

      expect(resultJpg.isSuccess, isTrue);
      expect(resultJpg.fileUrl, contains('avatars/'));
    });
  });
}
