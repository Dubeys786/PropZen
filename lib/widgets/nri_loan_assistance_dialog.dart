import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../screens/user_profile_screen.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// NRI Home Loan Assistance, Eligibility & Enquiry Dialog
class NriLoanAssistanceDialog extends StatefulWidget {
  final Property property;

  const NriLoanAssistanceDialog({
    super.key,
    required this.property,
  });

  static Future<void> show(BuildContext context, {required Property property}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NriLoanAssistanceDialog(property: property),
    );
  }

  @override
  State<NriLoanAssistanceDialog> createState() => _NriLoanAssistanceDialogState();
}

class _NriLoanAssistanceDialogState extends State<NriLoanAssistanceDialog> {
  final TextEditingController _nameController = TextEditingController(text: UserSession.fullName);
  final TextEditingController _emailController = TextEditingController(text: UserSession.email);
  final TextEditingController _phoneController = TextEditingController(text: UserSession.mobileNumber);
  final TextEditingController _countryController = TextEditingController(text: UserSession.userCountry.isNotEmpty ? UserSession.userCountry : 'United States');
  final TextEditingController _loanAmountController = TextEditingController();

  String _preferredBank = 'HDFC Bank (NRI Desk)';
  bool _isSubmitting = false;

  final List<String> _bankOptions = const [
    'HDFC Bank (NRI Desk)',
    'State Bank of India (SBI NRI Global)',
    'ICICI Bank NRI Services',
    'Axis Bank Overseas Hub',
    'Kotak Mahindra NRI Banking',
  ];

  @override
  void initState() {
    super.initState();
    final estimatedLoan = (widget.property.askingPriceCr * 10000000 * 0.8).round();
    _loanAmountController.text = estimatedLoan > 0 ? '₹${(estimatedLoan / 100000).toStringAsFixed(1)} Lakh' : '₹65 Lakh';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _loanAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.landmark, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NRI Home Loan Assistance',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.property.title,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eligibility Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NRI Loan Guidelines (RBI & FEMA Compliant)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 8),
                          _buildBullet('Up to 80-85% Loan to Value (LTV) on verified agreement value.'),
                          _buildBullet('Repayable via NRE / NRO bank accounts or overseas remittances.'),
                          _buildBullet('Tenure up to 30 years with fixed or floating interest rates starting at 8.4% p.a.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Required Checklist
                    Text('Required Documents for Overseas Processing', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    _buildDocCheck('Valid Indian Passport & Overseas Work Visa'),
                    _buildDocCheck('Last 6 Months Overseas Bank Statements'),
                    _buildDocCheck('Last 3 Months Salary Slips & HR Employment Letter'),
                    _buildDocCheck('NRE / NRO Account Proof & PAN Card Copy'),
                    _buildDocCheck('Allotment Letter / Agreement to Sell for this unit'),

                    const SizedBox(height: 20),

                    // Request Form
                    Text('Request Dedicated NRI Loan Manager', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),

                    _buildField(_nameController, 'Full Name', LucideIcons.user),
                    const SizedBox(height: 8),
                    _buildField(_emailController, 'Email Address', LucideIcons.mail),
                    const SizedBox(height: 8),
                    _buildField(_phoneController, 'WhatsApp / Phone with Country Code', LucideIcons.phone),
                    const SizedBox(height: 8),
                    _buildField(_countryController, 'Current Country of Employment', LucideIcons.globe),
                    const SizedBox(height: 8),
                    _buildField(_loanAmountController, 'Estimated Loan Amount Required', LucideIcons.indianRupee),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: DropdownButton<String>(
                        value: _preferredBank,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                        items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setState(() => _preferredBank = val!),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitLoanAssistance,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.send, size: 16, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Submitting Request...' : 'Connect with NRI Loan Desk',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildDocCheck(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.checkCheck, size: 14, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 15, color: AppTheme.primaryViolet),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  void _submitLoanAssistance() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your name and phone number.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SupabaseService.instance.addNotification(
        title: 'NRI Loan Desk Request Received 🏦',
        message: 'Your home loan advisory request for ${widget.property.title} with $_preferredBank is being assigned to an NRI specialist.',
        type: 'loan_assistance',
        propertyId: widget.property.id,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NRI Loan Request Submitted! A loan advisor will contact you on WhatsApp.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      setState(() => _isSubmitting = false);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
