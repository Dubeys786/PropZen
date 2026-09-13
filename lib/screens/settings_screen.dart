import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'terms_privacy_screen.dart';
import 'legal_hub_screen.dart';
import 'admin_panel_screen.dart';
import 'user_profile_screen.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _priceDropAlerts = true;
  bool _siteVisitReminders = true;
  bool _whatsappUpdates = true;
  bool _biometricLogin = false;
  String _selectedCurrency = 'INR (₹)';
  String _selectedUnit = 'Sq. Ft.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Preferences
          _buildSectionHeader('Preferences'),
          _buildDropdownTile(
            icon: LucideIcons.indianRupee,
            title: 'Currency',
            value: _selectedCurrency,
            options: ['INR (₹)', 'USD (\$)', 'AED (د.إ)'],
            onChanged: (val) => setState(() => _selectedCurrency = val!),
          ),
          _buildDropdownTile(
            icon: LucideIcons.maximize2,
            title: 'Measurement Unit',
            value: _selectedUnit,
            options: ['Sq. Ft.', 'Sq. Yards', 'Sq. Meters', 'Acres'],
            onChanged: (val) => setState(() => _selectedUnit = val!),
          ),

          const SizedBox(height: 24),

          // Section 2: Notifications
          _buildSectionHeader('Notification Preferences'),
          _buildSwitchTile(
            icon: LucideIcons.tag,
            title: 'Price Drop Deals',
            subtitle: 'Get alerts when shortlisted properties drop price',
            value: _priceDropAlerts,
            onChanged: (val) => setState(() => _priceDropAlerts = val),
          ),
          _buildSwitchTile(
            icon: LucideIcons.calendarCheck,
            title: 'Site Visit Reminders',
            subtitle: 'Reminders 24h and 2h before your scheduled tour',
            value: _siteVisitReminders,
            onChanged: (val) => setState(() => _siteVisitReminders = val),
          ),
          _buildSwitchTile(
            icon: LucideIcons.messageCircle,
            title: 'WhatsApp Advisory Alerts',
            subtitle: 'Receive verification documents and replies via WhatsApp',
            value: _whatsappUpdates,
            onChanged: (val) => setState(() => _whatsappUpdates = val),
          ),

          const SizedBox(height: 24),

          // Section 3: Security & Privacy
          _buildSectionHeader('Security & Privacy'),
          _buildSwitchTile(
            icon: LucideIcons.fingerprint,
            title: 'Biometric / Fingerprint Unlock',
            subtitle: 'Require biometric authentication on app launch',
            value: _biometricLogin,
            onChanged: (val) => setState(() => _biometricLogin = val),
          ),
          // Section 3: Legal & Compliance Hub
          _buildSectionHeader('Legal & Compliance'),
          _buildNavigationTile(
            icon: LucideIcons.scale,
            title: 'Legal & Policies Hub (All 9 Policies)',
            onTap: () => LegalHubScreen.show(context),
          ),
          _buildNavigationTile(
            icon: LucideIcons.lock,
            title: 'Privacy Policy',
            onTap: () => LegalHubScreen.show(context, initialIndex: 0),
          ),
          _buildNavigationTile(
            icon: LucideIcons.fileText,
            title: 'Terms & Conditions',
            onTap: () => LegalHubScreen.show(context, initialIndex: 1),
          ),
          _buildNavigationTile(
            icon: LucideIcons.rotateCcw,
            title: 'Refund & Cancellation Policy',
            onTap: () => LegalHubScreen.show(context, initialIndex: 2),
          ),
          _buildNavigationTile(
            icon: LucideIcons.creditCard,
            title: 'Subscription Terms',
            onTap: () => LegalHubScreen.show(context, initialIndex: 3),
          ),
          _buildNavigationTile(
            icon: LucideIcons.shieldAlert,
            title: 'Property Verification Disclaimer',
            onTap: () => LegalHubScreen.show(context, initialIndex: 4),
          ),
          _buildNavigationTile(
            icon: LucideIcons.briefcase,
            title: 'Dealer Terms & Code of Conduct',
            onTap: () => LegalHubScreen.show(context, initialIndex: 5),
          ),
          _buildNavigationTile(
            icon: LucideIcons.video,
            title: 'Drone Tour Terms',
            onTap: () => LegalHubScreen.show(context, initialIndex: 6),
          ),
          _buildNavigationTile(
            icon: LucideIcons.userCheck,
            title: 'Service Partner Terms',
            onTap: () => LegalHubScreen.show(context, initialIndex: 7),
          ),
          _buildNavigationTile(
            icon: LucideIcons.helpCircle,
            title: 'Contact & Grievance Officer',
            onTap: () => LegalHubScreen.show(context, initialIndex: 8),
          ),

          const SizedBox(height: 24),

          // Section 4: Account Actions & Security
          _buildSectionHeader('Account Actions & Administration'),
          _buildNavigationTile(
            icon: LucideIcons.trash2,
            title: 'Delete Account & Erase Personal Data',
            isDestructive: true,
            onTap: () => _promptDeleteAccountDialog(context),
          ),
          if (UserSession.isAdmin)
            _buildNavigationTile(
              icon: LucideIcons.shieldAlert,
              title: 'Admin Console (Restricted)',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AdminPanelScreen()),
              ),
            ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'PropZen v2.4.0 (Build 2026) • All Rights Reserved',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryViolet, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primaryViolet,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryViolet, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: Colors.white,
            underline: const SizedBox.shrink(),
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet, fontWeight: FontWeight.bold),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: GoogleFonts.inter(color: AppTheme.textPrimary)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDestructive ? const Color(0xFFFCA5A5) : AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.red : AppTheme.primaryViolet, size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : AppTheme.textPrimary,
          ),
        ),
        trailing: Icon(LucideIcons.chevronRight, size: 16, color: isDestructive ? Colors.red : AppTheme.textHint),
      ),
    );
  }

  void _promptDeleteAccountDialog(BuildContext context) {
    final confirmationController = TextEditingController();
    String selectedReason = 'No longer looking for property';
    bool isDeleting = false;
    String? errorMessage;

    final reasons = [
      'No longer looking for property',
      'Found property on PropZen',
      'Found property elsewhere',
      'Privacy and data concerns',
      'Creating a new account',
      'Other reason',
    ];

    showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permanently delete your PropZen profile and erase all associated records?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What will be permanently wiped:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBulletPoint('Your profile details and verified phone/email credentials'),
                        _buildBulletPoint('All saved favorite properties and comparison matrices'),
                        _buildBulletPoint('Scheduled site visits and dealer enquiry records'),
                        _buildBulletPoint('Active subscription access and AI chat conversation history'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Reason for leaving (optional):',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                        items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDlgState(() => selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Type "DELETE" below to confirm:',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmationController,
                    autofocus: false,
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      errorText: errorMessage,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(dlgCtx).pop(),
                child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        final entered = confirmationController.text.trim().toUpperCase();
                        if (entered != 'DELETE') {
                          setDlgState(() => errorMessage = 'Please type "DELETE" to confirm');
                          return;
                        }

                        setDlgState(() {
                          isDeleting = true;
                          errorMessage = null;
                        });

                        final userEmail = UserSession.email;
                        final userPhone = UserSession.phone;

                        // 1. Call Backend Deletion & Logging
                        await SupabaseService.instance.deleteUserAccountPermanently(
                          email: userEmail,
                          phone: userPhone,
                          reason: selectedReason,
                        );

                        // 2. Wipe Local Session & Log Out
                        UserSession.clearSession();

                        if (context.mounted) {
                          Navigator.of(dlgCtx).pop();
                          Navigator.of(context).popUntil((route) => route.isFirst);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your account and personal data have been permanently deleted.'),
                              backgroundColor: Color(0xFFDC2626),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Permanently Delete',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7F1D1D), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
