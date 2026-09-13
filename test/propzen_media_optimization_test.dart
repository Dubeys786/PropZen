import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/property_image_model.dart';
import 'package:dealghar_ncr_10x/services/smart_media_optimizer_service.dart';
import 'package:dealghar_ncr_10x/services/youtube_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Smart Media Upload & Storage Optimization Test Suite', () {
    // -------------------------------------------------------------------------
    // TEST 1: Oversized / Large Image Compression & Dimension Optimization
    // -------------------------------------------------------------------------
    test('TEST 1: Automatic compression & aspect-ratio dimension optimization for large images', () {
      // Create a simulated 2200x1500 high-res image
      final highResImg = img.Image(width: 2200, height: 1500);
      img.fill(highResImg, color: img.ColorRgb8(120, 150, 200));
      final highResRawBytes = Uint8List.fromList(img.encodeJpg(highResImg, quality: 90));

      expect(highResRawBytes.length, greaterThan(0));

      // 1. Optimize for Large Tier (Max 1920x1080)
      final largePayload = SmartMediaOptimizerService.instance.optimizeImage(
        rawBytes: highResRawBytes,
        tier: ImageTier.large,
      );

      expect(largePayload.width, lessThanOrEqualTo(1920));
      expect(largePayload.height, lessThanOrEqualTo(1080));
      expect(largePayload.bytes.length, lessThan(highResRawBytes.length));
      expect(largePayload.format, equals('jpg'));
      expect(largePayload.mimeType, equals('image/jpeg'));

      // 2. Optimize for Medium Tier (Max 1024x768)
      final medPayload = SmartMediaOptimizerService.instance.optimizeImage(
        rawBytes: highResRawBytes,
        tier: ImageTier.medium,
      );

      expect(medPayload.width, lessThanOrEqualTo(1024));
      expect(medPayload.height, lessThanOrEqualTo(768));
      expect(medPayload.bytes.length, lessThan(largePayload.bytes.length));

      // 3. Optimize for Thumbnail Tier (Max 400x300)
      final thumbPayload = SmartMediaOptimizerService.instance.optimizeImage(
        rawBytes: highResRawBytes,
        tier: ImageTier.thumbnail,
      );

      expect(thumbPayload.width, lessThanOrEqualTo(400));
      expect(thumbPayload.height, lessThanOrEqualTo(300));
      expect(thumbPayload.bytes.length, lessThan(medPayload.bytes.length));
    });

    // -------------------------------------------------------------------------
    // TEST 2: Disguised Executable & Malicious Script Rejection
    // -------------------------------------------------------------------------
    test('TEST 2: Strict rejection of executables, scripts, and disguised headers', () {
      // 1. Rejection of forbidden extension (.exe)
      final exeBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00]);
      final valExe = SmartMediaOptimizerService.validateImage(fileName: 'malware.exe', bytes: exeBytes);
      expect(valExe.isValid, isFalse);
      expect(valExe.errorMessage, contains('Forbidden file type'));

      // 2. Rejection of script file with .php
      final phpBytes = Uint8List.fromList('<?php echo "exploit"; ?>'.codeUnits);
      final valPhp = SmartMediaOptimizerService.validateImage(fileName: 'shell.php', bytes: phpBytes);
      expect(valPhp.isValid, isFalse);

      // 3. Disguised executable named "photo.jpg" with MZ magic header
      final disguisedBytes = Uint8List.fromList([0x4D, 0x5A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      final valDisguised = SmartMediaOptimizerService.validateImage(fileName: 'photo.jpg', bytes: disguisedBytes);
      expect(valDisguised.isValid, isFalse);
      expect(valDisguised.errorMessage, contains('verification failed'));

      // 4. Genuine JPEG with valid header
      final validJpgBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01]);
      final valJpg = SmartMediaOptimizerService.validateImage(fileName: 'living_room.jpg', bytes: validJpgBytes);
      expect(valJpg.isValid, isTrue);
      expect(valJpg.mimeType, equals('image/jpeg'));
    });

    // -------------------------------------------------------------------------
    // TEST 3: Multiple Property Image Batch Optimization
    // -------------------------------------------------------------------------
    test('TEST 3: Multiple property image batch processing and optimization', () {
      final imgA = img.Image(width: 1600, height: 1200);
      img.fill(imgA, color: img.ColorRgb8(200, 100, 50));
      final bytesA = Uint8List.fromList(img.encodeJpg(imgA));

      final imgB = img.Image(width: 1400, height: 900);
      img.fill(imgB, color: img.ColorRgb8(50, 200, 100));
      final bytesB = Uint8List.fromList(img.encodeJpg(imgB));

      final resA = SmartMediaOptimizerService.instance.optimizeImage(rawBytes: bytesA, tier: ImageTier.large);
      final resB = SmartMediaOptimizerService.instance.optimizeImage(rawBytes: bytesB, tier: ImageTier.large);

      expect(resA.sizeBytes, greaterThan(0));
      expect(resB.sizeBytes, greaterThan(0));
      expect(resA.width, lessThanOrEqualTo(1920));
      expect(resB.width, lessThanOrEqualTo(1920));
    });

    // -------------------------------------------------------------------------
    // TEST 4: Property Image Replacement and Unique Path Generation
    // -------------------------------------------------------------------------
    test('TEST 4: Property Image Model and unique storage path mapping', () {
      final imageModel = PropertyImageModel(
        id: 'IMG_123456789_01',
        propertyId: 'PROP_NOIDA_150',
        storagePath: 'properties/PROP_NOIDA_150/images/IMG_123456789_01_large.jpg',
        publicUrl: 'https://supabase.co/storage/v1/object/public/property-images/properties/PROP_NOIDA_150/images/IMG_123456789_01_large.jpg',
        mediumUrl: 'https://supabase.co/storage/v1/object/public/property-images/properties/PROP_NOIDA_150/images/IMG_123456789_01_med.jpg',
        thumbnailUrl: 'https://supabase.co/storage/v1/object/public/property-images/properties/PROP_NOIDA_150/images/IMG_123456789_01_thumb.jpg',
        width: 1920,
        height: 1080,
        fileSizeBytes: 420000,
        mimeType: 'image/jpeg',
        uploadedBy: 'dealer_9876543210',
        createdAt: DateTime.now().toIso8601String(),
      );

      final map = imageModel.toMap();
      expect(map['property_id'], equals('PROP_NOIDA_150'));
      expect(map['storage_path'], contains('properties/PROP_NOIDA_150/images/'));
      expect(imageModel.fileSizeFormatted, contains('KB'));

      final restored = PropertyImageModel.fromMap(map);
      expect(restored.id, equals('IMG_123456789_01'));
      expect(restored.publicUrl, equals(imageModel.publicUrl));
    });

    // -------------------------------------------------------------------------
    // TEST 5: Valid YouTube URL Extraction & Embed Generation
    // -------------------------------------------------------------------------
    test('TEST 5: Valid YouTube URL parsing across formats', () {
      // 1. Standard Watch URL
      final r1 = YouTubeMediaService.validateAndExtract('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(r1.isValid, isTrue);
      expect(r1.videoId, equals('dQw4w9WgXcQ'));
      expect(r1.embedUrl, contains('https://www.youtube.com/embed/dQw4w9WgXcQ'));
      expect(r1.thumbnailUrl, contains('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'));

      // 2. Short URL (youtu.be)
      final r2 = YouTubeMediaService.validateAndExtract('https://youtu.be/dQw4w9WgXcQ?si=abcdef12345');
      expect(r2.isValid, isTrue);
      expect(r2.videoId, equals('dQw4w9WgXcQ'));

      // 3. Embed URL
      final r3 = YouTubeMediaService.validateAndExtract('https://www.youtube.com/embed/dQw4w9WgXcQ');
      expect(r3.isValid, isTrue);
      expect(r3.videoId, equals('dQw4w9WgXcQ'));

      // 4. YouTube Shorts URL
      final r4 = YouTubeMediaService.validateAndExtract('https://www.youtube.com/shorts/dQw4w9WgXcQ');
      expect(r4.isValid, isTrue);
      expect(r4.videoId, equals('dQw4w9WgXcQ'));

      // 5. Direct 11-char ID
      final r5 = YouTubeMediaService.validateAndExtract('dQw4w9WgXcQ');
      expect(r5.isValid, isTrue);
      expect(r5.videoId, equals('dQw4w9WgXcQ'));
    });

    // -------------------------------------------------------------------------
    // TEST 6: Invalid & Non-YouTube URL Rejection
    // -------------------------------------------------------------------------
    test('TEST 6: Rejection of non-YouTube video hosts and dangerous links', () {
      // 1. Vimeo link
      final r1 = YouTubeMediaService.validateAndExtract('https://vimeo.com/12345678');
      expect(r1.isValid, isFalse);
      expect(r1.errorMessage, contains('Only official YouTube'));

      // 2. Direct MP4 link
      final r2 = YouTubeMediaService.validateAndExtract('https://example.com/property_video.mp4');
      expect(r2.isValid, isFalse);

      // 3. Script injection URL
      final r3 = YouTubeMediaService.validateAndExtract('javascript:alert(1)');
      expect(r3.isValid, isFalse);

      // 4. Empty string
      final r4 = YouTubeMediaService.validateAndExtract('');
      expect(r4.isValid, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Responsive Image Display Fallback & Prioritization
    // -------------------------------------------------------------------------
    test('TEST 7: Property model responsive display and thumbnail getters', () {
      const propWithOptimized = Property(
        id: 'PROP-01',
        title: 'Luxury Villa 150',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 3.5,
        imageUrl: 'https://images.unsplash.com/raw_large.jpg',
        optimizedMediumUrl: 'https://supabase.co/storage/prop_med.jpg',
        optimizedThumbnailUrl: 'https://supabase.co/storage/prop_thumb.jpg',
      );

      expect(propWithOptimized.displayImageUrl, equals('https://supabase.co/storage/prop_med.jpg'));
      expect(propWithOptimized.thumbnailImageUrl, equals('https://supabase.co/storage/prop_thumb.jpg'));

      const propWithoutOptimized = Property(
        id: 'PROP-02',
        title: 'Penthouse Express',
        sector: 'Sector 128',
        city: 'Noida',
        askingPriceCr: 4.2,
        imageUrl: 'https://images.unsplash.com/raw_fallback.jpg',
      );

      expect(propWithoutOptimized.displayImageUrl, equals('https://images.unsplash.com/raw_fallback.jpg'));
      expect(propWithoutOptimized.thumbnailImageUrl, equals('https://images.unsplash.com/raw_fallback.jpg'));
    });

    // -------------------------------------------------------------------------
    // TEST 8: Property YouTube Integration & Thumbnail Generation
    // -------------------------------------------------------------------------
    test('TEST 8: Property YouTube walk-through video flags and thumbnail URL', () {
      const propWithVideo = Property(
        id: 'PROP-03',
        title: 'Signature Towers',
        sector: 'Sector 72',
        city: 'Gurugram',
        askingPriceCr: 5.0,
        youtubeVideoId: 'dQw4w9WgXcQ',
        youtubeUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      expect(propWithVideo.hasYoutubeVideo, isTrue);
      expect(propWithVideo.youtubeThumbnailUrl, equals('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg'));
      expect(propWithVideo.officialYoutubeWatchUrl, equals('https://www.youtube.com/watch?v=dQw4w9WgXcQ'));

      const propWithoutVideo = Property(
        id: 'PROP-04',
        title: 'Green Meadows',
        sector: 'Sector 10',
        city: 'Greater Noida',
        askingPriceCr: 1.2,
      );

      expect(propWithoutVideo.hasYoutubeVideo, isFalse);
      expect(propWithoutVideo.youtubeThumbnailUrl, isEmpty);
    });

    // -------------------------------------------------------------------------
    // TEST 9: Unauthenticated Upload Protection
    // -------------------------------------------------------------------------
    test('TEST 9: Unauthenticated upload rejection in media optimization pipeline', () async {
      final dummyBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01]);
      final uploadRes = await SmartMediaOptimizerService.instance.uploadOptimizedPropertyImage(
        propertyId: 'PROP_TEST',
        userId: 'anon_user',
        rawBytes: dummyBytes,
        originalFileName: 'test.jpg',
        userRole: 'unauthenticated',
      );

      expect(uploadRes.isSuccess, isFalse);
      expect(uploadRes.errorMessage, contains('Authentication required'));
    });

    // -------------------------------------------------------------------------
    // TEST 10: Normal User Media Deletion Rejection (Anti-IDOR)
    // -------------------------------------------------------------------------
    test('TEST 10: Normal user cannot delete or tamper dealer media assets', () async {
      final deleteSuccess = await SmartMediaOptimizerService.instance.deletePropertyImage(
        propertyId: 'PROP_DEALER_01',
        storagePath: 'properties/PROP_DEALER_01/images/IMG_large.jpg',
        userId: 'regular_buyer_user_123',
        userRole: 'user',
      );

      expect(deleteSuccess, isFalse);
    });
  });
}
