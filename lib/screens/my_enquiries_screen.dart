import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';

class MyEnquiriesScreen extends StatelessWidget {
  const MyEnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stateService = PropertyStateService.instance;

    return AnimatedBuilder(
      animation: stateService,
      builder: (context, _) {
        final enquiries = stateService.leads;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              'My Enquiries',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
          ),
          body: enquiries.isEmpty
              ? const Center(
                  child: EmptyStateView(
                    title: 'No enquiries yet',
                    message: 'Enquire on any property to track dealer responses and updates here.',
                    icon: LucideIcons.messageSquareDashed,
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: enquiries.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final enq = enquiries[i];
                    final status = enq['status'] as String? ?? 'New';

                    Color statusColor = AppTheme.primaryViolet;
                    if (status == 'Site Visit' || status == 'Converted') {
                      statusColor = AppTheme.emeraldSuccess;
                    } else if (status == 'Contacted' || status == 'Interested') {
                      statusColor = const Color(0xFF0284C7);
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: AppTheme.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  enq['propertyTitle'] as String? ?? 'Property Enquiry',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            enq['message'] as String? ?? 'Inquiry submitted.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submitted: ${enq['date'] ?? ''}',
                                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.phone, size: 16, color: AppTheme.primaryViolet),
                                    onPressed: () {
                                      final phone = enq['phone'] ?? '';
                                      if (phone.isNotEmpty) {
                                        launchUrl(Uri.parse('tel:$phone'));
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.messageCircle, size: 16, color: Color(0xFF25D366)),
                                    onPressed: () {
                                      final phone = (enq['phone'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                                      if (phone.isNotEmpty) {
                                        launchUrl(Uri.parse('https://wa.me/$phone'));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
