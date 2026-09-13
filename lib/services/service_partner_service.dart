import 'package:flutter/foundation.dart';
import '../models/service_request_model.dart';
import '../models/service_partner_profile.dart';
import 'supabase_service.dart';

class ServicePartnerService extends ChangeNotifier {
  ServicePartnerService._internal();
  static final ServicePartnerService instance = ServicePartnerService._internal();
  factory ServicePartnerService() => instance;

  final List<ServiceRequest> _requests = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  ServicePartnerProfile? _currentProfile;
  ServiceCategoryType? _activeCategory;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  List<ServiceRequest> get allRequests => List.unmodifiable(_requests);
  ServicePartnerProfile? get currentProfile => _currentProfile;
  ServiceCategoryType? get activeCategory => _activeCategory;
  bool get isApprovedPartner => _currentProfile?.isApproved ?? false;

  /// Set the active partner profile
  void setCurrentProfile(ServicePartnerProfile? profile) {
    _currentProfile = profile;
    if (profile != null && profile.approvedCategoryTypes.isNotEmpty) {
      if (_activeCategory == null || !profile.canProvide(_activeCategory!)) {
        _activeCategory = profile.approvedCategoryTypes.first;
      }
    } else {
      _activeCategory = null;
    }
    notifyListeners();
  }

  /// Switch the active specialized category (restricted to approved categories)
  bool setActiveCategory(ServiceCategoryType category) {
    if (_currentProfile != null && !_currentProfile!.canProvide(category)) {
      debugPrint('[ServicePartnerService] Warning: Partner not authorized for category ${category.name}');
      return false;
    }
    _activeCategory = category;
    notifyListeners();
    return true;
  }

  /// Load service requests filtered strictly for a partner profile
  Future<void> loadForProfile(ServicePartnerProfile profile) async {
    setCurrentProfile(profile);
    _isLoading = true;
    notifyListeners();

    try {
      // Unapproved / pending / suspended partners must NOT receive or see any customer service requests
      if (!profile.isApproved) {
        _requests.clear();
        return;
      }
      final rows = await SupabaseService.instance.getServiceRequestsForPartner(
        partnerId: profile.id,
        approvedCategoryCodes: profile.approvedCategories,
      );
      _requests.clear();
      for (final r in rows) {
        _requests.add(ServiceRequest.fromJson(r));
      }
    } catch (e) {
      debugPrint('[ServicePartnerService] loadForProfile notice: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Load service requests from backend
  Future<void> loadFromBackend() async {
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await SupabaseService.instance.getServiceRequests();
      if (rows.isNotEmpty) {
        _requests.clear();
        for (final r in rows) {
          _requests.add(ServiceRequest.fromJson(r));
        }
      }
    } catch (e) {
      debugPrint('[ServicePartnerService] loadFromBackend notice: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // =========================================================================
  // BUYER FACING METHODS
  // =========================================================================

  /// Create a new service request from a Buyer
  Future<ServiceRequest> createServiceRequest({
    required ServiceCategoryType category,
    required String subCategory,
    required String title,
    required String description,
    String? propertyId,
    String? propertyTitle,
    String? propertyAddress,
    double? propertyPriceCr,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    double estimatedPrice = 0.0,
    List<String> requiredDocuments = const [],
  }) async {
    final now = DateTime.now();
    final uniqueId = 'SR-${now.millisecondsSinceEpoch.toString().substring(7)}';

    // Build standard initial milestones for the category
    final initialMilestones = _buildDefaultMilestonesForCategory(category, estimatedPrice);

    final newReq = ServiceRequest(
      id: 'req_${now.millisecondsSinceEpoch}',
      serviceNumber: uniqueId,
      category: category,
      subCategory: subCategory,
      title: title,
      description: description,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      propertyAddress: propertyAddress,
      propertyPriceCr: propertyPriceCr,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      status: ServiceStatus.requested,
      createdAt: now,
      updatedAt: now,
      estimatedPrice: estimatedPrice,
      paidAmount: 0.0,
      milestones: initialMilestones,
      documents: const [],
      requiredDocumentsList: requiredDocuments.isNotEmpty ? requiredDocuments : _defaultRequiredDocsForCategory(category),
    );

    _requests.insert(0, newReq);
    notifyListeners();

    // Persist to Supabase if available
    try {
      await SupabaseService.instance.saveServiceRequest(newReq.toJson());
    } catch (e) {
      debugPrint('[ServicePartnerService] Error saving request to Supabase: $e');
    }

    return newReq;
  }

  /// Get all requests submitted by a specific Buyer
  List<ServiceRequest> getRequestsForBuyer(String buyerIdentifier) {
    final clean = buyerIdentifier.trim().toLowerCase();
    if (clean.isEmpty) return [];

    return _requests.where((r) {
      return r.customerId.toLowerCase() == clean ||
          r.customerEmail.toLowerCase() == clean ||
          r.customerPhone.replaceAll(RegExp(r'[^0-9]'), '') == clean.replaceAll(RegExp(r'[^0-9]'), '');
    }).toList();
  }

  /// Buyer submits feedback & rating on a completed service
  Future<bool> submitFeedback({
    required String requestId,
    required int rating,
    required String comment,
    required String buyerName,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final fb = ServiceFeedback(
      rating: rating.clamp(1, 5),
      comment: comment,
      submittedAt: DateTime.now(),
      buyerName: buyerName,
    );

    _requests[index] = _requests[index].copyWith(
      feedback: fb,
      status: ServiceStatus.closed,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  /// Buyer or Partner uploads a document
  Future<bool> uploadDocument({
    required String requestId,
    required String title,
    required String fileName,
    required String fileUrl,
    String fileType = 'PDF',
    required String uploadedBy, // 'BUYER' or 'SERVICE_PARTNER'
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    final doc = ServiceDocument(
      id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      fileName: fileName,
      fileUrl: fileUrl,
      fileType: fileType,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
      isVerified: uploadedBy == 'SERVICE_PARTNER',
    );

    final updatedDocs = List<ServiceDocument>.from(_requests[index].documents)..add(doc);

    // If buyer uploaded documents when status was DOCUMENTS_REQUIRED, advance to IN_PROGRESS
    ServiceStatus newStatus = _requests[index].status;
    if (uploadedBy == 'BUYER' && newStatus == ServiceStatus.documentsRequired) {
      newStatus = ServiceStatus.inProgress;
    }

    _requests[index] = _requests[index].copyWith(
      documents: updatedDocs,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  // =========================================================================
  // SERVICE PARTNER FACING METHODS (Strict Tenant Isolation)
  // =========================================================================

  /// Get requests assigned to this specific Service Partner (strictly category isolated)
  List<ServiceRequest> getRequestsForPartner(String partnerId, {ServiceCategoryType? category}) {
    if (_currentProfile != null && !_currentProfile!.isApproved) {
      return [];
    }
    final clean = partnerId.trim().toLowerCase();
    if (clean.isEmpty) return [];

    return _requests.where((r) {
      final matchesPartner = (r.partnerId != null && r.partnerId!.toLowerCase() == clean);
      if (!matchesPartner) return false;
      if (category != null) {
        return r.category == category;
      }
      if (_currentProfile != null) {
        return _currentProfile!.canProvide(r.category);
      }
      return true;
    }).toList();
  }

  /// Get unassigned requests or requests matching the category
  List<ServiceRequest> getAvailableRequestsForCategory({
    ServiceCategoryType? category,
    String? currentPartnerId,
  }) {
    if (_currentProfile != null && !_currentProfile!.isApproved) {
      return [];
    }
    final targetCategory = category ?? _activeCategory;
    if (targetCategory == null) return [];

    // Security check: if current profile exists and cannot provide this category, return empty list!
    if (_currentProfile != null && !_currentProfile!.canProvide(targetCategory)) {
      return [];
    }

    final cleanPartnerId = (currentPartnerId ?? '').trim().toLowerCase();

    return _requests.where((r) {
      if (r.category != targetCategory) return false;
      // Show if unassigned or already assigned to this partner
      final pId = (r.partnerId ?? '').toLowerCase();
      return pId.isEmpty || pId == cleanPartnerId;
    }).toList();
  }

  /// Service Partner accepts an incoming service request
  Future<bool> acceptServiceRequest({
    required String requestId,
    required String partnerId,
    required String partnerName,
    String? partnerCompany,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    // Security & Specialization authorization guards
    if (_currentProfile != null) {
      if (!_currentProfile!.isApproved) {
        debugPrint('[ServicePartnerService] Security Reject: Partner ${_currentProfile!.id} is not approved');
        return false;
      }
      if (!_currentProfile!.canProvide(_requests[index].category)) {
        debugPrint('[ServicePartnerService] Security Reject: Partner ${_currentProfile!.id} not authorized for ${_requests[index].category.code}');
        return false;
      }
    }

    _requests[index] = _requests[index].copyWith(
      partnerId: partnerId,
      partnerName: partnerName,
      partnerCompany: partnerCompany,
      status: ServiceStatus.accepted,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  /// Service Partner rejects an incoming request
  Future<bool> rejectServiceRequest({
    required String requestId,
    String? reason,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    // Security & Specialization authorization guards
    if (_currentProfile != null) {
      if (!_currentProfile!.isApproved) {
        debugPrint('[ServicePartnerService] Security Reject: Partner is not approved');
        return false;
      }
      if (!_currentProfile!.canProvide(_requests[index].category)) {
        return false;
      }
    }

    _requests[index] = _requests[index].copyWith(
      status: ServiceStatus.closed,
      description: reason != null ? '${_requests[index].description}\n[Declined: $reason]' : _requests[index].description,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  /// Admin reassigns a service request to a different partner
  Future<bool> reassignServiceRequest({
    required String requestId,
    required String newPartnerId,
    required String newPartnerName,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    _requests[index] = _requests[index].copyWith(
      partnerId: newPartnerId,
      partnerName: newPartnerName,
      status: ServiceStatus.accepted,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  /// Get distinct customer profiles serviced by this partner in this category
  List<Map<String, dynamic>> getCustomersForPartner(String partnerId, {ServiceCategoryType? category}) {
    final reqs = getRequestsForPartner(partnerId, category: category);
    final seen = <String>{};
    final customers = <Map<String, dynamic>>[];
    for (final r in reqs) {
      final key = r.customerEmail.isNotEmpty ? r.customerEmail : r.customerId;
      if (seen.add(key)) {
        customers.add({
          'id': r.customerId,
          'name': r.customerName,
          'phone': r.customerPhone,
          'email': r.customerEmail,
          'latestRequest': r.title,
          'status': r.status.label,
          'propertyTitle': r.propertyTitle ?? 'N/A',
          'date': r.createdAt,
        });
      }
    }
    return customers;
  }

  /// Service Partner transitions service to the next lifecycle stage
  Future<bool> updateServiceStatus({
    required String requestId,
    required ServiceStatus newStatus,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    // Security & Specialization authorization guards
    if (_currentProfile != null) {
      if (!_currentProfile!.isApproved) {
        debugPrint('[ServicePartnerService] Security Reject: Partner is not approved');
        return false;
      }
      if (!_currentProfile!.canProvide(_requests[index].category)) {
        debugPrint('[ServicePartnerService] Security Reject: Category not authorized');
        return false;
      }
    }

    _requests[index] = _requests[index].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  /// Toggle or complete a milestone
  Future<bool> toggleMilestone({
    required String requestId,
    required String milestoneId,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    // Security & Specialization authorization guards
    if (_currentProfile != null) {
      if (!_currentProfile!.isApproved) return false;
      if (!_currentProfile!.canProvide(_requests[index].category)) return false;
    }

    final milestones = List<ServiceMilestone>.from(_requests[index].milestones);
    final mIndex = milestones.indexWhere((m) => m.id == milestoneId);
    if (mIndex == -1) return false;

    final current = milestones[mIndex];
    final updated = current.copyWith(
      isCompleted: !current.isCompleted,
      completedAt: !current.isCompleted ? DateTime.now() : null,
    );
    milestones[mIndex] = updated;

    // Recalculate paid amount from completed milestones
    double newPaid = 0.0;
    for (final m in milestones) {
      if (m.isCompleted) newPaid += m.amount;
    }

    // If all milestones completed, update status to approvalPending or completed
    ServiceStatus updatedStatus = _requests[index].status;
    final allCompleted = milestones.every((m) => m.isCompleted);
    if (allCompleted && updatedStatus != ServiceStatus.completed && updatedStatus != ServiceStatus.closed) {
      updatedStatus = ServiceStatus.approvalPending;
    }

    _requests[index] = _requests[index].copyWith(
      milestones: milestones,
      paidAmount: newPaid,
      status: updatedStatus,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  /// Add custom milestone
  Future<bool> addMilestone({
    required String requestId,
    required String title,
    String description = '',
    double amount = 0.0,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return false;

    // Security & Specialization authorization guards
    if (_currentProfile != null) {
      if (!_currentProfile!.isApproved) return false;
      if (!_currentProfile!.canProvide(_requests[index].category)) return false;
    }

    final milestones = List<ServiceMilestone>.from(_requests[index].milestones);
    milestones.add(ServiceMilestone(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      orderIndex: milestones.length,
    ));

    _requests[index] = _requests[index].copyWith(
      milestones: milestones,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await SupabaseService.instance.updateServiceRequest(_requests[index].toJson());
    } catch (_) {}

    return true;
  }

  // =========================================================================
  // METRICS & KPIS (Strictly Zero Hardcoded Data)
  // =========================================================================

  int getTotalRequestsCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category).length;
  }

  int getNewRequestsCount(String partnerId, {ServiceCategoryType? category}) {
    if (category != null) {
      return getAvailableRequestsForCategory(category: category, currentPartnerId: partnerId)
          .where((r) => r.status == ServiceStatus.requested)
          .length;
    }
    return getRequestsForPartner(partnerId).where((r) => r.status == ServiceStatus.requested).length;
  }

  int getActiveServicesCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category).where((r) => r.isActive && r.status != ServiceStatus.requested).length;
  }

  int getPendingCustomerActionsCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category)
        .where((r) => r.status == ServiceStatus.awaitingCustomer || r.status == ServiceStatus.documentsRequired)
        .length;
  }

  int getDocumentsPendingCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category).where((r) => r.status == ServiceStatus.documentsRequired).length;
  }

  int getInProgressCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category).where((r) => r.status == ServiceStatus.inProgress).length;
  }

  int getCompletedCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category).where((r) => r.isCompleted || r.status == ServiceStatus.closed).length;
  }

  int getCancelledCount(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category).where((r) => r.status == ServiceStatus.closed && r.feedback == null).length;
  }

  double getTotalEarnings(String partnerId, {ServiceCategoryType? category}) {
    final list = getRequestsForPartner(partnerId, category: category);
    double sum = 0.0;
    for (final r in list) {
      sum += r.paidAmount;
    }
    return sum;
  }

  double getAverageRating(String partnerId, {ServiceCategoryType? category}) {
    final list = getRequestsForPartner(partnerId, category: category).where((r) => r.feedback != null).toList();
    if (list.isEmpty) return 0.0;
    double sum = 0.0;
    for (final r in list) {
      sum += r.feedback!.rating;
    }
    return double.parse((sum / list.length).toStringAsFixed(1));
  }

  List<ServiceFeedback> getPartnerFeedbackList(String partnerId, {ServiceCategoryType? category}) {
    return getRequestsForPartner(partnerId, category: category)
        .where((r) => r.feedback != null)
        .map((r) => r.feedback!)
        .toList();
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  List<ServiceMilestone> _buildDefaultMilestonesForCategory(ServiceCategoryType category, double estimatedPrice) {
    final share = estimatedPrice > 0 ? estimatedPrice / 3 : 0.0;
    switch (category) {
      case ServiceCategoryType.loan:
        return [
          ServiceMilestone(id: 'm_1', title: 'Eligibility & Document Collection', amount: share, orderIndex: 0),
          ServiceMilestone(id: 'm_2', title: 'Bank Application Submission', amount: share, orderIndex: 1),
          ServiceMilestone(id: 'm_3', title: 'Sanction Letter & Disbursement', amount: share, orderIndex: 2),
        ];
      case ServiceCategoryType.homeDesign:
        return [
          ServiceMilestone(id: 'm_1', title: '2D Floor Plan & Concept Layout', amount: share, orderIndex: 0),
          ServiceMilestone(id: 'm_2', title: '3D Photorealistic Renderings', amount: share, orderIndex: 1),
          ServiceMilestone(id: 'm_3', title: 'Final Blueprint & Material Specification', amount: share, orderIndex: 2),
        ];
      case ServiceCategoryType.vastu:
        return [
          ServiceMilestone(id: 'm_1', title: 'Plot & Layout Analysis', amount: share, orderIndex: 0),
          ServiceMilestone(id: 'm_2', title: 'Directional Energy Audit & Recommendations', amount: share, orderIndex: 1),
          ServiceMilestone(id: 'm_3', title: 'Remedial Plan & Follow-Up Session', amount: share, orderIndex: 2),
        ];
      case ServiceCategoryType.construction:
        return [
          ServiceMilestone(id: 'm_1', title: 'Structural Assessment & BOQ Estimate', amount: share, orderIndex: 0),
          ServiceMilestone(id: 'm_2', title: 'Phase 1 Construction & Milestone Audit', amount: share, orderIndex: 1),
          ServiceMilestone(id: 'm_3', title: 'Quality Signoff & Completion Handover', amount: share, orderIndex: 2),
        ];
      case ServiceCategoryType.propertyVerification:
        return [
          ServiceMilestone(id: 'm_1', title: 'Title Deed & Encumbrance Verification', amount: share, orderIndex: 0),
          ServiceMilestone(id: 'm_2', title: 'RERA Compliance & Municipal Audit', amount: share, orderIndex: 1),
          ServiceMilestone(id: 'm_3', title: 'Institutional Legal Verification Report', amount: share, orderIndex: 2),
        ];
      case ServiceCategoryType.visualization:
        return [
          ServiceMilestone(id: 'm_1', title: 'Site Drone Capture / Laser Scanning', amount: share, orderIndex: 0),
          ServiceMilestone(id: 'm_2', title: '3D Model Stitching & Interactive Tour Generation', amount: share, orderIndex: 1),
          ServiceMilestone(id: 'm_3', title: '4K VR Delivery & Cloud Hosting', amount: share, orderIndex: 2),
        ];
    }
  }

  List<String> _defaultRequiredDocsForCategory(ServiceCategoryType category) {
    switch (category) {
      case ServiceCategoryType.loan:
        return ['Identity Proof (Aadhaar / Passport)', 'Income Proof (3 Months Salary Slips)', 'Bank Statement (6 Months)'];
      case ServiceCategoryType.homeDesign:
        return ['Floor Plan Drawing', 'Current Site Photos', 'Design Preferences / Moodboard'];
      case ServiceCategoryType.vastu:
        return ['Architectural Floor Plan with North Pointer', 'Plot Layout Map'];
      case ServiceCategoryType.construction:
        return ['Site Survey Report', 'Architectural Drawings', 'Soil Testing Report'];
      case ServiceCategoryType.propertyVerification:
        return ['Sale Deed / Title Document', 'Encumbrance Certificate (EC)', 'Latest Tax Receipt'];
      case ServiceCategoryType.visualization:
        return ['Location Coordinates', 'Site Permission Pass'];
    }
  }

  /// Clean state for testing or logout
  void resetState() {
    _requests.clear();
    _currentProfile = null;
    _activeCategory = null;
    _isInitialized = false;
    _isLoading = false;
    notifyListeners();
  }
}
