import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/dealer_notification_model.dart';
import '../services/dealer_lead_service.dart';
import '../theme/app_theme.dart';
import '../screens/user_profile_screen.dart';

class DealerNotificationsModal extends StatelessWidget {
  final String dealerId;

  const DealerNotificationsModal({
    super.key,
    this.dealerId = '',
  });

  static void show(BuildContext context, {String dealerId = ''}) {
    final effectiveId = dealerId.isNotEmpty ? dealerId : UserSession.dealerId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DealerNotificationsModal(dealerId: effectiveId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadService = DealerLeadService.instance;
    final effectiveDealerId = dealerId.isNotEmpty ? dealerId : UserSession.dealerId;

    return AnimatedBuilder(
      animation: leadService,
      builder: (context, _) {
        final notifs = leadService.getNotificationsForDealer(effectiveDealerId);
        final unreadCount = notifs.where((n) => !n.isRead).length;

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.bell, color: AppTheme.primaryViolet, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dealer Notifications',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            Text(
                              '$unreadCount unread updates',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (unreadCount > 0)
                      TextButton.icon(
                        onPressed: () => leadService.markAllNotificationsAsRead(dealerId),
                        icon: const Icon(LucideIcons.checkCheck, size: 14, color: AppTheme.primaryViolet),
                        label: Text(
                          'Mark All Read',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderLight, height: 1),

              // Notifications List
              Flexible(
                child: notifs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.bellOff, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No notifications yet', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('Updates on enquiries, leads, and listings will appear here.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final n = notifs[idx];
                          return InkWell(
                            onTap: () {
                              if (!n.isRead) leadService.markNotificationAsRead(n.id);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: n.isRead ? Colors.white : const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: n.isRead ? AppTheme.borderLight : AppTheme.primaryViolet.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: n.iconColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(n.icon, color: n.iconColor, size: 16),
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
                                                n.title,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (!n.isRead)
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
                                          n.message,
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTimeAgo(n.createdAt),
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
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
