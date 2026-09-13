import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../routes/app_routes.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/dual_auth_screen.dart';
import '../screens/user_profile_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_gate.dart';

/// Secure Role-Based Admin Route Guard
/// Strictly enforces access control for PropZen Command Center:
/// - Only dubeysakshi618@gmail.com with verified ADMIN role is granted access.
/// - Unauthenticated users are redirected to DualAuthScreen.
/// - Non-admin users (Buyer, Dealer, Service Partner) are blocked immediately,
///   shown an explicit "Unauthorized Access" banner, and redirected to their
///   designated role dashboard.
class AdminRouteGuard extends StatefulWidget {
  final Widget? child;
  final bool allowCrmRoles;

  const AdminRouteGuard({super.key, this.child, this.allowCrmRoles = false});

  @override
  State<AdminRouteGuard> createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  bool _redirectScheduled = false;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _checkAndScheduleRedirect();
  }

  @override
  void didUpdateWidget(covariant AdminRouteGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndScheduleRedirect();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _checkAndScheduleRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AuthService.instance.isLoading) return;

      final isAuthorizedAdmin = UserSession.isAdmin;
      final isPermittedCrmUser = widget.allowCrmRoles && UserSession.isCrmAuthorized;

      // If user is logged in but NOT authorized, schedule auto-redirect to their dashboard
      if (UserSession.isLoggedIn && !isAuthorizedAdmin && !isPermittedCrmUser && !_redirectScheduled) {
        _redirectScheduled = true;
        _redirectTimer = Timer(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          final destination = AppRoutes.getPostLoginDestination();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unauthorized Access. Admin credentials required.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.of(context).pushReplacementNamed(destination);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AuthService.instance,
        UserSession.isLoggedInNotifier,
        UserSession.roleTierNotifier,
        UserSession.emailNotifier,
      ]),
      builder: (context, _) {
        // 1. Session Restoration & Async Auth State (Prevents blank screen & loop on refresh)
        if (AuthService.instance.isLoading) {
          return const PropZenSplashScreen();
        }

        // 2. Unauthenticated State -> Must sign in first
        if (!UserSession.isLoggedIn) {
          return const DualAuthScreen(redirectRoute: AppRoutes.admin);
        }

        // 3. Authorized Admin or Permitted CRM Role -> Render Command Center / Child
        final isAuthorizedAdmin = UserSession.isAdmin;
        final isPermittedCrmUser = widget.allowCrmRoles && UserSession.isCrmAuthorized;

        if (isAuthorizedAdmin || isPermittedCrmUser) {
          return widget.child ?? const AdminPanelScreen();
        }

        // 4. Unauthorized User (Buyer, etc.) -> Access Denied Screen
        return _buildAccessDeniedScreen(context);
      },
    );
  }

  Widget _buildAccessDeniedScreen(BuildContext context) {
    final currentRole = UserSession.roleTierNotifier.value.isNotEmpty
        ? UserSession.roleTierNotifier.value.toUpperCase()
        : 'USER';
    final userEmail = UserSession.email.isNotEmpty ? UserSession.email : 'Unknown User';
    final destination = AppRoutes.getPostLoginDestination();

    String roleDisplayName = 'Buyer Dashboard';
    if (UserSession.isDealer) {
      roleDisplayName = 'Dealer Portal';
    } else if (UserSession.isServicePartner) {
      roleDisplayName = 'Service Partner Portal';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Secure dark slate background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacementNamed(destination),
        ),
        title: Text(
          'Security Checkpoint',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Red Shield Icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(LucideIcons.shieldAlert, color: Color(0xFFEF4444), size: 44),
                ),
                const SizedBox(height: 20),

                // Primary Error Header
                Text(
                  'Unauthorized Access',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Specific Error Notice Required
                Text(
                  'Admin credentials required.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF87171),
                  ),
                ),
                const SizedBox(height: 18),

                // Identity info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.user, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFE2E8F0),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.badgeAlert, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'Active Role: $currentRole',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'This route (/admin) is restricted exclusively to authorized PropZen platform administrators. Your account does not have administrative privileges.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),

                // Action 1: Return to their valid dashboard
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed(destination);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(LucideIcons.arrowRight, size: 18),
                    label: Text(
                      'Go to $roleDisplayName',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action 2: Switch to Admin Account
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AuthService.instance.logout();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const DualAuthScreen(redirectRoute: AppRoutes.admin),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF475569)),
                      foregroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.logIn, size: 16),
                    label: Text(
                      'Sign In as Admin',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
