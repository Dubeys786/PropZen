import '../models/property.dart';

/// Buyer Interest Level after a site visit
enum BuyerInterestLevel {
  lovedIt, // ❤️ Loved it / Highly Interested
  interested, // 👍 Interested
  considering, // 🤔 Need more options / Considering
  wantMoreOptions, // 🔍 Want More Options
  notInterested, // ❌ Not Interested
}

extension BuyerInterestLevelExtension on BuyerInterestLevel {
  String get label {
    switch (this) {
      case BuyerInterestLevel.lovedIt:
        return '❤️ Loved it';
      case BuyerInterestLevel.interested:
        return '👍 Interested';
      case BuyerInterestLevel.considering:
        return '🤔 Need more options';
      case BuyerInterestLevel.wantMoreOptions:
        return '🔍 Want More Options';
      case BuyerInterestLevel.notInterested:
        return '❌ Not Interested';
    }
  }

  String get shortCode {
    switch (this) {
      case BuyerInterestLevel.lovedIt:
        return 'Highly Interested';
      case BuyerInterestLevel.interested:
        return 'Interested';
      case BuyerInterestLevel.considering:
        return 'Considering';
      case BuyerInterestLevel.wantMoreOptions:
        return 'Want More Options';
      case BuyerInterestLevel.notInterested:
        return 'Not Interested';
    }
  }

  static BuyerInterestLevel fromString(String val) {
    final lower = val.toLowerCase().trim();
    if (lower.contains('loved') || lower.contains('highly')) return BuyerInterestLevel.lovedIt;
    if (lower.contains('not') || lower.contains('reject')) return BuyerInterestLevel.notInterested;
    if (lower.contains('more') || lower.contains('option')) return BuyerInterestLevel.wantMoreOptions;
    if (lower.contains('considering') || lower.contains('need')) return BuyerInterestLevel.considering;
    return BuyerInterestLevel.interested;
  }
}

/// Structured AI Post-Visit Feedback Model
class PostVisitFeedback {
  final String id;
  final String visitId;
  final String propertyId;
  final String propertyTitle;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final BuyerInterestLevel interestLevel;
  final String rawNotes;
  final List<String> pros;
  final List<String> cons;
  final List<String> concerns;
  final List<String> dealBreakers;
  final List<String> followUpQuestions;
  final String recommendedNextStep;
  final double rating; // 1 to 5
  final DateTime createdAt;
  final DateTime updatedAt;

  PostVisitFeedback({
    required this.id,
    required this.visitId,
    required this.propertyId,
    required this.propertyTitle,
    required this.buyerId,
    this.buyerName = 'Verified Buyer',
    this.buyerPhone = '',
    required this.interestLevel,
    required this.rawNotes,
    required this.pros,
    required this.cons,
    required this.concerns,
    this.dealBreakers = const [],
    this.followUpQuestions = const [],
    required this.recommendedNextStep,
    this.rating = 4.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'visit_id': visitId,
        'property_id': propertyId,
        'property_title': propertyTitle,
        'buyer_id': buyerId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'interest_level': interestLevel.shortCode,
        'raw_notes': rawNotes,
        'pros': pros,
        'cons': cons,
        'concerns': concerns,
        'deal_breakers': dealBreakers,
        'follow_up_questions': followUpQuestions,
        'recommended_next_step': recommendedNextStep,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PostVisitFeedback.fromMap(Map<String, dynamic> map) => PostVisitFeedback(
        id: map['id']?.toString() ?? 'FB-${DateTime.now().millisecondsSinceEpoch}',
        visitId: map['visit_id']?.toString() ?? '',
        propertyId: map['property_id']?.toString() ?? '',
        propertyTitle: map['property_title']?.toString() ?? '',
        buyerId: map['buyer_id']?.toString() ?? 'usr_buyer',
        buyerName: map['buyer_name']?.toString() ?? 'Verified Buyer',
        buyerPhone: map['buyer_phone']?.toString() ?? '',
        interestLevel: BuyerInterestLevelExtension.fromString(map['interest_level']?.toString() ?? 'Interested'),
        rawNotes: map['raw_notes']?.toString() ?? '',
        pros: (map['pros'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        cons: (map['cons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        concerns: (map['concerns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        dealBreakers: (map['deal_breakers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        followUpQuestions: (map['follow_up_questions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        recommendedNextStep: map['recommended_next_step']?.toString() ?? 'Review matching options in PropZen.',
        rating: (map['rating'] as num?)?.toDouble() ?? 4.0,
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
        updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      );

  /// AI Natural Language Parser: Converts spoken/typed Hindi/Hinglish/English notes into structured intelligence
  static PostVisitFeedback parse({
    required String visitId,
    required String propertyId,
    required String propertyTitle,
    required String buyerId,
    String buyerName = 'Verified Buyer',
    String buyerPhone = '',
    required BuyerInterestLevel interestLevel,
    required String rawNotes,
  }) {
    final lower = rawNotes.toLowerCase();
    final List<String> pros = [];
    final List<String> cons = [];
    final List<String> concerns = [];
    final List<String> dealBreakers = [];
    final List<String> questions = [];

    // 1. Balcony, Sunlight & Ventilation
    if (lower.contains('balcony') || lower.contains('balkani') || lower.contains('balconi')) {
      if (lower.contains('achi') || lower.contains('achhi') || lower.contains('large') || lower.contains('big') || lower.contains('badi') || lower.contains('good') || lower.contains('pasand') || lower.contains('sundar')) {
        pros.add('Large balcony with spacious sit-out and clear ventilation.');
      } else if (lower.contains('chhoti') || lower.contains('small') || lower.contains('narrow')) {
        cons.add('Balcony dimensions are compact.');
      }
    }

    // 2. Flat / Layout / Construction Quality
    if (lower.contains('flat') || lower.contains('layout') || lower.contains('room') || lower.contains('living')) {
      if (lower.contains('acha') || lower.contains('accha') || lower.contains('badiya') || lower.contains('good') || lower.contains('nice') || lower.contains('spacious') || lower.contains('premium')) {
        pros.add('Well-designed apartment layout with optimal room proportions.');
      }
    }

    // 3. Location, Highway, Metro Connectivity
    if (lower.contains('location') || lower.contains('jagah') || lower.contains('sector') || lower.contains('road') || lower.contains('metro') || lower.contains('highway')) {
      if (lower.contains('achi') || lower.contains('achhi') || lower.contains('good') || lower.contains('prime') || lower.contains('best') || lower.contains('connectivity')) {
        pros.add('Prime micro-market location with strong expressway & metro accessibility.');
      } else if (lower.contains('dur') || lower.contains('far') || lower.contains('traffic')) {
        cons.add('Commute distance to central commercial hub.');
      }
    }

    // 4. Parking (Deal Breakers / Cons)
    if (lower.contains('parking')) {
      if (lower.contains('chhoti') || lower.contains('choti') || lower.contains('small') || lower.contains('tight') || lower.contains('kam') || lower.contains('issue') || lower.contains('problem') || lower.contains('dikkat')) {
        cons.add('Small basement parking bay dimensions for large vehicles.');
        concerns.add('Dedicated covered parking slot size and SUV clearance.');
        dealBreakers.add('Small parking space');
        questions.add('Is an additional covered stilt/basement parking slot available?');
      } else {
        pros.add('Dedicated reserved covered basement parking.');
      }
    }

    // 5. Pricing & Budget Concerns
    if (lower.contains('price') || lower.contains('daam') || lower.contains('rate') || lower.contains('budget') || lower.contains('cost') || lower.contains('mehnga') || lower.contains('high') || lower.contains('expensive')) {
      if (lower.contains('high') || lower.contains('mehnga') || lower.contains('thoda high') || lower.contains('zyada') || lower.contains('expensive') || lower.contains('costly')) {
        cons.add('Quoted asking price is at upper threshold of target budget.');
        concerns.add('Price negotiation headroom vs registered circle rates.');
        questions.add('What is the maximum dealer/builder negotiable spread on payment terms?');
      } else {
        pros.add('Attractive pricing within estimated fair market range.');
      }
    }

    // 6. Maintenance & Society Amenities
    if (lower.contains('club') || lower.contains('gym') || lower.contains('pool') || lower.contains('amenities') || lower.contains('society') || lower.contains('maintenance')) {
      if (lower.contains('maintenance') || lower.contains('charge')) {
        concerns.add('Recurring monthly society maintenance and sinking fund levy.');
        questions.add('What is the exact monthly maintenance rate per sq. ft.?');
      } else {
        pros.add('Active clubhouse with operational sports and fitness amenities.');
      }
    }

    // Fallbacks if notes are brief
    if (pros.isEmpty) {
      if (interestLevel == BuyerInterestLevel.lovedIt || interestLevel == BuyerInterestLevel.interested) {
        pros.add('Modern gated community with verified infrastructure and amenities.');
      }
    }
    if (cons.isEmpty && (interestLevel == BuyerInterestLevel.wantMoreOptions || interestLevel == BuyerInterestLevel.notInterested)) {
      cons.add('Unit specification does not fully align with buyer requirements.');
    }
    if (concerns.isEmpty && interestLevel == BuyerInterestLevel.considering) {
      concerns.add('Exploring comparative options across adjacent sectors.');
    }

    // Determine Recommended Next Step based on Interest Level & Feedback
    String nextStep;
    if (interestLevel == BuyerInterestLevel.lovedIt || interestLevel == BuyerInterestLevel.interested) {
      nextStep = 'Start Negotiation in PropZen Safe Deal Room to formalize an offer and review verified title documents.';
    } else if (interestLevel == BuyerInterestLevel.considering) {
      nextStep = 'Compare this property with 2 alternate listings that address specific feedback (${concerns.isNotEmpty ? concerns.first : "pricing & layout"}).';
    } else {
      nextStep = 'Find Better Properties using AI Property Re-Match with refined filters for ${dealBreakers.isNotEmpty ? dealBreakers.join(", ") : "spacious layout & pricing"}.';
    }

    return PostVisitFeedback(
      id: 'FB-${DateTime.now().millisecondsSinceEpoch}',
      visitId: visitId,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      interestLevel: interestLevel,
      rawNotes: rawNotes,
      pros: pros,
      cons: cons,
      concerns: concerns,
      dealBreakers: dealBreakers,
      followUpQuestions: questions,
      recommendedNextStep: nextStep,
      rating: interestLevel == BuyerInterestLevel.lovedIt ? 5.0 : (interestLevel == BuyerInterestLevel.interested ? 4.0 : (interestLevel == BuyerInterestLevel.considering ? 3.0 : 2.0)),
    );
  }
}

/// AI Property Re-Match Result with Explicit Reason
class PostVisitReMatch {
  final Property property;
  final int matchPercentage;
  final String matchGrade; // 'Exceptional' (90%+), 'High' (80-89%), 'Good' (70-79%)
  final String matchExplanation;
  final List<String> resolvedConcerns;
  final List<String> keyHighlights;

  const PostVisitReMatch({
    required this.property,
    required this.matchPercentage,
    required this.matchGrade,
    required this.matchExplanation,
    required this.resolvedConcerns,
    required this.keyHighlights,
  });
}
