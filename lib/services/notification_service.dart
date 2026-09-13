import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';
import 'property_state_service.dart';

class NotificationItem {
  final String id;
  final String? userId;
  final String? dealerId;
  final String? propertyId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    this.userId,
    this.dealerId,
    this.propertyId,
    required this.title,
    required this.message,
    this.type = 'system',
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    try {
      parsedDate = map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationItem(
      id: map['id']?.toString() ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString(),
      dealerId: map['dealer_id']?.toString(),
      propertyId: map['property_id']?.toString(),
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'system',
      isRead: map['is_read'] == true || map['read'] == true || map['isRead'] == true,
      createdAt: parsedDate,
    );
  }
}

class NotificationService extends ChangeNotifier {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;

  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // =========================================================================
  // 1. FETCH NOTIFICATIONS FROM SUPABASE
  // =========================================================================
  Future<List<NotificationItem>> fetchNotifications() async {
    try {
      final list = await SupabaseService.instance.fetchNotifications();
      if (list.isNotEmpty) {
        _notifications = list.map((item) => NotificationItem.fromMap(item)).toList();
        notifyListeners();
        return _notifications;
      }
    } catch (e) {
      debugPrint('[NotificationService] Error fetching notifications: $e');
    }

    // Default fallback from local state
    _notifications = PropertyStateService.instance.notifications
        .map((n) => NotificationItem.fromMap(n))
        .toList();
    notifyListeners();
    return _notifications;
  }

  // =========================================================================
  // 2. MARK NOTIFICATION AS READ
  // =========================================================================
  Future<bool> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      final current = _notifications[idx];
      _notifications[idx] = NotificationItem(
        id: current.id,
        userId: current.userId,
        dealerId: current.dealerId,
        propertyId: current.propertyId,
        title: current.title,
        message: current.message,
        type: current.type,
        isRead: true,
        createdAt: current.createdAt,
      );
      notifyListeners();
    }
    return await SupabaseService.instance.markNotificationAsRead(notificationId);
  }

  // =========================================================================
  // 3. SEND NOTIFICATION
  // =========================================================================
  Future<bool> sendNotification({
    required String title,
    required String message,
    String type = 'system',
    String? userId,
    String? dealerId,
    String? propertyId,
  }) async {
    final now = DateTime.now();
    final item = NotificationItem(
      id: 'NOTIF-${now.millisecondsSinceEpoch}',
      userId: userId,
      dealerId: dealerId,
      propertyId: propertyId,
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: now,
    );

    _notifications.insert(0, item);
    notifyListeners();

    try {
      await SupabaseService.instance.addNotification(
        title: title,
        message: message,
        type: type,
        userId: userId,
        propertyId: propertyId,
      );
    } catch (_) {}

    return true;
  }
}
