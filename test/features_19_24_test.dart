import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/loan_model.dart';
import 'package:dealghar_ncr_10x/services/loan_service.dart';
import 'package:dealghar_ncr_10x/models/supplier_model.dart';
import 'package:dealghar_ncr_10x/services/supplier_service.dart';
import 'package:dealghar_ncr_10x/models/forum_model.dart';
import 'package:dealghar_ncr_10x/services/forum_service.dart';
import 'package:dealghar_ncr_10x/services/chat_service.dart';
import 'package:dealghar_ncr_10x/models/nri_model.dart';
import 'package:dealghar_ncr_10x/services/currency_service.dart';
import 'package:dealghar_ncr_10x/services/nri_meeting_service.dart';
import 'package:dealghar_ncr_10x/models/region_model.dart';
import 'package:dealghar_ncr_10x/services/region_service.dart';
import 'package:dealghar_ncr_10x/models/construction_model.dart';
import 'package:dealghar_ncr_10x/services/construction_service.dart';
import 'package:dealghar_ncr_10x/models/property.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProp = const Property(
    id: 'prop_sector_150_01',
    title: 'Mahagun Manorialle Luxury Suites',
    propertyType: 'Apartment',
    bhk: '3 BHK',
    askingPriceCr: 2.2,
    sqft: 2150,
    sector: 'Sector 150',
    city: 'Noida',
    postalCode: '201310',
    latitude: 28.4595,
    longitude: 77.5020,
    imageUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb18f15f6',
  );

  group('Feature 19: Loan Comparison & Processing', () {
    final loanService = LoanService.instance;

    test('should provide partner bank products with indicative interest rates', () {
      final prods = loanService.loanProducts;
      expect(prods.length, greaterThanOrEqualTo(4));
      final sbi = prods.firstWhere((p) => p.lenderId == 'bank_sbi');
      expect(sbi.interestRate, equals(8.50));
      expect(sbi.rateType, contains('Floating EBLR'));
    });

    test('should calculate accurate EMI without negative values', () {
      final res = loanService.calculateEmi(
        loanAmount: 5000000,
        interestRatePercent: 8.5,
        tenureYears: 20,
      );
      expect(res['emi'], greaterThan(40000));
      expect(res['totalPayment'], greaterThan(5000000));
    });

    test('should return indicative eligibility status without claiming 100% guarantee', () async {
      final eligible = await loanService.estimateEligibility(
        monthlyIncome: 150000,
        existingEmi: 15000,
        interestRate: 8.5,
        tenureYears: 20,
      );
      expect(eligible.eligibilityStatus, equals('LIKELY_ELIGIBLE'));
      expect(eligible.maxEligibleLoan, greaterThan(0));
      expect(eligible.legalDisclaimer, contains('Indicative estimate only'));
    });
  });

  group('Feature 20: Construction Supplier Directory', () {
    final supplierService = SupplierService.instance;

    test('should filter suppliers by construction material categories', () {
      final cementSuppliers = supplierService.filterSuppliers(category: SupplierCategory.cement);
      expect(cementSuppliers.isNotEmpty, isTrue);
      expect(cementSuppliers.first.category, equals(SupplierCategory.cement));
    });

    test('should submit quote request for verified supplier', () async {
      final reqId = await supplierService.requestQuote(
        supplierId: 'sup_01_ultratech',
        userId: 'usr_test',
        userName: 'Test Builder',
        userPhone: '+91 99999 88888',
        materialNeeded: 'UltraTech Super Cement',
        quantity: '500 Bags',
        siteLocation: 'Sector 150, Noida',
      );
      expect(reqId.startsWith('quot_'), isTrue);
      expect(supplierService.quoteRequests.any((r) => r.requestId == reqId), isTrue);
    });
  });

  group('Feature 21: Buyer-Seller Forum & Real-Time Chat', () {
    final forumService = ForumService.instance;
    final chatService = ChatService.instance;

    test('should filter forum posts across 10 structured categories', () {
      final legalPosts = forumService.getPostsForSection(ForumSection.legalDocumentation);
      expect(legalPosts.isNotEmpty, isTrue);
      expect(legalPosts.first.title, contains('RERA'));
    });

    test('should add new post and support community comments and upvotes', () {
      forumService.createPost(
        section: ForumSection.construction,
        title: 'Best waterproofing techniques for basement slabs',
        content: 'Sharing experience using crystalline waterproofing admixtures vs torch-on bitumen membranes.',
        authorId: 'usr_engineer_01',
        authorName: 'Er. Nitin Rao',
      );
      final latest = forumService.posts.first;
      expect(latest.title, contains('waterproofing'));

      forumService.addComment(latest.postId, 'usr_builder_02', 'Sunil Builder', 'Crystalline admixture performed better.');
      expect(forumService.getComments(latest.postId).length, equals(1));

      final initialVotes = latest.upvotes;
      forumService.upvotePost(latest.postId);
      expect(forumService.posts.first.upvotes, equals(initialVotes + 1));
    });

    test('should strictly isolate participant messages in chat', () {
      final conv = chatService.conversations.first;
      final messages = chatService.getMessagesForConversation(conv.conversationId, 'usr_buyer_demo');
      expect(messages.isNotEmpty, isTrue);

      expect(
        () => chatService.getMessagesForConversation(conv.conversationId, 'usr_unauthorized_stranger'),
        throwsException,
      );
    });
  });

  group('Feature 22: NRI Property Hub & Currency/Timezone', () {
    final currencyService = CurrencyService.instance;
    final meetingService = NriMeetingService.instance;

    test('should convert INR prices into USD, AED, GBP, EUR', () {
      currencyService.setCurrency('USD');
      final formattedUsd = currencyService.formatConvertedPrice(10000000, 'USD');
      expect(formattedUsd, contains('\$'));

      final formattedAed = currencyService.formatConvertedPrice(10000000, 'AED');
      expect(formattedAed, contains('AED'));
    });

    test('should schedule time-zone aware NRI meeting', () async {
      final meetId = await meetingService.scheduleMeeting(
        property: testProp,
        attendeeId: 'usr_nri_uk',
        attendeeName: 'Anil Kumar',
        attendeeEmail: 'anil.k@london.co.uk',
        timezone: 'Europe/London (GMT+0)',
        scheduledTimeUtc: DateTime.now().add(const Duration(days: 4)),
        meetingType: NriMeetingType.videoCall,
      );
      expect(meetId.startsWith('meet_'), isTrue);
      expect(meetingService.meetings.any((m) => m.meetingId == meetId), isTrue);
    });
  });

  group('Feature 23: Multi-Region Scaling Architecture', () {
    final regionService = RegionConfigService.instance;

    test('should maintain active regions with localized boundaries and pincodes', () {
      final regions = regionService.regions;
      expect(regions.any((r) => r.regionId == 'reg_noida' && r.enabled), isTrue);
      expect(regions.any((r) => r.regionId == 'reg_delhi_ncr' && r.enabled), isTrue);
      expect(regions.any((r) => r.regionId == 'reg_up_major' && !r.enabled), isTrue);
    });

    test('should allow switching browsing region and filter properties accordingly', () {
      regionService.selectRegion('reg_delhi_ncr');
      expect(regionService.selectedRegion.regionId, equals('reg_delhi_ncr'));

      regionService.selectRegion('reg_noida');
      expect(regionService.selectedRegion.regionId, equals('reg_noida'));
    });
  });

  group('Feature 24: Real-Time Construction Progress Tracking', () {
    final constructionService = ConstructionService.instance;

    test('should represent all 13 construction phases in sequence', () {
      expect(ConstructionPhase.values.length, equals(13));
      expect(ConstructionPhase.values.first, equals(ConstructionPhase.landPreparation));
      expect(ConstructionPhase.values.last, equals(ConstructionPhase.handover));
    });

    test('should allow site engineers to submit photo updates and update milestones', () {
      final project = constructionService.getProjectForProperty(testProp);
      expect(project.overallProgress, greaterThan(0));

      final initialUpdatesCount = project.updates.length;
      constructionService.submitEngineerUpdate(
        projectId: project.projectId,
        phase: ConstructionPhase.structure,
        title: '5th Floor Slab Casting Complete',
        description: 'M30 ready mix concrete poured and cured with ultrasonic test certification.',
        progress: 82.0,
        photos: ['https://images.unsplash.com/photo-1541888946425-d0fbb18f15f6?w=600'],
        engineerName: 'Er. Test Site Engineer',
      );

      final updatedProject = constructionService.getProjectForProperty(testProp);
      expect(updatedProject.updates.length, equals(initialUpdatesCount + 1));
      expect(updatedProject.overallProgress, equals(82.0));
    });
  });
}
