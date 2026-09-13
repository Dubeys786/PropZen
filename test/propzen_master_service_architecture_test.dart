import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/dealer.dart';
import 'package:dealghar_ncr_10x/models/verification_report_model.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/property_service.dart';
import 'package:dealghar_ncr_10x/services/dealer_service.dart';
import 'package:dealghar_ncr_10x/services/enquiry_service.dart';
import 'package:dealghar_ncr_10x/services/site_visit_service.dart';
import 'package:dealghar_ncr_10x/services/verification_service.dart';
import 'package:dealghar_ncr_10x/services/ai_advisor_service.dart';
import 'package:dealghar_ncr_10x/services/vastu_service.dart';
import 'package:dealghar_ncr_10x/services/home_design_service.dart';
import 'package:dealghar_ncr_10x/services/video_reporter_service.dart';
import 'package:dealghar_ncr_10x/services/notification_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  setUp(() {
    UserSession.clear();
  });

  group('PropZen Master Production Architecture & Service Layer Tests', () {
    // 1. AuthService Tests
    test('AuthService handles sign in and role session routing', () async {
      final auth = AuthService.instance;
      expect(auth.isLoggedIn, isFalse);

      final res = await auth.signInWithEmail(
        identifier: 'test_buyer@propzen.ai',
        password: 'password123',
      );

      expect(res.isSuccess, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.isCustomer, isTrue);

      auth.logout();
      expect(auth.isLoggedIn, isFalse);
    });

    test('AuthService signs in dealer and maps dealer role', () async {
      final auth = AuthService.instance;
      final res = await auth.signInWithEmail(
        identifier: 'dealer_ncr@propzen.ai',
        password: 'dealerPass123',
      );

      expect(res.isSuccess, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.isDealer, isTrue);
    });

    // 2. PropertyService Tests
    test('PropertyService performs exact multi-criteria search', () async {
      final propService = PropertyService.instance;

      // Exact 2 BHK search
      final results2bhk = await propService.searchProperties(
        categoryChip: '2 BHK Apartments',
      );
      expect(results2bhk, isNotEmpty);
      for (final p in results2bhk) {
        expect(p.bhk.toLowerCase(), contains('2 bhk'));
      }

      // Exact Sector 150 search
      final resultsSec150 = await propService.searchProperties(
        categoryChip: 'Sector 150',
      );
      expect(resultsSec150, isNotEmpty);
      for (final p in resultsSec150) {
        final loc = '${p.locality} ${p.sector} ${p.address} ${p.title}'.toLowerCase();
        expect(loc, contains('150'));
      }
    });

    test('PropertyService retrieves dynamic categories', () async {
      final propService = PropertyService.instance;
      final categories = await propService.fetchDynamicCategories();
      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.name.contains('Sector 150')), isTrue);
    });

    // 3. DealerService Tests
    test('DealerService registers dealer and submits pending listing', () async {
      final dealerService = DealerService.instance;
      final registered = await dealerService.registerDealer(
        dealerId: 'DLR-TEST-99',
        companyName: 'Apex NCR Properties',
        phone: '+91 98103 94068',
        email: 'dealer@apex.com',
      );
      expect(registered, isTrue);

      const testProp = Property(
        id: 'PROP-TEST-99',
        title: 'ATS Kingston Heath Luxury Residences',
        sector: 'Sector 150',
        city: 'Noida',
        category: 'Residential',
        propertyType: 'Apartment',
        askingPriceCr: 2.4,
        fairValueCr: 2.45,
        pricePerSqft: 11000,
        score10x: 9.4,
        rentalYieldPercent: 4.5,
        sqft: 2180,
        bhk: '3 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
        possessionDate: 'Ready to Move',
        isVerified: true,
        rating: 4.9,
        reviewCount: 28,
        dealerPhone: '+91 98103 94068',
        description: 'Luxury 3BHK overlooking 9-hole golf course.',
        amenities: ['Golf Course View', 'Clubhouse', 'Infinity Pool'],
        nearby: {'Metro': '600m'},
        statusTag: 'Featured',
        reraId: 'UPRERAPRJ990011',
        builderName: 'ATS Infrastructure',
        facing: 'North-East',
        furnishing: 'Semi-Furnished',
        availability: 'Ready to Move',
        intelligenceScore: 94,
        investmentScore: 92,
        status: 'pending',
      );

      final submitted = await dealerService.submitPropertyListing(
        testProp,
        dealerId: 'DLR-TEST-99',
        dealerName: 'Apex NCR Properties',
        dealerPhone: '+91 98103 94068',
        dealerEmail: 'dealer@apex.com',
      );
      expect(submitted, isTrue);
    });

    // 4. EnquiryService Tests
    test('EnquiryService submits enquiry and stores record', () async {
      final enquiryService = EnquiryService.instance;
      final res = await enquiryService.submitEnquiry(
        propertyTitle: 'Mahagun Manorialle',
        propertyId: 'PROP-001',
        name: 'Rahul Sharma',
        email: 'rahul@example.com',
        phone: '9810394068',
        message: 'Please send complete brochure and floor plans.',
      );

      expect(res.isSuccess, isTrue);
      expect(res.enquiryId, startsWith('ENQ-'));
    });

    // 5. SiteVisitService Tests
    test('SiteVisitService registers site visit booking with cab requirement', () async {
      final visitService = SiteVisitService.instance;
      final res = await visitService.bookSiteVisit(
        propertyTitle: 'ATS HomeKraft Happy Trails',
        propertyId: 'PROP-002',
        name: 'Priya Verma',
        email: 'priya@example.com',
        phone: '9810394068',
        visitDate: '2026-09-05',
        visitTime: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
        pickupLocation: 'Botanical Garden Metro Station, Noida',
      );

      expect(res.isSuccess, isTrue);
      expect(res.bookingId, startsWith('VISIT-'));
    });

    // 6. VerificationService & Property Intelligence Tests
    test('VerificationService generates report with legal disclaimer and risk gauge', () async {
      final verifService = VerificationService.instance;
      final prop = Property.sampleDeals.first;

      final report = await verifService.fetchReportForProperty(prop);
      expect(report.propertyId, equals(prop.id));
      expect(report.riskScore, greaterThanOrEqualTo(70));
      expect(report.statusBadgeLabel, contains('RISK'));
      expect(report.remarks, contains(VerificationReportModel.mandatoryLegalDisclaimer));
    });

    // 7. AIAdvisorService Tests
    test('AIAdvisorService recommends properties strictly from database catalog', () async {
      final advisor = AIAdvisorService.instance;
      final recommendations = await advisor.getRecommendations(
        location: 'Sector 150',
        budgetCr: 2.5,
        propertyType: 'Apartment',
        bhk: '3 BHK',
        purpose: 'Investment',
      );

      expect(recommendations, isNotEmpty);
      for (final rec in recommendations) {
        expect(rec.matchPercentage, greaterThanOrEqualTo(60));
        expect(rec.property.id, isNotEmpty);
        expect(rec.matchReasons, isNotEmpty);
      }
    });

    // 8. VastuService Tests
    test('VastuService provides directional analysis and room placement advice', () {
      final vastu = VastuService.instance;
      final analysis = vastu.analyzeVastu(
        plotWidth: 30,
        plotLength: 60,
        propertyType: 'Independent Villa',
        direction: 'North-East',
        entranceDirection: 'North-East',
      );

      expect(analysis.overallScore, greaterThanOrEqualTo(80));
      expect(analysis.roomSuggestions, isNotEmpty);
      expect(analysis.disclaimer, isNotEmpty);
    });

    // 9. HomeDesignService Tests
    test('HomeDesignService provides curated visualizer styles', () async {
      final designService = HomeDesignService.instance;
      expect(HomeDesignService.defaultStyles, isNotEmpty);

      final render = await designService.generateDesignRender(
        roomType: 'Living Room',
        designTheme: 'Luxury',
      );
      expect(render, isNotEmpty);
    });

    // 10. VideoReporterService Tests
    test('VideoReporterService generates market update videos', () async {
      final reporter = VideoReporterService.instance;
      expect(reporter.videos, isNotEmpty);

      final generated = await reporter.generateMarketUpdateVideo(
        sector: 'Sector 150',
        locality: 'Noida Expressway',
        topic: 'Metro Extension & Appreciation',
      );
      expect(generated, isTrue);
    });

    // 11. NotificationService Tests
    test('NotificationService manages notification stream', () async {
      final notifService = NotificationService.instance;
      final sent = await notifService.sendNotification(
        title: 'New Site Visit Confirmed',
        message: 'Your site visit for ATS Kingston Heath is confirmed.',
        type: 'site_visit',
      );
      expect(sent, isTrue);
      expect(notifService.notifications, isNotEmpty);
    });
  });
}
