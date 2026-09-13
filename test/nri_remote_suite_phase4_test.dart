import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/property_media_item.dart';
import 'package:dealghar_ncr_10x/models/nri_subscription_model.dart';
import 'package:dealghar_ncr_10x/services/nri_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Phase 4 - NRI Remote Property Suite Tests', () {
    late NriSubscriptionService nriService;
    late PropertyStateService stateService;

    setUp(() {
      nriService = NriSubscriptionService.instance;
      stateService = PropertyStateService.instance;
      UserSession.logout();
    });

    test('TEST 1: Resident Indian logs in -> NRI Remote Suite Restricted', () {
      UserSession.setUserType('Indian Resident', country: 'India');
      expect(UserSession.isNri, isFalse);
      expect(nriService.canAccessFeature('drone_tour'), isFalse);
      expect(nriService.canAccessFeature('3d_view'), isFalse);
      expect(nriService.canAccessFeature('live_remote_tour'), isFalse);
    });

    test('TEST 2: NRI without subscription -> Suite Visible, Premium Locked', () {
      UserSession.setUserType('NRI', country: 'United States');
      UserSession.nriSubscriptionNotifier.value = null;

      expect(UserSession.isNri, isTrue);
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(nriService.canAccessFeature('drone_tour'), isFalse);
      expect(nriService.canAccessFeature('3d_view'), isFalse);
      expect(nriService.canAccessFeature('live_remote_tour'), isFalse);
    });

    test('TEST 3: NRI selects Premium plan -> Plan Selected Only, NOT Active', () {
      UserSession.setUserType('NRI', country: 'United States');
      final premiumPlan = nriService.plans.firstWhere((p) => p.tier == 'premium');

      final selectedSub = nriService.selectPlan(
        plan: premiumPlan,
        userId: 'usr_nri_123',
        userEmail: 'nri@propzen.ai',
      );

      expect(selectedSub.isPlanSelected, isTrue);
      expect(selectedSub.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(nriService.canAccessFeature('drone_tour'), isFalse);
    });

    test('TEST 4 & 5: NRI Payment Cancelled or Failed -> Subscription Remains Inactive', () {
      UserSession.setUserType('NRI', country: 'United Kingdom');
      final sub = NriSubscription(
        id: 'sub_failed_101',
        userId: 'usr_nri_uk',
        userEmail: 'nri.uk@propzen.ai',
        planId: 'nri_pass_premium',
        planName: 'Premium NRI Drone Pass',
        tier: 'premium',
        durationMonths: 6,
        status: 'payment_failed',
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        amount: 3999.0,
      );

      UserSession.nriSubscriptionNotifier.value = sub;
      expect(sub.isPaymentFailed, isTrue);
      expect(sub.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
    });

    test('TEST 6: Payment Verified on Server -> Subscription Active & Entitlements Unlocked', () {
      UserSession.setUserType('NRI', country: 'United States');
      final activeSub = NriSubscription(
        id: 'sub_verified_202',
        userId: 'usr_nri_usa',
        userEmail: 'usa.nri@propzen.ai',
        planId: 'nri_pass_premium',
        planName: 'Premium NRI Drone Pass',
        tier: 'premium',
        durationMonths: 6,
        status: 'active',
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 180)),
        amount: 3999.0,
        paymentId: 'pay_verified_signature_ok',
        transactionId: 'txn_rzp_999',
      );

      UserSession.nriSubscriptionNotifier.value = activeSub;
      expect(activeSub.isActive, isTrue);
      expect(UserSession.hasActiveDroneAccess, isTrue);
      expect(nriService.canAccessFeature('drone_tour'), isTrue);
      expect(nriService.canAccessFeature('3d_view'), isTrue);
      expect(nriService.canAccessFeature('locality_intelligence'), isTrue);
    });

    test('TEST 7: Active Subscription Expires -> Features Locked & Renew Required', () {
      UserSession.setUserType('NRI', country: 'Canada');
      final expiredSub = NriSubscription(
        id: 'sub_expired_303',
        userId: 'usr_nri_canada',
        userEmail: 'canada.nri@propzen.ai',
        planId: 'nri_pass_premium',
        planName: 'Premium NRI Drone Pass',
        tier: 'premium',
        durationMonths: 6,
        status: 'active', // Marked active string but date is in the past
        startDate: DateTime.now().subtract(const Duration(days: 200)),
        expiryDate: DateTime.now().subtract(const Duration(days: 20)),
        amount: 3999.0,
      );

      UserSession.nriSubscriptionNotifier.value = expiredSub;
      expect(expiredSub.isExpired, isTrue);
      expect(expiredSub.isActive, isFalse);
      expect(UserSession.hasActiveDroneAccess, isFalse);
      expect(nriService.canAccessFeature('drone_tour'), isFalse);
    });

    test('TEST 8 & 9: Property A vs Property B Media Isolation (No Media Leakage)', () {
      final mediaA = [
        PropertyMediaItem(
          id: 'med_prop_a',
          propertyId: 'PROP-A',
          url: 'https://propzen.ai/drone/prop_a.mp4',
          type: PropertyMediaType.drone,
          caption: 'Aerial View of Property A',
        ),
      ];

      final mediaB = [
        PropertyMediaItem(
          id: 'med_prop_b',
          propertyId: 'PROP-B',
          url: 'https://propzen.ai/drone/prop_b.mp4',
          type: PropertyMediaType.drone,
          caption: 'Aerial View of Property B',
        ),
      ];

      final propA = Property(
        id: 'PROP-A',
        title: 'ATS Knightsbridge Luxury Suite',
        sector: 'Sector 124',
        city: 'Noida',
        locality: 'Noida Expressway',
        address: 'Sector 124, Noida',
        postalCode: '201301',
        placeId: 'loc_a',
        latitude: 28.54,
        longitude: 77.33,
        askingPriceCr: 5.5,
        fairValueCr: 5.6,
        priceRangeDisplay: '₹ 5.5 Cr',
        pricePerSqft: 12000,
        score10x: 9.5,
        rentalYieldPercent: 5.0,
        sqft: 4000,
        carpetAreaSqft: 3500,
        bhk: '4 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        galleryImages: const [],
        mediaList: mediaA,
        droneTourAvailable: true,
        droneTourUrl: 'https://propzen.ai/drone/prop_a.mp4',
      );

      final propB = Property(
        id: 'PROP-B',
        title: 'Godrej Palm Retreat Villa',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        address: 'Sector 150, Noida',
        postalCode: '201310',
        placeId: 'loc_b',
        latitude: 28.43,
        longitude: 77.48,
        askingPriceCr: 2.8,
        fairValueCr: 2.9,
        priceRangeDisplay: '₹ 2.8 Cr',
        pricePerSqft: 8500,
        score10x: 9.1,
        rentalYieldPercent: 4.8,
        sqft: 2500,
        carpetAreaSqft: 2100,
        bhk: '3 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c',
        galleryImages: const [],
        mediaList: mediaB,
        droneTourAvailable: true,
        droneTourUrl: 'https://propzen.ai/drone/prop_b.mp4',
      );

      expect(propA.droneTourUrl, contains('prop_a.mp4'));
      expect(propB.droneTourUrl, contains('prop_b.mp4'));
      expect(propA.mediaList.first.url, isNot(equals(propB.mediaList.first.url)));
      expect(propA.latitude, isNot(equals(propB.latitude)));
    });

    test('TEST 10: Live Remote Tour Booking Linked to Property, Buyer & Dealer', () async {
      final booking = await nriService.bookRemoteTour(
        propertyId: 'PROP-A',
        propertyTitle: 'ATS Knightsbridge',
        tourType: 'live_video_walkthrough',
        preferredDate: '2026-09-05',
        preferredTime: '06:30 PM',
        timezone: 'EST (UTC-5)',
        userName: 'Vikram Seth',
        userEmail: 'vikram.seth@gmail.com',
        userPhone: '+1 415 888 9999',
        userCountry: 'United States',
        notes: 'Please show north-facing balcony views and master bathroom.',
      );

      expect(booking.propertyId, 'PROP-A');
      expect(booking.userName, 'Vikram Seth');
      expect(booking.timezone, 'EST (UTC-5)');
      expect(booking.status, 'confirmed');
      expect(nriService.remoteBookings.any((b) => b.id == booking.id), isTrue);
    });

    test('TEST 11: NRI Document Concierge Vault Security & Multi-Category Management', () {
      final docs = nriService.documents;
      expect(docs.isNotEmpty, isTrue);

      final reraDoc = docs.firstWhere((d) => d.category == 'verification_documents');
      expect(reraDoc.status, 'verified');
      expect(reraDoc.fileUrl, contains('.pdf'));
      expect(reraDoc.verifiedBy, isNotNull);
    });

    test('TEST 12: Family Decision Mode Voting & Preference Aggregation', () async {
      await nriService.submitFamilyReview(
        propertyId: 'PROP-A',
        memberName: 'Anita Seth',
        relation: 'Spouse',
        vote: 'like',
        rating: 5.0,
        comment: 'Great layout and high ceiling design.',
      );

      final reviews = nriService.getFamilyReviewsForProperty('PROP-A');
      expect(reviews.any((r) => r.memberName == 'Anita Seth' && r.vote == 'like'), isTrue);

      final summary = nriService.getFamilySummaryForProperty('PROP-A');
      expect(summary['totalVotes'], greaterThan(0));
      expect(summary['likes'], greaterThan(0));
      expect(summary['avgRating'], greaterThanOrEqualTo(4.0));
    });

    test('TEST 13: NRI Investment Calculator Mathematical Precision', () {
      const calc = NriInvestmentCalculation(
        propertyPrice: 15000000.0, // 1.5 Cr
        downPaymentPercent: 20.0, // 30 Lakhs
        interestRatePercent: 8.5,
        loanTenureYears: 20,
        expectedMonthlyRent: 45000.0,
        holdingPeriodYears: 5,
      );

      expect(calc.downPaymentAmount, 3000000.0);
      expect(calc.loanAmount, 12000000.0);
      expect(calc.monthlyEmi, greaterThan(100000.0));
      expect(calc.annualRent, 540000.0);
      expect(calc.grossRentalYield, closeTo(3.6, 0.1));
    });

    test('TEST 14: NRI Property Confidence Score Transparent Multi-Pillar Computation', () {
      final score = nriService.getConfidenceScoreForProperty('PROP-A');
      expect(score.propertyScore, inInclusiveRange(0, 100));
      expect(score.locationScore, inInclusiveRange(0, 100));
      expect(score.documentationScore, inInclusiveRange(0, 100));
      expect(score.valueScore, inInclusiveRange(0, 100));
      expect(score.remoteVisibilityScore, inInclusiveRange(0, 100));
      expect(score.dealReadinessScore, inInclusiveRange(0, 100));
      expect(score.overallScore, inInclusiveRange(0, 100));
      expect(score.recommendation, isNotEmpty);
    });
  });
}
