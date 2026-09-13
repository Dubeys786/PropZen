import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class PropertyComparisonScreen extends StatelessWidget {
  const PropertyComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (ctx, _) {
        final props = PropertyStateService.instance.comparedProperties;
        final isDesktop = MediaQuery.of(context).size.width >= 1024;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(LucideIcons.scale, color: AppTheme.primaryViolet, size: 20),
                const SizedBox(width: 10),
                Text('Compare Properties (${props.length}/4)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (props.isNotEmpty)
                TextButton.icon(
                  onPressed: () => PropertyStateService.instance.clearCompare(clearBackend: true),
                  icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                  label: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
            ],
          ),
          body: props.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.scale, size: 48, color: AppTheme.primaryViolet),
                      ),
                      const SizedBox(height: 16),
                      Text('No properties in comparison', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Add up to 4 properties from search or details to compare specs.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Browse Properties'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: isDesktop ? 900 : 600),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.white),
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 68,
                        columns: [
                          const DataColumn(label: Text('Feature / Metric', style: TextStyle(fontWeight: FontWeight.bold))),
                          ...props.map((p) => DataColumn(
                                label: Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(p.title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      Text(p.propzenId, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                        rows: [
                          // 1. Price
                          DataRow(cells: [
                            const DataCell(Text('Asking Price', style: TextStyle(fontWeight: FontWeight.w600))),
                            ...props.map((p) => DataCell(Text(p.formattedPrice, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)))),
                          ]),
                          // 2. Price / sqft
                          DataRow(cells: [
                            const DataCell(Text('Price / Sq.Ft.')),
                            ...props.map((p) => DataCell(Text('₹${p.pricePerSqft.toStringAsFixed(0)} / sq.ft.'))),
                          ]),
                          // 3. Configuration
                          DataRow(cells: [
                            const DataCell(Text('BHK & Area')),
                            ...props.map((p) => DataCell(Text('${p.bhk} • ${p.sqft} Sq.Ft.'))),
                          ]),
                          // 4. Property Type
                          DataRow(cells: [
                            const DataCell(Text('Property Type')),
                            ...props.map((p) => DataCell(Text(p.propertyType.isNotEmpty ? p.propertyType : 'Not available'))),
                          ]),
                          // 5. Location
                          DataRow(cells: [
                            const DataCell(Text('Location')),
                            ...props.map((p) => DataCell(Text('${p.sector}, ${p.city}'))),
                          ]),
                          // 6. Verification Badge
                          DataRow(cells: [
                            const DataCell(Text('PropZen Verified')),
                            ...props.map((p) => DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.isPropZenVerified ? AppTheme.emeraldSuccess.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.isPropZenVerified ? '✓ Verified' : 'Under Audit',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.isPropZenVerified ? AppTheme.emeraldSuccess : Colors.grey),
                                    ),
                                  ),
                                )),
                          ]),
                          // 7. Trust Score
                          DataRow(cells: [
                            const DataCell(Text('Trust Score')),
                            ...props.map((p) => DataCell(Text('${p.intelligenceScore > 0 ? p.intelligenceScore : 92} / 100', style: const TextStyle(fontWeight: FontWeight.bold)))),
                          ]),
                          // 8. Verification Freshness
                          DataRow(cells: [
                            const DataCell(Text('Freshness')),
                            ...props.map((p) => DataCell(Text(p.freshnessDisplay))),
                          ]),
                          // 9. Availability
                          DataRow(cells: [
                            const DataCell(Text('Availability')),
                            ...props.map((p) => DataCell(Text(p.isSold ? 'Sold' : (p.availability.isNotEmpty ? p.availability : 'Immediate')))),
                          ]),
                          // 10. RERA ID
                          DataRow(cells: [
                            const DataCell(Text('RERA Sanction')),
                            ...props.map((p) => DataCell(Text(p.reraId.isNotEmpty ? p.reraId : 'Not available'))),
                          ]),
                          // 11. Actions
                          DataRow(cells: [
                            const DataCell(Text('Action')),
                            ...props.map((p) => DataCell(
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)),
                                      );
                                    },
                                    child: const Text('View', style: TextStyle(fontSize: 11)),
                                  ),
                                )),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
