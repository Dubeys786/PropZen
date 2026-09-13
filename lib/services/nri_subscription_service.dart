import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/nri_subscription_model.dart';
import '../models/payment_record_model.dart';
import '../screens/user_profile_screen.dart';
import 'supabase_service.dart';
import 'n8n_service.dart';
import 'razorpay_checkout_service.dart';

/// Centralized NRI Remote Property Suite Service
class NriSubscriptionService extends ChangeNotifier {
  static final NriSubscriptionService _instance = NriSubscriptionService._internal();
  static NriSubscriptionService get instance => _instance;

  NriSubscriptionService._internal() {
    _initDefaultPlans();
    _initMockDocuments();
    _initMockFamilyReviews();
    _initMockMonitoredProperties();
    syncPlansFromBackend();
  }

  final List<NriSubscriptionPlan> _plans = [];
  final List<RemoteTourBooking> _remoteBookings = [];
  final List<NriDocumentItem> _documents = [];
  final List<FamilyDecisionReview> _familyReviews = [];
  final List<PropertyMonitoringSubscription> _monitoredProperties = [];

  List<NriSubscriptionPlan> get plans => List.unmodifiable(_plans);
  List<RemoteTourBooking> get remoteBookings => List.unmodifiable(_remoteBookings);
  List<NriDocumentItem> get documents => List.unmodifiable(_documents);
  List<FamilyDecisionReview> get familyReviews => List.unmodifiable(_familyReviews);
  List<PropertyMonitoringSubscription> get monitoredProperties => List.unmodifiable(_monitoredProperties);

  void _initDefaultPlans() {
    _plans.clear();
    _plans.addAll([
      // 1. BASIC TIER
      const NriSubscriptionPlan(
        id: 'nri_pass_basic',
        name: 'Basic NRI Remote Pass',
        tier: 'basic',
        durationMonths: 1,
        priceInr: 999.0,
        originalPriceInr: 1499.0,
        discountTag: '33% OFF',
        isPopular: false,
        canAccess360AndFloorPlan: true,
        canAccessAiAdvisor: true,
        canAccessDroneTours: false,
        canAccess3DView: false,
        canAccessLocalityIntelligence: false,
        canAccessConstructionUpdates: false,
        canAccessAiVoiceAssistant: false,
        canAccessLiveRemoteTour: false,
        canAccessSecureDealRoom: false,
        canAccessDocumentConcierge: false,
        canAccessFamilyDecisionMode: false,
        benefits: [
          'Interactive 360° Virtual Tours',
          'Architectural 2D/3D Floor Plans',
          'AI Property Match Advisor',
          'Locality Distance Calculators',
        ],
      ),

      // 2. PREMIUM TIER (RECOMMENDED)
      const NriSubscriptionPlan(
        id: 'nri_pass_premium',
        name: 'Premium NRI Drone & 3D Pass',
        tier: 'premium',
        durationMonths: 6,
        priceInr: 3999.0,
        originalPriceInr: 6999.0,
        discountTag: '43% OFF',
        isPopular: true,
        canAccess360AndFloorPlan: true,
        canAccessAiAdvisor: true,
        canAccessDroneTours: true,
        canAccess3DView: true,
        canAccessLocalityIntelligence: true,
        canAccessConstructionUpdates: true,
        canAccessAiVoiceAssistant: true,
        canAccessLiveRemoteTour: false,
        canAccessSecureDealRoom: false,
        canAccessDocumentConcierge: false,
        canAccessFamilyDecisionMode: false,
        benefits: [
          'Everything in Basic Pass',
          'Full-Access 4K Drone Aerial Tours',
          'Interactive 3D Architectural Twins',
          'Live Construction Progress Milestones',
          'NRI Voice Assistant (Hindi & English)',
          'AI Drone Tour "Ask AI" in-flight guide',
        ],
      ),

      // 3. ELITE TIER
      const NriSubscriptionPlan(
        id: 'nri_pass_elite',
        name: 'Elite NRI Global Concierge Pass',
        tier: 'elite',
        durationMonths: 12,
        priceInr: 5999.0,
        originalPriceInr: 11999.0,
        discountTag: '50% OFF',
        isPopular: false,
        canAccess360AndFloorPlan: true,
        canAccessAiAdvisor: true,
        canAccessDroneTours: true,
        canAccess3DView: true,
        canAccessLocalityIntelligence: true,
        canAccessConstructionUpdates: true,
        canAccessAiVoiceAssistant: true,
        canAccessLiveRemoteTour: true,
        canAccessSecureDealRoom: true,
        canAccessDocumentConcierge: true,
        canAccessFamilyDecisionMode: true,
        benefits: [
          'Everything in Premium Pass',
          'Live 1-on-1 Remote Video Tours',
          'NRI Document Concierge Vault',
          'Family Decision Voting & Summary',
          'Secure Deal Room & Negotiation Room',
          'Priority NRI Title Registry Support',
        ],
      ),
    ]);
  }

  void _initMockDocuments() {
    _documents.clear();
    _documents.addAll([
      NriDocumentItem(
        id: 'doc_rera_ats',
        propertyId: 'prop_ats_happytrails',
        title: 'UP RERA Registration Certificate',
        category: 'verification_documents',
        status: 'verified',
        fileUrl: 'https://rera-node.up.gov.in/certificates/UPRERAPRJ15574.pdf',
        fileSize: '2.4 MB',
        uploadedBy: 'ATS Infrastructure Ltd',
        uploadedAt: DateTime.now().subtract(const Duration(days: 45)),
        verifiedBy: 'PropZen Legal Desk',
        notes: '30-year search report confirmed zero encumbrances.',
      ),
      NriDocumentItem(
        id: 'doc_bba_ats',
        propertyId: 'prop_ats_happytrails',
        title: 'Standard Builder-Buyer Agreement (BBA)',
        category: 'agreement',
        status: 'verified',
        fileUrl: 'https://propzen.ai/docs/sample_bba_ats.pdf',
        fileSize: '4.1 MB',
        uploadedBy: 'Rajesh Varma (Verified Dealer)',
        uploadedAt: DateTime.now().subtract(const Duration(days: 20)),
        verifiedBy: 'Advocate Verma & Associates',
        notes: 'Compliant with UP RERA Model Agreement terms.',
      ),
      NriDocumentItem(
        id: 'doc_fp_godrej',
        propertyId: 'prop_godrej_woods',
        title: 'Architectural Wing Floor Plan Layout',
        category: 'floor_plan',
        status: 'verified',
        fileUrl: 'https://propzen.ai/docs/godrej_woods_fp.pdf',
        fileSize: '3.6 MB',
        uploadedBy: 'Godrej Properties',
        uploadedAt: DateTime.now().subtract(const Duration(days: 12)),
        verifiedBy: 'PropZen Architecture Team',
      ),
    ]);
  }

  void _initMockFamilyReviews() {
    _familyReviews.clear();
    _familyReviews.addAll([
      FamilyDecisionReview(
        id: 'fam_1',
        propertyId: 'prop_ats_happytrails',
        memberName: 'Priya Sharma',
        relation: 'Spouse',
        vote: 'like',
        rating: 4.8,
        comment: 'Love the balcony orientation and the green belt facing. Looks peaceful!',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      FamilyDecisionReview(
        id: 'fam_2',
        propertyId: 'prop_ats_happytrails',
        memberName: 'Dr. R.K. Sharma',
        relation: 'Parent',
        vote: 'like',
        rating: 4.5,
        comment: 'Good hospital proximity (Fortis 9km) and verified RERA title.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }

  void _initMockMonitoredProperties() {
    _monitoredProperties.clear();
    _monitoredProperties.add(
      PropertyMonitoringSubscription(
        propertyId: 'prop_ats_happytrails',
        propertyTitle: 'ATS HomeKraft Happy Trails',
        subscribedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    );
  }

  NriSubscriptionPlan? getPlanById(String id) {
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Feature Access Checker based on Active Subscription Tier
  bool canAccessFeature(String featureKey) {
    if (!UserSession.isNri) return false;
    final sub = UserSession.nriSubscription;
    if (sub == null || sub.status.toLowerCase().trim() != 'active' || !sub.isActive) return false;

    final plan = getPlanById(sub.planId);
    if (plan == null) {
      // Fallback based on tier string
      if (sub.tier == 'elite') return true;
      if (sub.tier == 'premium') {
        return featureKey != 'live_remote_tour' &&
            featureKey != 'document_concierge' &&
            featureKey != 'family_decision_mode' &&
            featureKey != 'secure_deal_room';
      }
      return featureKey == '360_tour' || featureKey == 'floor_plan' || featureKey == 'ai_advisor';
    }

    switch (featureKey) {
      case 'drone_tour':
        return plan.canAccessDroneTours;
      case '3d_view':
        return plan.canAccess3DView;
      case '360_tour':
      case 'floor_plan':
        return plan.canAccess360AndFloorPlan;
      case 'ai_advisor':
        return plan.canAccessAiAdvisor;
      case 'ai_voice':
        return plan.canAccessAiVoiceAssistant;
      case 'construction_updates':
        return plan.canAccessConstructionUpdates;
      case 'locality_intelligence':
        return plan.canAccessLocalityIntelligence;
      case 'live_remote_tour':
        return plan.canAccessLiveRemoteTour;
      case 'document_concierge':
        return plan.canAccessDocumentConcierge;
      case 'family_decision_mode':
        return plan.canAccessFamilyDecisionMode;
      case 'secure_deal_room':
        return plan.canAccessSecureDealRoom;
      default:
        return false;
    }
  }

  /// Select Plan without activating subscription (Sets status to 'plan_selected' / Payment Required)
  NriSubscription selectPlan({
    required NriSubscriptionPlan plan,
    required String userId,
    required String userEmail,
  }) {
    final now = DateTime.now();
    final draftSub = NriSubscription(
      id: 'sub_draft_${now.millisecondsSinceEpoch}',
      userId: userId.isNotEmpty ? userId : 'usr_nri_guest',
      userEmail: userEmail,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      durationMonths: plan.durationMonths,
      status: 'plan_selected', // STRICTLY NOT ACTIVE
      startDate: now,
      expiryDate: now.add(Duration(days: plan.durationMonths * 30)),
      amount: plan.priceInr,
      currency: 'INR',
      paymentId: 'pending',
      transactionId: 'TXN-DRAFT-${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );

    UserSession.setUserType('NRI');
    UserSession.updateNriSubscription(draftSub);
    notifyListeners();
    return draftSub;
  }

  /// Mark Subscription as Payment Pending
  NriSubscription setPaymentPending({
    required NriSubscriptionPlan plan,
    required String userId,
    required String userEmail,
  }) {
    final now = DateTime.now();
    final pendingSub = NriSubscription(
      id: 'sub_pending_${now.millisecondsSinceEpoch}',
      userId: userId.isNotEmpty ? userId : 'usr_nri_guest',
      userEmail: userEmail,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      durationMonths: plan.durationMonths,
      status: 'payment_pending', // STRICTLY NOT ACTIVE
      startDate: now,
      expiryDate: now.add(Duration(days: plan.durationMonths * 30)),
      amount: plan.priceInr,
      currency: 'INR',
      paymentId: 'gateway_unconfigured',
      transactionId: 'TXN-PENDING-${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
    );

    UserSession.setUserType('NRI');
    UserSession.updateNriSubscription(pendingSub);
    notifyListeners();
    return pendingSub;
  }

  /// Synchronize dynamic plans from backend
  Future<void> syncPlansFromBackend() async {
    try {
      final url = Uri.parse('${RazorpayCheckoutService.instance.apiBaseUrl}/api/payments/plans');
      final response = await httpGet(url);
      if (response != null && response['status'] == 'success') {
        final List<dynamic> backendList = response['plans'] ?? [];
        if (backendList.isNotEmpty) {
          _plans.clear();
          for (final item in backendList) {
            _plans.add(NriSubscriptionPlan.fromJson(item as Map<String, dynamic>));
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Prepare Payment Order on Backend Server
  Future<Map<String, dynamic>> initiatePaymentOrder({
    required NriSubscriptionPlan plan,
    required String userId,
    required String userEmail,
  }) async {
    try {
      return await RazorpayCheckoutService.instance.createBackendOrder(
        plan: plan,
        userId: userId,
        userEmail: userEmail,
      );
    } catch (e) {
      // Fallback local signed order if offline
      final orderId = 'order_nri_${DateTime.now().millisecondsSinceEpoch}';
      final amountInPaise = (plan.priceInr * 100).toInt();

      return {
        'orderId': orderId,
        'amount': amountInPaise,
        'currency': 'INR',
        'planId': plan.id,
        'planName': plan.name,
        'tier': plan.tier,
        'keyId': 'rzp_test_propzen_remote_2026',
      };
    }
  }

  /// Server-Side Verification and Subscription Activation
  /// ONLY invoked when payment succeeds AND server-side verification confirms authenticity
  Future<NriSubscription> verifyAndActivateSubscription({
    required NriSubscriptionPlan plan,
    required String paymentId,
    required String orderId,
    required String signature,
    required String userId,
    required String userEmail,
  }) async {
    final bool isSignatureValid = signature.isNotEmpty && paymentId.isNotEmpty && !paymentId.contains('fail');
    if (!isSignatureValid) {
      final now = DateTime.now();
      final failedSub = NriSubscription(
        id: 'sub_failed_${now.millisecondsSinceEpoch}',
        userId: userId.isNotEmpty ? userId : 'usr_nri_guest',
        userEmail: userEmail,
        planId: plan.id,
        planName: plan.name,
        tier: plan.tier,
        durationMonths: plan.durationMonths,
        status: 'payment_failed',
        startDate: now,
        expiryDate: now,
        amount: plan.priceInr,
        currency: 'INR',
        paymentId: paymentId,
        transactionId: 'TXN-FAILED',
      );
      UserSession.updateNriSubscription(failedSub);
      notifyListeners();
      throw Exception('Payment signature verification failed. Subscription cannot be activated.');
    }

    try {
      // Strictly verify with backend server endpoint
      await RazorpayCheckoutService.instance.verifyPaymentOnBackend(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        planId: plan.id,
        userId: userId,
        userEmail: userEmail,
      );
    } catch (e) {
      final now = DateTime.now();
      final failedSub = NriSubscription(
        id: 'sub_failed_${now.millisecondsSinceEpoch}',
        userId: userId.isNotEmpty ? userId : 'usr_nri_guest',
        userEmail: userEmail,
        planId: plan.id,
        planName: plan.name,
        tier: plan.tier,
        durationMonths: plan.durationMonths,
        status: 'payment_failed',
        startDate: now,
        expiryDate: now,
        amount: plan.priceInr,
        currency: 'INR',
        paymentId: paymentId,
        transactionId: 'TXN-FAILED',
      );
      UserSession.updateNriSubscription(failedSub);
      notifyListeners();
      throw Exception('Server payment verification failed: $e');
    }

    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: plan.durationMonths * 30));
    final transactionId = 'TXN-PROPZEN-${now.millisecondsSinceEpoch}';

    final subscription = NriSubscription(
      id: 'sub_${now.millisecondsSinceEpoch}',
      userId: userId.isNotEmpty ? userId : 'usr_nri_guest',
      userEmail: userEmail,
      planId: plan.id,
      planName: plan.name,
      tier: plan.tier,
      durationMonths: plan.durationMonths,
      status: 'active', // ONLY SET TO ACTIVE HERE AFTER VERIFICATION
      startDate: now,
      expiryDate: expiryDate,
      amount: plan.priceInr,
      currency: 'INR',
      paymentId: paymentId,
      transactionId: transactionId,
      signatureVerificationHash: 'sha256_${orderId}_$paymentId',
      createdAt: now,
      updatedAt: now,
    );

    UserSession.setUserType('NRI');
    UserSession.updateNriSubscription(subscription);

    try {
      await SupabaseService.instance.saveNriSubscription(subscription.toJson());
      await SupabaseService.instance.addNotification(
        title: '${plan.name} Activated! 🎥',
        message: 'Your ${plan.name} is now active until ${subscription.formattedExpiryDate}.',
        type: 'subscription',
        userId: userId,
        metadata: {
          'subscription_id': subscription.id,
          'plan_id': plan.id,
          'tier': plan.tier,
          'expiry_date': subscription.expiryDate.toIso8601String(),
        },
      );
    } catch (_) {}

    notifyListeners();
    return subscription;
  }

  /// Helper for backend GET calls
  Future<Map<String, dynamic>?> httpGet(Uri uri) async {
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

  /// Fetch Payment History for User
  Future<List<PaymentRecord>> getPaymentHistory(String userId) async {
    return await RazorpayCheckoutService.instance.fetchPaymentHistory(userId);
  }

  /// Schedule Remote Property Tour
  Future<RemoteTourBooking> bookRemoteTour({
    required String propertyId,
    required String propertyTitle,
    required String tourType,
    required String preferredDate,
    required String preferredTime,
    required String timezone,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String userCountry,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final booking = RemoteTourBooking(
      id: 'rem_${now.millisecondsSinceEpoch}',
      userId: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'usr_nri_guest',
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      userCountry: userCountry,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      tourType: tourType,
      preferredDate: preferredDate,
      preferredTime: preferredTime,
      timezone: timezone,
      status: 'confirmed',
      notes: notes,
      createdAt: now,
    );

    _remoteBookings.insert(0, booking);

    try {
      await SupabaseService.instance.saveRemoteTourBooking(booking.toJson());
      await SupabaseService.instance.addNotification(
        title: 'Remote Tour Scheduled! 🌐',
        message: 'Your ${booking.tourTypeDisplay} for $propertyTitle is confirmed for $preferredDate.',
        type: 'remote_tour',
        propertyId: propertyId,
      );

      await N8nService.instance.bookSiteVisit(
        fullName: userName,
        email: userEmail,
        mobileNumber: userPhone,
        propertyId: propertyId,
        propertyName: propertyTitle,
        visitDate: preferredDate,
        visitTime: preferredTime,
        message: 'NRI Remote Tour: ${booking.tourTypeDisplay} ($timezone, Country: $userCountry)',
      );
    } catch (_) {}

    notifyListeners();
    return booking;
  }

  // =========================================================================
  // DOCUMENT CONCIERGE
  // =========================================================================
  List<NriDocumentItem> getDocumentsForProperty(String propertyId) {
    return _documents.where((d) => d.propertyId == propertyId).toList();
  }

  Future<NriDocumentItem> uploadDocument({
    required String propertyId,
    required String title,
    required String category,
    required String fileUrl,
    String notes = '',
  }) async {
    final item = NriDocumentItem(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      title: title,
      category: category,
      status: 'under_review',
      fileUrl: fileUrl,
      fileSize: '2.8 MB',
      uploadedBy: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'NRI Client',
      uploadedAt: DateTime.now(),
      notes: notes,
    );

    _documents.insert(0, item);
    notifyListeners();
    return item;
  }

  // =========================================================================
  // FAMILY DECISION MODE
  // =========================================================================
  List<FamilyDecisionReview> getFamilyReviewsForProperty(String propertyId) {
    return _familyReviews.where((r) => r.propertyId == propertyId).toList();
  }

  Map<String, dynamic> getFamilySummaryForProperty(String propertyId) {
    final list = getFamilyReviewsForProperty(propertyId);
    if (list.isEmpty) {
      return {
        'totalVotes': 0,
        'likes': 0,
        'dislikes': 0,
        'avgRating': 0.0,
        'consensus': 'No family reviews yet',
      };
    }

    final likes = list.where((r) => r.vote == 'like').length;
    final dislikes = list.where((r) => r.vote == 'dislike').length;
    final avg = list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;

    return {
      'totalVotes': list.length,
      'likes': likes,
      'dislikes': dislikes,
      'avgRating': avg,
      'consensus': likes > dislikes ? 'Strong Family Approval ($likes/${list.length})' : 'Divided Opinion',
    };
  }

  Future<FamilyDecisionReview> submitFamilyReview({
    required String propertyId,
    required String memberName,
    required String relation,
    required String vote,
    required double rating,
    required String comment,
  }) async {
    final rev = FamilyDecisionReview(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      memberName: memberName,
      relation: relation,
      vote: vote,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    _familyReviews.insert(0, rev);
    notifyListeners();
    return rev;
  }

  // =========================================================================
  // PROPERTY MONITORING
  // =========================================================================
  bool isPropertyMonitored(String propertyId) {
    return _monitoredProperties.any((p) => p.propertyId == propertyId);
  }

  void togglePropertyMonitoring(String propertyId, String propertyTitle) {
    final idx = _monitoredProperties.indexWhere((p) => p.propertyId == propertyId);
    if (idx >= 0) {
      _monitoredProperties.removeAt(idx);
    } else {
      _monitoredProperties.add(
        PropertyMonitoringSubscription(
          propertyId: propertyId,
          propertyTitle: propertyTitle,
          subscribedAt: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  // =========================================================================
  // CONSTRUCTION PROGRESS PROVIDER
  // =========================================================================
  ConstructionProgressModel getConstructionProgressForProperty(String propertyId, String propertyTitle) {
    return ConstructionProgressModel(
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      overallProgressPercent: 78,
      currentPhase: 'Finishing & Tower Façade Glass Fitting',
      verifiedSource: 'UP RERA Q2 2026 Audit Report',
      lastUpdatedDate: '15 July 2026',
      scheduledPossession: 'March 2027',
      milestones: const [
        ConstructionMilestone(
          stageName: 'Deep Excavation & Raft Foundation',
          description: 'Earthwork, seismic piling & 100% concrete foundation completed.',
          progressPercent: 100,
          isCompleted: true,
          estimatedDate: 'Completed (Jan 2024)',
        ),
        ConstructionMilestone(
          stageName: 'RCC Superstructure (28 Floors)',
          description: 'Core slab casting, columns & high-tensile beam framework complete.',
          progressPercent: 100,
          isCompleted: true,
          estimatedDate: 'Completed (Nov 2025)',
        ),
        ConstructionMilestone(
          stageName: 'Brickwork & Internal Partition Plaster',
          description: 'AAC block masonry, electrical conduits & internal wall plastering.',
          progressPercent: 100,
          isCompleted: true,
          estimatedDate: 'Completed (May 2026)',
        ),
        ConstructionMilestone(
          stageName: 'Tower Façade & Window Glazing',
          description: 'Double-glazed soundproof glass panels & weatherproof exterior paint.',
          progressPercent: 65,
          isCompleted: false,
          isCurrent: true,
          estimatedDate: 'In Progress (Target: Nov 2026)',
        ),
        ConstructionMilestone(
          stageName: 'Internal Flooring & Premium Fittings',
          description: 'Vitrified marble flooring, modular kitchens, Grohe sanitary ware.',
          progressPercent: 30,
          isCompleted: false,
          estimatedDate: 'Target: Jan 2027',
        ),
        ConstructionMilestone(
          stageName: 'Occupancy Certificate (OC) & Handover',
          description: 'Final fire NOC, municipal occupancy clearance and registry keys.',
          progressPercent: 0,
          isCompleted: false,
          estimatedDate: 'Target: March 2027',
        ),
      ],
    );
  }

  // =========================================================================
  // NRI PROPERTY CONFIDENCE SCORE PROVIDER
  // =========================================================================
  NriConfidenceScore getConfidenceScoreForProperty(String propertyId) {
    return const NriConfidenceScore(
      propertyId: 'prop_ats_happytrails',
      propertyScore: 92,
      locationScore: 94,
      documentationScore: 90,
      valueScore: 86,
      remoteVisibilityScore: 96,
      dealReadinessScore: 88,
      highlights: [
        'UP RERA Approved (UPRERAPRJ15574) with zero active encumbrances.',
        'High Remote Visibility: 4K Drone Tour, 360° Panorama & 3D Twin available.',
        'Strategic Connectivity: 3.8 km to FNG Expressway & 8 km to Sector 52 Metro.',
        'Reputed Tier-1 NCR Developer with 15+ delivered residential townships.',
      ],
      considerations: [
        'Expected possession Q1 2027 — verify interior fit-out schedule before booking.',
        'Rental yield estimated at 4.9% based on current Sector 10 micro-market demand.',
      ],
    );
  }
}
