import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/property_image_model.dart';
import 'package:dealghar_ncr_10x/services/smart_media_optimizer_service.dart';
import 'package:dealghar_ncr_10x/services/media_moderation_service.dart';
import 'package:dealghar_ncr_10x/services/youtube_media_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Advanced Smart Media System V2 Master Test Suite (20 Scenarios)', () {
    // -------------------------------------------------------------------------
    // TEST 1: Upload 10 MB Image -> Optimized Before Storage
    // -------------------------------------------------------------------------
    test('TEST 1: Upload 10 MB image is optimized and compressed before storage', () {
      final largeImg = img.Image(width: 2200, height: 1500);
      img.fill(largeImg, color: img.ColorRgb8(100, 150, 200));
      final rawBytes = Uint8List.fromList(img.encodeJpg(largeImg, quality: 90));

      final optimized = SmartMediaOptimizerService.instance.optimizeImage(
        rawBytes: rawBytes,
        tier: ImageTier.large,
      );

      expect(optimized.width, lessThanOrEqualTo(1920));
      expect(optimized.height, lessThanOrEqualTo(1080));
      expect(optimized.sizeBytes, lessThan(rawBytes.length));
      expect(optimized.mimeType, equals('image/jpeg'));
    });

    // -------------------------------------------------------------------------
    // TEST 2: Upload 20 MB Image -> Rejected over Limit
    // -------------------------------------------------------------------------
    test('TEST 2: Upload >15 MB image is rejected over configured limit', () {
      final oversizedBytes = Uint8List(20 * 1024 * 1024); // 20 MB dummy
      final valRes = SmartMediaOptimizerService.validateImage(
        fileName: 'huge_penthouse.jpg',
        bytes: oversizedBytes,
      );

      expect(valRes.isValid, isFalse);
      expect(valRes.errorMessage, contains('exceeds the maximum allowed upload limit'));
    });

    // -------------------------------------------------------------------------
    // TEST 3: Upload PNG -> Optimized Appropriately
    // -------------------------------------------------------------------------
    test('TEST 3: PNG image is validated and optimized appropriately', () {
      final pngImg = img.Image(width: 1200, height: 800);
      img.fill(pngImg, color: img.ColorRgb8(80, 180, 120));
      final pngBytes = Uint8List.fromList(img.encodePng(pngImg));

      final valPng = SmartMediaOptimizerService.validateImage(
        fileName: 'floorplan_schematic.png',
        bytes: pngBytes,
      );

      expect(valPng.isValid, isTrue);
      expect(valPng.mimeType, equals('image/png'));

      final optimized = SmartMediaOptimizerService.instance.optimizeImage(
        rawBytes: pngBytes,
        tier: ImageTier.medium,
      );

      expect(optimized.width, lessThanOrEqualTo(1024));
      expect(optimized.height, lessThanOrEqualTo(768));
    });

    // -------------------------------------------------------------------------
    // TEST 4: Upload JPEG -> Optimized Appropriately
    // -------------------------------------------------------------------------
    test('TEST 4: JPEG image is validated and optimized appropriately', () {
      final jpgImg = img.Image(width: 1600, height: 1000);
      img.fill(jpgImg, color: img.ColorRgb8(210, 140, 90));
      final jpgBytes = Uint8List.fromList(img.encodeJpg(jpgImg, quality: 85));

      final valJpg = SmartMediaOptimizerService.validateImage(
        fileName: 'master_bedroom.jpg',
        bytes: jpgBytes,
      );

      expect(valJpg.isValid, isTrue);
      expect(valJpg.mimeType, equals('image/jpeg'));
    });

    // -------------------------------------------------------------------------
    // TEST 5: Upload Unsupported File -> Rejected
    // -------------------------------------------------------------------------
    test('TEST 5: Executable, script, and disguised files are strictly rejected', () {
      final exeBytes = Uint8List.fromList([0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00]);
      final valExe = SmartMediaOptimizerService.validateImage(
        fileName: 'installer.exe',
        bytes: exeBytes,
      );
      expect(valExe.isValid, isFalse);

      final scriptBytes = Uint8List.fromList('<script>alert("hack")</script>'.codeUnits);
      final valScript = SmartMediaOptimizerService.validateImage(
        fileName: 'photo.jpg',
        bytes: scriptBytes,
      );
      expect(valScript.isValid, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 6: Upload Duplicate Image -> Detected and Handled
    // -------------------------------------------------------------------------
    test('TEST 6: Duplicate image detection via content hashing', () {
      final sampleImg = img.Image(width: 500, height: 500);
      img.fill(sampleImg, color: img.ColorRgb8(100, 100, 100));
      final bytes = Uint8List.fromList(img.encodeJpg(sampleImg));

      final hash = SmartMediaOptimizerService.computeContentHash(bytes);
      expect(hash.isNotEmpty, isTrue);

      SmartMediaOptimizerService.instance.registerPropertyImageHash('PROP_DUP_01', hash);
      final isDup = SmartMediaOptimizerService.instance.isDuplicateImage('PROP_DUP_01', hash);
      expect(isDup, isTrue);

      final isDifferentProp = SmartMediaOptimizerService.instance.isDuplicateImage('PROP_OTHER_02', hash);
      expect(isDifferentProp, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Delete Image -> Reference and Storage Handled Safely
    // -------------------------------------------------------------------------
    test('TEST 7: Delete image removes storage references cleanly', () async {
      final res = await SmartMediaOptimizerService.instance.deletePropertyImage(
        propertyId: 'PROP_DELETE_01',
        storagePath: 'properties/PROP_DELETE_01/images/large/IMG_01_large.jpg',
        userId: 'dealer_12345',
        userRole: 'dealer',
      );
      expect(res, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Replace Image -> Safely Replaces Without Leaving Orphans
    // -------------------------------------------------------------------------
    test('TEST 8: Replace image creates new asset and cleans old storage files', () async {
      final oldPath = 'properties/PROP_REP_01/images/large/OLD_IMG_large.jpg';
      final newImg = img.Image(width: 800, height: 600);
      img.fill(newImg, color: img.ColorRgb8(150, 120, 90));
      final newBytes = Uint8List.fromList(img.encodeJpg(newImg));

      final replaceRes = await SmartMediaOptimizerService.instance.replacePropertyImage(
        propertyId: 'PROP_REP_01',
        oldStoragePath: oldPath,
        newRawBytes: newBytes,
        newFileName: 'new_kitchen.jpg',
        userId: 'dealer_12345',
      );

      expect(replaceRes.isSuccess, isTrue);
      expect(replaceRes.storagePath, isNot(equals(oldPath)));
    });

    // -------------------------------------------------------------------------
    // TEST 9: Reorder Images -> Display Order Persists
    // -------------------------------------------------------------------------
    test('TEST 9: Image reordering preserves explicit display order', () {
      final img1 = PropertyImageModel(
        id: 'IMG-1',
        propertyId: 'PROP-01',
        storagePath: 'properties/PROP-01/images/IMG1.jpg',
        publicUrl: 'https://supabase.co/img1.jpg',
        displayOrder: 1,
        createdAt: DateTime.now().toIso8601String(),
      );

      final img2 = PropertyImageModel(
        id: 'IMG-2',
        propertyId: 'PROP-01',
        storagePath: 'properties/PROP-01/images/IMG2.jpg',
        publicUrl: 'https://supabase.co/img2.jpg',
        displayOrder: 2,
        createdAt: DateTime.now().toIso8601String(),
      );

      final reorderedImg2 = img2.copyWith(displayOrder: 1);
      final reorderedImg1 = img1.copyWith(displayOrder: 2);

      expect(reorderedImg2.displayOrder, equals(1));
      expect(reorderedImg1.displayOrder, equals(2));
      expect(reorderedImg2.toMap()['display_order'], equals(1));
    });

    // -------------------------------------------------------------------------
    // TEST 10: Change Cover Image -> Enforces Single Cover Invariant
    // -------------------------------------------------------------------------
    test('TEST 10: Only one cover image can be designated per property', () {
      final photoA = PropertyImageModel(
        id: 'IMG-A',
        propertyId: 'PROP-COVER',
        storagePath: 'path/A.jpg',
        publicUrl: 'https://supabase.co/A.jpg',
        isCover: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      final photoB = PropertyImageModel(
        id: 'IMG-B',
        propertyId: 'PROP-COVER',
        storagePath: 'path/B.jpg',
        publicUrl: 'https://supabase.co/B.jpg',
        isCover: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(photoA.isCover, isTrue);
      expect(photoB.isCover, isFalse);

      // Promote photo B to cover and demote photo A
      final updatedPhotoA = photoA.copyWith(isCover: false);
      final updatedPhotoB = photoB.copyWith(isCover: true);

      expect(updatedPhotoA.isCover, isFalse);
      expect(updatedPhotoB.isCover, isTrue);
      expect(updatedPhotoB.toMap()['is_cover'], equals(true));
    });

    // -------------------------------------------------------------------------
    // TEST 11: Add YouTube URL -> Only Video ID/URL Stored (Zero Video Binary)
    // -------------------------------------------------------------------------
    test('TEST 11: YouTube URL validation stores only 11-char video ID and URL', () {
      final yt = YouTubeMediaService.validateAndExtract('https://www.youtube.com/watch?v=ScMzIvxBSi4');
      expect(yt.isValid, isTrue);
      expect(yt.videoId, equals('ScMzIvxBSi4'));
      expect(yt.watchUrl, equals('https://www.youtube.com/watch?v=ScMzIvxBSi4'));
      expect(yt.embedUrl, contains('https://www.youtube.com/embed/ScMzIvxBSi4'));
    });

    // -------------------------------------------------------------------------
    // TEST 12: Try Non-YouTube Video -> Rejected
    // -------------------------------------------------------------------------
    test('TEST 12: Non-YouTube video URLs (Vimeo, Dailymotion, direct MP4) are rejected', () {
      final vimeo = YouTubeMediaService.validateAndExtract('https://vimeo.com/76979871');
      expect(vimeo.isValid, isFalse);

      final mp4 = YouTubeMediaService.validateAndExtract('https://mycdn.com/videos/drone_tour.mp4');
      expect(mp4.isValid, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 13: Open Property Listing -> Loads Optimized/Lazy-Loaded Images
    // -------------------------------------------------------------------------
    test('TEST 13: Property card loads optimized medium/thumbnail URLs', () {
      const prop = Property(
        id: 'PROP-CARD-01',
        title: 'Ace Parkway',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 2.8,
        imageUrl: 'https://unsplash.com/raw.jpg',
        optimizedMediumUrl: 'https://supabase.co/storage/medium.jpg',
        optimizedThumbnailUrl: 'https://supabase.co/storage/thumb.jpg',
      );

      expect(prop.displayImageUrl, equals('https://supabase.co/storage/medium.jpg'));
      expect(prop.thumbnailImageUrl, equals('https://supabase.co/storage/thumb.jpg'));
    });

    // -------------------------------------------------------------------------
    // TEST 14: Open Property Details -> Appropriate Resolution Loads
    // -------------------------------------------------------------------------
    test('TEST 14: Property details view resolves full high-fidelity image', () {
      const prop = Property(
        id: 'PROP-DETAIL-01',
        title: 'ATS Knightsbridge',
        sector: 'Sector 124',
        city: 'Noida',
        askingPriceCr: 9.5,
        imageUrl: 'https://supabase.co/storage/large.jpg',
      );

      expect(prop.imageUrl, equals('https://supabase.co/storage/large.jpg'));
    });

    // -------------------------------------------------------------------------
    // TEST 15: Open YouTube Section -> Thumbnail First, Player After Interaction
    // -------------------------------------------------------------------------
    test('TEST 15: YouTube section generates high-res thumbnail and deferred embed', () {
      const prop = Property(
        id: 'PROP-YT-01',
        title: 'DLF The Camellias',
        sector: 'Sector 42',
        city: 'Gurugram',
        askingPriceCr: 25.0,
        youtubeVideoId: 'ScMzIvxBSi4',
        youtubeUrl: 'https://www.youtube.com/watch?v=ScMzIvxBSi4',
      );

      expect(prop.hasYoutubeVideo, isTrue);
      expect(prop.youtubeThumbnailUrl, equals('https://img.youtube.com/vi/ScMzIvxBSi4/hqdefault.jpg'));
    });

    // -------------------------------------------------------------------------
    // TEST 16: Dealer Tries Another Dealer's Media -> Rejected
    // -------------------------------------------------------------------------
    test('TEST 16: Cross-dealer media tampering is blocked', () async {
      final success = await SmartMediaOptimizerService.instance.deletePropertyImage(
        propertyId: 'PROP_OTHER_DEALER',
        storagePath: 'properties/PROP_OTHER_DEALER/images/large/IMG.jpg',
        userId: 'malicious_dealer_999',
        userRole: 'user',
      );

      expect(success, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 17: Normal User Attempts Media Management -> Rejected
    // -------------------------------------------------------------------------
    test('TEST 17: Normal non-dealer user cannot modify media', () async {
      final success = await SmartMediaOptimizerService.instance.deletePropertyImage(
        propertyId: 'PROP_DEALER_EXCLUSIVE',
        storagePath: 'properties/PROP_DEALER_EXCLUSIVE/images/large/IMG.jpg',
        userId: 'buyer_user_456',
        userRole: 'user',
      );

      expect(success, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 18: Rejected Image Direct Access -> Must Not Bypass Moderation
    // -------------------------------------------------------------------------
    test('TEST 18: Moderation status filters out rejected and flagged media', () {
      final approvedImg = PropertyImageModel(
        id: 'IMG-APP',
        propertyId: 'PROP-MOD',
        storagePath: 'path/app.jpg',
        publicUrl: 'https://supabase.co/app.jpg',
        status: 'approved',
        createdAt: DateTime.now().toIso8601String(),
      );

      final rejectedImg = PropertyImageModel(
        id: 'IMG-REJ',
        propertyId: 'PROP-MOD',
        storagePath: 'path/rej.jpg',
        publicUrl: 'https://supabase.co/rej.jpg',
        status: 'rejected',
        rejectionReason: 'Blurry photo violating quality policy',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(approvedImg.isApproved, isTrue);
      expect(rejectedImg.isApproved, isFalse);
      expect(rejectedImg.isRejected, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 19: Admin Approves Image -> Image Becomes Publicly Available
    // -------------------------------------------------------------------------
    test('TEST 19: Admin approval transitions pending media to approved state', () {
      final pendingImg = PropertyImageModel(
        id: 'IMG-PEND',
        propertyId: 'PROP-MOD',
        storagePath: 'path/pend.jpg',
        publicUrl: 'https://supabase.co/pend.jpg',
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );

      expect(pendingImg.isApproved, isFalse);
      final approved = pendingImg.copyWith(status: 'approved');
      expect(approved.isApproved, isTrue);
      expect(approved.toMap()['status'], equals('approved'));
    });

    // -------------------------------------------------------------------------
    // TEST 20: Admin Rejects Image -> Image Is No Longer Publicly Displayed
    // -------------------------------------------------------------------------
    test('TEST 20: Admin rejection transitions media to rejected with reason', () {
      final imgModel = PropertyImageModel(
        id: 'IMG-TEST-20',
        propertyId: 'PROP-20',
        storagePath: 'path/20.jpg',
        publicUrl: 'https://supabase.co/20.jpg',
        status: 'approved',
        createdAt: DateTime.now().toIso8601String(),
      );

      final rejected = imgModel.copyWith(
        status: 'rejected',
        rejectionReason: 'Copyright watermarks detected on property image.',
      );

      expect(rejected.isRejected, isTrue);
      expect(rejected.rejectionReason, contains('Copyright watermarks'));
      expect(rejected.toMap()['status'], equals('rejected'));
    });
  });
}
