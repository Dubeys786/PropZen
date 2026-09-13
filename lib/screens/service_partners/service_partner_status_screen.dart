import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../models/service_partner_profile.dart';
import '../../services/supabase_service.dart';
import '../../services/service_partner_service.dart';
import '../user_profile_screen.dart';

enum ServicePartnerStatusType {
  pending,
  suspended,
  rejected,
  missingSpecialization,
}

class ServicePartnerStatusScreen extends StatefulWidget {
  final ServicePartnerStatusType? forcedStatus;

  const ServicePartnerStatusScreen({
    super.key,
    this.forcedStatus,
  });

  @override
  State<ServicePartnerStatusScreen> createState() => _ServicePartnerStatusScreenState();
}

class _ServicePartnerStatusScreenState extends State<ServicePartnerStatusScreen> {
  bool _isRefreshing = false;
  String? _statusNotice;

  ServicePartnerStatusType _resolveCurrentStatus(ServicePartnerProfile? profile) {
    if (widget.forcedStatus != null) return widget.forcedStatus!;
    if (profile == null) return ServicePartnerStatusType.missingSpecialization;
    if (profile.isSuspended) return ServicePartnerStatusType.suspended;
    if (profile.isRejected) return ServicePartnerStatusType.rejected;
    if (!profile.isApproved) return ServicePartnerStatusType.pending;
    if (profile.approvedCategories.isEmpty) return ServicePartnerStatusType.missingSpecialization;
    return ServicePartnerStatusType.pending;
  }

  Future<void> _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
      _statusNotice = null;
    });

    try {
      ServicePartnerProfile? updated;
      if (UserSession.userId.isNotEmpty) {
        updated = await SupabaseService.instance.fetchServicePartnerProfileByUserId(UserSession.userId);
      }
      if (updated == null && UserSession.email.isNotEmpty) {
        updated = await SupabaseService.instance.fetchServicePartnerProfileByEmail(UserSession.email);
      }

      if (mounted) {
        if (updated != null) {
          UserSession.setServicePartnerProfile(updated);
          if (updated.isApproved && updated.approvedCategories.isNotEmpty) {
            await ServicePartnerService.instance.loadForProfile(updated);
            setState(() {
              _isRefreshing = false;
              _statusNotice = 'Account approved! Redirecting to your portal...';
            });
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) {
              AppRoutes.navigateToPostLoginDestination(context);
            }
            return;
          }
        }
        setState(() {
          _isRefreshing = false;
          _statusNotice = 'Status refreshed: Profile is currently ${_statusLabel(updated?.verificationStatus ?? 'PENDING')}.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _statusNotice = 'Failed refreshing status. Please check your internet connection.';
        });
      }
    }
  }

  String _statusLabel(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'VERIFIED':
      case 'APPROVED':
        return 'Approved & Active';
      case 'SUSPENDED':
        return 'Suspended';
      case 'REJECTED':
        return 'Not Approved';
      default:
        return 'Under Review (Pending)';
    }
  }

  String _formatCategoryLabel(String code) {
    switch (code.trim().toUpperCase()) {
      case 'LOAN':
        return 'Home Loan & Mortgage';
      case 'HOME_DESIGN':
        return 'Interior & Architectural Design';
      case 'VASTU':
        return 'Vastu Consultation';
      case 'CONSTRUCTION':
        return 'Construction & Renovation';
      case 'PROPERTY_VERIFICATION':
        return 'Legal & Title Verification';
      case 'VIRTUAL_3D':
        return '3D Modeling & Virtual Tours';
      default:
        return code.isNotEmpty ? code : 'Unassigned';
    }
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.headphones, color: AppTheme.primaryViolet, size: 22),
            const SizedBox(width: 10),
            Text(
              'Partner Support Desk',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For application review, account activation, or specialization updates, please reach out to our Partner Onboarding team:',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.mail, size: 16, color: AppTheme.primaryViolet),
                      const SizedBox(width: 8),
                      Text('partners@propzen.ai', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 16, color: AppTheme.primaryViolet),
                      const SizedBox(width: 8),
                      Text('+91 1800 212 9900 (Toll-Free)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = UserSession.currentServicePartnerProfile;
    final statusType = _resolveCurrentStatus(profile);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryViolet, Color(0xFF4F46E5)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.shield, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'PropZen Partner Portal',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _buildStatusCard(context, profile, statusType),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, ServicePartnerProfile? profile, ServicePartnerStatusType statusType) {
    switch (statusType) {
      case ServicePartnerStatusType.pending:
        return _buildPendingView(profile);
      case ServicePartnerStatusType.suspended:
        return _buildSuspendedView(profile);
      case ServicePartnerStatusType.rejected:
        return _buildRejectedView(profile);
      case ServicePartnerStatusType.missingSpecialization:
        return _buildMissingSpecializationView(profile);
    }
  }

  Widget _buildPendingView(ServicePartnerProfile? profile) {
    final businessName = profile?.businessName.isNotEmpty == true
        ? profile!.businessName
        : (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Service Partner');
    final categoryCode = profile?.serviceCategory ?? '';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pending Icon Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Center(
              child: Icon(LucideIcons.clock, size: 36, color: Color(0xFFD97706)),
            ),
          ),
          const SizedBox(height: 24),
          // Heading
          Text(
            'Your Service Partner application is under review.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Our compliance and onboarding team is actively verifying your credentials and business registration. You will receive full portal access and customer service requests once approved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Details summary box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Business Name', businessName, LucideIcons.building2),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _buildInfoRow('Applied Service', _formatCategoryLabel(categoryCode), LucideIcons.briefcase),
                const Divider(height: 16, color: Color(0xFFE2E8F0)),
                _buildInfoRow('Account Status', 'PENDING REVIEW', LucideIcons.shieldAlert, isBadge: true, badgeColor: const Color(0xFFD97706), badgeBg: const Color(0xFFFEF3C7)),
              ],
            ),
          ),

          if (_statusNotice != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusNotice!,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRefreshing ? null : _refreshStatus,
                  icon: _isRefreshing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(LucideIcons.refreshCw, size: 16),
                  label: Text(_isRefreshing ? 'Checking...' : 'Refresh Status'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryViolet),
                    foregroundColor: AppTheme.primaryViolet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showContactSupportDialog(context),
                  icon: const Icon(LucideIcons.headphones, size: 16),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              UserSession.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
            icon: const Icon(LucideIcons.logOut, size: 14, color: AppTheme.textSecondary),
            label: Text(
              'Sign out and return to Home',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspendedView(ServicePartnerProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF87171), width: 2),
            ),
            child: const Center(
              child: Icon(LucideIcons.alertOctagon, size: 36, color: Color(0xFFDC2626)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Service Partner account is currently suspended.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Access to customer service requests and partner portal tools has been temporarily paused. Please contact administrative support to resolve pending compliance or verification items.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _showContactSupportDialog(context),
            icon: const Icon(LucideIcons.headphones, size: 16),
            label: const Text('Contact Admin Support'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              UserSession.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: AppTheme.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedView(ServicePartnerProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: const Center(
              child: Icon(LucideIcons.xCircle, size: 36, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your application was not approved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We were unable to verify your partner credentials at this time. Please contact our onboarding support if you believe this was an error or wish to re-submit documentation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _showContactSupportDialog(context),
            icon: const Icon(LucideIcons.headphones, size: 16),
            label: const Text('Contact Admin Support'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              UserSession.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: AppTheme.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingSpecializationView(ServicePartnerProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: const [
          BoxShadow(color: Color(0x080F172A), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDBA74), width: 2),
            ),
            child: const Center(
              child: Icon(LucideIcons.helpCircle, size: 36, color: Color(0xFFEA580C)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your service specialization has not been assigned yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your partner profile is verified, but no specific service domain (Home Loan, Interior Design, Vastu, Construction, Legal Verification, or Virtual 3D Tours) is currently configured. Please complete your partner profile or contact an administrator.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showContactSupportDialog(context),
                  icon: const Icon(LucideIcons.headphones, size: 16),
                  label: const Text('Contact Admin'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFEA580C)),
                    foregroundColor: const Color(0xFFEA580C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.profile);
                  },
                  icon: const Icon(LucideIcons.userCheck, size: 16),
                  label: const Text('Complete Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              UserSession.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isBadge = false, Color? badgeColor, Color? badgeBg}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg ?? const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor ?? AppTheme.textPrimary),
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
          ),
      ],
    );
  }
}
