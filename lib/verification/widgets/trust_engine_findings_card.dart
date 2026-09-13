import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';

class TrustEngineFindingsCard extends StatefulWidget {
  final List<AiFinding> findings;

  const TrustEngineFindingsCard({super.key, required this.findings});

  @override
  State<TrustEngineFindingsCard> createState() => _TrustEngineFindingsCardState();
}

class _TrustEngineFindingsCardState extends State<TrustEngineFindingsCard> {
  int _activeFilter = 0; // 0: All, 1: Verified, 2: Warnings, 3: Requires Review

  @override
  Widget build(BuildContext context) {
    final verifiedCount = widget.findings.where((f) => f.severity == FindingSeverity.verified).length;
    final warningCount = widget.findings.where((f) => f.severity == FindingSeverity.warning).length;
    final reviewCount = widget.findings.where((f) => f.severity == FindingSeverity.review).length;

    List<AiFinding> filtered = widget.findings;
    if (_activeFilter == 1) {
      filtered = widget.findings.where((f) => f.severity == FindingSeverity.verified).toList();
    } else if (_activeFilter == 2) {
      filtered = widget.findings.where((f) => f.severity == FindingSeverity.warning).toList();
    } else if (_activeFilter == 3) {
      filtered = widget.findings.where((f) => f.severity == FindingSeverity.review).toList();
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 3)),
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
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Verification Findings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              // Filter Chips
              Wrap(
                spacing: 8,
                children: [
                  _filterChip(0, 'All (${widget.findings.length})'),
                  _filterChip(1, '✓ Verified ($verifiedCount)'),
                  _filterChip(2, '⚠ Warnings ($warningCount)'),
                  _filterChip(3, '! Review ($reviewCount)'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Actionable observations synthesized across deed clauses, authority clearances, and encumbrance certificates.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          if (filtered.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.checkCircle2, size: 32, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No findings available in this category.',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildFindingCard(filtered[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final isSelected = _activeFilter == index;
    return InkWell(
      onTap: () => setState(() => _activeFilter = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildFindingCard(AiFinding finding) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  Icon(finding.severity.icon, size: 16, color: finding.severity.color),
                  const SizedBox(width: 8),
                  Text(
                    finding.title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: finding.severity.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  finding.severity.label,
                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: finding.severity.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            finding.description,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.arrowRightCircle, size: 14, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Action: ${finding.recommendedAction}',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF4C1D95)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Source: ${finding.source}',
                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
