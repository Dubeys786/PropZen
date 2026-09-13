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

/// HOME DESIGN PARTNER PORTAL
/// Route: /service-partner/home-design
/// Completely separate standalone dashboard with architecture, 2D CAD, 3D photorealistic
/// renders, floor plans, and a 14-stage design project lifecycle.
class HomeDesignPartnerDashboard extends StatefulWidget {
  final int initialNavIndex;

  const HomeDesignPartnerDashboard({super.key, this.initialNavIndex = 0});

  @override
  State<HomeDesignPartnerDashboard> createState() => _HomeDesignPartnerDashboardState();
}

class _HomeDesignPartnerDashboardState extends State<HomeDesignPartnerDashboard> {
  final ServicePartnerService _service = ServicePartnerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  ServicePartnerProfile? _profile;
  final ServiceCategoryType _category = ServiceCategoryType.homeDesign;

  static const Color _accentColor = Color(0xFF8B5CF6); // Studio Violet

  final List<Map<String, dynamic>> _navSections = [
    {'title': 'Dashboard', 'icon': LucideIcons.layoutDashboard},
    {'title': 'My Design Journey', 'icon': LucideIcons.gitFork},
    {'title': 'New Design Requests', 'icon': LucideIcons.inbox},
    {'title': 'Active Design Projects', 'icon': LucideIcons.palette},
    {'title': 'Customers', 'icon': LucideIcons.users},
    {'title': 'Requirements', 'icon': LucideIcons.clipboardList},
    {'title': 'Site Measurements', 'icon': LucideIcons.ruler},
    {'title': 'Design Documents', 'icon': LucideIcons.folder},
    {'title': 'Floor Plans', 'icon': LucideIcons.map},
    {'title': '2D Designs', 'icon': LucideIcons.penTool},
    {'title': '3D Designs', 'icon': LucideIcons.box},
    {'title': 'Interior Design', 'icon': LucideIcons.sofa},
    {'title': 'Exterior Design', 'icon': LucideIcons.home},
    {'title': 'Furniture/Layout', 'icon': LucideIcons.layoutGrid},
    {'title': 'Customer Review', 'icon': LucideIcons.messageSquare},
    {'title': 'Revisions', 'icon': LucideIcons.refreshCw},
    {'title': 'Approvals', 'icon': LucideIcons.checkCheck},
    {'title': 'Final Deliverables', 'icon': LucideIcons.packageCheck},
    {'title': 'Payments', 'icon': LucideIcons.creditCard},
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
    final allDesignRequests = partnerId.isNotEmpty ? _service.getRequestsForPartner(partnerId, category: _category) : <ServiceRequest>[];
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
                  title: 'Home Design Partner Portal',
                  subtitle: 'Architectural Design Studio, 2D/3D Floor Plans & Turnkey Interiors',
                  icon: LucideIcons.palette,
                  accentColor: _accentColor,
                  profile: _profile,
                  onLogout: _onLogout,
                  onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveSection(partnerId, allDesignRequests, newRequests),
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
                child: const Icon(LucideIcons.palette, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropZen Design',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Interior & CAD Studio',
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
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.badgePercent, color: _accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-Rendering Engine Ready (4K)',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B21B6), fontWeight: FontWeight.w600),
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
        return _buildMyDesignJourney(allRequests);
      case 2:
        return _buildNewDesignRequests(newRequests);
      case 3:
        return _buildActiveProjects(allRequests);
      case 4:
        return _buildCustomersSection(partnerId);
      case 5:
        return _buildRequirementsSection(allRequests);
      case 6:
        return _buildSiteMeasurementsSection(allRequests);
      case 7:
        return _buildDesignDocumentsSection(allRequests);
      case 8:
        return _buildFloorPlansSection(allRequests);
      case 9:
        return _build2DDesignsSection(allRequests);
      case 10:
        return _build3DDesignsSection(allRequests);
      case 11:
        return _buildInteriorDesignSection(allRequests);
      case 12:
        return _buildExteriorDesignSection(allRequests);
      case 13:
        return _buildFurnitureLayoutSection(allRequests);
      case 14:
        return _buildCustomerReviewSection(allRequests);
      case 15:
        return _buildRevisionsSection(allRequests);
      case 16:
        return _buildApprovalsSection(allRequests);
      case 17:
        return _buildFinalDeliverablesSection(allRequests);
      case 18:
        return _buildPaymentsSection(partnerId);
      case 19:
        return _buildCompletedProjects(allRequests);
      case 20:
        return _buildCustomerFeedback(partnerId);
      case 21:
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
                  Text(
                    'Studio Overview',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Architectural drawings, 3D renderings, and client sign-offs',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                  ),
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
                icon: const Icon(LucideIcons.box, size: 14),
                label: const Text('View 3D Renders'),
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
                    title: 'New Design Briefs',
                    value: '${newRequests.length}',
                    subtitle: 'Requires Scope',
                    icon: LucideIcons.inbox,
                    accentColor: _accentColor,
                    onTap: () => setState(() => _selectedNavIndex = 2),
                  ),
                  ServicePartnerStatCard(
                    title: 'Active Drafting Projects',
                    value: '$activeCount',
                    subtitle: 'CAD & 3D',
                    icon: LucideIcons.palette,
                    accentColor: const Color(0xFF3B82F6),
                    onTap: () => setState(() => _selectedNavIndex = 3),
                  ),
                  ServicePartnerStatCard(
                    title: 'Approved Deliveries',
                    value: '$completedCount',
                    subtitle: 'Delivered',
                    icon: LucideIcons.checkCircle2,
                    accentColor: const Color(0xFF10B981),
                    onTap: () => setState(() => _selectedNavIndex = 19),
                  ),
                  ServicePartnerStatCard(
                    title: 'Design Fees Billed',
                    value: '₹${(earnings / 1000).toStringAsFixed(0)}K',
                    subtitle: 'Milestone Escrow',
                    icon: LucideIcons.indianRupee,
                    accentColor: const Color(0xFFF59E0B),
                    onTap: () => setState(() => _selectedNavIndex = 18),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 14-Step Journey Lifecycle
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 7,
            accentColor: _accentColor,
            onStepSelected: (s) => setState(() => _selectedNavIndex = 1),
          ),
          const SizedBox(height: 24),

          // Active Design Projects List
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
                    Text(
                      'Live Design Projects',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedNavIndex = 3),
                      child: const Text('View All Projects', style: TextStyle(color: _accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allRequests.isEmpty && newRequests.isEmpty)
                  _buildEmptyState('No design briefs currently assigned.')
                else
                  ...allRequests.take(4).map((r) => _buildDesignRow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: MY DESIGN JOURNEY (14 Stages)
  // ---------------------------------------------------------------------------
  Widget _buildMyDesignJourney(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Design Journey Lifecycle', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Comprehensive 14-stage architectural space planning and turnkey interior delivery', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 7,
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
  // SECTION 2: NEW DESIGN REQUESTS
  // ---------------------------------------------------------------------------
  Widget _buildNewDesignRequests(List<ServiceRequest> newRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Design Requests', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Incoming client interior and architectural requests', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (newRequests.isEmpty)
            _buildEmptyState('No new design briefs at the moment.')
          else
            ...newRequests.map((r) => _buildIncomingDesignCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: ACTIVE DESIGN PROJECTS
  // ---------------------------------------------------------------------------
  Widget _buildActiveProjects(List<ServiceRequest> allRequests) {
    final active = allRequests.where((r) => r.isActive).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Design Projects (${active.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Drawings in progress, CAD iterations, and client reviews', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (active.isEmpty)
            _buildEmptyState('No active design projects right now.')
          else
            ...active.map((r) => _buildDesignDetailCard(r)),
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
          Text('Design Clients (${customers.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Homeowners & commercial clients commissioning design layouts', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (customers.isEmpty)
            _buildEmptyState('No client accounts on file.')
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
                          Text('Space: ${c['propertyTitle']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
  // SECTION 5: REQUIREMENTS
  // ---------------------------------------------------------------------------
  Widget _buildRequirementsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Design Briefs & Client Styling Preferences', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Color palettes, Scandinavian/Minimalist/Neo-Classical choices, and space usage goals', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 6: SITE MEASUREMENTS
  // ---------------------------------------------------------------------------
  Widget _buildSiteMeasurementsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Site Measurements & Dimension Audits', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Laser carpet area measurement logs, ceiling heights, and column offsets', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 7: DESIGN DOCUMENTS
  // ---------------------------------------------------------------------------
  Widget _buildDesignDocumentsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Design Documents & Spec Sheets', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('DWG, DXF, PDF blueprints and material schedule documents', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 8: FLOOR PLANS
  // ---------------------------------------------------------------------------
  Widget _buildFloorPlansSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Architectural Floor Plans', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Zonal layouts, wall modifications, and plumbing/electrical conduits', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 9: 2D DESIGNS
  // ---------------------------------------------------------------------------
  Widget _build2DDesignsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('2D CAD Space Planning', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Precision 2D drawings for wall partitions, cabinetry, and tile patterns', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 10: 3D DESIGNS
  // ---------------------------------------------------------------------------
  Widget _build3DDesignsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('3D Photorealistic Renderings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Ray-traced photorealistic interior views with ambient lighting and textures', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 11: INTERIOR DESIGN
  // ---------------------------------------------------------------------------
  Widget _buildInteriorDesignSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interior Architecture & Finishes', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('False ceiling concepts, veneer wall paneling, and modular kitchen layouts', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 12: EXTERIOR DESIGN
  // ---------------------------------------------------------------------------
  Widget _buildExteriorDesignSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exterior Elevation & Façade', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Villa elevation, terrace garden landscaping, and boundary treatment', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 13: FURNITURE / LAYOUT
  // ---------------------------------------------------------------------------
  Widget _buildFurnitureLayoutSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Furniture Specs & Bill of Quantities (BOQ)', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Custom loose furniture specifications, upholstery selections, and carpentry cuts', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 14: CUSTOMER REVIEW
  // ---------------------------------------------------------------------------
  Widget _buildCustomerReviewSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Design Reviews', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Client feedback comments on 3D drafts and space layouts', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 15: REVISIONS
  // ---------------------------------------------------------------------------
  Widget _buildRevisionsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Design Revision Tracker', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Tracking iteration rounds (V1, V2, V3) and material modifications', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 16: APPROVALS
  // ---------------------------------------------------------------------------
  Widget _buildApprovalsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Final Approvals & Client Sign-Offs', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Formally approved design dossiers ready for final export', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 17: FINAL DELIVERABLES
  // ---------------------------------------------------------------------------
  Widget _buildFinalDeliverablesSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Final Deliverables Package', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('High-resolution printable blueprints, 4K renders, and vendor execution guide', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 18: PAYMENTS
  // ---------------------------------------------------------------------------
  Widget _buildPaymentsSection(String partnerId) {
    final earnings = _service.getTotalEarnings(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Design Fee Milestones & Escrow', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Stage-wise payments released upon 2D layout and 3D sign-off', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                    Text('Total Realized Fees', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    Text('₹${earnings.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _accentColor)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: const Text('Design Escrow Active', style: TextStyle(color: Color(0xFF5B21B6), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 19: COMPLETED PROJECTS
  // ---------------------------------------------------------------------------
  Widget _buildCompletedProjects(List<ServiceRequest> allRequests) {
    final completed = allRequests.where((r) => r.isCompleted || r.status == ServiceStatus.closed).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completed Design Projects (${completed.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Archived turnkey interior designs and handed-over projects', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (completed.isEmpty)
            _buildEmptyState('No completed design projects yet.')
          else
            ...completed.map((r) => _buildDesignDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 20: CUSTOMER FEEDBACK
  // ---------------------------------------------------------------------------
  Widget _buildCustomerFeedback(String partnerId) {
    final feedbacks = _service.getPartnerFeedbackList(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Client Reviews & Architecture Ratings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Client satisfaction feedback on design creativity and deliverables', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (feedbacks.isEmpty)
            _buildEmptyState('No client reviews yet.')
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
                    Text(f.comment ?? 'Outstanding aesthetic sense and fast 3D turnaround!', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 21: PARTNER PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildPartnerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Home Design Studio Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Accredited architecture studio profile and design certifications', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                Text(_profile?.businessName ?? 'Specialized Design Studio', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Partner ID: ${_profile?.id ?? "Pending Partner Verification"} • Category: HOME_DESIGN', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text('Contact: ${_profile?.phone.isNotEmpty == true ? _profile!.phone : "Not provided"} | ${_profile?.email.isNotEmpty == true ? _profile!.email : "Not provided"}'),
                const SizedBox(height: 6),
                Text('Status: ${_profile?.status ?? "PENDING"} (${_profile?.verificationStatus ?? "UNDER_REVIEW"})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildDesignRow(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.palette, color: _accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${r.customerName} • ${r.propertyTitle ?? "Residential"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(r.status.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor)),
        ],
      ),
    );
  }

  Widget _buildIncomingDesignCard(ServiceRequest r) {
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
                child: const Text('NEW BRIEF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
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
                child: const Text('Accept Brief', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesignDetailCard(ServiceRequest r) {
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
          Text('Client: ${r.customerName} • Property: ${r.propertyTitle ?? "Residential"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milestones Completed: ${r.completedMilestonesCount} / ${r.milestones.length}', style: GoogleFonts.inter(fontSize: 11)),
              TextButton(
                onPressed: () async {
                  await _service.updateServiceStatus(requestId: r.id, newStatus: ServiceStatus.completed);
                  setState(() {});
                },
                child: const Text('Mark Deliverables Completed', style: TextStyle(fontSize: 11, color: _accentColor)),
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
          const Icon(LucideIcons.palette, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
