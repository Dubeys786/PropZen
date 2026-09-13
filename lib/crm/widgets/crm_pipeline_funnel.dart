import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/crm_dashboard_metrics.dart';
import '../models/crm_analytics.dart';

class CrmPipelineFunnel extends StatelessWidget {
  final CrmDashboardMetrics metrics;
  final CrmAnalyticsData? analytics;
  final bool isLoading;
  final VoidCallback? onTap;

  const CrmPipelineFunnel({
    super.key,
    required this.metrics,
    this.analytics,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = metrics.totalLeads;

    // Derive stage counts from API metrics & analytics
    final newCount = metrics.newLeads;
    final contactedCount = metrics.contactedLeads;
    final qualifiedCount = metrics.qualifiedLeads;
    final siteVisitCount = metrics.siteVisits;
    final negotiationCount = analytics?.leadsByStage['NEGOTIATION'] ??
        (analytics?.leadsByStage['negotiation'] ?? 0);
    final convertedCount = metrics.convertedLeads;

    final stages = [
      _FunnelStage(
        name: 'New Lead',
        count: newCount,
        percent: total > 0 ? (newCount / total * 100) : 0.0,
        status: 'Inbound',
        icon: LucideIcons.sparkles,
        accentColor: const Color(0xFF3B82F6),
      ),
      _FunnelStage(
        name: 'Contacted',
        count: contactedCount,
        percent: total > 0 ? (contactedCount / total * 100) : 0.0,
        status: 'Engaged',
        icon: LucideIcons.phoneCall,
        accentColor: const Color(0xFF6366F1),
      ),
      _FunnelStage(
        name: 'Qualified',
        count: qualifiedCount,
        percent: total > 0 ? (qualifiedCount / total * 100) : 0.0,
        status: 'Verified',
        icon: LucideIcons.badgeCheck,
        accentColor: const Color(0xFF8B5CF6),
      ),
      _FunnelStage(
        name: 'Site Visit',
        count: siteVisitCount,
        percent: total > 0 ? (siteVisitCount / total * 100) : 0.0,
        status: 'Scheduled',
        icon: LucideIcons.compass,
        accentColor: const Color(0xFF0284C7),
      ),
      _FunnelStage(
        name: 'Negotiation',
        count: negotiationCount,
        percent: total > 0 ? (negotiationCount / total * 100) : 0.0,
        status: 'In Closing',
        icon: LucideIcons.scale,
        accentColor: const Color(0xFFEC4899),
      ),
      _FunnelStage(
        name: 'Converted',
        count: convertedCount,
        percent: metrics.conversionRate > 0
            ? metrics.conversionRate
            : (total > 0 ? (convertedCount / total * 100) : 0.0),
        status: 'Won Deals',
        icon: LucideIcons.checkCircle2,
        accentColor: const Color(0xFF10B981),
      ),
    ];

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.gitFork,
                            size: 16, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pipeline Funnel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'End-to-end stage velocity and conversion distribution.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (onTap != null)
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Leads'),
                      SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 14),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Responsive Layout: Horizontal on desktop/tablet, Vertical on mobile
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 860;

              if (isNarrow) {
                return Column(
                  children: stages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stage = entry.value;
                    final isLast = index == stages.length - 1;

                    return Column(
                      children: [
                        _buildMobileStageItem(stage),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Icon(
                              LucideIcons.arrowDown,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                );
              }

              // Desktop Horizontal Funnel
              return Row(
                children: stages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stage = entry.value;
                  final isLast = index == stages.length - 1;

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildDesktopStageCard(stage)),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: Colors.grey.shade300,
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

  Widget _buildDesktopStageCard(_FunnelStage stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  stage.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              Icon(stage.icon, size: 14, color: stage.accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${stage.count}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (stage.percent / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(stage.accentColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage.status,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${stage.percent.toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: stage.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStageItem(_FunnelStage stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: stage.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(stage.icon, size: 16, color: stage.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stage.status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${stage.count}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${stage.percent.toStringAsFixed(0)}% of total',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: stage.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FunnelStage {
  final String name;
  final int count;
  final double percent;
  final String status;
  final IconData icon;
  final Color accentColor;

  _FunnelStage({
    required this.name,
    required this.count,
    required this.percent,
    required this.status,
    required this.icon,
    required this.accentColor,
  });
}
