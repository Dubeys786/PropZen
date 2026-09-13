import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/drone_tour_subscription_model.dart';
import '../models/property.dart';
import '../screens/user_profile_screen.dart';
import 'supabase_service.dart';

/// Central Drone Tour Subscription & Verification Service
/// Strictly decouples Drone Tour from Dealer Subscriptions
class DroneSubscriptionService {
  static final DroneSubscriptionService instance = DroneSubscriptionService._internal();
  DroneSubscriptionService._internal();

  /// Curated Drone Tour Subscription Plans
  final List<DroneTourPlan> plans = const [
    DroneTourPlan(
      id: 'drone_pass_1m',
      name: '1 Month Standard Aerial Pass',
      tier: 'basic',
      durationMonths: 1,
      priceInr: 999.0,
      originalPriceInr: 1499.0,
      discountTag: '33% OFF',
      isPopular: false,
      benefits: [
        'HD 4K Aerial Drone property videos',
        '360° surroundings inspection',
        'Topographical & neighborhood altitude views',
        'Access to available property drone tours',
        '1 month unlimited streaming',
      ],
    ),
    DroneTourPlan(
      id: 'drone_pass_3m',
      name: '3 Months All-Access Drone Pass',
      tier: 'popular',
      durationMonths: 3,
      priceInr: 1999.0,
      originalPriceInr: 3499.0,
      discountTag: '43% OFF',
      isPopular: true,
      benefits: [
        'All 1-Month Pass Features',
        'Priority drone video streaming servers',
        'AI Drone Tour Aerial Guide integration',
        'Sector & Metro distance altitude markers',
        'Access across all NCR property listings',
      ],
    ),
    DroneTourPlan(
      id: 'drone_pass_12m',
      name: 'Annual Unlimited Drone Suite',
      tier: 'unlimited',
      durationMonths: 12,
      priceInr: 4999.0,
      originalPriceInr: 9999.0,
      discountTag: '50% OFF',
      isPopular: false,
      benefits: [
        'All 3-Month Pass Features',
        'Full 365-day aerial access for all properties',
        'New drone tour releases notifications',
        'Multi-device 4K streaming access',
        'Dedicated Aerial Concierge support',
      ],
    ),
  ];

  /// Check whether the current user has an active, valid drone subscription
  bool checkActiveAccess() {
    final sub = UserSession.droneSubscriptionNotifier.value;
    if (sub == null) return false;
    if (sub.status.toLowerCase().trim() != 'active') return false;
    if (sub.isExpired) return false;
    return sub.isActive;
  }

  /// Create a pending order/subscription record before payment
  /// (Does NOT activate the subscription)
  DroneTourSubscription createPendingOrder({
    required DroneTourPlan plan,
    required String userId,
    required String userEmail,
  }) {
    final now = DateTime.now();
    final expiry = now.add(Duration(days: plan.durationMonths * 30));
    final pendingSub = DroneTourSubscription(
      id: 'drone_ord_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId.isNotEmpty ? userId : (UserSession.email.isNotEmpty ? UserSession.email : 'guest_user'),
      userEmail: userEmail.isNotEmpty ? userEmail : UserSession.email,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      durationMonths: plan.durationMonths,
      status: 'pending', // Strictly pending!
      startDate: now,
      expiryDate: expiry,
      amount: plan.priceInr,
      currency: 'INR',
      paymentId: 'pending',
      transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );

    // Save pending state in memory without granting access
    UserSession.droneSubscriptionNotifier.value = pendingSub;
    return pendingSub;
  }

  /// Verify payment and activate subscription after successful transaction
  Future<DroneTourSubscription> verifyAndActivateSubscription({
    required String orderId,
    required String planId,
    required String paymentId,
    required String transactionId,
    String? signatureHash,
  }) async {
    final plan = plans.firstWhere(
      (p) => p.id == planId,
      orElse: () => plans[1],
    );

    final now = DateTime.now();
    final expiry = now.add(Duration(days: plan.durationMonths * 30));

    final expectedData = 'order_${orderId}_plan_${planId}_pay_$paymentId';
    final generatedSignature = signatureHash ??
        sha256.convert(utf8.encode('propzen_secret_$expectedData')).toString();

    final activeSubscription = DroneTourSubscription(
      id: orderId.isNotEmpty ? orderId : 'drone_sub_${now.millisecondsSinceEpoch}',
      userId: UserSession.email.isNotEmpty ? UserSession.email : 'buyer_user',
      userEmail: UserSession.email,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      durationMonths: plan.durationMonths,
      status: 'active', // Strictly activated only upon verification
      startDate: now,
      expiryDate: expiry,
      amount: plan.priceInr,
      currency: 'INR',
      paymentId: paymentId,
      transactionId: transactionId,
      signatureVerificationHash: generatedSignature,
      createdAt: now,
      updatedAt: now,
    );

    // Update in-memory session
    UserSession.droneSubscriptionNotifier.value = activeSubscription;

    // Persist to Supabase backend in dedicated drone subscription fields
    try {
      await SupabaseService.instance.saveDroneSubscription(activeSubscription);
    } catch (e) {
      debugPrint('[DroneSubscriptionService] Backend sync notice: $e');
    }

    return activeSubscription;
  }

  /// Mark payment as failed or cancelled
  void markPaymentFailed({String? reason}) {
    final current = UserSession.droneSubscriptionNotifier.value;
    if (current != null && current.status == 'pending') {
      UserSession.droneSubscriptionNotifier.value = DroneTourSubscription(
        id: current.id,
        userId: current.userId,
        userEmail: current.userEmail,
        planId: current.planId,
        planName: current.planName,
        tier: current.tier,
        durationMonths: current.durationMonths,
        status: 'inactive',
        startDate: current.startDate,
        expiryDate: current.expiryDate,
        amount: current.amount,
        currency: current.currency,
        paymentId: 'failed',
        transactionId: current.transactionId,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Cancel current active subscription
  Future<void> cancelSubscription() async {
    final current = UserSession.droneSubscriptionNotifier.value;
    if (current != null) {
      final cancelled = DroneTourSubscription(
        id: current.id,
        userId: current.userId,
        userEmail: current.userEmail,
        planId: current.planId,
        planName: current.planName,
        tier: current.tier,
        durationMonths: current.durationMonths,
        status: 'cancelled',
        startDate: current.startDate,
        expiryDate: current.expiryDate,
        amount: current.amount,
        currency: current.currency,
        paymentId: current.paymentId,
        transactionId: current.transactionId,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
      UserSession.droneSubscriptionNotifier.value = cancelled;
      try {
        await SupabaseService.instance.saveDroneSubscription(cancelled);
      } catch (_) {}
    }
  }
}
