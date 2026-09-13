import 'package:flutter/material.dart';
import '../models/service_request_model.dart';
import '../screens/user_profile_screen.dart';
import '../screens/dual_auth_screen.dart';
import '../screens/service_partner_access_denied_screen.dart';
import '../screens/service_partners/service_partner_status_screen.dart';
import '../routes/app_routes.dart';

/// Route Guard ensuring only authenticated, approved partners with matching service specialization
/// can access a specific service partner portal.
class ServicePartnerRouteGuard extends StatelessWidget {
  final ServiceCategoryType requiredCategory;
  final WidgetBuilder builder;

  const ServicePartnerRouteGuard({
    super.key,
    required this.requiredCategory,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Check Authentication
    if (!UserSession.isLoggedIn) {
      final targetRoute = AppRoutes.getPartnerPortalRouteForCategory(requiredCategory);
      return DualAuthScreen(redirectRoute: targetRoute);
    }

    // 2. Admin Universal Clearance (Admins can preview and inspect any partner portal)
    if (UserSession.isAdmin) {
      return builder(context);
    }

    // 3. Strict Role Enforcement (Only Service Partners allowed)
    if (!UserSession.isServicePartner) {
      return const ServicePartnerAccessDeniedScreen();
    }

    // 4. Verification and Specialization Checks
    final profile = UserSession.currentServicePartnerProfile;
    if (profile == null) {
      return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.missingSpecialization);
    }

    if (profile.isSuspended) {
      return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.suspended);
    }

    if (profile.isRejected) {
      return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.rejected);
    }

    if (!profile.isApproved) {
      return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.pending);
    }

    if (profile.approvedCategoryTypes.isEmpty) {
      return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.missingSpecialization);
    }

    // 5. Specialization Gate: Partner must have approval for this specific category
    if (!profile.canProvide(requiredCategory)) {
      return const ServicePartnerAccessDeniedScreen();
    }

    return builder(context);
  }
}
