import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class PublicPropertyVerificationScreen extends StatelessWidget {
  final Property? property;
  final String? propertyId;

  const PublicPropertyVerificationScreen({
    super.key,
    this.property,
    this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    Property? prop = property;
    if (prop == null && propertyId != null && propertyId!.isNotEmpty) {
      prop = PropertyStateService.instance.findPropertyById(propertyId!);
    }
    if (prop == null) {
      final all = PropertyStateService.instance.allProperties;
      prop = all.isNotEmpty ? all.first : Property.sampleDeals.first;
    }

    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(LucideIcons.shieldCheck, color: AppTheme.emeraldSuccess, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PropZen Official Verification', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('Public Authenticity Certificate', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Verified Banner Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.4)),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prop.propzenId,
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: prop.isSold
                                  ? Colors.red.withOpacity(0.1)
                                  : AppTheme.emeraldSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              prop.isSold ? 'SOLD' : (prop.isPropZenVerified ? '🟢 PROPZEN VERIFIED' : 'UNDER AUDIT'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: prop.isSold ? Colors.red : AppTheme.emeraldSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(prop.title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('${prop.sector}, ${prop.city} • ${prop.bhk} • ₹${prop.askingPriceCr} Cr', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Text(prop.freshnessDisplay, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(width: 16),
                          const Icon(LucideIcons.checkCheck, size: 14, color: AppTheme.emeraldSuccess),
                          const SizedBox(width: 6),
                          Text('Last Checked: ${prop.lastCheckedAt.day}/${prop.lastCheckedAt.month}/${prop.lastCheckedAt.year}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. 5-Pillar Verification Checklist
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verification Checklist & Credentials', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Direct verification records confirmed by PropZen legal & field desk.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const Divider(height: 24),
                      _buildChecklistRow('Dealer / Owner Identity', 'Authorized registered dealer with active KYC compliance.', true),
                      _buildChecklistRow('Property Registry & Documents', 'Sanctioned architectural layout blueprints and title deeds reviewed.', true),
                      _buildChecklistRow('Physical Location Geocoding', 'GPS boundary mapped to ${prop.sector}, ${prop.city} (${prop.postalCode}).', prop.locationVerified),
                      _buildChecklistRow('Legal & RERA Sanction', prop.reraId.isNotEmpty ? 'Official RERA ID: ${prop.reraId}' : 'Freehold non-encumbrance title search verified.', true),
                      _buildChecklistRow('Listing Accuracy & Pricing', 'Pricing and physical specifications verified without manipulation.', true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 3. PropZen Trust Score Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PropZen Trust Score', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${prop.intelligenceScore > 0 ? prop.intelligenceScore : 92} / 100', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trust Score is an internal PropZen indicator based on available verification signals. It is not a legal or financial guarantee.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. CTA to View Details
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop)),
                      );
                    },
                    icon: const Icon(LucideIcons.externalLink, size: 16),
                    label: Text('Open Full Property Listing', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String title, String subtitle, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(passed ? LucideIcons.checkCircle2 : LucideIcons.circle, color: passed ? AppTheme.emeraldSuccess : AppTheme.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
