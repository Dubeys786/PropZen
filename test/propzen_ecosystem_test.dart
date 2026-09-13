import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/buyer_requirement.dart';
import 'package:dealghar_ncr_10x/models/lead_model.dart';
import 'package:dealghar_ncr_10x/models/deal_room_model.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/models/site_visit_checklist_model.dart';
import 'package:dealghar_ncr_10x/services/ai_copywriter_service.dart';
import 'package:dealghar_ncr_10x/services/ai_matching_service.dart';
import 'package:dealghar_ncr_10x/services/ai_negotiation_service.dart';
import 'package:dealghar_ncr_10x/services/deal_room_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen AI Ecosystem & Role Tests', () {
    test('BuyerRequirement deterministic matching engine evaluates property fit', () {
      final req = BuyerRequirement(
        id: 'REQ-01',
        userId: 'USR-01',
        userName: 'Vikram Mehta',
        preferredLocations: ['Sector 150', 'Noida Expressway'],
        minBudgetCr: 1.5,
        maxBudgetCr: 2.5,
        propertyType: 'Apartment',
        bhk: '3 BHK',
        minAreaSqft: 1500,
        requiredAmenities: ['Swimming Pool', 'Club House'],
      );

      final sampleProp = Property(
        id: 'PROP-01',
        title: 'ATS Pious Orchards Luxury Suites',
        askingPriceCr: 1.85,
        sqft: 1850,
        bhk: '3 BHK',
        propertyType: 'Apartment',
        sector: 'Sector 150',
        city: 'Noida',
        amenities: ['Swimming Pool', 'Club House', 'Gym'],
        possessionStatus: 'Ready to Move',
        isVerified: true,
      );

      final match = req.matchAgainst(sampleProp);

      expect(match.matchPercentage, greaterThanOrEqualTo(85));
      expect(match.matchGrade, contains('Exceptional'));
      expect(match.matchReasons.any((r) => r.isMatched && r.text.contains('Within budget')), isTrue);
      expect(match.matchReasons.any((r) => r.isMatched && r.text.contains('Preferred location')), isTrue);
    });

    test('DealerLead AI Lead Scoring accurately classifies Hot and Warm tiers', () {
      final hotLead = DealerLead(
        id: 'L-HOT',
        dealerId: 'D-01',
        buyerName: 'Dr. Sameer Kapoor',
        buyerPhone: '+91 98112 34567',
        propertyId: 'PROP-01',
        propertyTitle: 'ATS Pious Orchards',
        budgetCr: 1.95,
        leadScore: 94,
        scoreTier: LeadScoreTier.hot,
        enquiryStatus: 'Site Visit Scheduled',
        siteVisitStatus: 'Confirmed',
      );

      expect(hotLead.scoreTier, LeadScoreTier.hot);
      expect(hotLead.scoreTier.badgeLabel, '🔥 HOT LEAD');

      final calculatedScore = DealerLead.calculateScore(
        budgetCr: 1.95,
        targetPropertyPriceCr: 1.85,
        hasSiteVisit: true,
        hasVerificationViewed: true,
        inquiryCount: 4,
      );

      expect(calculatedScore, greaterThanOrEqualTo(85));
    });

    test('DealRoomService handles offers, counter-offers, and acceptance', () {
      final service = DealRoomService.instance;
      final room = DealRoom.sampleRoom();

      expect(room.stage, isNotNull);
      expect(room.offers.isNotEmpty, isTrue);

      // Submit a counter offer
      service.submitOffer(
        dealRoomId: room.id,
        senderId: 'usr_buyer_active',
        senderName: 'Rahul Singhania',
        senderRole: 'Buyer',
        amountCr: 1.76,
        note: 'Immediate token if modular kitchen is included.',
      );

      final updatedRoom = service.getRoomById(room.id);
      expect(updatedRoom, isNotNull);
      expect(updatedRoom!.offers.first.amountCr, 1.76);
      expect(updatedRoom.offers.first.status, OfferStatus.pending);

      // Accept the offer
      service.acceptOffer(
        dealRoomId: room.id,
        offerId: updatedRoom.offers.first.id,
        actorName: 'Aman Sharma',
        actorRole: 'Dealer',
      );

      final finalizedRoom = service.getRoomById(room.id);
      expect(finalizedRoom!.agreedPriceCr, 1.76);
      expect(finalizedRoom.stage, DealStage.agreement);
    });

    test('AiCopywriterService produces complete multi-channel marketing package', () async {
      final copy = await AiCopywriterService.instance.generateListingCopy(
        title: 'Godrej Palm Retreat',
        propertyType: 'Apartment',
        location: 'Sector 150',
        city: 'Noida',
        priceCr: 2.45,
        sqft: 2100,
        bhk: '3 BHK',
        furnishing: 'Semi-Furnished',
        possession: 'Ready to Move',
        amenities: ['Club House', 'Swimming Pool', 'Gym'],
        landmarks: 'Near Shaheed Bhagat Singh Park',
        dealerName: 'Aman Sharma',
        dealerPhone: '+91 98103 94068',
      );

      expect(copy.headline.isNotEmpty, isTrue);
      expect(copy.professionalDescription.contains('Godrej Palm Retreat') || copy.professionalDescription.contains('Sector 150'), isTrue);
      expect(copy.highlights.length, greaterThanOrEqualTo(4));
      expect(copy.whatsAppText.contains('NEW EXCLUSIVE LISTING'), isTrue);
      expect(copy.instagramCaption.contains('#PropZen'), isTrue);
    });

    test('AiNegotiationService estimates realistic negotiation range and spread', () {
      final insight = AiNegotiationService.instance.analyzeNegotiation(
        listedPriceCr: 1.95,
        buyerBudgetCr: 1.80,
        dealerOfferCr: 1.90,
      );

      expect(insight.estimatedMinRangeCr, lessThanOrEqualTo(insight.estimatedMaxRangeCr));
      expect(insight.priceDifferenceCr, closeTo(0.10, 0.01));
      expect(insight.spreadPercentage, greaterThan(0));
      expect(insight.disclaimer, contains('informational estimate'));
    });

    test('AiVisitSummary parses pros, cons, concerns from raw buyer observations', () {
      const rawNotes = 'The 3 BHK flat was spacious. Balcony had great morning sunlight. Parking was small. Road access was good.';

      final summary = AiVisitSummary.parseFromNotes(
        visitId: 'VISIT-01',
        propertyTitle: 'ATS Pious Orchards',
        rawNotes: rawNotes,
      );

      expect(summary.pros.any((p) => p.toLowerCase().contains('balcony') || p.toLowerCase().contains('sunlight')), isTrue);
      expect(summary.cons.any((c) => c.toLowerCase().contains('parking')), isTrue);
      expect(summary.followUpQuestions.isNotEmpty, isTrue);
    });
  });
}
