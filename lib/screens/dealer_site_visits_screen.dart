import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/site_visit_model.dart';
import '../services/dealer_lead_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import 'user_profile_screen.dart';

class DealerSiteVisitsScreen extends StatefulWidget {
  const DealerSiteVisitsScreen({super.key});

  @override
  State<DealerSiteVisitsScreen> createState() => _DealerSiteVisitsScreenState();
}

class _DealerSiteVisitsScreenState extends State<DealerSiteVisitsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final DealerLeadService _leadService = DealerLeadService.instance;
  final List<String> _tabs = ['All', 'Requested', 'Confirmed', 'Completed', 'Cancelled'];

  String get _currentDealerId => UserSession.dealerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _leadService,
      builder: (context, _) {
        final allVisits = _leadService.getSiteVisitsForDealer(_currentDealerId);

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.calendar, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Site Visit Management', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('${allVisits.length} total visit appointments', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.primaryViolet,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.primaryViolet,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.normal),
                  tabs: _tabs.map((tab) {
                    int count = 0;
                    if (tab == 'All') count = allVisits.length;
                    if (tab == 'Requested') count = allVisits.where((v) => v.isRequested).length;
                    if (tab == 'Confirmed') count = allVisits.where((v) => v.isConfirmed).length;
                    if (tab == 'Completed') count = allVisits.where((v) => v.isCompleted).length;
                    if (tab == 'Cancelled') count = allVisits.where((v) => v.isCancelled).length;
                    return Tab(text: '$tab ($count)');
                  }).toList(),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              List<DealerSiteVisit> list = allVisits;
              if (tab == 'Requested') list = allVisits.where((v) => v.isRequested).toList();
              if (tab == 'Confirmed') list = allVisits.where((v) => v.isConfirmed).toList();
              if (tab == 'Completed') list = allVisits.where((v) => v.isCompleted).toList();
              if (tab == 'Cancelled') list = allVisits.where((v) => v.isCancelled).toList();

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: EmptyStateView(
                      title: 'No $tab Visits',
                      message: 'No site visits found under the "$tab" status.',
                      icon: LucideIcons.calendarX,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, idx) => _buildSiteVisitCard(list[idx]),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSiteVisitCard(DealerSiteVisit visit) {
    Color badgeColor;
    Color badgeBg;
    switch (visit.status) {
      case SiteVisitStatus.confirmed:
        badgeColor = const Color(0xFF10B981);
        badgeBg = const Color(0xFFECFDF5);
        break;
      case SiteVisitStatus.completed:
        badgeColor = const Color(0xFF6366F1);
        badgeBg = const Color(0xFFEEF2FF);
        break;
      case SiteVisitStatus.cancelled:
        badgeColor = const Color(0xFFEF4444);
        badgeBg = const Color(0xFFFEF2F2);
        break;
      case SiteVisitStatus.requested:
      default:
        badgeColor = const Color(0xFFF59E0B);
        badgeBg = const Color(0xFFFFFBEB);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Buyer name & Status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryViolet.withOpacity(0.12),
                        child: Text(
                          visit.buyerName.isNotEmpty ? visit.buyerName[0].toUpperCase() : 'B',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.buyerName,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              visit.buyerPhone.isNotEmpty ? visit.buyerPhone : 'Buyer contact verified',
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: badgeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    visit.status.badgeLabel,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.borderLight, height: 1),
            const SizedBox(height: 12),

            // Property details
            Row(
              children: [
                const Icon(LucideIcons.home, size: 16, color: AppTheme.primaryViolet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visit.propertyTitle,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Appointment schedule & specs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${visit.scheduledDate} • ${visit.scheduledTime}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(LucideIcons.users, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${visit.visitorCount} Visitor${visit.visitorCount > 1 ? "s" : ""}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      if (visit.cabRequired) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.car, size: 10, color: Color(0xFF10B981)),
                              const SizedBox(width: 3),
                              Text('Cab', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (visit.pickupLocation != null && visit.pickupLocation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 6),
                  Text('Pickup: ${visit.pickupLocation}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                if (visit.buyerPhone.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      final clean = visit.buyerPhone.replaceAll(RegExp(r'[^0-9]'), '');
                      launchUrl(Uri.parse('https://wa.me/$clean?text=Hi%20${Uri.encodeComponent(visit.buyerName)},%20confirming%20your%20site%20visit%20for%20${Uri.encodeComponent(visit.propertyTitle)}%20on%20${Uri.encodeComponent(visit.scheduledDate)}.'));
                    },
                    icon: const Icon(LucideIcons.messageCircle, size: 14, color: Color(0xFF25D366)),
                    label: Text('WhatsApp', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF25D366))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                if (visit.isRequested) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _leadService.updateSiteVisitStatus(visitId: visit.id, newStatus: SiteVisitStatus.confirmed),
                      icon: const Icon(LucideIcons.check, size: 14),
                      label: Text('Confirm Visit', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _leadService.updateSiteVisitStatus(visitId: visit.id, newStatus: SiteVisitStatus.cancelled),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Decline'),
                  ),
                ] else if (visit.isConfirmed) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _leadService.updateSiteVisitStatus(visitId: visit.id, newStatus: SiteVisitStatus.completed),
                      icon: const Icon(LucideIcons.award, size: 14),
                      label: Text('Mark Completed', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
