import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class UserNotificationService extends ChangeNotifier {
  UserNotificationService._internal() {
    _initDefaultNotifications();
  }
  static final UserNotificationService instance = UserNotificationService._internal();
  factory UserNotificationService() => instance;

  final List<UserNotificationModel> _notifications = [];
  final Set<String> _priceAlertPropertyIds = {};

  List<UserNotificationModel> get notifications => List.unmodifiable(_notifications);
  Set<String> get priceAlertPropertyIds => Set.unmodifiable(_priceAlertPropertyIds);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _initDefaultNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      UserNotificationModel(
        id: 'notif_01',
        userId: 'usr_active',
        title: 'Property Verified: Mahagun Manorialle',
        message: 'Mahagun Manorialle (PZ-NOI-000124) has successfully completed 5-pillar verification.',
        type: NotificationType.propertyVerification,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
        relatedEntityId: 'prop_mahagun',
      ),
      UserNotificationModel(
        id: 'notif_02',
        userId: 'usr_active',
        title: 'Price Drop Alert',
        message: 'Price updated for your saved property: ATS Knightsbridge is now ₹8.75 Cr (Was ₹9.20 Cr).',
        type: NotificationType.priceChange,
        isRead: false,
        createdAt: now.subtract(const Duration(days: 1)),
        relatedEntityId: 'prop_ats',
        metadata: {'oldPrice': 9.20, 'newPrice': 8.75, 'currency': 'Cr'},
      ),
      UserNotificationModel(
        id: 'notif_03',
        userId: 'usr_active',
        title: 'Site Visit Confirmed',
        message: 'Your site visit for Godrej Tropical Isle is confirmed for this Saturday at 11:00 AM.',
        type: NotificationType.siteVisit,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
        relatedEntityId: 'prop_godrej',
      ),
    ]);
  }

  bool hasPriceAlert(String propertyId) => _priceAlertPropertyIds.contains(propertyId);

  void togglePriceAlert(String propertyId) {
    if (_priceAlertPropertyIds.contains(propertyId)) {
      _priceAlertPropertyIds.remove(propertyId);
    } else {
      _priceAlertPropertyIds.add(propertyId);
      addNotification(
        title: 'Price Alert Enabled',
        message: 'You will receive real-time notifications if the asking price updates.',
        type: NotificationType.priceChange,
        relatedEntityId: propertyId,
      );
    }
    notifyListeners();
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedEntityId,
    Map<String, dynamic>? metadata,
  }) {
    final notif = UserNotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_active',
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      relatedEntityId: relatedEntityId,
      metadata: metadata,
    );
    _notifications.insert(0, notif);
    notifyListeners();
  }

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final old = _notifications[idx];
      _notifications[idx] = UserNotificationModel(
        id: old.id,
        userId: old.userId,
        title: old.title,
        message: old.message,
        type: old.type,
        isRead: true,
        createdAt: old.createdAt,
        relatedEntityId: old.relatedEntityId,
        metadata: old.metadata,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final old = _notifications[i];
      if (!old.isRead) {
        _notifications[i] = UserNotificationModel(
          id: old.id,
          userId: old.userId,
          title: old.title,
          message: old.message,
          type: old.type,
          isRead: true,
          createdAt: old.createdAt,
          relatedEntityId: old.relatedEntityId,
          metadata: old.metadata,
        );
      }
    }
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
