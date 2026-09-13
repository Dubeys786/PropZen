import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_subscription_model.dart';
import '../services/nri_subscription_service.dart';
import '../theme/app_theme.dart';

/// NRI Property Confidence Score & 6-Pillar Risk Evaluation Card
class NriConfidenceScoreCard extends StatelessWidget {
  final Property property;

  const NriConfidenceScoreCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final score = NriSubscriptionService.instance.getConfidenceScoreForProperty(property.id);

    Color recColor;
    Color recBg;
    if (score.overallScore >= 85) {
      recColor = const Color(0xFF16A34A);
      recBg = const Color(0xFFDCFCE7);
    } else if (score.overallScore >= 70) {
      recColor = const Color(0xFFD97706);
      recBg = const Color(0xFFFEF3C7);
    } else {
      recColor = const Color(0xFFDC2626);
      recBg = const Color(0xFFFEE2E2);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primaryViolet, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NRI Confidence Score',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '6-Pillar Remote Investment Evaluation',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.overallScore}/100',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: recBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      score.recommendation,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: recColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: AppTheme.borderLight),

          // 6-Pillars Grid
          Column(
            children: [
              _buildPillarRow('Property Quality & Elevation', score.propertyScore, LucideIcons.building2),
              _buildPillarRow('Location & Corridor Access', score.locationScore, LucideIcons.mapPin),
              _buildPillarRow('RERA & Document Integrity', score.documentationScore, LucideIcons.fileCheck),
              _buildPillarRow('Fair Market Valuation', score.valueScore, LucideIcons.trendingUp),
              _buildPillarRow('Remote Digital Visibility', score.remoteVisibilityScore, LucideIcons.video),
              _buildPillarRow('Deal & Registry Readiness', score.dealReadinessScore, LucideIcons.award),
            ],
          ),
          const SizedBox(height: 14),

          // Highlights Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score Highlights', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                ...score.highlights.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.check, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Expanded(child: Text(h, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Center(
            child: Text(
              'Informational decision-support metric. Not legal or financial advice.',
              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarRow(String label, int score, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.primaryViolet),
          const SizedBox(width: 8),
          Expanded(
            flex: 40,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 45,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  score >= 90 ? const Color(0xFF16A34A) : (score >= 80 ? AppTheme.primaryViolet : const Color(0xFFD97706)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '$score%',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
