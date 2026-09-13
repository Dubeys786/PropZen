import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/service_partner_profile.dart';
import '../../models/service_request_model.dart';
import '../../services/service_partner_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../user_profile_screen.dart';

/// Screen displayed after login for partners with multiple ADMIN-APPROVED services.
/// Allows selecting which completely separate dashboard to open.
class SelectServicePortalScreen extends StatelessWidget {
  const SelectServicePortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ServicePartnerService.instance;
    final profile = UserSession.currentServicePartnerProfile ?? service.currentProfile;
    final approvedCategories = profile?.approvedCategoryTypes ?? [];

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryViolet, Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.layoutGrid, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'PropZen Multi-Service Partner',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(LucideIcons.logOut, color: AppTheme.textSecondary),
            onPressed: () {
              UserSession.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: 36,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 14, color: AppTheme.primaryViolet),
                      const SizedBox(width: 6),
                      Text(
                        'ADMIN-APPROVED MULTI-SPECIALIZATION PARTNER',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Your Service Portal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the specialized operational workspace you wish to manage. Each portal runs completely isolated workflows and dedicated customer data.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),

                // Grid of approved portals
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: isMobile ? 1.9 : 1.7,
                  ),
                  itemCount: approvedCategories.length,
                  itemBuilder: (ctx, i) {
                    final cat = approvedCategories[i];
                    return _buildPortalCard(context, cat, profile);
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Need to add another specialization? Contact PropZen Partner Support for institutional authorization.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, ServiceCategoryType category, ServicePartnerProfile? profile) {
    final details = _getPortalDetails(category);
    final count = ServicePartnerService.instance.getActiveServicesCount(profile?.id ?? '', category: category);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: details.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: details.color.withOpacity(0.25)),
                ),
                child: Icon(details.icon, color: details.color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.tagline,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count Active Projects',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: details.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  ServicePartnerService.instance.setActiveCategory(category);
                  Navigator.of(context).pushReplacementNamed(details.route);
                },
                icon: const Text('Open Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                label: const Icon(LucideIcons.arrowRight, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _PortalDetails _getPortalDetails(ServiceCategoryType category) {
    switch (category) {
      case ServiceCategoryType.loan:
        return _PortalDetails(
          name: 'Loan Partner Portal',
          tagline: 'Home finance, institutional loan files, and bank underwriting',
          icon: LucideIcons.landmark,
          color: const Color(0xFF059669),
          route: AppRoutes.loanPartnerPortal,
        );
      case ServiceCategoryType.homeDesign:
        return _PortalDetails(
          name: 'Home Design Partner Portal',
          tagline: 'Architectural floor plans, 2D/3D renders, and turnkey interiors',
          icon: LucideIcons.palette,
          color: const Color(0xFF8B5CF6),
          route: AppRoutes.homeDesignPartnerPortal,
        );
      case ServiceCategoryType.vastu:
        return _PortalDetails(
          name: 'Vastu Partner Portal',
          tagline: 'Directional zonal energy audits, Vedic remedies, and certified reports',
          icon: LucideIcons.compass,
          color: const Color(0xFFD97706),
          route: AppRoutes.vastuPartnerPortal,
        );
      case ServiceCategoryType.construction:
        return _PortalDetails(
          name: 'Construction Partner Portal',
          tagline: 'Civil construction, site milestones, BOQ tracking, and site inspections',
          icon: LucideIcons.hardHat,
          color: const Color(0xFF0284C7),
          route: AppRoutes.constructionPartnerPortal,
        );
      case ServiceCategoryType.propertyVerification:
        return _PortalDetails(
          name: 'Property Verification Partner Portal',
          tagline: 'Legal due diligence, 30-year deed chains, and RERA compliance',
          icon: LucideIcons.fileCheck2,
          color: const Color(0xFF4F46E5),
          route: AppRoutes.propertyVerificationPartnerPortal,
        );
      case ServiceCategoryType.visualization:
        return _PortalDetails(
          name: 'Virtual & 3D Partner Portal',
          tagline: 'Matterport WebXR tours, drone photogrammetry, and AR model delivery',
          icon: LucideIcons.view,
          color: const Color(0xFFDB2777),
          route: AppRoutes.virtual3dPartnerPortal,
        );
    }
  }
}

class _PortalDetails {
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  final String route;

  const _PortalDetails({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.route,
  });
}
