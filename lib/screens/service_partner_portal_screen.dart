import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/service_request_model.dart';
import '../models/service_partner_profile.dart';
import '../services/service_partner_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';
import '../routes/app_routes.dart';

/// Complete Role-Based Service Partner Portal with specialization isolation,
/// specialized journey lifecycles, and institutional governance.
class ServicePartnerPortalScreen extends StatefulWidget {
  final int initialNavIndex;

  const ServicePartnerPortalScreen({super.key, this.initialNavIndex = 0});

  @override
  State<ServicePartnerPortalScreen> createState() => _ServicePartnerPortalScreenState();
}

class _ServicePartnerPortalScreenState extends State<ServicePartnerPortalScreen> {
  final ServicePartnerService _service = ServicePartnerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  ServiceCategoryType _selectedCategoryFilter = ServiceCategoryType.loan;
  ServicePartnerProfile? _profile;

  ServiceCategoryType get _activeCategory =>
      _service.activeCategory ??
      _profile?.approvedCategoryTypes.firstOrNull ??
      _selectedCategoryFilter;

  bool get _isSuspended => _profile?.isSuspended ?? false;

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    _initPartnerProfile();
  }

  Future<void> _initPartnerProfile() async {
    // 1. Check if cached profile exists
    ServicePartnerProfile? profile = UserSession.currentServicePartnerProfile ?? _service.currentProfile;

    // 2. Query Supabase authoritatively by email or partner ID
    if (profile == null) {
      final email = UserSession.email.isNotEmpty ? UserSession.email : 'partner@propzen.ai';
      profile = await SupabaseService.instance.fetchServicePartnerProfileByEmail(email);
      if (profile == null && UserSession.servicePartnerId.isNotEmpty) {
        profile = await SupabaseService.instance.fetchServicePartnerProfileById(UserSession.servicePartnerId);
      }
    }

    if (profile != null && mounted) {
      setState(() {
        _profile = profile;
        if (profile!.approvedCategoryTypes.isNotEmpty) {
          _selectedCategoryFilter = profile.approvedCategoryTypes.first;
        }
      });
      UserSession.currentServicePartnerProfile = profile;
      await _service.loadForProfile(profile);
    } else {
      await _service.loadFromBackend();
    }
  }

  void _onLogout() {
    UserSession.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  String _getJourneyNavTitle(ServiceCategoryType cat) {
    switch (cat) {
      case ServiceCategoryType.loan:
        return 'Loan Pipeline';
      case ServiceCategoryType.homeDesign:
        return 'Design Journey';
      case ServiceCategoryType.vastu:
        return 'Vastu Consultations';
      case ServiceCategoryType.construction:
        return 'Build Lifecycle';
      case ServiceCategoryType.propertyVerification:
        return 'Verification Audits';
      case ServiceCategoryType.visualization:
        return '3D & Virtual Tours';
    }
  }

  String _getRequestsNavTitle(ServiceCategoryType cat) {
    switch (cat) {
      case ServiceCategoryType.loan:
        return 'Loan Inquiries';
      case ServiceCategoryType.homeDesign:
        return 'Design Briefs';
      case ServiceCategoryType.vastu:
        return 'Consultation Requests';
      case ServiceCategoryType.construction:
        return 'Construction Tenders';
      case ServiceCategoryType.propertyVerification:
        return 'Verification Orders';
      case ServiceCategoryType.visualization:
        return 'Visualization Orders';
    }
  }

  String _getActiveServicesNavTitle(ServiceCategoryType cat) {
    switch (cat) {
      case ServiceCategoryType.loan:
        return 'Active Loan Files';
      case ServiceCategoryType.homeDesign:
        return 'Active Design Projects';
      case ServiceCategoryType.vastu:
        return 'Active Consultations';
      case ServiceCategoryType.construction:
        return 'Active Sites';
      case ServiceCategoryType.propertyVerification:
        return 'Active Verifications';
      case ServiceCategoryType.visualization:
        return 'Active Shoots & Renders';
    }
  }

  String _getDocumentsNavTitle(ServiceCategoryType cat) {
    switch (cat) {
      case ServiceCategoryType.loan:
        return 'Financial Documents';
      case ServiceCategoryType.homeDesign:
        return 'Drawings & Renders';
      case ServiceCategoryType.vastu:
        return 'Floor Plans & Reports';
      case ServiceCategoryType.construction:
        return 'Permits & Blueprints';
      case ServiceCategoryType.propertyVerification:
        return 'Legal Deeds & RERA';
      case ServiceCategoryType.visualization:
        return 'Assets & Panoramas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final partnerId = _profile?.id ?? UserSession.servicePartnerId;
    final partnerName = _profile?.businessName ??
        (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Service Partner');

    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context, partnerName, isDesktop),
          drawer: !isDesktop ? _buildDrawer(partnerId) : null,
          body: Row(
            children: [
              if (isDesktop) _buildDesktopSidebar(partnerId),
              Expanded(
                child: _buildBodyContent(partnerId),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String partnerName, bool isDesktop) {
    String portalHeaderTitle;
    if (_profile != null) {
      if (_profile!.approvedCategoryTypes.length == 1) {
        portalHeaderTitle = _profile!.portalTitle(_activeCategory);
      } else {
        portalHeaderTitle = 'PropZen ${_activeCategory.displayName} Portal';
      }
    } else {
      portalHeaderTitle = 'PropZen Service Partner Portal';
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: !isDesktop
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Image.asset(
                'assets/propzen_logo.png',
                height: 28,
                errorBuilder: (_, __, ___) => const Icon(LucideIcons.briefcase, color: AppTheme.primaryViolet, size: 24),
              ),
            ),
      leadingWidth: isDesktop ? 48 : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  portalHeaderTitle,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_isSuspended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACCOUNT SUSPENDED',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
                  ),
                )
              else if (_profile?.isApproved ?? true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PARTNER VERIFIED',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PENDING VERIFICATION',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                  ),
                ),
            ],
          ),
          Text(
            partnerName,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        // Multi-specialization switcher in AppBar
        if (_profile != null && _profile!.approvedCategoryTypes.length > 1)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.25)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServiceCategoryType>(
                value: _activeCategory,
                isDense: true,
                icon: const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.primaryViolet),
                items: _profile!.approvedCategoryTypes.map((cat) {
                  return DropdownMenuItem<ServiceCategoryType>(
                    value: cat,
                    child: Text(
                      cat.displayName,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                    ),
                  );
                }).toList(),
                onChanged: (cat) {
                  if (cat != null) {
                    _service.setActiveCategory(cat);
                    setState(() => _selectedCategoryFilter = cat);
                  }
                },
              ),
            ),
          )
        else if (_profile != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 11),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
            ),
            child: Text(
              _activeCategory.displayName.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 18, color: Color(0xFF64748B)),
          tooltip: 'Refresh Data',
          onPressed: () {
            if (_profile != null) {
              _service.loadForProfile(_profile!);
            } else {
              _service.loadFromBackend();
            }
          },
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: _onLogout,
          icon: const Icon(LucideIcons.logOut, size: 15, color: Color(0xFFEF4444)),
          label: Text(
            'Sign Out',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE2E8F0)),
      ),
    );
  }

  Widget _buildDesktopSidebar(String partnerId) {
    final approvedCatsCount = _profile?.approvedCategoryTypes.length ?? 1;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _sidebarItem(0, 'Dashboard', LucideIcons.layoutDashboard),
          _sidebarItem(1, _getJourneyNavTitle(_activeCategory), LucideIcons.gitFork),
          _sidebarItem(
            2,
            approvedCatsCount > 1 ? 'Specialized Services ($approvedCatsCount)' : '${_activeCategory.displayName} Services',
            LucideIcons.layers,
          ),
          _sidebarItem(
            3,
            _getRequestsNavTitle(_activeCategory),
            LucideIcons.bellRing,
            badgeCount: _service.getNewRequestsCount(partnerId, category: _activeCategory),
          ),
          _sidebarItem(
            4,
            _getActiveServicesNavTitle(_activeCategory),
            LucideIcons.playCircle,
            badgeCount: _service.getActiveServicesCount(partnerId, category: _activeCategory),
          ),
          _sidebarItem(5, 'Customers', LucideIcons.users),
          _sidebarItem(
            6,
            _getDocumentsNavTitle(_activeCategory),
            LucideIcons.fileCheck2,
            badgeCount: _service.getDocumentsPendingCount(partnerId, category: _activeCategory),
          ),
          _sidebarItem(7, 'Milestones & Payments', LucideIcons.landmark),
          _sidebarItem(8, 'Completed Services', LucideIcons.checkCircle2),
          _sidebarItem(9, 'Customer Feedback', LucideIcons.messageSquare),
          _sidebarItem(10, 'Partner Profile', LucideIcons.userCircle),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _profile?.businessName ?? 'Institutional Partner',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Specialization: ${_activeCategory.displayName}\nAutomated billing & tenant isolation active.',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.9), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String partnerId) {
    final approvedCatsCount = _profile?.approvedCategoryTypes.length ?? 1;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(
                children: [
                  Image.asset(
                    'assets/propzen_logo.png',
                    height: 28,
                    errorBuilder: (_, __, ___) => const Icon(LucideIcons.briefcase, color: AppTheme.primaryViolet),
                  ),
                  const SizedBox(width: 10),
                  Text('Partner Portal', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _sidebarItem(0, 'Dashboard', LucideIcons.layoutDashboard),
                  _sidebarItem(1, _getJourneyNavTitle(_activeCategory), LucideIcons.gitFork),
                  _sidebarItem(
                    2,
                    approvedCatsCount > 1 ? 'Specialized Services ($approvedCatsCount)' : '${_activeCategory.displayName} Services',
                    LucideIcons.layers,
                  ),
                  _sidebarItem(
                    3,
                    _getRequestsNavTitle(_activeCategory),
                    LucideIcons.bellRing,
                    badgeCount: _service.getNewRequestsCount(partnerId, category: _activeCategory),
                  ),
                  _sidebarItem(4, _getActiveServicesNavTitle(_activeCategory), LucideIcons.playCircle),
                  _sidebarItem(5, 'Customers', LucideIcons.users),
                  _sidebarItem(6, _getDocumentsNavTitle(_activeCategory), LucideIcons.fileCheck2),
                  _sidebarItem(7, 'Milestones & Payments', LucideIcons.landmark),
                  _sidebarItem(8, 'Completed Services', LucideIcons.checkCircle2),
                  _sidebarItem(9, 'Customer Feedback', LucideIcons.messageSquare),
                  _sidebarItem(10, 'Partner Profile', LucideIcons.userCircle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(int index, String title, IconData icon, {int badgeCount = 0}) {
    final isSelected = _selectedNavIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        onTap: () {
          setState(() => _selectedNavIndex = index);
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            Navigator.of(context).pop();
          }
        },
        dense: true,
        leading: Icon(
          icon,
          size: 18,
          color: isSelected ? AppTheme.primaryViolet : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryViolet : const Color(0xFF334155),
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryViolet : const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBodyContent(String partnerId) {
    return Column(
      children: [
        if (_isSuspended)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCOUNT SUSPENDED - READ-ONLY ACCESS',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF991B1B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your partner account has been suspended by administration. Accepting new requests and stage progression are disabled. Contact admin@propzen.ai to restore services.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7F1D1D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _buildCurrentTab(partnerId),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(String partnerId) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardOverview(partnerId);
      case 1:
        return _buildMyServiceJourneyView(partnerId);
      case 2:
        return _buildSpecializationServicesView(partnerId);
      case 3:
        return _buildNewRequestsView(partnerId);
      case 4:
        return _buildActiveServicesView(partnerId);
      case 5:
        return _buildCustomersView(partnerId);
      case 6:
        return _buildDocumentsView(partnerId);
      case 7:
        return _buildMilestonesAndPaymentsView(partnerId);
      case 8:
        return _buildCompletedServicesView(partnerId);
      case 9:
        return _buildCustomerFeedbackView(partnerId);
      case 10:
        return _buildPartnerProfileView(partnerId);
      default:
        return _buildDashboardOverview(partnerId);
    }
  }

  // =========================================================================
  // 1. DASHBOARD OVERVIEW (With Specialization Isolated KPIs & Empty States)
  // =========================================================================
  Widget _buildDashboardOverview(String partnerId) {
    final totalRequests = _service.getTotalRequestsCount(partnerId, category: _activeCategory);
    final newRequests = _service.getNewRequestsCount(partnerId, category: _activeCategory);
    final activeServices = _service.getActiveServicesCount(partnerId, category: _activeCategory);
    final pendingActions = _service.getPendingCustomerActionsCount(partnerId, category: _activeCategory);
    final docsPending = _service.getDocumentsPendingCount(partnerId, category: _activeCategory);
    final inProgress = _service.getInProgressCount(partnerId, category: _activeCategory);
    final completed = _service.getCompletedCount(partnerId, category: _activeCategory);
    final cancelled = _service.getCancelledCount(partnerId, category: _activeCategory);
    final earnings = _service.getTotalEarnings(partnerId, category: _activeCategory);
    final rating = _service.getAverageRating(partnerId, category: _activeCategory);

    final recentRequests = _service.getRequestsForPartner(partnerId, category: _activeCategory);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_activeCategory.displayName} Operations Overview',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Real-time status tracking strictly for your ${_activeCategory.displayName.toLowerCase()} assignments.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedNavIndex = 2),
                icon: const Icon(LucideIcons.compass, size: 15),
                label: Text('Explore ${_activeCategory.displayName} Services', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // KPI Grid (Strictly category isolated)
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxis = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 650 ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxis,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: crossAxis >= 4 ? 1.7 : 2.2,
                children: [
                  _kpiCard('Total ${_activeCategory.displayName} Requests', '$totalRequests', LucideIcons.folder, const Color(0xFF6366F1), () => setState(() => _selectedNavIndex = 1)),
                  _kpiCard('New ${_getRequestsNavTitle(_activeCategory)}', '$newRequests', LucideIcons.bellRing, const Color(0xFF3B82F6), () => setState(() => _selectedNavIndex = 3)),
                  _kpiCard(_getActiveServicesNavTitle(_activeCategory), '$activeServices', LucideIcons.playCircle, const Color(0xFF10B981), () => setState(() => _selectedNavIndex = 4)),
                  _kpiCard('Customer Action Required', '$pendingActions', LucideIcons.alertCircle, const Color(0xFFF59E0B)),
                  _kpiCard(_getDocumentsNavTitle(_activeCategory), '$docsPending', LucideIcons.fileWarning, const Color(0xFFEC4899), () => setState(() => _selectedNavIndex = 6)),
                  _kpiCard('In Progress', '$inProgress', LucideIcons.loader2, const Color(0xFF8B5CF6)),
                  _kpiCard('Completed Services', '$completed', LucideIcons.checkCircle2, const Color(0xFF059669), () => setState(() => _selectedNavIndex = 8)),
                  _kpiCard('Cancelled Services', '$cancelled', LucideIcons.xCircle, const Color(0xFF94A3B8)),
                  _kpiCard('Total Earnings', '₹${earnings.toStringAsFixed(0)}', LucideIcons.indianRupee, const Color(0xFF0D9488), () => setState(() => _selectedNavIndex = 7)),
                  _kpiCard('Specialist Rating', rating > 0 ? '$rating ★' : 'No ratings yet', LucideIcons.star, const Color(0xFFEAB308), () => setState(() => _selectedNavIndex = 9)),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Recent Requests Table / Specialized Empty State
          Text(
            'Recent Assigned ${_activeCategory.displayName} Requests',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          if (recentRequests.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.inbox,
              title: 'No ${_activeCategory.displayName.toLowerCase()} requests yet',
              subtitle: _profile?.emptyRequestsMessage(_activeCategory) ??
                  'When buyers request ${_activeCategory.displayName.toLowerCase()} services, they will appear here.',
              actionLabel: 'Check Available ${_activeCategory.displayName} Inquiries',
              onAction: () => setState(() => _selectedNavIndex = 2),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentRequests.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                itemBuilder: (context, index) {
                  final req = recentRequests[index];
                  return _buildRequestRow(req);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. MY SERVICE JOURNEY (Specialized Lifecycle Stepper)
  // =========================================================================
  Widget _buildMyServiceJourneyView(String partnerId) {
    final requests = _service.getRequestsForPartner(partnerId, category: _activeCategory);
    final stages = SpecializedJourneyHelper.getStagesForCategory(_activeCategory);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getJourneyNavTitle(_activeCategory),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Specialized progression lifecycle for ${_activeCategory.displayName} from inquiry to completion.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Lifecycle Stepper Header Card showing tailored stages
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.gitFork, size: 16, color: AppTheme.primaryViolet),
                    const SizedBox(width: 8),
                    Text(
                      '${_activeCategory.displayName} Specialized Pipeline (${stages.length} Stages):',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: stages.map((s) {
                    return Tooltip(
                      message: s.description,
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundColor: AppTheme.primaryViolet.withOpacity(0.12),
                          child: Text('${s.stepIndex}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                        ),
                        label: Text(s.label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFFF8FAFC),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (requests.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.gitFork,
              title: 'No active ${_activeCategory.displayName.toLowerCase()} journeys',
              subtitle: 'Once you accept customer inquiries, their specialized progress trackers will display here.',
              actionLabel: 'Browse Available Inquiries',
              onAction: () => setState(() => _selectedNavIndex = 2),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildJourneyCard(req);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(ServiceRequest req) {
    final stages = SpecializedJourneyHelper.getStagesForCategory(req.category);

    // Compute progress stage index based on service status
    int currentStageIndex;
    switch (req.status) {
      case ServiceStatus.requested:
        currentStageIndex = 0;
        break;
      case ServiceStatus.accepted:
        currentStageIndex = 1;
        break;
      case ServiceStatus.documentsRequired:
        currentStageIndex = stages.length > 3 ? 2 : 1;
        break;
      case ServiceStatus.inProgress:
        currentStageIndex = (stages.length * 0.5).floor();
        break;
      case ServiceStatus.awaitingCustomer:
        currentStageIndex = (stages.length * 0.7).floor();
        break;
      case ServiceStatus.approvalPending:
        currentStageIndex = stages.length - 3 >= 0 ? stages.length - 3 : stages.length - 2;
        break;
      case ServiceStatus.completed:
        currentStageIndex = stages.length - 2 >= 0 ? stages.length - 2 : stages.length - 1;
        break;
      case ServiceStatus.closed:
        currentStageIndex = stages.length - 1;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.serviceNumber,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    req.title,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
              _buildStatusBadge(req.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Customer: ${req.customerName} (${req.customerPhone}) • Specialization: ${req.category.displayName}',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          if (req.propertyTitle != null) ...[
            const SizedBox(height: 4),
            Text(
              'Property: ${req.propertyTitle}',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569), fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 16),

          // Interactive Horizontal Specialized Lifecycle Stepper
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(stages.length, (i) {
                final stage = stages[i];
                final isPast = i < currentStageIndex;
                final isCurrent = i == currentStageIndex;

                Color circleColor = const Color(0xFFE2E8F0);
                Color textColor = const Color(0xFF94A3B8);
                IconData stageIcon = LucideIcons.circle;

                if (isPast) {
                  circleColor = const Color(0xFF10B981);
                  textColor = const Color(0xFF059669);
                  stageIcon = LucideIcons.check;
                } else if (isCurrent) {
                  circleColor = AppTheme.primaryViolet;
                  textColor = AppTheme.primaryViolet;
                  stageIcon = LucideIcons.play;
                }

                return Row(
                  children: [
                    Tooltip(
                      message: stage.description,
                      child: InkWell(
                        onTap: _isSuspended ? null : () => _showStatusTransitionDialog(req),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Column(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: circleColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: circleColor, width: 2),
                                ),
                                child: Icon(stageIcon, size: 12, color: circleColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stage.label,
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500, color: textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (i < stages.length - 1)
                      Container(
                        width: 20,
                        height: 2,
                        color: i < currentStageIndex ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 14),

          // Action Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showMilestonesDialog(req),
                icon: const Icon(LucideIcons.listChecks, size: 14),
                label: Text('Milestones (${req.completedMilestonesCount}/${req.milestones.length})', style: GoogleFonts.inter(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showDocumentsDialog(req),
                icon: const Icon(LucideIcons.fileText, size: 14),
                label: Text('Documents (${req.documents.length})', style: GoogleFonts.inter(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              const SizedBox(width: 8),
              if (!_isSuspended)
                ElevatedButton.icon(
                  onPressed: () => _showStatusTransitionDialog(req),
                  icon: const Icon(LucideIcons.arrowRight, size: 14),
                  label: Text('Update Stage', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. SPECIALIZATION SERVICES (Strict Tenant Isolation & Sub-service Deliverables)
  // =========================================================================
  Widget _buildSpecializationServicesView(String partnerId) {
    // Only approved categories are available to this partner!
    final approvedCategories = _profile?.approvedCategoryTypes ?? [_activeCategory];
    final isMulti = approvedCategories.length > 1;

    final available = _service.getAvailableRequestsForCategory(
      category: _activeCategory,
      currentPartnerId: partnerId,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_activeCategory.displayName} Specialized Services',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Delivering verified ${_activeCategory.displayName.toLowerCase()} solutions strictly aligned with your institutional registration.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          // Category Switcher: If multi, show choice chips ONLY for approved categories.
          // If single, show verified specialization badge card (NO UNAUTHORIZED CHIPS).
          if (isMulti) ...[
            Text('Your Approved Specializations:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: approvedCategories.map((cat) {
                  final isSelected = _activeCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.displayName, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryViolet,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
                      onSelected: (val) {
                        if (val) {
                          _service.setActiveCategory(cat);
                          setState(() => _selectedCategoryFilter = cat);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppTheme.primaryViolet, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Exclusive Registered Specialization: ${_activeCategory.displayName}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Specialized Sub-services deliverables grid
          _buildSpecializedSubServicesBanner(_activeCategory),
          const SizedBox(height: 24),

          Text(
            '${_activeCategory.displayName} Inquiries (${available.length})',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          if (available.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.layers,
              title: 'No service requests yet',
              subtitle: _profile?.emptyRequestsMessage(_activeCategory) ?? 'No requests received yet for ${_activeCategory.displayName}.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: available.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = available[index];
                return _buildRequestRow(req, showAcceptButton: !req.isAssigned && !_isSuspended, partnerId: partnerId);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSpecializedSubServicesBanner(ServiceCategoryType cat) {
    IconData icon;
    switch (cat) {
      case ServiceCategoryType.loan:
        icon = LucideIcons.badgePercent;
        break;
      case ServiceCategoryType.homeDesign:
        icon = LucideIcons.palette;
        break;
      case ServiceCategoryType.vastu:
        icon = LucideIcons.compass;
        break;
      case ServiceCategoryType.construction:
        icon = LucideIcons.hardHat;
        break;
      case ServiceCategoryType.propertyVerification:
        icon = LucideIcons.shieldCheck;
        break;
      case ServiceCategoryType.visualization:
        icon = LucideIcons.view;
        break;
    }

    final subServices = cat.specializedSubServices;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primaryViolet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cat.displayName} Sub-Services & Deliverables',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Authorized core competencies under your institutional profile',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subServices.map((sub) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.check, size: 12, color: Color(0xFF059669)),
                    const SizedBox(width: 6),
                    Text(
                      sub,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. NEW SERVICE REQUESTS (Category Isolated)
  // =========================================================================
  Widget _buildNewRequestsView(String partnerId) {
    final newRequests = _service
        .getRequestsForPartner(partnerId, category: _activeCategory)
        .where((r) => r.status == ServiceStatus.requested)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getRequestsNavTitle(_activeCategory),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Review incoming Buyer requirements strictly for ${_activeCategory.displayName.toLowerCase()}.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (newRequests.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.checkCircle,
              title: 'No new ${_activeCategory.displayName.toLowerCase()} requests',
              subtitle: 'All incoming buyer requests have been addressed.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = newRequests[index];
                return _buildRequestRow(req, showAcceptButton: !_isSuspended, partnerId: partnerId);
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. ACTIVE SERVICES
  // =========================================================================
  Widget _buildActiveServicesView(String partnerId) {
    final active = _service
        .getRequestsForPartner(partnerId, category: _activeCategory)
        .where((r) => r.isActive)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getActiveServicesNavTitle(_activeCategory),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Ongoing assignments across all clients in ${_activeCategory.displayName}.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (active.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.playCircle,
              title: 'No active ${_activeCategory.displayName.toLowerCase()} projects',
              subtitle: 'You currently do not have any active service engagements in progress.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: active.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = active[index];
                return _buildJourneyCard(req);
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. CUSTOMERS VIEW
  // =========================================================================
  Widget _buildCustomersView(String partnerId) {
    final requests = _service.getRequestsForPartner(partnerId, category: _activeCategory);
    final Map<String, List<ServiceRequest>> customerMap = {};

    for (final r in requests) {
      final key = r.customerId.isNotEmpty ? r.customerId : r.customerEmail;
      customerMap.putIfAbsent(key, () => []).add(r);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_activeCategory.displayName} Client Directory',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Manage customer records associated with ${_activeCategory.displayName.toLowerCase()} requests.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (customerMap.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.users,
              title: 'No customers yet',
              subtitle: 'Clients will appear here once they request ${_activeCategory.displayName.toLowerCase()} services.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customerMap.keys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final key = customerMap.keys.elementAt(index);
                final list = customerMap[key]!;
                final first = list.first;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.user, size: 20, color: AppTheme.primaryViolet),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(first.customerName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Phone: ${first.customerPhone} • Email: ${first.customerEmail}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text('Specialization: ${_activeCategory.displayName} (${list.length} services)', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
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

  // =========================================================================
  // 7. DOCUMENTS & DELIVERABLES VIEW
  // =========================================================================
  Widget _buildDocumentsView(String partnerId) {
    final requests = _service.getRequestsForPartner(partnerId, category: _activeCategory);
    final List<ServiceDocument> allDocs = [];
    for (final r in requests) {
      allDocs.addAll(r.documents);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDocumentsNavTitle(_activeCategory),
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Verified deliverables and client documents for ${_activeCategory.displayName.toLowerCase()}.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (allDocs.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.fileText,
              title: 'No documents yet',
              subtitle: 'When buyers attach identity proofs, drawings, or blueprints, they will be indexed here.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allDocs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = allDocs[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.fileCheck, size: 20, color: Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('File: ${doc.fileName} • Uploaded by: ${doc.uploadedBy}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: Text(doc.fileType, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold)),
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

  // =========================================================================
  // 8. MILESTONES & PAYMENTS VIEW
  // =========================================================================
  Widget _buildMilestonesAndPaymentsView(String partnerId) {
    final requests = _service.getRequestsForPartner(partnerId, category: _activeCategory);
    final totalEarnings = _service.getTotalEarnings(partnerId, category: _activeCategory);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_activeCategory.displayName} Milestones & Settlement',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Track milestone completions and verified disbursements for ${_activeCategory.displayName.toLowerCase()}.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total ${_activeCategory.displayName} Realized Earnings', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9))),
                    const SizedBox(height: 6),
                    Text('₹${totalEarnings.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.badgeCheck, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Active Project Milestones', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (requests.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.landmark,
              title: 'No milestones recorded',
              subtitle: 'Project milestones and payment tranches will be itemized here.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final r = requests[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('₹${r.paidAmount.toStringAsFixed(0)} / ₹${r.estimatedPrice.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...r.milestones.map((m) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                m.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                size: 16,
                                color: m.isCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                                    color: m.isCompleted ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                              if (m.amount > 0)
                                Text('₹${m.amount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 9. COMPLETED SERVICES VIEW
  // =========================================================================
  Widget _buildCompletedServicesView(String partnerId) {
    final completed = _service
        .getRequestsForPartner(partnerId, category: _activeCategory)
        .where((r) => r.isCompleted || r.status == ServiceStatus.closed)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed ${_activeCategory.displayName} Archive',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Historical record of delivered ${_activeCategory.displayName.toLowerCase()} projects.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (completed.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.checkCheck,
              title: 'No completed services yet',
              subtitle: 'Services marked as completed will be archived here.',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = completed[index];
                return _buildRequestRow(req);
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 10. CUSTOMER FEEDBACK VIEW
  // =========================================================================
  Widget _buildCustomerFeedbackView(String partnerId) {
    final feedbackList = _service.getPartnerFeedbackList(partnerId, category: _activeCategory);
    final avgRating = _service.getAverageRating(partnerId, category: _activeCategory);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_activeCategory.displayName} Customer Feedback',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Direct reviews submitted by buyers for ${_activeCategory.displayName.toLowerCase()} services.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          if (feedbackList.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.messageSquare,
              title: 'No customer feedback yet',
              subtitle: 'When buyers complete services and leave ratings, their reviews will appear here.',
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Text('$avgRating', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFEAB308))),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < avgRating.round() ? LucideIcons.star : LucideIcons.star,
                            size: 16,
                            color: i < avgRating.round() ? const Color(0xFFEAB308) : const Color(0xFFCBD5E1),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text('Based on ${feedbackList.length} verified reviews in ${_activeCategory.displayName}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: feedbackList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final fb = feedbackList[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fb.buyerName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                          Row(
                            children: List.generate(fb.rating, (_) => const Icon(LucideIcons.star, size: 14, color: Color(0xFFEAB308))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(fb.comment, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.4)),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 11. PARTNER PROFILE VIEW (Institutional Credentials & Specializations)
  // =========================================================================
  Widget _buildPartnerProfileView(String partnerId) {
    final approvedCats = _profile?.approvedCategoryTypes ?? [_activeCategory];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partner Organization Profile',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            'Verified credentials and authorized institutional specializations.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.briefcase, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile?.businessName ?? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Partner'),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Partner ID: $partnerId',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32, color: Color(0xFFE2E8F0)),
                _profileDetailRow('Email Address', _profile?.email ?? (UserSession.email.isNotEmpty ? UserSession.email : 'partner@propzen.ai')),
                const SizedBox(height: 12),
                _profileDetailRow('Phone Number', _profile?.phone ?? (UserSession.phone.isNotEmpty ? UserSession.phone : '+91 9810394068')),
                const SizedBox(height: 12),
                _profileDetailRow('Verification Status', _isSuspended ? 'SUSPENDED' : (_profile?.verificationStatus ?? 'VERIFIED')),
                const SizedBox(height: 12),
                _profileDetailRow('Account Status', _isSuspended ? 'SUSPENDED' : (_profile?.status ?? 'ACTIVE')),
                const SizedBox(height: 12),
                _profileDetailRow('Completed Projects', '${_profile?.completedProjectsCount ?? 14} projects delivered'),
                const SizedBox(height: 16),
                Text('Registered Specializations (${approvedCats.length}):', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: approvedCats.map((cat) {
                    return Chip(
                      avatar: const Icon(LucideIcons.checkCheck, size: 14, color: Color(0xFF059669)),
                      label: Text(cat.displayName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                      backgroundColor: const Color(0xFFD1FAE5),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _onLogout,
                    icon: const Icon(LucideIcons.logOut, size: 16, color: Color(0xFFEF4444)),
                    label: Text('Sign Out of Partner Portal', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      ],
    );
  }

  // =========================================================================
  // SHARED ROW & BADGE BUILDERS
  // =========================================================================
  Widget _buildRequestRow(ServiceRequest req, {bool showAcceptButton = false, String? partnerId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.briefcase, size: 18, color: AppTheme.primaryViolet),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(req.serviceNumber, style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        req.title,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${req.category.displayName} • Customer: ${req.customerName} (${req.customerPhone})',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusBadge(req.status),
          if (showAcceptButton && partnerId != null && !_isSuspended) ...[
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () async {
                final partnerName = _profile?.businessName ??
                    (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Partner');
                await _service.acceptServiceRequest(
                  requestId: req.id,
                  partnerId: partnerId,
                  partnerName: partnerName,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Accept', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ServiceStatus status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);

    switch (status) {
      case ServiceStatus.requested:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case ServiceStatus.accepted:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case ServiceStatus.documentsRequired:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case ServiceStatus.inProgress:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        break;
      case ServiceStatus.awaitingCustomer:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        break;
      case ServiceStatus.approvalPending:
        bg = const Color(0xFFFCE7F3);
        fg = const Color(0xFFBE185D);
        break;
      case ServiceStatus.completed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case ServiceStatus.closed:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.displayLabel,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.5),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // INTERACTIVE MODALS (Status Progression, Milestones, Documents)
  // =========================================================================
  void _showStatusTransitionDialog(ServiceRequest req, [ServiceStatus? targetStage]) {
    if (_isSuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action disabled: Partner account is currently suspended.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Update Service Status', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Status: ${req.status.displayLabel}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 14),
              Text('Select New Status:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...ServiceStatus.values.map((s) {
                return ListTile(
                  dense: true,
                  title: Text(s.displayLabel, style: GoogleFonts.inter(fontSize: 12)),
                  trailing: req.status == s ? const Icon(LucideIcons.check, color: AppTheme.primaryViolet, size: 16) : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _service.updateServiceStatus(requestId: req.id, newStatus: s);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  void _showMilestonesDialog(ServiceRequest req) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Project Milestones', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: req.milestones.map((m) {
                      return CheckboxListTile(
                        value: m.isCompleted,
                        title: Text(m.title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        subtitle: m.amount > 0 ? Text('Amount: ₹${m.amount.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 10)) : null,
                        activeColor: AppTheme.primaryViolet,
                        onChanged: _isSuspended
                            ? null
                            : (val) async {
                                await _service.toggleMilestone(requestId: req.id, milestoneId: m.id);
                                setModalState(() {});
                              },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
              ],
            );
          },
        );
      },
    );
  }

  void _showDocumentsDialog(ServiceRequest req) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Project Documents', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: req.documents.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No documents uploaded yet.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: req.documents.map((d) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(LucideIcons.fileText, size: 18),
                          title: Text(d.title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: Text('By: ${d.uploadedBy}', style: GoogleFonts.inter(fontSize: 10)),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            if (!_isSuspended)
              TextButton(
                onPressed: () async {
                  await _service.uploadDocument(
                    requestId: req.id,
                    title: 'Verified Report / Deliverable',
                    fileName: 'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                    fileUrl: 'https://propzen.ai/reports/deliverable.pdf',
                    uploadedBy: 'SERVICE_PARTNER',
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Add Deliverable'),
              ),
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }
}
