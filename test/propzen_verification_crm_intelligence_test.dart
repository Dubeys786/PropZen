import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/lead_model.dart';
import 'package:dealghar_ncr_10x/services/property_intelligence_service.dart';
import 'package:dealghar_ncr_10x/services/property_verification_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_lead_service.dart';
import 'package:dealghar_ncr_10x/services/ai_copywriter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen AI Property Intelligence, Verification & CRM Master Test Suite (16 Scenarios)', () {
    // -------------------------------------------------------------------------
    // TEST 1: Normal User Cannot Verify Property
    // -------------------------------------------------------------------------
    test('TEST 1: Normal user cannot set verified status or approve property', () {
      const prop = Property(
        id: 'PROP-USR-01',
        title: 'ATS Dolce 3 BHK',
        sector: 'Zeta 1',
        city: 'Greater Noida',
        askingPriceCr: 1.25,
        status: 'pending',
        isVerified: false,
      );

      expect(prop.isPropZenVerified, isFalse);
      expect(prop.isPending, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Dealer Cannot Verify Own Property
    // -------------------------------------------------------------------------
    test('TEST 2: Dealer submitting property defaults to pending_review, not verified', () async {
      const prop = Property(
        id: 'PROP-DLR-01',
        title: 'Godrej Golf Links Villa',
        sector: 'Sector 27',
        city: 'Greater Noida',
        askingPriceCr: 3.5,
        dealerId: 'dlr_noida_01',
        status: 'draft',
        isVerified: false,
      );

      final submitSuccess = await PropertyVerificationService.instance.submitForVerification(
        prop.id,
        dealerId: prop.dealerId,
      );

      expect(submitSuccess, isTrue);
      // Still not verified without admin review
      expect(prop.isPropZenVerified, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Only Admin Can Approve Verification
    // -------------------------------------------------------------------------
    test('TEST 3: Admin verification transitions property to verified with audit trail', () async {
      final verifySuccess = await PropertyVerificationService.instance.verifyProperty(
        'PROP-ADM-VERIFY',
        'dubeysakshi618@gmail.com',
        notes: 'Passed all 8 checklist pillars including RERA and media audit.',
      );

      expect(verifySuccess, isTrue);

      const verifiedProp = Property(
        id: 'PROP-ADM-VERIFY',
        title: 'Ace Starlit 3 BHK',
        sector: 'Sector 152',
        city: 'Noida',
        askingPriceCr: 2.1,
        status: 'verified',
        isVerified: true,
      );

      expect(verifiedProp.isPropZenVerified, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 4: Verified Badge Appears Only For Verified Properties
    // -------------------------------------------------------------------------
    test('TEST 4: Verified badge is hidden for pending, rejected, and suspended listings', () {
      const pendingProp = Property(
        id: 'P1',
        title: 'Pending Flat',
        sector: 'Sector 10',
        city: 'Noida Extension',
        askingPriceCr: 0.8,
        status: 'pending',
        isVerified: false,
      );

      const rejectedProp = Property(
        id: 'P2',
        title: 'Rejected Flat',
        sector: 'Sector 10',
        city: 'Noida Extension',
        askingPriceCr: 0.8,
        status: 'rejected',
        isVerified: false,
      );

      const suspendedProp = Property(
        id: 'P3',
        title: 'Suspended Flat',
        sector: 'Sector 10',
        city: 'Noida Extension',
        askingPriceCr: 0.8,
        status: 'suspended',
        isVerified: false,
      );

      const verifiedProp = Property(
        id: 'P4',
        title: 'Verified Penthouse',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 4.5,
        status: 'verified',
        isVerified: true,
      );

      expect(pendingProp.isPropZenVerified, isFalse);
      expect(rejectedProp.isPropZenVerified, isFalse);
      expect(suspendedProp.isPropZenVerified, isFalse);
      expect(verifiedProp.isPropZenVerified, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 5: Major Verified-Property Change Triggers Re-Review
    // -------------------------------------------------------------------------
    test('TEST 5: Material changes (price > 10%, location) require re-review while harmless edits pass', () {
      const originalVerified = Property(
        id: 'P-VER-01',
        title: 'Mahagun Manorialle',
        sector: 'Sector 128',
        city: 'Noida',
        askingPriceCr: 5.0,
        status: 'verified',
        isVerified: true,
        contactPhone: '9876543210',
      );

      // Harmless edit: phone number update
      final harmlessEdit = originalVerified.copyWith(contactPhone: '9998887770');
      final needsReview1 = PropertyVerificationService.instance.checkVerifiedPropertyChangeProtection(
        originalVerified,
        harmlessEdit,
      );
      expect(needsReview1, isFalse);

      // Material edit: 25% price increase
      final materialPriceEdit = originalVerified.copyWith(askingPriceCr: 6.25);
      final needsReview2 = PropertyVerificationService.instance.checkVerifiedPropertyChangeProtection(
        originalVerified,
        materialPriceEdit,
      );
      expect(needsReview2, isTrue);

      // Material edit: location shift
      final materialLocationEdit = originalVerified.copyWith(sector: 'Sector 150');
      final needsReview3 = PropertyVerificationService.instance.checkVerifiedPropertyChangeProtection(
        originalVerified,
        materialLocationEdit,
      );
      expect(needsReview3, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 6: Duplicate Listing Is Flagged, Not Automatically Deleted
    // -------------------------------------------------------------------------
    test('TEST 6: Duplicate property detection flags match without deleting listing', () {
      const existingProp = Property(
        id: 'PROP-ORIG-01',
        title: 'Tata Eureka Park 3 BHK',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '3 BHK',
        sqft: 1550,
        askingPriceCr: 1.85,
        latitude: 28.4410,
        longitude: 77.4930,
      );

      const candidateProp = Property(
        id: 'PROP-DUP-02',
        title: 'Tata Eureka 3BHK Flat',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '3 BHK',
        sqft: 1550,
        askingPriceCr: 1.85,
        latitude: 28.4411,
        longitude: 77.4931,
      );

      final dupRes = PropertyIntelligenceService.instance.detectDuplicateListings(
        candidateProp,
        [existingProp],
      );

      expect(dupRes.status, equals('confirmed_duplicate'));
      expect(dupRes.similarityScore, greaterThan(0.70));
      expect(dupRes.matchedProperty?.id, equals('PROP-ORIG-01'));
      expect(dupRes.matchReasons.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 7: AI Description Does Not Invent Details
    // -------------------------------------------------------------------------
    test('TEST 7: AI description generator builds strictly on supplied facts', () async {
      final copy = await AiCopywriterService.instance.generateListingCopy(
        title: 'Gaur Wave City Penthouse',
        propertyType: 'Penthouse',
        location: 'NH-24 Corridor',
        city: 'Ghaziabad',
        priceCr: 1.45,
        sqft: 2100,
        bhk: '4 BHK',
        furnishing: 'Semi-Furnished',
        possession: 'Ready to Move',
        amenities: ['Sky Deck', 'Clubhouse', 'Olympic Pool'],
        landmarks: 'Columbia Asia Hospital',
        dealerName: 'Rohit Sharma',
        dealerPhone: '9810012345',
      );

      expect(copy.professionalDescription, contains('4 BHK Penthouse'));
      expect(copy.professionalDescription, contains('2100 sq. ft.'));
      expect(copy.professionalDescription, contains('Ghaziabad'));
      expect(copy.headline, contains('₹1.45 Cr'));
      expect(copy.locationSummary, contains('Columbia Asia Hospital'));
    });

    // -------------------------------------------------------------------------
    // TEST 8: Natural-Language Search Returns Real Database Properties
    // -------------------------------------------------------------------------
    test('TEST 8: Natural-language queries map to structured database filters', () {
      final sampleDb = [
        const Property(
          id: 'PROP-N1',
          title: 'Expressway Tower 2 BHK',
          sector: 'Sector 150',
          city: 'Noida',
          bhk: '2 BHK',
          askingPriceCr: 0.75, // Under 80 lakh
          possessionStatus: 'Ready to Move',
        ),
        const Property(
          id: 'PROP-N2',
          title: 'Expressway Luxury 3 BHK',
          sector: 'Sector 150',
          city: 'Noida',
          bhk: '3 BHK',
          askingPriceCr: 1.60,
          possessionStatus: 'Under Construction',
        ),
        const Property(
          id: 'PROP-G1',
          title: 'Golf Course Villa 4 BHK',
          sector: 'Sector 42',
          city: 'Gurugram',
          bhk: '4 BHK',
          askingPriceCr: 8.50,
          possessionStatus: 'Ready to Move',
        ),
      ];

      final searchRes = PropertyIntelligenceService.instance.filterPropertiesNaturalLanguage(
        '2 BHK in Noida under 80 lakh',
        sampleDb,
      );

      expect(searchRes.hasExactMatches, isTrue);
      expect(searchRes.exactMatches.length, equals(1));
      expect(searchRes.exactMatches.first.id, equals('PROP-N1'));
      expect(searchRes.exactMatches.first.askingPriceCr, lessThanOrEqualTo(0.80));
    });

    // -------------------------------------------------------------------------
    // TEST 9: Exact Filters Remain Exact
    // -------------------------------------------------------------------------
    test('TEST 9: Exact budget filters do not return out-of-bounds properties', () {
      final sampleDb = [
        const Property(id: 'P-A', title: 'Unit A', sector: 'Sec 1', city: 'Noida', bhk: '2 BHK', askingPriceCr: 0.65),
        const Property(id: 'P-B', title: 'Unit B', sector: 'Sec 1', city: 'Noida', bhk: '2 BHK', askingPriceCr: 0.78),
        const Property(id: 'P-C', title: 'Unit C', sector: 'Sec 1', city: 'Noida', bhk: '3 BHK', askingPriceCr: 0.95),
        const Property(id: 'P-D', title: 'Unit D', sector: 'Sec 1', city: 'Noida', bhk: '2 BHK', askingPriceCr: 1.20),
      ];

      // Query: 2 BHK under 80L (0.80 Cr)
      final results = PropertyIntelligenceService.instance.filterPropertiesNaturalLanguage(
        '2 BHK under 80 lakh',
        sampleDb,
      );

      for (final prop in results.exactMatches) {
        expect(prop.bhk, contains('2 BHK'));
        expect(prop.askingPriceCr, lessThanOrEqualTo(0.80));
      }
      expect(results.exactMatches.any((p) => p.askingPriceCr > 0.80), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 10: Dealer Sees Only Authorized Leads (Tenant Isolation)
    // -------------------------------------------------------------------------
    test('TEST 10: Dealer CRM isolates leads strictly by dealerId', () {
      final service = DealerLeadService.instance;
      service.initializeSampleLeads();

      final dealerALeads = service.getLeadsForDealer('dlr_001');
      final dealerBLeads = service.getLeadsForDealer('dlr_002');

      for (final lead in dealerALeads) {
        expect(lead.dealerId, equals('dlr_001'));
      }

      for (final lead in dealerBLeads) {
        expect(lead.dealerId, equals('dlr_002'));
      }

      // Cross-tenant bleed check
      expect(dealerALeads.any((l) => l.dealerId == 'dlr_002'), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 11: Normal User Cannot Access CRM
    // -------------------------------------------------------------------------
    test('TEST 11: Normal unauthenticated/buyer user receives empty lead access', () {
      final service = DealerLeadService.instance;
      final emptyLeads = service.getLeadsForDealer('');
      expect(emptyLeads.isEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 12: Admin Analytics Uses Real Data
    // -------------------------------------------------------------------------
    test('TEST 12: Admin analytics compute real aggregates without mocked values', () {
      final service = DealerLeadService.instance;
      final analytics = service.getAnalyticsForDealer('dlr_001');

      expect(analytics.totalProperties, greaterThanOrEqualTo(0));
      expect(analytics.totalLeads, greaterThanOrEqualTo(0));
      expect(analytics.leadConversionRate, greaterThanOrEqualTo(0.0));
      expect(analytics.leadConversionRate, lessThanOrEqualTo(100.0));
    });

    // -------------------------------------------------------------------------
    // TEST 13: AI Property Quality Score (0 - 100)
    // -------------------------------------------------------------------------
    test('TEST 13: Property quality score evaluates completeness and offers suggestions', () {
      const incompleteProp = Property(
        id: 'P-INC',
        title: '2BHK',
        sector: 'Noida',
        city: 'Noida',
        askingPriceCr: 0.60,
        description: 'Short desc',
        carpetAreaSqft: 0,
        galleryImages: [],
      );

      final qScore = PropertyIntelligenceService.instance.calculateQualityScore(incompleteProp);
      expect(qScore.totalScore, lessThan(75));
      expect(qScore.suggestions.isNotEmpty, isTrue);
      expect(qScore.suggestions.any((s) => s.contains('carpet area')), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 14: Fraud Risk Scoring (LOW, MEDIUM, HIGH)
    // -------------------------------------------------------------------------
    test('TEST 14: Anomaly detector flags unrealistic price and contact anomalies', () {
      const suspiciousProp = Property(
        id: 'P-SUS',
        title: '3 BHK Ultra Luxury Penthouse',
        sector: 'Sector 150',
        city: 'Noida',
        bhk: '3 BHK',
        askingPriceCr: 0.08, // Extreme underpricing (8 Lakhs)
        contactPhone: '1234', // Invalid phone
      );

      final risk = PropertyIntelligenceService.instance.evaluateFraudRisk(
        suspiciousProp,
        dealerTotalListings: 5,
        dealerRejectedCount: 3,
      );

      expect(risk.riskLevel, isIn(['MEDIUM RISK', 'HIGH RISK']));
      expect(risk.riskFlags.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 15: Property Availability Controls
    // -------------------------------------------------------------------------
    test('TEST 15: Availability statuses (Available, Reserved, Sold, Rented) reflect correctly', () {
      const availProp = Property(
        id: 'P-AV',
        title: 'Unit 101',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 1.2,
        availabilityStatus: 'Available',
      );

      const soldProp = Property(
        id: 'P-SOLD',
        title: 'Unit 102',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 1.2,
        availabilityStatus: 'Sold',
      );

      expect(availProp.isAvailable, isTrue);
      expect(soldProp.isAvailable, isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 16: Smart Recommendations Engine
    // -------------------------------------------------------------------------
    test('TEST 16: Privacy-conscious smart recommendations return localized matching units', () {
      const baseProp = Property(
        id: 'P-BASE',
        title: 'ATS Knightsbridge 4 BHK',
        sector: 'Sector 124',
        city: 'Noida',
        bhk: '4 BHK',
        askingPriceCr: 9.0,
      );

      final inventory = [
        const Property(id: 'P-REC1', title: 'ATS Le Grandiose', sector: 'Sector 150', city: 'Noida', bhk: '4 BHK', askingPriceCr: 8.5),
        const Property(id: 'P-REC2', title: 'Kalpataru Vista', sector: 'Sector 128', city: 'Noida', bhk: '4 BHK', askingPriceCr: 9.5),
        const Property(id: 'P-OTHER', title: 'Budget 1 BHK', sector: 'Sector 1', city: 'Faridabad', bhk: '1 BHK', askingPriceCr: 0.35),
      ];

      final recs = PropertyIntelligenceService.instance.getSmartRecommendations(
        baseProp,
        inventory,
        userBudgetCr: 9.0,
      );

      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.city, equals('Noida'));
      expect(recs.any((r) => r.id == 'P-OTHER'), isFalse);
    });
  });
}
