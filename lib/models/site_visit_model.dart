enum SiteVisitStatus {
  requested,
  confirmed,
  completed,
  cancelled,
}

extension SiteVisitStatusExt on SiteVisitStatus {
  String get displayName {
    switch (this) {
      case SiteVisitStatus.requested:
        return 'Requested';
      case SiteVisitStatus.confirmed:
        return 'Confirmed';
      case SiteVisitStatus.completed:
        return 'Completed';
      case SiteVisitStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get badgeLabel {
    switch (this) {
      case SiteVisitStatus.requested:
        return '⏳ REQUESTED';
      case SiteVisitStatus.confirmed:
        return '✅ CONFIRMED';
      case SiteVisitStatus.completed:
        return '🏆 COMPLETED';
      case SiteVisitStatus.cancelled:
        return '❌ CANCELLED';
    }
  }
}

class DealerSiteVisit {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertySector;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final String dealerId;
  final String dealerName;
  final String scheduledDate;
  final String scheduledTime;
  final int visitorCount;
  final bool cabRequired;
  final String? pickupLocation;
  final String? notes;
  final SiteVisitStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DealerSiteVisit({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertySector,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhone = '',
    this.buyerEmail = '',
    required this.dealerId,
    this.dealerName = 'Verified Dealer',
    required this.scheduledDate,
    required this.scheduledTime,
    this.visitorCount = 1,
    this.cabRequired = false,
    this.pickupLocation,
    this.notes,
    this.status = SiteVisitStatus.requested,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isRequested => status == SiteVisitStatus.requested;
  bool get isConfirmed => status == SiteVisitStatus.confirmed;
  bool get isCompleted => status == SiteVisitStatus.completed;
  bool get isCancelled => status == SiteVisitStatus.cancelled;

  DealerSiteVisit copyWith({
    SiteVisitStatus? status,
    String? scheduledDate,
    String? scheduledTime,
    String? notes,
    DateTime? updatedAt,
  }) {
    return DealerSiteVisit(
      id: id,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      propertySector: propertySector,
      buyerId: buyerId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      dealerId: dealerId,
      dealerName: dealerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      visitorCount: visitorCount,
      cabRequired: cabRequired,
      pickupLocation: pickupLocation,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'property_title': propertyTitle,
      'property_sector': propertySector,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'buyer_email': buyerEmail,
      'dealer_id': dealerId,
      'dealer_name': dealerName,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'visitor_count': visitorCount,
      'cab_required': cabRequired,
      'pickup_location': pickupLocation,
      'notes': notes,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DealerSiteVisit.fromMap(Map<String, dynamic> map) {
    SiteVisitStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'confirmed':
          return SiteVisitStatus.confirmed;
        case 'completed':
          return SiteVisitStatus.completed;
        case 'cancelled':
          return SiteVisitStatus.cancelled;
        case 'requested':
        default:
          return SiteVisitStatus.requested;
      }
    }

    return DealerSiteVisit(
      id: map['id']?.toString() ?? 'VISIT-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: map['property_id']?.toString() ?? map['propertyId']?.toString() ?? '',
      propertyTitle: map['property_title']?.toString() ?? map['propertyTitle']?.toString() ?? 'Property Visit',
      propertySector: map['property_sector']?.toString() ?? map['propertySector']?.toString() ?? 'Sector 150',
      buyerId: map['buyer_id']?.toString() ?? map['buyerId']?.toString() ?? 'usr_buyer',
      buyerName: map['buyer_name']?.toString() ?? map['buyerName']?.toString() ?? 'Prospective Buyer',
      buyerPhone: map['buyer_phone']?.toString() ?? map['buyerPhone']?.toString() ?? '',
      buyerEmail: map['buyer_email']?.toString() ?? map['buyerEmail']?.toString() ?? '',
      dealerId: map['dealer_id']?.toString() ?? map['dealerId']?.toString() ?? '',
      dealerName: map['dealer_name']?.toString() ?? map['dealerName']?.toString() ?? 'Verified Dealer',
      scheduledDate: map['scheduled_date']?.toString() ?? map['scheduledDate']?.toString() ?? 'Today',
      scheduledTime: map['scheduled_time']?.toString() ?? map['scheduledTime']?.toString() ?? '11:00 AM',
      visitorCount: (map['visitor_count'] as num?)?.toInt() ?? (map['visitorCount'] as num?)?.toInt() ?? 1,
      cabRequired: map['cab_required'] == true || map['cabRequired'] == true,
      pickupLocation: map['pickup_location']?.toString() ?? map['pickupLocation']?.toString(),
      notes: map['notes']?.toString(),
      status: parseStatus(map['status']?.toString()),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }
}
