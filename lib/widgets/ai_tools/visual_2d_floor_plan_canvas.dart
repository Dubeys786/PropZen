import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';

/// Data model for a rendered room in the 2D CAD Floor Plan
class CadRoom {
  final String id;
  final String name;
  final String dimensions;
  final String area;
  final String vastuZone;
  final Color baseColor;
  final Rect relativeRect; // Normalized 0.0 -> 1.0 within the built envelope
  final List<String> features;
  final bool isBalcony;
  final bool isParking;

  const CadRoom({
    required this.id,
    required this.name,
    required this.dimensions,
    required this.area,
    required this.vastuZone,
    required this.baseColor,
    required this.relativeRect,
    required this.features,
    this.isBalcony = false,
    this.isParking = false,
  });
}

/// Interactive 2D Vector CAD Floor Plan Canvas Widget
class Visual2dFloorPlanCanvas extends StatefulWidget {
  final double plotWidth;
  final double plotLength;
  final String facing;
  final String bhk;
  final String floors;
  final String vastuStrictness;
  final VoidCallback? onRegenerate;
  final VoidCallback? onSave;

  const Visual2dFloorPlanCanvas({
    super.key,
    required this.plotWidth,
    required this.plotLength,
    this.facing = 'North-East',
    this.bhk = '3 BHK',
    this.floors = 'G+1 (Double Story)',
    this.vastuStrictness = 'Strict 100% Vastu',
    this.onRegenerate,
    this.onSave,
  });

  @override
  State<Visual2dFloorPlanCanvas> createState() => _Visual2dFloorPlanCanvasState();
}

class _Visual2dFloorPlanCanvasState extends State<Visual2dFloorPlanCanvas> {
  final TransformationController _transformController = TransformationController();
  CadRoom? _selectedRoom;
  bool _showVastuTags = true;
  bool _isSaved = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final Matrix4 current = _transformController.value;
    _transformController.value = current.scaled(1.25, 1.25);
  }

  void _zoomOut() {
    final Matrix4 current = _transformController.value;
    _transformController.value = current.scaled(0.8, 0.8);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    setState(() => _selectedRoom = null);
  }

  void _openFullscreenModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            title: Text(
              '${widget.plotWidth.toInt()}×${widget.plotLength.toInt()} ft ${widget.bhk} — 2D Architectural CAD Plan',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.download, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Architectural 2D CAD blueprint export initiated (PDF/DXF format).'),
                      backgroundColor: Color(0xFF0D9488),
                    ),
                  );
                },
              ),
            ],
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildCadPlanVisual(isDark: true, isFullscreen: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Parametric Layout Generator: adapts rooms according to dimensions, BHK, and facing direction
  List<CadRoom> _generateParametricRooms() {
    final isCompact = widget.plotWidth <= 25;
    final isExpansive = widget.plotWidth >= 35;
    final isEastFacing = widget.facing.toLowerCase().contains('east');

    final rooms = <CadRoom>[];

    if (isCompact) {
      // 20x50 ft / Compact Linear Row Layout
      rooms.addAll([
        CadRoom(
          id: 'parking',
          name: 'Covered Car Porch',
          dimensions: '9\'6" × 14\'0"',
          area: '133 sq.ft.',
          vastuZone: 'North-West (Vayu)',
          baseColor: const Color(0xFFE2E8F0),
          relativeRect: const Rect.fromLTWH(0.0, 0.0, 0.48, 0.28),
          features: ['1 Covered Sedan Bay', 'Paved Tile Flooring', 'EV Charging Point Ready'],
          isParking: true,
        ),
        CadRoom(
          id: 'verandah',
          name: 'Entrance Foyer & Verandah',
          dimensions: '8\'0" × 10\'0"',
          area: '80 sq.ft.',
          vastuZone: 'North-East (Ishanya)',
          baseColor: const Color(0xFFE0F2FE),
          relativeRect: const Rect.fromLTWH(0.48, 0.0, 0.52, 0.20),
          features: ['Teak Main Door', 'Shoe Console Niche', 'Vastu Threshold Step'],
        ),
        CadRoom(
          id: 'living',
          name: 'Living & Family Lounge',
          dimensions: '18\'0" × 14\'6"',
          area: '261 sq.ft.',
          vastuZone: 'Brahmasthan / North Zone',
          baseColor: const Color(0xFFF1F5F9),
          relativeRect: const Rect.fromLTWH(0.0, 0.28, 1.0, 0.26),
          features: ['Cross Ventilation Windows', '6-Seater Sectional Area', 'TV Feature Wall'],
        ),
        CadRoom(
          id: 'kitchen',
          name: 'Modular Kitchen & Utility',
          dimensions: '9\'0" × 10\'6"',
          area: '95 sq.ft.',
          vastuZone: isEastFacing ? 'South-East (Agni Zone)' : 'North-West (Vayu Zone)',
          baseColor: const Color(0xFFFEF3C7),
          relativeRect: const Rect.fromLTWH(0.0, 0.54, 0.48, 0.22),
          features: ['East Facing Cooking Hob', 'L-Shaped Quartz Counter', 'Utility Sink Duct'],
        ),
        CadRoom(
          id: 'dining_puja',
          name: 'Dining Hall + Pooja Niche',
          dimensions: '9\'6" × 10\'6"',
          area: '100 sq.ft.',
          vastuZone: 'Ishanya Corner',
          baseColor: const Color(0xFFEDE9FE),
          relativeRect: const Rect.fromLTWH(0.48, 0.54, 0.52, 0.22),
          features: ['6-Seater Table Clearances', 'Integrated Pooja Mandir', 'Wash Basin Vanity'],
        ),
        CadRoom(
          id: 'master_bed',
          name: 'Master Suite + En-Suite Bath',
          dimensions: '14\'0" × 12\'6"',
          area: '175 sq.ft.',
          vastuZone: 'South-West (Nairutya)',
          baseColor: const Color(0xFFDCFCE7),
          relativeRect: const Rect.fromLTWH(0.0, 0.76, 0.65, 0.24),
          features: ['South-West Bed Alignment', 'Attached 5x8 ft Bath', 'Floor-to-Ceiling Wardrobes'],
        ),
        CadRoom(
          id: 'common_bath',
          name: 'Common Toilet + Shaft',
          dimensions: '6\'6" × 8\'0"',
          area: '52 sq.ft.',
          vastuZone: 'West Shaft',
          baseColor: const Color(0xFFFEE2E2),
          relativeRect: const Rect.fromLTWH(0.65, 0.76, 0.35, 0.24),
          features: ['Dry & Wet Segregation', 'Ventilation Light Well', 'Concealed Cistern'],
        ),
      ]);
    } else if (isExpansive) {
      // 35x60 or 40x60 ft / Luxury Villa Double-Frontage Layout
      rooms.addAll([
        CadRoom(
          id: 'parking',
          name: 'Dual Covered Car Port',
          dimensions: '16\'0" × 16\'0"',
          area: '256 sq.ft.',
          vastuZone: 'North-West (Vayu)',
          baseColor: const Color(0xFFE2E8F0),
          relativeRect: const Rect.fromLTWH(0.0, 0.0, 0.44, 0.24),
          features: ['2 Full Size SUVs', 'EV Charging Station', 'Cobblestone Ramp'],
          isParking: true,
        ),
        CadRoom(
          id: 'lawn_entry',
          name: 'Front Green Lawn & Foyer',
          dimensions: '18\'0" × 16\'0"',
          area: '288 sq.ft.',
          vastuZone: 'North-East (Ishanya)',
          baseColor: const Color(0xFFDCFCE7),
          relativeRect: const Rect.fromLTWH(0.44, 0.0, 0.56, 0.24),
          features: ['Cascading Water Feature', 'Landscape Planter Beds', 'Wide Covered Porch'],
          isBalcony: true,
        ),
        CadRoom(
          id: 'drawing_room',
          name: 'Formal Drawing Room',
          dimensions: '16\'0" × 18\'0"',
          area: '288 sq.ft.',
          vastuZone: 'North Zone',
          baseColor: const Color(0xFFEDE9FE),
          relativeRect: const Rect.fromLTWH(0.0, 0.24, 0.44, 0.26),
          features: ['Double Height Ceiling (18 ft)', 'Full Glass Garden Facing', 'Marble Fireplace Feature'],
        ),
        CadRoom(
          id: 'family_living',
          name: 'Double-Height Family Lounge',
          dimensions: '20\'0" × 18\'0"',
          area: '360 sq.ft.',
          vastuZone: 'Brahmasthan (Center Open)',
          baseColor: const Color(0xFFF1F5F9),
          relativeRect: const Rect.fromLTWH(0.44, 0.24, 0.56, 0.26),
          features: ['Central Courtyard Sightline', 'Open Staircase Void', 'Sectional Sofa Lounge'],
        ),
        CadRoom(
          id: 'puja_room',
          name: 'Vedic Pooja Sanctuary',
          dimensions: '8\'0" × 10\'0"',
          area: '80 sq.ft.',
          vastuZone: 'North-East (Ishanya Sanctum)',
          baseColor: const Color(0xFFFEF08A),
          relativeRect: const Rect.fromLTWH(0.0, 0.50, 0.25, 0.22),
          features: ['White Makrana Marble Cladding', 'Skylight Illumination', 'Vastu Copper Threshold'],
        ),
        CadRoom(
          id: 'kitchen_dining',
          name: 'Island Kitchen & Dining Hall',
          dimensions: '18\'0" × 15\'0"',
          area: '270 sq.ft.',
          vastuZone: 'South-East (Agni)',
          baseColor: const Color(0xFFFEF3C7),
          relativeRect: const Rect.fromLTWH(0.25, 0.50, 0.45, 0.22),
          features: ['Central Breakfast Island', '8-Seater Dining Space', 'Separate Wet Spice Kitchen'],
        ),
        CadRoom(
          id: 'guest_bedroom',
          name: 'Guest Bedroom Suite',
          dimensions: '14\'0" × 15\'0"',
          area: '210 sq.ft.',
          vastuZone: 'North-West (Air Zone)',
          baseColor: const Color(0xFFE0F2FE),
          relativeRect: const Rect.fromLTWH(0.70, 0.50, 0.30, 0.22),
          features: ['En-Suite 3-Fixture Bathroom', 'Large Garden Window', 'Built-in Study Console'],
        ),
        CadRoom(
          id: 'master_suite',
          name: 'Grand Master Suite + Walk-in Closet',
          dimensions: '18\'0" × 16\'0"',
          area: '288 sq.ft.',
          vastuZone: 'South-West (Nairutya Leadership Zone)',
          baseColor: const Color(0xFFDCFCE7),
          relativeRect: const Rect.fromLTWH(0.0, 0.72, 0.60, 0.28),
          features: ['His & Hers Walk-In Closet', '5-Fixture Luxury Master Bath', 'Rear Private Courtyard Deck'],
        ),
        CadRoom(
          id: 'home_office',
          name: 'Executive Home Office & Library',
          dimensions: '14\'0" × 16\'0"',
          area: '224 sq.ft.',
          vastuZone: 'West Zone',
          baseColor: const Color(0xFFFCE7F3),
          relativeRect: const Rect.fromLTWH(0.60, 0.72, 0.40, 0.28),
          features: ['Acoustic Soundproofing', 'Custom Teak Bookshelf', 'Courtyard Access'],
        ),
      ]);
    } else {
      // 30x50 or 30x60 ft / Standard 3 BHK Balanced Layout
      rooms.addAll([
        CadRoom(
          id: 'parking',
          name: 'Covered Car Porch & Ramp',
          dimensions: '11\'0" × 16\'0"',
          area: '176 sq.ft.',
          vastuZone: isNorthFacingVastu(widget.facing) ? 'North-West (Vayu)' : 'South-East Driveway',
          baseColor: const Color(0xFFE2E8F0),
          relativeRect: const Rect.fromLTWH(0.0, 0.0, 0.42, 0.24),
          features: ['Covered Sedan + 2 Two-Wheelers', 'Granite Cobblestones', 'Security Sensor'],
          isParking: true,
        ),
        CadRoom(
          id: 'foyer_verandah',
          name: 'Main Foyer & Verandah',
          dimensions: '14\'6" × 8\'0"',
          area: '116 sq.ft.',
          vastuZone: 'North-East (Ishanya Gate)',
          baseColor: const Color(0xFFE0F2FE),
          relativeRect: const Rect.fromLTWH(0.42, 0.0, 0.58, 0.14),
          features: ['Teak Carved Main Entrance Door', 'Decorative Water Urn', 'Foyer Planter'],
        ),
        CadRoom(
          id: 'puja_room',
          name: 'Pooja Mandir',
          dimensions: '6\'6" × 7\'6"',
          area: '48 sq.ft.',
          vastuZone: 'North-East (Ishanya)',
          baseColor: const Color(0xFFFEF08A),
          relativeRect: const Rect.fromLTWH(0.75, 0.14, 0.25, 0.14),
          features: ['East Facing Idol Pedestal', 'Natural Light Jali', 'Sacred Water Vessel'],
        ),
        CadRoom(
          id: 'living_hall',
          name: 'Spacious Living & Drawing Hall',
          dimensions: '16\'0" × 20\'6"',
          area: '328 sq.ft.',
          vastuZone: 'North / East Zone',
          baseColor: const Color(0xFFF1F5F9),
          relativeRect: const Rect.fromLTWH(0.0, 0.24, 0.58, 0.28),
          features: ['11 ft False Ceiling', '3-Side Cross Ventilation', '8-Seater Lounge Space'],
        ),
        CadRoom(
          id: 'dining_area',
          name: 'Family Dining Lounge',
          dimensions: '12\'6" × 14\'0"',
          area: '175 sq.ft.',
          vastuZone: 'Central Core (Brahmasthan Clear)',
          baseColor: const Color(0xFFEDE9FE),
          relativeRect: const Rect.fromLTWH(0.58, 0.28, 0.42, 0.24),
          features: ['6-Seater Marble Dining Table', 'Open Wash Basin Console', 'Direct Kitchen Access'],
        ),
        CadRoom(
          id: 'modular_kitchen',
          name: 'Modular Island Kitchen & Utility',
          dimensions: '11\'6" × 13\'6"',
          area: '155 sq.ft.',
          vastuZone: isEastFacing ? 'South-East (Agni)' : 'South-East (Agni Zone)',
          baseColor: const Color(0xFFFEF3C7),
          relativeRect: const Rect.fromLTWH(0.58, 0.52, 0.42, 0.22),
          features: ['East-Facing Induction & Gas Hob', 'Attached Utility Balcony', 'Tall Pantry Storage'],
        ),
        CadRoom(
          id: 'bedroom_2',
          name: 'Kids / Guest Bedroom',
          dimensions: '12\'6" × 14\'0"',
          area: '175 sq.ft.',
          vastuZone: 'North-West (Air Zone)',
          baseColor: const Color(0xFFE0F2FE),
          relativeRect: const Rect.fromLTWH(0.0, 0.52, 0.58, 0.22),
          features: ['Study Desk by Window', 'Fitted Sliding Wardrobe', 'Attached 5x7 ft Bath'],
        ),
        CadRoom(
          id: 'master_bedroom',
          name: 'Master Bedroom Suite',
          dimensions: '15\'0" × 16\'0"',
          area: '240 sq.ft.',
          vastuZone: 'South-West (Nairutya Leadership)',
          baseColor: const Color(0xFFDCFCE7),
          relativeRect: const Rect.fromLTWH(0.0, 0.74, 0.65, 0.26),
          features: ['South-West King Bed Orientation', 'Dresser Passage', 'Private Balcony Access'],
        ),
        CadRoom(
          id: 'master_bath_balcony',
          name: 'En-Suite Bath & Rear Balcony',
          dimensions: '10\'0" × 14\'0"',
          area: '140 sq.ft.',
          vastuZone: 'West Shaft',
          baseColor: const Color(0xFFFCE7F3),
          relativeRect: const Rect.fromLTWH(0.65, 0.74, 0.35, 0.26),
          features: ['Glass Shower Cubicle', 'Solar Water Heater Link', 'Private Green Balcony'],
        ),
      ]);
    }

    return rooms;
  }

  bool isNorthFacingVastu(String facing) {
    return facing.toLowerCase().contains('north') || facing.toLowerCase().contains('east');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rooms = _generateParametricRooms();
    final totalPlotSqft = (widget.plotWidth * widget.plotLength).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // 1. Control Toolbar (Zoom, Reset, Fullscreen, Toggle Tags, Download)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurfaceContainer : AppTheme.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Vastu Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSuccess.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.compass, size: 14, color: AppTheme.emeraldSuccess),
                    const SizedBox(width: 6),
                    Text(
                      'Vastu Score: 94% Compliant (${widget.facing})',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
                    ),
                  ],
                ),
              ),

              // Tool Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolIcon(LucideIcons.zoomIn, 'Zoom In', _zoomIn, isDark),
                  const SizedBox(width: 4),
                  _buildToolIcon(LucideIcons.zoomOut, 'Zoom Out', _zoomOut, isDark),
                  const SizedBox(width: 4),
                  _buildToolIcon(LucideIcons.rotateCcw, 'Reset View', _resetZoom, isDark),
                  const SizedBox(width: 4),
                  _buildToolIcon(LucideIcons.maximize2, 'Fullscreen Plan', _openFullscreenModal, isDark),
                  const SizedBox(width: 8),
                  // Save / Bookmark Button
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _isSaved = !_isSaved);
                      widget.onSave?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isSaved ? '✓ 2D CAD Floor Plan saved to your project designs.' : 'Floor plan bookmark removed.'),
                          backgroundColor: const Color(0xFF0D9488),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(_isSaved ? LucideIcons.check : LucideIcons.bookmark, size: 13, color: const Color(0xFF0D9488)),
                    label: Text(_isSaved ? 'Saved' : 'Save Plan', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Interactive CAD Canvas Body
        Container(
          width: double.infinity,
          height: 480,
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B), // Professional CAD Slate Blueprint Navy
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Grid Background Lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _CadGridPainter(),
                ),
              ),

              // Interactive Pan & Zoom Area
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.7,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(80),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildCadPlanVisual(isDark: true),
                  ),
                ),
              ),

              // North Direction Compass Indicator (Top Right)
              Positioned(
                top: 14,
                right: 14,
                child: _buildNorthCompass(),
              ),

              // Plot Dimensions Overlay Pill (Top Left)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0D9488), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.ruler, color: Color(0xFF2DD4BF), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.plotWidth.toInt()} ft × ${widget.plotLength.toInt()} ft ($totalPlotSqft sq.ft.)',
                        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected Room Floating Inspector (Bottom Overlay)
              if (_selectedRoom != null)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: _buildSelectedRoomInspector(_selectedRoom!),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Action Buttons Row (Download Blueprint, Generate Again)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ 2D CAD Floor Plan downloaded in high-resolution PDF with dimension lines.'),
                      backgroundColor: Color(0xFF0D9488),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.download, size: 16, color: Colors.white),
                label: Text('Download Floor Plan (PDF)', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRegenerate ?? () {
                  setState(() => _resetZoom());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Generating optimized layout alternative with adjusted circulation flow...'),
                      backgroundColor: Color(0xFF6D28D9),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.refreshCw, size: 15, color: Color(0xFF6D28D9)),
                label: Text('Generate Again', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6D28D9), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 4. In-Depth Vastu Directional Zone Analysis
        _buildVastuZoneAnalysisCard(isDark),

        const SizedBox(height: 14),

        // 5. Official Architectural & Civil Engineering Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, color: Color(0xFFD97706), size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Generated Conceptual Floor Plan',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFB45309)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This layout is an architectural spatial proposal. Consult a licensed architect and structural engineer before starting construction or civil excavation.',
                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF92400E), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildToolIcon(IconData icon, String tooltip, VoidCallback onTap, bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 15, color: isDark ? Colors.white : AppTheme.textPrimary),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildNorthCompass() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.arrowUp, color: Color(0xFF38BDF8), size: 16),
          Text(
            'N',
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
          ),
        ],
      ),
    );
  }

  /// Core 2D CAD Plan Blueprint Drawing Widget
  Widget _buildCadPlanVisual({required bool isDark, bool isFullscreen = false}) {
    final rooms = _generateParametricRooms();
    final canvasWidth = isFullscreen ? 580.0 : 360.0;
    final canvasHeight = isFullscreen ? 720.0 : 420.0;

    return Container(
      width: canvasWidth,
      height: canvasHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF38BDF8), width: 2.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.2), blurRadius: 16),
        ],
      ),
      child: Stack(
        children: [
          // Outer Dimension Callouts
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '◀─── ${widget.plotWidth.toInt()}’ 0” FRONTAGE ───▶',
                style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8), letterSpacing: 0.8),
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: RotatedBox(
              quarterTurns: 3,
              child: Center(
                child: Text(
                  '◀─── ${widget.plotLength.toInt()}’ 0” PLOT LENGTH ───▶',
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8), letterSpacing: 0.8),
                ),
              ),
            ),
          ),

          // Render Each Room Box
          ...rooms.map((room) {
            final isSelected = _selectedRoom?.id == room.id;
            final rect = room.relativeRect;

            return Positioned(
              left: 20 + rect.left * (canvasWidth - 28),
              top: 20 + rect.top * (canvasHeight - 28),
              width: rect.width * (canvasWidth - 28),
              height: rect.height * (canvasHeight - 28),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedRoom = room);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0D9488).withOpacity(0.35)
                        : (room.isParking
                            ? const Color(0xFF334155).withOpacity(0.6)
                            : (room.isBalcony ? const Color(0xFF065F46).withOpacity(0.4) : const Color(0xFF1E293B).withOpacity(0.75))),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2DD4BF) : const Color(0xFF64748B),
                      width: isSelected ? 2.5 : 1.2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Door Swing Indicator (CAD Arc)
                      if (!room.isParking && !room.isBalcony)
                        Positioned(
                          top: 3,
                          left: 3,
                          child: Icon(LucideIcons.doorOpen, size: 10, color: Colors.white.withOpacity(0.5)),
                        ),

                      // Room Info & Labels
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  room.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: canvasWidth > 400 ? 11 : 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF2DD4BF) : Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  room.dimensions,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: canvasWidth > 400 ? 9.5 : 8,
                                    color: const Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_showVastuTags) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      room.vastuZone,
                                      style: GoogleFonts.inter(fontSize: 7, color: const Color(0xFFFDE047), fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomInspector(CadRoom room) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2DD4BF), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.layout, color: Color(0xFF2DD4BF), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      room.name,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        room.vastuZone,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Size: ${room.dimensions} (${room.area}) • Features: ${room.features.join(", ")}',
                  style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white70, size: 16),
            onPressed: () => setState(() => _selectedRoom = null),
          ),
        ],
      ),
    );
  }

  Widget _buildVastuZoneAnalysisCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainer : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.compass, size: 18, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              Text(
                'Directional Vastu Analysis & Sizing',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Zone Breakdown Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              _buildVastuZonePill('North-East (Ishanya)', 'Pooja Mandir & Entrance', 'Auspicious (98%)', const Color(0xFF059669), isDark),
              _buildVastuZonePill('South-East (Agni)', 'Modular Island Kitchen', 'Optimal (95%)', const Color(0xFFD97706), isDark),
              _buildVastuZonePill('South-West (Nairutya)', 'Master Bedroom Suite', 'Harmonic (94%)', const Color(0xFF0D9488), isDark),
              _buildVastuZonePill('North-West (Vayu)', 'Guest Bed & Car Porch', 'Balanced (90%)', const Color(0xFF6366F1), isDark),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            'Architectural Recommendations:',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          _buildBulletPoint('Maintain unobstructed 3.5 ft corridor clearances from entrance to rear rooms.', isDark),
          _buildBulletPoint('Cooking hob is positioned facing East for positive solar energy alignment.', isDark),
          _buildBulletPoint('Master bed headboard is oriented toward South/East for restorative sleep.', isDark),
          _buildBulletPoint('Brahmasthan (central core) remains open and uncluttered for cross ventilation.', isDark),
        ],
      ),
    );
  }

  Widget _buildVastuZonePill(String zone, String room, String score, Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(zone, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: accent), maxLines: 1),
          const SizedBox(height: 2),
          Text(room, style: GoogleFonts.inter(fontSize: 9.5, color: isDark ? Colors.white70 : AppTheme.textSecondary), maxLines: 1),
          const SizedBox(height: 2),
          Text(score, style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: accent)),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.check, size: 13, color: AppTheme.emeraldSuccess),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white70 : AppTheme.textSecondary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// CAD Grid Background Painter
class _CadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.5)
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
