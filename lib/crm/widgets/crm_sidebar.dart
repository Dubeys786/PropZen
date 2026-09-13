import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../screens/user_profile_screen.dart';

enum CrmTab {
  dashboard('Dashboard', LucideIcons.layoutDashboard, '/crm'),
  leads('Leads', LucideIcons.users, '/crm/leads'),
  followUps('Follow-ups', LucideIcons.calendarClock, '/crm/follow-ups'),
  tasks('Tasks', LucideIcons.checkSquare, '/crm/tasks'),
  campaigns('WhatsApp & Campaigns', LucideIcons.megaphone, '/crm/campaigns'),
  properties('Properties', LucideIcons.building, '/crm/properties'),
  customers('Customer 360', LucideIcons.userCheck, '/crm/customers'),
  analytics('Analytics', LucideIcons.barChart2, '/crm/analytics');

  final String label;
  final IconData icon;
  final String route;

  const CrmTab(this.label, this.icon, this.route);
}

class CrmSidebar extends StatelessWidget {
  final CrmTab activeTab;
  final ValueChanged<CrmTab> onTabSelected;
  final int overdueFollowUps;
  final int pendingTasks;

  const CrmSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.overdueFollowUps = 0,
    this.pendingTasks = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession.isAdmin;
    final isDealer = UserSession.isDealer;
    final roleLabel = isAdmin ? 'ADMIN' : (isDealer ? 'DEALER' : 'STAFF');

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'PropZen',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'CRM',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enterprise Pipeline',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              children: CrmTab.values.map((tab) {
                // WhatsApp campaign tab is admin-centric, but visible for preview
                final isSelected = activeTab == tab;

                int badgeCount = 0;
                Color badgeColor = const Color(0xFFEF4444);
                if (tab == CrmTab.followUps && overdueFollowUps > 0) {
                  badgeCount = overdueFollowUps;
                } else if (tab == CrmTab.tasks && pendingTasks > 0) {
                  badgeCount = pendingTasks;
                  badgeColor = const Color(0xFFF59E0B);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      selected: isSelected,
                      selectedTileColor: AppTheme.primaryColor.withOpacity(0.08),
                      leading: Icon(
                        tab.icon,
                        size: 18,
                        color: isSelected ? AppTheme.primaryColor : const Color(0xFF64748B),
                      ),
                      title: Text(
                        tab.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryColor : const Color(0xFF334155),
                        ),
                      ),
                      trailing: badgeCount > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => onTabSelected(tab),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // User info and exit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE2E8F0),
                      child: Text(
                        UserSession.fullName.isNotEmpty ? UserSession.fullName[0].toUpperCase() : 'U',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserSession.fullName.isNotEmpty ? UserSession.fullName : 'CRM Operator',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              roleLabel,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.externalLink, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          'Exit to Marketplace',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
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
