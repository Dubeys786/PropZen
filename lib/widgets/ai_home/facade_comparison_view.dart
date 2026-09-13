import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/ai_home_project.dart';
import '../../theme/app_theme.dart';

/// Facade Design Comparison View with Side-by-Side Style Comparisons
class FacadeComparisonView extends StatefulWidget {
  final List<AiFacadeDesign> facades;
  final String activeStyle;
  final ValueChanged<String> onStyleSelected;
  final VoidCallback onRegenerateFacade;
  final VoidCallback? onDownload;

  const FacadeComparisonView({
    super.key,
    required this.facades,
    required this.activeStyle,
    required this.onStyleSelected,
    required this.onRegenerateFacade,
    this.onDownload,
  });

  @override
  State<FacadeComparisonView> createState() => _FacadeComparisonViewState();
}

class _FacadeComparisonViewState extends State<FacadeComparisonView> {
  int _selectedVariantIndex = 0;
  bool _isSideBySideMode = false;

  final List<HomeDesignStyle> _styles = HomeDesignStyle.values;

  @override
  Widget build(BuildContext context) {
    if (widget.facades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.image, size: 40, color: AppTheme.textHint),
              const SizedBox(height: 12),
              Text('No Facade Variants Generated Yet', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: widget.onRegenerateFacade,
                icon: const Icon(LucideIcons.sparkles, size: 16),
                label: const Text('Generate Facades'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeFacade = widget.facades[_selectedVariantIndex.clamp(0, widget.facades.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Switcher: Single Spotlight vs Side-by-Side Comparison
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exterior Elevations',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Row(
              children: [
                _buildModeTab('Spotlight', !_isSideBySideMode, () => setState(() => _isSideBySideMode = false)),
                const SizedBox(width: 6),
                _buildModeTab('Compare (A vs B vs C)', _isSideBySideMode, () => setState(() => _isSideBySideMode = true)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (!_isSideBySideMode) ...[
          // Single Variant Spotlight Hero Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.softCardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Facade Image Preview with Gradient Overlay
                Stack(
                  children: [
                    Image.network(
                      activeFacade.imageUrl ?? 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 210,
                        color: AppTheme.surfaceHighlight,
                        child: const Center(child: Icon(LucideIcons.image, size: 36, color: AppTheme.textHint)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeFacade.variantName,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    if (widget.onDownload != null)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: widget.onDownload,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.download, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),

                // Specifications Breakdown
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpecRow(LucideIcons.palette, 'Color Palette', activeFacade.colorPalette),
                      const SizedBox(height: 10),
                      _buildSpecRow(LucideIcons.layers, 'Materials', activeFacade.exteriorMaterials),
                      const SizedBox(height: 10),
                      _buildSpecRow(LucideIcons.sun, 'Lighting Accent', activeFacade.lightingHighlights),
                      const SizedBox(height: 14),

                      // Feature Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeFacade.tags.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderPurple),
                            ),
                            child: Text(
                              t,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Variant Selection Switcher (Design A, B, C)
          Row(
            children: widget.facades.asMap().entries.map((entry) {
              final idx = entry.key;
              final f = entry.value;
              final isSelected = _selectedVariantIndex == idx;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedVariantIndex = idx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: idx < widget.facades.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryViolet : AppTheme.cardWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                      ),
                      boxShadow: isSelected ? AppTheme.subtleCardShadow : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Variant ${String.fromCharCode(65 + idx)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          f.style,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isSelected ? Colors.white70 : AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          // Side-by-Side Comparison Matrix
          SizedBox(
            height: 420,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.facades.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 14),
              itemBuilder: (ctx, i) {
                final facade = widget.facades[i];
                return Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        facade.imageUrl ?? 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
                        height: 140,
                        width: 260,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facade.variantName,
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _buildSpecRow(LucideIcons.palette, 'Colors', facade.colorPalette),
                            const SizedBox(height: 6),
                            _buildSpecRow(LucideIcons.layers, 'Materials', facade.exteriorMaterials),
                            const SizedBox(height: 6),
                            _buildSpecRow(LucideIcons.sun, 'Lighting', facade.lightingHighlights),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Style Selector Carousel & Regenerate CTA
        Text(
          'Choose Facade Architectural Style',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _styles.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final s = _styles[i];
              final isSelected = s.label.toLowerCase() == widget.activeStyle.toLowerCase();

              return GestureDetector(
                onTap: () => widget.onStyleSelected(s.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet : AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      s.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Regenerate Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: widget.onRegenerateFacade,
            icon: const Icon(LucideIcons.sparkles, size: 16, color: AppTheme.primaryViolet),
            label: Text(
              'Regenerate Facade with ${widget.activeStyle}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryViolet),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryViolet : AppTheme.surfaceHighlight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppTheme.primaryViolet),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
