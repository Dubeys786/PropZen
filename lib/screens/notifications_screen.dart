import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stateService = PropertyStateService.instance;

    return AnimatedBuilder(
      animation: stateService,
      builder: (context, _) {
        final notifs = stateService.notifications;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              'Notifications',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
            actions: [
              if (notifs.isNotEmpty)
                TextButton(
                  onPressed: () => stateService.markAllNotificationsAsRead(),
                  child: Text('Mark all read', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: notifs.isEmpty
              ? const Center(
                  child: EmptyStateView(
                    title: 'No notifications yet',
                    message: 'You will receive price drops, inquiry responses, and site visit confirmations here.',
                    icon: LucideIcons.bellOff,
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
                  itemCount: notifs.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final n = notifs[i];
                    final isRead = n['isRead'] as bool? ?? false;
                    final type = n['type'] as String? ?? 'general';

                    IconData icon = LucideIcons.bell;
                    Color iconColor = AppTheme.primaryViolet;

                    if (type == 'price_drop') {
                      icon = LucideIcons.tag;
                      iconColor = AppTheme.coralDanger;
                    } else if (type == 'new_launch') {
                      icon = LucideIcons.rocket;
                      iconColor = AppTheme.primaryViolet;
                    } else if (type == 'booking') {
                      icon = LucideIcons.calendarCheck;
                      iconColor = AppTheme.emeraldSuccess;
                    }

                    return InkWell(
                      onTap: () => stateService.markNotificationAsRead(n['id'] as String),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead ? AppTheme.cardWhite : AppTheme.surfaceSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead ? AppTheme.borderLight : AppTheme.primaryViolet.withOpacity(0.3),
                          ),
                          boxShadow: AppTheme.softCardShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n['title'] as String? ?? 'Alert',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryViolet,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['body'] as String? ?? '',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n['time'] as String? ?? '',
                                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
