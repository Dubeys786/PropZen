import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../screens/user_profile_screen.dart';

/// Interactive modal allowing Buyers to register / upgrade to a PropZen Dealer / Broker
class BecomeDealerDialog extends StatefulWidget {
  final VoidCallback? onActivated;

  const BecomeDealerDialog({super.key, this.onActivated});

  static Future<void> show(BuildContext context, {VoidCallback? onActivated}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BecomeDealerDialog(onActivated: onActivated),
    );
  }

  @override
  State<BecomeDealerDialog> createState() => _BecomeDealerDialogState();
}

class _BecomeDealerDialogState extends State<BecomeDealerDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firmController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reraController = TextEditingController();
  final TextEditingController _marketController = TextEditingController();

  bool _agreedToTerms = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = UserSession.fullName.isNotEmpty ? UserSession.fullName : '';
    _phoneController.text = UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068';
    _firmController.text = 'PropZen Partner Realty';
    _reraController.text = 'HRERA-GGM-2024-884';
    _marketController.text = 'Golf Course Ext, Dwarka Exp, Sector 150';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firmController.dispose();
    _phoneController.dispose();
    _reraController.dispose();
    _marketController.dispose();
    super.dispose();
  }

  void _activateDealerAccount() {
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_firmController.text.trim().isNotEmpty ? _firmController.text.trim() : 'PropZen Dealer Partner');
    final phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '9810394068';

    UserSession.registerAsDealer(
      agencyName: name,
      phone: phone,
      reraNumber: _reraController.text.trim(),
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.clock, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 Application Submitted! Your Dealer credentials are under review by PropZen Admin.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF7C3AED),
        duration: const Duration(seconds: 4),
      ),
    );

    if (widget.onActivated != null) {
      widget.onActivated!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryViolet.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.briefcase, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Become a PropZen Dealer',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Join 500+ Top NCR Channel Partners & Brokers',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.primaryViolet,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Benefits Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(LucideIcons.sparkles, 'AI Listing Creator & Automated NCR Marketing'),
                    const SizedBox(height: 8),
                    _buildBenefitRow(LucideIcons.users, 'Direct High-Intent Buyer Leads & Site Tour Booking'),
                    const SizedBox(height: 8),
                    _buildBenefitRow(LucideIcons.shieldCheck, 'Safe Deal Rooms & Digital Negotiation Milestones'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Partner Details',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              // Form Fields
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Representative / Advisor Name',
                  prefixIcon: const Icon(LucideIcons.user, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _firmController,
                decoration: InputDecoration(
                  labelText: 'Agency / Brokerage Firm Name',
                  prefixIcon: const Icon(LucideIcons.building, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: const Icon(LucideIcons.phone, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _reraController,
                      decoration: InputDecoration(
                        labelText: 'RERA ID (Optional)',
                        prefixIcon: const Icon(LucideIcons.award, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _marketController,
                decoration: InputDecoration(
                  labelText: 'Focus Micro-Markets (e.g. Golf Course Ext, Noida 150)',
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppTheme.primaryViolet,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to PropZen Partner Terms & RERA ethical conduct code.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _activateDealerAccount,
                      icon: const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                      label: Text(
                        'Submit Application',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.primaryViolet),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
