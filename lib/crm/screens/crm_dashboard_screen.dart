import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../models/crm_dashboard_metrics.dart';
import '../models/crm_follow_up.dart';
import '../models/crm_analytics.dart';
import '../services/crm_service.dart';
import '../services/crm_follow_up_service.dart';
import '../widgets/crm_stat_card.dart';
import '../widgets/crm_sidebar.dart';
import '../widgets/crm_pipeline_funnel.dart';
import '../widgets/crm_lead_sources_card.dart';
import '../widgets/crm_dashboard_skeletons.dart';

class CrmDashboardScreen extends StatefulWidget {
  final ValueChanged<CrmTab>? onNavigateTab;

  const CrmDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<CrmDashboardScreen> createState() => _CrmDashboardScreenState();
}

class _CrmDashboardScreenState extends State<CrmDashboardScreen> {
  final CrmService _crmService = CrmService.instance;
  final CrmFollowUpService _followUpService = CrmFollowUpService.instance;

  CrmDashboardMetrics? _metrics;
  CrmAnalyticsData? _analytics;
  List<CrmFollowUp> _todayFollowUps = [];
  List<CrmFollowUp> _overdueFollowUps = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedRange = '30 Days';
  final List<String> _ranges = [
    'Today',
    '7 Days',
    '30 Days',
    '90 Days',
    'This Year',
    'Custom Range'
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metricsFuture = _crmService.getDashboardMetrics();
      final followUpsFuture = _followUpService.getFollowUps();
      final analyticsFuture = _crmService.getAnalytics();

      final results =
          await Future.wait([metricsFuture, followUpsFuture, analyticsFuture]);
      final metrics = results[0] as CrmDashboardMetrics;
      final followUps = results[1] as List<CrmFollowUp>;
      final analytics = results[2] as CrmAnalyticsData;

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _analytics = analytics;
          _todayFollowUps = followUps
              .where((f) => f.isToday && f.status == FollowUpStatus.pending)
              .toList();
          _overdueFollowUps = followUps.where((f) => f.isOverdue).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Technical logs for developers only - never leak stack traces or URLs to user
      debugPrint('CRM Dashboard API Exception: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to load CRM data. Please check your connection and try again.';
        });
      }
    }
  }

  Future<void> _handleRangeChanged(String? val) async {
    if (val == null) return;
    if (val == 'Custom Range') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 2),
        lastDate: now,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF7C3AED),
                onPrimary: Colors.white,
                onSurface: Color(0xFF0F172A),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _selectedRange = 'Custom Range');
        _loadDashboardData();
      }
    } else {
      setState(() => _selectedRange = val);
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics ?? CrmDashboardMetrics.zero;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF7C3AED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header with Title & Date Range Selector
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // 2. Overdue Banner (if any)
                  if (_overdueFollowUps.isNotEmpty) ...[
                    _buildOverdueBanner(),
                    const SizedBox(height: 20),
                  ],

                  // 3. Error Banner (Non-destructive, sanitized)
                  if (_errorMessage != null && !_isLoading) ...[
                    _buildErrorBanner(),
                    const SizedBox(height: 20),
                  ],

                  // 4. Primary KPI Grid (8 Cards)
                  _buildKpiGrid(m),
                  const SizedBox(height: 24),

                  // 5. Quick Pipeline Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // 6. Split Section: Today's Follow-ups & Pipeline Health
                  _buildFollowUpsAndHealthSection(m),
                  const SizedBox(height: 24),

                  // 7. Pipeline Funnel (End-to-End Stages)
                  CrmPipelineFunnel(
                    metrics: m,
                    analytics: _analytics,
                    isLoading: _isLoading,
                    onTap: () => widget.onNavigateTab?.call(CrmTab.leads),
                  ),
                  const SizedBox(height: 24),

                  // 8. Lead Source Analytics (Live Acquisition Channels)
                  CrmLeadSourcesCard(
                    analytics: _analytics,
                    totalLeads: m.totalLeads,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. PAGE HEADER
  // =========================================================================
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'CRM Pipeline Overview',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time conversion performance from live database records.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final filterDropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRange,
              icon: const Icon(LucideIcons.chevronDown,
                  size: 15, color: Color(0xFF64748B)),
              items: _ranges.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.calendar,
                          size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Text(
                        r,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _handleRangeChanged,
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              filterDropdown,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            filterDropdown,
          ],
        );
      },
    );
  }

  // =========================================================================
  // 2. OVERDUE ALERT BANNER
  // =========================================================================
  Widget _buildOverdueBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertCircle,
                color: Colors.white, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_overdueFollowUps.length} Overdue Follow-up Actions',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  'Follow-ups scheduled in the past require immediate attention to prevent lead stagnation.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => widget.onNavigateTab?.call(CrmTab.followUps),
            child: Text(
              'Review Now',
              style:
                  GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. CLEAN ERROR / CONNECTION BANNER
  // =========================================================================
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertTriangle,
                color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load CRM data',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Please check your connection and try again.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.refreshCw, size: 13),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. RESPONSIVE KPI GRID (8 CARDS)
  // =========================================================================
  Widget _buildKpiGrid(CrmDashboardMetrics m) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        }

        if (_isLoading && _metrics == null) {
          return CrmKpiGridSkeleton(crossAxisCount: crossAxisCount);
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 138,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return CrmStatCard(
                  title: 'Total Active Leads',
                  value: '${m.totalLeads}',
                  icon: LucideIcons.users,
                  accentColor: const Color(0xFF3B82F6),
                  subtitle: 'Across all pipeline stages',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.leads),
                );
              case 1:
                return CrmStatCard(
                  title: 'New Unassigned Leads',
                  value: '${m.newLeads}',
                  icon: LucideIcons.userPlus,
                  accentColor: const Color(0xFF10B981),
                  subtitle: 'Requiring initial contact',
                  trend: m.newLeads > 0 ? 'Needs Attention' : 'All Clear',
                  isPositiveTrend: m.newLeads == 0,
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.leads),
                );
              case 2:
                return CrmStatCard(
                  title: 'Follow-ups Due',
                  value: '${m.followUpsDue}',
                  icon: LucideIcons.calendarClock,
                  accentColor: const Color(0xFFF59E0B),
                  subtitle: 'Pending follow-up actions',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.followUps),
                );
              case 3:
                return CrmStatCard(
                  title: 'Site Visits Booked',
                  value: '${m.siteVisits}',
                  icon: LucideIcons.compass,
                  accentColor: const Color(0xFF8B5CF6),
                  subtitle: 'Physical visits scheduled',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.properties),
                );
              case 4:
                return CrmStatCard(
                  title: 'Contacted Leads',
                  value: '${m.contactedLeads}',
                  icon: LucideIcons.phoneCall,
                  accentColor: const Color(0xFF0284C7),
                  subtitle: 'Initial dialogue completed',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.leads),
                );
              case 5:
                return CrmStatCard(
                  title: 'Qualified Prospects',
                  value: '${m.qualifiedLeads}',
                  icon: LucideIcons.badgeCheck,
                  accentColor: const Color(0xFF059669),
                  subtitle: 'Budget & location verified',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.leads),
                );
              case 6:
                return CrmStatCard(
                  title: 'Converted Deals',
                  value: '${m.convertedLeads}',
                  icon: LucideIcons.checkCircle2,
                  accentColor: const Color(0xFF16A34A),
                  subtitle: 'Successfully closed sales',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.leads),
                );
              case 7:
              default:
                return CrmStatCard(
                  title: 'Conversion Rate',
                  value: '${m.conversionRate.toStringAsFixed(1)}%',
                  icon: LucideIcons.trendingUp,
                  accentColor: const Color(0xFF7C3AED),
                  subtitle: 'Leads to closed deals',
                  isLoading: _isLoading,
                  onTap: () => widget.onNavigateTab?.call(CrmTab.analytics),
                );
            }
          },
        );
      },
    );
  }

  // =========================================================================
  // 5. QUICK PIPELINE ACTIONS
  // =========================================================================
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.zap, size: 16, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(
                'Quick Pipeline Actions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // Primary Action: Add Lead
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.userPlus, size: 15),
                label: const Text('Add Lead'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: () => widget.onNavigateTab?.call(CrmTab.leads),
              ),
              // Secondary Action: Today's Follow-ups
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.calendarClock,
                    size: 15, color: Color(0xFF475569)),
                label: const Text("Today's Follow-ups"),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => widget.onNavigateTab?.call(CrmTab.followUps),
              ),
              // Secondary Action: Create Campaign
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.megaphone,
                    size: 15, color: Color(0xFF475569)),
                label: const Text('Create Campaign'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => widget.onNavigateTab?.call(CrmTab.campaigns),
              ),
              // Secondary Action: View Analytics
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.barChart2,
                    size: 15, color: Color(0xFF475569)),
                label: const Text('View Analytics'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E293B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => widget.onNavigateTab?.call(CrmTab.analytics),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. SPLIT SECTION: TODAY'S FOLLOW-UPS & PIPELINE HEALTH
  // =========================================================================
  Widget _buildFollowUpsAndHealthSection(CrmDashboardMetrics m) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 960;

        final followUpsCard = _buildTodayFollowUpsCard();
        final healthCard = _buildPipelineHealthCard(m);

        if (isNarrow) {
          return Column(
            children: [
              followUpsCard,
              const SizedBox(height: 20),
              healthCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: followUpsCard),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: healthCard),
          ],
        );
      },
    );
  }

  // Today's Follow-ups Card
  Widget _buildTodayFollowUpsCard() {
    if (_isLoading && _metrics == null) {
      return const CrmCardSkeleton(height: 330);
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.clock,
                        size: 16, color: Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Today's Scheduled Follow-ups",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigateTab?.call(CrmTab.followUps),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7C3AED),
                  textStyle: GoogleFonts.inter(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All'),
                    SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayFollowUps.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.calendarCheck,
                        size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No follow-ups scheduled for today.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All scheduled client interactions for today are completed or none are due.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._todayFollowUps.take(5).map((f) {
              final timeStr =
                  '${f.scheduledAt.hour.toString().padLeft(2, '0')}:${f.scheduledAt.minute.toString().padLeft(2, '0')}';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.phone,
                          size: 15, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                f.leadName ?? 'Lead Follow-up',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  timeStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            f.notes?.isNotEmpty == true
                                ? f.notes!
                                : 'Channel: ${f.channel} • Assigned: ${f.assignedTo ?? 'Agent'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.check,
                          size: 12, color: Colors.white),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        textStyle: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        await _followUpService.completeFollowUp(f.id);
                        _loadDashboardData();
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // Pipeline Health Card
  Widget _buildPipelineHealthCard(CrmDashboardMetrics m) {
    if (_isLoading && _metrics == null) {
      return const CrmCardSkeleton(height: 330);
    }

    final total = m.totalLeads;

    // Derived from API values
    final qualificationRatio =
        total > 0 ? ((m.contactedLeads + m.qualifiedLeads) / total) : 0.0;
    final contactedRatio = total > 0 ? (m.contactedLeads / total) : 0.0;
    final qualifiedRatio = total > 0 ? (m.qualifiedLeads / total) : 0.0;
    final siteVisitRatio = total > 0 ? (m.siteVisits / total) : 0.0;
    final negotiationCount = _analytics?.leadsByStage['NEGOTIATION'] ??
        (_analytics?.leadsByStage['negotiation'] ?? 0);
    final negotiationRatio = total > 0 ? (negotiationCount / total) : 0.0;
    final convertedRatio = total > 0 ? (m.convertedLeads / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.activity,
                    size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              Text(
                'Pipeline Health',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildHealthBar(
              'Lead Qualification', qualificationRatio, const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          _buildHealthBar('Contacted', contactedRatio, const Color(0xFF6366F1)),
          const SizedBox(height: 12),
          _buildHealthBar('Qualified', qualifiedRatio, const Color(0xFF8B5CF6)),
          const SizedBox(height: 12),
          _buildHealthBar('Site Visit', siteVisitRatio, const Color(0xFF0284C7)),
          const SizedBox(height: 12),
          _buildHealthBar(
              'Negotiation', negotiationRatio, const Color(0xFFEC4899)),
          const SizedBox(height: 12),
          _buildHealthBar('Converted', convertedRatio, const Color(0xFF10B981)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles,
                    size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Tip: Contacting new leads within 15 minutes increases visit booking rate by 3.2x.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF4C1D95),
                      fontWeight: FontWeight.w500,
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

  Widget _buildHealthBar(String label, double ratio, Color color) {
    final percentStr = (ratio * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
            Text(
              '$percentStr%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
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
    );
  }
}
