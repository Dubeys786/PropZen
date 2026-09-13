import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/post_visit_retention_model.dart';
import '../services/post_visit_retention_service.dart';
import '../services/deal_room_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'site_visit_booking_screen.dart';
import 'deal_room_screen.dart';

class AiPropertyRematchScreen extends StatelessWidget {
  final PostVisitFeedback? feedback;

  const AiPropertyRematchScreen({super.key, this.feedback});

  @override
  Widget build(BuildContext context) {
    final matches = PostVisitRetentionService.instance.getReMatchedProperties(feedback: feedback);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Property Re-Match',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Feedback Insights Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.brainCircuit, color: Color(0xFFC084FC), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'PERSONALIZED RE-MATCH ENGINE',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFC084FC), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Properties Matched For You',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feedback != null
                        ? 'Curated alternatives addressing your feedback on "${feedback!.propertyTitle}" (${feedback!.dealBreakers.isNotEmpty ? feedback!.dealBreakers.join(", ") : "budget & layout"}).'
                        : 'Curated properties matching your saved preferences and search history.',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Top Verified Matches (${matches.length} Available)',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            // 2. Property Match List
            if (matches.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.searchX, size: 40, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No matching properties found right now',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can broaden your budget or location preferences in your profile.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  final m = matches[i];
                  final p = m.property;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Match Badge & Pricing Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: m.matchPercentage >= 90
                                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                      : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.sparkles, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${m.matchPercentage}% Match • ${m.matchGrade}',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              p.priceRangeDisplay,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title and Sector
                        Text(
                          p.title,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '${p.effectiveLocality}, ${p.city} • ${p.bhk} • ${p.sqft} sq.ft.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                        ),

                        const SizedBox(height: 12),

                        // "Why this matches you" Explanatory Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF4F46E5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Why this matches you',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF312E81)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.matchExplanation,
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF374151), height: 1.3),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Highlights
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: m.keyHighlights.map((h) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                h,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textPrimary,
                                  side: const BorderSide(color: AppTheme.borderLight),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('View Details', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => SiteVisitBookingScreen(property: p)),
                                  );
                                },
                                icon: const Icon(LucideIcons.calendar, size: 14),
                                label: const Text('Book Visit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryViolet,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final room = DealRoomService.instance.getOrCreateDealRoom(
                                  property: p,
                                  buyerId: 'usr_active',
                                  buyerName: 'Verified Buyer',
                                  dealerId: p.dealerId.isNotEmpty ? p.dealerId : 'dealer_ncr_01',
                                  dealerName: 'Aman Sharma (Prime Realty)',
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: room.id)),
                                );
                              },
                              icon: const Icon(LucideIcons.shieldCheck, color: AppTheme.emeraldSuccess),
                              tooltip: 'Open Deal Room',
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
