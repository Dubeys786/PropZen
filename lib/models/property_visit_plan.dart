class PlannedVisitStop {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertySector;
  final String propertyImage;
  final double askingPriceCr;
  final String timeSlot; // e.g. '10:00 AM'
  final int durationMinutes; // e.g. 45
  final int visitorCount;
  final bool cabRequired;
  final String notes;
  final String status; // 'Scheduled', 'In Progress', 'Completed', 'Skipped'

  PlannedVisitStop({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertySector,
    required this.propertyImage,
    required this.askingPriceCr,
    required this.timeSlot,
    this.durationMinutes = 45,
    this.visitorCount = 2,
    this.cabRequired = false,
    this.notes = '',
    this.status = 'Scheduled',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'property_id': propertyId,
        'property_title': propertyTitle,
        'property_sector': propertySector,
        'property_image': propertyImage,
        'asking_price_cr': askingPriceCr,
        'time_slot': timeSlot,
        'duration_minutes': durationMinutes,
        'visitor_count': visitorCount,
        'cab_required': cabRequired,
        'notes': notes,
        'status': status,
      };

  factory PlannedVisitStop.fromMap(Map<String, dynamic> map) => PlannedVisitStop(
        id: map['id']?.toString() ?? '',
        propertyId: map['property_id']?.toString() ?? '',
        propertyTitle: map['property_title']?.toString() ?? '',
        propertySector: map['property_sector']?.toString() ?? '',
        propertyImage: map['property_image']?.toString() ?? '',
        askingPriceCr: (map['asking_price_cr'] as num?)?.toDouble() ?? 1.5,
        timeSlot: map['time_slot']?.toString() ?? '10:00 AM',
        durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 45,
        visitorCount: (map['visitor_count'] as num?)?.toInt() ?? 2,
        cabRequired: map['cab_required'] as bool? ?? false,
        notes: map['notes']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Scheduled',
      );
}

class PropertyVisitPlan {
  final String id;
  final String buyerId;
  final String planTitle;
  final String visitDate; // e.g. 'Saturday, 12 Sept 2026'
  final List<PlannedVisitStop> stops;
  final String preferredCabPickupLocation;
  final DateTime createdAt;

  PropertyVisitPlan({
    required this.id,
    required this.buyerId,
    required this.planTitle,
    required this.visitDate,
    required this.stops,
    this.preferredCabPickupLocation = 'Sector 137 Metro Station, Noida',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'buyer_id': buyerId,
        'plan_title': planTitle,
        'visit_date': visitDate,
        'stops': stops.map((s) => s.toMap()).toList(),
        'preferred_cab_pickup_location': preferredCabPickupLocation,
        'created_at': createdAt.toIso8601String(),
      };

  factory PropertyVisitPlan.fromMap(Map<String, dynamic> map) => PropertyVisitPlan(
        id: map['id']?.toString() ?? 'PLAN-${DateTime.now().millisecondsSinceEpoch}',
        buyerId: map['buyer_id']?.toString() ?? '',
        planTitle: map['plan_title']?.toString() ?? 'Weekend NCR Property Tour',
        visitDate: map['visit_date']?.toString() ?? 'Saturday, 12 Sept 2026',
        stops: (map['stops'] as List<dynamic>?)
                ?.map((s) => PlannedVisitStop.fromMap(Map<String, dynamic>.from(s as Map)))
                .toList() ??
            [],
        preferredCabPickupLocation: map['preferred_cab_pickup_location']?.toString() ?? 'Sector 137 Metro Station',
        createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      );

  static PropertyVisitPlan samplePlan(String buyerId) => PropertyVisitPlan(
        id: 'PLAN-SAMPLE-01',
        buyerId: buyerId,
        planTitle: 'Noida Expressway 3 BHK Shortlist Tour',
        visitDate: 'This Saturday, 10:00 AM - 3:00 PM',
        preferredCabPickupLocation: 'Sector 137 Metro Station, Noida',
        stops: [
          PlannedVisitStop(
            id: 'STOP-1',
            propertyId: 'PROP-ATS-01',
            propertyTitle: 'ATS HomeKraft Pious Orchards',
            propertySector: 'Sector 150, Noida',
            propertyImage: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
            askingPriceCr: 1.85,
            timeSlot: '10:00 AM',
            durationMinutes: 60,
            visitorCount: 2,
            cabRequired: true,
            notes: 'Inspect 18th floor tower unit facing central greens.',
          ),
          PlannedVisitStop(
            id: 'STOP-2',
            propertyId: 'PROP-GODREJ-02',
            propertyTitle: 'Godrej Palm Retreat',
            propertySector: 'Sector 150, Noida',
            propertyImage: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
            askingPriceCr: 2.75,
            timeSlot: '12:00 PM',
            durationMinutes: 60,
            visitorCount: 2,
            cabRequired: true,
            notes: 'Review clubhouse amenities and sample modular kitchen.',
          ),
          PlannedVisitStop(
            id: 'STOP-3',
            propertyId: 'PROP-GAUR-03',
            propertyTitle: 'Gaur City 2 - 14th Avenue',
            propertySector: 'Greater Noida West',
            propertyImage: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
            askingPriceCr: 1.10,
            timeSlot: '02:30 PM',
            durationMinutes: 45,
            visitorCount: 2,
            cabRequired: true,
            notes: 'Compare rental yield and commercial market connectivity.',
          ),
        ],
      );
}
