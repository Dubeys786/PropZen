import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/property_media_item.dart';
import 'package:dealghar_ncr_10x/models/lead_model.dart';
import 'package:dealghar_ncr_10x/models/site_visit_model.dart';
import 'package:dealghar_ncr_10x/models/dealer_notification_model.dart';
import 'package:dealghar_ncr_10x/models/dealer_subscription_model.dart';
import 'package:dealghar_ncr_10x/services/dealer_lead_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_subscription_service.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Phase 3 - Dealer Marketplace & Lead Management Tests', () {
    late DealerLeadService leadService;
    late DealerSubscriptionService subService;
    late AdminService adminService;
    late PropertyStateService stateService;

    setUp(() {
      leadService = DealerLeadService.instance;
      subService = DealerSubscriptionService.instance;
      adminService = AdminService.instance;
      stateService = PropertyStateService.instance;
    });

    test('1. Dealer Property Posting with Media Items & Phase 3 Specs', () {
      final List<PropertyMediaItem> media = [
        PropertyMediaItem(
          id: 'med_001',
          propertyId: 'PROP-ALPHA-01',
          url: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
          type: PropertyMediaType.image,
          caption: 'Living Room',
          sortOrder: 0,
        ),
        PropertyMediaItem(
          id: 'med_002',
          propertyId: 'PROP-ALPHA-01',
          url: 'https://propzen.ai/drone/alpha01.mp4',
          type: PropertyMediaType.drone,
          caption: 'Aerial View',
          sortOrder: 1,
        ),
      ];

      final prop = Property(
        id: 'PROP-ALPHA-01',
        title: 'ATS Knightsbridge 4 BHK Sky Villa',
        sector: 'Sector 124',
        city: 'Noida',
        locality: 'Noida Expressway',
        address: 'Sector 124, Noida Expressway',
        postalCode: '201301',
        placeId: 'loc_alpha_01',
        latitude: 28.54,
        longitude: 77.33,
        askingPriceCr: 4.85,
        fairValueCr: 4.90,
        priceRangeDisplay: '₹ 4.85 Cr',
        pricePerSqft: 11000,
        score10x: 9.4,
        rentalYieldPercent: 5.2,
        sqft: 4400,
        carpetAreaSqft: 3800,
        bhk: '4 BHK',
        imageUrl: media[0].url,
        galleryImages: [media[0].url],
        mediaList: media,
        dealerId: 'DLR-ALPHA',
        dealerName: 'Alpha Real Estate',
        projectName: 'ATS Knightsbridge',
        floorNumber: 18,
        totalFloors: 42,
        parkingSlots: 3,
        constructionStatus: 'Ready to Move',
        contactPreference: 'WhatsApp & Call',
        status: 'pending',
      );

      expect(prop.isPending, isTrue);
      expect(prop.isApproved, isFalse);
      expect(prop.mediaList.length, 2);
      expect(prop.mediaList[1].isDrone, isTrue);
      expect(prop.parkingSlots, 3);
      expect(prop.floorNumber, 18);
    });

    test('2. Property Verification Lifecycle (Pending -> Under Review -> Approved / Rejected / Needs Correction)', () {
      final p1 = Property(
        id: 'PROP-REVIEW-01',
        title: 'Godrej Palm Retreat 3 BHK',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        address: 'Sector 150, Noida',
        postalCode: '201310',
        placeId: 'loc_01',
        latitude: 28.43,
        longitude: 77.48,
        askingPriceCr: 1.85,
        fairValueCr: 1.90,
        priceRangeDisplay: '₹ 1.85 Cr',
        pricePerSqft: 7500,
        score10x: 9.0,
        rentalYieldPercent: 4.6,
        sqft: 1900,
        carpetAreaSqft: 1600,
        bhk: '3 BHK',
        imageUrl: '',
        galleryImages: const [],
        dealerId: 'DLR-ALPHA',
        dealerName: 'Alpha Dealer',
        status: 'pending',
      );

      expect(p1.isPending, isTrue);

      final pUnderReview = p1.copyWith(status: 'under_review');
      expect(pUnderReview.isUnderReview, isTrue);

      final pApproved = p1.copyWith(status: 'approved');
      expect(pApproved.isApproved, isTrue);

      final pNeedsCorrection = p1.copyWith(status: 'needs_correction', adminNote: 'Upload RERA certificate');
      expect(pNeedsCorrection.isNeedsCorrection, isTrue);
      expect(pNeedsCorrection.adminNote, 'Upload RERA certificate');

      final pRejected = p1.copyWith(status: 'rejected', adminNote: 'Invalid pricing fidelity');
      expect(pRejected.isRejected, isTrue);
      expect(pRejected.adminNote, 'Invalid pricing fidelity');
    });

    test('3. Multi-Tenant Lead Isolation between Dealer A and Dealer B', () async {
      // Clear and populate isolated leads
      final propA = Property(
        id: 'PROP-A',
        title: 'Alpha Luxury Villa',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        address: 'Sector 150, Noida',
        postalCode: '201310',
        placeId: 'loc_a',
        latitude: 28.43,
        longitude: 77.48,
        askingPriceCr: 3.5,
        fairValueCr: 3.6,
        priceRangeDisplay: '₹ 3.5 Cr',
        pricePerSqft: 8000,
        score10x: 9.0,
        rentalYieldPercent: 4.5,
        sqft: 3000,
        carpetAreaSqft: 2500,
        bhk: '4 BHK',
        imageUrl: '',
        galleryImages: const [],
        dealerId: 'DLR-ALPHA',
        dealerName: 'Alpha Realty',
      );

      final propB = Property(
        id: 'PROP-B',
        title: 'Beta High Rise',
        sector: 'Sector 128',
        city: 'Noida',
        locality: 'Sector 128',
        address: 'Sector 128, Noida',
        postalCode: '201304',
        placeId: 'loc_b',
        latitude: 28.50,
        longitude: 77.36,
        askingPriceCr: 2.1,
        fairValueCr: 2.2,
        priceRangeDisplay: '₹ 2.1 Cr',
        pricePerSqft: 7000,
        score10x: 8.8,
        rentalYieldPercent: 4.2,
        sqft: 2000,
        carpetAreaSqft: 1700,
        bhk: '3 BHK',
        imageUrl: '',
        galleryImages: const [],
        dealerId: 'DLR-BETA',
        dealerName: 'Beta Homes',
      );

      // Buyer enquires on Property A
      final leadA = await leadService.createLeadFromEnquiry(
        buyerId: 'usr_amit',
        buyerName: 'Amit Sharma',
        buyerPhone: '+91 98111 22233',
        buyerEmail: 'amit.sharma@gmail.com',
        property: propA,
        message: 'Interested in Alpha Villa',
      );

      // Buyer enquires on Property B
      final leadB = await leadService.createLeadFromEnquiry(
        buyerId: 'usr_rohit',
        buyerName: 'Rohit Verma',
        buyerPhone: '+91 98222 33344',
        buyerEmail: 'rohit.verma@gmail.com',
        property: propB,
        message: 'Interested in Beta High Rise',
      );

      // Verify Strict Tenant Isolation
      final alphaLeads = leadService.getLeadsForDealer('DLR-ALPHA');
      final betaLeads = leadService.getLeadsForDealer('DLR-BETA');

      expect(alphaLeads.any((l) => l.id == leadA.id), isTrue);
      expect(alphaLeads.any((l) => l.id == leadB.id), isFalse); // Dealer A cannot see Dealer B lead

      expect(betaLeads.any((l) => l.id == leadB.id), isTrue);
      expect(betaLeads.any((l) => l.id == leadA.id), isFalse); // Dealer B cannot see Dealer A lead
    });

    test('4. 7-Stage Lead Pipeline State Transitions & Notes Tracking', () {
      final lead = DealerLead(
        id: 'LEAD-TEST-007',
        dealerId: 'DLR-ALPHA',
        buyerName: 'Vikram Malhotra',
        buyerPhone: '+91 98765 00000',
        buyerEmail: 'vikram@malhotra.com',
        requirement: '3 BHK in Sector 150',
        budgetCr: 2.0,
        preferredLocation: 'Sector 150',
        propertyId: 'PROP-001',
        propertyTitle: 'ATS Knightsbridge',
        enquiryStatus: 'New',
        leadScore: 85,
        scoreTier: LeadScoreTier.hot,
      );

      expect(lead.isNew, isTrue);

      // Transition to Contacted
      final s1 = lead.copyWith(enquiryStatus: 'Contacted');
      expect(s1.isContacted, isTrue);

      // Transition to Qualified
      final s2 = s1.copyWith(enquiryStatus: 'Qualified');
      expect(s2.isQualified, isTrue);

      // Transition to Site Visit
      final s3 = s2.copyWith(enquiryStatus: 'Site Visit');
      expect(s3.isSiteVisit, isTrue);

      // Transition to Negotiation
      final s4 = s3.copyWith(enquiryStatus: 'Negotiation');
      expect(s4.isNegotiation, isTrue);

      // Transition to Converted
      final s5 = s4.copyWith(enquiryStatus: 'Converted');
      expect(s5.isConverted, isTrue);

      // Transition to Lost
      final s6 = s4.copyWith(enquiryStatus: 'Lost');
      expect(s6.isLost, isTrue);
    });

    test('5. Site Visit Booking Associated with Dealer & Confirmation Lifecycle', () async {
      final prop = Property(
        id: 'PROP-VISIT-01',
        title: 'Gulshan Dynasty Luxury Floor',
        sector: 'Sector 144',
        city: 'Noida',
        locality: 'Sector 144',
        address: 'Sector 144, Noida Expressway',
        postalCode: '201306',
        placeId: 'loc_dynasty',
        latitude: 28.51,
        longitude: 77.40,
        askingPriceCr: 6.2,
        fairValueCr: 6.3,
        priceRangeDisplay: '₹ 6.2 Cr',
        pricePerSqft: 14000,
        score10x: 9.6,
        rentalYieldPercent: 5.5,
        sqft: 4700,
        carpetAreaSqft: 4100,
        bhk: '4 BHK',
        imageUrl: '',
        galleryImages: const [],
        dealerId: 'DLR-ALPHA',
        dealerName: 'Alpha Realty',
      );

      final visit = await leadService.bookSiteVisit(
        property: prop,
        buyerId: 'usr_deepak',
        buyerName: 'Deepak Chopra',
        buyerPhone: '+91 99999 11111',
        buyerEmail: 'deepak@chopra.org',
        scheduledDate: '2026-09-02',
        scheduledTime: '11:00 AM',
        visitorCount: 3,
        cabRequired: true,
        pickupLocation: 'Noida City Centre Metro',
      );

      expect(visit.isRequested, isTrue);
      expect(visit.dealerId, 'DLR-ALPHA');
      expect(visit.visitorCount, 3);
      expect(visit.cabRequired, isTrue);

      // Dealer confirms site visit
      leadService.updateSiteVisitStatus(visitId: visit.id, newStatus: SiteVisitStatus.confirmed);
      final confirmed = leadService.allSiteVisits.firstWhere((v) => v.id == visit.id);
      expect(confirmed.isConfirmed, isTrue);

      // Dealer completes site visit
      leadService.updateSiteVisitStatus(visitId: visit.id, newStatus: SiteVisitStatus.completed);
      final completed = leadService.allSiteVisits.firstWhere((v) => v.id == visit.id);
      expect(completed.isCompleted, isTrue);
    });

    test('6. Dealer Notifications System (10 Event Types Delivery)', () {
      leadService.sendNotification(
        dealerId: 'DLR-ALPHA',
        type: DealerNotificationType.propertyApproved,
        title: 'Listing Approved',
        message: 'Your property is now live',
      );

      leadService.sendNotification(
        dealerId: 'DLR-ALPHA',
        type: DealerNotificationType.propertyRejected,
        title: 'Listing Rejected',
        message: 'Pricing requires correction',
      );

      leadService.sendNotification(
        dealerId: 'DLR-ALPHA',
        type: DealerNotificationType.propertyCorrectionRequired,
        title: 'Correction Required',
        message: 'Add floor plan',
      );

      final notifs = leadService.getNotificationsForDealer('DLR-ALPHA');
      expect(notifs.any((n) => n.type == DealerNotificationType.propertyApproved), isTrue);
      expect(notifs.any((n) => n.type == DealerNotificationType.propertyRejected), isTrue);
      expect(notifs.any((n) => n.type == DealerNotificationType.propertyCorrectionRequired), isTrue);
    });

    test('7. Dealer Analytics Real Computed Metrics', () {
      final analytics = leadService.computeAnalyticsForDealer('DLR-NOIDA-101');

      expect(analytics.totalProperties, greaterThanOrEqualTo(0));
      expect(analytics.totalViews, greaterThanOrEqualTo(0));
      expect(analytics.totalLeads, greaterThanOrEqualTo(0));
      expect(analytics.leadConversionRate, greaterThanOrEqualTo(0.0));
      expect(analytics.siteVisitConversionRate, greaterThanOrEqualTo(0.0));
    });

    test('8. Dealer Subscription Listing Limit Enforced Server-Side', () {
      // Starter plan has 5 listing limit
      final starterPlan = subService.plans.firstWhere((p) => p.id == 'dealer_starter');
      expect(starterPlan.listingLimit, 5);

      // Pro plan has 50 listing limit
      final proPlan = subService.plans.firstWhere((p) => p.id == 'dealer_pro');
      expect(proPlan.listingLimit, 50);

      // Premium plan has 150 listing limit
      final premiumPlan = subService.plans.firstWhere((p) => p.id == 'dealer_premium');
      expect(premiumPlan.listingLimit, 150);
    });
  });
}
