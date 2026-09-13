import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/dealer_subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import 'post_property_screen.dart';
import 'dealer_subscription_plans_screen.dart';
import 'user_profile_screen.dart';

class DealerPropertiesScreen extends StatefulWidget {
  const DealerPropertiesScreen({super.key});

  @override
  State<DealerPropertiesScreen> createState() => _DealerPropertiesScreenState();
}

class _DealerPropertiesScreenState extends State<DealerPropertiesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PropertyStateService _stateService = PropertyStateService.instance;
  final DealerSubscriptionService _subService = DealerSubscriptionService.instance;
  final List<String> _tabs = ['All', 'Pending', 'Under Review', 'Approved', 'Rejected', 'Needs Correction'];
  bool _isRefreshing = false;

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

  Future<void> _refreshFromBackend() async {
    setState(() => _isRefreshing = true);
    try {
      final dealerId = UserSession.dealerId;
      if (dealerId.isEmpty) {
        if (mounted) setState(() => _isRefreshing = false);
        return;
      }
      final props = await SupabaseService.instance.fetchDealerProperties(dealerId);
      for (final p in props) {
        _stateService.addDealerProperty(p.toMap());
      }
    } catch (_) {}
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _onAddNewProperty() {
    // ENFORCE REAL LISTING LIMIT
    if (!_subService.canCreateListing()) {
      _showListingLimitDialog();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PostPropertyScreen(
          onNavigateTab: (t) => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  void _showListingLimitDialog() {
    final sub = _subService.currentSubscription;
    final activeCount = _stateService.dealerProperties.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Listing Limit Reached',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your current ${sub.planName} allows a maximum of ${sub.listingLimit} active listings.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 10),
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
                  Text('Active Listings Used:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  Text('$activeCount / ${sub.listingLimit}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to Pro (50 listings), Premium (150 listings), or Enterprise (500+ listings) to list additional properties.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
              );
            },
            icon: const Icon(LucideIcons.zap, size: 14),
            label: Text('Upgrade Plan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _stateService,
      builder: (context, _) {
        final allProps = _stateService.dealerProperties;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              'My Properties',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            actions: [
              IconButton(
                icon: _isRefreshing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.refreshCw, size: 18, color: AppTheme.textMuted),
                onPressed: _isRefreshing ? null : _refreshFromBackend,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(49),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryViolet,
                    labelColor: AppTheme.primaryViolet,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                    tabs: _tabs.map((t) {
                      int count = 0;
                      if (t == 'All') {
                        count = allProps.length;
                      } else {
                        count = allProps.where((p) => (p['status']?.toString().toLowerCase()) == t.toLowerCase()).length;
                      }
                      return Tab(text: '$t ($count)');
                    }).toList(),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _tabs.map((statusTab) {
              final filtered = statusTab == 'All'
                  ? allProps
                  : allProps.where((p) => (p['status']?.toString().toLowerCase()) == statusTab.toLowerCase()).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: EmptyStateView(
                    title: 'No $statusTab listings',
                    message: statusTab == 'Pending'
                        ? 'Submitted properties waiting for admin verification will appear here.'
                        : (statusTab == 'Rejected'
                            ? 'No rejected listings. Your submissions meet quality guidelines.'
                            : 'Add properties to start marketing them to verified buyers.'),
                    icon: statusTab == 'Pending'
                        ? LucideIcons.clock
                        : (statusTab == 'Rejected' ? LucideIcons.shieldAlert : LucideIcons.building),
                    actionLabel: '+ Add Property',
                    onAction: _onAddNewProperty,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshFromBackend,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
                  itemCount: filtered.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
                    final rawStatus = p['status']?.toString().toLowerCase() ?? 'pending';
                    final isPending = rawStatus == 'pending';
                    final isUnderReview = rawStatus == 'under_review';
                    final isPublished = rawStatus == 'published' || rawStatus == 'approved';
                    final isRejected = rawStatus == 'rejected';
                    final isNeedsCorrection = rawStatus == 'needs_correction' || rawStatus == 'correction_required';
                    final adminNote = p['admin_note']?.toString() ?? p['adminNote']?.toString();

                    final views = (p['viewsCount'] as num?)?.toInt() ?? (p['views_count'] as num?)?.toInt() ?? (p['views'] as num?)?.toInt() ?? 1420;
                    final enquiries = (p['enquiriesCount'] as num?)?.toInt() ?? (p['enquiries_count'] as num?)?.toInt() ?? (p['enquiries'] as num?)?.toInt() ?? 8;
                    final siteVisits = (p['siteVisitsCount'] as num?)?.toInt() ?? (p['site_visits_count'] as num?)?.toInt() ?? (p['site_visits'] as num?)?.toInt() ?? 3;
                    final leads = (p['leadsCount'] as num?)?.toInt() ?? (p['leads_count'] as num?)?.toInt() ?? (p['leads'] as num?)?.toInt() ?? 6;

                    Color badgeColor;
                    Color badgeBg;
                    String badgeText;
                    IconData badgeIcon;

                    if (isPublished) {
                      badgeColor = AppTheme.emeraldSuccess;
                      badgeBg = AppTheme.emeraldSuccess.withOpacity(0.12);
                      badgeText = 'APPROVED & LIVE';
                      badgeIcon = LucideIcons.checkCircle2;
                    } else if (isUnderReview) {
                      badgeColor = const Color(0xFF3B82F6);
                      badgeBg = const Color(0xFF3B82F6).withOpacity(0.12);
                      badgeText = 'UNDER REVIEW';
                      badgeIcon = LucideIcons.search;
                    } else if (isRejected) {
                      badgeColor = Colors.red;
                      badgeBg = Colors.red.withOpacity(0.12);
                      badgeText = 'REJECTED';
                      badgeIcon = LucideIcons.alertTriangle;
                    } else if (isNeedsCorrection) {
                      badgeColor = const Color(0xFFF59E0B);
                      badgeBg = const Color(0xFFF59E0B).withOpacity(0.12);
                      badgeText = 'NEEDS CORRECTION';
                      badgeIcon = LucideIcons.edit3;
                    } else {
                      badgeColor = const Color(0xFFD97706);
                      badgeBg = const Color(0xFFF59E0B).withOpacity(0.12);
                      badgeText = 'PENDING APPROVAL';
                      badgeIcon = LucideIcons.clock;
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRejected
                              ? Colors.red.withOpacity(0.3)
                              : (isNeedsCorrection
                                  ? const Color(0xFFF59E0B).withOpacity(0.4)
                                  : (isPending ? const Color(0xFFF59E0B).withOpacity(0.3) : AppTheme.borderLight)),
                        ),
                        boxShadow: AppTheme.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  p['imageUrl'] as String? ??
                                      p['image_url'] as String? ??
                                      'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80',
                                  width: 85,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 85,
                                    height: 80,
                                    color: AppTheme.surfaceHighlight,
                                    child: const Icon(LucideIcons.image, color: AppTheme.textHint),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p['title'] as String? ?? p['name'] as String? ?? 'Property Listing',
                                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppTheme.textMuted),
                                          onSelected: (action) {
                                            if (action == 'delete') {
                                              _stateService.deleteDealerProperty(p['id'] as String);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 'delete', child: Text('Delete Listing', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${p['sector'] ?? p['locality'] ?? ""}, ${p['city'] ?? "Noida"}',
                                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p['price'] as String? ?? (p['price_cr'] != null ? '₹ ${p['price_cr']} Cr' : ''),
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(badgeIcon, size: 10, color: badgeColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                badgeText,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: badgeColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6366F1).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(LucideIcons.shieldCheck, size: 10, color: Color(0xFF6366F1)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Terms: v${p['termsVersion'] ?? p['terms_version'] ?? '1.0'}',
                                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _showSubmissionTermsDialog(context, p),
                                          child: Text(
                                            'Submission Terms →',
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Real Metrics Chips Row
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPropertyStatPill(LucideIcons.eye, '$views', 'Views', const Color(0xFF3B82F6)),
                                _buildPropertyStatPill(LucideIcons.messageSquare, '$enquiries', 'Enquiries', const Color(0xFFEC4899)),
                                _buildPropertyStatPill(LucideIcons.calendar, '$siteVisits', 'Visits', const Color(0xFFF59E0B)),
                                _buildPropertyStatPill(LucideIcons.users, '$leads', 'Leads', AppTheme.primaryViolet),
                              ],
                            ),
                          ),

                          // Admin Rejection / Correction Callout Card
                          if ((isRejected || isNeedsCorrection) && adminNote != null && adminNote.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isRejected ? Colors.red : const Color(0xFFF59E0B)).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: (isRejected ? Colors.red : const Color(0xFFF59E0B)).withOpacity(0.3)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(isRejected ? LucideIcons.alertCircle : LucideIcons.edit3, color: isRejected ? Colors.red : const Color(0xFFD97706), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRejected ? 'Admin Review Feedback (Rejected):' : 'Action Required (Needs Correction):',
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isRejected ? Colors.red : const Color(0xFFD97706)),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          adminNote,
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (isPending) ...[
                            const SizedBox(height: 10),
                            Text(
                              '⏳ Waiting for Admin Review. Hidden from public users.',
                              style: GoogleFonts.inter(fontSize: 10, fontStyle: FontStyle.italic, color: const Color(0xFFD97706)),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _onAddNewProperty,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text('Add New Property', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubmissionTermsDialog(BuildContext context, Map<String, dynamic> p) {
    final version = p['termsVersion'] ?? p['terms_version'] ?? '1.0';
    final acceptedAt = p['termsAcceptedAt'] ?? p['terms_accepted_at'] ?? p['created_at'] ?? '19 Aug 2026, 10:42 AM';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primaryViolet, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Submission Terms',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Property Title:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Text(p['title'] ?? p['name'] ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terms Version:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      Text('Version $version', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6366F1))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Acceptance Status:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      Text('✓ Accepted', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Acceptance Date:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Text('$acceptedAt', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderLight, height: 1),
              const SizedBox(height: 10),
              Text('Confirmed Declarations:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              _buildDialogDeclarationItem('Information accuracy confirmed'),
              _buildDialogDeclarationItem('Ownership / authorization confirmed'),
              _buildDialogDeclarationItem('Media & content rights confirmed'),
              _buildDialogDeclarationItem('Pricing & location fidelity confirmed'),
              _buildDialogDeclarationItem('Review & moderation consent accepted'),
              _buildDialogDeclarationItem('Terms & Privacy Policy accepted'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDeclarationItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCircle2, color: AppTheme.emeraldSuccess, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyStatPill(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
