import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/crm_analytics.dart';

class CrmLeadSourcesCard extends StatelessWidget {
  final CrmAnalyticsData? analytics;
  final int totalLeads;
  final bool isLoading;

  const CrmLeadSourcesCard({
    super.key,
    required this.analytics,
    required this.totalLeads,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final sourcesMap = analytics?.leadsBySource ?? {};
    final hasSources = sourcesMap.isNotEmpty;

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
                      color: const Color(0xFF0284C7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.pieChart,
                        size: 16, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lead Source Analytics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (hasSources)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${sourcesMap.length} Active Channels',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Channel distribution and attribution based on live database records.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          if (!hasSources) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.inbox,
                        size: 32, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No lead source data available yet',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Channel metrics will automatically appear as leads are ingested from website, WhatsApp, and portals.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 700;
                final sortedEntries = sourcesMap.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                if (isWide) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 76,
                    ),
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final item = sortedEntries[index];
                      return _buildSourceRow(item.key, item.value, totalLeads);
                    },
                  );
                }

                return Column(
                  children: sortedEntries.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child:
                          _buildSourceRow(item.key, item.value, totalLeads),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceRow(String rawKey, int count, int total) {
    final meta = _getSourceMeta(rawKey);
    final ratio = total > 0 ? (count / total) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(meta.icon, size: 14, color: meta.color),
                  const SizedBox(width: 8),
                  Text(
                    meta.label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '$count leads',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$percent%',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: meta.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(meta.color),
            ),
          ),
        ],
      ),
    );
  }

  _SourceMeta _getSourceMeta(String key) {
    final clean = key.toUpperCase().trim();
    switch (clean) {
      case 'WEBSITE':
        return _SourceMeta(
            'Website', LucideIcons.globe, const Color(0xFF3B82F6));
      case 'PROPERTY_ENQUIRY':
      case 'PROPERTY_SEARCH':
        return _SourceMeta('Property Search', LucideIcons.search,
            const Color(0xFF6366F1));
      case 'DEALER':
      case 'DEALER_REFERRAL':
        return _SourceMeta(
            'Dealer Referral', LucideIcons.briefcase, const Color(0xFF8B5CF6));
      case 'SERVICE_REQUEST':
      case 'SERVICE_PARTNER':
        return _SourceMeta('Service Request', LucideIcons.wrench,
            const Color(0xFFEC4899));
      case 'WHATSAPP':
        return _SourceMeta(
            'WhatsApp', LucideIcons.messageCircle, const Color(0xFF10B981));
      case 'REFERRAL':
        return _SourceMeta(
            'Referral', LucideIcons.userCheck, const Color(0xFF059669));
      case 'CAMPAIGN':
        return _SourceMeta(
            'Marketing Campaign', LucideIcons.megaphone, const Color(0xFFF59E0B));
      case 'PHONE':
      case 'DIRECT':
        return _SourceMeta(
            'Direct Call', LucideIcons.phone, const Color(0xFF0284C7));
      default:
        return _SourceMeta(
            key, LucideIcons.helpCircle, const Color(0xFF64748B));
    }
  }
}

class _SourceMeta {
  final String label;
  final IconData icon;
  final Color color;

  _SourceMeta(this.label, this.icon, this.color);
}
