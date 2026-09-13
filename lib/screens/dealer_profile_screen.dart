import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dealer.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/enquiry_auth_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/property_card.dart';
import 'property_details_screen.dart';
import 'user_profile_screen.dart';

class DealerProfileScreen extends StatefulWidget {
  final Dealer? dealer;

  const DealerProfileScreen({super.key, this.dealer});

  @override
  State<DealerProfileScreen> createState() => _DealerProfileScreenState();
}

class _DealerProfileScreenState extends State<DealerProfileScreen> {
  late final Dealer _dealer;

  @override
  void initState() {
    super.initState();
    _dealer = widget.dealer ??
        Dealer(
          id: 'dlr_current',
          name: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Partner',
          agency: 'PropZen Premier Associates',
          photoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
          reraNumber: 'UPRERAAGT12984',
          experienceYears: 8,
          location: 'Sector 150, Noida',
          city: 'Noida',
          areasServed: const ['Sector 150', 'Yamuna Expressway', 'Noida Extension'],
          activeListingsCount: PropertyStateService.instance.dealerProperties.length,
          rating: 4.9,
          reviewCount: 42,
          specialization: 'Luxury High-Rise & RERA Plots',
        );
  }

  void _openWhatsApp() {
    EnquiryAuthDialog.show(
      context,
      actionLabel: 'WhatsApp Dealer ${_dealer.name}',
      onSuccess: () async {
        PropertyStateService.instance.addEnquiry('Dealer: ${_dealer.name}', 'WhatsApp Dealer Chat');
        final text = Uri.encodeComponent('Hi ${_dealer.name}! I found your profile on PropZen. I am looking for property assistance in ${_dealer.location}.');
        final rawPhone = _dealer.phone.replaceAll(RegExp(r'[^0-9]'), '');
        final cleanPhone = rawPhone.isNotEmpty ? rawPhone : '919810394068';
        final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }

  void _makeCall() {
    EnquiryAuthDialog.show(
      context,
      actionLabel: 'Call Dealer ${_dealer.name}',
      onSuccess: () async {
        PropertyStateService.instance.addEnquiry('Dealer: ${_dealer.name}', 'Phone Call to Dealer');
        final uri = Uri.parse('tel:${_dealer.phone.isNotEmpty ? _dealer.phone : "+919810394068"}');
        await launchUrl(uri);
      },
    );
  }

  void _showMeetingModal() {
    String meetingType = 'Property Visit';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedTimeSlot = '11:00 AM - 12:00 PM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🤝 Schedule Dealer Meeting',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                  Text('With ${_dealer.name} • ${_dealer.agency}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                  const Divider(height: 24),

                  // Meeting Type
                  Text('1. Select Meeting Type', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Property Visit', 'Office Meeting', 'Video Call'].map((type) {
                      final isSel = meetingType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSel,
                        selectedColor: const Color(0xFFD32F2F),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                        onSelected: (val) {
                          if (val) setModalState(() => meetingType = type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Text('2. Select Date', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          const Icon(LucideIcons.calendar, size: 18, color: Color(0xFFD32F2F)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
                        PropertyStateService.instance.addScheduledVisit(
                          propertyId: 'DEALER-${_dealer.id}',
                          propertyTitle: '$meetingType with ${_dealer.name}',
                          sector: _dealer.location,
                          date: dateStr,
                          time: selectedTimeSlot,
                          name: UserSession.fullNameNotifier.value.isNotEmpty ? UserSession.fullNameNotifier.value : 'Verified User',
                          phone: UserSession.mobileNumberNotifier.value.isNotEmpty ? UserSession.mobileNumberNotifier.value : 'Contact Pending',
                        );

                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Row(
                              children: [
                                Icon(LucideIcons.checkCircle2, color: Colors.green, size: 24),
                                SizedBox(width: 8),
                                Text('Meeting Confirmed!'),
                              ],
                            ),
                            content: Text(
                              '$meetingType confirmed with ${_dealer.name} on $dateStr at $selectedTimeSlot.\n\nConfirmation details sent to your phone.',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK', style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold))),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                      child: Text('Confirm Meeting Schedule', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dealer = _dealer;
    final dealerProps = Property.sampleDeals.where((p) => p.city.toLowerCase() == dealer.city.toLowerCase() || p.sector.contains(dealer.city)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Dealer Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dealer Header Card
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 85,
                          height: 85,
                          child: Image.network(
                            dealer.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800, child: const Icon(LucideIcons.user, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(dealer.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.checkCircle2, color: Colors.blue, size: 16),
                              ],
                            ),
                            Text(dealer.agency, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text(dealer.reraNumber, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${dealer.rating} (${dealer.reviewCount} Reviews)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('${dealer.experienceYears}+ Yrs', 'Experience'),
                      _buildHeaderStat('${dealer.activeListingsCount}', 'Active Listings'),
                      _buildHeaderStat('${dealer.intelligenceScore}/100', 'Dealer Score'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dealer Badges (Req #26)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dealer.badges.map((b) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.award, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(b, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Verification Information (Req #17)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VERIFICATION CHECKLIST', style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  const SizedBox(height: 10),
                  _buildVerificationRow('Identity Verified', dealer.identityVerified),
                  _buildVerificationRow('RERA Business License Verified', dealer.businessVerified),
                  _buildVerificationRow('Phone & WhatsApp Contact Verified', dealer.contactVerified),
                  _buildVerificationRow('Property Registry Audit Verified', dealer.listingsVerified),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dealer Intelligence Score & Response Metrics (Req #18)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Dealer Intelligence Score', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(12)),
                        child: Text('${dealer.intelligenceScore} / 100', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricCol('Response Rate', '${dealer.responseRatePercent}%'),
                      _buildMetricCol('Response Time', dealer.responseTimeStr),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Properties by this Dealer (Req #16)
            Text('🏠 Active Listings by ${dealer.name}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(dealerProps.isEmpty ? Property.sampleDeals.take(2) : dealerProps).map((p) {
              return PropertyCard(
                property: p,
                onTapReport: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => PropertyDetailsScreen(property: p)));
                },
                onTapPhotos: () {},
              );
            }).toList(),
            const SizedBox(height: 16),

            // Customer Reviews (Req #19)
            Text('⭐ Customer Reviews', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...dealer.reviews.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r['user'] as String, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('★ ${r['rating']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r['comment'] as String, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),

      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              InkWell(
                onTap: _makeCall,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.phone, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openWhatsApp,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.messageSquare, color: Colors.black, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showMeetingModal,
                  icon: const Icon(LucideIcons.calendar, color: Colors.white, size: 18),
                  label: Text('Book Meeting / Visit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFD32F2F))),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMetricCol(String label, String val) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildVerificationRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)),
          Row(
            children: [
              Icon(isOk ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle, size: 14, color: isOk ? Colors.green : Colors.amber),
              const SizedBox(width: 4),
              Text(isOk ? 'Verified ✓' : 'Pending', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isOk ? Colors.green.shade800 : Colors.amber.shade900)),
            ],
          ),
        ],
      ),
    );
  }
}
