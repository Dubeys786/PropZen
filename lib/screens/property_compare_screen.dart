import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';

class PropertyCompareScreen extends StatelessWidget {
  const PropertyCompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PropertyStateService.instance,
      builder: (context, _) {
        final comparedProps = PropertyStateService.instance.comparedProperties;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(
              '⚖️ Property Comparison (${comparedProps.length})',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
            actions: [
              if (comparedProps.isNotEmpty)
                TextButton(
                  onPressed: () {
                    PropertyStateService.instance.clearCompare(clearBackend: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compare list cleared')),
                    );
                  },
                  child: const Text('Clear All', style: TextStyle(color: AppTheme.coralDanger, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          body: comparedProps.isEmpty
              ? const Center(
                  child: EmptyStateView(
                    title: 'No properties added to compare',
                    message: 'Add properties to perform side-by-side institutional analysis of valuation, BHK, pricing, and yield.',
                    icon: LucideIcons.scale,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: AppTheme.softCardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.scale, color: AppTheme.primaryViolet, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Comparing ${comparedProps.length} Properties',
                                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  Text(
                                    'Institutional side-by-side analysis of valuation, layout, yield & intelligence scores.',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Comparison Table Horizontal Scroll Container
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Container(
                          width: 180 + (comparedProps.length * 170.0),
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderLight),
                            boxShadow: AppTheme.softCardShadow,
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row with Property Thumbnails
                              Row(
                                children: [
                                  SizedBox(
                                    width: 160,
                                    child: Text('Property', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                  ),
                                  ...comparedProps.map((p) {
                                    return SizedBox(
                                      width: 170,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: SizedBox(
                                                height: 90,
                                                width: double.infinity,
                                                child: Image.network(
                                                  p.dynamicImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => Container(
                                                    color: AppTheme.surfaceHighlight,
                                                    child: const Icon(LucideIcons.image, color: AppTheme.textHint),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              p.title,
                                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                              const Divider(height: 24, color: AppTheme.borderLight),

                              // Metric Rows
                              _buildRow('Asking Price', comparedProps.map((p) => '₹${p.askingPriceCr} Cr').toList(), isHighlight: true),
                              _buildRow('Fair Value', comparedProps.map((p) => '₹${p.fairValueCr} Cr').toList()),
                              _buildRow('Price / Sq.Ft', comparedProps.map((p) => '₹${p.pricePerSqft.toStringAsFixed(0)}').toList()),
                              _buildRow('Location', comparedProps.map((p) => p.sector).toList()),
                              _buildRow('Property Type', comparedProps.map((p) => p.propertyType).toList()),
                              _buildRow('BHK / Layout', comparedProps.map((p) => p.bhk).toList()),
                              _buildRow('Area (Sq.Ft)', comparedProps.map((p) => '${p.sqft} Sq.Ft').toList()),
                              _buildRow('Facing', comparedProps.map((p) => p.facing).toList()),
                              _buildRow('Furnishing', comparedProps.map((p) => p.furnishing).toList()),
                              _buildRow('Availability', comparedProps.map((p) => p.availability).toList()),
                              _buildRow('Rental Yield', comparedProps.map((p) => '${p.rentalYieldPercent}%').toList()),
                              _buildRow('Verification', comparedProps.map((p) => p.isVerified ? 'VERIFIED ✓' : 'Pending').toList()),
                              _buildRow('Intelligence Score', comparedProps.map((p) => '${p.intelligenceScore} / 100').toList(), isHighlight: true),
                              _buildRow('Investment Score', comparedProps.map((p) => '${p.investmentScore} / 100').toList(), isHighlight: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildRow(String label, List<String> values, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
            ),
          ),
          ...values.map((v) {
            return SizedBox(
              width: 170,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  v,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                    color: isHighlight ? AppTheme.primaryViolet : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
