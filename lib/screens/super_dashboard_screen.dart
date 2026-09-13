import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/super_dashboard_seo_models.dart';
import '../services/super_dashboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin/admin_seo_workspace_widget.dart';
import '../widgets/admin/admin_monetization_workspace_widget.dart';

class SuperDashboardScreen extends StatefulWidget {
  const SuperDashboardScreen({super.key});

  @override
  State<SuperDashboardScreen> createState() => _SuperDashboardScreenState();
}

class _SuperDashboardScreenState extends State<SuperDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SuperDashboardService _service = SuperDashboardService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _service.fetchPlatformOverview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    if (val >= 10000000) {
      return '₹ ${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '₹ ${(val / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹ ${val.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final m = _service.metrics;
        final isDesktop = MediaQuery.of(context).size.width >= 1000;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Text(
              'PropZen Super Dashboard',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppTheme.primaryViolet),
                onPressed: () => _service.fetchPlatformOverview(),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryViolet,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryViolet,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(LucideIcons.barChart2, size: 18), text: 'Super Dashboard'),
                Tab(icon: Icon(LucideIcons.globe, size: 18), text: 'SEO Engine'),
                Tab(icon: Icon(LucideIcons.wallet, size: 18), text: 'Monetization Rules'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(m, isDesktop),
              const AdminSeoWorkspaceWidget(),
              const AdminMonetizationWorkspaceWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab(PlatformOverviewMetrics m, bool isDesktop) {
    final categories = _service.getCategoryDistribution();
    final locations = _service.getLocationDistribution();
    final revenue = _service.getMonthlyRevenueSeries();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metric Overview Cards
          _buildMetricsGrid(m, isDesktop),

          const SizedBox(height: 24),

          // 2. Charts Row: Category Distribution & Locality Spread
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCategoryDistributionCard(categories)),
                const SizedBox(width: 20),
                Expanded(child: _buildLocalitySpreadCard(locations)),
              ],
            )
          else ...[
            _buildCategoryDistributionCard(categories),
            const SizedBox(height: 20),
            _buildLocalitySpreadCard(locations),
          ],

          const SizedBox(height: 24),

          // 3. Lead Funnel & Revenue Trends
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeadFunnelCard(m)),
                const SizedBox(width: 20),
                Expanded(child: _buildRevenueSeriesCard(revenue)),
              ],
            )
          else ...[
            _buildLeadFunnelCard(m),
            const SizedBox(height: 20),
            _buildRevenueSeriesCard(revenue),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(PlatformOverviewMetrics m, bool isDesktop) {
    final items = [
      {'label': 'Total Users', 'val': '${m.totalUsers}', 'sub': '${m.activeUsers} active', 'icon': LucideIcons.users, 'color': AppTheme.primaryViolet},
      {'label': 'Verified Dealers', 'val': '${m.verifiedDealers}', 'sub': '${m.pendingDealers} pending review', 'icon': LucideIcons.briefcase, 'color': AppTheme.emeraldSuccess},
      {'label': 'Live Properties', 'val': '${m.liveProperties}', 'sub': '${m.pendingProperties} pending review', 'icon': LucideIcons.home, 'color': AppTheme.accentEmerald},
      {'label': 'Verified Listings', 'val': '${m.verifiedProperties}', 'sub': 'RERA & Legal AI verified', 'icon': LucideIcons.shieldCheck, 'color': const Color(0xFF0284C7)},
      {'label': 'Customer Enquiries', 'val': '${m.totalEnquiries}', 'sub': '${m.totalSiteVisits} visits booked', 'icon': LucideIcons.messageSquare, 'color': const Color(0xFF8B5CF6)},
      {'label': 'Monetized Leads', 'val': '${m.totalLeads}', 'sub': '${m.convertedLeads} converted (${m.conversionRatePercent.toStringAsFixed(0)}%)', 'icon': LucideIcons.target, 'color': AppTheme.coralDanger},
      {'label': 'Platform Revenue', 'val': _formatCurrency(m.totalRevenueInr), 'sub': '${m.walletTransactionsCount} ledger events', 'icon': LucideIcons.trendingUp, 'color': AppTheme.emeraldSuccess},
      {'label': 'Conversion Rate', 'val': '${m.conversionRatePercent.toStringAsFixed(1)}%', 'sub': 'Lead to site visit ROI', 'icon': LucideIcons.award, 'color': const Color(0xFFD97706)},
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = isDesktop ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 110,
        ),
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final it = items[idx];
          final color = it['color'] as Color;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
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
                    Text(it['label'] as String, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    Icon(it['icon'] as IconData, size: 16, color: color),
                  ],
                ),
                Text(it['val'] as String, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(it['sub'] as String, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildCategoryDistributionCard(List<CategorySlice> categories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.pieChart, size: 18, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              Text('Property Category Distribution', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.categoryName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${c.count} listings (${c.percentage.toStringAsFixed(1)}%)', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.percentage / 100,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLocalitySpreadCard(List<LocationMetric> locations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 18, color: AppTheme.emeraldSuccess),
              const SizedBox(width: 8),
              Text('Key Corridor Concentration', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...locations.map((loc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(loc.sectorOrCity, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('₹ ${loc.avgPriceCr.toStringAsFixed(2)} Cr avg', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('${loc.propertyCount} props', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLeadFunnelCard(PlatformOverviewMetrics m) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.filter, size: 18, color: AppTheme.coralDanger),
              const SizedBox(width: 8),
              Text('Lead Monetization Funnel', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildFunnelStage('1. Inquiries Generated', m.totalEnquiries, 1.0, const Color(0xFF6366F1)),
          _buildFunnelStage('2. Qualified Leads Distributed', m.totalLeads, m.totalEnquiries > 0 ? m.totalLeads / m.totalEnquiries : 0.8, const Color(0xFF8B5CF6)),
          _buildFunnelStage('3. Site Visits Scheduled', m.totalSiteVisits, m.totalEnquiries > 0 ? m.totalSiteVisits / m.totalEnquiries : 0.5, const Color(0xFFEC4899)),
          _buildFunnelStage('4. Deals Converted', m.convertedLeads, m.totalEnquiries > 0 ? m.convertedLeads / m.totalEnquiries : 0.3, AppTheme.emeraldSuccess),
        ],
      ),
    );
  }

  Widget _buildFunnelStage(String label, int count, double ratio, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$count', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSeriesCard(List<MonthlyRevenueDataPoint> revenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 18, color: AppTheme.emeraldSuccess),
              const SizedBox(width: 8),
              Text('Monthly Revenue Trajectory', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...revenue.map((dp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text(dp.month, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₹ ${(dp.total / 1000).toStringAsFixed(0)}k total', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Subs: ₹${(dp.subscriptionRevenue / 1000).toStringAsFixed(0)}k | Wallets: ₹${(dp.walletRechargeRevenue / 1000).toStringAsFixed(0)}k | Leads: ₹${(dp.leadPurchaseRevenue / 1000).toStringAsFixed(0)}k', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
