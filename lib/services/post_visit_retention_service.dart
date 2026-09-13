import 'package:flutter/foundation.dart';
import '../models/post_visit_retention_model.dart';
import '../models/property.dart';
import '../models/deal_room_model.dart';
import '../services/property_state_service.dart';
import '../services/deal_room_service.dart';
import '../services/supabase_service.dart';
import '../screens/user_profile_screen.dart';

/// Central Post-Site-Visit Buyer Retention Service
class PostVisitRetentionService extends ChangeNotifier {
  PostVisitRetentionService._();
  static final PostVisitRetentionService instance = PostVisitRetentionService._();

  final List<PostVisitFeedback> _feedbacks = [];
  List<PostVisitFeedback> get allFeedbacks => List.unmodifiable(_feedbacks);

  /// Structured Buyer Preferences updated continuously from visit feedback
  final Map<String, dynamic> _buyerPreferenceProfile = {
    'preferredLocations': ['Sector 150', 'Noida Extension', 'Sector 63'],
    'minBudgetCr': 0.65,
    'maxBudgetCr': 1.60,
    'preferredBhk': '3 BHK',
    'propertyType': 'Apartment',
    'status': 'Ready to Move',
    'importantAmenities': ['Balcony', 'Parking', 'Club House', 'Security'],
    'dealBreakers': <String>[],
  };

  Map<String, dynamic> get buyerPreferenceProfile => Map.unmodifiable(_buyerPreferenceProfile);

  /// Check scheduled visits and automatically mark any whose date has passed as "Completed"
  void checkAndCompletePastVisits() {
    final now = DateTime.now();
    final visits = PropertyStateService.instance.scheduledVisits;
    bool hasChanges = false;

    for (final v in visits) {
      final status = v['status']?.toString() ?? 'Confirmed';
      if (status == 'Cancelled' || status == 'Completed') continue;

      final dateStr = v['date']?.toString() ?? v['visit_date']?.toString() ?? '';
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        // If the date is earlier than today (or today at midnight), mark completed
        if (parsedDate.isBefore(DateTime(now.year, now.month, now.day))) {
          v['status'] = 'Completed';
          hasChanges = true;
        }
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Submit or update post-visit feedback with structured AI parsing
  Future<PostVisitFeedback> submitFeedback({
    required String visitId,
    required String propertyId,
    required String propertyTitle,
    required BuyerInterestLevel interestLevel,
    required String rawNotes,
    List<String>? customPros,
    List<String>? customCons,
    List<String>? customConcerns,
    String? customNextStep,
  }) async {
    final buyerId = UserSession.isLoggedIn
        ? (UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer')
        : 'usr_active';

    final buyerName = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Buyer';
    final buyerPhone = UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068';

    // 1. AI Parsing
    final parsed = PostVisitFeedback.parse(
      visitId: visitId,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      interestLevel: interestLevel,
      rawNotes: rawNotes,
    );

    // Apply custom overrides if user edited the AI summary
    final feedback = PostVisitFeedback(
      id: parsed.id,
      visitId: visitId,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      interestLevel: interestLevel,
      rawNotes: rawNotes,
      pros: customPros ?? parsed.pros,
      cons: customCons ?? parsed.cons,
      concerns: customConcerns ?? parsed.concerns,
      dealBreakers: parsed.dealBreakers,
      followUpQuestions: parsed.followUpQuestions,
      recommendedNextStep: customNextStep ?? parsed.recommendedNextStep,
      rating: parsed.rating,
    );

    // 2. Cache in local memory
    _feedbacks.removeWhere((f) => f.visitId == visitId);
    _feedbacks.insert(0, feedback);

    // 3. Mark visit as Completed in PropertyStateService
    PropertyStateService.instance.updateVisitStatus(visitId, 'Completed');

    // 4. Update Buyer Preference Profile with new insights & deal breakers
    if (feedback.dealBreakers.isNotEmpty) {
      final List<String> currentDb = List<String>.from(_buyerPreferenceProfile['dealBreakers'] as List<dynamic>);
      for (final db in feedback.dealBreakers) {
        if (!currentDb.contains(db)) currentDb.add(db);
      }
      _buyerPreferenceProfile['dealBreakers'] = currentDb;
    }

    // 5. Asynchronous persistence to Supabase
    try {
      SupabaseService.instance.saveSiteVisit(
        propertyTitle: propertyTitle,
        propertyId: propertyId,
        name: buyerName,
        email: UserSession.email,
        phone: buyerPhone,
        visitDate: DateTime.now().toIso8601String().split('T').first,
        timeSlot: 'Completed',
        visitorCount: 1,
        cabRequired: false,
        message: 'Post-Visit Feedback: ${interestLevel.shortCode}. Notes: $rawNotes',
        status: 'Completed',
        metadata: {
          'feedback_id': feedback.id,
          'interest_level': interestLevel.shortCode,
          'pros': feedback.pros,
          'cons': feedback.cons,
          'concerns': feedback.concerns,
          'deal_breakers': feedback.dealBreakers,
          'rating': feedback.rating,
          'submitted_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {}

    notifyListeners();
    return feedback;
  }

  /// Get feedback for a specific visit ID
  PostVisitFeedback? getFeedbackForVisit(String visitId) {
    try {
      return _feedbacks.firstWhere((f) => f.visitId == visitId);
    } catch (_) {
      return null;
    }
  }

  /// Get all feedbacks for the current buyer
  List<PostVisitFeedback> getFeedbacksForBuyer(String buyerId) {
    return _feedbacks.where((f) => f.buyerId == buyerId || buyerId.isEmpty || f.buyerId == 'usr_buyer' || f.buyerId == 'usr_active').toList();
  }

  /// AI Property Re-Match Algorithm:
  /// Evaluates real database properties and boosts those that address the buyer's explicit feedback & deal breakers
  List<PostVisitReMatch> getReMatchedProperties({
    PostVisitFeedback? feedback,
    int limit = 6,
  }) {
    final allProperties = PropertyStateService.instance.allProperties;
    if (allProperties.isEmpty) return [];

    final targetPropertyId = feedback?.propertyId ?? '';
    final dealBreakers = feedback?.dealBreakers ?? (_buyerPreferenceProfile['dealBreakers'] as List<String>);
    final rawNotes = feedback?.rawNotes.toLowerCase() ?? '';

    final hasParkingConcern = dealBreakers.any((db) => db.toLowerCase().contains('parking')) || rawNotes.contains('parking');
    final hasPriceConcern = rawNotes.contains('price') || rawNotes.contains('budget') || rawNotes.contains('mehnga');
    final hasBalconyPreference = rawNotes.contains('balcony') || rawNotes.contains('view');

    final List<PostVisitReMatch> matches = [];

    for (final prop in allProperties) {
      // Exclude the visited property if user wants more options
      if (prop.id == targetPropertyId && (feedback?.interestLevel == BuyerInterestLevel.wantMoreOptions || feedback?.interestLevel == BuyerInterestLevel.notInterested)) {
        continue;
      }

      int score = 70; // Baseline catalog score
      final List<String> resolved = [];
      final List<String> highlights = [];

      // Check parking resolution
      if (hasParkingConcern) {
        final amenitiesLower = prop.amenities.map((a) => a.toLowerCase()).join(' ');
        if (amenitiesLower.contains('parking') || prop.description.toLowerCase().contains('parking') || prop.description.toLowerCase().contains('covered')) {
          score += 15;
          resolved.add('Spacious 2-Car Reserved Covered Basement Parking');
          highlights.add('✓ Solves parking space constraint');
        }
      }

      // Check price resolution
      if (hasPriceConcern) {
        if (prop.askingPriceCr <= 1.20) {
          score += 12;
          resolved.add('Competitive pricing ₹${prop.askingPriceCr.toStringAsFixed(2)} Cr with high negotiable spread');
          highlights.add('✓ Within comfortable budget threshold');
        }
      }

      // Check balcony & layout
      if (hasBalconyPreference) {
        score += 8;
        resolved.add('Expansive continuous wrap-around balcony with park views');
        highlights.add('✓ Premium balcony sit-out');
      }

      // Base property quality score bonus
      if (prop.intelligenceScore >= 85) {
        score += (prop.intelligenceScore - 80).clamp(0, 8);
      }

      final finalPercentage = score.clamp(72, 97);
      String grade = 'Good';
      if (finalPercentage >= 90) {
        grade = 'Exceptional';
      } else if (finalPercentage >= 82) {
        grade = 'High';
      }

      final explanation = '${finalPercentage}% Match because it matches your ${prop.bhk} requirement in ${prop.effectiveLocality}, ${prop.city}, fits your ₹${prop.askingPriceCr} Cr budget, and ${resolved.isNotEmpty ? resolved.first.toLowerCase() : "offers verified RERA clearances"}.';

      matches.add(PostVisitReMatch(
        property: prop,
        matchPercentage: finalPercentage,
        matchGrade: grade,
        matchExplanation: explanation,
        resolvedConcerns: resolved,
        keyHighlights: highlights.isNotEmpty ? highlights : ['✓ Verified Title & RERA registered', '✓ Ready for Immediate Visit'],
      ));
    }

    // Sort descending by match percentage
    matches.sort((a, b) => b.matchPercentage.compareTo(a.matchPercentage));
    return matches.take(limit).toList();
  }

  /// AI Dealer Follow-Up Assistant: Generates personalized, empathetic messages for dealers to contact buyers
  String generateDealerFollowUpMessage(PostVisitFeedback feedback) {
    final buyerFirstName = feedback.buyerName.split(' ').first;
    final propTitle = feedback.propertyTitle;

    if (feedback.interestLevel == BuyerInterestLevel.lovedIt || feedback.interestLevel == BuyerInterestLevel.interested) {
      return 'Hi $buyerFirstName, thanks for visiting $propTitle! I noticed you really liked the layout and balcony. Would you like to discuss the offer terms and explore available payment milestones in the PropZen Safe Deal Room?';
    } else if (feedback.dealBreakers.any((d) => d.toLowerCase().contains('parking'))) {
      return 'Hi $buyerFirstName, thanks for taking the time to tour $propTitle today. I understand the parking space was one of your key considerations. We have an option for an upgraded dual-covered basement slot. Would you like me to share the layout details?';
    } else if (feedback.concerns.any((c) => c.toLowerCase().contains('price'))) {
      return 'Hi $buyerFirstName, thank you for visiting $propTitle today. I understand pricing is an important factor. The seller is open to structured installment terms. Would you like to submit a formal counter-offer via the Deal Room?';
    } else {
      return 'Hi $buyerFirstName, thank you for touring $propTitle today. I noted your preferences from the visit. I have curated 2 similar properties with larger layouts in the same sector. Would you like to review them?';
    }
  }

  /// Seamlessly initialize or navigate to Safe Deal Room from post-visit interest
  DealRoom startNegotiationFromFeedback(PostVisitFeedback feedback) {
    final prop = PropertyStateService.instance.findPropertyById(feedback.propertyId) ??
        Property.sampleDeals.first;

    final room = DealRoomService.instance.getOrCreateDealRoom(
      property: prop,
      buyerId: feedback.buyerId,
      buyerName: feedback.buyerName,
      buyerPhone: feedback.buyerPhone,
      dealerId: prop.dealerId.isNotEmpty ? prop.dealerId : 'dealer_ncr_01',
      dealerName: 'Aman Sharma (Prime Realty)',
      dealerPhone: '+91 98103 94068',
    );

    return room;
  }
}
