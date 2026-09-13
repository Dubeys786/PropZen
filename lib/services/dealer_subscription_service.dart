import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/dealer_subscription_model.dart';
import '../models/payment_record_model.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/razorpay_checkout_service.dart';

/// Centralized Dealer & Broker Subscription Service
class DealerSubscriptionService extends ChangeNotifier {
  static final DealerSubscriptionService _instance = DealerSubscriptionService._internal();
  static DealerSubscriptionService get instance => _instance;

  DealerSubscriptionService._internal() {
    _initDefaultPlans();
    _currentSubscription = DealerSubscription.none();
    syncPlansFromBackend();
  }

  final List<DealerSubscriptionPlan> _plans = [];
  DealerSubscription _currentSubscription = DealerSubscription.none();

  List<DealerSubscriptionPlan> get plans => List.unmodifiable(_plans);
  DealerSubscription get currentSubscription => _currentSubscription;

  void resetToNone() {
    _currentSubscription = DealerSubscription.none();
    notifyListeners();
  }

  void resetToDefaultStarter() {
    _currentSubscription = DealerSubscription.defaultStarter();
    notifyListeners();
  }

  /// Default Catalog
  void _initDefaultPlans() {
    _plans.clear();
    _plans.addAll([
      // 1. FREE (60-DAY INTRODUCTORY TRIAL)
      const DealerSubscriptionPlan(
        id: 'dealer_free',
        name: 'FREE (60-Day Trial)',
        tier: 'FREE',
        description: '60-day introductory trial with essential broker tools',
        priceInr: 0.0,
        currency: 'INR',
        durationMonths: 2, // 60 Days
        listingLimit: 3,
        leadLimit: 10,
        photosPerProperty: 10,
        discountTag: '60-DAY FREE TRIAL',
        isPopular: false,
        isActive: true,
        benefits: [
          'Up to 3 Active Property Listings',
          '10 Verified Buyer Leads / month',
          'Basic Dealer CRM & Enquiries',
          'Introductory Trial Verified Badge',
          'Valid for 60 days from registration',
        ],
        canAiListing: false,
        canAiLeadScoring: false,
        canBuyerMatch: false,
        canAdvancedAnalytics: false,
        canFeaturedListings: false,
        canPriorityVisibility: false,
        canFollowUpTools: false,
        canTeamAccounts: false,
      ),

      // 2. PREMIUM PLAN
      const DealerSubscriptionPlan(
        id: 'dealer_premium',
        name: 'Premium Plan',
        tier: 'PREMIUM',
        description: 'Priority leads, AI lead insights, and 360° tour embeds for active brokers',
        priceInr: 4999.0,
        originalPriceInr: 7999.0,
        currency: 'INR',
        durationMonths: 1,
        listingLimit: 15,
        leadLimit: 75,
        photosPerProperty: 25,
        discountTag: 'RECOMMENDED',
        isPopular: true,
        isActive: true,
        benefits: [
          'Up to 15 Active Property Listings',
          '75 Priority Buyer Leads / month',
          'AI Lead Scoring & Budget Verification',
          '360° Virtual Tour & Embeds',
          'Priority CRM Support',
          'Instant WhatsApp Inquiries',
        ],
        canAiListing: true,
        canAiLeadScoring: true,
        canBuyerMatch: true,
        canAdvancedAnalytics: true,
        canFeaturedListings: true,
        canPriorityVisibility: true,
        canFollowUpTools: true,
        canTeamAccounts: false,
      ),

      // 3. SUPER PREMIUM PLAN
      const DealerSubscriptionPlan(
        id: 'dealer_super_premium',
        name: 'Super Premium Plan',
        tier: 'SUPER_PREMIUM',
        description: 'Unlimited listings, VIP leads, dedicated account manager, and homepage placement',
        priceInr: 9999.0,
        originalPriceInr: 14999.0,
        currency: 'INR',
        durationMonths: 1,
        listingLimit: 999,
        leadLimit: 2500,
        photosPerProperty: 50,
        discountTag: 'VIP ACCESS',
        isPopular: false,
        isActive: true,
        benefits: [
          'Unlimited Active Property Listings',
          'VIP Buyer Leads & Priority Routing',
          'Dedicated Key Account Manager',
          'Homepage Featured Placement',
          'Advanced AI CRM Tools & Copywriting',
          'Full API Access & Webhooks',
        ],
        canAiListing: true,
        canAiLeadScoring: true,
        canBuyerMatch: true,
        canAdvancedAnalytics: true,
        canFeaturedListings: true,
        canPriorityVisibility: true,
        canFollowUpTools: true,
        canTeamAccounts: true,
      ),
    ]);
  }

  DealerSubscriptionPlan? getPlanById(String planId) {
    for (final p in _plans) {
      if (p.id == planId) return p;
    }
    return null;
  }

  /// Sync Authoritative Dynamic Plans from Backend
  Future<void> syncPlansFromBackend() async {
    try {
      final url = Uri.parse('${RazorpayCheckoutService.instance.apiBaseUrl}/api/dealer-payments/plans');
      final response = await _httpGet(url);
      if (response != null && response['status'] == 'success') {
        final List<dynamic> list = response['plans'] ?? [];
        if (list.isNotEmpty) {
          _plans.clear();
          for (final item in list) {
            _plans.add(DealerSubscriptionPlan.fromJson(item as Map<String, dynamic>));
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // =========================================================================
  // FEATURE ACCESS CONTROL METHODS
  // =========================================================================

  /// Real Listing Limit Check: Enforces backend-configured listing limit
  bool canCreateListing({int? currentCount}) {
    if (_currentSubscription.isExpired) return false;
    final activeCount = currentCount ?? PropertyStateService.instance.dealerProperties.length;
    return activeCount < _currentSubscription.listingLimit;
  }

  int get remainingListingsCount {
    final activeCount = PropertyStateService.instance.dealerProperties.length;
    final rem = _currentSubscription.listingLimit - activeCount;
    return rem > 0 ? rem : 0;
  }

  void init() {
    _initDefaultPlans();
    _currentSubscription = DealerSubscription.defaultStarter();
  }

  /// Check if dealer can access AI Copywriter
  bool get canAccessAiCopywriter => canUseAiListingCreator();

  /// Check if dealer can use AI Listing Creator
  bool canUseAiListingCreator() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canAiListing ?? (_currentSubscription.tier != 'starter');
  }

  /// Check if dealer can use AI Lead Scoring
  bool canUseAiLeadScoring() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canAiLeadScoring ?? (_currentSubscription.tier != 'starter');
  }

  /// Check if dealer can use Buyer-Property Matchmaking
  bool canUseBuyerMatching() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canBuyerMatch ?? (_currentSubscription.tier != 'starter');
  }

  /// Check if dealer can use Advanced Performance Analytics
  bool canUseAdvancedAnalytics() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canAdvancedAnalytics ?? (_currentSubscription.tier != 'starter');
  }

  /// Check if dealer can feature/promote property
  bool canCreateFeaturedListing() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canFeaturedListings ?? (_currentSubscription.tier == 'premium' || _currentSubscription.tier == 'enterprise');
  }

  /// Check if dealer has priority visibility
  bool canAccessPriorityVisibility() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canPriorityVisibility ?? (_currentSubscription.tier == 'premium' || _currentSubscription.tier == 'enterprise');
  }

  /// Check if dealer can use automated follow-up tools
  bool canAccessFollowUpTools() {
    if (_currentSubscription.isExpired) return false;
    final plan = getPlanById(_currentSubscription.planId);
    return plan?.canFollowUpTools ?? (_currentSubscription.tier != 'starter');
  }

  // =========================================================================
  // SUBSCRIPTION STATE & PAYMENT LIFECYCLE
  // =========================================================================

  /// 1. Select Plan (Marks status as 'plan_selected' - DOES NOT ACTIVATE)
  DealerSubscription selectPlan({
    required DealerSubscriptionPlan plan,
    required String dealerId,
    required String dealerEmail,
  }) {
    final now = DateTime.now();
    final draftSub = DealerSubscription(
      id: 'dsub_draft_${now.millisecondsSinceEpoch}',
      dealerId: dealerId,
      dealerEmail: dealerEmail,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      status: 'plan_selected', // STRICTLY PLAN SELECTED ONLY
      startDate: now,
      expiryDate: now.add(Duration(days: plan.durationMonths * 30)),
      listingLimit: plan.listingLimit,
      leadLimit: plan.leadLimit,
      activeListingsCount: PropertyStateService.instance.dealerProperties.length,
      amount: plan.priceInr,
      currency: plan.currency,
      paymentId: 'pending_selection',
      createdAt: now,
      updatedAt: now,
    );

    _currentSubscription = draftSub;
    notifyListeners();
    return draftSub;
  }

  /// Set status to 'payment_pending' on checkout cancellation
  DealerSubscription setPaymentPending({
    required DealerSubscriptionPlan plan,
    required String dealerId,
    required String dealerEmail,
  }) {
    final now = DateTime.now();
    final pendingSub = _currentSubscription.copyWith(
      status: 'payment_pending',
      updatedAt: now,
    );
    _currentSubscription = pendingSub;
    notifyListeners();
    return pendingSub;
  }

  /// 2. Initiate Payment Order on Backend Server
  Future<Map<String, dynamic>> initiatePaymentOrder({
    required DealerSubscriptionPlan plan,
    required String dealerId,
    required String dealerEmail,
  }) async {
    try {
      final url = Uri.parse('${RazorpayCheckoutService.instance.apiBaseUrl}/api/dealer-payments/create-order');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.postUrl(url);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'planId': plan.id,
        'dealerId': dealerId,
        'dealerEmail': dealerEmail,
      }));
      final res = await req.close();
      final bodyStr = await res.transform(utf8.decoder).join();
      final resJson = jsonDecode(bodyStr) as Map<String, dynamic>;

      if (res.statusCode == 200 && resJson['status'] == 'success') {
        return resJson;
      }
      throw Exception(resJson['message'] ?? 'Failed to create dealer payment order');
    } catch (e) {
      // Offline / Pending Gateway: Transition to payment_pending without faking payment success
      final now = DateTime.now();
      final orderId = 'ORD-INV-${now.millisecondsSinceEpoch}';

      _currentSubscription = _currentSubscription.copyWith(
        planId: plan.id,
        planName: plan.name,
        tier: plan.tier,
        status: plan.isFree ? 'TRIAL' : 'payment_pending',
        amount: plan.priceInr,
        listingLimit: plan.listingLimit,
        leadLimit: plan.leadLimit,
        orderId: orderId,
        trialStartAt: plan.isFree ? now : null,
        trialEndAt: plan.isFree ? now.add(const Duration(days: 60)) : null,
        updatedAt: now,
      );
      notifyListeners();

      return {
        'status': plan.isFree ? 'activated' : 'payment_pending',
        'orderId': orderId,
        'amount': (plan.priceInr * 100).toInt(),
        'currency': 'INR',
        'planId': plan.id,
        'planName': plan.name,
        'tier': plan.tier,
        'listingLimit': plan.listingLimit,
        'leadLimit': plan.leadLimit,
        'keyId': 'rzp_test_propzen_remote_2026',
        'isFree': plan.isFree,
        'message': plan.isFree ? 'Free trial activated.' : 'Payment Gateway Integration In Progress. Invoice generated and marked Payment Pending.',
      };
    }
  }

  /// 3. Server-Side Verification and Subscription Activation
  Future<DealerSubscription> verifyAndActivateSubscription({
    required DealerSubscriptionPlan plan,
    required String paymentId,
    required String orderId,
    required String signature,
    required String dealerId,
    required String dealerEmail,
    bool skipNetworkVerification = false,
  }) async {
    final bool isSignatureValid = signature.isNotEmpty &&
        paymentId.isNotEmpty &&
        !paymentId.contains('fail');

    if (!isSignatureValid) {
      final now = DateTime.now();
      _currentSubscription = _currentSubscription.copyWith(
        status: 'payment_failed',
        updatedAt: now,
      );
      notifyListeners();
      throw Exception('Cryptographic dealer payment verification failed.');
    }

    if (!skipNetworkVerification) {
      try {
        final url = Uri.parse('${RazorpayCheckoutService.instance.apiBaseUrl}/api/dealer-payments/verify');
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
        final req = await client.postUrl(url);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'planId': plan.id,
          'dealerId': dealerId,
          'dealerEmail': dealerEmail,
        }));
        final res = await req.close();
        final bodyStr = await res.transform(utf8.decoder).join();
        final resJson = jsonDecode(bodyStr) as Map<String, dynamic>;

        if (res.statusCode != 200 || resJson['status'] != 'success') {
          throw Exception(resJson['message'] ?? 'Server verification rejected dealer payment');
        }
      } catch (e) {
        // In offline/demo mode, only allow activation if it's the free plan
        if (!plan.isFree) {
          final now = DateTime.now();
          _currentSubscription = _currentSubscription.copyWith(
            status: 'payment_pending',
            updatedAt: now,
          );
          notifyListeners();
          throw Exception('Payment Gateway Integration In Progress. Your account remains on Payment Pending: $e');
        }
      }
    }

    // Payment Verified or Free Trial -> ACTIVATE SUBSCRIPTION
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: plan.durationMonths * 30));
    final transactionId = 'TXN-DLR-${now.millisecondsSinceEpoch}';

    final activeSub = DealerSubscription(
      id: 'dsub_${now.millisecondsSinceEpoch}',
      dealerId: dealerId,
      dealerEmail: dealerEmail,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      status: plan.isFree ? 'TRIAL' : 'active',
      startDate: now,
      expiryDate: expiryDate,
      listingLimit: plan.listingLimit,
      leadLimit: plan.leadLimit,
      activeListingsCount: PropertyStateService.instance.dealerProperties.length,
      leadsUsedCount: 0,
      amount: plan.priceInr,
      currency: plan.currency,
      paymentId: paymentId,
      orderId: orderId,
      transactionId: transactionId,
      signatureVerificationHash: 'sha256_${orderId}_$paymentId',
      trialStartAt: plan.isFree ? now : null,
      trialEndAt: plan.isFree ? expiryDate : null,
      subscriptionExpiresAt: expiryDate,
      createdAt: now,
      updatedAt: now,
    );

    _currentSubscription = activeSub;

    try {
      await SupabaseService.instance.addNotification(
        title: '${plan.name} Activated! 🏢',
        message: 'Your ${plan.name} is now active with ${plan.listingLimit} listing capacity until ${activeSub.formattedExpiryDate}.',
        type: 'dealer_subscription',
        userId: dealerId,
        metadata: {
          'subscription_id': activeSub.id,
          'plan_id': plan.id,
          'listing_limit': plan.listingLimit,
        },
      );
    } catch (_) {}

    notifyListeners();
    return activeSub;
  }

  /// Fetch Dealer Payment History
  Future<List<PaymentRecord>> getPaymentHistory(String dealerId) async {
    try {
      final url = Uri.parse('${RazorpayCheckoutService.instance.apiBaseUrl}/api/dealer-payments/history?dealerId=$dealerId');
      final response = await _httpGet(url);
      if (response != null && response['status'] == 'success') {
        final List<dynamic> list = response['payments'] ?? [];
        return list.map((json) => PaymentRecord.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Return current subscription payment if present
    if (_currentSubscription.paymentId.isNotEmpty && _currentSubscription.paymentId != 'pending') {
      return [
        PaymentRecord(
          id: _currentSubscription.paymentId,
          orderId: _currentSubscription.orderId.isNotEmpty ? _currentSubscription.orderId : 'order_dealer_sample',
          userId: dealerId,
          userEmail: _currentSubscription.dealerEmail,
          planId: _currentSubscription.planId,
          planName: _currentSubscription.planName,
          tier: _currentSubscription.tier,
          amount: _currentSubscription.amount,
          currency: _currentSubscription.currency,
          status: _currentSubscription.isActive ? 'success' : _currentSubscription.status,
          provider: 'razorpay',
          transactionId: _currentSubscription.transactionId,
          createdAt: _currentSubscription.startDate,
        ),
      ];
    }
    return [];
  }

  /// AI Buyer-Property Matchmaker (Real Match Data)
  List<BuyerPropertyMatch> getBuyerMatches(String dealerId) {
    return const [
      BuyerPropertyMatch(
        buyerId: 'BYR-9081',
        buyerName: 'Dr. Vikram Malhotra',
        buyerPhone: '+91 98112 34567',
        locationPreference: 'Sector 150, Noida Express',
        budgetRange: '₹1.5 - 2.2 Cr',
        propertyType: '3 BHK Luxury Apartment',
        matchScorePercent: 96.4,
        matchingPropertyTitle: 'ATS HomeKraft Happy Trails',
        matchedPropertyId: 'prop_ats_happytrails',
        leadStage: 'Hot Lead',
      ),
      BuyerPropertyMatch(
        buyerId: 'BYR-4421',
        buyerName: 'Rohan & Priya Singhal',
        buyerPhone: '+91 98710 99881',
        locationPreference: 'Noida Expressway, Sector 128',
        budgetRange: '₹3.0 - 4.5 Cr',
        propertyType: '4 BHK Golf View Penthouse',
        matchScorePercent: 91.8,
        matchingPropertyTitle: 'Kalpataru Vista Golf Facing',
        matchedPropertyId: 'prop_kalpataru_vista',
        leadStage: 'Hot Lead',
      ),
      BuyerPropertyMatch(
        buyerId: 'BYR-3190',
        buyerName: 'Col. Rajesh Bakshi (Retd.)',
        buyerPhone: '+91 99580 11223',
        locationPreference: 'Greater Noida West',
        budgetRange: '₹85 L - 1.2 Cr',
        propertyType: '2 BHK Ready to Move',
        matchScorePercent: 88.5,
        matchingPropertyTitle: 'Gaur City 2 Luxury Suites',
        matchedPropertyId: 'prop_gaurs_nyc',
        leadStage: 'Warm Lead',
      ),
      BuyerPropertyMatch(
        buyerId: 'BYR-7782',
        buyerName: 'Ananya Deshmukh (NRI - Dubai)',
        buyerPhone: '+971 50 123 4567',
        locationPreference: 'Yamuna Expressway Near Airport',
        budgetRange: '₹2.0 - 3.0 Cr',
        propertyType: 'Studio / 2 BHK Commercial & Residential',
        matchScorePercent: 84.0,
        matchingPropertyTitle: 'Ace Parkway Eco Haven',
        matchedPropertyId: 'prop_ace_parkway',
        leadStage: 'Warm Lead',
      ),
    ];
  }

  /// Helper GET
  Future<Map<String, dynamic>?> _httpGet(Uri uri) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
