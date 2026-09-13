import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/property_state_service.dart';
import '../widgets/global_search_bar.dart';
import 'home_screen.dart';
import 'property_search_screen.dart';
import 'dynamic_filter_screen.dart';
import 'ai_advisor_chat_screen.dart';
import 'all_features_screen.dart';
import 'wishlist_screen.dart';
import 'user_profile_screen.dart';
import 'dealer_dashboard_screen.dart';
import 'post_property_screen.dart';
import 'dual_auth_screen.dart';
import 'email_verification_screen.dart';
import 'notifications_screen.dart';
import 'emi_calculator_screen.dart';
import 'property_compare_screen.dart';
import 'about_screen.dart';
import 'contact_screen.dart';
import 'settings_screen.dart';
import 'dealers_directory_screen.dart';
import 'market_hub_screen.dart';
import 'admin_panel_screen.dart';
import 'my_site_visits_screen.dart';
import '../widgets/propzen_voice_agent_modal.dart';
import '../widgets/floating_social_buttons.dart';
import '../widgets/propzen_tools_mega_menu.dart';
import '../config/social_config.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import 'dealer_access_denied_screen.dart';

class MainShell extends StatefulWidget {
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final ThemeMode currentThemeMode;
  final int initialIndex;

  const MainShell({
    super.key,
    this.onThemeModeChanged,
    this.currentThemeMode = ThemeMode.dark,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final PropertyStateService _stateService = PropertyStateService.instance;
  final GlobalKey<GlobalSearchBarState> _searchBarKey = GlobalKey<GlobalSearchBarState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkRoleRedirection();
    AuthService.instance.addListener(_checkRoleRedirection);
    UserSession.roleTierNotifier.addListener(_checkRoleRedirection);
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_checkRoleRedirection);
    UserSession.roleTierNotifier.removeListener(_checkRoleRedirection);
    super.dispose();
  }

  void _checkRoleRedirection() {
    if (!mounted) return;
    if (AuthService.instance.isLoading) return;
    if (widget.initialIndex == 0 && _currentIndex == 0) {
      if (UserSession.isServicePartner) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !UserSession.isServicePartner) return;
          final r = ModalRoute.of(context);
          if (r != null && !r.isCurrent) return;
          AppRoutes.navigateToPostLoginDestination(context);
        });
      } else if (UserSession.isAdmin) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !UserSession.isAdmin) return;
          final r = ModalRoute.of(context);
          if (r != null && !r.isCurrent) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.admin);
        });
      }
    }
  }

  void _switchTab(int index) {
    if (index < 0 || index >= 14) {
      debugPrint('[MainShell] _switchTab called with out-of-bounds index: $index');
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _openWhatsApp() async {
    final uri = Uri.parse(SocialConfig.whatsappChatUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openListPropertyGate(BuildContext context) {
    if (!UserSession.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const DualAuthScreen(redirectRoute: AppRoutes.listProperty),
        ),
      );
      return;
    }

    if (!UserSession.isEmailVerified) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EmailVerificationGateScreen(
            redirectRoute: AppRoutes.listProperty,
            onVerified: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (ctx2) => PostPropertyScreen(onNavigateTab: (t) => Navigator.of(ctx2).pop()),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PostPropertyScreen(onNavigateTab: (t) => Navigator.of(ctx).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideDesktop = screenWidth >= 1340;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 650 && screenWidth < 1024;
    final isMobile = screenWidth < 650;

    final screens = [
      // 0: Home Screen
      HomeScreen(
        onNavigateTab: _switchTab,
      ),
      // 1: Properties / Search Screen
      const PropertySearchScreen(),
      // 2: AI Match / Advisor
      const AiAdvisorChatScreen(),
      // 3: Site Visits Screen
      MySiteVisitsScreen(onNavigateTab: _switchTab),
      // 4: Profile & My Account
      UserProfileScreen(onNavigateTab: _switchTab),
      // 5: Wishlist / Saved
      const WishlistScreen(),
      // 6: Notifications
      const NotificationsScreen(),
      // 7: Compare Properties
      const PropertyCompareScreen(),
      // 8: Loan Calculator
      const EmiCalculatorScreen(),
      // 9: About Screen
      const AboutScreen(),
      // 10: Contact Screen
      const ContactScreen(),
      // 11: Settings Screen
      const SettingsScreen(),
      // 12: Dealer & Broker Portal (Strictly Guarded)
      (UserSession.isDealer || UserSession.isAdmin)
          ? const DealerDashboardScreen()
          : const DealerAccessDeniedScreen(),
      // 13: Services Hub & All Features
      AllFeaturesScreen(onNavigateTab: _switchTab),
    ];

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _SearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (intent) {
              if (isMobile) {
                GlobalSearchBar.showSearchModal(context, onNavigateTab: _switchTab);
              } else {
                _searchBarKey.currentState?.focusSearch();
              }
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: AppTheme.pageBackground,
          endDrawer: _buildSideMenuDrawer(context),
          appBar: AppBar(
            toolbarHeight: isDesktop ? 74 : (isTablet ? 66 : 58),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            automaticallyImplyLeading: false,
            titleSpacing: isDesktop ? 20 : 12,
            leading: (isMobile && _currentIndex != 0)
                ? IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A), size: 20),
                    tooltip: 'Back to Home',
                    onPressed: () => _switchTab(0),
                  )
                : null,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PropZen Responsive Top Navigation Logo
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _switchTab(0),
                    child: Image.asset(
                      'assets/propzen_logo.png',
                      height: isDesktop ? 46 : (isTablet ? 38 : 30),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (ctx, err, stack) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Prop',
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Zen',
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 22 : 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (isDesktop) const SizedBox(width: 16),

                // Desktop Navigation Header Links
                if (isDesktop) ...[
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _buildHeaderNavLink('Home', _currentIndex == 0, () => _switchTab(0)),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('Properties', _currentIndex == 1, () => _switchTab(1)),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('AI Match', _currentIndex == 2, () => _switchTab(2)),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('Tools ▾', false, () => PropzenToolsMegaMenu.show(context)),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('Services Hub', _currentIndex == 13, () => _switchTab(13)),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('Deals', false, () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => const PropertySearchScreen(
                                  filterTag: 'Price Drop',
                                  title: 'Price Drop Deals',
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('Dealers Directory', false, () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const DealersDirectoryScreen()),
                            );
                          }),
                          const SizedBox(width: 4),
                          _buildHeaderNavLink('Market Hub', false, () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => const MarketHubScreen()),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              // 1. GLOBAL SEARCH (Desktop & Tablet)
              if (isDesktop) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: GlobalSearchBar(
                    key: _searchBarKey,
                    onNavigateTab: _switchTab,
                    width: isWideDesktop ? 310 : 250,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              if (isTablet) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: GlobalSearchBar(
                    key: _searchBarKey,
                    onNavigateTab: _switchTab,
                    width: 210,
                    isCompact: true,
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Mobile Global Search Button
              if (isMobile) ...[
                IconButton(
                  tooltip: 'Search PropZen (Ctrl+K)',
                  icon: const Icon(LucideIcons.search, size: 20, color: Color(0xFF7C3AED)),
                  onPressed: () => GlobalSearchBar.showSearchModal(context, onNavigateTab: _switchTab),
                ),
              ],

              // 2. "Talk to PropZen AI" Button
              if (isDesktop) ...[
                ElevatedButton.icon(
                  onPressed: () => PropzenVoiceAgentModal.show(context),
                  icon: const Icon(LucideIcons.mic, size: 14, color: Colors.white),
                  label: Text(
                    isWideDesktop ? 'Talk to PropZen AI' : 'AI Voice',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (isTablet) ...[
                IconButton(
                  tooltip: 'Talk to PropZen AI',
                  icon: const Icon(LucideIcons.mic, size: 19, color: Color(0xFF4F46E5)),
                  onPressed: () => PropzenVoiceAgentModal.show(context),
                ),
              ],

              // 3. "List Your Property" Button (Desktop)
              if (isDesktop) ...[
                ElevatedButton.icon(
                  onPressed: () => _openListPropertyGate(context),
                  icon: const Icon(LucideIcons.plusCircle, size: 14, color: Colors.white),
                  label: Text(
                    'List Your Property',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // 4. Saved Heart Icon (Desktop & Tablet)
              if (!isMobile) ...[
                IconButton(
                  tooltip: 'Saved Properties',
                  icon: const Icon(LucideIcons.heart, size: 19, color: Color(0xFFEC4899)),
                  onPressed: () => _switchTab(5),
                ),
              ],

              // 5. Notifications Bell Icon with Badge
              _buildNotificationBellButton(),

              // 6. Dealer Dashboard Icon (Only for active Dealers / Brokers)
              if (isDesktop) ...[
                ValueListenableBuilder<String>(
                  valueListenable: UserSession.roleTierNotifier,
                  builder: (ctx, roleTier, _) {
                    if (!UserSession.isDealer) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: 'Dealer Portal',
                      icon: const Icon(LucideIcons.briefcase, size: 19, color: AppTheme.primaryViolet),
                      onPressed: () => _switchTab(12),
                    );
                  },
                ),
              ],

              // 7. Profile Avatar Icon (Desktop & Tablet)
              if (!isMobile) ...[
                ValueListenableBuilder<String?>(
                  valueListenable: UserSession.avatarUrlNotifier,
                  builder: (ctx, avatarUrl, _) {
                    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
                    return IconButton(
                      tooltip: 'My Profile',
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentIndex == 4 ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          image: hasPhoto
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: hasPhoto
                            ? null
                            : const Icon(LucideIcons.user, size: 16, color: Color(0xFF0F172A)),
                      ),
                      onPressed: () => _switchTab(4),
                    );
                  },
                ),
              ],

              // Hamburger Menu on mobile & tablet
              if (!isDesktop) ...[
                Builder(
                  builder: (menuCtx) => IconButton(
                    icon: const Icon(LucideIcons.menu, color: Color(0xFF0F172A), size: 20),
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(menuCtx).openEndDrawer(),
                  ),
                ),
              ],
              const SizedBox(width: 6),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
      bottomNavigationBar: !isDesktop
          ? SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
                  color: Colors.white,
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex < 5 ? _currentIndex : 0,
                  onTap: (index) {
                    _switchTab(index);
                  },
                  backgroundColor: Colors.white,
                  selectedItemColor: AppTheme.primaryViolet,
                  unselectedItemColor: const Color(0xFF64748B),
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(LucideIcons.building), label: 'Properties'),
                    BottomNavigationBarItem(icon: Icon(LucideIcons.bot), label: 'AI Match'),
                    BottomNavigationBarItem(icon: Icon(LucideIcons.calendarCheck), label: 'Site Visits'),
                    BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: _currentIndex == 4 ? null : const FloatingSocialButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildNotificationBellButton() {
    return AnimatedBuilder(
      animation: _stateService,
      builder: (ctx, _) {
        final unread = _stateService.unreadNotificationCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(LucideIcons.bell, size: 19, color: Color(0xFFF59E0B)),
              onPressed: () => _switchTab(6),
            ),
            if (unread > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  child: Text(
                    '$unread',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSideMenuDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/propzen_logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Text('PropZen', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Quick Search in Drawer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        GlobalSearchBar.showSearchModal(context, onNavigateTab: _switchTab);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.search, size: 16, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 10),
                            Text(
                              'Search PropZen...',
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⌘K',
                                style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildDrawerTile(LucideIcons.plusCircle, 'List Your Property', () {
                    Navigator.of(context).pop();
                    _openListPropertyGate(context);
                  }, isHighlighted: true),
                  _buildDrawerTile(LucideIcons.building, 'Properties', () {
                    Navigator.of(context).pop();
                    _switchTab(1);
                  }),
                  _buildDrawerTile(LucideIcons.bot, 'AI Match', () {
                    Navigator.of(context).pop();
                    _switchTab(2);
                  }),
                  _buildDrawerTile(LucideIcons.layoutGrid, 'PropZen Tools', () {
                    Navigator.of(context).pop();
                    PropzenToolsMegaMenu.show(context);
                  }, isHighlighted: true),
                  _buildDrawerTile(LucideIcons.calendarCheck, 'My Site Visits', () {
                    Navigator.of(context).pop();
                    _switchTab(3);
                  }),
                  _buildDrawerTile(LucideIcons.layoutGrid, 'Services Hub', () {
                    Navigator.of(context).pop();
                    _switchTab(13);
                  }),
                  _buildDrawerTile(LucideIcons.barChart2, 'Market Intelligence', () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const MarketHubScreen()));
                  }, isHighlighted: true),
                  _buildDrawerTile(LucideIcons.users, 'Dealers Directory', () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const DealersDirectoryScreen()));
                  }),
                  _buildDrawerTile(LucideIcons.slidersHorizontal, 'Advanced Filters', () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const DynamicFilterScreen()));
                  }),
                  _buildDrawerTile(LucideIcons.scale, 'Compare Properties', () {
                    Navigator.of(context).pop();
                    _switchTab(7);
                  }),
                  _buildDrawerTile(LucideIcons.calculator, 'Loan Calculator', () {
                    Navigator.of(context).pop();
                    _switchTab(8);
                  }),
                  const Divider(height: 20, color: AppTheme.borderLight),
                  if (UserSession.isAdmin)
                    _buildDrawerTile(LucideIcons.shieldCheck, 'Command Center', () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AdminPanelScreen()));
                    }, isHighlighted: true),
                  if (UserSession.isDealer)
                    _buildDrawerTile(LucideIcons.layoutDashboard, 'Dealer Portal', () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.dealerPortal);
                    }, isHighlighted: true),
                  if (UserSession.isServicePartner)
                    _buildDrawerTile(LucideIcons.wrench, 'Service Partner Portal', () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed(AppRoutes.servicePartnerPortal);
                    }, isHighlighted: true),
                  _buildDrawerTile(LucideIcons.sparkles, 'AI Home Designer', () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(AppRoutes.aiHomeDesigner);
                  }),
                  _buildDrawerTile(LucideIcons.heart, 'Saved Properties', () {
                    Navigator.of(context).pop();
                    _switchTab(5);
                  }),
                  _buildDrawerTile(LucideIcons.bell, 'Notifications', () {
                    Navigator.of(context).pop();
                    _switchTab(6);
                  }),
                  _buildDrawerTile(LucideIcons.user, 'My Profile', () {
                    Navigator.of(context).pop();
                    _switchTab(4);
                  }),
                  _buildDrawerTile(LucideIcons.messageCircle, 'WhatsApp Support', () {
                    Navigator.of(context).pop();
                    _openWhatsApp();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap, {bool isHighlighted = false}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: isHighlighted ? AppTheme.primaryViolet : const Color(0xFF334155)),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          color: isHighlighted ? AppTheme.primaryViolet : const Color(0xFF1E293B),
        ),
      ),
      trailing: isHighlighted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'LIVE',
                style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
              ),
            )
          : const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  Widget _buildHeaderNavLink(String title, bool isSelected, VoidCallback onTap, {bool isBadge = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      hoverColor: const Color(0xFFF5F3FF),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: const Color(0xFFDDD6FE)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF334155),
              ),
            ),
            if (isBadge) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'PORTAL',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
