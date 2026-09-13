import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../screens/finance_tools_hub_screen.dart';
import '../screens/credit_score_center_screen.dart';
import '../screens/city_intelligence_hub_screen.dart';
import '../screens/explore_india_screen.dart';
import '../screens/property_tools_screen.dart';
import '../screens/area_discovery_screen.dart';
import '../screens/market_hub_screen.dart';
import '../screens/nearby_services_screen.dart';
import '../models/nearby_category_taxonomy.dart';

class PropzenToolsMegaMenu extends StatelessWidget {
  const PropzenToolsMegaMenu({super.key});

  static void show(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
              const Expanded(child: PropzenToolsMegaMenu()),
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.4),
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 720),
            child: const PropzenToolsMegaMenu(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.layoutGrid, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PropZen Tools & Intelligence Directory',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '39 Everyday Utilities for Money, Living, City Insights & Lifestyle',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Close Menu',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          // Categorized Columns
          Expanded(
            child: SingleChildScrollView(
              child: isMobile
                  ? Column(
                      children: [
                        _buildCategoryColumn(context, 'FINANCE', LucideIcons.indianRupee, const Color(0xFF2563EB), _getFinanceItems(context)),
                        const SizedBox(height: 24),
                        _buildCategoryColumn(context, 'CREDIT & MONEY', LucideIcons.creditCard, const Color(0xFF7C3AED), _getCreditItems(context)),
                        const SizedBox(height: 24),
                        _buildCategoryColumn(context, 'PROPERTY', LucideIcons.home, const Color(0xFF10B981), _getPropertyItems(context)),
                        const SizedBox(height: 24),
                        _buildCategoryColumn(context, 'CITY INTELLIGENCE', LucideIcons.mapPin, const Color(0xFF0D9488), _getCityItems(context)),
                        const SizedBox(height: 24),
                        _buildCategoryColumn(context, 'TRAVEL & LIFESTYLE', LucideIcons.plane, const Color(0xFFF59E0B), _getTravelItems(context)),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildCategoryColumn(context, 'FINANCE', LucideIcons.indianRupee, const Color(0xFF2563EB), _getFinanceItems(context))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryColumn(context, 'CREDIT & MONEY', LucideIcons.creditCard, const Color(0xFF7C3AED), _getCreditItems(context))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryColumn(context, 'PROPERTY', LucideIcons.home, const Color(0xFF10B981), _getPropertyItems(context))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryColumn(context, 'CITY INTELLIGENCE', LucideIcons.mapPin, const Color(0xFF0D9488), _getCityItems(context))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCategoryColumn(context, 'TRAVEL & LIFESTYLE', LucideIcons.plane, const Color(0xFFF59E0B), _getTravelItems(context))),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryColumn(BuildContext context, String title, IconData icon, Color color, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          final rawTitle = (item['title'] as String?) ?? '';
          final cleanTitle = rawTitle.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          final displayTitle = '$index. $cleanTitle';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                final action = item['action'] as VoidCallback?;
                if (action != null) action();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, size: 14, color: const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  List<Map<String, dynamic>> _getFinanceItems(BuildContext context) => [
        {'title': 'Home Loan EMI', 'icon': LucideIcons.calculator, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 0)))},
        {'title': 'Home Affordability', 'icon': LucideIcons.wallet, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 1)))},
        {'title': 'Loan Eligibility', 'icon': LucideIcons.badgeCheck, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 1)))},
        {'title': 'Rent vs Buy', 'icon': LucideIcons.scale, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 2)))},
        {'title': 'Stamp Duty Calculator', 'icon': LucideIcons.receipt, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 3)))},
        {'title': 'Registration Cost', 'icon': LucideIcons.fileCheck, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 3)))},
        {'title': 'Total Purchase Cost', 'icon': LucideIcons.pieChart, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 3)))},
        {'title': 'Property ROI', 'icon': LucideIcons.trendingUp, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 4)))},
        {'title': 'Rental Yield', 'icon': LucideIcons.percent, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 4)))},
        {'title': 'Loan Amortization', 'icon': LucideIcons.calendar, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 0)))},
      ];

  List<Map<String, dynamic>> _getCreditItems(BuildContext context) => [
        {'title': 'Credit Score Center', 'icon': LucideIcons.shieldCheck, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen()))},
        {'title': 'Credit Score Education', 'icon': LucideIcons.bookOpen, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen()))},
        {'title': 'Home Loan Readiness', 'icon': LucideIcons.checkCircle2, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen()))},
        {'title': 'Down Payment Planner', 'icon': LucideIcons.piggyBank, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 1)))},
      ];

  List<Map<String, dynamic>> _getPropertyItems(BuildContext context) => [
        {'title': 'Property Cost Calculator', 'icon': LucideIcons.calculator, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 0)))},
        {'title': 'Interior Cost Calculator', 'icon': LucideIcons.palette, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 0)))},
        {'title': 'Renovation Calculator', 'icon': LucideIcons.wrench, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 1)))},
        {'title': 'Vastu Tool', 'icon': LucideIcons.compass, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 2)))},
        {'title': 'Document Checklist', 'icon': LucideIcons.listChecks, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 3)))},
        {'title': 'Verification Guide', 'icon': LucideIcons.fileSearch, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 4)))},
      ];

  List<Map<String, dynamic>> _getCityItems(BuildContext context) => [
        {'title': 'Area Guide', 'icon': LucideIcons.map, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AreaDiscoveryScreen()))},
        {'title': 'Connectivity Explorer', 'icon': LucideIcons.navigation, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen()))},
        {'title': 'Metro Connectivity', 'icon': LucideIcons.train, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.metroStation)))},
        {'title': 'Airport Connectivity', 'icon': LucideIcons.plane, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen()))},
        {'title': 'Railway Connectivity', 'icon': LucideIcons.train, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen()))},
        {'title': 'Highway Connectivity', 'icon': LucideIcons.car, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen()))},
        {'title': 'Schools Nearby', 'icon': LucideIcons.graduationCap, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.school)))},
        {'title': 'Hospitals Nearby', 'icon': LucideIcons.heartPulse, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.hospital)))},
        {'title': 'Shopping & Lifestyle', 'icon': LucideIcons.shoppingBag, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.mall)))},
        {'title': 'Upcoming Infrastructure', 'icon': LucideIcons.building, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen()))},
        {'title': 'City Property Trends', 'icon': LucideIcons.barChart2, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketHubScreen()))},
        {'title': 'Commute Calculator', 'icon': LucideIcons.clock, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen()))},
      ];

  List<Map<String, dynamic>> _getTravelItems(BuildContext context) => [
        {'title': 'Explore India', 'icon': LucideIcons.globe, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen()))},
        {'title': 'Premium Destinations', 'icon': LucideIcons.star, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen()))},
        {'title': 'Weekend Getaways', 'icon': LucideIcons.sun, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen()))},
        {'title': 'Nearby Attractions', 'icon': LucideIcons.mapPin, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen()))},
        {'title': 'Travel Planner', 'icon': LucideIcons.calendarDays, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen()))},
        {'title': 'Luxury Places', 'icon': LucideIcons.sparkles, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen(initialCategory: 'Luxury & Heritage')))},
        {'title': 'Destination Guide', 'icon': LucideIcons.compass, 'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen()))},
      ];
}
