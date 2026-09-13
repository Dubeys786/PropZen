import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';

class TrustEngineRiskDashboard extends StatelessWidget {
  final RiskLevel overallRisk;
  final double? numericalScore;
  final List<RiskCategory> categories;

  const TrustEngineRiskDashboard({
    super.key,
    required this.overallRisk,
    this.numericalScore,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = numericalScore != null;

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
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.shieldAlert, size: 16, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Multi-Vector Risk Analysis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '8 Vectors Evaluated',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Holistic algorithmic scoring spanning title continuity, physical bounds, judicial databases, and registry encumbrance.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Top Overall Risk Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: overallRisk.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: overallRisk.color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: overallRisk.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Risk Classification: ${overallRisk.label}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: overallRisk.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Risk index: ${hasScore ? '${numericalScore!.toStringAsFixed(0)} / 100 (Clean Range)' : 'Not Available'}. All verified vectors indicate a sound transaction baseline.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: overallRisk.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    hasScore ? numericalScore!.toStringAsFixed(0) : 'N/A',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: overallRisk.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 8 Categories Breakdown Grid
          if (categories.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              child: Text(
                'Risk vectors will populate automatically following verification processing.',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
              ),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                if (isWide) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 130,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryCard(categories[index]);
                    },
                  );
                }

                return Column(
                  children: categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCategoryCard(cat),
                  )).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(RiskCategory cat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  cat.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: cat.riskLevel.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: cat.riskLevel.color.withOpacity(0.3)),
                ),
                child: Text(
                  cat.riskLevel.label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cat.riskLevel.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            cat.explanation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569), height: 1.3),
          ),
          if (cat.evidence != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.database, size: 11, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    cat.evidence!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
