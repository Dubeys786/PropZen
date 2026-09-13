import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/nri_subscription_service.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_theme.dart';

/// Interactive Modal Dialog to Request an NRI Remote Property Tour
class NriRemoteTourDialog extends StatefulWidget {
  final Property property;

  const NriRemoteTourDialog({
    super.key,
    required this.property,
  });

  static Future<void> show(BuildContext context, {required Property property}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NriRemoteTourDialog(property: property),
    );
  }

  @override
  State<NriRemoteTourDialog> createState() => _NriRemoteTourDialogState();
}

class _NriRemoteTourDialogState extends State<NriRemoteTourDialog> {
  String _selectedTourType = 'live_video_walkthrough';
  String _selectedTimezone = 'EST (New York / GMT-5)';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '08:00 PM IST (09:30 AM EST)';

  final TextEditingController _nameController = TextEditingController(text: UserSession.fullName);
  final TextEditingController _emailController = TextEditingController(text: UserSession.email);
  final TextEditingController _phoneController = TextEditingController(text: UserSession.mobileNumber);
  final TextEditingController _countryController = TextEditingController(text: UserSession.userCountry.isNotEmpty ? UserSession.userCountry : 'United States');
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  final List<Map<String, String>> _timezones = const [
    {'code': 'EST', 'name': 'EST (New York / Toronto - GMT-5)'},
    {'code': 'PST', 'name': 'PST (San Francisco / Vancouver - GMT-8)'},
    {'code': 'CST', 'name': 'CST (Chicago / Houston - GMT-6)'},
    {'code': 'GMT', 'name': 'GMT / BST (London - GMT+0/+1)'},
    {'code': 'GST', 'name': 'GST (Dubai / Abu Dhabi - GMT+4)'},
    {'code': 'SGT', 'name': 'SGT (Singapore / Hong Kong - GMT+8)'},
    {'code': 'AEST', 'name': 'AEST (Sydney / Melbourne - GMT+10)'},
    {'code': 'IST', 'name': 'IST (India Standard Time - GMT+5:30)'},
  ];

  final List<String> _timeSlots = const [
    '07:00 PM IST (Evening India / Morning US)',
    '08:30 PM IST (Evening India / Midday US)',
    '10:00 PM IST (Late Night India / Afternoon US)',
    '11:30 AM IST (Morning India / Evening US)',
    '03:00 PM IST (Afternoon India / Morning Europe/Gulf)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
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
                    child: const Icon(LucideIcons.video, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Remote Property Tour',
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

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tour Type Radio Selector
                    Text(
                      'Select Remote Tour Format',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _buildTourTypeRadio(
                      id: 'live_video_walkthrough',
                      title: 'Live 1-on-1 Video Walkthrough',
                      subtitle: 'Property specialist walks through the unit live with real-time video.',
                      icon: LucideIcons.video,
                    ),
                    const SizedBox(height: 8),
                    _buildTourTypeRadio(
                      id: 'dealer_assisted_tour',
                      title: 'Dealer-Assisted Virtual Session',
                      subtitle: 'Shared screen exploration of 3D models, drone telemetry, and floor plans.',
                      icon: LucideIcons.users,
                    ),
                    const SizedBox(height: 8),
                    _buildTourTypeRadio(
                      id: 'scheduled_virtual_visit',
                      title: 'Interactive 360° Guided Tour',
                      subtitle: 'Scheduled walkthrough of high-res panoramas and locality buffer views.',
                      icon: LucideIcons.compass,
                    ),

                    const SizedBox(height: 20),

                    // Timezone & Date
                    Text(
                      'Preferred Date & Timezone',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTimezone,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                        items: _timezones.map((tz) => DropdownMenuItem(value: tz['name'], child: Text(tz['name']!))).toList(),
                        onChanged: (val) => setState(() => _selectedTimezone = val!),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTimeSlot,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
                        items: _timeSlots.map((ts) => DropdownMenuItem(value: ts, child: Text(ts))).toList(),
                        onChanged: (val) => setState(() => _selectedTimeSlot = val!),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Details
                    Text(
                      'Your Contact Information',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(_nameController, 'Full Name', LucideIcons.user),
                    const SizedBox(height: 8),
                    _buildTextField(_emailController, 'Email Address', LucideIcons.mail),
                    const SizedBox(height: 8),
                    _buildTextField(_phoneController, 'WhatsApp / Mobile Number', LucideIcons.phone),
                    const SizedBox(height: 8),
                    _buildTextField(_countryController, 'Current Country of Residence', LucideIcons.globe),
                    const SizedBox(height: 8),
                    _buildTextField(_notesController, 'Special Questions / Requirements (Optional)', LucideIcons.fileText, maxLines: 2),
                  ],
                ),
              ),
            ),

            // Modal Footer CTA
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitRemoteTour,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(LucideIcons.checkCheck, size: 16, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Confirming Remote Tour...' : 'Schedule Remote Property Tour',
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

  Widget _buildTourTypeRadio({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedTourType == id;

    return InkWell(
      onTap: () => setState(() => _selectedTourType = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.primaryViolet : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 16,
              color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint),
          prefixIcon: Icon(icon, size: 15, color: AppTheme.primaryViolet),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  void _submitRemoteTour() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your name, email, and phone number.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

      await NriSubscriptionService.instance.bookRemoteTour(
        propertyId: widget.property.id,
        propertyTitle: widget.property.title,
        tourType: _selectedTourType,
        preferredDate: dateStr,
        preferredTime: _selectedTimeSlot,
        timezone: _selectedTimezone,
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        userPhone: _phoneController.text.trim(),
        userCountry: _countryController.text.trim(),
        notes: _notesController.text.trim(),
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Remote Property Tour Confirmed for ${widget.property.title}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking tour: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
