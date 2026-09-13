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

/// PROPERTY VERIFICATION PARTNER PORTAL
/// Route: /service-partner/property-verification
/// Standalone legal due diligence dashboard for 30-year deed chain analysis,
/// RERA court dispute checks, mutation certificate audits, and 13-stage verification pipeline.
class PropertyVerificationPartnerDashboard extends StatefulWidget {
  final int initialNavIndex;

  const PropertyVerificationPartnerDashboard({super.key, this.initialNavIndex = 0});

  @override
  State<PropertyVerificationPartnerDashboard> createState() => _PropertyVerificationPartnerDashboardState();
}

class _PropertyVerificationPartnerDashboardState extends State<PropertyVerificationPartnerDashboard> {
  final ServicePartnerService _service = ServicePartnerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  ServicePartnerProfile? _profile;
  final ServiceCategoryType _category = ServiceCategoryType.propertyVerification;

  static const Color _accentColor = Color(0xFF4F46E5); // Royal Shield Indigo

  final List<Map<String, dynamic>> _navSections = [
    {'title': 'Dashboard', 'icon': LucideIcons.layoutDashboard},
    {'title': 'Verification Journey', 'icon': LucideIcons.gitFork},
    {'title': 'New Verification Requests', 'icon': LucideIcons.inbox},
    {'title': 'Active Verifications', 'icon': LucideIcons.shieldCheck},
    {'title': 'Customers', 'icon': LucideIcons.users},
    {'title': 'Property Details', 'icon': LucideIcons.home},
    {'title': 'Document Collection', 'icon': LucideIcons.files},
    {'title': 'Ownership Verification', 'icon': LucideIcons.userCheck},
    {'title': 'RERA Verification', 'icon': LucideIcons.checkSquare},
    {'title': 'Registry Verification', 'icon': LucideIcons.landmark},
    {'title': 'Legal Review', 'icon': LucideIcons.scale},
    {'title': 'Location Verification', 'icon': LucideIcons.mapPin},
    {'title': 'Risk/Issue Tracking', 'icon': LucideIcons.alertTriangle},
    {'title': 'Verification Report', 'icon': LucideIcons.fileCheck},
    {'title': 'Completed Verifications', 'icon': LucideIcons.archive},
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
    final allVerifRequests = partnerId.isNotEmpty ? _service.getRequestsForPartner(partnerId, category: _category) : <ServiceRequest>[];
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
                  title: 'Property Verification Partner Portal',
                  subtitle: 'Legal Due Diligence, 30-Yr Chain Search & Title Clearance Certification',
                  icon: LucideIcons.fileCheck2,
                  accentColor: _accentColor,
                  profile: _profile,
                  onLogout: _onLogout,
                  onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveSection(partnerId, allVerifRequests, newRequests),
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
                child: const Icon(LucideIcons.fileCheck2, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropZen Verify',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Legal Due Diligence Desk',
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
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: _accentColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'High Court & Registry Index Linked',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF3730A3), fontWeight: FontWeight.w600),
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
        return _buildVerificationJourney(allRequests);
      case 2:
        return _buildNewRequests(newRequests);
      case 3:
        return _buildActiveVerifications(allRequests);
      case 4:
        return _buildCustomersSection(partnerId);
      case 5:
        return _buildPropertyDetails(allRequests);
      case 6:
        return _buildDocumentCollection(allRequests);
      case 7:
        return _buildOwnershipVerification(allRequests);
      case 8:
        return _buildReraVerification(allRequests);
      case 9:
        return _buildRegistryVerification(allRequests);
      case 10:
        return _buildLegalReview(allRequests);
      case 11:
        return _buildLocationVerification(allRequests);
      case 12:
        return _buildRiskIssueTracking(allRequests);
      case 13:
        return _buildVerificationReport(allRequests);
      case 14:
        return _buildCompletedVerifications(allRequests);
      case 15:
        return _buildPaymentsSection(partnerId);
      case 16:
        return _buildCustomerFeedback(partnerId);
      case 17:
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
                  Text('Legal Intelligence Overview', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Title deed clearances, encumbrance searches, and risk assessments', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() => _selectedNavIndex = 13),
                icon: const Icon(LucideIcons.fileCheck, size: 14),
                label: const Text('Generate Title Certificate'),
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
                    subtitle: 'Requires Audit',
                    icon: LucideIcons.inbox,
                    accentColor: _accentColor,
                    onTap: () => setState(() => _selectedNavIndex = 2),
                  ),
                  ServicePartnerStatCard(
                    title: 'Audits Underway',
                    value: '$activeCount',
                    subtitle: 'Deed Chain & RERA',
                    icon: LucideIcons.shieldCheck,
                    accentColor: const Color(0xFF0284C7),
                    onTap: () => setState(() => _selectedNavIndex = 3),
                  ),
                  ServicePartnerStatCard(
                    title: 'Certified Titles',
                    value: '$completedCount',
                    subtitle: 'Clean Clearance',
                    icon: LucideIcons.checkCircle2,
                    accentColor: const Color(0xFF10B981),
                    onTap: () => setState(() => _selectedNavIndex = 14),
                  ),
                  ServicePartnerStatCard(
                    title: 'Legal Retainers Billed',
                    value: '₹${(earnings / 1000).toStringAsFixed(0)}K',
                    subtitle: 'Audit Revenue',
                    icon: LucideIcons.indianRupee,
                    accentColor: const Color(0xFFD97706),
                    onTap: () => setState(() => _selectedNavIndex = 15),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 13-Step Verification Journey
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 6,
            accentColor: _accentColor,
            onStepSelected: (s) => setState(() => _selectedNavIndex = 1),
          ),
          const SizedBox(height: 24),

          // Active Verifications Table
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
                    Text('Active Legal Verifications', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _selectedNavIndex = 3),
                      child: const Text('View All Audits', style: TextStyle(color: _accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allRequests.isEmpty && newRequests.isEmpty)
                  _buildEmptyState('No property verifications assigned yet.')
                else
                  ...allRequests.take(4).map((r) => _buildVerifRow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: VERIFICATION JOURNEY (13 Stages)
  // ---------------------------------------------------------------------------
  Widget _buildVerificationJourney(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verification Journey Lifecycle', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('13-stage institutional title clearance, encumbrance verification, and risk delivery process', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 6,
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
  // SECTION 2: NEW REQUESTS
  // ---------------------------------------------------------------------------
  Widget _buildNewRequests(List<ServiceRequest> newRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Verification Requests', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Incoming buyer title verification requests awaiting assignment acceptance', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (newRequests.isEmpty)
            _buildEmptyState('No pending verification inquiries.')
          else
            ...newRequests.map((r) => _buildIncomingVerifCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: ACTIVE VERIFICATIONS
  // ---------------------------------------------------------------------------
  Widget _buildActiveVerifications(List<ServiceRequest> allRequests) {
    final active = allRequests.where((r) => r.isActive).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Verifications (${active.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Properties currently under deed verification, court litigation searches, and RERA reviews', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (active.isEmpty)
            _buildEmptyState('No active legal reviews.')
          else
            ...active.map((r) => _buildVerifDetailCard(r)),
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
          Text('Buyers & Property Owners (${customers.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Verified buyers seeking title clearance and legal diligence', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (customers.isEmpty)
            _buildEmptyState('No client dossiers.')
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
                          Text('Target Asset: ${c['propertyTitle']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
  // SECTIONS 5 TO 13: SPECIALIZED VERIFICATION STEPS
  // ---------------------------------------------------------------------------
  Widget _buildPropertyDetails(List<ServiceRequest> allRequests) => _buildSectionWrapper('Property & Land Registry Identifiers', 'Survey numbers, Khasra, Khatauni, and municipal registry index records', allRequests);
  Widget _buildDocumentCollection(List<ServiceRequest> allRequests) => _buildSectionWrapper('Document Intake & Chain Deeds', 'Mother deed, sale agreements, power of attorney (GPA/SPA), and death/mutation certificates', allRequests);
  Widget _buildOwnershipVerification(List<ServiceRequest> allRequests) => _buildSectionWrapper('30-Year Ownership Chain Search', 'Unbroken chain of title ownership inspection via sub-registrar index II registers', allRequests);
  Widget _buildReraVerification(List<ServiceRequest> allRequests) => _buildSectionWrapper('RERA Compliance & Project Escrow Verification', 'RERA registration validity, sanctioned floor plan approvals, and appellate tribunal records', allRequests);
  Widget _buildRegistryVerification(List<ServiceRequest> allRequests) => _buildSectionWrapper('Tehsil & Sub-Registrar Office Verification', 'Physical verification of book records at district registrar office', allRequests);
  Widget _buildLegalReview(List<ServiceRequest> allRequests) => _buildSectionWrapper('Court Litigation & Dispute Search', 'Civil court, High Court, DRT, and consumer forum search against buyer/seller/land', allRequests);
  Widget _buildLocationVerification(List<ServiceRequest> allRequests) => _buildSectionWrapper('Physical Boundary & Location Verification', 'On-ground survey to ensure demarcation matches approved master plan', allRequests);
  Widget _buildRiskIssueTracking(List<ServiceRequest> allRequests) => _buildSectionWrapper('Risk & Encumbrance Issue Tracking', 'Red-flag monitor: bank mortgages, probate disputes, and pending revenue taxes', allRequests);
  Widget _buildVerificationReport(List<ServiceRequest> allRequests) => _buildSectionWrapper('Certified Title Clearance Certificate', 'Advocate-certified Title Verification Report ready for banking and purchase closing', allRequests);

  Widget _buildSectionWrapper(String title, String subtitle, List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildVerifDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 14: COMPLETED VERIFICATIONS
  // ---------------------------------------------------------------------------
  Widget _buildCompletedVerifications(List<ServiceRequest> allRequests) {
    final completed = allRequests.where((r) => r.isCompleted || r.status == ServiceStatus.closed).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certified Verifications (${completed.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Closed title clearance reports with green-flag verification badges', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (completed.isEmpty)
            _buildEmptyState('No completed audits on record.')
          else
            ...completed.map((r) => _buildVerifDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 15: PAYMENTS
  // ---------------------------------------------------------------------------
  Widget _buildPaymentsSection(String partnerId) {
    final earnings = _service.getTotalEarnings(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verification Fees & Payouts', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Realized legal diligence honorariums', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: const Text('Title Settlement Active', style: TextStyle(color: Color(0xFF3730A3), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 16: CUSTOMER FEEDBACK
  // ---------------------------------------------------------------------------
  Widget _buildCustomerFeedback(String partnerId) {
    final feedbacks = _service.getPartnerFeedbackList(partnerId, category: _category);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Client Feedback & Attorney Ratings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Testimonials from property buyers regarding legal thoroughness', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (feedbacks.isEmpty)
            _buildEmptyState('No reviews yet.')
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
                        Text(f.buyerName ?? 'Verified Buyer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(f.comment ?? 'Very thorough deed search and saved us from a disputed property!', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 17: PARTNER PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildPartnerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legal Partner Profile', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Bar Council accreditations and institutional title auditing certifications', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                Text(_profile?.businessName ?? 'Specialized Legal Verification Partner', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Partner ID: ${_profile?.id ?? "Pending Partner Verification"} • Category: PROPERTY_VERIFICATION', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
  Widget _buildVerifRow(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.fileCheck, color: _accentColor, size: 18),
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

  Widget _buildIncomingVerifCard(ServiceRequest r) {
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
                child: const Text('NEW VERIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
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
                child: const Text('Accept Audit', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifDetailCard(ServiceRequest r) {
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
          Text('Buyer: ${r.customerName} • Property: ${r.propertyTitle ?? "Residential"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
                child: const Text('Mark Clearance Certified', style: TextStyle(fontSize: 11, color: _accentColor)),
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
          const Icon(LucideIcons.fileCheck2, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
