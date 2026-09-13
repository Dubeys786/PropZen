
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/admin_models.dart';
import '../models/property.dart';
import '../services/admin_service.dart';
import '../services/admin_command_service.dart';
import '../services/property_state_service.dart';
import '../services/dealer_lead_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../routes/app_routes.dart';
import 'admin_property_review_screen.dart';
import 'user_profile_screen.dart';
import '../config/phase_config.dart';
import '../services/auth_service.dart';
import 'dual_auth_screen.dart';
import '../services/feature_flag_service.dart';
import '../models/service_partner_profile.dart';
import '../models/service_request_model.dart';
import '../services/service_partner_service.dart';
import '../crm/screens/crm_dashboard_screen.dart';
import '../crm/screens/crm_leads_screen.dart';
import '../crm/screens/crm_customer_360_screen.dart';
import '../crm/screens/crm_follow_ups_screen.dart';
import '../crm/screens/crm_tasks_screen.dart';
import '../crm/screens/crm_properties_screen.dart';
import '../crm/screens/crm_campaigns_screen.dart';
import '../crm/screens/crm_analytics_screen.dart';
import '../crm/services/crm_service.dart';
import '../crm/models/crm_dashboard_metrics.dart';
import '../verification/screens/verification_workspace_view.dart';
import '../verification/models/trust_engine_models.dart';
import '../verification/services/trust_engine_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final int initialNavIndex;
  final String? initialLeadId;

  const AdminPanelScreen({
    super.key,
    this.onBackToHome,
    this.initialNavIndex = 0,
    this.initialLeadId,
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService.instance;
  final AdminCommandService _commandService = AdminCommandService.instance;
  final CrmService _crmService = CrmService.instance;

  // Selected navigation section (0 to 29)
  int _selectedNavIndex = 0;
  CrmDashboardMetrics? _crmMetrics;
  VerificationMetrics? _verificationMetrics;

  // Login Form Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Search & Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _propertyStatusFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected', 'Needs Correction'
  String _userRoleFilter = 'All'; // 'All', 'Buyer', 'NRI', 'Dealer', 'Admin'
  String _dealerStatusFilter = 'ALL'; // 'ALL', 'PENDING', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED', 'SUSPENDED'
  String _partnerStatusFilter = 'ALL'; // 'ALL', 'VERIFIED', 'PENDING', 'SUSPENDED'
  String _partnerCategoryFilter = 'ALL'; // 'ALL', 'LOAN', 'HOME_DESIGN', 'VASTU', 'CONSTRUCTION', 'PROPERTY_VERIFICATION', 'VIRTUAL_3D'
  String _revenuePeriodFilter = 'This Month'; // 'Today', '7 Days', '30 Days', 'This Month', 'Last Month'
  AdminRole? _selectedAdminRoleFilter; // null = 'All Roles'
  String _serviceLeadCategoryFilter = 'ALL';
  String _serviceLeadAssignmentFilter = 'ALL';
  List<Map<String, dynamic>> _serviceLeads = [];
  bool _loadingServiceLeads = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    if (!UserSession.isAdmin && UserSession.isCrmAuthorized && _selectedNavIndex == 0) {
      _selectedNavIndex = 20; // Default to CRM Dashboard for non-admin CRM users
    }
    _adminService.addListener(_onAdminServiceUpdate);
    _commandService.addListener(_onCommandServiceUpdate);
    _loadLiveBackendData();
  }

  @override
  void didUpdateWidget(covariant AdminPanelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialNavIndex != widget.initialNavIndex) {
      setState(() {
        _selectedNavIndex = widget.initialNavIndex;
      });
    }
  }

  Future<void> _loadLiveBackendData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    try {
      await Future.wait([
        _adminService.refreshFromSupabase(),
        _commandService.loadFromSupabase(),
        _loadCrmMetrics(),
        _loadVerificationMetrics(),
        _loadServiceLeads(),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminPanelScreen] Live backend sync error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Unable to load data. Please try again.';
        });
      }
    }
  }

  Future<void> _loadCrmMetrics() async {
    try {
      final metrics = await _crmService.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _crmMetrics = metrics;
        });
      }
    } catch (e) {
      debugPrint('[AdminPanelScreen] CRM Metrics sync error: $e');
    }
  }

  Future<void> _loadVerificationMetrics() async {
    try {
      final metrics = await TrustEngineService.instance.getDashboardMetrics();
      if (mounted) {
        setState(() {
          _verificationMetrics = metrics;
        });
      }
    } catch (e) {
      debugPrint('[AdminPanelScreen] Verification Metrics sync error: $e');
    }
  }

  Future<void> _loadServiceLeads() async {
    if (!mounted) return;
    setState(() => _loadingServiceLeads = true);
    try {
      final leads = await _commandService.fetchServiceLeads(
        serviceCategory: _serviceLeadCategoryFilter,
        assignmentStatus: _serviceLeadAssignmentFilter,
      );
      if (mounted) {
        setState(() {
          _serviceLeads = leads;
          _loadingServiceLeads = false;
        });
      }
    } catch (e) {
      debugPrint('[AdminPanelScreen] _loadServiceLeads error: $e');
      if (mounted) {
        setState(() => _loadingServiceLeads = false);
      }
    }
  }

  @override
  void dispose() {
    _adminService.removeListener(_onAdminServiceUpdate);
    _commandService.removeListener(_onCommandServiceUpdate);
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onAdminServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _onCommandServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFDC2626) : AppTheme.emeraldSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast('Please enter admin credentials.', isError: true);
      return;
    }

    final success = await _adminService.loginAdmin(email: email, password: password);
    if (success) {
      if (mounted) setState(() {});
      _showToast('Welcome to PropZen Command Center!');
    } else {
      _showToast('Invalid credentials. Please try again.', isError: true);
    }
  }

  Future<void> _handleQuickMasterLogin() async {
    final email = UserSession.email.isNotEmpty ? UserSession.email : 'admin@propzen.ai';
    final success = await _adminService.loginAdmin(email: email, password: 'secure_auth');
    if (success) {
      if (mounted) setState(() {});
      _showToast('Logged in as Administrator');
    } else {
      _showToast('Admin verification failed.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step 8: Handle Async Auth & Role Loading State
    if (AuthService.instance.isLoading) {
      return _buildAuthLoadingView();
    }

    // Centralized RBAC Security Guard
    final accessStatus = AuthService.instance.checkCommandCenterAccess();

    if (accessStatus == AdminAccessStatus.unauthenticated) {
      return _buildUnauthenticatedView();
    }
    if (accessStatus == AdminAccessStatus.emailNotVerified) {
      return _buildEmailVerificationRequiredView();
    }
    if (accessStatus == AdminAccessStatus.forbidden403) {
      return _buildAccessDeniedView();
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isDesktop),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildDesktopSidebar(),
          Expanded(
            child: _hasError
                ? _buildErrorRetryView()
                : _buildMainContentArea(isDesktop, isTablet),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 0. AUTH & ROLE LOADING VIEW
  // ===========================================================================
  Widget _buildAuthLoadingView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        ),
        title: Text('Security Gate', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryViolet),
            const SizedBox(height: 20),
            Text('Verifying Security Credentials...', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Checking administrative role and cryptographic claims...', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. UNAUTHENTICATED VIEW (LOGIN REQUIRED)
  // ===========================================================================
  Widget _buildUnauthenticatedView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        ),
        title: Text('Security Gate', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(LucideIcons.lock, color: AppTheme.primaryViolet, size: 48),
              ),
              const SizedBox(height: 20),
              Text('Authentication Required', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'Please sign in with your authorized administrator account to access the PropZen Command Center.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DualAuthScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.logIn, size: 16),
                  label: const Text('Sign In as Admin'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. EMAIL VERIFICATION REQUIRED VIEW
  // ===========================================================================
  Widget _buildEmailVerificationRequiredView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        ),
        title: Text('Security Gate', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(LucideIcons.mailWarning, color: Color(0xFFF59E0B), size: 48),
              ),
              const SizedBox(height: 20),
              Text('Email Verification Required', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              Text(
                'Your account (${UserSession.email}) must be email-verified before accessing the Command Center.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    _showToast('Refreshing verification status...');
                    await AuthService.instance.forceRefreshAdminPrivileges();
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Refresh Status'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. ACCESS DENIED (403 FORBIDDEN) VIEW
  // ===========================================================================
  Widget _buildAccessDeniedView() {
    final currentRole = UserSession.roleTierNotifier.value.isNotEmpty ? UserSession.roleTierNotifier.value : 'USER';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            }
          },
        ),
        title: Text(
          'Security Gate',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shieldAlert, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Access Denied (403)',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'Logged in as ${UserSession.email.isNotEmpty ? UserSession.email : "Guest"} (Role: $currentRole).\n\nOnly users with authorized administrator privileges (Role: ADMIN or SUPER_ADMIN) have permission to access the PropZen Command Center.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DualAuthScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.userCheck, size: 16),
                  label: const Text('Switch Account'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                  }
                },
                icon: const Icon(LucideIcons.home, size: 14),
                label: const Text('Return to Home Page'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR & RETRY VIEW
  // ===========================================================================
  Widget _buildErrorRetryView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              'Unable to load data. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Database request failed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadLiveBackendData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LOGIN VIEW
  // ===========================================================================
  Widget _buildLoginView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PropZen Command Center', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Text('Admin & Business Ecosystem', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Admin Email', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginEmailController,
                  onSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: 'admin@propzen.ai',
                    prefixIcon: const Icon(LucideIcons.mail, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Master Password', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  onSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogin,
                    icon: const Icon(LucideIcons.logIn, size: 18, color: Colors.white),
                    label: Text('Sign In to Command Center', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _handleQuickMasterLogin,
                    icon: const Icon(LucideIcons.zap, size: 15, color: AppTheme.primaryViolet),
                    label: Text('Quick Super Admin Access', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryViolet),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // APP BAR
  // ===========================================================================
  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      leading: !isDesktop
          ? null
          : IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              tooltip: 'Back to Home',
              onPressed: () {
                if (widget.onBackToHome != null) {
                  widget.onBackToHome!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('PropZen Command Center', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text('PROD BACKEND', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
              ),
            ],
          ),
          Text('Manage your property ecosystem from one place.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
      actions: [
        // Role Switcher / Filter Dropdown
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AdminRole?>(
              value: _selectedAdminRoleFilter,
              hint: Text('All Roles', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              icon: const Icon(LucideIcons.chevronDown, size: 14),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              items: [
                const DropdownMenuItem<AdminRole?>(
                  value: null,
                  child: Text('All Roles'),
                ),
                ...AdminRole.values.map((role) {
                  return DropdownMenuItem<AdminRole?>(
                    value: role,
                    child: Text(role.displayName),
                  );
                }),
              ],
              onChanged: (newRole) {
                setState(() {
                  _selectedAdminRoleFilter = newRole;
                });
                if (newRole != null) {
                  _commandService.switchRole(newRole);
                  _showToast('Filtered by ${newRole.displayName}');
                } else {
                  _showToast('Showing all administrator roles');
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Sync Backend Data',
          icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppTheme.primaryViolet),
          onPressed: () async {
            await _loadLiveBackendData();
            if (!_hasError) {
              _showToast('Synced live data from Supabase backend!');
            }
          },
        ),
        IconButton(
          tooltip: 'Sign Out Admin',
          icon: const Icon(LucideIcons.logOut, size: 18, color: Colors.redAccent),
          onPressed: () {
            _adminService.logoutAdmin();
            _showToast('Signed out of Command Center.');
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppTheme.borderLight),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP SIDEBAR
  // ===========================================================================
  Widget _buildDesktopSidebar() {
    final isFullAdmin = UserSession.isAdmin;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSidebarGroupHeader('CORE ECOSYSTEM'),
          _buildSidebarNavItem(0, 'Dashboard Overview', LucideIcons.layoutDashboard),
          if (isFullAdmin) ...[
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.barChart2, size: 18, color: Color(0xFF7C3AED)),
              title: Text(
                '📊 Super Dashboard & SEO',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED)),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
                ),
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.superDashboard),
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.wallet, size: 18, color: Color(0xFF10B981)),
              title: Text(
                '💰 Monetization & Lead Management',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.vendorWallet),
            ),
            _buildSidebarNavItem(1, 'Properties & Moderation', LucideIcons.building2, count: _commandService.totalPropertiesCount),
            _buildSidebarNavItem(
              2,
              'AI Property Verification',
              LucideIcons.shieldCheck,
              subtitle: 'AI-powered property & document verification',
              count: _verificationMetrics?.underReview ?? _commandService.pendingPropertiesCount,
              isAlert: (_verificationMetrics?.underReview ?? _commandService.pendingPropertiesCount) > 0,
            ),
            _buildSidebarNavItem(3, 'Dealers & Verification', LucideIcons.briefcase, count: _commandService.totalDealersCount),
            _buildSidebarNavItem(4, 'User Management', LucideIcons.users, count: _commandService.totalUsersCount),
            _buildSidebarNavItem(18, 'Service Partners & Categories', LucideIcons.hammer, count: _commandService.servicePartners.length),
          ],

          const Divider(height: 20, color: AppTheme.borderLight),
          _buildSidebarGroupHeader('CRM'),
          _buildSidebarNavItem(20, 'CRM Dashboard', LucideIcons.layoutGrid),
          _buildSidebarNavItem(21, 'Leads', LucideIcons.users, count: _crmMetrics?.totalLeads),
          _buildSidebarNavItem(22, 'Customers', LucideIcons.userCheck),
          _buildSidebarNavItem(23, 'Follow-ups', LucideIcons.clock, count: _crmMetrics?.followUpsDue, isAlert: (_crmMetrics?.followUpsDue ?? 0) > 0),
          _buildSidebarNavItem(24, 'Tasks', LucideIcons.checkSquare),
          _buildSidebarNavItem(25, 'Properties', LucideIcons.building),
          _buildSidebarNavItem(26, 'Site Visits', LucideIcons.calendarCheck, count: _adminService.siteVisitsCount),
          _buildSidebarNavItem(27, 'WhatsApp Campaigns', LucideIcons.messageSquare),
          _buildSidebarNavItem(28, 'Campaign History', LucideIcons.history),
          _buildSidebarNavItem(29, 'Analytics', LucideIcons.trendingUp),

          if (isFullAdmin) ...[
            const Divider(height: 20, color: AppTheme.borderLight),
            _buildSidebarGroupHeader('OPERATIONS & INTELLIGENCE'),
            _buildSidebarNavItem(5, 'Lead Pipeline', LucideIcons.filter),
            _buildSidebarNavItem(6, 'Site Visits Scheduler', LucideIcons.calendarCheck, count: _adminService.siteVisitsCount),
            _buildSidebarNavItem(7, 'NRI & Remote Tours', LucideIcons.globe),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.badgePercent, size: 18, color: Color(0xFF4F46E5)),
              title: Text('Loan Facilities', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              onTap: () => Navigator.pushNamed(context, AppRoutes.loanAdvisor),
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.compass, size: 18, color: Color(0xFF4F46E5)),
              title: Text('Design Studio', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              onTap: () => Navigator.pushNamed(context, AppRoutes.designStudio),
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.video, size: 18, color: Color(0xFF4F46E5)),
              title: Text('PropZen Reporter', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              onTap: () => Navigator.pushNamed(context, AppRoutes.reporterFeed),
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.globe, size: 18, color: Color(0xFF4F46E5)),
              title: Text('NRI Intelligence', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              onTap: () => Navigator.pushNamed(context, AppRoutes.nriValuation),
            ),

            const Divider(height: 20, color: AppTheme.borderLight),
            _buildSidebarGroupHeader('BUSINESS & FINANCE'),
            _buildSidebarNavItem(8, 'Subscriptions & Plans', LucideIcons.creditCard),
            _buildSidebarNavItem(9, 'Payments & Revenue', LucideIcons.indianRupee, count: _commandService.payments.length),
            _buildSidebarNavItem(10, 'Complaints & Reports', LucideIcons.alertCircle, count: _commandService.openComplaintsCount, isAlert: _commandService.openComplaintsCount > 0),

            const Divider(height: 20, color: AppTheme.borderLight),
            _buildSidebarGroupHeader('PLATFORM & SECURITY'),
            _buildSidebarNavItem(11, 'Content & Featured', LucideIcons.sparkles),
            _buildSidebarNavItem(12, 'Notification Center', LucideIcons.bell),
            _buildSidebarNavItem(13, 'AI Monitoring', LucideIcons.bot),
            _buildSidebarNavItem(14, 'System Health', LucideIcons.activity),
            _buildSidebarNavItem(15, 'Audit Logs', LucideIcons.fileText, count: _commandService.auditLogs.length),
            _buildSidebarNavItem(16, 'Settings & RBAC', LucideIcons.settings),
            _buildSidebarNavItem(17, 'Features 19–24 Command Hub', LucideIcons.layers),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSidebarNavItem(int index, String label, IconData icon, {int? count, bool isAlert = false, String? subtitle}) {
    final isSelected = _selectedNavIndex == index;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: Icon(icon, size: 18, color: isSelected ? const Color(0xFF4F46E5) : AppTheme.textSecondary),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF4F46E5) : AppTheme.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSelected ? const Color(0xFF6366F1) : AppTheme.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: count != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAlert
                    ? const Color(0xFFDC2626)
                    : (isSelected ? const Color(0xFF4F46E5) : AppTheme.surfaceHighlight),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: (isAlert || isSelected) ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            )
          : null,
      onTap: () => setState(() => _selectedNavIndex = index),
    );
  }

  // ===========================================================================
  // MOBILE DRAWER
  // ===========================================================================
  Widget _buildDrawer() {
    final isFullAdmin = UserSession.isAdmin;

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text('PropZen Command Center', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${_commandService.currentAdmin.name} (${_commandService.currentRole.displayName})', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
          _buildSidebarNavItem(0, 'Dashboard Overview', LucideIcons.layoutDashboard),
          if (isFullAdmin) ...[
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.barChart2, size: 18, color: Color(0xFF7C3AED)),
              title: Text(
                '📊 Super Dashboard & SEO',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.superDashboard);
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(LucideIcons.wallet, size: 18, color: Color(0xFF10B981)),
              title: Text(
                '💰 Monetization & Lead Management',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.vendorWallet);
              },
            ),
            _buildSidebarNavItem(1, 'Properties', LucideIcons.building2, count: _commandService.totalPropertiesCount),
            _buildSidebarNavItem(
              2,
              'AI Property Verification',
              LucideIcons.shieldCheck,
              subtitle: 'AI-powered property & document verification',
              count: _verificationMetrics?.underReview ?? _commandService.pendingPropertiesCount,
              isAlert: (_verificationMetrics?.underReview ?? _commandService.pendingPropertiesCount) > 0,
            ),
            _buildSidebarNavItem(3, 'Dealers', LucideIcons.briefcase, count: _commandService.totalDealersCount),
            _buildSidebarNavItem(4, 'Users', LucideIcons.users, count: _commandService.totalUsersCount),
            _buildSidebarNavItem(18, 'Service Partners', LucideIcons.hammer, count: _commandService.servicePartners.length),
          ],

          const Divider(height: 16),
          _buildSidebarGroupHeader('CRM'),
          _buildSidebarNavItem(20, 'CRM Dashboard', LucideIcons.layoutGrid),
          _buildSidebarNavItem(21, 'Leads', LucideIcons.users, count: _crmMetrics?.totalLeads),
          _buildSidebarNavItem(22, 'Customers', LucideIcons.userCheck),
          _buildSidebarNavItem(23, 'Follow-ups', LucideIcons.clock, count: _crmMetrics?.followUpsDue, isAlert: (_crmMetrics?.followUpsDue ?? 0) > 0),
          _buildSidebarNavItem(24, 'Tasks', LucideIcons.checkSquare),
          _buildSidebarNavItem(25, 'Properties', LucideIcons.building),
          _buildSidebarNavItem(26, 'Site Visits', LucideIcons.calendarCheck, count: _adminService.siteVisitsCount),
          _buildSidebarNavItem(27, 'WhatsApp Campaigns', LucideIcons.messageSquare),
          _buildSidebarNavItem(28, 'Campaign History', LucideIcons.history),
          _buildSidebarNavItem(29, 'Analytics', LucideIcons.trendingUp),
          _buildSidebarNavItem(
            30,
            'Service Lead Routing',
            LucideIcons.share2,
            count: _serviceLeads.where((l) => l['assignmentStatus'] == 'UNASSIGNED').length,
            isAlert: _serviceLeads.any((l) => l['assignmentStatus'] == 'UNASSIGNED'),
          ),

          if (isFullAdmin) ...[
            const Divider(height: 16),
            _buildSidebarNavItem(5, 'Leads Pipeline', LucideIcons.filter),
            _buildSidebarNavItem(6, 'Site Visits', LucideIcons.calendarCheck, count: _adminService.siteVisitsCount),
            _buildSidebarNavItem(7, 'NRI & Remote Tours', LucideIcons.globe),
            _buildSidebarNavItem(8, 'Subscriptions', LucideIcons.creditCard),
            _buildSidebarNavItem(9, 'Payments & Revenue', LucideIcons.indianRupee),
            _buildSidebarNavItem(10, 'Complaints', LucideIcons.alertCircle, count: _commandService.openComplaintsCount),
            _buildSidebarNavItem(11, 'Content & Featured', LucideIcons.sparkles),
            _buildSidebarNavItem(12, 'Notification Center', LucideIcons.bell),
            _buildSidebarNavItem(13, 'AI Monitoring', LucideIcons.bot),
            _buildSidebarNavItem(14, 'System Health', LucideIcons.activity),
            _buildSidebarNavItem(15, 'Audit Logs', LucideIcons.fileText),
            _buildSidebarNavItem(16, 'Settings & Roles', LucideIcons.settings),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // MAIN CONTENT DISPATCHER
  // ===========================================================================
  Widget _buildMainContentArea(bool isDesktop, bool isTablet) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardOverview(isDesktop, isTablet);
      case 1:
        return _buildPropertiesWorkspace(isDesktop);
      case 2:
        return _buildVerificationWorkspace(isDesktop);
      case 3:
        return _buildDealersWorkspace(isDesktop);
      case 4:
        return _buildUsersWorkspace(isDesktop);
      case 5:
        return CrmLeadsScreen(initialLeadId: widget.initialLeadId);
      case 6:
        return _buildSiteVisitsWorkspace(isDesktop);
      case 7:
        return _buildNriWorkspace(isDesktop);
      case 8:
        return _buildSubscriptionsWorkspace(isDesktop);
      case 9:
        return _buildPaymentsWorkspace(isDesktop);
      case 10:
        return _buildComplaintsWorkspace(isDesktop);
      case 11:
        return _buildContentWorkspace(isDesktop);
      case 12:
        return _buildNotificationsWorkspace(isDesktop);
      case 13:
        return _buildAiMonitoringWorkspace(isDesktop);
      case 14:
        return _buildSystemHealthWorkspace(isDesktop);
      case 15:
        return _buildAuditLogsWorkspace(isDesktop);
      case 16:
        return _buildSettingsWorkspace(isDesktop);
      case 17:
        return _buildFeatures19To24Workspace(isDesktop);
      case 18:
        return _buildServicePartnersWorkspace(isDesktop);

      // CRM Workspaces (Indices 20 to 29)
      case 20:
        return const CrmDashboardScreen();
      case 21:
        return CrmLeadsScreen(initialLeadId: widget.initialLeadId);
      case 22:
        return const CrmCustomer360Screen();
      case 23:
        return const CrmFollowUpsScreen();
      case 24:
        return const CrmTasksScreen();
      case 25:
        return const CrmPropertiesScreen();
      case 26:
        return _buildSiteVisitsWorkspace(isDesktop);
      case 27:
        return const CrmCampaignsScreen(initialTab: 0);
      case 28:
        return const CrmCampaignsScreen(initialTab: 1);
      case 29:
        return const CrmAnalyticsScreen();
      case 30:
        return _buildServiceLeadsRoutingWorkspace(isDesktop);

      default:
        return _buildDashboardOverview(isDesktop, isTablet);
    }
  }

  // ===========================================================================
  // SECTION 0: DASHBOARD OVERVIEW & QUICK ACTIONS
  // ===========================================================================
  Widget _buildDashboardOverview(bool isDesktop, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('PropZen Command Center', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text('Manage your property ecosystem from one place.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          // Clickable Priority Action Alerts
          _buildQuickActionAlerts(),
          const SizedBox(height: 24),

          // CRM Quick Stats Section (Live Backend Metrics)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.barChart2, size: 18, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Text('CRM Quick Stats', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.arrowRight, size: 14),
                label: const Text('Open CRM Dashboard'),
                onPressed: () => setState(() => _selectedNavIndex = 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              int crossCount = isDesktop ? 4 : (constraints.maxWidth >= 600 ? 3 : 2);
              final metrics = _crmMetrics ?? CrmDashboardMetrics.zero;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: crossCount >= 4 ? 1.5 : 1.35,
                children: [
                  _buildStatCard('Total Leads', '${metrics.totalLeads}', LucideIcons.users, const Color(0xFF6366F1), () => setState(() => _selectedNavIndex = 21)),
                  _buildStatCard('New Leads Today', '${metrics.newLeads}', LucideIcons.sparkles, const Color(0xFF0EA5E9), () => setState(() => _selectedNavIndex = 21)),
                  _buildStatCard('Hot Leads', '${metrics.qualifiedLeads}', LucideIcons.flame, const Color(0xFFF97316), () => setState(() => _selectedNavIndex = 21)),
                  _buildStatCard('Follow-ups Due Today', '${metrics.followUpsDue}', LucideIcons.calendar, const Color(0xFFEAB308), () => setState(() => _selectedNavIndex = 23)),
                  _buildStatCard('Overdue Follow-ups', '${metrics.lostLeads}', LucideIcons.alertTriangle, const Color(0xFFEF4444), () => setState(() => _selectedNavIndex = 23)),
                  _buildStatCard('Site Visits Today', '${metrics.siteVisits}', LucideIcons.calendarCheck, const Color(0xFFEC4899), () => setState(() => _selectedNavIndex = 26)),
                  _buildStatCard('Overall Conversion', '${metrics.conversionRate.toStringAsFixed(1)}%', LucideIcons.trendingUp, AppTheme.emeraldSuccess, () => setState(() => _selectedNavIndex = 29)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // AI Property Verification Section (Live Backend Telemetry)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 8),
                  Text('AI Property Verification Engine', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              TextButton.icon(
                icon: const Icon(LucideIcons.arrowRight, size: 14),
                label: const Text('Open Verification Engine'),
                onPressed: () => setState(() => _selectedNavIndex = 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              int crossCount = isDesktop ? 4 : (constraints.maxWidth >= 600 ? 3 : 2);
              final vMetrics = _verificationMetrics ?? VerificationMetrics.zero;
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: crossCount >= 4 ? 1.5 : 1.35,
                children: [
                  _buildStatCard('Total AI Cases', '${vMetrics.totalCases}', LucideIcons.fileText, const Color(0xFF4F46E5), () => setState(() => _selectedNavIndex = 2)),
                  _buildStatCard('AI Verified', '${vMetrics.verified}', LucideIcons.checkCircle2, AppTheme.emeraldSuccess, () => setState(() => _selectedNavIndex = 2)),
                  _buildStatCard('Under Review', '${vMetrics.underReview}', LucideIcons.clock, const Color(0xFFF59E0B), () => setState(() => _selectedNavIndex = 2)),
                  _buildStatCard('High Risk Cases', '${vMetrics.highRisk}', LucideIcons.alertTriangle, const Color(0xFFEF4444), () => setState(() => _selectedNavIndex = 2)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // KPI Stats Grid (12 Real Metrics)
          Text('Operational Overview', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              int crossCount = isDesktop ? 4 : (constraints.maxWidth >= 600 ? 3 : 2);
              return GridView.count(
                crossAxisCount: crossCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: crossCount >= 4 ? 1.5 : 1.35,
                children: [
                  _buildStatCard('Total Users', '${_commandService.totalUsersCount}', LucideIcons.users, const Color(0xFF0EA5E9), () => setState(() => _selectedNavIndex = 4)),
                  _buildStatCard('Active Users', '${_commandService.activeUsersCount}', LucideIcons.userCheck, AppTheme.emeraldSuccess, () => setState(() => _selectedNavIndex = 4)),
                  _buildStatCard('Total Dealers', '${_commandService.totalDealersCount}', LucideIcons.briefcase, const Color(0xFF6366F1), () => setState(() => _selectedNavIndex = 3)),
                  _buildStatCard('Verified Dealers', '${_commandService.verifiedDealersCount}', LucideIcons.badgeCheck, AppTheme.emeraldSuccess, () => setState(() => _selectedNavIndex = 3)),
                  _buildStatCard('Service Partners', '${_commandService.servicePartners.length}', LucideIcons.hammer, const Color(0xFFF59E0B), () => setState(() => _selectedNavIndex = 18)),
                  _buildStatCard('Total Properties', '${_commandService.totalPropertiesCount}', LucideIcons.building2, const Color(0xFF8B5CF6), () => setState(() => _selectedNavIndex = 1)),
                  _buildStatCard('Approved Properties', '${_commandService.approvedPropertiesCount}', LucideIcons.checkCircle2, AppTheme.emeraldSuccess, () => setState(() => _selectedNavIndex = 1)),
                  _buildStatCard('Pending Reviews', '${_commandService.pendingPropertiesCount}', LucideIcons.clock, const Color(0xFFD97706), () => setState(() => _selectedNavIndex = 2)),
                  _buildStatCard('Site Visits', '${_adminService.siteVisitsCount}', LucideIcons.calendarCheck, const Color(0xFFEC4899), () => setState(() => _selectedNavIndex = 6)),
                  _buildStatCard('Active Subscriptions', '${_commandService.payments.length}', LucideIcons.creditCard, const Color(0xFF14B8A6), () => setState(() => _selectedNavIndex = 8)),
                  _buildStatCard('Total Revenue', '₹${(_commandService.totalRevenueRupees / 1000).toStringAsFixed(1)}k', LucideIcons.indianRupee, const Color(0xFF10B981), () => setState(() => _selectedNavIndex = 9)),
                  _buildStatCard('Open Complaints', '${_commandService.openComplaintsCount}', LucideIcons.alertCircle, const Color(0xFFEF4444), () => setState(() => _selectedNavIndex = 10)),
                  _buildStatCard('AI Queries Today', '${_commandService.aiMetrics.totalRequests}', LucideIcons.bot, const Color(0xFF6366F1), () => setState(() => _selectedNavIndex = 13)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionAlerts() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if ((_crmMetrics?.followUpsDue ?? 0) > 0)
          _buildActionBanner(
            title: '${_crmMetrics?.followUpsDue} Follow-ups Due Today',
            subtitle: 'Prospective buyers scheduled for immediate callback',
            color: const Color(0xFFF59E0B),
            icon: LucideIcons.phoneCall,
            onTap: () => setState(() => _selectedNavIndex = 23),
          ),
        _buildActionBanner(
          title: 'Super Dashboard & SEO',
          subtitle: 'Real-time Analytics, JSON-LD Schema & Slugs',
          color: const Color(0xFF7C3AED),
          icon: LucideIcons.barChart2,
          onTap: () => Navigator.pushNamed(context, AppRoutes.superDashboard),
        ),
        _buildActionBanner(
          title: 'Monetization & Lead Management',
          subtitle: 'Dealer Wallets, Lead Distribution & Pricing',
          color: const Color(0xFF10B981),
          icon: LucideIcons.wallet,
          onTap: () => Navigator.pushNamed(context, AppRoutes.vendorWallet),
        ),
        _buildActionBanner(
          title: 'AI Property Verification Engine',
          subtitle: '8-step legal, deed & encumbrance telemetry audit',
          color: const Color(0xFF4F46E5),
          icon: LucideIcons.shieldCheck,
          onTap: () => setState(() => _selectedNavIndex = 2),
        ),
        if (_commandService.pendingPropertiesCount > 0)
          _buildActionBanner(
            title: '${_commandService.pendingPropertiesCount} Pending Properties',
            subtitle: 'New dealer listings waiting for RERA verification',
            color: const Color(0xFFD97706),
            icon: LucideIcons.clock,
            onTap: () => setState(() => _selectedNavIndex = 2),
          ),
        if (_commandService.pendingDealersCount > 0)
          _buildActionBanner(
            title: '${_commandService.pendingDealersCount} Dealer Verifications',
            subtitle: 'Broker credentials submitted for authorization',
            color: const Color(0xFF4F46E5),
            icon: LucideIcons.badgeAlert,
            onTap: () => setState(() => _selectedNavIndex = 3),
          ),
        if (_commandService.servicePartners.where((p) => p.verificationStatus == 'PENDING').isNotEmpty)
          _buildActionBanner(
            title: '${_commandService.servicePartners.where((p) => p.verificationStatus == 'PENDING').length} Partner Verifications',
            subtitle: 'Service partners waiting for specialization category review',
            color: const Color(0xFF0284C7),
            icon: LucideIcons.hammer,
            onTap: () => setState(() => _selectedNavIndex = 18),
          ),
        if (_commandService.openComplaintsCount > 0)
          _buildActionBanner(
            title: '${_commandService.openComplaintsCount} New Complaints',
            subtitle: 'Buyer inquiry tickets require support resolution',
            color: const Color(0xFFDC2626),
            icon: LucideIcons.alertTriangle,
            onTap: () => setState(() => _selectedNavIndex = 10),
          ),
      ],
    );
  }

  Widget _buildActionBanner({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.arrowRight, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: PROPERTIES & MODERATION WORKSPACE
  // ===========================================================================
  Widget _buildPropertiesWorkspace(bool isDesktop) {
    final allProps = PropertyStateService.instance.rawProperties;
    var filtered = allProps.where((p) {
      if (_propertyStatusFilter == 'Pending' && !p.isPending) return false;
      if (_propertyStatusFilter == 'Approved' && !p.isPublished) return false;
      if (_propertyStatusFilter == 'Rejected' && !p.isRejected) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.title.toLowerCase().contains(q) || p.sector.toLowerCase().contains(q) || p.city.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Properties & Moderation', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Review, approve, reject, or request correction on listings', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final csv = _commandService.exportDataAsCsv('properties');
                  _showToast('Exported ${allProps.length} properties as CSV.');
                },
                icon: const Icon(LucideIcons.download, size: 14),
                label: const Text('Export CSV'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filters & Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by property, sector or city...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _propertyStatusFilter,
                items: ['All', 'Pending', 'Approved', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _propertyStatusFilter = v ?? 'All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (filtered.isEmpty)
            const EmptyStateView(
              icon: LucideIcons.building2,
              title: 'No Properties Found',
              message: 'No listings match the selected filters.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final prop = filtered[i];
                return _buildPropertyRowCard(prop);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyRowCard(Property prop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              prop.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: AppTheme.surfaceHighlight,
                child: const Icon(LucideIcons.image, color: AppTheme.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prop.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${prop.sector}, ${prop.city} • ${prop.bhk} • ₹${prop.askingPriceCr} Cr', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusTag(prop.status.toUpperCase(), prop.isPublished ? Colors.green : (prop.isPending ? Colors.orange : Colors.red)),
                    const SizedBox(width: 6),
                    if (prop.droneTourAvailable || (prop.droneTourUrl != null && prop.droneTourUrl!.isNotEmpty)) _buildFeatureChip('Drone 4K'),
                    if (prop.virtualTour != null || (prop.virtualTourUrl != null && prop.virtualTourUrl!.isNotEmpty)) _buildFeatureChip('360° Tour'),
                    if ((prop.model3DUrl != null && prop.model3DUrl!.isNotEmpty) || (prop.model3DId != null && prop.model3DId!.isNotEmpty)) _buildFeatureChip('3D Model'),
                  ],
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminPropertyReviewScreen(property: prop)),
                ),
                child: const Text('View Details'),
              ),
              if (prop.isPending) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldSuccess, foregroundColor: Colors.white),
                  onPressed: () async {
                    await _commandService.approveProperty(prop.id);
                    _showToast('Property "${prop.title}" approved.');
                  },
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _promptRejectDialog(prop),
                  child: const Text('Reject'),
                ),
              ],
              if (prop.isPublished)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  onPressed: () => _promptUnpublishDialog(prop),
                  child: const Text('Unpublish'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.surfaceHighlight, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary)),
    );
  }

  Future<void> _promptRejectDialog(Property prop) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Property Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify reason for rejection for "${prop.title}":'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g., Invalid RERA certificate number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reason = controller.text.trim().isEmpty ? 'Document verification mismatch.' : controller.text.trim();
      await _commandService.rejectProperty(prop.id, reason);
      _showToast('Property rejected and logged in Audit.');
    }
  }

  Future<void> _promptUnpublishDialog(Property prop) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpublish Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Specify reason to unpublish "${prop.title}":'),
            const SizedBox(height: 8),
            TextField(controller: controller, maxLines: 2, decoration: const InputDecoration(hintText: 'e.g., Sold out / inventory withdrawn')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpublish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reason = controller.text.trim().isEmpty ? 'Admin unpublish action.' : controller.text.trim();
      await _commandService.unpublishProperty(prop.id, reason);
      _showToast('Property unpublished.');
    }
  }

  // ===========================================================================
  // SECTION 2: VERIFICATION WORKSPACE
  // ===========================================================================
  Widget _buildVerificationWorkspace(bool isDesktop) {
    return VerificationWorkspaceView(isDesktop: isDesktop);
  }

  // ===========================================================================
  // SECTION 3: DEALERS WORKSPACE
  // ===========================================================================
  // ===========================================================================
  // SECTION 3: DEALER VERIFICATION & ONBOARDING WORKSPACE
  // ===========================================================================
  String _normalizeDealerStatus(DealerAccountModel d) {
    final s = d.verificationStatus.toUpperCase().trim();
    if (s == 'APPROVED') return 'VERIFIED';
    if (s == 'NEEDS REVIEW' || s == 'NEEDS_REVIEW') return 'UNDER_REVIEW';
    if (d.accountStatus.toUpperCase() == 'SUSPENDED' || s == 'SUSPENDED') return 'SUSPENDED';
    return s;
  }

  Color _getDealerStatusColor(String status) {
    switch (status) {
      case 'VERIFIED':
        return AppTheme.emeraldSuccess;
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'UNDER_REVIEW':
        return const Color(0xFF7C3AED);
      case 'REJECTED':
        return AppTheme.coralDanger;
      case 'SUSPENDED':
        return const Color(0xFF64748B);
      default:
        return AppTheme.primaryViolet;
    }
  }

  Widget _buildDealersWorkspace(bool isDesktop) {
    final allDealers = _commandService.dealers;

    // Filter computation
    final pendingCount = allDealers.where((d) => _normalizeDealerStatus(d) == 'PENDING').length;
    final reviewCount = allDealers.where((d) => _normalizeDealerStatus(d) == 'UNDER_REVIEW').length;
    final verifiedCount = allDealers.where((d) => _normalizeDealerStatus(d) == 'VERIFIED').length;
    final rejectedCount = allDealers.where((d) => _normalizeDealerStatus(d) == 'REJECTED').length;
    final suspendedCount = allDealers.where((d) => _normalizeDealerStatus(d) == 'SUSPENDED').length;

    List<DealerAccountModel> filteredDealers = allDealers;
    if (_dealerStatusFilter != 'ALL') {
      filteredDealers = allDealers.where((d) => _normalizeDealerStatus(d) == _dealerStatusFilter).toList();
    }

    final filterTabs = [
      {'label': 'ALL', 'count': allDealers.length},
      {'label': 'PENDING', 'count': pendingCount},
      {'label': 'UNDER_REVIEW', 'count': reviewCount},
      {'label': 'VERIFIED', 'count': verifiedCount},
      {'label': 'REJECTED', 'count': rejectedCount},
      {'label': 'SUSPENDED', 'count': suspendedCount},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.badgeCheck, color: AppTheme.primaryViolet, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dealer Verification & Onboarding',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Review RERA credentials, license documents, and manage authorized partner dealer accounts',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5-State Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterTabs.map((tab) {
                final label = tab['label'] as String;
                final count = tab['count'] as int;
                final isSelected = _dealerStatusFilter == label;
                final color = label == 'ALL' ? AppTheme.primaryViolet : _getDealerStatusColor(label);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      '$label ($count)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? color : AppTheme.borderLight,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _dealerStatusFilter = label);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          if (filteredDealers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.shieldAlert, size: 36, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No dealers in "$_dealerStatusFilter" status',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Switch status filter tabs to inspect other broker verification records.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDealers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final dlr = filteredDealers[i];
                final normStatus = _normalizeDealerStatus(dlr);
                final statusColor = _getDealerStatusColor(normStatus);

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: const [
                      BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar, Name, Firm, RERA & Status Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: statusColor.withOpacity(0.12),
                            child: Text(
                              dlr.name.isNotEmpty ? dlr.name.substring(0, 1).toUpperCase() : 'D',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dlr.firmName.isNotEmpty ? dlr.firmName : dlr.name,
                                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        normStatus,
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Applicant: ${dlr.name} • Contact: ${dlr.phone} • ${dlr.email}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Verification Details Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _buildDealerDetailChip(LucideIcons.badgeCheck, 'RERA Number', dlr.reraId.isNotEmpty ? dlr.reraId : 'Under Submission'),
                            _buildDealerDetailChip(LucideIcons.clock, 'Experience', dlr.experienceYears),
                            _buildDealerDetailChip(LucideIcons.star, 'Rating', '${dlr.rating} / 5.0'),
                            _buildDealerDetailChip(LucideIcons.calendar, 'Applied On', dlr.submissionDate ?? '2026-08-20'),
                            _buildDealerDetailChip(LucideIcons.creditCard, 'Plan', dlr.subscriptionPlan),
                            _buildDealerDetailChip(LucideIcons.building, 'Active Listings', '${dlr.activeListings} Properties'),
                          ],
                        ),
                      ),

                      // Submitted Documents List
                      if (dlr.submittedDocuments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(LucideIcons.fileText, size: 14, color: AppTheme.primaryViolet),
                            const SizedBox(width: 6),
                            Text(
                              'Submitted Documents for Review:',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: dlr.submittedDocuments.map((doc) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.paperclip, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(doc, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Reason or Notes Banner
                      if (dlr.statusReason?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.info, size: 14, color: Color(0xFFB45309)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Audit Note: ${dlr.statusReason}',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 14),

                      // Action Buttons Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // 1. Approve (changes status to VERIFIED)
                          if (normStatus != 'VERIFIED')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.emeraldSuccess,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                await _commandService.updateDealerVerificationStatus(dlr.id, 'VERIFIED');
                                _showToast('Dealer "${dlr.name}" approved and granted portal access.');
                              },
                              icon: const Icon(LucideIcons.check, size: 14),
                              label: const Text('Approve (Verify)'),
                            ),

                          // 2. Under Review (marks as actively being reviewed)
                          if (normStatus != 'UNDER_REVIEW')
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side: const BorderSide(color: Color(0xFF7C3AED)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                await _commandService.updateDealerVerificationStatus(dlr.id, 'UNDER_REVIEW');
                                _showToast('Dealer "${dlr.name}" marked as Under Review.');
                              },
                              icon: const Icon(LucideIcons.clock, size: 14),
                              label: const Text('Under Review'),
                            ),

                          // 3. Request Correction (marks with notes for applicant)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              side: const BorderSide(color: Color(0xFFD97706)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _promptDealerCorrectionDialog(dlr),
                            icon: const Icon(LucideIcons.edit3, size: 14),
                            label: const Text('Request Correction'),
                          ),

                          // 4. Reject (with mandatory reason, status to REJECTED)
                          if (normStatus != 'REJECTED')
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.coralDanger,
                                side: const BorderSide(color: AppTheme.coralDanger),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _promptDealerRejectDialog(dlr),
                              icon: const Icon(LucideIcons.xCircle, size: 14),
                              label: const Text('Reject'),
                            ),

                          // 5. Suspend / Unsuspend (for existing dealers)
                          if (normStatus == 'SUSPENDED')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                await _commandService.updateDealerVerificationStatus(dlr.id, 'VERIFIED');
                                _showToast('Dealer "${dlr.name}" unsuspended.');
                              },
                              icon: const Icon(LucideIcons.unlock, size: 14),
                              label: const Text('Unsuspend'),
                            )
                          else if (normStatus == 'VERIFIED')
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF64748B),
                                side: const BorderSide(color: Color(0xFF64748B)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _promptDealerSuspendDialog(dlr),
                              icon: const Icon(LucideIcons.lock, size: 14),
                              label: const Text('Suspend'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDealerDetailChip(IconData icon, String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.primaryViolet),
        const SizedBox(width: 5),
        Text(
          '$title: ',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Future<void> _promptDealerCorrectionDialog(DealerAccountModel dlr) async {
    final controller = TextEditingController(text: dlr.statusReason ?? '');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Request Dealer Correction', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify what document or detail "${dlr.name}" must rectify:',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Please upload renewal certificate for RERA license or clear PAN scan.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send Correction Request'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final note = controller.text.trim().isEmpty ? 'Document verification requires clarification.' : controller.text.trim();
      await _commandService.updateDealerVerificationStatus(dlr.id, 'UNDER_REVIEW', reason: note);
      _showToast('Correction requested from "${dlr.name}".');
    }
  }

  Future<void> _promptDealerRejectDialog(DealerAccountModel dlr) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Dealer Application', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coralDanger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mandatory rejection reason for "${dlr.name} (${dlr.firmName})":',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Unverified brokerage credentials or non-matching RERA records.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralDanger, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Rejection reason is mandatory.'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirm == true && controller.text.trim().isNotEmpty) {
      await _commandService.updateDealerVerificationStatus(dlr.id, 'REJECTED', reason: controller.text.trim());
      _showToast('Dealer "${dlr.name}" application rejected.');
    }
  }

  Future<void> _promptDealerSuspendDialog(DealerAccountModel dlr) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Suspend Dealer Account', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify reason to temporarily suspend "${dlr.name}":', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Investigation into listing irregularities or compliance hold.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64748B), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspend Account'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reason = controller.text.trim().isEmpty ? 'Account compliance hold.' : controller.text.trim();
      await _commandService.updateDealerVerificationStatus(dlr.id, 'SUSPENDED', reason: reason);
      _showToast('Dealer "${dlr.name}" suspended.');
    }
  }

  // ===========================================================================
  // SECTION 4: USERS WORKSPACE
  // ===========================================================================
  Widget _buildUsersWorkspace(bool isDesktop) {
    final users = _commandService.users;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Account Management', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Manage buyers, NRI investors, dealers, and staff with secure privacy controls', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          if (users.isEmpty)
            const EmptyStateView(
              icon: LucideIcons.users,
              title: 'No users registered',
              message: 'Registered customer and staff accounts from Supabase will appear here.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final u = users[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.12),
                        child: Text(u.fullName.isNotEmpty ? u.fullName.substring(0, 1) : 'U', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF0EA5E9))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.fullName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('${u.email} • ${u.phone}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusTag(u.userType.toUpperCase(), const Color(0xFF4F46E5)),
                                const SizedBox(width: 6),
                                _buildStatusTag(u.accountStatus.toUpperCase(), u.isActive ? Colors.green : Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (u.isActive)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () async {
                            await _commandService.suspendUser(u.id, 'Admin compliance suspension.');
                            _showToast('User "${u.fullName}" suspended in Supabase.');
                          },
                          child: const Text('Suspend'),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldSuccess, foregroundColor: Colors.white),
                          onPressed: () async {
                            await _commandService.reactivateUser(u.id);
                            _showToast('User "${u.fullName}" reactivated in Supabase.');
                          },
                          child: const Text('Reactivate'),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: LEADS WORKSPACE
  // ===========================================================================
  Widget _buildLeadsWorkspace(bool isDesktop) {
    final leads = DealerLeadService.instance.allLeads;
    final enquiries = _adminService.enquiries;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform Enquiries & Leads', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Monitor buyer intent, property inquiries, and conversion stages in Supabase', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final csv = _commandService.exportDataAsCsv('leads');
                  _showToast('Exported inquiries & leads as CSV.');
                },
                icon: const Icon(LucideIcons.download, size: 14),
                label: const Text('Export Leads'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (enquiries.isNotEmpty) ...[
            Text('Direct Property Enquiries (${enquiries.length})', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: enquiries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final enq = enquiries[i];
                final status = enq['status']?.toString() ?? 'New';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.12), child: const Icon(LucideIcons.mail, size: 18, color: Color(0xFF0EA5E9))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${enq['name'] ?? enq['user_name'] ?? 'Buyer'} • ${enq['property_title'] ?? 'General Enquiry'}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('${enq['email'] ?? enq['user_email'] ?? ''} • ${enq['phone'] ?? enq['user_phone'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                            if (enq['message'] != null && enq['message'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Message: "${enq['message']}"', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildStatusTag(status.toUpperCase(), status.toLowerCase() == 'contacted' ? Colors.blue : (status.toLowerCase() == 'closed' ? Colors.green : Colors.orange)),
                          if (status.toLowerCase() != 'contacted')
                            OutlinedButton(
                              onPressed: () async {
                                await _adminService.updateEnquiryStatus(enq['id']?.toString() ?? '', 'Contacted');
                                _showToast('Marked enquiry as Contacted.');
                              },
                              child: const Text('Contacted'),
                            ),
                          if (status.toLowerCase() != 'closed')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldSuccess, foregroundColor: Colors.white),
                              onPressed: () async {
                                await _adminService.updateEnquiryStatus(enq['id']?.toString() ?? '', 'Closed');
                                _showToast('Marked enquiry as Closed.');
                              },
                              child: const Text('Close'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          if (leads.isNotEmpty) ...[
            Text('Dealer Lead Pipeline (${leads.length})', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final lead = leads[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: const Color(0xFFEC4899).withOpacity(0.12), child: const Icon(LucideIcons.user, size: 18, color: Color(0xFFEC4899))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${lead.buyerName} • Budget ₹${lead.budgetCr} Cr', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Requirement: ${lead.requirement} • Property: ${lead.propertyTitle}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Status: ${lead.enquiryStatus.toUpperCase()} • Score: ${lead.leadScore}/100', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          if (enquiries.isEmpty && leads.isEmpty)
            const EmptyStateView(
              icon: LucideIcons.mail,
              title: 'No enquiries or leads yet',
              message: 'Customer enquiries from property pages will be synced here in real-time.',
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 6: SITE VISITS WORKSPACE
  // ===========================================================================
  Widget _buildSiteVisitsWorkspace(bool isDesktop) {
    final visits = _adminService.siteVisits;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Site Visits Management', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Track scheduled in-person walkthroughs, AC cab dispatch, and buyer attendance', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          if (visits.isEmpty)
            const EmptyStateView(
              icon: LucideIcons.calendar,
              title: 'No site visits scheduled',
              message: 'Property walkthrough bookings from buyers will appear here.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final v = visits[i];
                final status = v['status']?.toString() ?? 'Scheduled';
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(LucideIcons.calendar, size: 18, color: Color(0xFFD97706))),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${v['property_title'] ?? 'Property Tour'} • Visitor: ${v['name'] ?? v['user_name'] ?? 'Buyer'}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Date: ${v['visit_date'] ?? v['date'] ?? ''} • Time: ${v['time_slot'] ?? v['time'] ?? ''} • Cab: ${v['cab_required'] == true ? "Yes" : "No"}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildStatusTag(status.toUpperCase(), status.toLowerCase() == 'completed' ? Colors.green : (status.toLowerCase() == 'cancelled' ? Colors.red : Colors.blue)),
                          if (status.toLowerCase() != 'confirmed' && status.toLowerCase() != 'completed')
                            OutlinedButton(
                              onPressed: () async {
                                await _adminService.updateSiteVisitStatus(v['id']?.toString() ?? '', 'Confirmed');
                                _showToast('Site visit marked as Confirmed.');
                              },
                              child: const Text('Confirm'),
                            ),
                          if (status.toLowerCase() != 'completed')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldSuccess, foregroundColor: Colors.white),
                              onPressed: () async {
                                await _adminService.updateSiteVisitStatus(v['id']?.toString() ?? '', 'Completed');
                                _showToast('Site visit marked as Completed.');
                              },
                              child: const Text('Complete'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 7: NRI & REMOTE TOURS WORKSPACE
  // ===========================================================================
  Widget _buildNriWorkspace(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NRI Remote Property Suite & Live Tours', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Overseas investor pass subscriptions, 4K Drone requests, and live timezone schedulers', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduled 1-on-1 Remote Video Walkthroughs', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(LucideIcons.video, color: Color(0xFF4F46E5))),
                  title: Text('Arjun Singhania (Dubai, UAE) • ATS Knightsbridge', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  subtitle: Text('Preferred Slot: Tomorrow 04:30 PM GST (06:00 PM IST) • Status: Confirmed', style: GoogleFonts.inter(fontSize: 12)),
                  trailing: ElevatedButton(
                    onPressed: () => _showToast('Launched Live Video Room.'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                    child: const Text('Join Room'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 8: SUBSCRIPTIONS & PLANS WORKSPACE
  // ===========================================================================
  Widget _buildSubscriptionsWorkspace(bool isDesktop) {
    final plans = _commandService.plans;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscription Plans & Pricing Control', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Dynamically adjust dealer and NRI tier pricing, lead allocations, and feature sets', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : 1,
              childAspectRatio: isDesktop ? 1.1 : 1.4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: plans.length,
            itemBuilder: (ctx, i) {
              final plan = plans[i];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(plan.planName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                            _buildStatusTag(plan.userType, const Color(0xFF4F46E5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('₹${plan.priceRupees.toStringAsFixed(0)} / ${plan.duration}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                        const SizedBox(height: 8),
                        Text(plan.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, minimumSize: const Size.fromHeight(40)),
                      onPressed: () => _promptEditPlanDialog(plan),
                      child: const Text('Edit Plan Settings'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _promptEditPlanDialog(SubscriptionPlanConfig plan) async {
    final priceController = TextEditingController(text: plan.priceRupees.toStringAsFixed(0));
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${plan.planName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Price (INR):'),
            TextField(controller: priceController, keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final newPrice = double.tryParse(priceController.text.trim()) ?? plan.priceRupees;
      await _commandService.saveSubscriptionPlan(plan.copyWith(priceRupees: newPrice));
      _showToast('Updated plan pricing to ₹$newPrice');
    }
  }

  // ===========================================================================
  // SECTION 9: PAYMENTS & REVENUE WORKSPACE
  // ===========================================================================
  Widget _buildPaymentsWorkspace(bool isDesktop) {
    final payments = _commandService.payments;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payments & Revenue Analytics', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Real transactions processed via Razorpay gateway and UPI architecture', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final csv = _commandService.exportDataAsCsv('payments');
                  _showToast('Exported payment history as CSV.');
                },
                icon: const Icon(LucideIcons.download, size: 14),
                label: const Text('Export Payments'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final pay = payments[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFD1FAE5), child: Icon(LucideIcons.check, color: Color(0xFF059669))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pay.userName} • ₹${pay.amountRupees.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Order: ${pay.orderId} • Plan: ${pay.planName} • ID: ${pay.paymentId}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    if (pay.status == 'Success')
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () async {
                          await _commandService.processRefund(pay.id, 'User requested refund.');
                          _showToast('Processed refund for ${pay.paymentId}.');
                        },
                        child: const Text('Refund'),
                      )
                    else
                      _buildStatusTag(pay.status.toUpperCase(), Colors.orange),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 10: COMPLAINTS & REPORTS WORKSPACE
  // ===========================================================================
  Widget _buildComplaintsWorkspace(bool isDesktop) {
    final complaints = _commandService.complaints;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complaints & User Reports Ticket Queue', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Investigate listing discrepancies, broker issues, and resolution notes', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: complaints.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) {
              final c = complaints[i];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('[${c.ticketNumber}] ${c.title}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                        _buildStatusTag(c.status.toUpperCase(), c.status == 'Resolved' ? Colors.green : Colors.red),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Reporter: ${c.reporterName} (${c.reporterEmail}) • Target: ${c.targetTitle}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Text(c.description, style: GoogleFonts.inter(fontSize: 13)),
                    if (c.resolutionNotes != null) ...[
                      const SizedBox(height: 8),
                      Text('Resolution: ${c.resolutionNotes}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.emeraldSuccess)),
                    ],
                    const SizedBox(height: 12),
                    if (c.status != 'Resolved')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldSuccess, foregroundColor: Colors.white),
                        onPressed: () async {
                          await _commandService.updateComplaintStatus(c.id, 'Resolved', notes: 'Investigated and resolved by Admin.');
                          _showToast('Ticket ${c.ticketNumber} marked resolved.');
                        },
                        child: const Text('Mark as Resolved'),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 11: PROGRAMMATIC SEO & CONTENT AUTOMATION WORKSPACE
  // ===========================================================================
  Widget _buildContentWorkspace(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Programmatic SEO & Content Automation Hub', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Autonomous AI Market Reports, Fact-Check Gates, and Human Review Queue', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                icon: const Icon(LucideIcons.filePlus, size: 16),
                label: const Text('Generate New Market Report'),
                onPressed: () {
                  _showToast('Triggered automated LangGraph market data ingestion and drafting.');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // SEO Key Metric Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dynamic XML Sitemap', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text('18 Active URLs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                      const SizedBox(height: 4),
                      Text('Synced daily via Search Console pipeline', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.emeraldSuccess)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fact-Check Gate Pass Rate', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text('98.4%', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                      const SizedBox(height: 4),
                      Text('100% verified against UP Gov Circle Rates', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Human Reviews', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text('1 Article', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                      const SizedBox(height: 4),
                      Text('Requires 1-click admin sign-off', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Review Queue Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Content Review Queue (Human-in-the-Loop)', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                    _buildStatusTag('AI Quality Score 96/100', AppTheme.emeraldSuccess),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surfaceSubtle, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.fileText, size: 18, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          Text('Sector 150 Noida Real Estate Trends & Price Index', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Slug: /insights/sector-150-noida-property-rates-trends • Source: UP_Gov_Circle_Rates (Validated)', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 10),
                      Text(
                        'Average capital value ₹8,900/sq.ft. (+5.8% QoQ). Highlights 70% low-density green zoning, Sports City developments, and upcoming metro line expansion.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldSuccess, foregroundColor: Colors.white),
                            icon: const Icon(LucideIcons.checkCheck, size: 16),
                            label: const Text('Approve & Publish'),
                            onPressed: () {
                              _showToast('Article approved and published to sitemap.xml.');
                            },
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            icon: const Icon(LucideIcons.eye, size: 16),
                            label: const Text('Preview Page'),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/property-rates/noida/sector-150');
                            },
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                            icon: const Icon(LucideIcons.x, size: 16),
                            label: const Text('Reject'),
                            onPressed: () {
                              _showToast('Draft rejected and archived.', isError: true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic Programmatic Location Pages Links
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Programmatic Location Rate Hubs', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Each page features dynamic real-time circle rates, available inventory, and FAQ structured data.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ActionChip(
                      avatar: const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF4F46E5)),
                      label: const Text('/property-rates/noida/sector-150'),
                      onPressed: () => Navigator.of(context).pushNamed('/property-rates/noida/sector-150'),
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF4F46E5)),
                      label: const Text('/property-rates/noida/sector-137'),
                      onPressed: () => Navigator.of(context).pushNamed('/property-rates/noida/sector-137'),
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF4F46E5)),
                      label: const Text('/property-rates/greater-noida/sector-10'),
                      onPressed: () => Navigator.of(context).pushNamed('/property-rates/greater-noida/sector-10'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 12: NOTIFICATION CENTER WORKSPACE
  // ===========================================================================
  Widget _buildNotificationsWorkspace(bool isDesktop) {
    final notifs = _commandService.notifications;
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String targetAudience = 'All Users';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Broadcast Notification Center', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Dispatch audience-targeted push and in-app announcements', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          // Send New Notification Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Announcement', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Notification Title')),
                const SizedBox(height: 12),
                TextField(controller: messageController, maxLines: 2, decoration: const InputDecoration(labelText: 'Message Body')),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                      _showToast('Please fill in title and message', isError: true);
                      return;
                    }
                    await _commandService.sendBroadcastNotification(
                      title: titleController.text.trim(),
                      message: messageController.text.trim(),
                      notificationType: 'System',
                      audience: targetAudience,
                    );
                    titleController.clear();
                    messageController.clear();
                    _showToast('Broadcast notification sent!');
                  },
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Dispatch Broadcast Notification'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Recent Dispatches', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final n = notifs[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.borderLight)),
                leading: const Icon(LucideIcons.bellRing, color: Color(0xFF4F46E5)),
                title: Text(n.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                subtitle: Text('${n.message}\nAudience: ${n.audience} • Sent by ${n.createdBy}', style: GoogleFonts.inter(fontSize: 12)),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 13: AI MONITORING & FEATURE FLAGS WORKSPACE
  // ===========================================================================
  Widget _buildAiMonitoringWorkspace(bool isDesktop) {
    final metrics = _commandService.aiMetrics;
    final flags = _commandService.featureFlags;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI Super Assistant Monitoring & Feature Toggles', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Operational metrics, voice requests, latency, and real-time feature flags', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          // Operational Metrics
          Row(
            children: [
              Expanded(child: _buildMetricCard('Total AI Requests', '${metrics.totalRequests}', LucideIcons.bot, const Color(0xFF4F46E5))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Voice Queries', '${metrics.voiceRequests}', LucideIcons.mic, const Color(0xFF059669))),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Avg Latency', '${metrics.avgResponseTimeMs.toInt()} ms', LucideIcons.gauge, const Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 24),

          // Feature Flags
          Text('Operational Feature Flags (Server-Side)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('AI Property Advisor (Chat)'),
                  subtitle: const Text('Enable consultative property search and recommendation turns'),
                  value: flags.aiAdvisorEnabled,
                  onChanged: (v) => _commandService.toggleAiFeature('aiAdvisor', v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('AI Indian Female Voice Agent'),
                  subtitle: const Text('Enable voice recognition and Indian English/Hindi TTS synthesis'),
                  value: flags.aiVoiceEnabled,
                  onChanged: (v) => _commandService.toggleAiFeature('aiVoice', v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('AI Dealer Listing Creator'),
                  subtitle: const Text('Enable automated RERA-verified listing description writer'),
                  value: flags.aiListingCreatorEnabled,
                  onChanged: (v) => _commandService.toggleAiFeature('aiListingCreator', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 14: SYSTEM HEALTH WORKSPACE
  // ===========================================================================
  Widget _buildSystemHealthWorkspace(bool isDesktop) {
    final health = _commandService.systemHealth;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Health & Infrastructure Services', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Real-time operational status and API latency across PropZen services', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: health.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final h = health[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFD1FAE5), child: Icon(LucideIcons.activity, color: Color(0xFF059669), size: 18)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.serviceName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(h.details, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Text(h.latencyMs, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(width: 10),
                    _buildStatusTag(h.status.toUpperCase(), Colors.green),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 15: AUDIT LOGS WORKSPACE
  // ===========================================================================
  Widget _buildAuditLogsWorkspace(bool isDesktop) {
    final logs = _commandService.auditLogs;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Immutable Admin Audit Logs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Append-only audit trail recording every administrative moderation and security action', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          if (logs.isEmpty)
            const EmptyStateView(
              icon: LucideIcons.fileText,
              title: 'No Audit Records',
              message: 'No administrative actions have been recorded yet.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final log = logs[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.fileClock, size: 18, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${log.action} • ${log.targetType}: ${log.targetTitle}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Reason: ${log.reason}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Actor: ${log.adminName} • Time: ${log.timestamp}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 16: SETTINGS & RBAC WORKSPACE
  // ===========================================================================
  Widget _buildSettingsWorkspace(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings & Role-Based Access Control', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Admin role permission matrix and security policies', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Profile & Active Session', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Logged In Administrator: ${_commandService.currentAdmin.name}', style: GoogleFonts.inter(fontSize: 13)),
                Text('Email: ${_commandService.currentAdmin.email}', style: GoogleFonts.inter(fontSize: 13)),
                Text('Active Role: ${_commandService.currentRole.displayName}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text('Permission Matrix for ${_commandService.currentRole.displayName}:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildPermissionRow('Manage Users', _commandService.permissions.canManageUsers),
                _buildPermissionRow('Manage Dealers', _commandService.permissions.canManageDealers),
                _buildPermissionRow('Verify Properties', _commandService.permissions.canVerifyProperties),
                _buildPermissionRow('Manage Payments & Refunds', _commandService.permissions.canManagePayments),
                _buildPermissionRow('Manage Subscriptions', _commandService.permissions.canManageSubscriptions),
                _buildPermissionRow('Manage Content & Announcements', _commandService.permissions.canManageContent),
                _buildPermissionRow('Manage Complaints', _commandService.permissions.canManageComplaints),
                _buildPermissionRow('Manage AI Feature Flags', _commandService.permissions.canManageAiConfig),
                _buildPermissionRow('Export Data (CSV / JSON)', _commandService.permissions.canExportData),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Administrator Roster with Dynamic Role Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Administrator Roster', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Filter administrators by system role and permissions', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              // Role Filter Dropdown in Roster Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AdminRole?>(
                    value: _selectedAdminRoleFilter,
                    hint: Text('All Roles', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    icon: const Icon(LucideIcons.chevronDown, size: 14),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    items: [
                      const DropdownMenuItem<AdminRole?>(
                        value: null,
                        child: Text('All Roles'),
                      ),
                      ...AdminRole.values.map((role) {
                        return DropdownMenuItem<AdminRole?>(
                          value: role,
                          child: Text(role.displayName),
                        );
                      }),
                    ],
                    onChanged: (newRole) {
                      setState(() {
                        _selectedAdminRoleFilter = newRole;
                      });
                      if (newRole != null) {
                        _showToast('Filtered by ${newRole.displayName}');
                      } else {
                        _showToast('Showing all administrator roles');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Administrators List matching filter
          Builder(
            builder: (ctx) {
              final admins = _commandService.getFilteredAdministrators(_selectedAdminRoleFilter, searchQuery: _searchQuery);
              if (admins.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const EmptyStateView(
                    icon: LucideIcons.shieldAlert,
                    title: 'No administrators found',
                    message: 'No administrator records match the selected role filter. Try selecting "All Roles" to reset.',
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: admins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final admin = admins[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.12),
                          child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF4F46E5), size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(admin.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('${admin.email} • ID: ${admin.id}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildStatusTag(admin.role.displayName, const Color(0xFF4F46E5)),
                                  const SizedBox(width: 8),
                                  _buildStatusTag(admin.isActive ? 'ACTIVE' : 'INACTIVE', admin.isActive ? Colors.green : Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String perm, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(granted ? LucideIcons.checkCircle : LucideIcons.xCircle, color: granted ? Colors.green : Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(perm, style: GoogleFonts.inter(fontSize: 12, color: granted ? AppTheme.textPrimary : AppTheme.textMuted)),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 17: FEATURES 19-24 COMMAND HUB
  // ===========================================================================
  Widget _buildFeatures19To24Workspace(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.layers, color: AppTheme.primaryViolet, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Features 19–24 Command Center',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                      ),
                      Text(
                        'Unified administration for Loan Products, Construction Marketplace, Community Forum, NRI Hub, Multi-Region Scaling, and Real-Time Construction Tracking.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid of Cards for 6 Features
          GridView.count(
            crossAxisCount: isDesktop ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.6 : 2.2,
            children: [
              _buildFeatureHubCard(
                'Feature 19: Loan Comparison',
                '4 Partner Banks • Active Indicative Rates • EMI Configurator',
                LucideIcons.landmark,
                const Color(0xFF4F46E5),
                () => Navigator.pushNamed(context, AppRoutes.loanComparison),
              ),
              _buildFeatureHubCard(
                'Feature 20: Supplier Directory',
                'Verified Materials • Cement, Steel, Tiles & Contractors',
                LucideIcons.truck,
                const Color(0xFF0EA5E9),
                () => Navigator.pushNamed(context, AppRoutes.constructionMarketplace),
              ),
              _buildFeatureHubCard(
                'Feature 21: Community Forum',
                '10 Discussion Sections • User Moderation & Chat Logs',
                LucideIcons.messageSquare,
                const Color(0xFF10B981),
                () => Navigator.pushNamed(context, AppRoutes.forum),
              ),
              _buildFeatureHubCard(
                'Feature 22: NRI Global Hub',
                'Dynamic Currencies (USD/AED/GBP) • Timezone Cal.com Sync',
                LucideIcons.globe,
                const Color(0xFF8B5CF6),
                () => Navigator.pushNamed(context, AppRoutes.nriHub),
              ),
              _buildFeatureHubCard(
                'Feature 23: Multi-Region Scaling',
                'Noida, Delhi NCR, UP & Pan-India Expansion Geofencing',
                LucideIcons.mapPin,
                const Color(0xFFF59E0B),
                () => Navigator.pushNamed(context, AppRoutes.regions),
              ),
              _buildFeatureHubCard(
                'Feature 24: Construction Progress',
                '13-Phase Milestones • Site Photo Uploads • Review Pipeline',
                LucideIcons.hardHat,
                const Color(0xFFEC4899),
                () => Navigator.pushNamed(context, AppRoutes.constructionProgress),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Launch Phase & Feature Flag Control Panel
          Text('Release Phase & Feature Flag Manager', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: AnimatedBuilder(
              animation: FeatureFlagService.instance,
              builder: (ctx, _) {
                final flags = FeatureFlagService.instance.allFlags;
                final activePhase = FeatureFlagService.instance.activePhase;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Launch Phase:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        DropdownButton<LaunchPhase>(
                          value: activePhase,
                          underline: const SizedBox(),
                          items: LaunchPhase.values
                              .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) FeatureFlagService.instance.setLaunchPhase(v);
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Text('Active Feature Flags (Toggle at Runtime without Redeploying):', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: flags.keys.map((k) {
                        final isEnabled = flags[k] ?? false;
                        return FilterChip(
                          label: Text(k, style: TextStyle(fontSize: 11, color: isEnabled ? Colors.white : AppTheme.textPrimary)),
                          selected: isEnabled,
                          selectedColor: AppTheme.primaryViolet,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            FeatureFlagService.instance.setFeatureFlag(k, val);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHubCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
            ],
          ),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: onTap,
              child: const Text('Open Hub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 18: SERVICE PARTNERS & SPECIALIZATION CATEGORIES
  // ===========================================================================
  Widget _buildServicePartnersWorkspace(bool isDesktop) {
    final allPartners = _commandService.servicePartners;

    // Filter computation
    final verifiedCount = allPartners.where((p) => p.verificationStatus == 'VERIFIED' && p.status != 'SUSPENDED').length;
    final pendingCount = allPartners.where((p) => p.verificationStatus == 'PENDING').length;
    final suspendedCount = allPartners.where((p) => p.isSuspended).length;

    List<ServicePartnerProfile> filtered = allPartners;
    if (_partnerStatusFilter == 'VERIFIED') {
      filtered = filtered.where((p) => p.verificationStatus == 'VERIFIED' && p.status != 'SUSPENDED').toList();
    } else if (_partnerStatusFilter == 'PENDING') {
      filtered = filtered.where((p) => p.verificationStatus == 'PENDING').toList();
    } else if (_partnerStatusFilter == 'SUSPENDED') {
      filtered = filtered.where((p) => p.isSuspended).toList();
    }

    if (_partnerCategoryFilter != 'ALL') {
      filtered = filtered.where((p) =>
        p.serviceCategories.contains(_partnerCategoryFilter) ||
        p.serviceCategory == _partnerCategoryFilter
      ).toList();
    }

    final statusTabs = [
      {'label': 'ALL', 'count': allPartners.length},
      {'label': 'VERIFIED', 'count': verifiedCount},
      {'label': 'PENDING', 'count': pendingCount},
      {'label': 'SUSPENDED', 'count': suspendedCount},
    ];

    final categoryFilterOptions = [
      {'code': 'ALL', 'label': 'All Specializations', 'icon': LucideIcons.layers},
      {'code': 'LOAN', 'label': 'Home Loan', 'icon': LucideIcons.landmark},
      {'code': 'HOME_DESIGN', 'label': 'Home Design', 'icon': LucideIcons.palette},
      {'code': 'VASTU', 'label': 'Vastu', 'icon': LucideIcons.compass},
      {'code': 'CONSTRUCTION', 'label': 'Construction', 'icon': LucideIcons.hardHat},
      {'code': 'PROPERTY_VERIFICATION', 'label': 'Verification', 'icon': LucideIcons.fileCheck2},
      {'code': 'VIRTUAL_3D', 'label': 'Virtual / 3D', 'icon': LucideIcons.view},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.hammer, color: AppTheme.primaryViolet, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Partner Specializations & Governance',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Manage verified vendor profiles, authorize category specializations, and enforce strict data isolation',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Filter Tabs (ALL, VERIFIED, PENDING, SUSPENDED)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statusTabs.map((tab) {
                final label = tab['label'] as String;
                final count = tab['count'] as int;
                final isSelected = _partnerStatusFilter == label;
                Color activeColor;
                if (label == 'VERIFIED') {
                  activeColor = AppTheme.emeraldSuccess;
                } else if (label == 'PENDING') {
                  activeColor = const Color(0xFFD97706);
                } else if (label == 'SUSPENDED') {
                  activeColor = const Color(0xFFDC2626);
                } else {
                  activeColor = AppTheme.primaryViolet;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      '$label ($count)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: activeColor,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? activeColor : AppTheme.borderLight,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _partnerStatusFilter = label);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoryFilterOptions.map((opt) {
                final code = opt['code'] as String;
                final label = opt['label'] as String;
                final icon = opt['icon'] as IconData;
                final isSelected = _partnerCategoryFilter == code;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: isSelected,
                    avatar: Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    label: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF4F46E5) : AppTheme.borderLight,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _partnerCategoryFilter = code);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // KPI Summary Cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossCount = isDesktop ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 2.8 : 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPartnerMetricCard('Total Partners', '${allPartners.length}', LucideIcons.users, const Color(0xFF4F46E5)),
                  _buildPartnerMetricCard('Verified & Active', '$verifiedCount', LucideIcons.badgeCheck, AppTheme.emeraldSuccess),
                  _buildPartnerMetricCard('Pending Review', '$pendingCount', LucideIcons.clock, const Color(0xFFD97706)),
                  _buildPartnerMetricCard('Suspended', '$suspendedCount', LucideIcons.shieldAlert, const Color(0xFFDC2626)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Partner List / Cards
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.hammer, size: 36, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No service partners match current filters',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try changing the status tab or specialization category filter.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                return _buildServicePartnerCard(p);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPartnerMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicePartnerCard(ServicePartnerProfile p) {
    Color statusColor;
    String statusLabel;
    if (p.isSuspended) {
      statusColor = const Color(0xFFDC2626);
      statusLabel = 'SUSPENDED';
    } else if (p.verificationStatus == 'VERIFIED') {
      statusColor = AppTheme.emeraldSuccess;
      statusLabel = 'VERIFIED';
    } else {
      statusColor = const Color(0xFFD97706);
      statusLabel = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Text(
                  p.businessName.isNotEmpty ? p.businessName.substring(0, 1).toUpperCase() : 'S',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.businessName,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            statusLabel,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Partner ID: ${p.id} • Contact: ${p.phone} • ${p.email}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Partner Details Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDealerDetailChip(LucideIcons.star, 'Rating', '${p.rating} / 5.0'),
                _buildDealerDetailChip(LucideIcons.checkCircle2, 'Completed Projects', '${p.completedProjectsCount} Orders'),
                _buildDealerDetailChip(LucideIcons.shieldCheck, 'Verification', p.verificationStatus),
                _buildDealerDetailChip(LucideIcons.activity, 'Account Status', p.status),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Approved Specialization Categories
          Row(
            children: [
              const Icon(LucideIcons.layers, size: 14, color: AppTheme.primaryViolet),
              const SizedBox(width: 6),
              Text(
                'Approved Specializations (${p.serviceCategories.length}):',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: p.approvedCategoryTypes.map((catType) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryPillColor(catType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getCategoryPillColor(catType).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(catType), size: 12, color: _getCategoryPillColor(catType)),
                    const SizedBox(width: 5),
                    Text(
                      catType.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryPillColor(catType),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Action Buttons Row
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Approve / Verify button
              if (!p.isApproved) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldSuccess,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await _commandService.verifyServicePartner(p.id);
                    _showToast('Partner "${p.businessName}" verified and approved.');
                  },
                  icon: const Icon(LucideIcons.check, size: 14),
                  label: const Text('Approve / Verify'),
                ),
                if (p.verificationStatus == 'PENDING')
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await _commandService.rejectServicePartner(p.id, 'Application rejected by administrator.');
                      _showToast('Partner "${p.businessName}" application rejected.');
                    },
                    icon: const Icon(LucideIcons.x, size: 14),
                    label: const Text('Reject Application'),
                  ),
              ],

              // Edit Specialization Categories button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: const BorderSide(color: Color(0xFF4F46E5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showEditPartnerCategoriesDialog(p),
                icon: const Icon(LucideIcons.edit3, size: 14),
                label: const Text('Edit Specializations'),
              ),

              // View Partner Portal
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D9488),
                  side: const BorderSide(color: Color(0xFF0D9488)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _openPartnerPortalPreview(p),
                icon: const Icon(LucideIcons.externalLink, size: 14),
                label: const Text('View Partner Portal'),
              ),

              // Customers & Requests
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showPartnerRequestsAndCustomersDialog(p),
                icon: const Icon(LucideIcons.users, size: 14),
                label: const Text('Customers & Requests'),
              ),

              // Suspend button
              if (!p.isSuspended)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showSuspendPartnerDialog(p),
                  icon: const Icon(LucideIcons.shieldAlert, size: 14),
                  label: const Text('Suspend Account'),
                ),

              // Reactivate button
              if (p.isSuspended)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    await _commandService.reactivateServicePartner(p.id);
                    _showToast('Partner "${p.businessName}" reactivated.');
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 14),
                  label: const Text('Reactivate Partner'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryPillColor(ServiceCategoryType type) {
    switch (type) {
      case ServiceCategoryType.homeDesign:
        return const Color(0xFF8B5CF6);
      case ServiceCategoryType.loan:
        return const Color(0xFF10B981);
      case ServiceCategoryType.vastu:
        return const Color(0xFFF59E0B);
      case ServiceCategoryType.construction:
        return const Color(0xFF0EA5E9);
      case ServiceCategoryType.propertyVerification:
        return const Color(0xFF6366F1);
      case ServiceCategoryType.visualization:
        return const Color(0xFFEC4899);
    }
  }

  IconData _getCategoryIcon(ServiceCategoryType type) {
    switch (type) {
      case ServiceCategoryType.homeDesign:
        return LucideIcons.palette;
      case ServiceCategoryType.loan:
        return LucideIcons.landmark;
      case ServiceCategoryType.vastu:
        return LucideIcons.compass;
      case ServiceCategoryType.construction:
        return LucideIcons.hardHat;
      case ServiceCategoryType.propertyVerification:
        return LucideIcons.fileCheck2;
      case ServiceCategoryType.visualization:
        return LucideIcons.view;
    }
  }

  void _showEditPartnerCategoriesDialog(ServicePartnerProfile partner) {
    final selectedCodes = Set<String>.from(partner.serviceCategories);
    if (selectedCodes.isEmpty && partner.serviceCategory.isNotEmpty) {
      selectedCodes.add(partner.serviceCategory);
    }

    final allTypes = [
      ServiceCategoryType.homeDesign,
      ServiceCategoryType.loan,
      ServiceCategoryType.vastu,
      ServiceCategoryType.construction,
      ServiceCategoryType.propertyVerification,
      ServiceCategoryType.visualization,
    ];

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.hammer, color: AppTheme.primaryViolet, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Specializations', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(partner.businessName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Data Isolation Guarantee: The partner will ONLY see inquiries and pipeline stages for the checked specializations.',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Select Authorized Specializations:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      ...allTypes.map((type) {
                        final code = type.code;
                        final isChecked = selectedCodes.contains(code);
                        return CheckboxListTile(
                          dense: true,
                          value: isChecked,
                          activeColor: const Color(0xFF4F46E5),
                          secondary: Icon(_getCategoryIcon(type), size: 18, color: _getCategoryPillColor(type)),
                          title: Text(type.displayName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('Code: $code', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                          onChanged: (val) {
                            setDlgState(() {
                              if (val == true) {
                                selectedCodes.add(code);
                              } else {
                                selectedCodes.remove(code);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: selectedCodes.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dlgContext);
                          await _commandService.updatePartnerCategories(partner.id, selectedCodes.toList());
                          _showToast('Updated specializations for "${partner.businessName}".');
                        },
                  child: const Text('Save Specializations'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSuspendPartnerDialog(ServicePartnerProfile partner) {
    final reasonController = TextEditingController(text: 'Under compliance and SLA verification review');

    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.shieldAlert, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Text('Suspend Partner Account', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suspending "${partner.businessName}" will immediately block them from accepting new requests or performing stage actions. Their portal will be locked in read-only mode.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Text('Reason for Suspension:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for audit logs...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final reason = reasonController.text.trim();
                Navigator.pop(dlgContext);
                await _commandService.suspendServicePartner(partner.id, reason.isNotEmpty ? reason : 'Admin manual suspension');
                _showToast('Partner "${partner.businessName}" suspended.');
              },
              child: const Text('Confirm Suspension'),
            ),
          ],
        );
      },
    );
  }

  void _openPartnerPortalPreview(ServicePartnerProfile partner) {
    final categories = partner.approvedCategoryTypes;
    if (categories.isEmpty) {
      if (partner.primaryCategory != null) {
        Navigator.pushNamed(context, AppRoutes.getPartnerPortalRouteForCategory(partner.primaryCategory!));
        return;
      }
      _showToast('Partner has no approved categories assigned yet.');
      return;
    }

    if (categories.length == 1) {
      Navigator.pushNamed(context, AppRoutes.getPartnerPortalRouteForCategory(categories.first));
      return;
    }

    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.layoutDashboard, color: AppTheme.primaryViolet, size: 22),
            const SizedBox(width: 10),
            Text('Select Portal to Preview', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${partner.businessName} has multiple approved service specializations. Select a portal to view:',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ...categories.map((cat) {
                final color = _getCategoryPillColor(cat);
                final icon = _getCategoryIcon(cat);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.pop(dlgContext);
                      Navigator.pushNamed(context, AppRoutes.getPartnerPortalRouteForCategory(cat));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(10),
                        color: color.withOpacity(0.06),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.displayName,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  AppRoutes.getPartnerPortalRouteForCategory(cat),
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPartnerRequestsAndCustomersDialog(ServicePartnerProfile partner) {
    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final requests = ServicePartnerService.instance.getRequestsForPartner(partner.id);
            final customers = ServicePartnerService.instance.getCustomersForPartner(partner.id);

            return DefaultTabController(
              length: 2,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.briefcase, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.businessName,
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Assigned Requests & Serviced Customers (${requests.length} Requests, ${customers.length} Customers)',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () => Navigator.pop(dlgContext),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 700,
                  height: 480,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: AppTheme.primaryViolet,
                        unselectedLabelColor: AppTheme.textSecondary,
                        indicatorColor: AppTheme.primaryViolet,
                        tabs: [
                          Tab(text: 'Assigned Requests (${requests.length})'),
                          Tab(text: 'Serviced Customers (${customers.length})'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Requests
                            requests.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.inbox, size: 40, color: AppTheme.textMuted),
                                        const SizedBox(height: 8),
                                        Text('No requests currently assigned to this partner.',
                                            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: requests.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (ctx, i) {
                                      final r = requests[i];
                                      final catColor = _getCategoryPillColor(r.category);
                                      return Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardWhite,
                                          border: Border.all(color: AppTheme.borderLight),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: catColor.withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    r.category.displayName,
                                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: catColor),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  r.id,
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    r.status.label,
                                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              r.title,
                                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(LucideIcons.user, size: 12, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${r.customerName} (${r.customerPhone})',
                                                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                                ),
                                                if (r.propertyTitle != null) ...[
                                                  const SizedBox(width: 12),
                                                  const Icon(LucideIcons.building, size: 12, color: AppTheme.textMuted),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      r.propertyTitle!,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Stage: ${r.currentStage}',
                                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                                                ),
                                                OutlinedButton.icon(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: const Color(0xFF4F46E5),
                                                    side: const BorderSide(color: Color(0xFF4F46E5)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                  onPressed: () {
                                                    _showReassignRequestDialog(r, partner, () {
                                                      setDlgState(() {});
                                                      setState(() {});
                                                    });
                                                  },
                                                  icon: const Icon(LucideIcons.userCheck, size: 12),
                                                  label: const Text('Reassign Partner'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                            // Tab 2: Customers
                            customers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.users, size: 40, color: AppTheme.textMuted),
                                        const SizedBox(height: 8),
                                        Text('No customers serviced yet.',
                                            style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13)),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: customers.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (ctx, i) {
                                      final c = customers[i];
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardWhite,
                                          border: Border.all(color: AppTheme.borderLight),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: AppTheme.primaryViolet.withOpacity(0.12),
                                              child: Text(
                                                (c['name'] as String? ?? 'C').substring(0, 1).toUpperCase(),
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(c['name'] ?? 'Unknown Customer', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                                                  Text('${c['email'] ?? ''} • ${c['phone'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                                                  Text('Service: ${c['latestRequest'] ?? ''} • ${c['propertyTitle'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dlgContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReassignRequestDialog(ServiceRequest request, ServicePartnerProfile currentPartner, VoidCallback onReassigned) {
    final eligiblePartners = _commandService.servicePartners.where((p) {
      return p.id != currentPartner.id && p.canProvide(request.category) && !p.isSuspended;
    }).toList();

    ServicePartnerProfile? selectedCandidate = eligiblePartners.isNotEmpty ? eligiblePartners.first : null;

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(LucideIcons.arrowRightLeft, color: AppTheme.primaryViolet, size: 22),
                  const SizedBox(width: 10),
                  Text('Reassign Service Request', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Category: ${request.category.displayName} • ID: ${request.id}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          Text('Current Assignee: ${currentPartner.businessName}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFDC2626), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select New Specialized Partner:',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    if (eligiblePartners.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          'No other verified service partners are specialized in ${request.category.displayName}. Verify or update partner specializations first.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B)),
                        ),
                      )
                    else
                      DropdownButtonFormField<ServicePartnerProfile>(
                        value: selectedCandidate,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: eligiblePartners.map((p) {
                          return DropdownMenuItem<ServicePartnerProfile>(
                            value: p,
                            child: Row(
                              children: [
                                Text(p.businessName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text('(${p.email.isNotEmpty ? p.email : p.id})', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDlgState(() => selectedCandidate = val);
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: selectedCandidate == null
                      ? null
                      : () async {
                          Navigator.pop(dlgContext);
                          final ok = await ServicePartnerService.instance.reassignServiceRequest(
                            requestId: request.id,
                            newPartnerId: selectedCandidate!.id,
                            newPartnerName: selectedCandidate!.businessName,
                          );
                          if (ok) {
                            _showToast('Request ${request.id} successfully reassigned to ${selectedCandidate!.businessName}.');
                            onReassigned();
                          } else {
                            _showToast('Failed to reassign request.');
                          }
                        },
                  child: const Text('Confirm Reassign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // SECTION 30: SERVICE PARTNER LEAD ROUTING & MANAGEMENT WORKSPACE
  // ===========================================================================
  Widget _buildServiceLeadsRoutingWorkspace(bool isDesktop) {
    List<Map<String, dynamic>> filtered = _serviceLeads;

    if (_serviceLeadCategoryFilter != 'ALL') {
      filtered = filtered.where((l) => (l['serviceCategory']?.toString().toUpperCase() ?? '') == _serviceLeadCategoryFilter).toList();
    }

    if (_serviceLeadAssignmentFilter == 'ASSIGNED') {
      filtered = filtered.where((l) => (l['assignmentStatus']?.toString().toUpperCase() ?? '') == 'ASSIGNED').toList();
    } else if (_serviceLeadAssignmentFilter == 'UNASSIGNED') {
      filtered = filtered.where((l) => (l['assignmentStatus']?.toString().toUpperCase() ?? '') == 'UNASSIGNED').toList();
    }

    final totalCount = _serviceLeads.length;
    final assignedCount = _serviceLeads.where((l) => (l['assignmentStatus']?.toString().toUpperCase() ?? '') == 'ASSIGNED').length;
    final unassignedCount = _serviceLeads.where((l) => (l['assignmentStatus']?.toString().toUpperCase() ?? '') == 'UNASSIGNED').length;
    final inProgressCount = _serviceLeads.where((l) => (l['status']?.toString().toUpperCase() ?? '') == 'IN_PROGRESS').length;
    final completedCount = _serviceLeads.where((l) => (l['status']?.toString().toUpperCase() ?? '') == 'COMPLETED').length;

    final categoryTabs = [
      {'code': 'ALL', 'label': 'All Categories', 'icon': LucideIcons.layers},
      {'code': 'LOAN', 'label': 'Home Loan', 'icon': LucideIcons.landmark},
      {'code': 'HOME_DESIGN', 'label': 'Home Design', 'icon': LucideIcons.palette},
      {'code': 'VASTU', 'label': 'Vastu', 'icon': LucideIcons.compass},
      {'code': 'CONSTRUCTION', 'label': 'Construction', 'icon': LucideIcons.hardHat},
      {'code': 'PROPERTY_VERIFICATION', 'label': 'Verification', 'icon': LucideIcons.fileCheck2},
      {'code': 'VIRTUAL_3D', 'label': 'Virtual / 3D', 'icon': LucideIcons.view},
    ];

    final assignmentTabs = [
      {'code': 'ALL', 'label': 'All Leads', 'count': totalCount},
      {'code': 'UNASSIGNED', 'label': 'Unassigned Queue', 'count': unassignedCount},
      {'code': 'ASSIGNED', 'label': 'Assigned Leads', 'count': assignedCount},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.share2, color: AppTheme.primaryViolet, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Partner Lead Routing & Assignment System',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Deterministic multi-criteria matching by category, location proximity, active workload balancing, and partner ratings',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                tooltip: 'Refresh Service Leads',
                onPressed: _loadServiceLeads,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Summary Cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossCount = isDesktop ? 5 : 2;
              return GridView.count(
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 2.5 : 2.0,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPartnerMetricCard('Total Service Leads', '$totalCount', LucideIcons.fileText, const Color(0xFF4F46E5)),
                  _buildPartnerMetricCard('Unassigned Queue', '$unassignedCount', LucideIcons.alertTriangle, const Color(0xFFF59E0B)),
                  _buildPartnerMetricCard('Assigned Leads', '$assignedCount', LucideIcons.userCheck, AppTheme.emeraldSuccess),
                  _buildPartnerMetricCard('In Progress', '$inProgressCount', LucideIcons.clock, const Color(0xFF0EA5E9)),
                  _buildPartnerMetricCard('Completed', '$completedCount', LucideIcons.checkCircle2, const Color(0xFF8B5CF6)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categoryTabs.map((tab) {
                final code = tab['code'] as String;
                final label = tab['label'] as String;
                final icon = tab['icon'] as IconData;
                final isSelected = _serviceLeadCategoryFilter == code;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.primaryViolet),
                    label: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.primaryViolet,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _serviceLeadCategoryFilter = code);
                      _loadServiceLeads();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Assignment Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: assignmentTabs.map((tab) {
                final code = tab['code'] as String;
                final label = tab['label'] as String;
                final count = tab['count'] as int;
                final isSelected = _serviceLeadAssignmentFilter == code;
                final color = code == 'UNASSIGNED' ? const Color(0xFFF59E0B) : (code == 'ASSIGNED' ? AppTheme.emeraldSuccess : const Color(0xFF4F46E5));

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      '$label ($count)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? color : AppTheme.borderLight,
                      ),
                    ),
                    onSelected: (_) {
                      setState(() => _serviceLeadAssignmentFilter = code);
                      _loadServiceLeads();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Content List
          if (_loadingServiceLeads)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.inbox, size: 40, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No service leads found matching criteria',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'When customers submit intake inquiries on Service Hub, deterministic routing dynamically scores and assigns them.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) {
                final lead = filtered[i];
                return _buildServiceLeadCard(lead);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceLeadCard(Map<String, dynamic> lead) {
    final catCode = lead['serviceCategory']?.toString().toUpperCase() ?? 'GENERAL';
    final assignmentStatus = lead['assignmentStatus']?.toString().toUpperCase() ?? 'UNASSIGNED';
    final isAssigned = assignmentStatus == 'ASSIGNED';
    final assignedPartnerName = lead['assignedPartnerName']?.toString() ?? lead['assignedPartnerId']?.toString() ?? 'Unassigned';
    final leadStatus = lead['status']?.toString().toUpperCase() ?? 'NEW';

    Color catColor;
    IconData catIcon;
    switch (catCode) {
      case 'HOME_DESIGN':
        catColor = const Color(0xFF8B5CF6);
        catIcon = LucideIcons.palette;
        break;
      case 'LOAN':
        catColor = const Color(0xFF10B981);
        catIcon = LucideIcons.landmark;
        break;
      case 'VASTU':
        catColor = const Color(0xFFF59E0B);
        catIcon = LucideIcons.compass;
        break;
      case 'CONSTRUCTION':
        catColor = const Color(0xFF0EA5E9);
        catIcon = LucideIcons.hardHat;
        break;
      case 'PROPERTY_VERIFICATION':
        catColor = const Color(0xFF6366F1);
        catIcon = LucideIcons.fileCheck2;
        break;
      case 'VIRTUAL_3D':
        catColor = const Color(0xFFEC4899);
        catIcon = LucideIcons.view;
        break;
      default:
        catColor = AppTheme.primaryViolet;
        catIcon = LucideIcons.tag;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAssigned ? AppTheme.borderLight : const Color(0xFFFCD34D),
          width: isAssigned ? 1.0 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: catColor.withOpacity(0.12),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead['name']?.toString() ?? 'Service Enquiry Applicant',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: catColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            catCode,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: catColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contact: ${lead['phone'] ?? 'N/A'} • ${lead['email'] ?? 'N/A'}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Requirements & Notes
          if (lead['notes']?.toString().isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Requirement: ${lead['notes']}',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Details Grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildDealerDetailChip(LucideIcons.mapPin, 'Location', lead['city']?.toString() ?? lead['location']?.toString() ?? 'National'),
              _buildDealerDetailChip(LucideIcons.activity, 'Lead Status', leadStatus),
              _buildDealerDetailChip(LucideIcons.calendar, 'Submitted', lead['createdAt']?.toString().split('T').first ?? 'Recent'),
              if (lead['budget'] != null)
                _buildDealerDetailChip(LucideIcons.indianRupee, 'Budget', '₹${lead['budget']}'),
            ],
          ),
          const SizedBox(height: 14),

          // Assignment Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAssigned ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isAssigned ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Icon(
                  isAssigned ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                  size: 16,
                  color: isAssigned ? const Color(0xFF059669) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAssigned
                        ? 'Assigned Partner: $assignedPartnerName'
                        : 'Awaiting Assignment (Fallback Unassigned Admin Queue)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAssigned ? const Color(0xFF065F46) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              if (!isAssigned) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showManualAssignPartnerDialog(lead),
                  icon: const Icon(LucideIcons.zap, size: 14),
                  label: const Text('⚡ Match & Assign Partner'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showManualAssignPartnerDialog(lead),
                  icon: const Icon(LucideIcons.arrowRightLeft, size: 14),
                  label: const Text('Reassign Partner'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final ok = await _commandService.unassignLeadPartner(lead['id'].toString(), reason: 'Admin unassigned to queue');
                    if (ok) {
                      _showToast('Lead unassigned and moved to fallback queue.');
                      await _loadServiceLeads();
                    }
                  },
                  icon: const Icon(LucideIcons.userMinus, size: 14),
                  label: const Text('Unassign'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showManualAssignPartnerDialog(Map<String, dynamic> lead) {
    final leadId = lead['id']?.toString() ?? '';
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgContext) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _commandService.fetchEligiblePartnersForLead(leadId),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    content: const SizedBox(
                      height: 150,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Scoring & matching eligible partners...'),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final candidates = snapshot.data ?? [];

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      const Icon(LucideIcons.share2, color: AppTheme.primaryViolet, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Assign Service Partner',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info, size: 16, color: Color(0xFF475569)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lead: ${lead['name']} • Category: ${lead['serviceCategory']} • City: ${lead['city'] ?? 'National'}',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Eligible Candidates (Ranked by Multi-Criteria Scoring):',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 8),

                          if (candidates.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Text(
                                'No verified, approved partners found for specialization "${lead['serviceCategory']}". Ensure partner profiles are approved in the Service Partners tab.',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF92400E)),
                              ),
                            )
                          else
                            ...candidates.map((partner) {
                              final pId = partner['id']?.toString() ?? '';
                              final bName = partner['businessName']?.toString() ?? 'Partner';
                              final city = partner['city']?.toString() ?? 'NCR';
                              final rating = partner['rating']?.toString() ?? '4.8';
                              final workload = partner['activeWorkload']?.toString() ?? '0';
                              final totalScore = partner['totalMatchingScore']?.toString() ?? 'N/A';
                              final proximityScore = partner['proximityScore']?.toString() ?? '0';
                              final workloadScore = partner['workloadScore']?.toString() ?? '0';
                              final ratingScore = partner['ratingScore']?.toString() ?? '0';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  bName,
                                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFECFDF5),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Score: $totalScore pts',
                                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'City: $city • Rating: ★ $rating • Active Workload: $workload leads',
                                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Breakdown: Prox (+$proximityScore) | Load (+$workloadScore) | Rating (+$ratingScore)',
                                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryViolet,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(dlgContext);
                                        final ok = await _commandService.assignLeadToPartner(
                                          leadId,
                                          pId,
                                          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                                        );
                                        if (ok) {
                                          _showToast('Lead successfully assigned to $bName!');
                                          await _loadServiceLeads();
                                        } else {
                                          _showToast('Failed to assign lead.');
                                        }
                                      },
                                      child: const Text('Assign', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              );
                            }),

                          const SizedBox(height: 12),
                          TextField(
                            controller: notesController,
                            decoration: InputDecoration(
                              labelText: 'Optional Admin Assignment Notes',
                              hintText: 'e.g. Priority dispatch requested by client',
                              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dlgContext),
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
