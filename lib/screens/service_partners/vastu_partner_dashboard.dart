import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/service_partner_profile.dart';
import '../../models/service_request_model.dart';
import '../../services/service_partner_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../user_profile_screen.dart';
import 'service_partner_shared_widgets.dart';

/// VASTU CONSULTATION PARTNER PORTAL
/// Route: /service-partner/vastu
/// Dedicated dashboard for Vedic consultation, 16-zone geomagnetic energy audits,
/// non-demolition remedies, and a 12-stage consultation pipeline.
class VastuPartnerDashboard extends StatefulWidget {
  final int initialNavIndex;

  const VastuPartnerDashboard({super.key, this.initialNavIndex = 0});

  @override
  State<VastuPartnerDashboard> createState() => _VastuPartnerDashboardState();
}

class _VastuPartnerDashboardState extends State<VastuPartnerDashboard> {
  final ServicePartnerService _service = ServicePartnerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  ServicePartnerProfile? _profile;
  final ServiceCategoryType _category = ServiceCategoryType.vastu;

  static const Color _accentColor = Color(0xFFD97706); // Warm Amber Gold

  final List<Map<String, dynamic>> _navSections = [
    {'title': 'Dashboard', 'icon': LucideIcons.layoutDashboard},
    {'title': 'My Vastu Journey', 'icon': LucideIcons.gitFork},
    {'title': 'New Consultations', 'icon': LucideIcons.inbox},
    {'title': 'Active Consultations', 'icon': LucideIcons.compass},
    {'title': 'Customers', 'icon': LucideIcons.users},
    {'title': 'Property Details', 'icon': LucideIcons.home},
    {'title': 'Floor Plan Analysis', 'icon': LucideIcons.mapPin},
    {'title': 'Vastu Analysis', 'icon': LucideIcons.pieChart},
    {'title': 'Recommendations', 'icon': LucideIcons.sparkles},
    {'title': 'Consultation Notes', 'icon': LucideIcons.fileText},
    {'title': 'Vastu Report', 'icon': LucideIcons.fileCheck},
    {'title': 'Customer Review', 'icon': LucideIcons.messageSquare},
    {'title': 'Completed Consultations', 'icon': LucideIcons.archive},
    {'title': 'Payments', 'icon': LucideIcons.creditCard},
    {'title': 'Customer Feedback', 'icon': LucideIcons.star},
    {'title': 'Partner Profile', 'icon': LucideIcons.userCheck},
  ];

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialNavIndex;
    _service.setActiveCategory(_category);
    _initProfile();
  }

  Future<void> _initProfile() async {
    ServicePartnerProfile? p = UserSession.currentServicePartnerProfile ?? _service.currentProfile;
    if (p == null) {
      if (UserSession.userId.isNotEmpty) {
        p = await SupabaseService.instance.fetchServicePartnerProfileByUserId(UserSession.userId);
      }
      if (p == null && UserSession.email.isNotEmpty) {
        p = await SupabaseService.instance.fetchServicePartnerProfileByEmail(UserSession.email);
      }
    }
    if (p != null && mounted) {
      setState(() => _profile = p);
      UserSession.setServicePartnerProfile(p);
      await _service.loadForProfile(p);
    }
  }

  void _onLogout() {
    UserSession.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final partnerId = _profile?.id ?? '';
    final allVastuRequests = partnerId.isNotEmpty ? _service.getRequestsForPartner(partnerId, category: _category) : <ServiceRequest>[];
    final newRequests = partnerId.isNotEmpty
        ? _service.getAvailableRequestsForCategory(category: _category, currentPartnerId: partnerId)
            .where((r) => r.status == ServiceStatus.requested).toList()
        : <ServiceRequest>[];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 260,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: AppTheme.borderLight)),
                ),
                child: _buildSidebarContent(),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                ServicePartnerHeader(
                  title: 'Vastu Partner Portal',
                  subtitle: 'Vedic Energy Audits, 16-Zone Space Harmonization & Remedies',
                  icon: LucideIcons.compass,
                  accentColor: _accentColor,
                  profile: _profile,
                  onLogout: _onLogout,
                  onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveSection(partnerId, allVastuRequests, newRequests),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    final partnerId = _profile?.id ?? '';
    final newCount = partnerId.isNotEmpty ? _service.getNewRequestsCount(partnerId, category: _category) : 0;
    final activeCount = partnerId.isNotEmpty ? _service.getActiveServicesCount(partnerId, category: _category) : 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.compass, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropZen Vastu',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Vedic Energy Sciences',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _navSections.length,
            itemBuilder: (ctx, i) {
              final sec = _navSections[i];
              int? badgeCount;
              if (i == 2) badgeCount = newCount;
              if (i == 3) badgeCount = activeCount;

              return ServicePartnerSidebarTile(
                index: i,
                selectedIndex: _selectedNavIndex,
                label: sec['title'] as String,
                icon: sec['icon'] as IconData,
                activeColor: _accentColor,
                count: badgeCount,
                onSelect: (idx) {
                  setState(() => _selectedNavIndex = idx);
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sun, color: _accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vedic Astro-Grid Sync Active',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSection(String partnerId, List<ServiceRequest> allRequests, List<ServiceRequest> newRequests) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardOverview(partnerId, allRequests, newRequests);
      case 1:
        return _buildMyVastuJourney(allRequests);
      case 2:
        return _buildNewConsultations(newRequests);
      case 3:
        return _buildActiveConsultations(allRequests);
      case 4:
        return _buildCustomersSection(partnerId);
      case 5:
        return _buildPropertyDetailsSection(allRequests);
      case 6:
        return _buildFloorPlanAnalysis(allRequests);
      case 7:
        return _buildVastuAnalysis(allRequests);
      case 8:
        return _buildRecommendationsSection(allRequests);
      case 9:
        return _buildConsultationNotes(allRequests);
      case 10:
        return _buildVastuReport(allRequests);
      case 11:
        return _buildCustomerReview(allRequests);
      case 12:
        return _buildCompletedConsultations(allRequests);
      case 13:
        return _buildPaymentsSection(partnerId);
      case 14:
        return _buildCustomerFeedback(partnerId);
      case 15:
        return _buildPartnerProfile();
      default:
        return _buildDashboardOverview(partnerId, allRequests, newRequests);
    }
  }

  // ---------------------------------------------------------------------------
  // SECTION 0: DASHBOARD OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildDashboardOverview(String partnerId, List<ServiceRequest> allRequests, List<ServiceRequest> newRequests) {
    final activeCount = _service.getActiveServicesCount(partnerId, category: _category);
    final completedCount = _service.getCompletedCount(partnerId, category: _category);
    final earnings = _service.getTotalEarnings(partnerId, category: _category);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vastu Practice Overview', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Directional energy scores, live client audits, and remedy dossiers', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() => _selectedNavIndex = 10),
                icon: const Icon(LucideIcons.fileCheck, size: 14),
                label: const Text('Generate Vastu Audit'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Stat Cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossCount = constraints.maxWidth > 900 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  ServicePartnerStatCard(
                    title: 'New Inquiries',
                    value: '${newRequests.length}',
                    subtitle: 'Pending Acceptance',
                    icon: LucideIcons.inbox,
                    accentColor: _accentColor,
                    onTap: () => setState(() => _selectedNavIndex = 2),
                  ),
                  ServicePartnerStatCard(
                    title: 'Active Consultations',
                    value: '$activeCount',
                    subtitle: 'Audit & Analysis',
                    icon: LucideIcons.compass,
                    accentColor: const Color(0xFF0284C7),
                    onTap: () => setState(() => _selectedNavIndex = 3),
                  ),
                  ServicePartnerStatCard(
                    title: 'Reports Delivered',
                    value: '$completedCount',
                    subtitle: 'Certified',
                    icon: LucideIcons.checkCircle2,
                    accentColor: const Color(0xFF10B981),
                    onTap: () => setState(() => _selectedNavIndex = 12),
                  ),
                  ServicePartnerStatCard(
                    title: 'Consultation Fees',
                    value: '₹${(earnings / 1000).toStringAsFixed(0)}K',
                    subtitle: 'Total Billed',
                    icon: LucideIcons.indianRupee,
                    accentColor: const Color(0xFF7C3AED),
                    onTap: () => setState(() => _selectedNavIndex = 13),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 12-Step Journey
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 5,
            accentColor: _accentColor,
            onStepSelected: (s) => setState(() => _selectedNavIndex = 1),
          ),
          const SizedBox(height: 24),

          // Live Consultations Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Energy Audits', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _selectedNavIndex = 3),
                      child: const Text('View All Consultations', style: TextStyle(color: _accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allRequests.isEmpty && newRequests.isEmpty)
                  _buildEmptyState('No Vastu consultations currently assigned.')
                else
                  ...allRequests.take(4).map((r) => _buildVastuRow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: MY VASTU JOURNEY (12 Stages)
  // ---------------------------------------------------------------------------
  Widget _buildMyVastuJourney(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Vastu Journey Lifecycle', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Standardized 12-stage Vedic property audit and space realignment process', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 5,
            accentColor: _accentColor,
          ),
          const SizedBox(height: 24),
          ...SpecializedJourneyHelper.getStagesForCategory(_category).map((s) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: _accentColor.withOpacity(0.12),
                    child: Text('${s.stepIndex}', style: const TextStyle(color: _accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(s.description, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Text('Step ${s.stepIndex}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: NEW CONSULTATIONS
  // ---------------------------------------------------------------------------
  Widget _buildNewConsultations(List<ServiceRequest> newRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Vastu Consultation Requests', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Incoming plot, residential, and commercial Vastu inquiries', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (newRequests.isEmpty)
            _buildEmptyState('No pending consultations at this time.')
          else
            ...newRequests.map((r) => _buildIncomingVastuCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: ACTIVE CONSULTATIONS
  // ---------------------------------------------------------------------------
  Widget _buildActiveConsultations(List<ServiceRequest> allRequests) {
    final active = allRequests.where((r) => r.isActive).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Consultations (${active.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Audits underway: floor plan zoning, remedies, and video debriefs', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (active.isEmpty)
            _buildEmptyState('No active consultations right now.')
          else
            ...active.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 4: CUSTOMERS
  // ---------------------------------------------------------------------------
  Widget _buildCustomersSection(String partnerId) {
    final customers = _service.getCustomersForPartner(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vastu Clients (${customers.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Property owners and business leaders receiving consultations', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (customers.isEmpty)
            _buildEmptyState('No client dossiers on record.')
          else
            ...customers.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _accentColor.withOpacity(0.15),
                      child: Text(c['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: _accentColor)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Phone: ${c['phone']} • Email: ${c['email']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                          Text('Plot/Property: ${c['propertyTitle']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Text(c['status'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 5: PROPERTY DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildPropertyDetailsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Property Orientation & Geomagnetic Data', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('True North alignment, slope gradient, and surrounding environmental energies', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 6: FLOOR PLAN ANALYSIS
  // ---------------------------------------------------------------------------
  Widget _buildFloorPlanAnalysis(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Floor Plan Analysis (16 Directional Zones)', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Zonal mapping of Brahmasthan, Ishanya (NE), Agneya (SE), Nairuthya (SW), and Vayavya (NW)', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 7: VASTU ANALYSIS
  // ---------------------------------------------------------------------------
  Widget _buildVastuAnalysis(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Five Elements Balance (Pancha Tattva)', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Elemental distribution: Water (Jal), Air (Vayu), Fire (Agni), Earth (Prithvi), Space (Akash)', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 8: RECOMMENDATIONS
  // ---------------------------------------------------------------------------
  Widget _buildRecommendationsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Non-Demolition Vastu Remedies', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Pyramid placement, metal strips, color therapies, and energy harmonizers', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 9: CONSULTATION NOTES
  // ---------------------------------------------------------------------------
  Widget _buildConsultationNotes(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shastri Consultation Session Notes', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Interactive homeowner debriefing logs and personalized remedial timelines', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 10: VASTU REPORT
  // ---------------------------------------------------------------------------
  Widget _buildVastuReport(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certified Vastu Audit Dossiers', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Formal PDF reports certified with Shastri seal for client delivery', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 11: CUSTOMER REVIEW
  // ---------------------------------------------------------------------------
  Widget _buildCustomerReview(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Review Queue', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Clients reviewing recommended remedies and scheduling follow-up sessions', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 12: COMPLETED CONSULTATIONS
  // ---------------------------------------------------------------------------
  Widget _buildCompletedConsultations(List<ServiceRequest> allRequests) {
    final completed = allRequests.where((r) => r.isCompleted || r.status == ServiceStatus.closed).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completed Consultations (${completed.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Closed and certified Vedic audits', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (completed.isEmpty)
            _buildEmptyState('No completed consultations yet.')
          else
            ...completed.map((r) => _buildVastuDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 13: PAYMENTS
  // ---------------------------------------------------------------------------
  Widget _buildPaymentsSection(String partnerId) {
    final earnings = _service.getTotalEarnings(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consultation Honorarium & Payments', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Verified payment settlements for Vedic advisory cases', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Fees Collected', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    Text('₹${earnings.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _accentColor)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text('Direct Settlement Active', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 14: CUSTOMER FEEDBACK
  // ---------------------------------------------------------------------------
  Widget _buildCustomerFeedback(String partnerId) {
    final feedbacks = _service.getPartnerFeedbackList(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Reviews & Harmony Ratings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Direct client reviews on consultation impact and accuracy', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (feedbacks.isEmpty)
            _buildEmptyState('No client feedback recorded yet.')
          else
            ...feedbacks.map((f) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (idx) => Icon(
                          idx < f.rating.toInt() ? Icons.star : Icons.star_border,
                          size: 16,
                          color: const Color(0xFFEAB308),
                        )),
                        const SizedBox(width: 8),
                        Text(f.buyerName ?? 'Verified Client', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(f.comment ?? 'Very scientific and practical non-demolition remedies.', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 15: PARTNER PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildPartnerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vastu Shastri Partner Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Certified Vedic practice credentials and institutional verification', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_profile?.businessName ?? 'Specialized Vastu Studio', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Partner ID: ${_profile?.id ?? "Pending Partner Verification"} • Specialization: VASTU', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text('Contact: ${_profile?.phone.isNotEmpty == true ? _profile!.phone : "Not provided"} | ${_profile?.email.isNotEmpty == true ? _profile!.email : "Not provided"}'),
                const SizedBox(height: 6),
                Text('Practice Status: ${_profile?.status ?? "PENDING"} (${_profile?.verificationStatus ?? "UNDER_REVIEW"})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildVastuRow(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.compass, color: _accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${r.customerName} • ${r.propertyTitle ?? "Residential Plot"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(r.status.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor)),
        ],
      ),
    );
  }

  Widget _buildIncomingVastuCard(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('NEW INQUIRY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Client: ${r.customerName} (${r.customerPhone})', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (_profile != null) {
                    await _service.acceptServiceRequest(
                      requestId: r.id,
                      partnerId: _profile!.id,
                      partnerName: _profile!.businessName,
                    );
                    setState(() {});
                  }
                },
                child: const Text('Accept Consultation', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVastuDetailCard(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(r.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text(r.status.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Client: ${r.customerName} • Space: ${r.propertyTitle ?? "Residential Plot"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milestones: ${r.completedMilestonesCount} / ${r.milestones.length}', style: GoogleFonts.inter(fontSize: 11)),
              TextButton(
                onPressed: () async {
                  await _service.updateServiceStatus(requestId: r.id, newStatus: ServiceStatus.completed);
                  setState(() {});
                },
                child: const Text('Mark Consultation Completed', style: TextStyle(fontSize: 11, color: _accentColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.compass, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
