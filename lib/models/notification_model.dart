enum NotificationType {
  propertyVerification,
  enquiry,
  siteVisit,
  priceChange,
  dealerResponse,
  savedPropertyUpdate,
  accountSecurity;

  String get displayName {
    switch (this) {
      case NotificationType.propertyVerification:
        return 'Property Verification';
      case NotificationType.enquiry:
        return 'Enquiry Update';
      case NotificationType.siteVisit:
        return 'Site Visit';
      case NotificationType.priceChange:
        return 'Price Alert';
      case NotificationType.dealerResponse:
        return 'Dealer Message';
      case NotificationType.savedPropertyUpdate:
        return 'Saved Property';
      case NotificationType.accountSecurity:
        return 'Security';
    }
  }

  static NotificationType fromString(String val) {
    final lower = val.toLowerCase().replaceAll('_', '');
    if (lower.contains('verify') || lower.contains('verification')) return NotificationType.propertyVerification;
    if (lower.contains('enquiry') || lower.contains('lead')) return NotificationType.enquiry;
    if (lower.contains('visit') || lower.contains('tour')) return NotificationType.siteVisit;
    if (lower.contains('price') || lower.contains('alert')) return NotificationType.priceChange;
    if (lower.contains('dealer') || lower.contains('message')) return NotificationType.dealerResponse;
    if (lower.contains('saved') || lower.contains('wishlist')) return NotificationType.savedPropertyUpdate;
    return NotificationType.accountSecurity;
  }
}

class UserNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedEntityId;
  final Map<String, dynamic>? metadata;

  const UserNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.relatedEntityId,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'relatedEntityId': relatedEntityId,
        'metadata': metadata,
      };

  factory UserNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return UserNotificationModel(
      id: id,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: NotificationType.fromString(map['type']?.toString() ?? 'accountSecurity'),
      isRead: map['isRead'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      relatedEntityId: map['relatedEntityId']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic> ? map['metadata'] as Map<String, dynamic> : null,
    );
  }
}
