import 'package:flutter/material.dart';
import '../../screens/user_profile_screen.dart';
import '../../screens/dual_auth_screen.dart';
import '../screens/crm_unauthorized_screen.dart';

/// Route guard ensuring only authorized internal roles can access CRM modules.
/// Authorized roles: ADMIN, DEALER, STAFF, CRM_MANAGER, CRM_AGENT.
/// Unauthorized users (e.g. BUYER or guests) are securely intercepted.
class CrmRouteGuard extends StatelessWidget {
  final WidgetBuilder builder;
  final String? redirectRoute;

  const CrmRouteGuard({
    super.key,
    required this.builder,
    this.redirectRoute,
  });

  static bool isUserAuthorized() {
    if (!UserSession.isLoggedIn) return false;
    if (UserSession.isAdmin) return true;
    if (UserSession.isDealer) return true;

    final role = UserSession.roleTierNotifier.value.toUpperCase().trim();
    const authorizedRoles = {
      'ADMIN',
      'SUPER_ADMIN',
      'DEALER',
      'VERIFIED DEALER',
      'APPROVED_DEALER',
      'STAFF',
      'CRM_MANAGER',
      'CRM_AGENT',
    };
    return authorizedRoles.contains(role);
  }

  @override
  Widget build(BuildContext context) {
    if (!UserSession.isLoggedIn) {
      return DualAuthScreen(redirectRoute: redirectRoute ?? '/crm');
    }

    if (!isUserAuthorized()) {
      return CrmUnauthorizedScreen(attemptedRoute: redirectRoute);
    }

    return builder(context);
  }
}
