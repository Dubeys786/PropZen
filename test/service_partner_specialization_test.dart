import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/service_partner_profile.dart';
import 'package:dealghar_ncr_10x/models/service_request_model.dart';
import 'package:dealghar_ncr_10x/services/service_partner_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';

void main() {
  group('ServicePartnerProfile Specialization & Authorization Tests', () {
    test('Single-specialization Home Design partner permissions', () {
      final designPartner = ServicePartnerProfile(
        id: 'SP-DESIGN-TEST',
        userId: 'usr_design_test',
        businessName: 'Aura Interiors & Architecture',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(designPartner.isApproved, isTrue);
      expect(designPartner.isSuspended, isFalse);
      expect(designPartner.canProvide(ServiceCategoryType.homeDesign), isTrue);
      expect(designPartner.canProvideCategory('HOME_DESIGN'), isTrue);

      // Must NOT have permissions for other categories (Zero leak guarantee)
      expect(designPartner.canProvide(ServiceCategoryType.loan), isFalse);
      expect(designPartner.canProvideCategory('LOAN'), isFalse);
      expect(designPartner.canProvide(ServiceCategoryType.vastu), isFalse);
      expect(designPartner.canProvide(ServiceCategoryType.construction), isFalse);
      expect(designPartner.canProvide(ServiceCategoryType.propertyVerification), isFalse);
      expect(designPartner.canProvide(ServiceCategoryType.visualization), isFalse);

      expect(designPartner.portalTitle(), equals('Home Design Partner Portal'));
      expect(designPartner.emptyRequestsMessage(), contains('Home Design'));
    });

    test('Single-specialization Loan partner permissions', () {
      final loanPartner = ServicePartnerProfile(
        id: 'SP-LOAN-TEST',
        userId: 'usr_loan_test',
        businessName: 'FinZen Advisory',
        serviceCategory: 'LOAN',
        serviceCategories: ['LOAN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(loanPartner.isApproved, isTrue);
      expect(loanPartner.canProvide(ServiceCategoryType.loan), isTrue);
      expect(loanPartner.canProvide(ServiceCategoryType.homeDesign), isFalse);
      expect(loanPartner.canProvide(ServiceCategoryType.vastu), isFalse);
      expect(loanPartner.portalTitle(), equals('Loan Partner Portal'));
      expect(loanPartner.emptyRequestsMessage(), contains('Loan'));
    });

    test('Multi-specialization partner permissions', () {
      final multiPartner = ServicePartnerProfile(
        id: 'SP-MULTI-TEST',
        userId: 'usr_multi_test',
        businessName: 'Apex Design & Construction Co',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN', 'CONSTRUCTION', 'VIRTUAL_3D'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(multiPartner.approvedCategoryTypes.length, equals(3));
      expect(multiPartner.canProvide(ServiceCategoryType.homeDesign), isTrue);
      expect(multiPartner.canProvide(ServiceCategoryType.construction), isTrue);
      expect(multiPartner.canProvide(ServiceCategoryType.visualization), isTrue);

      // Must NOT be able to provide unapproved categories
      expect(multiPartner.canProvide(ServiceCategoryType.loan), isFalse);
      expect(multiPartner.canProvide(ServiceCategoryType.vastu), isFalse);
      expect(multiPartner.canProvide(ServiceCategoryType.propertyVerification), isFalse);
    });

    test('Suspended partner loses action authorizations', () {
      final suspendedPartner = ServicePartnerProfile(
        id: 'SP-SUSPENDED-TEST',
        userId: 'usr_suspended_test',
        businessName: 'Suspended Services Ltd',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'SUSPENDED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(suspendedPartner.isApproved, isFalse);
      expect(suspendedPartner.isSuspended, isTrue);
      expect(suspendedPartner.canProvide(ServiceCategoryType.homeDesign), isFalse);
    });
  });

  group('Specialized Journey Stage Tests', () {
    test('Each specialization has dedicated pipeline stages', () {
      final designStages = SpecializedJourneyHelper.getStagesForCategory(ServiceCategoryType.homeDesign);
      expect(designStages.length, equals(14));
      expect(designStages.first.name, equals('Request Received'));
      expect(designStages.last.name, equals('Feedback'));

      final loanStages = SpecializedJourneyHelper.getStagesForCategory(ServiceCategoryType.loan);
      expect(loanStages.length, equals(11));
      expect(loanStages.first.name, equals('New Request'));
      expect(loanStages.last.name, equals('Customer Feedback'));

      final vastuStages = SpecializedJourneyHelper.getStagesForCategory(ServiceCategoryType.vastu);
      expect(vastuStages.length, equals(12));

      final constStages = SpecializedJourneyHelper.getStagesForCategory(ServiceCategoryType.construction);
      expect(constStages.length, equals(16));

      final verifStages = SpecializedJourneyHelper.getStagesForCategory(ServiceCategoryType.propertyVerification);
      expect(verifStages.length, equals(13));

      final virtStages = SpecializedJourneyHelper.getStagesForCategory(ServiceCategoryType.visualization);
      expect(virtStages.length, equals(12));
    });
  });

  group('ServicePartnerService Data Isolation & Category Switcher', () {
    late ServicePartnerService service;

    setUp(() {
      service = ServicePartnerService.instance;
    });

    test('Loading Home Design profile strictly isolates data and metrics', () async {
      final designProfile = ServicePartnerProfile(
        id: 'SP-DESIGN-001',
        userId: 'usr_design_01',
        businessName: 'Aura Interiors & Architecture',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.loadForProfile(designProfile);

      expect(service.currentProfile, isNotNull);
      expect(service.activeCategory, equals(ServiceCategoryType.homeDesign));

      // Inquiries must ONLY contain HOME_DESIGN category
      final partnerRequests = service.getRequestsForPartner('SP-DESIGN-001');
      for (final req in partnerRequests) {
        expect(req.category, equals(ServiceCategoryType.homeDesign));
        expect(req.category, isNot(ServiceCategoryType.loan));
        expect(req.category, isNot(ServiceCategoryType.vastu));
      }

      // Available requests for HOME_DESIGN should be accessible
      final availableDesign = service.getAvailableRequestsForCategory(category: ServiceCategoryType.homeDesign);
      for (final req in availableDesign) {
        expect(req.category, equals(ServiceCategoryType.homeDesign));
      }

      // Partner cannot query or see available requests of unauthorized categories
      final availableLoan = service.getAvailableRequestsForCategory(category: ServiceCategoryType.loan);
      expect(availableLoan, isEmpty);
    });

    test('Unauthorized category switching is rejected', () async {
      final designProfile = ServicePartnerProfile(
        id: 'SP-DESIGN-001',
        userId: 'usr_design_01',
        businessName: 'Aura Interiors & Architecture',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.loadForProfile(designProfile);
      expect(service.activeCategory, equals(ServiceCategoryType.homeDesign));

      // Attempt to switch to LOAN (which partner is NOT approved for)
      final switchSuccess = service.setActiveCategory(ServiceCategoryType.loan);
      expect(switchSuccess, isFalse);
      // Active category remains unchanged
      expect(service.activeCategory, equals(ServiceCategoryType.homeDesign));
    });

    test('Multi-specialization partner can switch between approved categories', () async {
      final multiProfile = ServicePartnerProfile(
        id: 'SP-MULTI-001',
        userId: 'usr_multi_01',
        businessName: 'Zenith Integrated Living Solutions',
        serviceCategory: 'HOME_DESIGN',
        serviceCategories: ['HOME_DESIGN', 'CONSTRUCTION', 'VIRTUAL_3D'],
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.loadForProfile(multiProfile);
      expect(service.activeCategory, equals(ServiceCategoryType.homeDesign));

      // Switch to CONSTRUCTION (approved)
      final switchToConst = service.setActiveCategory(ServiceCategoryType.construction);
      expect(switchToConst, isTrue);
      expect(service.activeCategory, equals(ServiceCategoryType.construction));

      // Switch to VIRTUAL_3D (approved)
      final switchToVirt = service.setActiveCategory(ServiceCategoryType.visualization);
      expect(switchToVirt, isTrue);
      expect(service.activeCategory, equals(ServiceCategoryType.visualization));

      // Switch to LOAN (unapproved) -> MUST fail
      final switchToLoan = service.setActiveCategory(ServiceCategoryType.loan);
      expect(switchToLoan, isFalse);
      expect(service.activeCategory, equals(ServiceCategoryType.visualization));
    });
  });

  group('AdminCommandService Partner Governance & Specialization Management', () {
    late AdminCommandService adminService;

    setUp(() {
      adminService = AdminCommandService.instance;
    });

    test('Admin can verify a pending partner', () async {
      // Find or verify partner
      final partner = adminService.servicePartners.firstWhere(
        (p) => p.id == 'SP-CONST-001',
      );

      final success = await adminService.verifyServicePartner(partner.id);
      expect(success, isTrue);

      final updated = adminService.servicePartners.firstWhere((p) => p.id == partner.id);
      expect(updated.verificationStatus, equals('VERIFIED'));
      expect(updated.status, equals('ACTIVE'));
      expect(updated.isApproved, isTrue);
    });

    test('Admin can suspend and reactivate partner account', () async {
      final partnerId = 'SP-VASTU-001';

      // Suspend
      final suspendSuccess = await adminService.suspendServicePartner(partnerId, 'Annual license renewal pending');
      expect(suspendSuccess, isTrue);

      final suspended = adminService.servicePartners.firstWhere((p) => p.id == partnerId);
      expect(suspended.status, equals('SUSPENDED'));
      expect(suspended.isSuspended, isTrue);
      expect(suspended.isApproved, isFalse);

      // Reactivate
      final reactivateSuccess = await adminService.reactivateServicePartner(partnerId);
      expect(reactivateSuccess, isTrue);

      final reactivated = adminService.servicePartners.firstWhere((p) => p.id == partnerId);
      expect(reactivated.status, equals('ACTIVE'));
      expect(reactivated.isSuspended, isFalse);
    });

    test('Admin can modify partner approved specialization categories', () async {
      final partnerId = 'SP-LOAN-001';
      final newCategories = ['LOAN', 'PROPERTY_VERIFICATION'];

      final success = await adminService.updatePartnerCategories(partnerId, newCategories);
      expect(success, isTrue);

      final updated = adminService.servicePartners.firstWhere((p) => p.id == partnerId);
      expect(updated.serviceCategories, contains('LOAN'));
      expect(updated.serviceCategories, contains('PROPERTY_VERIFICATION'));
      expect(updated.canProvide(ServiceCategoryType.loan), isTrue);
      expect(updated.canProvide(ServiceCategoryType.propertyVerification), isTrue);
      expect(updated.canProvide(ServiceCategoryType.homeDesign), isFalse);
    });
  });
}
