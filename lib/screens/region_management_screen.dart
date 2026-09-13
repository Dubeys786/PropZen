import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/region_model.dart';
import '../services/region_service.dart';
import '../theme/app_theme.dart';

class RegionManagementScreen extends StatefulWidget {
  final bool isAdminMode;

  const RegionManagementScreen({super.key, this.isAdminMode = false});

  @override
  State<RegionManagementScreen> createState() => _RegionManagementScreenState();
}

class _RegionManagementScreenState extends State<RegionManagementScreen> {
  final RegionConfigService _regionService = RegionConfigService.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _regionService,
      builder: (context, _) {
        final regions = _regionService.regions;
        final selected = _regionService.selectedRegion;

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
              widget.isAdminMode ? 'Multi-Region Admin Scaling' : 'Select Browsing Region',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: AppTheme.primaryViolet, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Region: ${selected.name}',
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                          ),
                          Text(
                            'Properties and market data are dynamically localized to your active territory.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Available Territories & Expansion Hubs', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              ...regions.map((r) {
                final isSelected = r.regionId == selected.regionId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight, width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(r.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: r.launchStatus == RegionLaunchStatus.active
                                  ? AppTheme.emeraldSuccess.withOpacity(0.1)
                                  : AppTheme.amberWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.launchStatus.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: r.launchStatus == RegionLaunchStatus.active ? AppTheme.emeraldSuccess : AppTheme.amberWarning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${r.city}, ${r.state} • ${r.country}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: r.boundaries.map((b) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(b, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                            )).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${r.propertyCount} Properties • ${r.dealerCount} Dealers', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          if (r.enabled && !isSelected)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryViolet,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              onPressed: () {
                                _regionService.selectRegion(r.regionId);
                                Navigator.of(context).pop();
                              },
                              child: const Text('Switch Region', style: TextStyle(fontSize: 12)),
                            )
                          else if (isSelected)
                            const Row(
                              children: [
                                Icon(LucideIcons.checkCircle2, size: 16, color: AppTheme.primaryViolet),
                                SizedBox(width: 4),
                                Text('Current Region', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                              ],
                            )
                          else
                            Text('Coming Soon', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
