import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_subscription_model.dart';
import '../services/nri_subscription_service.dart';
import '../theme/app_theme.dart';

/// Real Construction Progress Tracker Card for Under-Construction Properties
class NriConstructionProgressCard extends StatelessWidget {
  final Property property;

  const NriConstructionProgressCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final progressData = NriSubscriptionService.instance.getConstructionProgressForProperty(
      property.id,
      property.title,
    );

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.hardHat, color: Color(0xFFD97706), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Construction Progress',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Current Stage: ${progressData.currentPhase}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${progressData.overallProgressPercent}% Complete',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Linear Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressData.overallProgressPercent / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Possession: ${progressData.scheduledPossession}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Verified: ${progressData.verifiedSource}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
          const Divider(height: 24, color: AppTheme.borderLight),

          // Stage Milestones List
          Text('Key Engineering Milestones', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),

          Column(
            children: progressData.milestones.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      m.isCompleted
                          ? LucideIcons.checkCircle2
                          : (m.isCurrent ? LucideIcons.clock : LucideIcons.circle),
                      size: 16,
                      color: m.isCompleted
                          ? const Color(0xFF16A34A)
                          : (m.isCurrent ? const Color(0xFFD97706) : AppTheme.textHint),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m.stageName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: m.isCurrent ? FontWeight.bold : FontWeight.w600,
                                  color: m.isCompleted || m.isCurrent ? AppTheme.textPrimary : AppTheme.textMuted,
                                ),
                              ),
                              Text(
                                m.estimatedDate,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: m.isCurrent ? FontWeight.bold : FontWeight.normal,
                                  color: m.isCurrent ? const Color(0xFFD97706) : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.description,
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
