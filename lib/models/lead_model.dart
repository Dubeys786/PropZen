enum LeadScoreTier {
  hot,
  warm,
  earlyInquiry,
}

extension LeadScoreTierExt on LeadScoreTier {
  String get displayName {
    switch (this) {
      case LeadScoreTier.hot:
        return 'HOT LEAD';
      case LeadScoreTier.warm:
        return 'WARM LEAD';
      case LeadScoreTier.earlyInquiry:
        return 'EARLY INQUIRY';
    }
  }

  String get badgeLabel {
    switch (this) {
      case LeadScoreTier.hot:
        return '🔥 HOT LEAD';
      case LeadScoreTier.warm:
        return '⚡ WARM LEAD';
      case LeadScoreTier.earlyInquiry:
        return '🌱 EARLY INQUIRY';
    }
  }
}

class LeadScoreFactor {
  final String title;
  final bool isPositive;
  final int impactPercentage;
  final String description;

  const LeadScoreFactor({
    required this.title,
    required this.isPositive,
    required this.impactPercentage,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'isPositive': isPositive,
        'impactPercentage': impactPercentage,
        'description': description,
      };

  factory LeadScoreFactor.fromMap(Map<String, dynamic> map) => LeadScoreFactor(
        title: map['title'] as String? ?? '',
        isPositive: map['isPositive'] as bool? ?? true,
        impactPercentage: (map['impactPercentage'] as num?)?.toInt() ?? 0,
        description: map['description'] as String? ?? '',
      );
}

class DealerLead {
  final String id;
  final String dealerId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String requirement;
  final double budgetCr;
  final String preferredLocation;
  final String propertyId;
  final String propertyTitle;
  final String lastActivity;
  final DateTime lastActivityTime;
  final String enquiryStatus; // 'New', 'Contacted', 'Site Visit Scheduled', 'Negotiation', 'Closed'
  final String siteVisitStatus; // 'None', 'Requested', 'Confirmed', 'Completed', 'Cancelled'
  final int leadScore; // 0 - 100
  final LeadScoreTier scoreTier;
  final List<LeadScoreFactor> scoreFactors;
  final List<String> notes;
  final String? lastFollowUpText;
  final DateTime? lastFollowUpDate;
  final DateTime createdAt;

  DealerLead({
    required this.id,
    this.dealerId = 'dealer_ncr_01',
    String? buyerId,
    required this.buyerName,
    this.buyerPhone = '',
    this.buyerEmail = '',
    this.requirement = '3 BHK Luxury Apartment',
    required this.budgetCr,
    this.preferredLocation = 'Sector 150, Noida',
    required this.propertyId,
    required this.propertyTitle,
    this.lastActivity = 'Active recently on platform',
    DateTime? lastActivityTime,
    this.enquiryStatus = 'New',
    this.siteVisitStatus = 'None',
    required this.leadScore,
    required this.scoreTier,
    this.scoreFactors = const [],
    this.notes = const [],
    this.lastFollowUpText,
    this.lastFollowUpDate,
    DateTime? createdAt,
  })  : buyerId = buyerId ?? 'usr_${id.hashCode.abs()}',
        lastActivityTime = lastActivityTime ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  static int calculateScore({
    required double budgetCr,
    required double targetPropertyPriceCr,
    bool hasSiteVisit = false,
    bool hasVerificationViewed = false,
    int inquiryCount = 1,
  }) {
    int score = 40;
    if (budgetCr >= targetPropertyPriceCr * 0.9) score += 25;
    if (hasSiteVisit) score += 20;
    if (hasVerificationViewed) score += 10;
    if (inquiryCount > 2) score += 5;
    return score.clamp(10, 99);
  }

  DealerLead copyWith({
    String? dealerId,
    String? enquiryStatus,
    String? siteVisitStatus,
    int? leadScore,
    LeadScoreTier? scoreTier,
    List<LeadScoreFactor>? scoreFactors,
    List<String>? notes,
    String? lastFollowUpText,
    DateTime? lastFollowUpDate,
    String? lastActivity,
    DateTime? lastActivityTime,
  }) {
    return DealerLead(
      id: id,
      dealerId: dealerId ?? this.dealerId,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      requirement: requirement,
      budgetCr: budgetCr,
      preferredLocation: preferredLocation,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      lastActivity: lastActivity ?? this.lastActivity,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      enquiryStatus: enquiryStatus ?? this.enquiryStatus,
      siteVisitStatus: siteVisitStatus ?? this.siteVisitStatus,
      leadScore: leadScore ?? this.leadScore,
      scoreTier: scoreTier ?? this.scoreTier,
      scoreFactors: scoreFactors ?? this.scoreFactors,
      notes: notes ?? this.notes,
      lastFollowUpText: lastFollowUpText ?? this.lastFollowUpText,
      lastFollowUpDate: lastFollowUpDate ?? this.lastFollowUpDate,
      createdAt: createdAt,
    );
  }

  // 7-Stage Pipeline Convenience Getters
  bool get isNew => enquiryStatus.toLowerCase() == 'new';
  bool get isContacted => enquiryStatus.toLowerCase() == 'contacted';
  bool get isQualified => enquiryStatus.toLowerCase() == 'qualified';
  bool get isSiteVisit => enquiryStatus.toLowerCase() == 'site visit' || enquiryStatus.toLowerCase() == 'site_visit' || enquiryStatus.toLowerCase() == 'site visit scheduled';
  bool get isNegotiation => enquiryStatus.toLowerCase() == 'negotiation';
  bool get isConverted => enquiryStatus.toLowerCase() == 'converted' || enquiryStatus.toLowerCase() == 'closed';
  bool get isLost => enquiryStatus.toLowerCase() == 'lost';

  Map<String, dynamic> toMap() => {
        'id': id,
        'dealer_id': dealerId,
        'buyer_id': buyerId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'buyer_email': buyerEmail,
        'requirement': requirement,
        'budget_cr': budgetCr,
        'preferred_location': preferredLocation,
        'property_id': propertyId,
        'property_title': propertyTitle,
        'last_activity': lastActivity,
        'last_activity_time': lastActivityTime.toIso8601String(),
        'enquiry_status': enquiryStatus,
        'status': enquiryStatus,
        'site_visit_status': siteVisitStatus,
        'lead_score': leadScore,
        'score_tier': scoreTier.name,
        'score_factors': scoreFactors.map((f) => f.toMap()).toList(),
        'notes': notes,
        'last_follow_up_text': lastFollowUpText,
        'last_follow_up_date': lastFollowUpDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory DealerLead.fromMap(Map<String, dynamic> map) {
    final score = (map['lead_score'] as num?)?.toInt() ?? 65;
    LeadScoreTier tier = LeadScoreTier.warm;
    if (score >= 80) {
      tier = LeadScoreTier.hot;
    } else if (score < 50) {
      tier = LeadScoreTier.earlyInquiry;
    }

    return DealerLead(
      id: map['id']?.toString() ?? 'LEAD-${DateTime.now().millisecondsSinceEpoch}',
      dealerId: map['dealer_id']?.toString() ?? map['dealerId']?.toString() ?? 'dealer_ncr_01',
      buyerId: map['buyer_id']?.toString() ?? 'usr_buyer',
      buyerName: map['buyer_name']?.toString() ?? map['customer']?.toString() ?? 'Prospective Buyer',
      buyerPhone: map['buyer_phone']?.toString() ?? map['phone']?.toString() ?? '',
      buyerEmail: map['buyer_email']?.toString() ?? map['email']?.toString() ?? '',
      requirement: map['requirement']?.toString() ?? '3 BHK High-Rise Apartment',
      budgetCr: (map['budget_cr'] as num?)?.toDouble() ?? 1.85,
      preferredLocation: map['preferred_location']?.toString() ?? 'Sector 150, Noida',
      propertyId: map['property_id']?.toString() ?? map['propertyId']?.toString() ?? 'PROP-ATS-01',
      propertyTitle: map['property_title']?.toString() ?? map['propertyTitle']?.toString() ?? 'ATS HomeKraft Pious Orchards',
      lastActivity: map['last_activity']?.toString() ?? 'Site Visit Booked for this weekend',
      lastActivityTime: map['last_activity_time'] != null ? DateTime.tryParse(map['last_activity_time'].toString()) : null,
      enquiryStatus: map['enquiry_status']?.toString() ?? map['status']?.toString() ?? 'Site Visit Scheduled',
      siteVisitStatus: map['site_visit_status']?.toString() ?? 'Confirmed',
      leadScore: score,
      scoreTier: tier,
      scoreFactors: (map['score_factors'] as List<dynamic>?)
              ?.map((f) => LeadScoreFactor.fromMap(Map<String, dynamic>.from(f as Map)))
              .toList() ??
          [
            const LeadScoreFactor(title: 'Budget Match', isPositive: true, impactPercentage: 35, description: 'Budget of ₹1.85 Cr is within 3% of listing price.'),
            const LeadScoreFactor(title: 'Site Visit Confirmed', isPositive: true, impactPercentage: 30, description: 'User scheduled a private site visit with cab pickup.'),
            const LeadScoreFactor(title: 'Recent High Intent', isPositive: true, impactPercentage: 20, description: 'Viewed property brochure and pricing matrix twice in 24h.'),
          ],
      notes: (map['notes'] as List<dynamic>?)?.map((n) => n.toString()).toList() ?? [],
      lastFollowUpText: map['last_follow_up_text']?.toString(),
      lastFollowUpDate: map['last_follow_up_date'] != null ? DateTime.tryParse(map['last_follow_up_date'].toString()) : null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
    );
  }

  /// Sample production leads for dealer panel demonstration
  static List<DealerLead> get initialSampleLeads => [
        DealerLead(
          id: 'LEAD-101',
          buyerId: 'usr_rahul_981',
          buyerName: 'Rahul Singhania',
          buyerPhone: '+91 98103 44521',
          buyerEmail: 'rahul.singhania@techcorp.com',
          requirement: '3 BHK Luxury Apartment in Sector 150',
          budgetCr: 1.85,
          preferredLocation: 'Sector 150, Noida',
          propertyId: 'PROP-ATS-01',
          propertyTitle: 'ATS HomeKraft Pious Orchards',
          lastActivity: 'Booked Site Visit for Saturday 11:00 AM (Cab requested)',
          lastActivityTime: DateTime.now().subtract(const Duration(hours: 2)),
          enquiryStatus: 'Site Visit Scheduled',
          siteVisitStatus: 'Confirmed',
          leadScore: 92,
          scoreTier: LeadScoreTier.hot,
          scoreFactors: [
            const LeadScoreFactor(title: 'Budget Match', isPositive: true, impactPercentage: 35, description: '₹1.85 Cr matches listed unit value exactly.'),
            const LeadScoreFactor(title: 'Site Visit Booked', isPositive: true, impactPercentage: 35, description: 'Site visit booked with cab transfer for Saturday 11 AM.'),
            const LeadScoreFactor(title: 'High Response Rate', isPositive: true, impactPercentage: 22, description: 'Replied to verification report within 30 minutes.'),
          ],
          notes: ['Wants early possession in 2026', 'Corner unit preferred'],
        ),
        DealerLead(
          id: 'LEAD-102',
          buyerId: 'usr_priya_982',
          buyerName: 'Dr. Priya Mehta',
          buyerPhone: '+91 98711 88234',
          buyerEmail: 'dr.priya.mehta@maxhealth.in',
          requirement: '4 BHK Green View Penthouse / Large Flat',
          budgetCr: 2.75,
          preferredLocation: 'Noida Expressway / Sector 128',
          propertyId: 'PROP-GODREJ-02',
          propertyTitle: 'Godrej Palm Retreat',
          lastActivity: 'Submitted Price Negotiation Offer: ₹2.65 Cr',
          lastActivityTime: DateTime.now().subtract(const Duration(hours: 5)),
          enquiryStatus: 'Negotiation',
          siteVisitStatus: 'Completed',
          leadScore: 88,
          scoreTier: LeadScoreTier.hot,
          scoreFactors: [
            const LeadScoreFactor(title: 'Offer Submitted', isPositive: true, impactPercentage: 40, description: 'Submitted formal offer of ₹2.65 Cr in Deal Room.'),
            const LeadScoreFactor(title: 'Completed Visit', isPositive: true, impactPercentage: 30, description: 'Rated site visit 4.5/5 stars with completed checklist.'),
            const LeadScoreFactor(title: 'Loan Pre-Approved', isPositive: true, impactPercentage: 18, description: 'HDFC Bank instant pre-approval verified.'),
          ],
          notes: ['Negotiating final registry date in Sept'],
        ),
        DealerLead(
          id: 'LEAD-103',
          buyerId: 'usr_amit_983',
          buyerName: 'Amit Verma',
          buyerPhone: '+91 98112 33499',
          buyerEmail: 'amit.verma@fintech.io',
          requirement: '2 BHK / 3 BHK Compact Investment Unit',
          budgetCr: 1.10,
          preferredLocation: 'Greater Noida West / TechZone 4',
          propertyId: 'PROP-GAUR-03',
          propertyTitle: 'Gaur City 2 - 14th Avenue',
          lastActivity: 'Enquiry submitted for floor plan & payment schedule',
          lastActivityTime: DateTime.now().subtract(const Duration(days: 1)),
          enquiryStatus: 'Contacted',
          siteVisitStatus: 'Requested',
          leadScore: 68,
          scoreTier: LeadScoreTier.warm,
          scoreFactors: [
            const LeadScoreFactor(title: 'Budget Alignment', isPositive: true, impactPercentage: 30, description: 'Budget of ₹1.10 Cr aligns with 2 BHK + Study.'),
            const LeadScoreFactor(title: 'Brochure Download', isPositive: true, impactPercentage: 20, description: 'Downloaded AI Property Verification Report.'),
            const LeadScoreFactor(title: 'Follow-up Needed', isPositive: false, impactPercentage: -10, description: 'Has not confirmed site visit slot yet.'),
          ],
        ),
        DealerLead(
          id: 'LEAD-104',
          buyerId: 'usr_vikram_984',
          buyerName: 'Vikram Joshi',
          buyerPhone: '+91 99991 00213',
          buyerEmail: 'v.joshi@consulting.com',
          requirement: 'Looking for upcoming commercial / residential deals',
          budgetCr: 3.50,
          preferredLocation: 'Dwarka Expressway / Gurugram',
          propertyId: 'PROP-ATS-01',
          propertyTitle: 'ATS HomeKraft Pious Orchards',
          lastActivity: 'First-time search query on Dwarka Expressway',
          lastActivityTime: DateTime.now().subtract(const Duration(days: 3)),
          enquiryStatus: 'New',
          siteVisitStatus: 'None',
          leadScore: 35,
          scoreTier: LeadScoreTier.earlyInquiry,
          scoreFactors: [
            const LeadScoreFactor(title: 'Early Stage Inquiry', isPositive: true, impactPercentage: 20, description: 'Exploring multiple micro-markets.'),
            const LeadScoreFactor(title: 'No Direct Message', isPositive: false, impactPercentage: -15, description: 'Has not yet replied to initial welcome greeting.'),
          ],
        ),
      ];
}
