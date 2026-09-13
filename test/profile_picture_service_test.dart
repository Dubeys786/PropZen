import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/profile_image_picker_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Picture Validation Tests', () {
    test('Accepts valid image formats under 5 MB', () {
      const validSize = 1024 * 1024; // 1 MB

      expect(
        ProfileImagePickerService.validateImage(fileName: 'avatar.jpg', sizeBytes: validSize),
        isNull,
      );
      expect(
        ProfileImagePickerService.validateImage(fileName: 'photo.JPEG', sizeBytes: validSize),
        isNull,
      );
      expect(
        ProfileImagePickerService.validateImage(fileName: 'profile.png', sizeBytes: validSize),
        isNull,
      );
      expect(
        ProfileImagePickerService.validateImage(fileName: 'user_pic.webp', sizeBytes: validSize),
        isNull,
      );
    });

    test('Rejects images exceeding 5 MB limit with exact error message', () {
      const oversize = (5 * 1024 * 1024) + 1; // 5 MB + 1 byte

      final result = ProfileImagePickerService.validateImage(
        fileName: 'huge_photo.jpg',
        sizeBytes: oversize,
      );

      expect(result, equals('Image must be smaller than 5 MB.'));
    });

    test('Rejects unsupported formats with exact error message', () {
      const validSize = 500 * 1024; // 500 KB

      expect(
        ProfileImagePickerService.validateImage(fileName: 'document.pdf', sizeBytes: validSize),
        equals('Please upload a JPG, PNG, JPEG or WEBP image.'),
      );
      expect(
        ProfileImagePickerService.validateImage(fileName: 'animation.gif', sizeBytes: validSize),
        equals('Please upload a JPG, PNG, JPEG or WEBP image.'),
      );
      expect(
        ProfileImagePickerService.validateImage(fileName: 'script.exe', sizeBytes: validSize),
        equals('Please upload a JPG, PNG, JPEG or WEBP image.'),
      );
      expect(
        ProfileImagePickerService.validateImage(fileName: 'no_extension', sizeBytes: validSize),
        equals('Please upload a JPG, PNG, JPEG or WEBP image.'),
      );
    });
  });

  group('Supabase Storage Avatar Validation Tests', () {
    test('SupabaseStorageService validates oversized avatar bytes', () async {
      final oversizedBytes = Uint8List((5 * 1024 * 1024) + 10);
      final result = await SupabaseStorageService.instance.uploadAvatar(
        userId: 'test-user-123',
        bytes: oversizedBytes,
        fileName: 'avatar.jpg',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Image must be smaller than 5 MB.'));
    });

    test('SupabaseStorageService validates unsupported file extension', () async {
      final validBytes = Uint8List(100);
      final result = await SupabaseStorageService.instance.uploadAvatar(
        userId: 'test-user-123',
        bytes: validBytes,
        fileName: 'resume.pdf',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Please upload a JPG, PNG, JPEG or WEBP image.'));
    });
  });

  group('Image Cropping & Optimization Tests', () {
    test('optimizeAvatarImage crops and produces valid 512x512 JPEG', () {
      // Create a test 600x400 image in memory
      final testImage = img.Image(width: 600, height: 400);
      img.fill(testImage, color: img.ColorRgb8(124, 58, 237)); // PropZen Purple
      final rawBytes = Uint8List.fromList(img.encodeJpg(testImage));

      final optimizedBytes = ProfileImagePickerService.optimizeAvatarImage(
        rawBytes,
        targetDimension: 512,
        zoom: 1.2,
      );

      expect(optimizedBytes, isNotEmpty);
      expect(optimizedBytes.length, lessThan(5 * 1024 * 1024));

      // Decode optimized image and verify dimensions
      final decoded = img.decodeImage(optimizedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(512));
      expect(decoded.height, equals(512));
    });
  });

  group('UserSession Avatar Reactivity Tests', () {
    test('avatarUrlNotifier broadcasts changes and updates session state', () {
      UserSession.logout();
      expect(UserSession.avatarUrl, isNull);

      String? notifiedValue;
      void listener() {
        notifiedValue = UserSession.avatarUrlNotifier.value;
      }

      UserSession.avatarUrlNotifier.addListener(listener);

      const testUrl = 'https://supabase.propzen.com/storage/v1/object/public/profile-avatars/user-1/avatar.jpg?v=123';
      UserSession.avatarUrlNotifier.value = testUrl;

      expect(notifiedValue, equals(testUrl));
      expect(UserSession.avatarUrl, equals(testUrl));

      UserSession.logout();
      expect(notifiedValue, isNull);
      expect(UserSession.avatarUrl, isNull);

      UserSession.avatarUrlNotifier.removeListener(listener);
    });
  });
}
