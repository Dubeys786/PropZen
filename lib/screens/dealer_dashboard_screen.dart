import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../services/deal_room_service.dart';
import '../services/dealer_lead_service.dart';
import '../models/deal_room_model.dart';
import '../models/property.dart';
import '../models/lead_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/dealer_subscription_status_card.dart';
import '../widgets/dealer_buyer_matching_modal.dart';
import '../widgets/dealer_payment_history_modal.dart';
import '../widgets/dealer_notifications_modal.dart';
import 'dealer_properties_screen.dart';
import 'dealer_leads_screen.dart';
import 'dealer_site_visits_screen.dart';
import 'ai_listing_creator_screen.dart';
import 'deal_room_screen.dart';
import 'user_profile_screen.dart';
import 'dealer_subscription_plans_screen.dart';

class DealerDashboardScreen extends StatefulWidget {
  const DealerDashboardScreen({super.key});

  @override
  State<DealerDashboardScreen> createState() => _DealerDashboardScreenState();
}

class _DealerDashboardScreenState extends State<DealerDashboardScreen> {
  int _selectedSidebarIndex = 0; // 0: Overview, 1: Properties, 2: AI Listing Creator, 3: Leads, 4: Site Visits, 5: Deal Rooms
  String _selectedPeriod = 'This Month';

  final List<String> _periodOptions = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year'];

  void _onAddNewProperty() {
    setState(() => _selectedSidebarIndex = 2); // Switch to AI Listing Creator
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (context, _) {
        final dealerName = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Dealer Partner';

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.layoutDashboard, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Propzen Dealer Panel',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dealerName,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isDesktop) ...[
                // Enterprise CRM Pipeline CTA
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.crm),
                  icon: const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF10B981)),
                  label: Text('Enterprise CRM', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                ),
                const SizedBox(width: 4),

                // AI Buyer Matchmaker CTA
                TextButton.icon(
                  onPressed: () => DealerBuyerMatchingModal.show(context),
                  icon: const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.primaryViolet),
                  label: Text('AI Matchmaker', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ),
                const SizedBox(width: 4),

                // Billing & Invoices CTA
                TextButton.icon(
                  onPressed: () => DealerPaymentHistoryModal.show(context),
                  icon: const Icon(LucideIcons.receipt, size: 14, color: Color(0xFF475569)),
                  label: Text('Invoices', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                ),
                const SizedBox(width: 4),
              ] else ...[
                IconButton(
                  onPressed: () => DealerBuyerMatchingModal.show(context),
                  icon: const Icon(LucideIcons.sparkles, size: 18, color: AppTheme.primaryViolet),
                  tooltip: 'AI Matchmaker',
                ),
              ],

              // Dealer Notifications Bell with Unread Badge
              AnimatedBuilder(
                animation: DealerLeadService.instance,
                builder: (context, _) {
                  final unread = DealerLeadService.instance.unreadNotificationsCount;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () => DealerNotificationsModal.show(context),
                        icon: const Icon(LucideIcons.bell, size: 18, color: AppTheme.textPrimary),
                        tooltip: 'Notifications',
                      ),
                      if (unread > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 4),

              if (isDesktop) ...[
                // Period Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    dropdownColor: Colors.white,
                    underline: const SizedBox.shrink(),
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                    items: _periodOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => _selectedPeriod = val!),
                  ),
                ),
                const SizedBox(width: 10),

                // AI Listing Creator CTA
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: ElevatedButton.icon(
                    onPressed: _onAddNewProperty,
                    icon: const Icon(LucideIcons.wand2, size: 15),
                    label: Text('AI Listing Creator', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: _onAddNewProperty,
                  icon: const Icon(LucideIcons.wand2, size: 18, color: AppTheme.primaryViolet),
                  tooltip: 'AI Listing Creator',
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              // Left Sidebar (Desktop View)
              if (isDesktop) _buildDesktopSidebar(),

              // Main Dashboard Content Area
              Expanded(
                child: _buildSelectedSubScreen(),
              ),
            ],
          ),
          bottomNavigationBar: (!isDesktop)
              ? Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.borderLight)),
                    color: Colors.white,
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedSidebarIndex.clamp(0, 5),
                    onTap: (idx) => setState(() => _selectedSidebarIndex = idx),
                    backgroundColor: Colors.white,
                    selectedItemColor: AppTheme.primaryViolet,
                    unselectedItemColor: const Color(0xFF64748B),
                    type: BottomNavigationBarType.fixed,
                    items: const [
                      BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard), label: 'Analytics'),
                      BottomNavigationBarItem(icon: Icon(LucideIcons.building), label: 'Properties'),
                      BottomNavigationBarItem(icon: Icon(LucideIcons.wand2), label: 'AI Creator'),
                      BottomNavigationBarItem(icon: Icon(LucideIcons.users), label: 'Leads'),
                      BottomNavigationBarItem(icon: Icon(LucideIcons.shieldCheck), label: 'Deal Rooms'),
                      BottomNavigationBarItem(icon: Icon(LucideIcons.crown), label: 'Plans'),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildSelectedSubScreen() {
    switch (_selectedSidebarIndex) {
      case 1:
        return const DealerPropertiesScreen();
      case 2:
        return AiListingCreatorScreen(
          onPublished: () => setState(() => _selectedSidebarIndex = 1),
        );
      case 3:
        return const DealerLeadsScreen();
      case 4:
        return const DealerSiteVisitsScreen();
      case 5:
        final rooms = DealRoomService.instance.getRoomsForDealer(UserSession.dealerId);
        final roomId = rooms.isNotEmpty ? rooms.first.id : '';
        return DealRoomScreen(dealRoomId: roomId);
      case 6:
        return const DealerSubscriptionPlansScreen();
      case 0:
      default:
        return _buildDashboardOverview();
    }
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSidebarItem(0, 'Analytics Overview', LucideIcons.layoutDashboard),
          _buildSidebarItem(1, 'My Properties', LucideIcons.building),
          _buildSidebarItem(2, 'AI Listing Creator', LucideIcons.wand2),
          _buildSidebarItem(3, 'Leads & AI Scoring', LucideIcons.users),
          _buildSidebarItem(4, 'Site Visits', LucideIcons.calendar),
          _buildSidebarItem(5, 'Safe Deal Rooms', LucideIcons.shieldCheck),
          _buildSidebarItem(6, 'Subscription & Plans', LucideIcons.crown),

          const Spacer(),

          // Verified Institutional Partner Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Verified Institutional',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Real-time AI property verification and buyer matchmaking active.', style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSel = _selectedSidebarIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSel ? AppTheme.primaryViolet.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSel ? Border.all(color: AppTheme.primaryViolet) : null,
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedSidebarIndex = index),
        dense: true,
        leading: Icon(icon, size: 18, color: isSel ? AppTheme.primaryViolet : const Color(0xFF64748B)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? AppTheme.primaryViolet : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardOverview() {
    final state = PropertyStateService.instance;
    final leadService = DealerLeadService.instance;
    final dealRoomService = DealRoomService.instance;

    final dealerId = UserSession.dealerId;
    final dealerProps = state.getDealerPropertiesFor(dealerId);
    final leads = leadService.getLeadsForDealer(dealerId);
    final visits = leadService.getSiteVisitsForDealer(dealerId);
    final rooms = dealRoomService.getRoomsForDealer(dealerId);

    // Calculate real dynamic stats
    final totalPropsCount = dealerProps.length;
    int totalViews = 0;
    for (final p in dealerProps) {
      totalViews += p.viewsCount;
    }
    final totalLeadsCount = leads.length;
    final qualifiedLeadsCount = leads.where((l) => l.isQualified || l.scoreTier == LeadScoreTier.hot || l.scoreTier == LeadScoreTier.warm).length;
    final totalVisitsCount = visits.length;
    final cabVisitsCount = visits.where((v) => v.cabRequired).length;
    final cabAssistedPercent = totalVisitsCount > 0 ? ((cabVisitsCount / totalVisitsCount) * 100).round() : 0;
    final activeNegotiationsCount = rooms.where((r) => r.stage != DealStage.dealCompleted).length;
    final completedDeals = rooms.where((r) => r.stage == DealStage.dealCompleted).toList();
    final dealsClosedCount = completedDeals.length + leads.where((l) => l.isConverted).length;
    double volumeCr = 0.0;
    for (final r in completedDeals) {
      volumeCr += (r.agreedPriceCr ?? r.listedPriceCr);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dedicated Institutional Dealer Subscription & Limits Status Card
              const DealerSubscriptionStatusCard(),

              const SizedBox(height: 20),

              // 8 Institutional KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: crossAxisCount >= 4 ? 1.6 : (crossAxisCount == 1 ? 2.8 : 1.4),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildMetricCard(
                        'Total Properties',
                        '$totalPropsCount',
                        totalPropsCount > 0 ? '+$totalPropsCount listed' : '0 listed',
                        LucideIcons.building,
                        AppTheme.primaryViolet,
                        () => setState(() => _selectedSidebarIndex = 1),
                      ),
                      _buildMetricCard(
                        'Property Views',
                        '$totalViews',
                        totalViews > 0 ? '$totalViews this month' : '0 views',
                        LucideIcons.eye,
                        const Color(0xFF0284C7),
                      ),
                      _buildMetricCard(
                        'Total Leads',
                        '$totalLeadsCount',
                        totalLeadsCount > 0 ? '$totalLeadsCount active' : '0 active',
                        LucideIcons.users,
                        const Color(0xFF10B981),
                        () => setState(() => _selectedSidebarIndex = 3),
                      ),
                      _buildMetricCard(
                        'Qualified Leads',
                        '$qualifiedLeadsCount',
                        qualifiedLeadsCount > 0 ? '$qualifiedLeadsCount pre-approved' : '0 qualified',
                        LucideIcons.userCheck,
                        const Color(0xFFF59E0B),
                      ),
                      _buildMetricCard(
                        'Site Visits',
                        '$totalVisitsCount',
                        totalVisitsCount > 0 ? '$cabAssistedPercent% Cab Assisted' : '0 visits',
                        LucideIcons.calendarCheck,
                        AppTheme.emeraldSuccess,
                        () => setState(() => _selectedSidebarIndex = 4),
                      ),
                      _buildMetricCard(
                        'Active Negotiations',
                        '$activeNegotiationsCount',
                        activeNegotiationsCount > 0 ? '$activeNegotiationsCount in Deal Room' : '0 in Deal Room',
                        LucideIcons.scale,
                        AppTheme.primaryViolet,
                        () => setState(() => _selectedSidebarIndex = 5),
                      ),
                      _buildMetricCard(
                        'Deals Converted',
                        '$dealsClosedCount',
                        volumeCr > 0 ? '₹${volumeCr.toStringAsFixed(1)} Cr Volume' : '₹0 Cr Volume',
                        LucideIcons.award,
                        const Color(0xFFD97706),
                      ),
                      _buildMetricCard(
                        'Response Rate',
                        totalLeadsCount > 0 ? '100%' : '0%',
                        totalLeadsCount > 0 ? 'Avg 15m Response' : '0m Response',
                        LucideIcons.zap,
                        const Color(0xFF059669),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Visual Lead Conversion Funnel
              _buildConversionFunnelCard(
                views: totalViews,
                enquiries: totalLeadsCount,
                qualified: qualifiedLeadsCount,
                visits: totalVisitsCount,
                negotiations: activeNegotiationsCount,
                deals: dealsClosedCount,
              ),

              const SizedBox(height: 24),

              // Bottom Row: Recent Properties & Quick Actions
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildRecentPropertiesCard(dealerProps)),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _buildQuickActionsCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildRecentPropertiesCard(dealerProps),
                            const SizedBox(height: 16),
                            _buildQuickActionsCard(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String growth, IconData icon, Color color, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 14),
                ),
              ],
            ),
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Row(
              children: [
                Icon(LucideIcons.trendingUp, size: 11, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    growth,
                    style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionFunnelCard({
    int views = 0,
    int enquiries = 0,
    int qualified = 0,
    int visits = 0,
    int negotiations = 0,
    int deals = 0,
  }) {
    final maxBase = views > 0 ? views.toDouble() : (enquiries > 0 ? enquiries.toDouble() : 1.0);
    final hasData = views > 0 || enquiries > 0 || visits > 0 || deals > 0;

    final funnelStages = [
      {'label': '1. Views', 'count': '$views', 'pct': views > 0 ? 1.0 : 0.0, 'color': const Color(0xFF6366F1)},
      {'label': '2. Enquiries', 'count': '$enquiries', 'pct': hasData ? (enquiries / maxBase).clamp(0.0, 1.0) : 0.0, 'color': const Color(0xFF3B82F6)},
      {'label': '3. Qualified', 'count': '$qualified', 'pct': hasData ? (qualified / maxBase).clamp(0.0, 1.0) : 0.0, 'color': const Color(0xFF0EA5E9)},
      {'label': '4. Visits', 'count': '$visits', 'pct': hasData ? (visits / maxBase).clamp(0.0, 1.0) : 0.0, 'color': const Color(0xFF10B981)},
      {'label': '5. Negotiations', 'count': '$negotiations', 'pct': hasData ? (negotiations / maxBase).clamp(0.0, 1.0) : 0.0, 'color': const Color(0xFFF59E0B)},
      {'label': '6. Deals Closed', 'count': deals > 0 ? '$deals Deals' : '0 Deals', 'pct': hasData ? (deals / maxBase).clamp(0.0, 1.0) : 0.0, 'color': const Color(0xFF8B5CF6)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(LucideIcons.filter, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text('Dealer Conversion & Sales Funnel', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('End-to-End Pipeline Performance', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: funnelStages.map((stage) {
                  final double widthFraction = stage['pct'] as double;
                  final Color color = stage['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(stage['label'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, barConstraints) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 26,
                                    decoration: BoxDecoration(color: AppTheme.surfaceSubtle, borderRadius: BorderRadius.circular(6)),
                                  ),
                                  Container(
                                    width: barConstraints.maxWidth * widthFraction.clamp(0.0, 1.0),
                                    height: 26,
                                    decoration: BoxDecoration(color: color.withOpacity(0.85), borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      stage['count'] as String,
                                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPropertiesCard(List<Property> myProps) {
    if (myProps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Performing Listings',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.building, color: AppTheme.primaryViolet, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'No properties listed yet',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first property listing to start receiving enquiries.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedSidebarIndex = 2),
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              label: Text(
                'Add Property',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Performing Listings', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              TextButton(
                onPressed: () => setState(() => _selectedSidebarIndex = 1),
                child: Text('View All', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...myProps.take(5).map((prop) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: AppTheme.surfaceHighlight,
                        child: Image.network(
                          prop.dynamicImageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(LucideIcons.building, size: 20, color: AppTheme.primaryViolet),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(prop.title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${prop.bhk} • ₹${prop.askingPriceCr.toStringAsFixed(2)} Cr', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('ACTIVE ✓', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          _buildQuickActionButton('AI Listing Creator', LucideIcons.wand2, AppTheme.primaryViolet, () => setState(() => _selectedSidebarIndex = 2)),
          const SizedBox(height: 8),
          _buildQuickActionButton('Leads & AI Scoring', LucideIcons.users, const Color(0xFF0284C7), () => setState(() => _selectedSidebarIndex = 3)),
          const SizedBox(height: 8),
          _buildQuickActionButton('Safe Deal Rooms', LucideIcons.shieldCheck, const Color(0xFF10B981), () => setState(() => _selectedSidebarIndex = 5)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          alignment: Alignment.centerLeft,
          side: const BorderSide(color: AppTheme.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
