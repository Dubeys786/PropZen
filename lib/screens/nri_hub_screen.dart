import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/nri_model.dart';
import '../services/currency_service.dart';
import '../services/nri_meeting_service.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class NriHubScreen extends StatefulWidget {
  const NriHubScreen({super.key});

  @override
  State<NriHubScreen> createState() => _NriHubScreenState();
}

class _NriHubScreenState extends State<NriHubScreen> {
  final CurrencyService _currencyService = CurrencyService.instance;
  final NriMeetingService _meetingService = NriMeetingService.instance;

  double _inputInrAmount = 15000000; // 1.5 Cr

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_currencyService, _meetingService]),
      builder: (context, _) {
        final rates = _currencyService.rates;
        final selectedCurrency = _currencyService.selectedCurrency;
        final meetings = _meetingService.meetings;
        final nriProperties = PropertyStateService.instance.allProperties.take(4).toList();

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: AppTheme.cardWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'NRI Property Hub & Global Concierge',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryViolet, AppTheme.primaryViolet.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Global NRI Desk', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.globe, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(selectedCurrency, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '100% remote property acquisition, legal title search, 360 drone walkthroughs, and repatriable NRI capital escrow support.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildNriFeatureBadge(LucideIcons.video, 'Live 360 Drone Tours'),
                          _buildNriFeatureBadge(LucideIcons.shieldCheck, 'FEMA / NRE Compliant'),
                          _buildNriFeatureBadge(LucideIcons.calendar, 'Cal.com Timezone Sync'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Real-Time Currency Converter
                Text('Dynamic Multi-Currency Price Converter', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Select Target Currency:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          DropdownButton<String>(
                            value: selectedCurrency,
                            underline: const SizedBox(),
                            items: rates.keys
                                .map((c) => DropdownMenuItem(value: c, child: Text('$c (${rates[c]!.name})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _currencyService.setCurrency(v);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Indian Rupees (INR):', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                          Text('₹${(_inputInrAmount / 10000000).toStringAsFixed(2)} Cr', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Estimated $selectedCurrency Equivalent:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                          Text(
                            _currencyService.formatConvertedPrice(_inputInrAmount, selectedCurrency),
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Exchange Rate: 1 $selectedCurrency = ₹${rates[selectedCurrency]?.inrRate.toStringAsFixed(2)} • Indicative interbank feed.',
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. Scheduled Time-Zone Aware Consultations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Scheduled Global Meetings', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    TextButton.icon(
                      icon: const Icon(LucideIcons.calendarPlus, size: 14),
                      label: const Text('Book Meeting', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Cal.com Time-Zone Aware Booking Widget...')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...meetings.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryViolet.withOpacity(0.08),
                            child: const Icon(LucideIcons.video, size: 18, color: AppTheme.primaryViolet),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.propertyTitle, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                const SizedBox(height: 2),
                                Text(m.meetingType.displayName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                                const SizedBox(height: 4),
                                Text('Timezone: ${m.attendeeTimezone}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                                Text('Scheduled: ${m.scheduledTimeUtc.day}/${m.scheduledTimeUtc.month}/${m.scheduledTimeUtc.year} at ${m.scheduledTimeUtc.hour}:${m.scheduledTimeUtc.minute.toString().padLeft(2, '0')} UTC', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emeraldSuccess,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () {
                              if (m.videoJoinUrl != null) launchUrl(Uri.parse(m.videoJoinUrl!));
                            },
                            child: const Text('Join Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 20),

                // 4. Curated Luxury NRI Properties
                Text('Featured NRI Verified Listings (with Multi-Currency)', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),

                ...nriProperties.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            p.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppTheme.surfaceSubtle),
                          ),
                        ),
                        title: Text(p.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('₹${p.askingPriceCr} Cr (${_currencyService.formatConvertedPrice(p.askingPriceCr * 10000000, selectedCurrency)})', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                            Text('${p.sector}, ${p.city} • 360 Drone Ready', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.propertyDetails, arguments: p);
                          },
                          child: const Text('View', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNriFeatureBadge(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}
