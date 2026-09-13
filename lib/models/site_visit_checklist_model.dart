class ChecklistItem {
  final String id;
  final String category; // 'PROPERTY' or 'DOCUMENTS'
  final String title;
  final String subtitle;
  bool isCompleted;
  String notes;
  int rating; // 1 to 5 stars
  final List<String> photoUrls;
  final List<String> concerns;

  ChecklistItem({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.notes = '',
    this.rating = 0,
    this.photoUrls = const [],
    this.concerns = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'title': title,
        'subtitle': subtitle,
        'isCompleted': isCompleted,
        'notes': notes,
        'rating': rating,
        'photoUrls': photoUrls,
        'concerns': concerns,
      };

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
        id: map['id']?.toString() ?? '',
        category: map['category']?.toString() ?? 'PROPERTY',
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        notes: map['notes']?.toString() ?? '',
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        photoUrls: (map['photoUrls'] as List<dynamic>?)?.map((p) => p.toString()).toList() ?? [],
        concerns: (map['concerns'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
      );
}

class AiVisitSummary {
  final String id;
  final String visitId;
  final String propertyTitle;
  final String rawBuyerNotes;
  final List<String> pros;
  final List<String> cons;
  final List<String> concerns;
  final List<String> followUpQuestions;
  final double overallRating; // e.g. 4.5
  final DateTime createdAt;

  AiVisitSummary({
    required this.id,
    required this.visitId,
    required this.propertyTitle,
    required this.rawBuyerNotes,
    required this.pros,
    required this.cons,
    required this.concerns,
    required this.followUpQuestions,
    this.overallRating = 4.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'visit_id': visitId,
        'property_title': propertyTitle,
        'raw_buyer_notes': rawBuyerNotes,
        'pros': pros,
        'cons': cons,
        'concerns': concerns,
        'follow_up_questions': followUpQuestions,
        'overall_rating': overallRating,
        'created_at': createdAt.toIso8601String(),
      };

  factory AiVisitSummary.fromMap(Map<String, dynamic> map) => AiVisitSummary(
        id: map['id']?.toString() ?? 'SUM-${DateTime.now().millisecondsSinceEpoch}',
        visitId: map['visit_id']?.toString() ?? '',
        propertyTitle: map['property_title']?.toString() ?? '',
        rawBuyerNotes: map['raw_buyer_notes']?.toString() ?? '',
        pros: (map['pros'] as List<dynamic>?)?.map((p) => p.toString()).toList() ?? [],
        cons: (map['cons'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
        concerns: (map['concerns'] as List<dynamic>?)?.map((c) => c.toString()).toList() ?? [],
        followUpQuestions: (map['follow_up_questions'] as List<dynamic>?)?.map((q) => q.toString()).toList() ?? [],
        overallRating: (map['overall_rating'] as num?)?.toDouble() ?? 4.0,
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      );

  /// AI parser that converts natural text / transcript into structured summary
  static AiVisitSummary parseFromNotes({
    required String visitId,
    required String propertyTitle,
    required String rawNotes,
  }) {
    final lower = rawNotes.toLowerCase();

    final List<String> pros = [];
    final List<String> cons = [];
    final List<String> concerns = [];
    final List<String> questions = [];

    // Heuristic entity & sentiment extraction
    if (lower.contains('balcony') || lower.contains('view') || lower.contains('ventilation') || lower.contains('sunlight')) {
      pros.add('Spacious balcony with abundant natural sunlight & ventilation.');
    }
    if (lower.contains('road') || lower.contains('metro') || lower.contains('highway') || lower.contains('access') || lower.contains('location')) {
      pros.add('Excellent road connectivity and direct highway/sector access.');
    }
    if (lower.contains('room') || lower.contains('layout') || lower.contains('living') || lower.contains('good') || lower.contains('nice')) {
      pros.add('Well-designed layout with premium living area dimensions.');
    }

    if (lower.contains('small parking') || lower.contains('tight parking') || lower.contains('parking is small') || lower.contains('parking was small') || lower.contains('parking was tight') || lower.contains('parking issue')) {
      cons.add('Basement parking slot dimensions appear tight for full-size SUVs.');
      concerns.add('Designated parking capacity and guest parking allocation.');
      questions.add('Is an additional covered parking space available for purchase or lease?');
    } else if (lower.contains('parking')) {
      pros.add('Covered basement parking slot assigned.');
    }

    if (lower.contains('water') || lower.contains('pressure') || lower.contains('leakage') || lower.contains('damp')) {
      cons.add('Need official certificate for 24/7 treated water pressure.');
      concerns.add('Plumbing and seepage guarantee on top floors.');
      questions.add('What is the water treatment and backup supply setup during peak summer?');
    }

    if (lower.contains('maintenance') || lower.contains('charges') || lower.contains('fee')) {
      questions.add('What are the recurring monthly maintenance charges and club fees?');
    } else {
      questions.add('What is the current monthly society maintenance fee (per sq. ft.)?');
    }

    if (lower.contains('possession') || lower.contains('registry') || lower.contains('handover')) {
      questions.add('What is the exact estimated registry and key handover date?');
    }

    if (pros.isEmpty) {
      pros.add('Verified builder credentials and modern gated community features.');
      pros.add('Clubhouse with active gymnasium and swimming pool.');
    }
    if (cons.isEmpty && lower.isNotEmpty) {
      cons.add('Interior finishing touches still pending in secondary bedroom.');
    }
    if (concerns.isEmpty) {
      concerns.add('Final timeline for club handover and occupancy certificate.');
    }

    return AiVisitSummary(
      id: 'SUM-${DateTime.now().millisecondsSinceEpoch}',
      visitId: visitId,
      propertyTitle: propertyTitle,
      rawBuyerNotes: rawNotes,
      pros: pros,
      cons: cons,
      concerns: concerns,
      followUpQuestions: questions,
      overallRating: 4.2,
    );
  }
}

class SiteVisitChecklist {
  final String id;
  final String visitId;
  final String propertyId;
  final String propertyTitle;
  final String buyerId;
  final List<ChecklistItem> items;
  final String? generalNotes;
  final double overallRating;
  final DateTime createdAt;
  final DateTime updatedAt;

  SiteVisitChecklist({
    required this.id,
    required this.visitId,
    required this.propertyId,
    required this.propertyTitle,
    required this.buyerId,
    required this.items,
    this.generalNotes,
    this.overallRating = 4.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get completedCount => items.where((i) => i.isCompleted).length;
  double get completionPercentage => items.isNotEmpty ? (completedCount / items.length) : 0.0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'visit_id': visitId,
        'property_id': propertyId,
        'property_title': propertyTitle,
        'buyer_id': buyerId,
        'items': items.map((i) => i.toMap()).toList(),
        'general_notes': generalNotes,
        'overall_rating': overallRating,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SiteVisitChecklist.fromMap(Map<String, dynamic> map) => SiteVisitChecklist(
        id: map['id']?.toString() ?? 'CHK-${DateTime.now().millisecondsSinceEpoch}',
        visitId: map['visit_id']?.toString() ?? '',
        propertyId: map['property_id']?.toString() ?? '',
        propertyTitle: map['property_title']?.toString() ?? '',
        buyerId: map['buyer_id']?.toString() ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((i) => ChecklistItem.fromMap(Map<String, dynamic>.from(i as Map)))
                .toList() ??
            defaultItems(),
        generalNotes: map['general_notes']?.toString(),
        overallRating: (map['overall_rating'] as num?)?.toDouble() ?? 4.0,
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
        updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      );

  static List<ChecklistItem> defaultItems() => [
        // Property Category
        ChecklistItem(id: 'p_water', category: 'PROPERTY', title: 'Water Supply & Pressure', subtitle: 'Check RO / municipal supply and bathroom pressure'),
        ChecklistItem(id: 'p_elec', category: 'PROPERTY', title: 'Electricity & 100% Power Backup', subtitle: 'Inspect DG backup switchover and main electrical panel'),
        ChecklistItem(id: 'p_park', category: 'PROPERTY', title: 'Car Parking Space Allocation', subtitle: 'Verify basement slot number and maneuverability'),
        ChecklistItem(id: 'p_qual', category: 'PROPERTY', title: 'Construction & Wall Quality', subtitle: 'Inspect plaster, tile alignment, and paint finishing'),
        ChecklistItem(id: 'p_sun', category: 'PROPERTY', title: 'Sunlight & Orientation', subtitle: 'Verify east/north facing sunlight in master bedroom'),
        ChecklistItem(id: 'p_vent', category: 'PROPERTY', title: 'Cross-Ventilation & Airflow', subtitle: 'Check window openings and balcony wind direction'),
        ChecklistItem(id: 'p_leak', category: 'PROPERTY', title: 'Dampness & Seepage Inspection', subtitle: 'Inspect ceilings, external walls, and pipe joints'),
        ChecklistItem(id: 'p_road', category: 'PROPERTY', title: 'Road Access & Approach Width', subtitle: 'Verify 24m/45m wide sector road and entrance gates'),
        ChecklistItem(id: 'p_maint', category: 'PROPERTY', title: 'Society Maintenance & Cleanliness', subtitle: 'Evaluate lifts, lobbies, corridors, and club facilities'),
        ChecklistItem(id: 'p_sec', category: 'PROPERTY', title: 'Gated Security & CCTV Coverage', subtitle: 'Check boom barriers, guard deployment, and visitor entry log'),

        // Documents Category
        ChecklistItem(id: 'd_own', category: 'DOCUMENTS', title: 'Sub-Registrar Title Deed / Allotment Letter', subtitle: 'Verify chain of title and clean unencumbered ownership'),
        ChecklistItem(id: 'd_appr', category: 'DOCUMENTS', title: 'Sanctioned Building Plan & RERA Registration', subtitle: 'Cross-check sanctioned floors against actual construction'),
        ChecklistItem(id: 'd_tax', category: 'DOCUMENTS', title: 'Municipal Property Tax & Authority Dues Paid', subtitle: 'Inspect latest zero-dues receipt from local authority'),
        ChecklistItem(id: 'd_other', category: 'DOCUMENTS', title: 'Fire NOC & Occupancy Certificate (OC)', subtitle: 'Verify OC sanction and fire department clearance certificate'),
      ];
}
