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

/// CONSTRUCTION PARTNER PORTAL
/// Route: /service-partner/construction
/// Completely separate standalone dashboard with civil engineering milestone tracking,
/// BOQ estimating, material procurement, weekly site photos, and a 16-stage construction journey.
class ConstructionPartnerDashboard extends StatefulWidget {
  final int initialNavIndex;

  const ConstructionPartnerDashboard({super.key, this.initialNavIndex = 0});

  @override
  State<ConstructionPartnerDashboard> createState() => _ConstructionPartnerDashboardState();
}

class _ConstructionPartnerDashboardState extends State<ConstructionPartnerDashboard> {
  final ServicePartnerService _service = ServicePartnerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  ServicePartnerProfile? _profile;
  final ServiceCategoryType _category = ServiceCategoryType.construction;

  static const Color _accentColor = Color(0xFF0284C7); // Steel Sky Blue

  final List<Map<String, dynamic>> _navSections = [
    {'title': 'Dashboard', 'icon': LucideIcons.layoutDashboard},
    {'title': 'My Construction Journey', 'icon': LucideIcons.gitFork},
    {'title': 'New Projects', 'icon': LucideIcons.inbox},
    {'title': 'Active Projects', 'icon': LucideIcons.hardHat},
    {'title': 'Customers', 'icon': LucideIcons.users},
    {'title': 'Site Assessment', 'icon': LucideIcons.mapPin},
    {'title': 'Project Estimate', 'icon': LucideIcons.calculator},
    {'title': 'Quotation', 'icon': LucideIcons.fileText},
    {'title': 'Agreement', 'icon': LucideIcons.fileCheck2},
    {'title': 'Material Planning', 'icon': LucideIcons.boxes},
    {'title': 'Contractor/Team', 'icon': LucideIcons.userCheck},
    {'title': 'Construction Schedule', 'icon': LucideIcons.calendar},
    {'title': 'Project Milestones', 'icon': LucideIcons.flag},
    {'title': 'Site Progress', 'icon': LucideIcons.activity},
    {'title': 'Site Photos', 'icon': LucideIcons.camera},
    {'title': 'Quality Checks', 'icon': LucideIcons.shieldCheck},
    {'title': 'Payments', 'icon': LucideIcons.creditCard},
    {'title': 'Final Inspection', 'icon': LucideIcons.clipboardCheck},
    {'title': 'Completed Projects', 'icon': LucideIcons.archive},
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
    final allConstRequests = partnerId.isNotEmpty ? _service.getRequestsForPartner(partnerId, category: _category) : <ServiceRequest>[];
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
                  title: 'Construction Partner Portal',
                  subtitle: 'Civil Engineering, Turnkey Build Management & Site Handover Desk',
                  icon: LucideIcons.hardHat,
                  accentColor: _accentColor,
                  profile: _profile,
                  onLogout: _onLogout,
                  onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveSection(partnerId, allConstRequests, newRequests),
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
                child: const Icon(LucideIcons.hardHat, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropZen Build',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Civil Construction Desk',
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
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.hardHat, color: _accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ISO 9001 Structural Safety Verified',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0369A1), fontWeight: FontWeight.w600),
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
        return _buildMyConstructionJourney(allRequests);
      case 2:
        return _buildNewProjects(newRequests);
      case 3:
        return _buildActiveProjects(allRequests);
      case 4:
        return _buildCustomersSection(partnerId);
      case 5:
        return _buildSiteAssessment(allRequests);
      case 6:
        return _buildProjectEstimate(allRequests);
      case 7:
        return _buildQuotationSection(allRequests);
      case 8:
        return _buildAgreementSection(allRequests);
      case 9:
        return _buildMaterialPlanning(allRequests);
      case 10:
        return _buildContractorTeamSection(allRequests);
      case 11:
        return _buildConstructionSchedule(allRequests);
      case 12:
        return _buildProjectMilestones(allRequests);
      case 13:
        return _buildSiteProgress(allRequests);
      case 14:
        return _buildSitePhotos(allRequests);
      case 15:
        return _buildQualityChecks(allRequests);
      case 16:
        return _buildPaymentsSection(partnerId);
      case 17:
        return _buildFinalInspection(allRequests);
      case 18:
        return _buildCompletedProjects(allRequests);
      case 19:
        return _buildCustomerFeedback(partnerId);
      case 20:
        return _buildPartnerProfile();
      default:
        return _buildDashboardOverview(partnerId, allRequests, newRequests);
    }
  }

  // ---------------------------------------------------------------------------
  // SECTION 0: DASHBOARD
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
                  Text('Construction Operations Overview', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Active sites, concrete pours, contractor teams, and milestone sign-offs', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() => _selectedNavIndex = 14),
                icon: const Icon(LucideIcons.camera, size: 14),
                label: const Text('Upload Site Photos'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stat Cards
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
                    subtitle: 'Requires Estimation',
                    icon: LucideIcons.inbox,
                    accentColor: _accentColor,
                    onTap: () => setState(() => _selectedNavIndex = 2),
                  ),
                  ServicePartnerStatCard(
                    title: 'Active Sites',
                    value: '$activeCount',
                    subtitle: 'Under Construction',
                    icon: LucideIcons.hardHat,
                    accentColor: const Color(0xFFF97316),
                    onTap: () => setState(() => _selectedNavIndex = 3),
                  ),
                  ServicePartnerStatCard(
                    title: 'Handover Completed',
                    value: '$completedCount',
                    subtitle: 'Occupancy Ready',
                    icon: LucideIcons.checkCircle2,
                    accentColor: const Color(0xFF10B981),
                    onTap: () => setState(() => _selectedNavIndex = 18),
                  ),
                  ServicePartnerStatCard(
                    title: 'Civil Contract Volume',
                    value: '₹${(earnings / 100000).toStringAsFixed(1)}L',
                    subtitle: 'Escrow Released',
                    icon: LucideIcons.indianRupee,
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () => setState(() => _selectedNavIndex = 16),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 16-Step Journey Lifecycle
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 8,
            accentColor: _accentColor,
            onStepSelected: (s) => setState(() => _selectedNavIndex = 1),
          ),
          const SizedBox(height: 24),

          // Active Projects Table
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
                    Text('Active Civil Projects', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _selectedNavIndex = 3),
                      child: const Text('View All Sites', style: TextStyle(color: _accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allRequests.isEmpty && newRequests.isEmpty)
                  _buildEmptyState('No civil projects currently assigned.')
                else
                  ...allRequests.take(4).map((r) => _buildConstRow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: MY CONSTRUCTION JOURNEY (16 Stages)
  // ---------------------------------------------------------------------------
  Widget _buildMyConstructionJourney(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Construction Journey Lifecycle', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('End-to-end 16-stage turnkey civil construction and structural handover workflow', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 8,
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
                  Text('Stage ${s.stepIndex}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: NEW PROJECTS
  // ---------------------------------------------------------------------------
  Widget _buildNewProjects(List<ServiceRequest> newRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Construction Project Inquiries', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Incoming plot development and villa construction requests awaiting site assessment', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (newRequests.isEmpty)
            _buildEmptyState('No pending construction inquiries right now.')
          else
            ...newRequests.map((r) => _buildIncomingConstCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: ACTIVE PROJECTS
  // ---------------------------------------------------------------------------
  Widget _buildActiveProjects(List<ServiceRequest> allRequests) {
    final active = allRequests.where((r) => r.isActive).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Construction Sites (${active.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Sites under active execution from excavation to interior finishing', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (active.isEmpty)
            _buildEmptyState('No active construction sites right now.')
          else
            ...active.map((r) => _buildConstDetailCard(r)),
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
          Text('Property Owners & Clients (${customers.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Landowners and homebuilders commissioning turnkey civil works', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (customers.isEmpty)
            _buildEmptyState('No customer records on file.')
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
                          Text('Site: ${c['propertyTitle']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
  // SECTIONS 5 TO 15: SITE ASSESSMENT TO QUALITY CHECKS
  // ---------------------------------------------------------------------------
  Widget _buildSiteAssessment(List<ServiceRequest> allRequests) => _buildSectionWrapper('Site Assessment & Topography Survey', 'Soil testing, safe bearing capacity (SBC), and road access checks', allRequests);
  Widget _buildProjectEstimate(List<ServiceRequest> allRequests) => _buildSectionWrapper('Bill of Quantities (BOQ) & Estimate', 'Cost breakdown for cement, steel, masonry, and labor hours', allRequests);
  Widget _buildQuotationSection(List<ServiceRequest> allRequests) => _buildSectionWrapper('Commercial Quotation Proposals', 'Detailed turnkey pricing proposals submitted to client', allRequests);
  Widget _buildAgreementSection(List<ServiceRequest> allRequests) => _buildSectionWrapper('Civil Construction Agreements', 'Legally binding scope of work and penalty clause agreements', allRequests);
  Widget _buildMaterialPlanning(List<ServiceRequest> allRequests) => _buildSectionWrapper('Material Planning & Procurement', 'TMT steel, 53-grade OPC cement, aggregate, and brickwork orders', allRequests);
  Widget _buildContractorTeamSection(List<ServiceRequest> allRequests) => _buildSectionWrapper('Contractor & Engineering Team Allocation', 'On-site civil engineer, bar-benders, masons, and safety officers', allRequests);
  Widget _buildConstructionSchedule(List<ServiceRequest> allRequests) => _buildSectionWrapper('Construction Master Schedule', 'Gantt chart timeline from foundation excavation to lock-in delivery', allRequests);
  Widget _buildProjectMilestones(List<ServiceRequest> allRequests) => _buildSectionWrapper('Project Milestones (Slabs & Columns)', 'Plinth beam, ground floor slab, first floor slab casting tracking', allRequests);
  Widget _buildSiteProgress(List<ServiceRequest> allRequests) => _buildSectionWrapper('Live Site Progress Monitoring', 'Daily cubic meter pour logs, curing logs, and brickwork progress', allRequests);
  Widget _buildSitePhotos(List<ServiceRequest> allRequests) => _buildSectionWrapper('Site Photo Inspection Gallery', 'Geo-tagged weekly drone & ground site progress photographs', allRequests);
  Widget _buildQualityChecks(List<ServiceRequest> allRequests) => _buildSectionWrapper('Quality Checks & Slump Tests', '7-day and 28-day concrete cube compression strength lab certificates', allRequests);
  Widget _buildFinalInspection(List<ServiceRequest> allRequests) => _buildSectionWrapper('Final Inspection & Snag Checklist', 'Clearance of snag list, waterproofing check, and structural safety signoff', allRequests);

  Widget _buildSectionWrapper(String title, String subtitle, List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildConstDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 16: PAYMENTS
  // ---------------------------------------------------------------------------
  Widget _buildPaymentsSection(String partnerId) {
    final earnings = _service.getTotalEarnings(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Construction Milestone Payments', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Stage-wise release linked to structural milestone certifications', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                    Text('Total Milestone Payments Realized', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    Text('₹${(earnings / 100000).toStringAsFixed(1)} Lakhs', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _accentColor)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text('Milestone Escrow Active', style: TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 18: COMPLETED PROJECTS
  // ---------------------------------------------------------------------------
  Widget _buildCompletedProjects(List<ServiceRequest> allRequests) {
    final completed = allRequests.where((r) => r.isCompleted || r.status == ServiceStatus.closed).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Handed Over Projects (${completed.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Successfully completed buildings with occupancy handover certificates', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (completed.isEmpty)
            _buildEmptyState('No completed buildings archived yet.')
          else
            ...completed.map((r) => _buildConstDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 19: CUSTOMER FEEDBACK
  // ---------------------------------------------------------------------------
  Widget _buildCustomerFeedback(String partnerId) {
    final feedbacks = _service.getPartnerFeedbackList(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Homebuilder Reviews & Structural Quality Ratings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Client reviews on build timeliness and concrete craftsmanship', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (feedbacks.isEmpty)
            _buildEmptyState('No construction testimonials on record.')
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
                        Text(f.buyerName ?? 'Verified Builder', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(f.comment ?? 'Exceptional civil engineering and timely handover.', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 20: PARTNER PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildPartnerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Construction Firm Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Class-A civil contractor credentials and plant machinery assets', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                Text(_profile?.businessName ?? 'Specialized BuildTech Partner', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Partner ID: ${_profile?.id ?? "Pending Partner Verification"} • Specialization: CONSTRUCTION', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text('Contact: ${_profile?.phone.isNotEmpty == true ? _profile!.phone : "Not provided"} | ${_profile?.email.isNotEmpty == true ? _profile!.email : "Not provided"}'),
                const SizedBox(height: 6),
                Text('Contractor Status: ${_profile?.status ?? "PENDING"} (${_profile?.verificationStatus ?? "UNDER_REVIEW"})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildConstRow(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.hardHat, color: _accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${r.customerName} • ${r.propertyTitle ?? "Villa Plot"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(r.status.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor)),
        ],
      ),
    );
  }

  Widget _buildIncomingConstCard(ServiceRequest r) {
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
                child: const Text('NEW PROJECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
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
                child: const Text('Accept Project', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConstDetailCard(ServiceRequest r) {
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
          Text('Client: ${r.customerName} • Site: ${r.propertyTitle ?? "Villa Plot"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
                child: const Text('Mark Handover Complete', style: TextStyle(fontSize: 11, color: _accentColor)),
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
          const Icon(LucideIcons.hardHat, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
