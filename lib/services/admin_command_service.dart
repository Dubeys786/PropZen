import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';
import '../models/property.dart';
import '../models/service_partner_profile.dart';
import 'property_state_service.dart';
import 'dealer_lead_service.dart';
import 'supabase_service.dart';
import '../crm/services/crm_api_client.dart';

class AdminCommandService extends ChangeNotifier {
  static final AdminCommandService instance = AdminCommandService._internal();
  factory AdminCommandService() => instance;

  AdminCommandService._internal() {
    _initializeDefaultData();
  }

  // Active Admin Profile
  AdminUser _currentAdmin = AdminUser(
    id: 'ADM-MASTER-001',
    name: 'PropZen Administrator',
    email: 'admin@propzen.ai',
    role: AdminRole.superAdmin,
    lastLoginAt: DateTime.now().toIso8601String(),
  );

  AdminUser get currentAdmin => _currentAdmin;
  AdminRole get currentRole => _currentAdmin.role;
  AdminPermissions get permissions => _currentAdmin.permissions;

  void switchRole(AdminRole newRole) {
    _currentAdmin = AdminUser(
      id: _currentAdmin.id,
      name: _currentAdmin.name,
      email: _currentAdmin.email,
      role: newRole,
      lastLoginAt: _currentAdmin.lastLoginAt,
    );
    notifyListeners();
  }

  /// Real-time live data loader from Supabase backend
  Future<void> loadFromSupabase() async {
    try {
      debugPrint('[AdminCommandService] Fetching real data from Supabase backend...');

      // 1. Fetch live Users
      final rawUsers = await SupabaseService.instance.fetchUsers();
      if (rawUsers.isNotEmpty) {
        _users = rawUsers.map((u) => UserAccountModel.fromMap(u)).toList();
      }

      // 2. Fetch live Dealers
      final rawDealers = await SupabaseService.instance.fetchDealers();
      if (rawDealers != null && rawDealers.isNotEmpty) {
        _dealers = rawDealers.map((d) => DealerAccountModel.fromMap(d)).toList();
      }

      // 3. Fetch live Administrators
      final rawAdmins = await SupabaseService.instance.fetchAdminAccounts();
      if (rawAdmins.isNotEmpty) {
        _administrators = rawAdmins.map((a) => AdminUser.fromMap(a)).toList();
      }

      // 4. Fetch live Properties
      final rawProps = await SupabaseService.instance.fetchAdminProperties();
      if (rawProps.isNotEmpty) {
        PropertyStateService.instance.setProperties(rawProps);
      }

      // 5. Fetch live Notifications
      final rawNotifs = await SupabaseService.instance.fetchNotifications();
      if (rawNotifs.isNotEmpty) {
        _notifications = rawNotifs.map((n) => AdminBroadcastNotification.fromMap(n)).toList();
      }

      // 6. Fetch live Service Partners
      final rawPartners = await SupabaseService.instance.getAllServicePartnerProfiles();
      if (rawPartners.isNotEmpty) {
        _servicePartners = List.from(rawPartners);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[AdminCommandService] Error loading from Supabase: $e');
    }
  }

  // Data Stores
  List<AdminUser> _administrators = [];
  List<UserAccountModel> _users = [];
  List<DealerAccountModel> _dealers = [];
  List<ServicePartnerProfile> _servicePartners = [];
  List<ComplaintTicketModel> _complaints = [];
  List<SubscriptionPlanConfig> _plans = [];
  List<AdminPaymentRecord> _payments = [];
  List<AdminBroadcastNotification> _notifications = [];
  List<AdminAuditLogModel> _auditLogs = [];
  List<PropertyReportModel> _reports = [];
  AiMonitoringMetrics _aiMetrics = const AiMonitoringMetrics();
  SystemFeatureFlags _featureFlags = const SystemFeatureFlags();
  List<SystemHealthItem> _systemHealth = [];

  // Getters
  List<AdminUser> get administrators => List.unmodifiable(_administrators);
  List<UserAccountModel> get users => List.unmodifiable(_users);
  List<DealerAccountModel> get dealers => List.unmodifiable(_dealers);
  List<ServicePartnerProfile> get servicePartners => List.unmodifiable(_servicePartners);
  List<ComplaintTicketModel> get complaints => List.unmodifiable(_complaints);
  List<SubscriptionPlanConfig> get plans => List.unmodifiable(_plans);
  List<AdminPaymentRecord> get payments => List.unmodifiable(_payments);
  List<AdminBroadcastNotification> get notifications => List.unmodifiable(_notifications);
  List<AdminAuditLogModel> get auditLogs => List.unmodifiable(_auditLogs);
  List<PropertyReportModel> get reports => List.unmodifiable(_reports);
  AiMonitoringMetrics get aiMetrics => _aiMetrics;
  SystemFeatureFlags get featureFlags => _featureFlags;
  List<SystemHealthItem> get systemHealth => List.unmodifiable(_systemHealth);

  /// Dynamic case-insensitive and whitespace-safe Administrator Role Filter
  List<AdminUser> getFilteredAdministrators(AdminRole? roleFilter, {String? searchQuery}) {
    var list = _administrators;
    if (roleFilter != null) {
      list = list.where((admin) {
        final adminRoleName = admin.role.displayName.trim().toLowerCase();
        final targetRoleName = roleFilter.displayName.trim().toLowerCase();
        final adminRoleCode = admin.role.code.trim().toLowerCase();
        final targetRoleCode = roleFilter.code.trim().toLowerCase();
        return adminRoleName == targetRoleName || adminRoleCode == targetRoleCode;
      }).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((admin) =>
        admin.name.toLowerCase().contains(q) ||
        admin.email.toLowerCase().contains(q) ||
        admin.id.toLowerCase().contains(q) ||
        admin.role.displayName.toLowerCase().contains(q)
      ).toList();
    }
    return List.unmodifiable(list);
  }

  // Computed KPI Getters
  int get totalUsersCount => _users.length;
  int get activeUsersCount => _users.where((u) => u.isActive).length;
  int get totalDealersCount => _dealers.length;
  int get verifiedDealersCount => _dealers.where((d) => d.isVerified).length;
  int get pendingDealersCount => _dealers.where((d) => d.isPending).length;
  int get totalPropertiesCount => PropertyStateService.instance.rawProperties.length;
  int get approvedPropertiesCount => PropertyStateService.instance.rawProperties.where((p) => p.isPublished).length;
  int get pendingPropertiesCount => PropertyStateService.instance.rawProperties.where((p) => p.isPending).length;
  int get openComplaintsCount => _complaints.where((c) => c.status != 'Resolved' && c.status != 'Rejected').length;
  double get totalRevenueRupees => _payments.where((p) => p.status == 'Success').fold(0.0, (sum, p) => sum + p.amountRupees);

  void _initializeDefaultData() {
    // 0. Initial Administrators (Covering all 6 RBAC roles)
    _administrators = [
      AdminUser(
        id: 'ADM-001',
        name: 'PropZen Administrator',
        email: 'admin@propzen.ai',
        role: AdminRole.superAdmin,
        lastLoginAt: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        isActive: true,
      ),
      AdminUser(
        id: 'ADM-002',
        name: 'Vikram Rathore',
        email: 'vikram.property@propzen.ai',
        role: AdminRole.propertyAdmin,
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        isActive: true,
      ),
      AdminUser(
        id: 'ADM-003',
        name: 'Sneha Kulkarni',
        email: 'sneha.dealer@propzen.ai',
        role: AdminRole.dealerAdmin,
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        isActive: true,
      ),
      AdminUser(
        id: 'ADM-004',
        name: 'Aman Verma',
        email: 'aman.support@propzen.ai',
        role: AdminRole.supportAdmin,
        lastLoginAt: DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        isActive: true,
      ),
      AdminUser(
        id: 'ADM-005',
        name: 'Neha Aggarwal',
        email: 'neha.finance@propzen.ai',
        role: AdminRole.financeAdmin,
        lastLoginAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        isActive: true,
      ),
      AdminUser(
        id: 'ADM-006',
        name: 'Pooja Sharma',
        email: 'pooja.content@propzen.ai',
        role: AdminRole.contentAdmin,
        lastLoginAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        isActive: true,
      ),
    ];

    // 1. Initial Users
    _users = [
      UserAccountModel(
        id: 'usr_ananya_01',
        fullName: 'Ananya Sen',
        email: 'ananya.sen@example.com',
        phone: '+91 98101 22334',
        userType: 'Buyer',
        accountStatus: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        lastActivityAt: DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
      ),
      UserAccountModel(
        id: 'usr_rajesh_dlr',
        fullName: 'Rajesh Varma',
        email: 'rajesh.varma@ncrprimerealty.com',
        phone: '+91 98101 22334',
        userType: 'Dealer',
        accountStatus: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
        lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      UserAccountModel(
        id: 'usr_arjun_nri',
        fullName: 'Arjun Singhania',
        email: 'arjun.singhania@dubairealty.ae',
        phone: '+971 50 123 4567',
        userType: 'NRI',
        accountStatus: 'Active',
        createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        lastActivityAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      ),
      UserAccountModel(
        id: 'usr_vikas_susp',
        fullName: 'Vikas Malhotra',
        email: 'vikas@corptech.com',
        phone: '+91 98111 22334',
        userType: 'Buyer',
        accountStatus: 'Suspended',
        createdAt: DateTime.now().subtract(const Duration(days: 120)).toIso8601String(),
        lastActivityAt: DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
        suspensionReason: 'Policy violation: Unresponsive repeated mock site visits.',
      ),
    ];

    // 2. Initial Dealers
    _dealers = [
      DealerAccountModel(
        id: 'DLR-NOIDA-101',
        name: 'Rajesh Varma',
        firmName: 'NCR Prime Realty Associates',
        phone: '+91 98101 22334',
        email: 'rajesh.varma@ncrprimerealty.com',
        verificationStatus: 'Verified',
        subscriptionPlan: 'Dealer Premium',
        activeListings: 5,
        leadsCount: 18,
        siteVisitsCount: 12,
        accountStatus: 'Active',
        reraId: 'UPRERAAGT10294',
        experienceYears: '12 Years',
        rating: 4.9,
        submissionDate: '2026-06-15',
        submittedDocuments: ['RERA_License.pdf', 'GST_Certificate.pdf', 'PAN_Card.pdf'],
      ),
      DealerAccountModel(
        id: 'DLR-SEC150-102',
        name: 'Amit Goel',
        firmName: 'Sector 150 Luxury Homes',
        phone: '+91 98222 33445',
        email: 'amit.goel@sec150homes.in',
        verificationStatus: 'Pending',
        subscriptionPlan: 'Dealer Starter',
        activeListings: 3,
        leadsCount: 6,
        siteVisitsCount: 4,
        accountStatus: 'Active',
        reraId: 'UPRERAAGT11842',
        experienceYears: '8 Years',
        rating: 4.8,
        submissionDate: '2026-08-28',
        submittedDocuments: ['RERA_Reg_2026.pdf', 'GST_Filing.pdf'],
      ),
      DealerAccountModel(
        id: 'DLR-YAMUNA-103',
        name: 'Sanjay Gupta',
        firmName: 'Yamuna Express Property Advisory',
        phone: '+91 98333 44556',
        email: 'sanjay.gupta@yamunaproperties.com',
        verificationStatus: 'Needs Review',
        subscriptionPlan: 'Dealer Pro',
        activeListings: 4,
        leadsCount: 9,
        siteVisitsCount: 7,
        accountStatus: 'Active',
        reraId: 'UPRERAAGT12950',
        experienceYears: '15 Years',
        rating: 4.7,
        submissionDate: '2026-08-20',
        submittedDocuments: ['Trade_License.pdf'],
        statusReason: 'RERA Certificate renewal document missing signature.',
      ),
      DealerAccountModel(
        id: 'DLR-COMM-104',
        name: 'Rohit Kapoor',
        firmName: 'Noida Commercial Spaces Hub',
        phone: '+91 98444 55667',
        email: 'rohit@noidacommercial.in',
        verificationStatus: 'Verified',
        subscriptionPlan: 'Dealer Enterprise',
        activeListings: 6,
        leadsCount: 24,
        siteVisitsCount: 16,
        accountStatus: 'Active',
        reraId: 'UPRERAAGT13871',
        experienceYears: '10 Years',
        rating: 4.9,
        submissionDate: '2026-05-10',
        submittedDocuments: ['UPRERA_Agent_Cert.pdf', 'Company_Incorporation.pdf'],
      ),
    ];

    // 3. Initial Subscription Plans
    _plans = [
      const SubscriptionPlanConfig(
        id: 'plan_starter',
        planName: 'Dealer Starter',
        userType: 'Dealer',
        description: 'Ideal for independent brokers starting their digital presence.',
        priceRupees: 1999.0,
        duration: 'Monthly',
        listingLimit: 5,
        leadLimit: 20,
        features: ['5 Active Listings', '20 Verified Leads/mo', 'Standard AI Description Creator', 'Email Support'],
        isActive: true,
      ),
      const SubscriptionPlanConfig(
        id: 'plan_pro',
        planName: 'Dealer Pro',
        userType: 'Dealer',
        description: 'Designed for growing brokerages with high site visit volume.',
        priceRupees: 4999.0,
        duration: 'Monthly',
        listingLimit: 15,
        leadLimit: 75,
        features: ['15 Active Listings', '75 Verified Leads/mo', '3D Model & 360 Embeds', 'AI Follow-up Generator', 'Priority Support'],
        isActive: true,
      ),
      const SubscriptionPlanConfig(
        id: 'plan_premium',
        planName: 'Dealer Premium',
        userType: 'Dealer',
        description: 'Comprehensive package with 4K Drone Tours & Safe Deal Rooms.',
        priceRupees: 9999.0,
        duration: 'Monthly',
        listingLimit: 40,
        leadLimit: 250,
        features: ['40 Active Listings', '250 Verified Leads/mo', '4K Aerial Drone Tours', 'Safe Deal Room Concierge', 'Dedicated Manager'],
        isActive: true,
      ),
      const SubscriptionPlanConfig(
        id: 'plan_nri_pass',
        planName: 'NRI Remote Property Suite',
        userType: 'NRI',
        description: 'All-inclusive remote exploration, 1-on-1 live walkthroughs & legal vault.',
        priceRupees: 14999.0,
        duration: 'Quarterly',
        listingLimit: 0,
        leadLimit: 0,
        features: ['Unlimited 4K Drone & 360 Tours', '5 Live 1-on-1 Remote Video Tours', 'Complete Legal Vault & Due Diligence', 'Family Decision Voting'],
        isActive: true,
      ),
    ];

    // 4. Initial Payments
    _payments = [
      AdminPaymentRecord(
        id: 'PAY-2026-001',
        orderId: 'ORD-98101-01',
        userName: 'Rajesh Varma',
        userEmail: 'rajesh.varma@ncrprimerealty.com',
        userType: 'Dealer',
        planName: 'Dealer Premium',
        amountRupees: 9999.0,
        paymentId: 'pay_rzp_live_981012233',
        status: 'Success',
        date: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        paymentMethod: 'UPI / NetBanking',
      ),
      AdminPaymentRecord(
        id: 'PAY-2026-002',
        orderId: 'ORD-98444-02',
        userName: 'Rohit Kapoor',
        userEmail: 'rohit@noidacommercial.in',
        userType: 'Dealer',
        planName: 'Dealer Enterprise',
        amountRupees: 19999.0,
        paymentId: 'pay_rzp_live_984445566',
        status: 'Success',
        date: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        paymentMethod: 'Corporate Card',
      ),
      AdminPaymentRecord(
        id: 'PAY-2026-003',
        orderId: 'ORD-NRI-003',
        userName: 'Arjun Singhania',
        userEmail: 'arjun.singhania@dubairealty.ae',
        userType: 'NRI',
        planName: 'NRI Remote Property Suite',
        amountRupees: 14999.0,
        paymentId: 'pay_rzp_live_nri778899',
        status: 'Success',
        date: DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        paymentMethod: 'International Card',
      ),
    ];

    // 5. Initial Complaints
    _complaints = [
      ComplaintTicketModel(
        id: 'CMP-2026-001',
        ticketNumber: 'TKT-88401',
        reporterName: 'Kavita Roy',
        reporterEmail: 'kavita.roy@gmail.com',
        targetType: 'Incorrect Information',
        targetTitle: 'ATS HomeKraft Happy Trails',
        targetId: 'NCR-PROP-NOIDA-EXT-1',
        title: 'Discrepancy in possession date declaration',
        description: 'The listing states Dec 2026 possession while recent developer bulletin states March 2027.',
        status: 'Under Review',
        priority: 'High',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
        assignedAdmin: 'Property Administrator',
      ),
      ComplaintTicketModel(
        id: 'CMP-2026-002',
        ticketNumber: 'TKT-88402',
        reporterName: 'Sunil Sharma',
        reporterEmail: 'sunil.sharma@yahoo.com',
        targetType: 'Site Visit Issue',
        targetTitle: 'Tata Eureka Park',
        targetId: 'NCR-PROP-SEC150-1',
        title: 'Cab did not arrive on scheduled pickup time',
        description: 'Scheduled visit for 11 AM yesterday, cab was delayed by 45 minutes.',
        status: 'Resolved',
        priority: 'Medium',
        createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        assignedAdmin: 'Support Administrator',
        resolutionNotes: 'Contacted transport vendor, issued full travel reimbursement voucher.',
        resolvedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      ),
    ];

    // 6. Initial Broadcast Notifications
    _notifications = [
      AdminBroadcastNotification(
        id: 'NOTIF-2026-01',
        title: 'Jewar Airport Corridor Special Investor Summit',
        message: 'Explore exclusive high-yield commercial and residential inventory along Yamuna Expressway.',
        notificationType: 'NRI',
        audience: 'All Users',
        createdBy: 'Master Administrator',
        createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        status: 'Sent',
        recipientCount: 1420,
      ),
      AdminBroadcastNotification(
        id: 'NOTIF-2026-02',
        title: 'New RERA Title Verification Engine Active',
        message: 'All dealer listings now receive automated 5-pillar consistency check badges.',
        notificationType: 'Verification',
        audience: 'Dealers',
        createdBy: 'Property Administrator',
        createdAt: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        status: 'Sent',
        recipientCount: 42,
      ),
    ];

    // 7. Initial Audit Logs
    _auditLogs = [
      AdminAuditLogModel(
        id: 'AUD-001',
        timestamp: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        adminId: 'ADM-MASTER-001',
        adminName: 'Master Administrator',
        targetType: 'Property',
        targetId: 'NCR-PROP-NOIDA-EXT-1',
        targetTitle: 'ATS HomeKraft Happy Trails',
        action: 'Approved',
        fieldChanged: 'publication_status',
        oldValue: 'pending',
        newValue: 'published',
        reason: 'RERA certificate UPRERAPRJ15574 cross-verified with UP RERA portal.',
      ),
      AdminAuditLogModel(
        id: 'AUD-002',
        timestamp: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        adminId: 'ADM-MASTER-001',
        adminName: 'Master Administrator',
        targetType: 'Dealer',
        targetId: 'DLR-NOIDA-101',
        targetTitle: 'Rajesh Varma (NCR Prime Realty)',
        action: 'Verified',
        fieldChanged: 'verification_status',
        oldValue: 'pending',
        newValue: 'verified',
        reason: 'UPRERAAGT10294 valid until 2029.',
      ),
    ];

    // 8. System Health
    _systemHealth = [
      SystemHealthItem(serviceName: 'Supabase PostgreSQL Backend', status: 'Operational', latencyMs: '42 ms', lastCheckedAt: 'Just now', details: 'Database connection pool healthy at 12% capacity.'),
      SystemHealthItem(serviceName: 'Authentication Service (GoTrue)', status: 'Operational', latencyMs: '38 ms', lastCheckedAt: 'Just now', details: 'JWT token signing and session refresh normal.'),
      SystemHealthItem(serviceName: 'Payment Gateway (Razorpay)', status: 'Operational', latencyMs: '110 ms', lastCheckedAt: 'Just now', details: 'Webhook signatures and checkout APIs operational.'),
      SystemHealthItem(serviceName: 'AI Super Assistant Engine', status: 'Operational', latencyMs: '220 ms', lastCheckedAt: 'Just now', details: 'Natural language pipeline & slot-filling active.'),
      SystemHealthItem(serviceName: 'Indian Female Voice TTS / STT', status: 'Operational', latencyMs: '180 ms', lastCheckedAt: 'Just now', details: 'Web Speech Synthesis / Unified Female Voice active.'),
      SystemHealthItem(serviceName: 'Storage Buckets (Media / Docs)', status: 'Operational', latencyMs: '55 ms', lastCheckedAt: 'Just now', details: 'Encrypted document vault and CDN image delivery normal.'),
      SystemHealthItem(serviceName: 'Notification Dispatcher', status: 'Operational', latencyMs: '64 ms', lastCheckedAt: 'Just now', details: 'Push notification queue latency < 1.2s.'),
    ];

    // 9. Initial Sample Reports
    _reports = [
      PropertyReportModel(
        id: 'REP-001',
        propertyId: 'prop_mahagun',
        propertyTitle: 'Mahagun Manorialle',
        reporterId: 'usr_guest_01',
        reason: 'Misleading information',
        comment: 'Floor level discrepancy in brochure.',
        status: 'PENDING',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      ),
    ];

    // 10. Service Partner Profiles (Loaded dynamically from database)
    _servicePartners = [];
  }

  // ===========================================================================
  // AUDIT LOGGING HELPER
  // ===========================================================================
  void recordAuditLog({
    required String targetType,
    required String targetId,
    required String targetTitle,
    required String action,
    String fieldChanged = 'status',
    String oldValue = '',
    String newValue = '',
    required String reason,
    Map<String, dynamic> metadata = const {},
  }) {
    final log = AdminAuditLogModel(
      id: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toIso8601String(),
      adminId: _currentAdmin.id,
      adminName: '${_currentAdmin.name} (${_currentAdmin.role.displayName})',
      targetType: targetType,
      targetId: targetId,
      targetTitle: targetTitle,
      action: action,
      fieldChanged: fieldChanged,
      oldValue: oldValue,
      newValue: newValue,
      reason: reason,
      metadata: metadata,
    );
    _auditLogs.insert(0, log);
    notifyListeners();

    // Persist to Supabase audit_logs asynchronously
    try {
      SupabaseService.instance.recordAuditLog(
        actorEmail: _currentAdmin.email,
        action: action,
        entityType: targetType,
        entityId: targetId,
        metadata: {
          'title': targetTitle,
          'fieldChanged': fieldChanged,
          'oldValue': oldValue,
          'newValue': newValue,
          'reason': reason,
          ...metadata,
        },
      );
    } catch (_) {}
  }

  // ===========================================================================
  // PROPERTY REPORTS & MODERATION
  // ===========================================================================
  void submitUserReport({
    required String propertyId,
    required String propertyTitle,
    required String reporterId,
    required String reason,
    String comment = '',
  }) {
    final report = PropertyReportModel(
      id: 'REP-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      reporterId: reporterId,
      reason: reason,
      comment: comment,
      status: 'PENDING',
      createdAt: DateTime.now().toIso8601String(),
    );
    _reports.insert(0, report);
    recordAuditLog(
      targetType: 'Property Report',
      targetId: propertyId,
      targetTitle: propertyTitle,
      action: 'Report Submitted',
      reason: 'User submitted report: $reason',
    );
    notifyListeners();
  }

  void resolveReport(String reportId, String actionNote) {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final old = _reports[idx];
      _reports[idx] = PropertyReportModel(
        id: old.id,
        propertyId: old.propertyId,
        propertyTitle: old.propertyTitle,
        reporterId: old.reporterId,
        reason: old.reason,
        comment: old.comment,
        status: 'RESOLVED',
        createdAt: old.createdAt,
      );
      recordAuditLog(
        targetType: 'Property Report',
        targetId: old.propertyId,
        targetTitle: old.propertyTitle,
        action: 'Report Resolved',
        reason: actionNote,
      );
      notifyListeners();
    }
  }

  // ===========================================================================
  // USER MANAGEMENT WORKFLOWS
  // ===========================================================================
  Future<bool> suspendUser(String userId, String reason) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = user.copyWith(accountStatus: 'Suspended', suspensionReason: reason);

      recordAuditLog(
        targetType: 'User',
        targetId: user.id,
        targetTitle: user.fullName,
        action: 'Suspended',
        fieldChanged: 'account_status',
        oldValue: user.accountStatus,
        newValue: 'Suspended',
        reason: reason,
      );
    }
    await SupabaseService.instance.updateUserStatus(userId, 'Suspended', reason: reason);
    notifyListeners();
    return true;
  }

  Future<bool> reactivateUser(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _users[index];
      _users[index] = user.copyWith(accountStatus: 'Active', suspensionReason: '');

      recordAuditLog(
        targetType: 'User',
        targetId: user.id,
        targetTitle: user.fullName,
        action: 'Reactivated',
        fieldChanged: 'account_status',
        oldValue: user.accountStatus,
        newValue: 'Active',
        reason: 'Admin cleared account flags following compliance review.',
      );
    }
    await SupabaseService.instance.updateUserStatus(userId, 'Active');
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // DEALER MANAGEMENT WORKFLOWS (5 VERIFICATION STATES)
  // ===========================================================================
  Future<bool> updateDealerVerificationStatus(
    String dealerId,
    String status, {
    String? reason,
  }) async {
    final cleanStatus = status.trim().toUpperCase();
    final index = _dealers.indexWhere((d) => d.id == dealerId);
    if (index != -1) {
      final dealer = _dealers[index];
      final newAccountStatus = (cleanStatus == 'SUSPENDED' || cleanStatus == 'REJECTED') ? 'Suspended' : 'Active';
      _dealers[index] = dealer.copyWith(
        verificationStatus: cleanStatus,
        accountStatus: newAccountStatus,
        statusReason: reason ?? dealer.statusReason,
      );

      recordAuditLog(
        targetType: 'Dealer',
        targetId: dealer.id,
        targetTitle: '${dealer.name} (${dealer.firmName})',
        action: cleanStatus,
        fieldChanged: 'verification_status',
        oldValue: dealer.verificationStatus,
        newValue: cleanStatus,
        reason: reason ?? 'Status updated to $cleanStatus',
      );
    }

    // 1. Update Spring Boot backend for authoritative role activation
    try {
      final backendStatus = (cleanStatus == 'VERIFIED' || cleanStatus == 'APPROVED') ? 'APPROVED' : cleanStatus;
      await CrmApiClient.instance.patch(
        '/api/v1/admin/dealers/$dealerId/status',
        body: {
          'status': backendStatus,
          'adminNotes': reason ?? 'Status updated to $cleanStatus by Admin',
        },
      );
    } catch (e) {
      debugPrint('[AdminCommandService] Backend dealer status update note: $e');
    }

    // 2. PostgREST database sync
    await SupabaseService.instance.updateDealerVerificationStatus(
      dealerId,
      cleanStatus,
      notes: reason,
    );
    notifyListeners();
    return true;
  }

  Future<bool> verifyDealer(String dealerId) async {
    return updateDealerVerificationStatus(dealerId, 'VERIFIED', reason: 'RERA documents and business incorporation approved.');
  }

  Future<bool> markDealerUnderReview(String dealerId) async {
    return updateDealerVerificationStatus(dealerId, 'UNDER_REVIEW', reason: 'Admin actively conducting credential audit.');
  }

  Future<bool> rejectDealer(String dealerId, String reason) async {
    return updateDealerVerificationStatus(dealerId, 'REJECTED', reason: reason);
  }

  Future<bool> suspendDealer(String dealerId, String reason) async {
    return updateDealerVerificationStatus(dealerId, 'SUSPENDED', reason: reason);
  }

  Future<bool> requestDealerDocs(String dealerId, String note) async {
    return updateDealerVerificationStatus(dealerId, 'UNDER_REVIEW', reason: note);
  }

  // ===========================================================================
  // SERVICE PARTNER MANAGEMENT WORKFLOWS (SPECIALIZATION & COMPLIANCE GOVERNANCE)
  // ===========================================================================
  Future<bool> verifyServicePartner(String partnerId) async {
    final idx = _servicePartners.indexWhere((p) => p.id == partnerId);
    if (idx != -1) {
      final p = _servicePartners[idx];
      _servicePartners[idx] = p.copyWith(
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );
      recordAuditLog(
        targetType: 'Service Partner',
        targetId: p.id,
        targetTitle: p.businessName,
        action: 'VERIFIED',
        fieldChanged: 'verification_status',
        oldValue: p.verificationStatus,
        newValue: 'VERIFIED',
        reason: 'Service Partner verified and activated by Admin.',
      );
    }

    // 1. Update Spring Boot backend for authoritative role activation
    try {
      await CrmApiClient.instance.patch(
        '/api/v1/admin/service-partners/$partnerId/status',
        body: {
          'status': 'APPROVED',
          'adminNotes': 'Service Partner verified and activated by Admin.',
        },
      );
    } catch (e) {
      debugPrint('[AdminCommandService] Backend partner status update note: $e');
    }

    // 2. PostgREST database sync
    await SupabaseService.instance.updateServicePartnerProfile(partnerId, {
      'partner_status': 'APPROVED',
      'verification_status': 'VERIFIED',
      'status': 'ACTIVE',
    });
    notifyListeners();
    return true;
  }

  Future<bool> rejectServicePartner(String partnerId, String reason) async {
    final idx = _servicePartners.indexWhere((p) => p.id == partnerId);
    if (idx != -1) {
      final p = _servicePartners[idx];
      _servicePartners[idx] = p.copyWith(
        verificationStatus: 'REJECTED',
        status: 'INACTIVE',
      );
      recordAuditLog(
        targetType: 'Service Partner',
        targetId: p.id,
        targetTitle: p.businessName,
        action: 'REJECTED',
        fieldChanged: 'verification_status',
        oldValue: p.verificationStatus,
        newValue: 'REJECTED',
        reason: reason,
      );
    }

    // 1. Update Spring Boot backend
    try {
      await CrmApiClient.instance.patch(
        '/api/v1/admin/service-partners/$partnerId/status',
        body: {
          'status': 'REJECTED',
          'adminNotes': reason,
        },
      );
    } catch (e) {
      debugPrint('[AdminCommandService] Backend partner status update note: $e');
    }

    // 2. PostgREST database sync
    await SupabaseService.instance.updateServicePartnerProfile(partnerId, {
      'partner_status': 'REJECTED',
      'verification_status': 'REJECTED',
      'status': 'INACTIVE',
    });
    notifyListeners();
    return true;
  }

  Future<bool> suspendServicePartner(String partnerId, String reason) async {
    final idx = _servicePartners.indexWhere((p) => p.id == partnerId);
    if (idx != -1) {
      final p = _servicePartners[idx];
      _servicePartners[idx] = p.copyWith(
        verificationStatus: 'SUSPENDED',
        status: 'SUSPENDED',
      );
      recordAuditLog(
        targetType: 'Service Partner',
        targetId: p.id,
        targetTitle: p.businessName,
        action: 'SUSPENDED',
        fieldChanged: 'status',
        oldValue: p.status,
        newValue: 'SUSPENDED',
        reason: reason,
      );
    }

    // 1. Update Spring Boot backend
    try {
      await CrmApiClient.instance.patch(
        '/api/v1/admin/service-partners/$partnerId/status',
        body: {
          'status': 'SUSPENDED',
          'adminNotes': reason,
        },
      );
    } catch (e) {
      debugPrint('[AdminCommandService] Backend partner status update note: $e');
    }

    // 2. PostgREST database sync
    await SupabaseService.instance.updateServicePartnerProfile(partnerId, {
      'partner_status': 'SUSPENDED',
      'verification_status': 'SUSPENDED',
      'status': 'SUSPENDED',
    });
    notifyListeners();
    return true;
  }

  Future<bool> reactivateServicePartner(String partnerId) async {
    final idx = _servicePartners.indexWhere((p) => p.id == partnerId);
    if (idx != -1) {
      final p = _servicePartners[idx];
      _servicePartners[idx] = p.copyWith(
        verificationStatus: 'VERIFIED',
        status: 'ACTIVE',
      );
      recordAuditLog(
        targetType: 'Service Partner',
        targetId: p.id,
        targetTitle: p.businessName,
        action: 'REACTIVATED',
        fieldChanged: 'status',
        oldValue: p.status,
        newValue: 'ACTIVE',
        reason: 'Suspension lifted following compliance review.',
      );
    }

    // 1. Update Spring Boot backend
    try {
      await CrmApiClient.instance.patch(
        '/api/v1/admin/service-partners/$partnerId/status',
        body: {
          'status': 'APPROVED',
          'adminNotes': 'Suspension lifted following compliance review.',
        },
      );
    } catch (e) {
      debugPrint('[AdminCommandService] Backend partner status update note: $e');
    }

    // 2. PostgREST database sync
    await SupabaseService.instance.updateServicePartnerProfile(partnerId, {
      'partner_status': 'APPROVED',
      'verification_status': 'VERIFIED',
      'status': 'ACTIVE',
    });
    notifyListeners();
    return true;
  }

  Future<bool> updatePartnerCategories(String partnerId, List<String> categories) async {
    final idx = _servicePartners.indexWhere((p) => p.id == partnerId);
    if (idx != -1) {
      final p = _servicePartners[idx];
      final oldCats = p.serviceCategories.join(', ');
      final newCats = categories.join(', ');
      _servicePartners[idx] = p.copyWith(
        serviceCategories: categories,
        serviceCategory: categories.isNotEmpty ? categories.first : p.serviceCategory,
      );
      recordAuditLog(
        targetType: 'Service Partner',
        targetId: p.id,
        targetTitle: p.businessName,
        action: 'CATEGORIES_UPDATED',
        fieldChanged: 'service_categories',
        oldValue: oldCats,
        newValue: newCats,
        reason: 'Approved specializations modified by Admin.',
      );
    }
    await SupabaseService.instance.updateServicePartnerProfile(partnerId, {
      'service_categories': categories,
      if (categories.isNotEmpty) 'service_category': categories.first,
    });
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // PROPERTY MODERATION WORKFLOWS
  // ===========================================================================
  Future<bool> approveProperty(String propertyId) async {
    PropertyStateService.instance.approveProperty(propertyId);
    final prop = PropertyStateService.instance.rawProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => Property.sampleDeals.first,
    );
    recordAuditLog(
      targetType: 'Property',
      targetId: prop.id,
      targetTitle: prop.title,
      action: 'Approved',
      fieldChanged: 'approval_status',
      oldValue: 'pending',
      newValue: 'published',
      reason: 'Property details, pricing, and media approved for public marketplace.',
    );
    await SupabaseService.instance.approveProperty(
      propertyId: propertyId,
      adminId: _currentAdmin.email,
    );
    notifyListeners();
    return true;
  }

  Future<bool> rejectProperty(String propertyId, String reason) async {
    PropertyStateService.instance.rejectProperty(propertyId, reason: reason);
    final prop = PropertyStateService.instance.rawProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => Property.sampleDeals.first,
    );
    recordAuditLog(
      targetType: 'Property',
      targetId: prop.id,
      targetTitle: prop.title,
      action: 'Rejected',
      fieldChanged: 'approval_status',
      oldValue: 'pending',
      newValue: 'rejected',
      reason: reason,
    );
    await SupabaseService.instance.rejectProperty(
      propertyId: propertyId,
      adminId: _currentAdmin.email,
      reason: reason,
    );
    notifyListeners();
    return true;
  }

  Future<bool> requestPropertyCorrection(String propertyId, String note) async {
    PropertyStateService.instance.rejectProperty(propertyId, reason: note);
    final prop = PropertyStateService.instance.rawProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => Property.sampleDeals.first,
    );
    recordAuditLog(
      targetType: 'Property',
      targetId: prop.id,
      targetTitle: prop.title,
      action: 'Correction Requested',
      fieldChanged: 'approval_status',
      oldValue: 'pending',
      newValue: 'needs_correction',
      reason: note,
    );
    await SupabaseService.instance.requestPropertyCorrection(
      propertyId: propertyId,
      adminId: _currentAdmin.email,
      correctionNote: note,
    );
    notifyListeners();
    return true;
  }

  Future<bool> unpublishProperty(String propertyId, String reason) async {
    final prop = PropertyStateService.instance.rawProperties.firstWhere(
      (p) => p.id == propertyId,
      orElse: () => Property.sampleDeals.first,
    );
    PropertyStateService.instance.rejectProperty(propertyId, reason: reason);
    recordAuditLog(
      targetType: 'Property',
      targetId: prop.id,
      targetTitle: prop.title,
      action: 'Unpublished',
      fieldChanged: 'approval_status',
      oldValue: 'published',
      newValue: 'rejected',
      reason: reason,
    );
    await SupabaseService.instance.rejectProperty(
      propertyId: propertyId,
      adminId: _currentAdmin.email,
      reason: reason,
    );
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // PROPERTY INTELLIGENCE OVERRIDES
  // ===========================================================================
  Future<bool> overridePropertyIntelligence({
    required String propertyId,
    required String field,
    required String oldValue,
    required String newValue,
    required String reason,
  }) async {
    final prop = PropertyStateService.instance.rawProperties.firstWhere((p) => p.id == propertyId, orElse: () => Property.sampleDeals.first);

    recordAuditLog(
      targetType: 'Property Intelligence',
      targetId: prop.id,
      targetTitle: prop.title,
      action: 'Overridden',
      fieldChanged: field,
      oldValue: oldValue,
      newValue: newValue,
      reason: reason,
    );
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // COMPLAINT WORKFLOWS
  // ===========================================================================
  Future<bool> updateComplaintStatus(String ticketId, String status, {String? notes}) async {
    final index = _complaints.indexWhere((c) => c.id == ticketId);
    if (index == -1) return false;

    final ticket = _complaints[index];
    _complaints[index] = ticket.copyWith(
      status: status,
      resolutionNotes: notes ?? ticket.resolutionNotes,
      resolvedAt: status == 'Resolved' ? DateTime.now().toIso8601String() : null,
    );

    recordAuditLog(
      targetType: 'Complaint',
      targetId: ticket.ticketNumber,
      targetTitle: ticket.title,
      action: 'Status Updated to $status',
      fieldChanged: 'ticket_status',
      oldValue: ticket.status,
      newValue: status,
      reason: notes ?? 'Status updated by admin.',
    );
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // PLAN & SUBSCRIPTION CONFIGURATION
  // ===========================================================================
  Future<bool> saveSubscriptionPlan(SubscriptionPlanConfig updatedPlan) async {
    final index = _plans.indexWhere((p) => p.id == updatedPlan.id);
    if (index == -1) {
      _plans.add(updatedPlan);
    } else {
      _plans[index] = updatedPlan;
    }

    recordAuditLog(
      targetType: 'Subscription Plan',
      targetId: updatedPlan.id,
      targetTitle: updatedPlan.planName,
      action: 'Updated Plan Configuration',
      fieldChanged: 'pricing_limits',
      oldValue: 'Price: ₹${updatedPlan.priceRupees}',
      newValue: 'Price: ₹${updatedPlan.priceRupees} (Active: ${updatedPlan.isActive})',
      reason: 'Subscription plan parameters modified.',
    );
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // PAYMENT & REFUND PROCESSING
  // ===========================================================================
  Future<bool> processRefund(String paymentId, String reason) async {
    final index = _payments.indexWhere((p) => p.id == paymentId);
    if (index == -1) return false;

    final payment = _payments[index];
    _payments[index] = payment.copyWith(status: 'Refunded');

    recordAuditLog(
      targetType: 'Payment',
      targetId: payment.paymentId,
      targetTitle: '${payment.userName} - ${payment.planName}',
      action: 'Refunded',
      fieldChanged: 'payment_status',
      oldValue: payment.status,
      newValue: 'Refunded',
      reason: reason,
    );
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // BROADCAST NOTIFICATION SENDER
  // ===========================================================================
  Future<bool> sendBroadcastNotification({
    required String title,
    required String message,
    required String notificationType,
    required String audience,
  }) async {
    final notif = AdminBroadcastNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      notificationType: notificationType,
      audience: audience,
      createdBy: '${_currentAdmin.name} (${_currentAdmin.role.displayName})',
      createdAt: DateTime.now().toIso8601String(),
      status: 'Sent',
      recipientCount: audience == 'All Users' ? 1420 : (audience == 'Dealers' ? 42 : 310),
    );
    _notifications.insert(0, notif);

    recordAuditLog(
      targetType: 'Notification',
      targetId: notif.id,
      targetTitle: title,
      action: 'Broadcast Notification Dispatched',
      fieldChanged: 'audience_target',
      oldValue: 'Draft',
      newValue: audience,
      reason: 'Dispatched by ${_currentAdmin.name}',
    );
    notifyListeners();
    return true;
  }

  // ===========================================================================
  // AI FEATURE FLAGS
  // ===========================================================================
  void toggleAiFeature(String feature, bool isEnabled) {
    switch (feature) {
      case 'aiAdvisor':
        _featureFlags = _featureFlags.copyWith(aiAdvisorEnabled: isEnabled);
        break;
      case 'aiVoice':
        _featureFlags = _featureFlags.copyWith(aiVoiceEnabled: isEnabled);
        break;
      case 'aiListingCreator':
        _featureFlags = _featureFlags.copyWith(aiListingCreatorEnabled: isEnabled);
        break;
      case 'aiLeadAssistant':
        _featureFlags = _featureFlags.copyWith(aiLeadAssistantEnabled: isEnabled);
        break;
      case 'aiPropertyIntelligence':
        _featureFlags = _featureFlags.copyWith(aiPropertyIntelligenceEnabled: isEnabled);
        break;
    }

    recordAuditLog(
      targetType: 'AI Feature Flag',
      targetId: feature,
      targetTitle: feature,
      action: isEnabled ? 'Enabled' : 'Disabled',
      fieldChanged: 'is_enabled',
      oldValue: (!isEnabled).toString(),
      newValue: isEnabled.toString(),
      reason: 'Operational AI feature flag adjusted by Super Admin.',
    );
    notifyListeners();
  }

  // ===========================================================================
  // DATA EXPORT GENERATOR
  // ===========================================================================
  String exportDataAsCsv(String entity) {
    final buffer = StringBuffer();
    if (entity == 'properties') {
      buffer.writeln('ID,Title,Location,Price_Cr,Status,RERA');
      for (final p in PropertyStateService.instance.rawProperties) {
        buffer.writeln('"${p.id}","${p.title}","${p.sector}, ${p.city}",${p.askingPriceCr},"${p.status}","${p.reraStatus}"');
      }
    } else if (entity == 'leads') {
      buffer.writeln('ID,BuyerName,Phone,Budget_Cr,Requirement,Status');
      final leads = DealerLeadService.instance.allLeads;
      for (final l in leads) {
        buffer.writeln('"${l.id}","${l.buyerName}","${l.buyerPhone}",${l.budgetCr},"${l.requirement}","${l.enquiryStatus}"');
      }
    } else if (entity == 'payments') {
      buffer.writeln('ID,Order_ID,User,Email,Plan,Amount,Status,Date');
      for (final pay in _payments) {
        buffer.writeln('"${pay.id}","${pay.orderId}","${pay.userName}","${pay.userEmail}","${pay.planName}",${pay.amountRupees},"${pay.status}","${pay.date}"');
      }
    }
    return buffer.toString();
  }

  // ===========================================================================
  // AUTONOMOUS AI & SECURITY OVERRIDES
  // ===========================================================================
  Future<bool> overrideAiDecision({
    required String propertyId,
    required String newStatus, // 'published', 'rejected', 'under_review'
    required String reason,
  }) async {
    final success = await SupabaseService.instance.updatePropertyApprovalStatus(
      propertyId,
      status: newStatus,
      adminNote: 'Human Override by ${_currentAdmin.name}: $reason',
      adminId: _currentAdmin.id,
    );

    recordAuditLog(
      targetType: 'AI Property Decision',
      targetId: propertyId,
      targetTitle: 'Listing Approval Override',
      action: 'HUMAN_OVERRIDE_$newStatus'.toUpperCase(),
      fieldChanged: 'verification_status',
      oldValue: 'AI_AUTOMATED',
      newValue: newStatus,
      reason: reason,
    );

    notifyListeners();
    return success;
  }

  // ===========================================================================
  // SERVICE PARTNER LEAD ROUTING & MANAGEMENT APIS
  // ===========================================================================

  /// Fetch service enquiry leads with optional filters
  Future<List<Map<String, dynamic>>> fetchServiceLeads({
    String? serviceCategory,
    String? assignmentStatus,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (serviceCategory != null && serviceCategory.isNotEmpty && serviceCategory != 'ALL') {
        params['serviceCategory'] = serviceCategory;
      }
      if (assignmentStatus != null && assignmentStatus.isNotEmpty && assignmentStatus != 'ALL') {
        params['assignmentStatus'] = assignmentStatus;
      }
      if (status != null && status.isNotEmpty && status != 'ALL') {
        params['status'] = status;
      }
      final res = await CrmApiClient.instance.get('/api/v1/crm/leads', queryParams: params);
      if (res is Map<String, dynamic> && res.containsKey('content')) {
        final content = res['content'];
        if (content is List) {
          return List<Map<String, dynamic>>.from(content);
        }
      } else if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      }
      return [];
    } catch (e) {
      debugPrint('[AdminCommandService] Error fetching service leads: $e');
      return [];
    }
  }

  /// Fetch eligible partners ranked by proximity, workload, and rating for a lead
  Future<List<Map<String, dynamic>>> fetchEligiblePartnersForLead(String leadId) async {
    try {
      final res = await CrmApiClient.instance.get('/api/v1/crm/leads/$leadId/eligible-partners');
      if (res is List) {
        return List<Map<String, dynamic>>.from(res);
      }
      return [];
    } catch (e) {
      debugPrint('[AdminCommandService] Error fetching eligible partners for lead $leadId: $e');
      return [];
    }
  }

  /// Admin manual lead assignment to an eligible service partner
  Future<bool> assignLeadToPartner(String leadId, String partnerId, {String? notes}) async {
    try {
      await CrmApiClient.instance.patch(
        '/api/v1/crm/leads/$leadId/assign-partner',
        body: {
          'partnerId': partnerId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      recordAuditLog(
        targetType: 'Lead',
        targetId: leadId,
        targetTitle: 'Service Lead Assignment',
        action: 'MANUAL_ASSIGNMENT',
        fieldChanged: 'assigned_partner_id',
        newValue: partnerId,
        reason: notes ?? 'Manually assigned by administrator',
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdminCommandService] Error assigning lead to partner: $e');
      return false;
    }
  }

  /// Admin manual lead unassignment (moves lead to UNASSIGNED fallback queue)
  Future<bool> unassignLeadPartner(String leadId, {String? reason}) async {
    try {
      await CrmApiClient.instance.patch(
        '/api/v1/crm/leads/$leadId/unassign-partner',
        body: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      recordAuditLog(
        targetType: 'Lead',
        targetId: leadId,
        targetTitle: 'Service Lead Unassignment',
        action: 'MANUAL_UNASSIGNMENT',
        fieldChanged: 'assigned_partner_id',
        newValue: 'UNASSIGNED',
        reason: reason ?? 'Unassigned by administrator',
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AdminCommandService] Error unassigning lead partner: $e');
      return false;
    }
  }
}
