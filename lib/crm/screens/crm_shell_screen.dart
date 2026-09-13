import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../widgets/crm_sidebar.dart';
import 'crm_dashboard_screen.dart';
import 'crm_leads_screen.dart';
import 'crm_follow_ups_screen.dart';
import 'crm_tasks_screen.dart';
import 'crm_campaigns_screen.dart';
import 'crm_properties_screen.dart';
import 'crm_customer_360_screen.dart';
import 'crm_analytics_screen.dart';

class CrmShellScreen extends StatefulWidget {
  final CrmTab initialTab;

  const CrmShellScreen({
    super.key,
    this.initialTab = CrmTab.dashboard,
  });

  @override
  State<CrmShellScreen> createState() => _CrmShellScreenState();
}

class _CrmShellScreenState extends State<CrmShellScreen> {
  late CrmTab _activeTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  void _onTabSelected(CrmTab tab) {
    setState(() => _activeTab = tab);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop(); // Close drawer on mobile
    }
  }

  Widget _buildActiveScreen() {
    switch (_activeTab) {
      case CrmTab.dashboard:
        return CrmDashboardScreen(onNavigateTab: _onTabSelected);
      case CrmTab.leads:
        return const CrmLeadsScreen();
      case CrmTab.followUps:
        return const CrmFollowUpsScreen();
      case CrmTab.tasks:
        return const CrmTasksScreen();
      case CrmTab.campaigns:
        return const CrmCampaignsScreen();
      case CrmTab.properties:
        return const CrmPropertiesScreen();
      case CrmTab.customers:
        return const CrmCustomer360Screen();
      case CrmTab.analytics:
        return const CrmAnalyticsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          // Desktop Layout: Permanent Left Sidebar + Active View
          return Scaffold(
            body: Row(
              children: [
                CrmSidebar(
                  activeTab: _activeTab,
                  onTabSelected: _onTabSelected,
                ),
                Expanded(
                  child: _buildActiveScreen(),
                ),
              ],
            ),
          );
        }

        // Mobile / Tablet Layout: Top AppBar with Drawer
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.menu, color: AppTheme.textPrimary),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: Row(
              children: [
                Text(
                  'PropZen CRM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _activeTab.label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          drawer: Drawer(
            child: CrmSidebar(
              activeTab: _activeTab,
              onTabSelected: _onTabSelected,
            ),
          ),
          body: _buildActiveScreen(),
        );
      },
    );
  }
}
