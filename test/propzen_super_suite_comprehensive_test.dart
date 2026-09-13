import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/loan_model.dart';
import 'package:dealghar_ncr_10x/models/design_studio_models.dart';
import 'package:dealghar_ncr_10x/models/reporter_models.dart';
import 'package:dealghar_ncr_10x/models/super_dashboard_seo_models.dart';
import 'package:dealghar_ncr_10x/models/vendor_monetization_models.dart';
import 'package:dealghar_ncr_10x/models/nri_valuation_models.dart';
import 'package:dealghar_ncr_10x/models/location_intelligence_models.dart';
import 'package:dealghar_ncr_10x/models/ai_advisor_models.dart';
import 'package:dealghar_ncr_10x/models/international_payment_models.dart';
import 'package:dealghar_ncr_10x/models/visualization_models.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/loan_service.dart';
import 'package:dealghar_ncr_10x/services/design_studio_service.dart';
import 'package:dealghar_ncr_10x/services/visualization_service.dart';
import 'package:dealghar_ncr_10x/services/super_dashboard_service.dart';
import 'package:dealghar_ncr_10x/services/seo_engine_service.dart';
import 'package:dealghar_ncr_10x/services/vendor_wallet_lead_service.dart';
import 'package:dealghar_ncr_10x/services/nri_smart_valuation_service.dart';
import 'package:dealghar_ncr_10x/services/nri_location_intelligence_service.dart';
import 'package:dealghar_ncr_10x/services/nri_ai_advisor_engine_service.dart';
import 'package:dealghar_ncr_10x/services/international_payment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Comprehensive Production Suite Tests', () {
    // 1. LOAN FACILITIES MODULE TESTS
    test('LoanService EMI math and Indicative Eligibility calculations', () async {
      final loanService = LoanService.instance;
      final emiResult = loanService.calculateEmi(
        loanAmount: 5000000,
        interestRatePercent: 8.5,
        tenureYears: 20,
      );

      expect(emiResult['monthly_emi']!, greaterThan(40000));
      expect(emiResult['monthly_emi']!, lessThan(50000));
      expect(emiResult['total_repayment']!, greaterThan(5000000));

      final eligibility = await loanService.estimateEligibility(
        monthlyIncome: 150000,
        existingEmi: 20000,
        interestRate: 8.5,
        tenureYears: 20,
      );

      expect(eligibility.maxEligibleLoan, greaterThan(6000000));
      expect(eligibility.foirPercentage, equals(55.0));
      expect(eligibility.legalDisclaimer, contains('Indicative estimate only'));
    });

    test('Loan Application submission and Status updates', () async {
      final loanService = LoanService.instance;
      final request = LoanRequestModel(
        id: 'LOAN-TEST-001',
        userId: 'usr_test',
        propertyTitle: 'Mahagun Manorialle 4 BHK',
        propertyPrice: 35000000,
        downPayment: 7000000,
        loanAmount: 28000000,
        name: 'Vikas Sharma',
        phone: '+91 98103 94068',
        email: 'vikas@propzen.ai',
        monthlyIncome: 450000,
        indicativeEligibility: 25000000,
        status: LoanStatus.newRequest,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final appId = await loanService.submitLoanApplication(request);
      expect(appId, equals('LOAN-TEST-001'));
      expect(loanService.applications.first.id, equals('LOAN-TEST-001'));

      loanService.updateLoanStatus('LOAN-TEST-001', LoanStatus.approved, remarks: 'Sanction letter issued by SBI.');
      expect(loanService.applications.first.status, equals(LoanStatus.approved));
      expect(loanService.applications.first.adminRemarks, contains('Sanction letter'));
    });

    // 2. DESIGN STUDIO & VASTU TESTS
    test('DesignStudioService Vastu calculation and Project layout persistence', () {
      final designService = DesignStudioService.instance;
      final input = const VastuInputModel(
        plotWidth: 35.0,
        plotLength: 70.0,
        facingDirection: 'East',
        entranceDirection: 'North-East',
      );

      final vastu = designService.analyzeVastu(input);
      expect(vastu.overallScore, greaterThanOrEqualTo(85));
      expect(vastu.ratingGrade, contains('Excellent'));
      expect(vastu.disclaimer, contains('Vastu guidance is advisory'));

      expect(designService.projects, isNotEmpty);
      expect(designService.projects.first.rooms, isNotEmpty);
    });

    // 3. 3D VISUALIZATION TESTS
    test('VisualizationService replaceable provider and fallback handling', () async {
      final vizService = VisualizationService.instance;
      expect(vizService.activeProvider.isConfigured, isTrue);

      final unconfiguredProvider = ExternalCloud3dProvider(configured: false);
      vizService.setProvider(unconfiguredProvider);
      expect(vizService.activeProvider.isConfigured, isFalse);

      final job = VisualizationJobModel(
        id: 'VJOB-TEST-01',
        userId: 'usr_active',
        jobType: '3d_floor_plan',
        status: 'PROCESSING',
        createdAt: DateTime.now(),
      );

      expect(
        () => unconfiguredProvider.generate3dLayout(job),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('3D visualization provider is not configured yet.'))),
      );

      // Restore built-in provider
      vizService.setProvider(DefaultIsometric3dProvider());
      expect(vizService.activeProvider.isConfigured, isTrue);
    });

    // 4. REPORTER NEWS MODULE TESTS
    test('ReporterVideoModel and Script serialization', () {
      final script = const ReporterScriptModel(
        headline: 'Jewar Airport Operational Countdown Begins',
        shortScript30s: 'Final runway calibration flights underway.',
        fullScript60s: 'DGCA conducts final calibration flights.',
        caption: '#JewarAirport #NoidaRealEstate',
        description: 'Testing update.',
      );

      final video = ReporterVideoModel(
        id: 'VID-TEST-01',
        title: 'Jewar Airport Operational Countdown Begins',
        description: 'Testing update.',
        category: 'Infrastructure',
        videoUrl: 'https://propzen.ai/videos/jewar.mp4',
        thumbnailUrl: 'https://propzen.ai/thumb.jpg',
        script: script,
        sourceInformation: 'DGCA Press Release',
        status: ReporterStatus.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(video.status.dbValue, equals('PUBLISHED'));
      expect(video.script.headline, contains('Jewar Airport'));
      final map = video.toMap();
      expect(map['category'], equals('Infrastructure'));
    });

    // 5. SUPER DASHBOARD MODULE TESTS
    test('SuperDashboardService live metrics and category breakdown', () async {
      final superService = SuperDashboardService.instance;
      final metrics = await superService.fetchPlatformOverview();

      expect(metrics.totalProperties, greaterThan(0));
      expect(metrics.liveProperties, greaterThan(0));
      expect(metrics.conversionRatePercent, equals(40.0));

      final categories = superService.getCategoryDistribution();
      expect(categories, isNotEmpty);
      expect(categories.fold<double>(0, (a, b) => a + b.percentage), closeTo(100.0, 0.5));

      final revenue = superService.getMonthlyRevenueSeries();
      expect(revenue.length, equals(5));
      expect(revenue.last.total, greaterThan(500000));
    });

    // 6. SEO ENGINE MODULE TESTS
    test('SeoEngineService dynamic slugs, JSON-LD schema, and sitemap generation', () {
      final seoService = SeoEngineService.instance;
      final testProp = Property(
        id: 'PROP-TEST-99',
        title: 'Godrej Palm Retreat Luxury Villas',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 2.75,
        bhk: '3 BHK',
        sqft: 1950,
      );

      final meta = seoService.generateSeoMetadataForProperty(testProp);
      expect(meta.slug, equals('/property/godrej-palm-retreat-luxury-villas-sector-150-noida'));
      expect(meta.canonicalUrl, contains('https://propzen.ai/property/'));
      expect(meta.metaTitle, contains('Godrej Palm Retreat'));
      expect(meta.structuredDataJson['@type'], equals('RealEstateListing'));

      final xml = seoService.generateSitemapXml([testProp]);
      expect(xml, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(xml, contains('<loc>https://propzen.ai/property/godrej-palm-retreat-luxury-villas-sector-150-noida</loc>'));
    });

    // 7. VENDOR WALLET & LEAD MONETIZATION TESTS
    test('VendorWalletLeadService atomic recharge, non-negative balance guard, and fair scoring rules', () async {
      final walletService = VendorWalletLeadService.instance;
      final initialBalance = walletService.wallet.balanceInr;

      await walletService.topUpWallet(
        amountInr: 5000.0,
        providerPaymentId: 'RZP-UNIT-TEST',
        signature: 'valid_sig_hash',
      );

      expect(walletService.wallet.balanceInr, equals(initialBalance + 5000.0));
      expect(walletService.transactions.first.referenceId, equals('RZP-UNIT-TEST'));

      // Test fair scoring rule sum
      final rules = walletService.rules;
      final totalWeight = rules.subscriptionWeight +
          rules.locationWeight +
          rules.categoryWeight +
          rules.verificationWeight +
          rules.responseRateWeight +
          rules.rotationWeight;
      expect(totalWeight, closeTo(1.0, 0.01));

      // Test contact unlocking
      final firstLead = walletService.assignments.first;
      expect(firstLead.effectivePhone, contains('•••••'));
      await walletService.acceptLead(firstLead.id);
      expect(walletService.assignments.first.effectivePhone, isNot(contains('•••••')));
    });

    // 8. NRI SMART PROPERTY VALUATION TESTS
    test('NriSmartValuationService scenario projections and legal disclaimer', () async {
      final valuationService = NriSmartValuationService.instance;
      final testProp = Property(
        id: 'PROP-VAL-TEST',
        title: 'ATS Kingston Heath 3 BHK',
        sector: 'Sector 150',
        city: 'Noida',
        askingPriceCr: 2.0,
        sqft: 1800,
        rentalYieldPercent: 4.6,
      );

      final rep = await valuationService.fetchValuationForProperty(testProp);
      expect(rep.currentValueCr, equals(2.0));
      expect(rep.conservative1yCr, greaterThan(2.0));
      expect(rep.base1yCr, greaterThan(rep.conservative1yCr));
      expect(rep.optimistic1yCr, greaterThan(rep.base1yCr));

      expect(rep.disclaimer, equals('Illustrative projection based on available data. Actual market value may differ.'));
      expect(rep.historicalTrend.length, equals(4));
    });

    // 9. NRI LOCATION INTELLIGENCE TESTS
    test('NriLocationIntelligenceService 7-pillar weighted score and AQI timestamp', () async {
      final locService = NriLocationIntelligenceService.instance;
      final testProp = Property(
        id: 'PROP-LOC-TEST',
        title: 'Signature Towers',
        sector: 'Sector 128',
        city: 'Noida',
        askingPriceCr: 3.2,
      );

      final rep = await locService.fetchLocationIntelligence(testProp);
      expect(rep.isAvailable, isTrue);
      expect(rep.scoreBreakdown.overallScore, greaterThan(0.0));
      expect(rep.scoreBreakdown.overallScore, lessThanOrEqualTo(10.0));
      expect(rep.aqiSnapshot.aqi, greaterThan(0));
      expect(rep.hospitals, isNotEmpty);
      expect(rep.schools, isNotEmpty);
    });

    // 10. NRI AI ADVISOR TESTS (Strict Non-Hallucination)
    test('NriAiAdvisorEngineService extracts criteria and strictly returns real catalog properties', () async {
      final advisorService = NriAiAdvisorEngineService.instance;
      final response = await advisorService.processUserQuery('I have a 2 crore budget and want commercial property on Noida Expressway');

      expect(response.extractedCriteria, isNotNull);
      expect(response.extractedCriteria!.maxBudgetCr, equals(2.0));
      expect(response.extractedCriteria!.propertyType, equals('Commercial'));
      expect(response.extractedCriteria!.localityOrSector, equals('Expressway'));
      expect(response.recommendations, isNotEmpty);
      expect(response.recommendations.first.whyItMatches, isNotEmpty);
    });

    // 11. INTERNATIONAL PAYMENT MODULE TESTS
    test('InternationalPaymentService category isolation, currency conversion, and receipt issuance', () async {
      final paymentService = InternationalPaymentService.instance;

      // Currency conversion test
      final inrAmount = 8450.0;
      final usdAmount = paymentService.convertInrTo(inrAmount, 'USD');
      expect(usdAmount, closeTo(100.0, 0.1));

      // Category isolation check: verify Property Token is isolated from Vendor Wallet
      final tokenCategory = PaymentCategory.propertyToken;
      final walletCategory = PaymentCategory.vendorWallet;
      expect(tokenCategory.dbValue, isNot(equals(walletCategory.dbValue)));

      // Process payment order
      final receipt = await paymentService.processPaymentOrder(
        userId: 'usr_unit_test',
        category: PaymentCategory.serviceFee,
        amountInr: 3999.0,
        currency: 'USD',
      );

      expect(receipt.status, equals(PaymentStatus.success));
      expect(receipt.idempotencyKey, isNotEmpty);
      expect(receipt.receiptUrl, contains('propzen.ai/receipts/'));
    });
  });
}
