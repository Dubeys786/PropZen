import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/ai_home_project.dart';
import '../../theme/app_theme.dart';

/// Interior Designer Room Level Studio View
class InteriorRoomDesignerView extends StatefulWidget {
  final List<AiInteriorRoomDesign> interiorDesigns;
  final String activeStyle;
  final Function(String roomName, String style, String colorPref) onGenerateInterior;
  final VoidCallback? onSaveDesign;
  final VoidCallback? onDownload;

  const InteriorRoomDesignerView({
    super.key,
    required this.interiorDesigns,
    required this.activeStyle,
    required this.onGenerateInterior,
    this.onSaveDesign,
    this.onDownload,
  });

  @override
  State<InteriorRoomDesignerView> createState() => _InteriorRoomDesignerState();
}

class _InteriorRoomDesignerState extends State<InteriorRoomDesignerView> {
  String _selectedRoom = 'Living Room';
  String _selectedStyle = 'Modern Luxury';
  String _selectedColor = 'Warm Neutral';

  final List<String> _rooms = [
    'Living Room',
    'Master Bedroom',
    'Modular Kitchen',
    'Pooja Room',
    'Guest Bedroom',
    'Home Office',
    'Balcony Lounge',
  ];

  final List<String> _styles = [
    'Modern Luxury',
    'Minimal Warm',
    'Scandinavian',
    'Contemporary',
    'Indian Heritage',
    'Industrial Chic',
  ];

  final List<String> _colors = [
    'Warm Neutral',
    'Charcoal & Brass',
    'Earthy Terracotta',
    'Cool Sage & Slate',
    'Royal Emerald & Gold',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.activeStyle;
  }

  @override
  Widget build(BuildContext context) {
    // Find matching room design or fallback to first
    final activeDesign = widget.interiorDesigns.firstWhere(
      (d) => d.roomName.toLowerCase().contains(_selectedRoom.toLowerCase()),
      orElse: () => widget.interiorDesigns.isNotEmpty
          ? widget.interiorDesigns.first
          : const AiInteriorRoomDesign(
              roomName: 'Living Room',
              style: 'Modern Luxury',
              colorPreference: 'Warm Neutral',
              furniture: 'L-Shaped Velvet Sofa, Travertine Table',
              lighting: 'Recessed Magnetic Track Lights',
              wallDesign: 'Venetian Stucco with Wood Fluting',
              flooring: 'Italian Marble Finish Tiles',
              ceiling: 'Shadow Line False Ceiling',
              decor: 'Abstract Canvas, Brass Planters',
              estimatedFurnishingBudget: '₹ 4.5 – 6.5 Lakhs',
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Room Selector Carousel
        Text(
          '1. Select Room to Design',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _rooms.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final r = _rooms[i];
              final isSelected = r == _selectedRoom;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRoom = r);
                  widget.onGenerateInterior(_selectedRoom, _selectedStyle, _selectedColor);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet : AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                    ),
                    boxShadow: isSelected ? AppTheme.subtleCardShadow : null,
                  ),
                  child: Center(
                    child: Text(
                      r,
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
        const SizedBox(height: 18),

        // Style & Color Preferences Dropdowns / Chips
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interior Theme', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _styles.contains(_selectedStyle) ? _selectedStyle : _styles.first,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        items: _styles.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStyle = val);
                            widget.onGenerateInterior(_selectedRoom, _selectedStyle, _selectedColor);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Color Palette', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _colors.contains(_selectedColor) ? _selectedColor : _colors.first,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedColor = val);
                            widget.onGenerateInterior(_selectedRoom, _selectedStyle, _selectedColor);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Generated Interior Details Card
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
              // Room Concept Image
              Stack(
                children: [
                  Image.network(
                    activeDesign.imageUrl ?? 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                        '${activeDesign.roomName} • ${activeDesign.style}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Est. Furnishing: ${activeDesign.estimatedFurnishingBudget}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFBBF24)),
                      ),
                    ),
                  ),
                ],
              ),

              // Architectural & Material Specs
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSpecTile(LucideIcons.sofa, 'Furniture', activeDesign.furniture),
                    const Divider(height: 16),
                    _buildSpecTile(LucideIcons.sun, 'Lighting Scheme', activeDesign.lighting),
                    const Divider(height: 16),
                    _buildSpecTile(LucideIcons.layout, 'Wall Treatment', activeDesign.wallDesign),
                    const Divider(height: 16),
                    _buildSpecTile(LucideIcons.grid, 'Flooring', activeDesign.flooring),
                    const Divider(height: 16),
                    _buildSpecTile(LucideIcons.shield, 'Ceiling Design', activeDesign.ceiling),
                    const Divider(height: 16),
                    _buildSpecTile(LucideIcons.sparkles, 'Decor & Accents', activeDesign.decor),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons: Regenerate, Save Design, Download
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onGenerateInterior(_selectedRoom, _selectedStyle, _selectedColor),
                icon: const Icon(LucideIcons.rotateCcw, size: 15),
                label: const Text('Regenerate'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryViolet),
                  foregroundColor: AppTheme.primaryViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (widget.onSaveDesign != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onSaveDesign,
                  icon: const Icon(LucideIcons.bookmark, size: 15),
                  label: const Text('Save Design'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSpecTile(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: AppTheme.primaryViolet),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
