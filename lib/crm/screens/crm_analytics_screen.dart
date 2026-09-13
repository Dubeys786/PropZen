import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../models/crm_analytics.dart';
import '../services/crm_service.dart';

class CrmAnalyticsScreen extends StatefulWidget {
  const CrmAnalyticsScreen({super.key});

  @override
  State<CrmAnalyticsScreen> createState() => _CrmAnalyticsScreenState();
}

class _CrmAnalyticsScreenState extends State<CrmAnalyticsScreen> {
  final CrmService _service = CrmService.instance;
  CrmAnalyticsData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.getAnalytics();
      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Padding(
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
                      'CRM Pipeline Analytics & Insights',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Aggregated conversion funnel velocity, channel attribution, and operational performance.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  onPressed: _loadAnalytics,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _errorMessage != null
                      ? Center(child: Text('Error: $_errorMessage'))
                      : _buildAnalyticsDashboard(_data ?? const CrmAnalyticsData()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsDashboard(CrmAnalyticsData d) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conversion Rate Highlights
          Row(
            children: [
              Expanded(child: _rateCard('Overall Conversion Rate', '${d.overallConversionRate.toStringAsFixed(1)}%', const Color(0xFF10B981), LucideIcons.trendingUp)),
              const SizedBox(width: 16),
              Expanded(child: _rateCard('Follow-up Completion Rate', '${d.followUpCompletionRate.toStringAsFixed(1)}%', const Color(0xFF3B82F6), LucideIcons.calendarCheck)),
              const SizedBox(width: 16),
              Expanded(child: _rateCard('Task Execution Rate', '${d.taskCompletionRate.toStringAsFixed(1)}%', const Color(0xFF7C3AED), LucideIcons.checkSquare)),
            ],
          ),
          const SizedBox(height: 24),

          // Total Volume Aggregates
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cumulative Platform Volumes', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _volumeMetric('Total Leads', '${d.totalLeads}', const Color(0xFF3B82F6)),
                    _volumeMetric('Enquiries', '${d.totalEnquiries}', const Color(0xFF10B981)),
                    _volumeMetric('Follow-ups', '${d.totalFollowUps}', const Color(0xFFF59E0B)),
                    _volumeMetric('Tasks', '${d.totalTasks}', const Color(0xFF8B5CF6)),
                    _volumeMetric('Messages', '${d.totalCommunications}', const Color(0xFFEC4899)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Breakdown Grids: Stages & Sources
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;
              final stageCard = _buildBreakdownCard('Leads by Funnel Stage', d.leadsByStage, d.totalLeads, const Color(0xFF3B82F6));
              final sourceCard = _buildBreakdownCard('Attribution by Origin Source', d.leadsBySource, d.totalLeads, const Color(0xFF10B981));

              if (isNarrow) {
                return Column(children: [stageCard, const SizedBox(height: 16), sourceCard]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: stageCard),
                  const SizedBox(width: 16),
                  Expanded(child: sourceCard),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _rateCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _volumeMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildBreakdownCard(String title, Map<String, int> map, int total, Color barColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (map.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: Text('No data recorded', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
            )
          else
            ...map.entries.map((e) {
              final pct = total > 0 ? (e.value / total) : 0.0;
              final cleanKey = e.key.replaceAll('_', ' ');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cleanKey, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                        Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
