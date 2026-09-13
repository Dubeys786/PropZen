import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/n8n_service.dart';
import '../services/site_visit_booking_service.dart';
import '../theme/app_theme.dart';
import 'my_site_visits_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/enquiry_auth_dialog.dart';

class SiteVisitBookingScreen extends StatefulWidget {
  final Property? property;

  const SiteVisitBookingScreen({super.key, this.property});

  @override
  State<SiteVisitBookingScreen> createState() => _SiteVisitBookingScreenState();
}

class _SiteVisitBookingScreenState extends State<SiteVisitBookingScreen> {
  late Property _selectedProperty;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  String _selectedTime = '11:00 AM';
  int _visitorCount = 1;
  bool _cabRequired = false;
  bool _isSubmitting = false;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _messageController;

  final List<String> _timeSlots = [
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '04:30 PM',
  ];

  @override
  void initState() {
    super.initState();
    final all = PropertyStateService.instance.allProperties;
    _selectedProperty = widget.property ??
        (all.isNotEmpty
            ? all.first
            : const Property(
                id: 'PROP-DEFAULT',
                title: 'Propzen Verified Listing',
                sector: 'Sector 150',
                city: 'Noida',
                category: 'Residential',
                propertyType: 'Apartment',
                askingPriceCr: 1.5,
                fairValueCr: 1.55,
                pricePerSqft: 9090,
                score10x: 9.2,
                rentalYieldPercent: 4.2,
                sqft: 1650,
                bhk: '3 BHK',
                imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
                possessionDate: 'Ready to Move',
                isVerified: true,
                rating: 4.8,
                reviewCount: 42,
                dealerPhone: '+91 98103 94068',
                description: 'Exclusive luxury residential project.',
                amenities: ['Club House', 'Gym', 'Swimming Pool'],
                nearby: {'Metro': '500m'},
                statusTag: 'Verified',
                reraId: 'UPRERAPRJ998877',
                builderName: 'Propzen Verified Developers',
                facing: 'East',
                furnishing: 'Semi-Furnished',
                availability: 'Immediate',
                intelligenceScore: 92,
                investmentScore: 90,
              ));

    _nameController = TextEditingController(text: UserSession.fullName);
    _phoneController = TextEditingController(text: UserSession.mobileNumber);
    _emailController = TextEditingController(text: UserSession.email);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatIsoDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _onConfirmBooking() async {
    if (!UserSession.isLoggedIn || !UserSession.isEmailVerified) {
      EnquiryAuthDialog.show(
        context,
        actionLabel: 'Book a Site Visit',
        onSuccess: () {
          setState(() {
            _nameController.text = UserSession.fullName;
            _phoneController.text = UserSession.mobileNumber;
            _emailController.text = UserSession.email;
          });
          _onConfirmBooking();
        },
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();

    if (_visitorCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 1 visitor is required.'),
          backgroundColor: AppTheme.coralDanger,
        ),
      );
      return;
    }

    if (_selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your preferred visit date and time.'),
          backgroundColor: AppTheme.coralDanger,
        ),
      );
      return;
    }

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name and phone number.'),
          backgroundColor: AppTheme.coralDanger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dateIso = _formatIsoDate(_selectedDate);
    final dateDisplay = _formatDate(_selectedDate);

    // Centralized Site Visit Booking Service
    final bookingResult = await SiteVisitBookingService.instance.bookSiteVisit(
      propertyId: _selectedProperty.id,
      propertyTitle: _selectedProperty.title,
      sector: _selectedProperty.sector,
      priceDisplay: _selectedProperty.formattedPrice,
      visitDate: dateIso,
      timeSlot: _selectedTime,
      visitorCount: _visitorCount,
      cabRequired: _cabRequired,
      clientName: name,
      clientPhone: phone,
      clientEmail: email,
      message: message,
      source: 'PropZen Web App Portal',
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (bookingResult.isSuccess || bookingResult.isDuplicate) {
      _showSuccessDialog(dateDisplay);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bookingResult.message,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.coralDanger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog(String dateDisplay) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryViolet, width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.emeraldSuccess,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Site Visit Requested Successfully',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow(LucideIcons.building, 'Property:', _selectedProperty.title, isBold: true),
                    const SizedBox(height: 8),
                    _buildSummaryRow(LucideIcons.calendar, 'Date:', dateDisplay),
                    const SizedBox(height: 8),
                    _buildSummaryRow(LucideIcons.clock, 'Time:', _selectedTime),
                    const SizedBox(height: 8),
                    _buildSummaryRow(LucideIcons.users, 'Visitors:', '$_visitorCount ${_visitorCount == 1 ? "Visitor" : "Visitors"}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      _cabRequired ? LucideIcons.car : LucideIcons.ban,
                      'Cab:',
                      _cabRequired ? 'Required (🚕 Cab Required)' : 'Not Required (🚫 Cab Not Required)',
                      textColor: _cabRequired ? const Color(0xFFD97706) : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      LucideIcons.clock4,
                      'Status:',
                      'Pending Confirmation',
                      textColor: const Color(0xFFD97706),
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'A dedicated property manager will contact you on ${_phoneController.text} to confirm your appointment.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Back to Property'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MySiteVisitsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('View My Site Visits'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {bool isBold = false, Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: textColor ?? AppTheme.primaryViolet),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: textColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Book a Site Visit',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 20,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE SINGLE-COLUMN LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPropertyCard(),
        const SizedBox(height: 20),
        _buildDateSection(),
        const SizedBox(height: 20),
        _buildTimeSection(),
        const SizedBox(height: 20),
        _buildVisitorCountSection(),
        const SizedBox(height: 20),
        _buildCabRequiredSection(),
        const SizedBox(height: 24),
        _buildContactInfoSection(),
        const SizedBox(height: 24),
        _buildLiveSummaryCard(),
        const SizedBox(height: 28),
        _buildSubmitButton(),
        const SizedBox(height: 30),
      ],
    );
  }

  // ===========================================================================
  // DESKTOP TWO-COLUMN RESPONSIVE LAYOUT
  // ===========================================================================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Property Card & Live Summary Card (Sticky Preview)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyCard(),
              const SizedBox(height: 20),
              _buildLiveSummaryCard(),
            ],
          ),
        ),
        const SizedBox(width: 28),
        // Right Column: Interactive Schedule & Personal Info Form
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSection(),
                const SizedBox(height: 20),
                _buildTimeSection(),
                const SizedBox(height: 20),
                _buildVisitorCountSection(),
                const SizedBox(height: 20),
                _buildCabRequiredSection(),
                const SizedBox(height: 24),
                _buildContactInfoSection(),
                const SizedBox(height: 28),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION WIDGETS
  // ===========================================================================

  Widget _buildPropertyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _selectedProperty.dynamicImageUrl,
              width: 90,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (ctx, e, st) => Container(
                width: 90,
                height: 80,
                color: AppTheme.surfaceHighlight,
                child: const Icon(LucideIcons.building, color: AppTheme.primaryViolet, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SELECTED PROPERTY',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedProperty.title,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_selectedProperty.effectiveLocality}, ${_selectedProperty.city}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedProperty.formattedPrice,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.calendar, size: 16, color: AppTheme.primaryViolet),
            const SizedBox(width: 8),
            Text(
              'Preferred Date',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: 330,
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                onDateChanged: (newDate) => setState(() => _selectedDate = newDate),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.clock, size: 16, color: AppTheme.primaryViolet),
            const SizedBox(width: 8),
            Text(
              'Preferred Time Slot',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 24) / 4;
            final isCompact = itemWidth < 68;

            if (isCompact) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((time) {
                  final isSel = _selectedTime == time;
                  return InkWell(
                    onTap: () => setState(() => _selectedTime = time),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primaryViolet : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? AppTheme.primaryViolet : AppTheme.borderLight,
                          width: isSel ? 1.5 : 1.0,
                        ),
                        boxShadow: isSel ? AppTheme.softCardShadow : AppTheme.subtleCardShadow,
                      ),
                      child: Text(
                        time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            return Row(
              children: _timeSlots.map((time) {
                final isSel = _selectedTime == time;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _selectedTime = time),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.primaryViolet : AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? AppTheme.primaryViolet : AppTheme.borderLight,
                            width: isSel ? 1.5 : 1.0,
                          ),
                          boxShadow: isSel ? AppTheme.softCardShadow : AppTheme.subtleCardShadow,
                        ),
                        child: Center(
                          child: Text(
                            time,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVisitorCountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(LucideIcons.users, size: 16, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Number of Visitors',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Max 10 visitors',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$_visitorCount ${_visitorCount == 1 ? "person" : "people"} attending',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Stepper Control: [ − ]   1   [ + ]
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: AppTheme.subtleCardShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.minus, size: 16),
                      color: _visitorCount > 1 ? AppTheme.primaryViolet : Colors.grey.shade400,
                      onPressed: _visitorCount > 1
                          ? () => setState(() => _visitorCount--)
                          : null,
                      tooltip: 'Decrease visitors',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_visitorCount',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryViolet,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.plus, size: 16),
                      color: _visitorCount < 10 ? AppTheme.primaryViolet : Colors.grey.shade400,
                      onPressed: _visitorCount < 10
                          ? () => setState(() => _visitorCount++)
                          : null,
                      tooltip: 'Increase visitors',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCabRequiredSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(LucideIcons.car, size: 16, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Cab Required?',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Free pickup',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              // YES Option
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _cabRequired = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _cabRequired ? AppTheme.primaryViolet : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _cabRequired ? AppTheme.subtleCardShadow : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.car,
                          size: 15,
                          color: _cabRequired ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Yes',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _cabRequired ? FontWeight.bold : FontWeight.w500,
                            color: _cabRequired ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // NO Option
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _cabRequired = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_cabRequired ? AppTheme.primaryViolet : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: !_cabRequired ? AppTheme.subtleCardShadow : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.x,
                          size: 15,
                          color: !_cabRequired ? Colors.white : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: !_cabRequired ? FontWeight.bold : FontWeight.w500,
                            color: !_cabRequired ? Colors.white : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.userCheck, size: 16, color: AppTheme.primaryViolet),
            const SizedBox(width: 8),
            Text(
              'Your Contact Details',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(LucideIcons.user, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            hintText: 'Enter 10-digit mobile number',
            prefixIcon: const Icon(LucideIcons.phone, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter email address',
            prefixIcon: const Icon(LucideIcons.mail, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          style: GoogleFonts.inter(color: AppTheme.textPrimary),
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Additional Message (Optional)',
            hintText: 'e.g. Need assistance with wheelchair or specific parking instructions',
            prefixIcon: const Icon(LucideIcons.messageSquare, size: 18),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveSummaryCard() {
    final dateDisplay = _formatDate(_selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.25), width: 1.2),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.clipboardList, size: 16, color: AppTheme.primaryViolet),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Site Visit Summary',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          _buildSummaryItem('Property:', _selectedProperty.title, isBold: true),
          const SizedBox(height: 6),
          _buildSummaryItem('Date:', dateDisplay),
          const SizedBox(height: 6),
          _buildSummaryItem('Time:', _selectedTime),
          const SizedBox(height: 6),
          _buildSummaryItem('Visitors:', '$_visitorCount ${_visitorCount == 1 ? "Visitor" : "Visitors"}'),
          const SizedBox(height: 6),
          _buildSummaryItem(
            'Cab Required:',
            _cabRequired ? 'Yes (🚕 Cab Required)' : 'No (🚫 Cab Not Required)',
            badgeColor: _cabRequired ? const Color(0xFF10B981) : AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isBold = false, Color? badgeColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: badgeColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _onConfirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryViolet,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendarCheck, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Confirm Site Visit',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
