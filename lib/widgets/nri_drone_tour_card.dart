import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../screens/user_profile_screen.dart';
import '../screens/drone_tour_subscription_screen.dart';
import '../screens/ai_advisor_chat_screen.dart';
import '../screens/deal_room_screen.dart';
import '../services/nri_subscription_service.dart';
import '../services/deal_room_service.dart';
import '../theme/app_theme.dart';
import 'nri_drone_tour_player_modal.dart';
import 'nri_remote_tour_dialog.dart';
import 'nri_construction_progress_card.dart';
import 'nri_investment_calculator_dialog.dart';
import 'nri_loan_assistance_dialog.dart';
import 'nri_document_concierge_modal.dart';
import 'nri_family_decision_dialog.dart';
import 'nri_confidence_score_card.dart';
import 'property_3d_model_viewer.dart';
import 'property_360_tour_viewer.dart';
import 'property_floor_plan_viewer.dart';
import 'interactive_property_map.dart';

/// Complete, Premium Remote Experience & Drone Tour Suite (Visible to All Users)
class NriDroneTourCard extends StatelessWidget {
  final Property property;

  const NriDroneTourCard({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        UserSession.userTypeNotifier,
        UserSession.nriSubscriptionNotifier,
        UserSession.droneSubscriptionNotifier,
        NriSubscriptionService.instance,
      ]),
      builder: (context, _) {
        final isNri = UserSession.isNri;
        final hasSubscription = UserSession.hasActiveDroneAccess;
        final isMonitored = NriSubscriptionService.instance.isPropertyMonitored(property.id);

        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth >= 600;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDD6FE)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryViolet.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Suite Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryViolet, Color(0xFF4338CA)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.globe, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'NRI Remote Property Experience',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasSubscription ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      hasSubscription ? 'PASS ACTIVE' : 'PREVIEW MODE',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: hasSubscription ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Explore Indian properties remotely from anywhere in the world.',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => NriSubscriptionService.instance.togglePropertyMonitoring(property.id, property.title),
                    tooltip: isMonitored ? 'Following updates' : 'Follow property',
                    icon: Icon(
                      isMonitored ? LucideIcons.bellRing : LucideIcons.bell,
                      color: isMonitored ? AppTheme.primaryViolet : AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. The 8 Core NRI Experience Cards
              Text(
                'Remote Experience Suite',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isTablet ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Card 1: 🚁 Drone Tour
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.video,
                          iconColor: const Color(0xFF4F46E5),
                          iconBg: const Color(0xFFEEF2FF),
                          title: '🚁 Drone Tour',
                          badge: 'PREMIUM',
                          description: 'Premium Aerial Experience',
                          statusLabel: property.hasDroneTour
                              ? (hasSubscription ? '4K AERIAL READY' : 'PASS REQUIRED')
                              : 'NOT AVAILABLE YET',
                          statusColor: property.hasDroneTour
                              ? (hasSubscription ? AppTheme.emeraldSuccess : const Color(0xFFD97706))
                              : AppTheme.textMuted,
                          buttonText: property.hasDroneTour
                              ? (hasSubscription ? '▶ Watch Drone Tour' : '🔒 Unlock')
                              : 'Drone Tour Unavailable',
                          buttonIcon: hasSubscription ? LucideIcons.playCircle : LucideIcons.lock,
                          isButtonEnabled: property.hasDroneTour,
                          onPressed: () {
                            if (!property.hasDroneTour) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Drone tour is not available for this property yet.')),
                              );
                              return;
                            }
                            if (hasSubscription) {
                              NriDroneTourPlayerModal.show(context, property);
                            } else {
                              DroneTourSubscriptionScreen.show(context, returnToProperty: property);
                            }
                          },
                        ),
                      ),

                      // Card 2: 🌐 360° Virtual Tour
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.compass,
                          iconColor: const Color(0xFF7C3AED),
                          iconBg: const Color(0xFFEDE9FE),
                          title: '360° Virtual Tour',
                          description: 'Immerse in full 360-degree panoramic view of rooms.',
                          statusLabel: property.hasVirtualTour ? 'PANORAMA READY' : 'NOT AVAILABLE YET',
                          statusColor: property.hasVirtualTour ? AppTheme.emeraldSuccess : AppTheme.textMuted,
                          buttonText: property.hasVirtualTour ? 'Explore 360° Tour' : '360° Tour Unavailable',
                          buttonIcon: LucideIcons.maximize2,
                          isButtonEnabled: property.hasVirtualTour,
                          onPressed: () {
                            if (!property.hasVirtualTour) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('360° tour is not available for this property yet.')),
                              );
                              return;
                            }
                            Property360TourViewer.show(context, property);
                          },
                        ),
                      ),

                      // Card 3: 🏠 3D Property
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.box,
                          iconColor: const Color(0xFF0D9488),
                          iconBg: const Color(0xFFCCFBF1),
                          title: '3D Property',
                          description: 'Inspect architectural 3D digital twin model with orbit & pitch.',
                          statusLabel: property.has3DModel ? '3D TWIN READY' : 'NOT AVAILABLE YET',
                          statusColor: property.has3DModel ? AppTheme.emeraldSuccess : AppTheme.textMuted,
                          buttonText: property.has3DModel ? 'View 3D Model' : '3D Model Unavailable',
                          buttonIcon: LucideIcons.layers,
                          isButtonEnabled: property.has3DModel,
                          onPressed: () {
                            if (!property.has3DModel) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('3D model is not available for this property yet.')),
                              );
                              return;
                            }
                            Property3DModelViewer.show(context, property);
                          },
                        ),
                      ),

                      // Card 4: 📐 Floor Plan
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.layoutGrid,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFEDD5),
                          title: 'Floor Plan',
                          description: 'High-resolution architectural layout with room dimensions.',
                          statusLabel: 'BLUEPRINT VERIFIED',
                          statusColor: AppTheme.emeraldSuccess,
                          buttonText: 'View Floor Plan',
                          buttonIcon: LucideIcons.fileText,
                          isButtonEnabled: true,
                          onPressed: () => PropertyFloorPlanViewer.show(context, property),
                        ),
                      ),

                      // Card 5: 📍 Locality Intelligence
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.mapPin,
                          iconColor: const Color(0xFFDC2626),
                          iconBg: const Color(0xFFFEE2E2),
                          title: 'Locality Intelligence',
                          description: 'Real distance & travel time to Metro, Expressways, Airport & Hubs.',
                          statusLabel: 'COORDINATES VERIFIED',
                          statusColor: AppTheme.emeraldSuccess,
                          buttonText: 'Explore Locality',
                          buttonIcon: LucideIcons.map,
                          isButtonEnabled: true,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => Container(
                                height: MediaQuery.of(context).size.height * 0.85,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Locality Intelligence — ${property.sector}',
                                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            icon: const Icon(LucideIcons.x),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: InteractivePropertyMap(property: property),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Card 6: 🤖 AI Property Advisor
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.bot,
                          iconColor: const Color(0xFF4F46E5),
                          iconBg: const Color(0xFFEEF2FF),
                          title: 'AI Property Advisor',
                          description: 'Ask NRI investment, price trend & legal compliance questions.',
                          statusLabel: 'REAL-TIME DATA',
                          statusColor: AppTheme.emeraldSuccess,
                          buttonText: 'Ask AI Advisor',
                          buttonIcon: LucideIcons.sparkles,
                          isButtonEnabled: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AiAdvisorChatScreen(
                                  property: property,
                                  initialQuery: 'Is ${property.title} in ${property.sector} suitable for NRI investment?',
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Card 7: 📹 Live Remote Tour
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.video,
                          iconColor: const Color(0xFF059669),
                          iconBg: const Color(0xFFD1FAE5),
                          title: 'Live Remote Tour',
                          description: 'Schedule a live 1-on-1 virtual walkthrough with listing dealer.',
                          statusLabel: '1-ON-1 DEALER GUIDED',
                          statusColor: AppTheme.emeraldSuccess,
                          buttonText: 'Request Live Tour',
                          buttonIcon: LucideIcons.calendar,
                          isButtonEnabled: true,
                          onPressed: () => NriRemoteTourDialog.show(context, property: property),
                        ),
                      ),

                      // Card 8: 🏗️ Construction Progress
                      SizedBox(
                        width: cardWidth,
                        child: _buildExperienceCard(
                          context,
                          icon: LucideIcons.hardHat,
                          iconColor: const Color(0xFFCA8A04),
                          iconBg: const Color(0xFFFEF9C3),
                          title: 'Construction Progress',
                          description: 'Verified builder milestones & live construction timeline.',
                          statusLabel: property.constructionStatus.isNotEmpty ? property.constructionStatus : 'RERA TRACKED',
                          statusColor: AppTheme.emeraldSuccess,
                          buttonText: 'View Milestones',
                          buttonIcon: LucideIcons.trendingUp,
                          isButtonEnabled: true,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Construction Milestone Tracker',
                                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            icon: const Icon(LucideIcons.x),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      NriConstructionProgressCard(property: property),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // 3. Fast NRI Services Bar
              Text(
                'NRI Financial & Legal Hub',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickActionPill(
                    context,
                    icon: LucideIcons.calculator,
                    label: 'Yield Calculator',
                    onTap: () => NriInvestmentCalculatorDialog.show(context, property: property),
                  ),
                  _buildQuickActionPill(
                    context,
                    icon: LucideIcons.landmark,
                    label: 'NRI Home Loan',
                    onTap: () => NriLoanAssistanceDialog.show(context, property: property),
                  ),
                  _buildQuickActionPill(
                    context,
                    icon: LucideIcons.fileCheck2,
                    label: 'Document Vault',
                    onTap: () => NriDocumentConciergeModal.show(context, property: property),
                  ),
                  _buildQuickActionPill(
                    context,
                    icon: LucideIcons.users,
                    label: 'Family Voting',
                    onTap: () => NriFamilyDecisionDialog.show(context, property: property),
                  ),
                  _buildQuickActionPill(
                    context,
                    icon: LucideIcons.shieldCheck,
                    label: 'Secure Deal Room',
                    onTap: () {
                      final room = DealRoomService.instance.getOrCreateDealRoom(
                        property: property,
                        buyerId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_nri_active',
                        buyerName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'NRI Global Buyer',
                        dealerId: property.dealerId,
                        dealerName: property.dealerName.isNotEmpty ? property.dealerName : 'Verified Partner',
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: room.id)),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Multi-Pillar NRI Confidence Score
              NriConfidenceScoreCard(property: property),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExperienceCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? badge,
    required String description,
    required String statusLabel,
    required Color statusColor,
    required String buttonText,
    required IconData buttonIcon,
    required bool isButtonEnabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            description,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 14),
              label: Text(buttonText, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isButtonEnabled ? AppTheme.primaryViolet : const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppTheme.primaryViolet),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
