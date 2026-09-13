import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class MarketHubScreen extends StatefulWidget {
  const MarketHubScreen({super.key});

  @override
  State<MarketHubScreen> createState() => _MarketHubScreenState();
}

class _MarketHubScreenState extends State<MarketHubScreen> {
  String _selectedRegionFilter = 'All';
  bool _isRefreshing = false;
  String _lastUpdated = 'Today, 10:30 AM';
  bool _showAllSectors = false;

  final List<Map<String, dynamic>> _kpiStats = [
    {
      'title': 'Average Price Growth',
      'value': '+18.2%',
      'period': 'YoY',
      'trend': '+2.4% vs last quarter',
      'icon': LucideIcons.trendingUp,
      'color': AppTheme.emeraldSuccess,
      'bg': Color(0xFFECFDF5),
    },
    {
      'title': 'Top Growth Zone',
      'value': 'Yamuna Exp.',
      'period': 'YoY',
      'trend': '+28.4% • Jewar Hub',
      'icon': LucideIcons.flame,
      'color': AppTheme.primaryViolet,
      'bg': Color(0xFFF5F3FF),
    },
    {
      'title': 'Infrastructure Catalysts',
      'value': '12 Active',
      'period': 'High Impact',
      'trend': '4 Scheduled in 2026-27',
      'icon': LucideIcons.layers,
      'color': Color(0xFF0284C7),
      'bg': Color(0xFFE0F2FE),
    },
    {
      'title': 'Market Sentiment',
      'value': 'Bullish',
      'period': 'Institutional',
      'trend': 'High Buyer Velocity',
      'icon': LucideIcons.gauge,
      'color': AppTheme.indigoPrimary,
      'bg': Color(0xFFEEF2FF),
    },
  ];

  final List<Map<String, dynamic>> _growthSectors = [
    {
      'id': 'yamuna_exp',
      'name': 'Yamuna Expressway',
      'corridor': 'Jewar Airport Zone',
      'region': 'Expressways',
      'yoyGrowth': '+28.4% YoY',
      'growthRate': 0.92,
      'trendTag': 'High Growth',
      'priceRange': '₹6,500 – ₹9,500 / sq.ft.',
      'infraScore': '92/100',
      'demand': 'Very High',
      'accentColor': AppTheme.emeraldSuccess,
    },
    {
      'id': 'sec_137_150',
      'name': 'Sector 150 & 137 Noida',
      'corridor': 'Aqua Line Metro Corridor',
      'region': 'Noida',
      'yoyGrowth': '+18.2% YoY',
      'growthRate': 0.84,
      'trendTag': 'High Growth',
      'priceRange': '₹8,200 – ₹12,500 / sq.ft.',
      'infraScore': '88/100',
      'demand': 'High',
      'accentColor': AppTheme.primaryViolet,
    },
    {
      'id': 'golf_course_ext',
      'name': 'Golf Course Ext Gurgaon',
      'corridor': 'Luxury Housing Corridor',
      'region': 'Gurgaon',
      'yoyGrowth': '+15.8% YoY',
      'growthRate': 0.78,
      'trendTag': 'Steady Growth',
      'priceRange': '₹14,000 – ₹22,000 / sq.ft.',
      'infraScore': '85/100',
      'demand': 'Very High',
      'accentColor': AppTheme.indigoPrimary,
    },
    {
      'id': 'dwarka_exp',
      'name': 'Dwarka Expressway Delhi / NCR',
      'corridor': 'Northern Peripheral Corridor',
      'region': 'Expressways',
      'yoyGrowth': '+14.5% YoY',
      'growthRate': 0.76,
      'trendTag': 'High Velocity',
      'priceRange': '₹11,500 – ₹17,000 / sq.ft.',
      'infraScore': '89/100',
      'demand': 'High',
      'accentColor': Color(0xFFD946EF),
    },
    {
      'id': 'noida_ext',
      'name': 'Greater Noida West',
      'corridor': 'Tech Zone IV & Metro Extension',
      'region': 'Noida',
      'yoyGrowth': '+12.8% YoY',
      'growthRate': 0.72,
      'trendTag': 'High Volume',
      'priceRange': '₹5,800 – ₹8,200 / sq.ft.',
      'infraScore': '81/100',
      'demand': 'High',
      'accentColor': Color(0xFF06B6D4),
    },
    {
      'id': 'sohna_road',
      'name': 'Sohna Road (South Gurgaon)',
      'corridor': 'Delhi-Mumbai Expressway Spur',
      'region': 'Gurgaon',
      'yoyGrowth': '+11.4% YoY',
      'growthRate': 0.68,
      'trendTag': 'Emerging Hub',
      'priceRange': '₹7,200 – ₹10,800 / sq.ft.',
      'infraScore': '79/100',
      'demand': 'Moderate–High',
      'accentColor': AppTheme.amberWarning,
    },
  ];

  final List<Map<String, dynamic>> _timelineItems = [
    {
      'quarter': 'Q4 2026',
      'title': 'Noida International Airport Operational Runways',
      'status': 'On Track',
      'statusColor': AppTheme.emeraldSuccess,
      'statusBg': Color(0xFFECFDF5),
      'impact': 'High Impact (+15–20% micro-market uplift)',
      'category': 'Aviation & Logistics Hub',
      'icon': LucideIcons.planeTakeoff,
    },
    {
      'quarter': 'Q1 2027',
      'title': 'Aqua Line Metro Extension to Greater Noida West',
      'status': 'Planned',
      'statusColor': AppTheme.indigoPrimary,
      'statusBg': Color(0xFFEEF2FF),
      'impact': 'High Impact (Commute reduction for 5L+ residents)',
      'category': 'Rapid Mass Transit',
      'icon': LucideIcons.navigation,
    },
    {
      'quarter': 'Q3 2027',
      'title': 'Cyber City 2 Tech Hub Opening in Gurgaon',
      'status': 'Planned',
      'statusColor': AppTheme.primaryViolet,
      'statusBg': Color(0xFFF5F3FF),
      'impact': 'Medium–High Impact (50,000+ tech job creation)',
      'category': 'Commercial IT & SEZ',
      'icon': LucideIcons.building2,
    },
    {
      'quarter': 'Q4 2027',
      'title': 'Delhi-Varanasi High Speed Rail Corridor (NCR Phase)',
      'status': 'Under Survey',
      'statusColor': AppTheme.amberWarning,
      'statusBg': Color(0xFFFFFBEB),
      'impact': 'Regional Catalyst (NCR Intra-connectivity)',
      'category': 'High-Speed Rail Corridor',
      'icon': LucideIcons.zap,
    },
  ];

  final List<Map<String, dynamic>> _infraImpactPillars = [
    {
      'title': 'Airport Connectivity',
      'impactTag': 'High Impact',
      'impactColor': AppTheme.emeraldSuccess,
      'icon': LucideIcons.planeTakeoff,
      'desc': 'Jewar & IGI connectivity driving exponential commercial demand and international institutional capital inflow across Noida & Yamuna Expressway.',
    },
    {
      'title': 'Metro Expansion',
      'impactTag': 'High Impact',
      'impactColor': AppTheme.primaryViolet,
      'icon': LucideIcons.navigation,
      'desc': 'Aqua Line & Yellow Line expansions unlocking prime residential corridors and daily commute ease across Greater Noida West and Old Gurgaon.',
    },
    {
      'title': 'Commercial Development',
      'impactTag': 'Medium–High Impact',
      'impactColor': AppTheme.indigoPrimary,
      'icon': LucideIcons.building2,
      'desc': 'Grade-A IT parks, BFSI campuses, and data centers along Expressway and Cyber City generating resilient rental yields and capital appreciation.',
    },
  ];

  void _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = now.minute.toString().padLeft(2, '0');
    setState(() {
      _lastUpdated = 'Today, $hour:$minuteStr $period';
      _isRefreshing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Market Signals & Growth Metrics Refreshed!',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: AppTheme.emeraldSuccess,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSectors {
    List<Map<String, dynamic>> list = _growthSectors;
    if (_selectedRegionFilter != 'All') {
      list = list.where((s) => s['region'] == _selectedRegionFilter).toList();
    }
    if (!_showAllSectors && list.length > 4) {
      return list.take(4).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;
    final isMobile = screenWidth < 640;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
          vertical: 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Polished Header
                _buildHeader(isMobile),
                const SizedBox(height: 20),

                // 2. Market Overview Summary (4 KPI Cards)
                _buildKpiOverviewGrid(isDesktop, isTablet, isMobile),
                const SizedBox(height: 24),

                // 3. Top NCR Growth Sectors Section
                _buildGrowthSectorsSection(isDesktop, isTablet, isMobile),
                const SizedBox(height: 24),

                // 4. Infrastructure Catalyst Timeline
                _buildTimelineSection(isDesktop, isMobile),
                const SizedBox(height: 24),

                // 5. AI Market Intelligence Insight Card
                _buildAiMarketInsightCard(isMobile),
                const SizedBox(height: 24),

                // 6. Infrastructure Impact Pillars (3 Cards)
                _buildInfraImpactPillars(isDesktop, isTablet, isMobile),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. POLISHED DASHBOARD HEADER
  // ==========================================
  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildDesktopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Icon + Title + Subtitle
        Expanded(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryViolet.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(LucideIcons.lineChart, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NCR Market Signals Hub',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time price velocity & infrastructure catalysts across National Capital Region',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Right: Status Badge + Last Updated + Refresh Button
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live Market Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live Market',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Last Updated Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Updated $_lastUpdated',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Refresh Button
            _buildRefreshButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(LucideIcons.lineChart, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NCR Market Signals Hub',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Real-time price velocity & infrastructure catalysts',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            _buildRefreshButton(),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Live Market',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Updated $_lastUpdated',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isRefreshing ? null : _handleRefresh,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isRefreshing ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: _isRefreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryViolet),
                )
              : const Icon(LucideIcons.refreshCw, size: 18, color: Color(0xFF475569)),
        ),
      ),
    );
  }

  // ==========================================
  // 2. MARKET OVERVIEW SUMMARY (4 KPI CARDS)
  // ==========================================
  Widget _buildKpiOverviewGrid(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) {
      return Row(
        children: _kpiStats
            .map((kpi) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildKpiCard(kpi),
                  ),
                ))
            .toList(),
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCard(_kpiStats[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard(_kpiStats[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKpiCard(_kpiStats[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildKpiCard(_kpiStats[3])),
            ],
          ),
        ],
      );
    }

    // Mobile: 1-column stack
    return Column(
      children: _kpiStats
          .map((kpi) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildKpiCard(kpi),
              ))
          .toList(),
    );
  }

  Widget _buildKpiCard(Map<String, dynamic> kpi, {bool isCompact = false}) {
    final color = kpi['color'] as Color;
    final bg = kpi['bg'] as Color;
    final icon = kpi['icon'] as IconData;

    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Period badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isCompact ? 16 : 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    kpi['period'],
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 14),

          // Big Metric Value
          Text(
            kpi['value'],
            style: GoogleFonts.poppins(
              fontSize: isCompact ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Label
          Text(
            kpi['title'],
            style: GoogleFonts.inter(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Trend Indicator
          Row(
            children: [
              Icon(LucideIcons.arrowUpRight, color: color, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  kpi['trend'],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. TOP NCR GROWTH SECTORS (ANALYTICS CARDS)
  // ==========================================
  Widget _buildGrowthSectorsSection(bool isDesktop, bool isTablet, bool isMobile) {
    final sectors = _filteredSectors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header + View All Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Top NCR Growth Sectors',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_growthSectors.length} Tracked',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryViolet,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'High-potential micro-markets based on price velocity and infrastructure activity',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // View All / Show Less Toggle
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _showAllSectors = !_showAllSectors);
                },
                icon: Icon(
                  _showAllSectors ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 14,
                  color: AppTheme.primaryViolet,
                ),
                label: Text(
                  _showAllSectors ? 'Show Top 4' : 'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryViolet,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDDD6FE)),
                  backgroundColor: const Color(0xFFFAF5FF),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Micro-Market Region Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Noida', 'Gurgaon', 'Expressways'].map((region) {
                final isSelected = _selectedRegionFilter == region;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(region == 'All' ? 'All NCR Corridors' : region),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedRegionFilter = region);
                    },
                    selectedColor: AppTheme.primaryViolet,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    backgroundColor: const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // 2-Column Grid (Desktop/Tablet) or 1-Column (Mobile)
          if (isMobile)
            Column(
              children: sectors.map((s) => _buildSectorAnalyticsCard(s)).toList(),
            )
          else
            LayoutBuilder(builder: (ctx, constraints) {
              final cardWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: sectors.map((s) {
                  return SizedBox(
                    width: cardWidth,
                    child: _buildSectorAnalyticsCard(s),
                  );
                }).toList(),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSectorAnalyticsCard(Map<String, dynamic> sector) {
    final Color accentColor = sector['accentColor'] as Color;
    final double growthRate = (sector['growthRate'] as num).toDouble();
    final String growthPercent = (growthRate * 100).toInt().toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4.5,
              color: accentColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name + Growth Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sector['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sector['corridor'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.trendingUp, size: 12, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                sector['yoyGrowth'],
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Row 2: 3 Analytics KPIs (Price Range, Infra Score, Demand)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          // Price Range
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price Range',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sector['priceRange'],
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 8),

                          // Infrastructure Score
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Infra Score',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.award, size: 11, color: AppTheme.primaryViolet),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        sector['infraScore'],
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryViolet,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                          const SizedBox(width: 8),

                          // Demand
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Demand',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sector['demand'],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Row 3: Growth Momentum Progress Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Growth Momentum',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        Text(
                          '$growthPercent%',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: growthRate,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. INFRASTRUCTURE CATALYST TIMELINE
  // ==========================================
  Widget _buildTimelineSection(bool isDesktop, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.calendar, color: AppTheme.primaryViolet, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Infrastructure Catalyst Timeline',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Upcoming infrastructure developments influencing NCR property demand',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 20),

          // Vertical Timeline Items with Connecting Line
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _timelineItems.length,
            itemBuilder: (context, index) {
              final item = _timelineItems[index];
              final isLast = index == _timelineItems.length - 1;
              return _buildTimelineRow(item, isLast, isMobile);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(Map<String, dynamic> item, bool isLast, bool isMobile) {
    final statusColor = item['statusColor'] as Color;
    final statusBg = item['statusBg'] as Color;
    final icon = item['icon'] as IconData;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Timeline Dot & Connecting Vertical Line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: statusBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Center(
                  child: Icon(icon, size: 12, color: statusColor),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Right: Content Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Quarter Badge + Status Badge
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['quarter'],
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            item['status'],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      item['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Impact Label
                    Row(
                      children: [
                        const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['impact'],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. AI MARKET INTELLIGENCE INSIGHT CARD
  // ==========================================
  Widget _buildAiMarketInsightCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1.2),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C7C3AED),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AI Badge + Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'AI Market Insight',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PropZen AI v2.4',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Predictive intelligence synthesis for NCR micro-markets',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Insight Quote
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '"Yamuna Expressway is currently showing the strongest growth momentum in the NCR (+28.4% YoY), supported by airport infrastructure and improving connectivity."',
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3 Metric Pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInsightTag('Growth Outlook', 'Very Positive', AppTheme.emeraldSuccess, const Color(0xFFECFDF5)),
              _buildInsightTag('Recommended For', 'Long-term Investors', AppTheme.primaryViolet, const Color(0xFFF5F3FF)),
              _buildInsightTag('Risk Level', 'Moderate', AppTheme.amberWarning, const Color(0xFFFFFBEB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTag(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 6. INFRASTRUCTURE IMPACT PILLARS (3 CARDS)
  // ==========================================
  Widget _buildInfraImpactPillars(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) {
      return Row(
        children: _infraImpactPillars
            .map((pillar) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildInfraPillarCard(pillar),
                  ),
                ))
            .toList(),
      );
    }

    return Column(
      children: _infraImpactPillars
          .map((pillar) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInfraPillarCard(pillar),
              ))
          .toList(),
    );
  }

  Widget _buildInfraPillarCard(Map<String, dynamic> pillar) {
    final color = pillar['impactColor'] as Color;
    final icon = pillar['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Icon + Impact Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  pillar['impactTag'],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            pillar['title'],
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            pillar['desc'],
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
