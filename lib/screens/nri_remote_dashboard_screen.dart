import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_subscription_model.dart';
import '../services/property_state_service.dart';
import '../services/nri_subscription_service.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import '../widgets/nri_drone_tour_player_modal.dart';
import 'nri_subscription_plans_screen.dart';
import 'deal_room_screen.dart';
import '../widgets/my_payments_modal.dart';

/// Dedicated NRI Dashboard: "My Remote Property Journey"
class NriRemoteDashboardScreen extends StatefulWidget {
  const NriRemoteDashboardScreen({super.key});

  @override
  State<NriRemoteDashboardScreen> createState() => _NriRemoteDashboardScreenState();
}

class _NriRemoteDashboardScreenState extends State<NriRemoteDashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final PropertyStateService _stateService = PropertyStateService.instance;
  final NriSubscriptionService _subService = NriSubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;

    return AnimatedBuilder(
      animation: Listenable.merge([
        UserSession.userTypeNotifier,
        UserSession.nriSubscriptionNotifier,
        _subService,
        _stateService,
      ]),
      builder: (context, _) {
        final sub = UserSession.nriSubscription;
        final hasActiveDrone = UserSession.hasActiveDroneAccess;
        final droneProperties = _stateService.allProperties.where((p) => p.hasDroneTour).toList();
        final remoteBookings = _subService.remoteBookings;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            title: Text(
              'My Remote Property Journey',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => MyPaymentsModal.show(context),
                icon: const Icon(LucideIcons.receipt, size: 15, color: AppTheme.primaryViolet),
                label: Text(
                  'My Payments',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryViolet,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
              indicatorColor: AppTheme.primaryViolet,
              tabs: const [
                Tab(text: 'Drone Aerial Tours', icon: Icon(LucideIcons.video, size: 16)),
                Tab(text: 'Remote Virtual Tours', icon: Icon(LucideIcons.calendarCheck, size: 16)),
                Tab(text: '3D & 360° Tours', icon: Icon(LucideIcons.box, size: 16)),
                Tab(text: 'NRI Deal Room & Title', icon: Icon(LucideIcons.fileCheck2, size: 16)),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 50 : (isTablet ? 24 : 16),
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. NRI Status & Subscription Details Card
                _buildSubscriptionCard(sub, hasActiveDrone, isDesktop),

                const SizedBox(height: 24),

                // 2. Tab Content View
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Drone Aerial Tours
                      _buildDroneToursTab(droneProperties, hasActiveDrone),

                      // Tab 2: Remote Virtual Tours History & Scheduling
                      _buildRemoteToursTab(remoteBookings),

                      // Tab 3: 3D & 360° Tours
                      _build3dToursTab(),

                      // Tab 4: NRI Deal Room & Title
                      _buildDealRoomTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCard(NriSubscription? sub, bool hasActiveDrone, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1A7C3AED), blurRadius: 20, offset: Offset(0, 4))],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.globe, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NRI Investor Profile',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Residence: ${UserSession.userCountry} • Remote Exploration Mode',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasActiveDrone
                      ? const Color(0xFF10B981)
                      : (sub != null && (sub.isPlanSelected || sub.isPaymentPending)
                          ? const Color(0xFFF59E0B)
                          : (sub != null && sub.isExpired ? const Color(0xFFDC2626) : const Color(0xFF64748B))),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasActiveDrone
                          ? LucideIcons.checkCircle
                          : (sub != null && sub.isExpired ? LucideIcons.xCircle : LucideIcons.alertCircle),
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasActiveDrone
                          ? 'Active Pass'
                          : (sub != null && sub.isExpired
                              ? 'Pass Expired'
                              : (sub != null && (sub.isPlanSelected || sub.isPaymentPending)
                                  ? 'Payment Required'
                                  : 'No Active Pass')),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Colors.white24),
          if (hasActiveDrone && sub != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Plan: ${sub.planName}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Valid Until: ${sub.formattedExpiryDate} (${sub.remainingDays} days remaining)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NriSubscriptionPlansScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Manage Subscription', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else if (sub != null && (sub.isPlanSelected || sub.isPaymentPending)) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected: ${sub.planName} • Payment Required', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Complete server-verified payment to unlock 4K drone tours and remote features.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NriSubscriptionPlansScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Complete Payment', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unlock 4K Aerial Drone Tours', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Get full access to all NCR property drone flights and corridor aerial telemetry.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NriSubscriptionPlansScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(sub != null && sub.isExpired ? 'Renew Pass' : 'Get NRI Pass', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDroneToursTab(List<Property> properties, bool hasActiveDrone) {
    if (properties.isEmpty) {
      return Center(
        child: Text('No drone tours available currently.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: properties.length,
      itemBuilder: (ctx, i) {
        final p = properties[i];
        return InkWell(
          onTap: () {
            if (hasActiveDrone) {
              NriDroneTourPlayerModal.show(context, p);
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NriSubscriptionPlansScreen()));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.subtleCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          p.droneTourThumbnail ?? p.dynamicImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F172A)),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.video, size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(p.droneTourDuration ?? '2:45', style: GoogleFonts.inter(fontSize: 10, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(hasActiveDrone ? LucideIcons.play : LucideIcons.lock, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${p.sector}, ${p.city}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted), maxLines: 1),
                      const SizedBox(height: 6),
                      Text(p.formattedPrice, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemoteToursTab(List<RemoteTourBooking> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.calendarX, size: 42, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text('No Remote Tours Scheduled Yet', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('You can request live 1-on-1 video walkthroughs directly from any property page.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: bookings.length,
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.video, color: AppTheme.primaryViolet, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.propertyTitle, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('${b.tourTypeDisplay} • ${b.preferredDate} at ${b.preferredTime}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    Text('Timezone: ${b.timezone}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Confirmed', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A))),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _build3dToursTab() {
    final propertiesWith3D = _stateService.allProperties.where((p) => p.has3DModel || p.hasVirtualTour).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: propertiesWith3D.length,
      itemBuilder: (ctx, i) {
        final p = propertiesWith3D[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(p.dynamicImageUrl, width: 70, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 70, height: 60)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('${p.bhk} • ${p.formattedPrice}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => NriDroneTourPlayerModal.show(context, p),
                icon: const Icon(LucideIcons.box, size: 14, color: Colors.white),
                label: Text('Explore 3D', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDealRoomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 10),
                    Text('NRI Title & Legal Registry Supervision', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'All NRI remote transactions include verified 30-year encumbrance title searches, RERA compliance certificates, and power-of-attorney drafting support.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DealRoomScreen(dealRoomId: 'DR-NRI-101'))),
                  icon: const Icon(LucideIcons.lock, size: 14, color: Colors.white),
                  label: Text('Open Remote Deal Room', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
