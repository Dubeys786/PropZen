import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dealer Property Approval System Tests', () {
    late PropertyStateService stateService;

    setUp(() {
      stateService = PropertyStateService.instance;
      // Reset state
      stateService.setProperties(List.from(Property.sampleDeals));
    });

    test('1. Sample deals default to published and are visible to public users', () {
      final publicProps = stateService.allProperties;
      expect(publicProps.isNotEmpty, isTrue);
      for (final p in publicProps) {
        expect(p.isPublished, isTrue);
        expect(p.status, 'published');
        expect(p.isPending, isFalse);
        expect(p.isRejected, isFalse);
      }
    });

    test('2. Dealer submitting property sets status = pending and DOES NOT leak to public users', () {
      const testId = 'PROP-TEST-PENDING-001';
      final newDealerProp = Property(
        id: testId,
        title: 'Luxury 3 BHK Penthouse Express',
        sector: 'Sector 150',
        city: 'Noida',
        locality: 'Sector 150',
        address: 'Tower A, Sports City, Sector 150, Noida',
        postalCode: '201310',
        placeId: 'place_sector_150_test',
        latitude: 28.4354,
        longitude: 77.4878,
        category: 'Residential',
        propertyType: 'Apartment',
        askingPriceCr: 1.85,
        fairValueCr: 1.95,
        pricePerSqft: 7500,
        score10x: 9.3,
        rentalYieldPercent: 4.9,
        sqft: 1850,
        carpetAreaSqft: 1550,
        bhk: '3 BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        dealerId: 'DLR-9810394068',
        dealerName: 'Rajesh Varma',
        dealerPhone: '+91 98103 94068',
        dealerEmail: 'rajesh.varma@propzen.ai',
        status: 'pending',
      );

      // Dealer submits property
      stateService.addDealerPropertySubmission(newDealerProp);

      // MUST NOT be present in public allProperties
      final publicProps = stateService.allProperties;
      expect(publicProps.any((p) => p.id == testId), isFalse);

      // MUST be present in raw / pending / dealer lists
      expect(stateService.pendingProperties.any((p) => p.id == testId), isTrue);
      expect(stateService.getDealerPropertiesFor('DLR-9810394068').any((p) => p.id == testId), isTrue);
      expect(stateService.rawProperties.firstWhere((p) => p.id == testId).isPending, isTrue);
    });

    test('3. Admin approving property changes status to published and makes it visible publicly', () {
      const testId = 'PROP-TEST-APPROVE-002';
      final submittedProp = Property(
        id: testId,
        title: 'Grand Highstreet Retail Shop',
        sector: 'Sector 137',
        city: 'Noida',
        locality: 'Sector 137',
        category: 'Commercial',
        propertyType: 'Retail Shop',
        askingPriceCr: 0.95,
        fairValueCr: 1.05,
        pricePerSqft: 12000,
        score10x: 9.0,
        rentalYieldPercent: 6.2,
        sqft: 500,
        bhk: 'Commercial',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        dealerId: 'DLR-9810394068',
        dealerName: 'Rajesh Varma',
        status: 'pending',
      );

      stateService.addDealerPropertySubmission(submittedProp);
      expect(stateService.allProperties.any((p) => p.id == testId), isFalse);

      // Admin approves
      stateService.approveProperty(testId, adminId: 'admin@propzen.ai', adminNote: 'Verified & Approved');

      // Now MUST be present in public allProperties
      final publicProps = stateService.allProperties;
      final approvedProp = publicProps.firstWhere((p) => p.id == testId);
      expect(approvedProp.isPublished, isTrue);
      expect(approvedProp.status, 'published');
      expect(approvedProp.approvedBy, 'admin@propzen.ai');
      expect(approvedProp.approvedAt, isNotNull);
    });

    test('4. Admin rejecting property records adminNote reason and keeps it hidden from public', () {
      const testId = 'PROP-TEST-REJECT-003';
      final submittedProp = Property(
        id: testId,
        title: 'Unverified Land Parcel',
        sector: 'Sector 142',
        city: 'Noida',
        category: 'Residential',
        propertyType: 'Plot',
        askingPriceCr: 3.5,
        fairValueCr: 3.5,
        pricePerSqft: 8000,
        score10x: 8.5,
        rentalYieldPercent: 3.0,
        sqft: 2500,
        bhk: 'Plot',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        dealerId: 'DLR-9810394068',
        dealerName: 'Rajesh Varma',
        status: 'pending',
      );

      stateService.addDealerPropertySubmission(submittedProp);

      // Admin rejects with reason
      const rejectionReason = 'Please provide valid RERA certificate and clearer site photos.';
      stateService.rejectProperty(testId, reason: rejectionReason, adminId: 'admin@propzen.ai');

      // MUST NOT be in public properties
      expect(stateService.allProperties.any((p) => p.id == testId), isFalse);

      // MUST be in rejected list and contain adminNote
      final rejectedProp = stateService.rejectedProperties.firstWhere((p) => p.id == testId);
      expect(rejectedProp.isRejected, isTrue);
      expect(rejectedProp.status, 'rejected');
      expect(rejectedProp.adminNote, rejectionReason);
    });

    test('5. Serialization and Deserialization preserve approval fields & contact separation', () {
      final prop = Property(
        id: 'PROP-SER-001',
        title: 'Serialization Test Property',
        sector: 'Sector 62',
        city: 'Noida',
        locality: 'Sector 62',
        address: 'Sector 62 Institutional Area, Noida',
        postalCode: '201309',
        placeId: 'chij_test_serial',
        latitude: 28.6270,
        longitude: 77.3620,
        category: 'Commercial',
        propertyType: 'Office Space',
        askingPriceCr: 2.2,
        fairValueCr: 2.3,
        pricePerSqft: 9500,
        score10x: 9.1,
        rentalYieldPercent: 5.5,
        sqft: 1500,
        bhk: 'Commercial',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00',
        dealerId: 'DLR-9876543210',
        dealerName: 'Pooja Mehta',
        dealerPhone: '+91 98765 43210',
        dealerEmail: 'pooja.mehta@propzen.ai',
        contactName: 'Pooja Mehta',
        contactPhone: '+91 98765 43210',
        contactEmail: 'pooja.mehta@propzen.ai',
        status: 'rejected',
        adminNote: 'Needs updated registry docs',
        approvedAt: '2026-08-19T10:00:00Z',
        approvedBy: 'adm_master',
      );

      final map = prop.toMap();
      expect(map['status'], 'rejected');
      expect(map['admin_note'], 'Needs updated registry docs');
      expect(map['dealer_email'], 'pooja.mehta@propzen.ai');
      expect(map['contact_phone'], '+91 98765 43210');

      final deserialized = Property.fromMap(map);
      expect(deserialized.id, prop.id);
      expect(deserialized.status, 'rejected');
      expect(deserialized.isRejected, isTrue);
      expect(deserialized.adminNote, 'Needs updated registry docs');
      expect(deserialized.dealerEmail, 'pooja.mehta@propzen.ai');
      expect(deserialized.contactPhone, '+91 98765 43210');
    });
  });
}
