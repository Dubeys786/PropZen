import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/property_state_service.dart';
import '../services/post_visit_retention_service.dart';
import '../services/deal_room_service.dart';
import '../models/post_visit_retention_model.dart';
import '../models/property.dart';
import '../widgets/post_visit_feedback_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import 'ai_property_rematch_screen.dart';
import 'deal_room_screen.dart';

class MySiteVisitsScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const MySiteVisitsScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final stateService = PropertyStateService.instance;

    return AnimatedBuilder(
      animation: stateService,
      builder: (context, _) {
        final visits = stateService.scheduledVisits;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              'My Site Visits',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
          ),
          body: visits.isEmpty
              ? Center(
                  child: EmptyStateView(
                    title: 'No site visits booked yet',
                    message: 'Book a site visit from any property page to schedule a guided tour.',
                    icon: LucideIcons.calendarX2,
                    actionLabel: 'Explore Properties',
                    onAction: onNavigateTab != null ? () => onNavigateTab!(1) : null,
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: visits.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                      final v = visits[i];
                      final visitId = v['id']?.toString() ?? 'VISIT-$i';
                      final propId = v['property_id']?.toString() ?? v['propertyId']?.toString() ?? '';
                      final propTitle = v['propertyTitle'] as String? ?? v['property_title'] as String? ?? 'Property Site Visit';
                      final sector = v['sector'] as String? ?? 'Sector 150, Noida';
                      final status = v['status'] as String? ?? 'Confirmed';
                      final isConfirmed = status == 'Confirmed';
                      final isCompleted = status == 'Completed';

                      final feedback = PostVisitRetentionService.instance.getFeedbackForVisit(visitId);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCompleted ? AppTheme.emeraldSuccess.withOpacity(0.4) : AppTheme.borderLight,
                            width: isCompleted ? 1.5 : 1.0,
                          ),
                          boxShadow: AppTheme.softCardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        propTitle,
                                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      Text(
                                        sector,
                                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppTheme.emeraldSuccess.withOpacity(0.15)
                                        : (isConfirmed ? const Color(0xFF6366F1).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCompleted
                                          ? AppTheme.emeraldSuccess
                                          : (isConfirmed ? const Color(0xFF6366F1).withOpacity(0.3) : const Color(0xFFF59E0B).withOpacity(0.3)),
                                    ),
                                  ),
                                  child: Text(
                                    isCompleted ? 'SITE VISIT COMPLETED ✓' : status,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isCompleted
                                          ? AppTheme.emeraldSuccess
                                          : (isConfirmed ? const Color(0xFF6366F1) : const Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.calendar, size: 12, color: AppTheme.primaryViolet),
                                      const SizedBox(width: 6),
                                      Text(
                                        v['date'] as String? ?? v['visit_date'] as String? ?? '',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.clock, size: 12, color: AppTheme.primaryViolet),
                                      const SizedBox(width: 6),
                                      Text(
                                        v['time'] as String? ?? v['time_slot'] as String? ?? '',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                // Visitor Count Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.users, size: 12, color: Color(0xFF6366F1)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${v['visitorCount'] ?? v['visitor_count'] ?? 1} Visitors',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6366F1)),
                                      ),
                                    ],
                                  ),
                                ),
                                // Cab Status Chip
                                Builder(
                                  builder: (context) {
                                    final isCab = v['cabRequired'] == true || v['cab_required'] == true;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isCab ? const Color(0xFF10B981).withOpacity(0.08) : Colors.grey.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isCab ? const Color(0xFF10B981).withOpacity(0.3) : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isCab ? LucideIcons.car : LucideIcons.ban,
                                            size: 12,
                                            color: isCab ? const Color(0xFF10B981) : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isCab ? '🚕 Cab Required' : '🚫 Cab Not Required',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isCab ? const Color(0xFF10B981) : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // Post-Visit AI Feedback Card (if feedback exists or if visit is completed)
                            if (isCompleted || feedback != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
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
                                            const Icon(LucideIcons.brain, size: 14, color: AppTheme.primaryViolet),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Your Site Visit Feedback',
                                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                            ),
                                          ],
                                        ),
                                        if (feedback != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryViolet.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              feedback.interestLevel.shortCode,
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (feedback != null) ...[
                                      if (feedback.pros.isNotEmpty)
                                        Text('✓ Pros: ${feedback.pros.first}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.emeraldSuccess)),
                                      if (feedback.cons.isNotEmpty)
                                        Text('✗ Cons: ${feedback.cons.first}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.coralDanger)),
                                      if (feedback.concerns.isNotEmpty)
                                        Text('⚠ Concern: ${feedback.concerns.first}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFD97706))),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Next Step: ${feedback.recommendedNextStep}',
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                      ),
                                    ] else ...[
                                      Text(
                                        'How was your visit? Tell PropZen to unlock tailored next steps and negotiations.',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 14),

                            // Dynamic Actions
                            if (isCompleted || feedback != null)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      PostVisitFeedbackDialog.show(
                                        context,
                                        visitId: visitId,
                                        propertyId: propId,
                                        propertyTitle: propTitle,
                                        sector: sector,
                                      );
                                    },
                                    icon: const Icon(LucideIcons.messageSquarePlus, size: 14),
                                    label: Text(feedback != null ? 'View / Edit Summary' : 'Give Visit Feedback', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryViolet,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => AiPropertyRematchScreen(feedback: feedback)),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.primaryViolet),
                                    label: Text('Find Better Properties', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryViolet),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final prop = stateService.findPropertyById(propId) ?? Property.sampleDeals.first;
                                      final room = DealRoomService.instance.getOrCreateDealRoom(
                                        property: prop,
                                        buyerId: 'usr_active',
                                        buyerName: 'Verified Buyer',
                                        dealerId: prop.dealerId.isNotEmpty ? prop.dealerId : 'dealer_ncr_01',
                                        dealerName: 'Aman Sharma (Prime Realty)',
                                      );
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: room.id)),
                                      );
                                    },
                                    icon: const Icon(LucideIcons.shieldCheck, size: 14),
                                    label: Text('Open Safe Deal Room', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.emeraldSuccess,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      stateService.updateVisitStatus(visitId, 'Completed');
                                      PostVisitFeedbackDialog.show(
                                        context,
                                        visitId: visitId,
                                        propertyId: propId,
                                        propertyTitle: propTitle,
                                        sector: sector,
                                      );
                                    },
                                    icon: const Icon(LucideIcons.checkCheck, size: 14, color: AppTheme.emeraldSuccess),
                                    label: Text('Mark Completed', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.emeraldSuccess, fontWeight: FontWeight.bold)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.emeraldSuccess),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          stateService.cancelVisit(visitId);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Site visit cancelled.'), backgroundColor: AppTheme.coralDanger),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.coralDanger,
                                          side: const BorderSide(color: Color(0x44EF4444)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text('Cancel', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.coralDanger)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final phone = (v['phone'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                          if (phone.isNotEmpty) {
                                            launchUrl(Uri.parse('https://wa.me/$phone'));
                                          }
                                        },
                                        icon: const Icon(LucideIcons.messageCircle, size: 14),
                                        label: Text('Contact Dealer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF25D366),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                  },
                ),
        );
      },
    );
  }
}
