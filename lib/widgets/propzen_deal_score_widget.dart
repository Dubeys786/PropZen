import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';

class PropZenDealScoreWidget extends StatelessWidget {
  final Property? property;
  final int propertyScore;
  final int priceScore;
  final int documentsScore;
  final int locationScore;
  final int dealQualityScore;

  const PropZenDealScoreWidget({
    super.key,
    this.property,
    this.propertyScore = 89,
    this.priceScore = 82,
    this.documentsScore = 94,
    this.locationScore = 91,
    this.dealQualityScore = 87,
  });

  int get overallScore => ((propertyScore * 0.25) +
          (priceScore * 0.25) +
          (documentsScore * 0.20) +
          (locationScore * 0.15) +
          (dealQualityScore * 0.15))
      .round();

  String get recommendation {
    if (overallScore >= 80) return 'PROCEED WITH CONFIDENCE';
    if (overallScore >= 60) return 'REVIEW BEFORE PROCEEDING';
    return 'HIGH RISK — EXERCISE CAUTION';
  }

  Color get recommendationColor {
    if (overallScore >= 80) return const Color(0xFF10B981);
    if (overallScore >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData get recommendationIcon {
    if (overallScore >= 80) return LucideIcons.checkCircle;
    if (overallScore >= 60) return LucideIcons.alertTriangle;
    return LucideIcons.alertOctagon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.award, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PropZen Deal Score™',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Institutional 5-Pillar Investment Rating',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              // Overall circular score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$overallScore',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                    ),
                    Text(
                      '/100',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 18),

          // 5-Pillar Score Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPillarCard('PROPERTY', propertyScore, LucideIcons.home, isNarrow),
                  _buildPillarCard('PRICE', priceScore, LucideIcons.tag, isNarrow),
                  _buildPillarCard('DOCUMENTS', documentsScore, LucideIcons.fileCheck, isNarrow),
                  _buildPillarCard('LOCATION', locationScore, LucideIcons.mapPin, isNarrow),
                  _buildPillarCard('DEAL QUALITY', dealQualityScore, LucideIcons.shieldCheck, isNarrow),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // Recommendation Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: recommendationColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: recommendationColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(recommendationIcon, color: recommendationColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: recommendationColor),
                      ),
                      Text(
                        overallScore >= 80
                            ? 'High valuation consistency, verified title records, and prime location fundamentals.'
                            : 'Certain document verification items or price variances require advisor clarification.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Informational Legal Disclaimer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'PropZen Deal Score is an AI-powered informational assessment and should not be treated as legal, financial, valuation, or investment advice.',
                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, height: 1.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard(String title, int score, IconData icon, bool isNarrow) {
    return Container(
      width: isNarrow ? double.infinity : 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 14, color: AppTheme.primaryViolet),
              Text(
                '$score/100',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100.0,
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 85 ? const Color(0xFF10B981) : (score >= 70 ? AppTheme.primaryViolet : const Color(0xFFF59E0B)),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
