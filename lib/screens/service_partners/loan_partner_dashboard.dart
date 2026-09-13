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

/// LOAN / HOME FINANCE PARTNER PORTAL
/// Route: /service-partner/loan
/// Completely separate standalone dashboard with finance-focused workflows,
/// banking partner trackers, FOIR calculators, and 11-stage loan pipeline.
class LoanPartnerDashboard extends StatefulWidget {
  final int initialNavIndex;

  const LoanPartnerDashboard({super.key, this.initialNavIndex = 0});

  @override
  State<LoanPartnerDashboard> createState() => _LoanPartnerDashboardState();
}

class _LoanPartnerDashboardState extends State<LoanPartnerDashboard> {
  final ServicePartnerService _service = ServicePartnerService.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedNavIndex;
  ServicePartnerProfile? _profile;
  final ServiceCategoryType _category = ServiceCategoryType.loan;

  // Finance tool states
  double _calcLoanAmount = 7500000;
  double _calcTenureYears = 20;
  double _calcInterestRate = 8.5;

  static const Color _accentColor = Color(0xFF059669); // Emerald Finance

  final List<Map<String, dynamic>> _navSections = [
    {'title': 'Dashboard', 'icon': LucideIcons.layoutDashboard},
    {'title': 'My Loan Journey', 'icon': LucideIcons.gitFork},
    {'title': 'New Loan Requests', 'icon': LucideIcons.inbox},
    {'title': 'Active Applications', 'icon': LucideIcons.fileClock},
    {'title': 'Customers', 'icon': LucideIcons.users},
    {'title': 'Eligibility', 'icon': LucideIcons.calculator},
    {'title': 'Documents', 'icon': LucideIcons.folder},
    {'title': 'Application Processing', 'icon': LucideIcons.cpu},
    {'title': 'Bank/Institution Status', 'icon': LucideIcons.building2},
    {'title': 'Approval Tracking', 'icon': LucideIcons.checkCircle},
    {'title': 'Disbursement', 'icon': LucideIcons.send},
    {'title': 'Payments/Commission', 'icon': LucideIcons.creditCard},
    {'title': 'Completed Cases', 'icon': LucideIcons.archive},
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
    final allLoanRequests = partnerId.isNotEmpty ? _service.getRequestsForPartner(partnerId, category: _category) : <ServiceRequest>[];
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
                  title: 'Loan Partner Portal',
                  subtitle: 'Institutional Lending, Underwriting & Sanction Desk',
                  icon: LucideIcons.landmark,
                  accentColor: _accentColor,
                  profile: _profile,
                  onLogout: _onLogout,
                  onOpenDrawer: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveSection(partnerId, allLoanRequests, newRequests),
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
                child: const Icon(LucideIcons.landmark, color: _accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropZen Loan',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Home Finance Portal',
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
            padding: const EdgeInsets.symmetric(vertical: 10),
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
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, color: _accentColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'NBFC & Banking RERA Compliance Active',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534), fontWeight: FontWeight.w600),
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
        return _buildMyLoanJourney(allRequests);
      case 2:
        return _buildNewLoanRequests(newRequests);
      case 3:
        return _buildActiveApplications(allRequests);
      case 4:
        return _buildCustomersSection(partnerId);
      case 5:
        return _buildEligibilityCalculator();
      case 6:
        return _buildDocumentsSection(allRequests);
      case 7:
        return _buildApplicationProcessing(allRequests);
      case 8:
        return _buildBankInstitutionStatus();
      case 9:
        return _buildApprovalTracking(allRequests);
      case 10:
        return _buildDisbursementSection(allRequests);
      case 11:
        return _buildPaymentsCommission(partnerId);
      case 12:
        return _buildCompletedCases(allRequests);
      case 13:
        return _buildCustomerFeedback(partnerId);
      case 14:
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
    final totalEarnings = _service.getTotalEarnings(partnerId, category: _category);
    final avgRating = _service.getAverageRating(partnerId, category: _category);

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
                    'Finance Executive Dashboard',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    'Track loan files, sanction velocity, and institutional payouts',
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
                onPressed: () => setState(() => _selectedNavIndex = 5),
                icon: const Icon(LucideIcons.calculator, size: 14),
                label: const Text('Calculate Eligibility'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Main Stat Cards
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
                    title: 'New Applications',
                    value: '${newRequests.length}',
                    subtitle: 'Requires Review',
                    icon: LucideIcons.inbox,
                    accentColor: _accentColor,
                    onTap: () => setState(() => _selectedNavIndex = 2),
                  ),
                  ServicePartnerStatCard(
                    title: 'Active in Underwriting',
                    value: '$activeCount',
                    subtitle: 'Processing',
                    icon: LucideIcons.fileClock,
                    accentColor: const Color(0xFF0284C7),
                    onTap: () => setState(() => _selectedNavIndex = 3),
                  ),
                  ServicePartnerStatCard(
                    title: 'Sanctioned / Disbursed',
                    value: '$completedCount',
                    subtitle: 'Closed Cases',
                    icon: LucideIcons.checkCircle2,
                    accentColor: const Color(0xFF7C3AED),
                    onTap: () => setState(() => _selectedNavIndex = 12),
                  ),
                  ServicePartnerStatCard(
                    title: 'Disbursement Volume',
                    value: '₹${(totalEarnings / 100000).toStringAsFixed(1)}L',
                    subtitle: '$avgRating ★ Rating',
                    icon: LucideIcons.indianRupee,
                    accentColor: const Color(0xFFEA580C),
                    onTap: () => setState(() => _selectedNavIndex = 11),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Journey tracker demo
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 5,
            accentColor: _accentColor,
            onStepSelected: (step) => setState(() => _selectedNavIndex = 1),
          ),
          const SizedBox(height: 24),

          // Recent Requests Table
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
                      'Live Loan Applications',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedNavIndex = 3),
                      child: const Text('View All Applications', style: TextStyle(color: _accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (allRequests.isEmpty && newRequests.isEmpty)
                  _buildEmptyState('No loan applications currently assigned.')
                else
                  ...allRequests.take(4).map((r) => _buildLoanRequestRow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: MY LOAN JOURNEY (11 Stages)
  // ---------------------------------------------------------------------------
  Widget _buildMyLoanJourney(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Loan Journey Lifecycle',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            'Standardized 11-stage institutional home loan underwriting pipeline',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          ServiceJourneyTrackerWidget(
            category: _category,
            currentStepIndex: 5,
            accentColor: _accentColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Journey Stage Breakdown',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
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
                        Text(s.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text(s.description, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Stage ${s.stepIndex}', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: NEW LOAN REQUESTS
  // ---------------------------------------------------------------------------
  Widget _buildNewLoanRequests(List<ServiceRequest> newRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Loan Requests',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            'Incoming home loan inquiries awaiting partner acceptance',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          if (newRequests.isEmpty)
            _buildEmptyState('No pending loan requests currently. New inquiries will appear here automatically.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final r = newRequests[i];
                return _buildIncomingRequestCard(r);
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: ACTIVE APPLICATIONS
  // ---------------------------------------------------------------------------
  Widget _buildActiveApplications(List<ServiceRequest> allRequests) {
    final active = allRequests.where((r) => r.isActive).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Loan Applications (${active.length})',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            'Applications currently under bank underwriting and verification',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          if (active.isEmpty)
            _buildEmptyState('No active loan files right now.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: active.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _buildLoanDetailCard(active[i]),
            ),
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
          Text(
            'Borrower Profiles (${customers.length})',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            'Verified loan applicants and primary KYC contacts',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          if (customers.isEmpty)
            _buildEmptyState('No customer dossiers on file.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final c = customers[i];
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
                        radius: 20,
                        backgroundColor: _accentColor.withOpacity(0.15),
                        child: Text(
                          c['name'].isNotEmpty ? c['name'][0] : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: _accentColor),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Phone: ${c['phone']} • Email: ${c['email']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                            Text('Property: ${c['propertyTitle']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c['status'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
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

  // ---------------------------------------------------------------------------
  // SECTION 5: ELIGIBILITY CALCULATOR
  // ---------------------------------------------------------------------------
  Widget _buildEligibilityCalculator() {
    final monthlyRate = (_calcInterestRate / 12) / 100;
    final totalMonths = _calcTenureYears * 12;
    final emi = (_calcLoanAmount * monthlyRate * (1 + monthlyRate)) / (1 + monthlyRate); // simplified calculation
    final totalPayment = emi * totalMonths;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Institutional Loan Eligibility & EMI Calculator',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            'Instant FOIR, Max LTV, and monthly amortization simulator for client consultations',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
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
                    Text('Loan Amount: ₹${(_calcLoanAmount / 100000).toStringAsFixed(0)} Lakhs', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Text('Tenure: ${_calcTenureYears.toInt()} Years', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    Text('Interest Rate: ${_calcInterestRate.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Slider(
                  value: _calcLoanAmount,
                  min: 1000000,
                  max: 50000000,
                  divisions: 49,
                  activeColor: _accentColor,
                  onChanged: (v) => setState(() => _calcLoanAmount = v),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Estimated Monthly EMI', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
                          Text('₹${(emi).toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _accentColor)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Max Eligible LTV', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
                          Text('80% - 85%', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: _accentColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 6: DOCUMENTS
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Documents & KYC Dossiers', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Bank verification documents: ITR V, 6M Bank Statements, Chain Deed & NOC', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) {
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text('${r.documents.length} Docs Attached', style: const TextStyle(fontSize: 11, color: _accentColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: r.requiredDocumentsList.map((doc) {
                      return Chip(
                        label: Text(doc, style: const TextStyle(fontSize: 10)),
                        backgroundColor: const Color(0xFFF1F5F9),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 7: APPLICATION PROCESSING
  // ---------------------------------------------------------------------------
  Widget _buildApplicationProcessing(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Application Processing & Underwriting Queue', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Advancement through CIBIL check, field investigation, and credit committee', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildLoanDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 8: BANK / INSTITUTION STATUS
  // ---------------------------------------------------------------------------
  Widget _buildBankInstitutionStatus() {
    final banks = [
      {'name': 'HDFC Bank Ltd', 'rate': '8.35%', 'status': 'Preferred Partner', 'speed': '48-hr Sanction'},
      {'name': 'State Bank of India', 'rate': '8.40%', 'status': 'Active API Integration', 'speed': '5-day Processing'},
      {'name': 'ICICI Bank', 'rate': '8.45%', 'status': 'Direct Underwriting Access', 'speed': '24-hr In-Principle'},
      {'name': 'Axis Bank', 'rate': '8.50%', 'status': 'Active Tie-up', 'speed': '72-hr Sanction'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Institutional Lending Partners', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Approved banking tie-ups and direct DSA sanction lines', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...banks.map((b) {
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
                  const Icon(LucideIcons.building2, color: _accentColor, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['name']!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('Floating Rate from ${b['rate']} • ${b['speed']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(b['status']!, style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 9: APPROVAL TRACKING
  // ---------------------------------------------------------------------------
  Widget _buildApprovalTracking(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Approval & Sanction Tracking', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Official bank credit committee sanctions and formal offer letters', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildLoanDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 10: DISBURSEMENT
  // ---------------------------------------------------------------------------
  Widget _buildDisbursementSection(List<ServiceRequest> allRequests) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Disbursement & Tranche Release', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Builder demand letters, agreement sign-offs, and RTGS release records', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          ...allRequests.map((r) => _buildLoanDetailCard(r)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 11: PAYMENTS / COMMISSION
  // ---------------------------------------------------------------------------
  Widget _buildPaymentsCommission(String partnerId) {
    final earnings = _service.getTotalEarnings(partnerId, category: _category);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commission & Partner Payouts', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Institutional DSA referral commission payout ledger', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                    Text('Total Payout Realized', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    Text('₹${earnings.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: _accentColor)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Text('Bank Settlement Active', style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 12: COMPLETED CASES
  // ---------------------------------------------------------------------------
  Widget _buildCompletedCases(List<ServiceRequest> allRequests) {
    final completed = allRequests.where((r) => r.isCompleted || r.status == ServiceStatus.closed).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Completed Loan Cases (${completed.length})', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Fully disbursed and closed home loan files', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (completed.isEmpty)
            _buildEmptyState('No completed loan files yet.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _buildLoanDetailCard(completed[i]),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 13: CUSTOMER FEEDBACK
  // ---------------------------------------------------------------------------
  Widget _buildCustomerFeedback(String partnerId) {
    final feedbacks = _service.getPartnerFeedbackList(partnerId, category: _category);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Borrower Reviews & Ratings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Direct testimonials from loan applicants after disbursement', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          if (feedbacks.isEmpty)
            _buildEmptyState('No customer reviews recorded yet.')
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
                        Text(f.buyerName ?? 'Verified Applicant', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(f.comment ?? 'Smooth loan processing and great bank guidance.', style: GoogleFonts.inter(fontSize: 12)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 14: PARTNER PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildPartnerProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Partner Profile & Accreditations', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Authorized institutional credentials and DSA licensing', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
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
                Text(_profile?.businessName ?? 'Specialized Partner Desk', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Partner ID: ${_profile?.id ?? "Pending Partner Verification"} • Specialization: LOAN', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Text('Contact: ${_profile?.phone.isNotEmpty == true ? _profile!.phone : "Not provided"} | ${_profile?.email.isNotEmpty == true ? _profile!.email : "Not provided"}'),
                const SizedBox(height: 6),
                Text('Institutional Status: ${_profile?.status ?? "PENDING"} (${_profile?.verificationStatus ?? "UNDER_REVIEW"})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildLoanRequestRow(ServiceRequest r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.fileText, color: _accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${r.customerName} • ${r.customerPhone}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Text(r.status.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _accentColor)),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestCard(ServiceRequest r) {
    return Container(
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
                child: Text('NEW INQUIRY', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _accentColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Applicant: ${r.customerName} (${r.customerPhone})', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
                child: const Text('Accept Loan File', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoanDetailCard(ServiceRequest r) {
    return Container(
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
          Text('Borrower: ${r.customerName} • Property: ${r.propertyTitle ?? "General Real Estate"}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
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
                child: const Text('Mark Case Disbursed & Completed', style: TextStyle(fontSize: 11, color: _accentColor)),
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
          const Icon(LucideIcons.landmark, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
