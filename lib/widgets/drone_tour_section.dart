import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../screens/user_profile_screen.dart';
import '../screens/drone_tour_subscription_screen.dart';
import '../widgets/nri_drone_tour_player_modal.dart';
import '../theme/app_theme.dart';

/// Reusable Drone Tour Section Component for Property Cards
/// Displayed consistently across EVERY single property card in PropZen
class DroneTourSection extends StatelessWidget {
  final Property property;
  final VoidCallback? onUnlock;
  final VoidCallback? onWatchTour;

  const DroneTourSection({
    super.key,
    required this.property,
    this.onUnlock,
    this.onWatchTour,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UserSession.droneSubscriptionNotifier,
      builder: (context, _, __) {
        final hasDrone = UserSession.hasActiveDroneAccess;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasDrone
                  ? AppTheme.emeraldSuccess.withOpacity(0.4)
                  : const Color(0xFF6366F1).withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              const Text('🚁', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          'Drone Tour',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Premium Aerial Experience',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  if (hasDrone) {
                    if (onWatchTour != null) {
                      onWatchTour!();
                    } else {
                      NriDroneTourPlayerModal.show(context, property);
                    }
                  } else {
                    if (onUnlock != null) {
                      onUnlock!();
                    } else {
                      DroneTourSubscriptionScreen.show(context, returnToProperty: property);
                    }
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasDrone ? AppTheme.emeraldSuccess : const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDrone ? LucideIcons.play : LucideIcons.lock,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasDrone ? 'Watch Drone Tour' : 'Unlock',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
