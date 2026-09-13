import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/notification_model.dart';
import '../services/property_state_service.dart';
import '../services/user_notification_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'user_profile_screen.dart';

class MyPropzenDashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const MyPropzenDashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MyPropzenDashboardScreen> createState() => _MyPropzenDashboardScreenState();
}

class _MyPropzenDashboardScreenState extends State<MyPropzenDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(LucideIcons.home, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('My PropZen Dashboard', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryViolet,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryViolet,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Saved Properties', icon: Icon(LucideIcons.heart, size: 16)),
            Tab(text: 'Recently Viewed', icon: Icon(LucideIcons.history, size: 16)),
            Tab(text: 'My Enquiries', icon: Icon(LucideIcons.messageSquare, size: 16)),
            Tab(text: 'My Site Visits', icon: Icon(LucideIcons.calendar, size: 16)),
            Tab(text: 'Notifications & Alerts', icon: Icon(LucideIcons.bell, size: 16)),
            Tab(text: 'Account & Security', icon: Icon(LucideIcons.shield, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedPropertiesTab(isDesktop),
          _buildRecentlyViewedTab(isDesktop),
          _buildEnquiriesTab(isDesktop),
          _buildSiteVisitsTab(isDesktop),
          _buildNotificationsTab(isDesktop),
          _buildAccountSecurityTab(isDesktop),
        ],
      ),
    );
  }

  // 1. Saved Properties Tab
  Widget _buildSavedPropertiesTab(bool isDesktop) {
    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (ctx, _) {
        final saved = PropertyStateService.instance.savedProperties;
        if (saved.isEmpty) {
          return _buildEmptyTabState(
            icon: LucideIcons.heart,
            title: 'No Saved Properties',
            message: 'Tap the heart icon on any property to save it to your wishlist.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: saved.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final p = saved[i];
            return _buildPropertyItemCard(p, showRemoveWishlist: true);
          },
        );
      },
    );
  }

  // 2. Recently Viewed Tab
  Widget _buildRecentlyViewedTab(bool isDesktop) {
    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (ctx, _) {
        final viewed = PropertyStateService.instance.recentlyViewedProperties;
        if (viewed.isEmpty) {
          return _buildEmptyTabState(
            icon: LucideIcons.history,
            title: 'No Recently Viewed Properties',
            message: 'Properties you browse will automatically appear here for quick recall.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: viewed.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final p = viewed[i];
            return _buildPropertyItemCard(p);
          },
        );
      },
    );
  }

  // 3. Enquiries Tab
  Widget _buildEnquiriesTab(bool isDesktop) {
    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (ctx, _) {
        final enquiries = PropertyStateService.instance.enquiries;
        if (enquiries.isEmpty) {
          return _buildEmptyTabState(
            icon: LucideIcons.messageSquare,
            title: 'No Active Enquiries',
            message: 'Submit an enquiry on any verified property to track dealer responses here.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: enquiries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final e = enquiries[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e['propertyName'] ?? 'Property Enquiry', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text('Active Lead', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Message: "${e['message'] ?? 'Interest in property'}"', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. Site Visits Tab
  Widget _buildSiteVisitsTab(bool isDesktop) {
    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (ctx, _) {
        final visits = PropertyStateService.instance.scheduledVisits;
        if (visits.isEmpty) {
          return _buildEmptyTabState(
            icon: LucideIcons.calendar,
            title: 'No Scheduled Site Visits',
            message: 'Book a site visit on any property to experience it physically or remotely.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: visits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final v = visits[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['propertyTitle'] ?? 'Site Visit', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Date: ${v['date'] ?? 'Upcoming'} • Time: ${v['time'] ?? '11:00 AM'}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(v['status'] ?? 'CONFIRMED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                        onPressed: () => _showPostVisitFeedbackModal(v['propertyTitle'] ?? 'Property'),
                        icon: const Icon(LucideIcons.star, size: 14),
                        label: const Text('Leave Feedback', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 5. Notifications Tab
  Widget _buildNotificationsTab(bool isDesktop) {
    return AnimatedBuilder(
      animation: UserNotificationService.instance,
      builder: (ctx, _) {
        final notifs = UserNotificationService.instance.notifications;
        if (notifs.isEmpty) {
          return _buildEmptyTabState(
            icon: LucideIcons.bell,
            title: 'No Notifications',
            message: 'You are all caught up on property verifications and price alerts.',
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          itemCount: notifs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final n = notifs[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: n.isRead ? Colors.white : AppTheme.primaryViolet.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: n.isRead ? AppTheme.borderLight : AppTheme.primaryViolet.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(n.type == NotificationType.priceChange ? LucideIcons.trendingDown : (n.type == NotificationType.propertyVerification ? LucideIcons.shieldCheck : LucideIcons.bell), size: 18, color: AppTheme.primaryViolet),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(n.message, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 6. Account & Security Tab
  Widget _buildAccountSecurityTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Privacy & Trust Settings', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('PropZen strictly protects your phone number and email prior to verified enquiry initiation.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const Divider(height: 20),
                _buildSecuritySettingRow('Contact Masking', 'Active for unverified dealers', true),
                _buildSecuritySettingRow('WhatsApp Lead Notifications', 'Instant site visit confirmations enabled', true),
                _buildSecuritySettingRow('Price Drop Telemetry', 'Active on saved wishlist properties', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyItemCard(Property p, {bool showRemoveWishlist = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.borderLight)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(p.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${p.sector}, ${p.city} • ${p.bhk}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                Text(p.formattedPrice, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)),
              );
            },
            child: const Text('Open', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySettingRow(String title, String subtitle, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          ]),
          Icon(isEnabled ? LucideIcons.checkCircle : LucideIcons.circle, color: isEnabled ? AppTheme.emeraldSuccess : Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState({required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.08), shape: BoxShape.circle), child: Icon(icon, size: 40, color: AppTheme.primaryViolet)),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  void _showPostVisitFeedbackModal(String propTitle) {
    double overallRating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Site Visit Feedback', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate your completed site visit for "$propTitle":', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => const Icon(Icons.star, color: Colors.amber, size: 28)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Comments on property & dealer (Optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted. Thank you for helping keep PropZen verified!')));
            },
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }
}
