import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/property_visualization_model.dart';
import '../services/property_visualization_service.dart';
import '../screens/site_visit_booking_screen.dart';
import '../theme/app_theme.dart';

/// Interactive Architectural Floor Plan Viewer
/// Renders property-specific CAD blueprint floor plans, isometric cutaways,
/// room dimension inspector, carpet vs super area metrics, and direct booking flow.
class PropertyFloorPlanViewer extends StatefulWidget {
  final Property property;

  const PropertyFloorPlanViewer({super.key, required this.property});

  static void show(BuildContext context, Property property) {
    PropertyVisualizationService.instance.logVisualizationEvent(
      eventName: 'floor_plan_opened',
      propertyId: property.id,
      propertyTitle: property.title,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PropertyFloorPlanViewer(property: property),
    );
  }

  @override
  State<PropertyFloorPlanViewer> createState() => _PropertyFloorPlanViewerState();
}

class _PropertyFloorPlanViewerState extends State<PropertyFloorPlanViewer> {
  int _selectedViewMode = 0; // 0 = 2D CAD Blueprint, 1 = 3D Isometric Cutaway
  int _selectedRoomIndex = 0;
  double _zoomScale = 1.0;
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  List<FloorPlanRoom> _resolveRooms(Property prop) {
    if (prop.floorPlanRooms.isNotEmpty) {
      return prop.floorPlanRooms;
    }

    final totalSqft = prop.sqft > 0 ? prop.sqft : 1450;
    final isVilla = prop.propertyType.toLowerCase().contains('villa') || prop.bhk.contains('5');
    final isCommercial = prop.propertyType.toLowerCase().contains('commercial') || prop.category.toLowerCase().contains('commercial');

    if (isCommercial) {
      return [
        FloorPlanRoom(name: 'Main Workstation Hall', roomType: 'office', areaSqFt: (totalSqft * 0.45).round(), dimensions: '28\'0" x 36\'0"', features: ['Open Workstation Bay', 'Floor Trunking']),
        FloorPlanRoom(name: 'Executive Boardroom', roomType: 'meeting', areaSqFt: (totalSqft * 0.20).round(), dimensions: '16\'0" x 18\'0"', features: ['AV Conferencing Wall', 'Acoustic Glazing']),
        FloorPlanRoom(name: 'Director Cabin', roomType: 'cabin', areaSqFt: (totalSqft * 0.15).round(), dimensions: '14\'0" x 15\'0"', features: ['Attached Private Washroom', 'Expressway Facing']),
        FloorPlanRoom(name: 'Pantry & Cafeteria', roomType: 'kitchen', areaSqFt: (totalSqft * 0.12).round(), dimensions: '12\'0" x 14\'0"', features: ['Wet Pantry Counter', 'Dining Niche']),
        FloorPlanRoom(name: 'Server & Utility Room', roomType: 'utility', areaSqFt: (totalSqft * 0.08).round(), dimensions: '8\'0" x 12\'0"', features: ['Dedicated HVAC Vent', 'UPS Backup Rack']),
      ];
    }

    if (isVilla) {
      return [
        FloorPlanRoom(name: 'Double-Height Grand Foyer', roomType: 'livingRoom', areaSqFt: (totalSqft * 0.28).round(), dimensions: '22\'0" x 26\'0"', features: ['Double Height Ceiling', 'Private Courtyard Access']),
        FloorPlanRoom(name: 'Presidential Master Suite', roomType: 'masterBedroom', areaSqFt: (totalSqft * 0.22).round(), dimensions: '18\'0" x 22\'0"', features: ['Walk-in Dressing Suite', 'Jacuzzi Attached']),
        FloorPlanRoom(name: 'Guest Garden Suite', roomType: 'bedroom', areaSqFt: (totalSqft * 0.16).round(), dimensions: '15\'0" x 16\'0"', features: ['Private Lawn Patio', 'Ensuite Bath']),
        FloorPlanRoom(name: 'Gourmet Island Kitchen', roomType: 'kitchen', areaSqFt: (totalSqft * 0.14).round(), dimensions: '14\'0" x 16\'0"', features: ['Central Island', 'Dry + Wet Utility']),
        FloorPlanRoom(name: 'Infinity Pool Deck', roomType: 'balcony', areaSqFt: (totalSqft * 0.12).round(), dimensions: '12\'0" x 24\'0"', features: ['Sun Lounger Deck', 'Private Green Pergola']),
        FloorPlanRoom(name: 'Family Lounge & Bar', roomType: 'livingRoom', areaSqFt: (totalSqft * 0.08).round(), dimensions: '14\'0" x 15\'0"', features: ['Upper Floor Terrace', 'Skylight']),
      ];
    }

    // Standard Luxury Apartment Configuration
    final is2BHK = prop.bhk.contains('2');
    final is4BHK = prop.bhk.contains('4');

    if (is2BHK) {
      return [
        FloorPlanRoom(name: 'Living & Dining Hall', roomType: 'livingRoom', areaSqFt: (totalSqft * 0.36).round(), dimensions: '16\'0" x 20\'0"', features: ['East Balcony Deck Access', 'Cross Ventilation']),
        FloorPlanRoom(name: 'Master Suite', roomType: 'masterBedroom', areaSqFt: (totalSqft * 0.26).round(), dimensions: '14\'0" x 15\'0"', features: ['Attached Ensuite Bath', 'Dedicated Wardrobe Niche']),
        FloorPlanRoom(name: 'Guest Bedroom', roomType: 'bedroom', areaSqFt: (totalSqft * 0.18).round(), dimensions: '12\'0" x 13\'6"', features: ['Corner View Window', 'Hardwood Flooring']),
        FloorPlanRoom(name: 'Modular Chef Kitchen', roomType: 'kitchen', areaSqFt: (totalSqft * 0.11).round(), dimensions: '10\'0" x 11\'0"', features: ['Utility Balcony Attached', 'Granite Platform']),
        FloorPlanRoom(name: 'Panoramic Deck Balcony', roomType: 'balcony', areaSqFt: (totalSqft * 0.09).round(), dimensions: '6\'0" x 15\'0"', features: ['Garden Facing View', 'Anti-Skid Tiles']),
      ];
    } else if (is4BHK) {
      return [
        FloorPlanRoom(name: 'Grand Drawing & Dining', roomType: 'livingRoom', areaSqFt: (totalSqft * 0.30).round(), dimensions: '20\'0" x 24\'0"', features: ['Panoramic Deck Access', 'Italian Marble']),
        FloorPlanRoom(name: 'Master Bedroom Suite', roomType: 'masterBedroom', areaSqFt: (totalSqft * 0.20).round(), dimensions: '16\'0" x 18\'0"', features: ['Walk-in Closet', '5-Fixture Ensuite Bath']),
        FloorPlanRoom(name: 'Junior Master Bedroom', roomType: 'bedroom', areaSqFt: (totalSqft * 0.16).round(), dimensions: '14\'0" x 16\'0"', features: ['Attached Bath', 'Private Balcony']),
        FloorPlanRoom(name: 'Guest Bedroom 3', roomType: 'bedroom', areaSqFt: (totalSqft * 0.13).round(), dimensions: '12\'0" x 14\'0"', features: ['Large Bay Window', 'Study Niche']),
        FloorPlanRoom(name: 'Kids Bedroom 4', roomType: 'bedroom', areaSqFt: (totalSqft * 0.10).round(), dimensions: '11\'0" x 13\'0"', features: ['Attached Bath', 'Activity Area']),
        FloorPlanRoom(name: 'Modular Island Kitchen', roomType: 'kitchen', areaSqFt: (totalSqft * 0.11).round(), dimensions: '12\'0" x 14\'0"', features: ['Dry Pantry', 'Dedicated Servant Entry']),
      ];
    }

    // Default 3 BHK
    return [
      FloorPlanRoom(name: 'Living & Dining Hall', roomType: 'livingRoom', areaSqFt: (totalSqft * 0.32).round(), dimensions: '18\'0" x 22\'0"', features: ['East Balcony Deck', 'High-Ceiling Vitrified']),
      FloorPlanRoom(name: 'Master Bedroom Suite', roomType: 'masterBedroom', areaSqFt: (totalSqft * 0.22).round(), dimensions: '14\'0" x 16\'0"', features: ['Attached Bath', 'Walk-in Wardrobe Niche']),
      FloorPlanRoom(name: 'Bedroom 2', roomType: 'bedroom', areaSqFt: (totalSqft * 0.17).round(), dimensions: '12\'0" x 14\'0"', features: ['Corner Bay Window', 'Attached Washroom']),
      FloorPlanRoom(name: 'Bedroom 3 / Study', roomType: 'bedroom', areaSqFt: (totalSqft * 0.14).round(), dimensions: '11\'0" x 13\'0"', features: ['Garden Facing View', 'Dedicated Desk Niche']),
      FloorPlanRoom(name: 'Modular Chef Kitchen', roomType: 'kitchen', areaSqFt: (totalSqft * 0.10).round(), dimensions: '10\'0" x 12\'0"', features: ['Utility Balcony Attached', 'Granite Slab Counter']),
      FloorPlanRoom(name: 'Deck Balcony', roomType: 'balcony', areaSqFt: (totalSqft * 0.05).round(), dimensions: '6\'0" x 16\'0"', features: ['Expressway / Park View', 'Anti-skid Ceramic']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final prop = widget.property;
    final rooms = _resolveRooms(prop);
    final activeRoom = rooms[_selectedRoomIndex.clamp(0, rooms.length - 1)];
    final mediaHeight = MediaQuery.of(context).size.height;
    final carpetArea = prop.carpetAreaSqft > 0 ? prop.carpetAreaSqft : (prop.sqft * 0.78).round();

    return Container(
      height: mediaHeight * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900 architectural background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.layoutTemplate, size: 20, color: Color(0xFFFB923C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Architectural CAD Floor Plan',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.4)),
                            ),
                            child: Text(
                              '${prop.bhk.isNotEmpty ? prop.bhk : "UNIT"} • ${prop.sqft} SQ.FT.',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFB923C)),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${prop.title} • Carpet Area: $carpetArea sq.ft. (${prop.facing} Facing)',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.share2, color: Colors.white70, size: 20),
                  tooltip: 'Share Floor Plan',
                  onPressed: () => PropertyVisualizationService.instance.shareOnWhatsApp(
                    property: prop,
                    visualizationType: 'floor_plan',
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),

          // View Mode Selector + Zoom Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('2D CAD Blueprint'), icon: Icon(LucideIcons.map, size: 14)),
                    ButtonSegment(value: 1, label: Text('3D Isometric View'), icon: Icon(LucideIcons.box, size: 14)),
                  ],
                  selected: {_selectedViewMode},
                  onSelectionChanged: (val) => setState(() => _selectedViewMode = val.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) return const Color(0xFFEA580C);
                      return const Color(0xFF1E293B);
                    }),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                    textStyle: WidgetStateProperty.all(GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.zoomOut, size: 18, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _zoomScale = (_zoomScale - 0.2).clamp(0.8, 2.5);
                      _transformationController.value = Matrix4.identity()..scale(_zoomScale);
                    });
                  },
                ),
                Text('${(_zoomScale * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                IconButton(
                  icon: const Icon(LucideIcons.zoomIn, size: 18, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _zoomScale = (_zoomScale + 0.2).clamp(0.8, 2.5);
                      _transformationController.value = Matrix4.identity()..scale(_zoomScale);
                    });
                  },
                ),
              ],
            ),
          ),

          // Main Interactive Architectural Canvas
          Expanded(
            child: InteractiveViewer(
              minScale: 0.7,
              maxScale: 3.5,
              transformationController: _transformationController,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720, maxHeight: 440),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1329), // CAD Blueprint Navy
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 8)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        size: const Size(720, 440),
                        painter: _ArchitecturalBlueprintPainter(
                          rooms: rooms,
                          selectedRoomIndex: _selectedRoomIndex,
                          is3DIsometric: _selectedViewMode == 1,
                          facing: prop.facing,
                          totalSqft: prop.sqft,
                          propertyTitle: prop.title,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Room Selector Carousel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: const Color(0xFF111827),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: rooms.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final room = entry.value;
                  final isSelected = idx == _selectedRoomIndex;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${room.name} (${room.areaSqFt} sqft)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedRoomIndex = idx);
                      },
                      selectedColor: const Color(0xFFEA580C),
                      backgroundColor: const Color(0xFF1E293B),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFB923C) : const Color(0xFF334155),
                      ),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Active Room Specs Card + Site Visit CTA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              activeRoom.name,
                              style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.4)),
                            ),
                            child: Text(
                              '${activeRoom.dimensions} • ${activeRoom.areaSqFt} sq.ft.',
                              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFFFB923C)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Features: ${activeRoom.features.isNotEmpty ? activeRoom.features.join(' • ') : "Premium vitrified tiles, UPVC noise-insulating windows"}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SiteVisitBookingScreen(property: prop),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.calendarCheck, size: 15),
                  label: const Text('Book Site Visit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Architectural Blueprint Painter
class _ArchitecturalBlueprintPainter extends CustomPainter {
  final List<FloorPlanRoom> rooms;
  final int selectedRoomIndex;
  final bool is3DIsometric;
  final String facing;
  final int totalSqft;
  final String propertyTitle;

  _ArchitecturalBlueprintPainter({
    required this.rooms,
    required this.selectedRoomIndex,
    required this.is3DIsometric,
    required this.facing,
    required this.totalSqft,
    required this.propertyTitle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw CAD Grid Background
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.35)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (is3DIsometric) {
      _paint3DIsometricView(canvas, size);
    } else {
      _paint2DCadBlueprint(canvas, size);
    }

    // Overlay Header & North Indicator
    _paintNorthIndicator(canvas, size);
  }

  void _paint2DCadBlueprint(Canvas canvas, Size size) {
    final margin = 40.0;
    final planRect = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2 - 20);

    // Exterior Wall Paint
    final wallPaint = Paint()
      ..color = const Color(0xFF38BDF8) // CAD Cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final wallFill = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    // Room Layout Coordinates
    final roomCount = rooms.length;
    final w = planRect.width;
    final h = planRect.height;

    // Generate balanced architectural zoning boxes
    List<Rect> roomRects = [];
    if (roomCount <= 4) {
      // 2x2 grid
      roomRects = [
        Rect.fromLTWH(planRect.left, planRect.top, w * 0.58, h * 0.55), // Living
        Rect.fromLTWH(planRect.left + w * 0.58, planRect.top, w * 0.42, h * 0.55), // Master
        Rect.fromLTWH(planRect.left, planRect.top + h * 0.55, w * 0.48, h * 0.45), // Kitchen
        Rect.fromLTWH(planRect.left + w * 0.48, planRect.top + h * 0.55, w * 0.52, h * 0.45), // Bed 2
      ];
    } else if (roomCount == 5) {
      roomRects = [
        Rect.fromLTWH(planRect.left, planRect.top, w * 0.55, h * 0.58), // Living
        Rect.fromLTWH(planRect.left + w * 0.55, planRect.top, w * 0.45, h * 0.50), // Master
        Rect.fromLTWH(planRect.left + w * 0.55, planRect.top + h * 0.50, w * 0.45, h * 0.50), // Bed 2
        Rect.fromLTWH(planRect.left, planRect.top + h * 0.58, w * 0.32, h * 0.42), // Kitchen
        Rect.fromLTWH(planRect.left + w * 0.32, planRect.top + h * 0.58, w * 0.23, h * 0.42), // Balcony
      ];
    } else {
      // 6 rooms (3 BHK / 4 BHK standard)
      roomRects = [
        Rect.fromLTWH(planRect.left, planRect.top, w * 0.52, h * 0.56), // Living & Dining
        Rect.fromLTWH(planRect.left + w * 0.52, planRect.top, w * 0.48, h * 0.48), // Master Suite
        Rect.fromLTWH(planRect.left + w * 0.52, planRect.top + h * 0.48, w * 0.48, h * 0.52), // Bedroom 2
        Rect.fromLTWH(planRect.left, planRect.top + h * 0.56, w * 0.26, h * 0.44), // Kitchen
        Rect.fromLTWH(planRect.left + w * 0.26, planRect.top + h * 0.56, w * 0.26, h * 0.44), // Bedroom 3
        Rect.fromLTWH(planRect.left + w * 0.05, planRect.top - 12, w * 0.42, 16), // Exterior Balcony Deck
      ];
    }

    // 1. Draw outer building footprint fill & stroke
    canvas.drawRect(planRect, wallFill);

    // 2. Draw each room zone
    for (int i = 0; i < roomRects.length && i < rooms.length; i++) {
      final rRect = roomRects[i];
      final room = rooms[i];
      final isSelected = i == selectedRoomIndex;

      // Fill selected room with highlighting glow
      if (isSelected) {
        final highlightFill = Paint()
          ..color = const Color(0xFFEA580C).withOpacity(0.20)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rRect, highlightFill);

        final highlightBorder = Paint()
          ..color = const Color(0xFFFB923C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(rRect, highlightBorder);
      }

      // Draw interior partition walls
      final interiorWallPaint = Paint()
        ..color = isSelected ? const Color(0xFFFB923C) : const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(rRect, interiorWallPaint);

      // Draw Room Label & Dimensions
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${room.name}\n',
            style: TextStyle(
              color: isSelected ? const Color(0xFFFDBA74) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          TextSpan(
            text: '${room.dimensions} • ${room.areaSqFt} sq.ft.',
            style: TextStyle(
              color: isSelected ? const Color(0xFFFED7AA) : const Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: rRect.width - 12);
      textPainter.paint(
        canvas,
        Offset(
          rRect.center.dx - textPainter.width / 2,
          rRect.center.dy - textPainter.height / 2,
        ),
      );

      // Draw Architectural Door Swing in Room Corner
      _paintDoorSwing(canvas, Offset(rRect.left + 4, rRect.bottom - 4), 16, isSelected);
    }

    // 3. Draw outer structural thick boundary wall
    canvas.drawRect(planRect, wallPaint);

    // 4. Draw Main Entrance Arrow
    final entryPaint = Paint()
      ..color = const Color(0xFF10B981) // Green entrance indicator
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final entryX = planRect.left + planRect.width * 0.18;
    final entryY = planRect.top;
    canvas.drawLine(Offset(entryX, entryY - 14), Offset(entryX, entryY), entryPaint);
    canvas.drawLine(Offset(entryX - 4, entryY - 6), Offset(entryX, entryY), entryPaint);
    canvas.drawLine(Offset(entryX + 4, entryY - 6), Offset(entryX, entryY), entryPaint);

    final entryLabel = TextPainter(
      text: const TextSpan(
        text: 'MAIN ENTRANCE',
        style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    entryLabel.paint(canvas, Offset(entryX - entryLabel.width / 2, entryY - 24));
  }

  void _paint3DIsometricView(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final isoPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final isoFill = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw 3D Isometric Cutaway Cuboid
    const double w = 220;
    const double h = 130;
    const double d = 60; // wall height

    final topP1 = center + const Offset(0, -h / 2);
    final topP2 = center + const Offset(w / 2, -h / 4);
    final topP3 = center + const Offset(0, 0);
    final topP4 = center + const Offset(-w / 2, -h / 4);

    final topPath = Path()
      ..moveTo(topP1.dx, topP1.dy)
      ..lineTo(topP2.dx, topP2.dy)
      ..lineTo(topP3.dx, topP3.dy)
      ..lineTo(topP4.dx, topP4.dy)
      ..close();

    canvas.drawPath(topPath, isoFill);
    canvas.drawPath(topPath, isoPaint);

    // Front Left Wall
    final leftWall = Path()
      ..moveTo(topP4.dx, topP4.dy)
      ..lineTo(topP3.dx, topP3.dy)
      ..lineTo(topP3.dx, topP3.dy + d)
      ..lineTo(topP4.dx, topP4.dy + d)
      ..close();

    final leftFill = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftWall, leftFill);
    canvas.drawPath(leftWall, isoPaint);

    // Front Right Wall
    final rightWall = Path()
      ..moveTo(topP3.dx, topP3.dy)
      ..lineTo(topP2.dx, topP2.dy)
      ..lineTo(topP2.dx, topP2.dy + d)
      ..lineTo(topP3.dx, topP3.dy + d)
      ..close();

    final rightFill = Paint()
      ..color = const Color(0xFF1A2642)
      ..style = PaintingStyle.fill;
    canvas.drawPath(rightWall, rightFill);
    canvas.drawPath(rightWall, isoPaint);

    // Room Partition Lines in Isometric
    final activeRoom = rooms[selectedRoomIndex.clamp(0, rooms.length - 1)];
    final labelPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '3D ISOMETRIC ARCHITECTURAL CUTAWAY\n',
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: 'Active Room: ${activeRoom.name} (${activeRoom.dimensions})\n',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: 'Spatial Volume: ~${(activeRoom.areaSqFt * 10).round()} cu.ft. • 10.5 ft Ceiling Clear Height',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);

    labelPainter.paint(canvas, Offset(size.width / 2 - labelPainter.width / 2, size.height - 55));
  }

  void _paintDoorSwing(Canvas canvas, Offset origin, double radius, bool isSelected) {
    final doorPaint = Paint()
      ..color = isSelected ? const Color(0xFFFB923C).withOpacity(0.8) : const Color(0xFF38BDF8).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(origin, Offset(origin.dx, origin.dy - radius), doorPaint);
    final arcRect = Rect.fromCircle(center: origin, radius: radius);
    canvas.drawArc(arcRect, -1.5708, 1.5708, false, doorPaint);
  }

  void _paintNorthIndicator(Canvas canvas, Size size) {
    final compassOffset = Offset(size.width - 45, 35);
    final compassPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(compassOffset, 14, compassPaint);

    final needlePaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.fill;

    final needlePath = Path()
      ..moveTo(compassOffset.dx, compassOffset.dy - 12)
      ..lineTo(compassOffset.dx - 3.5, compassOffset.dy + 2)
      ..lineTo(compassOffset.dx + 3.5, compassOffset.dy + 2)
      ..close();
    canvas.drawPath(needlePath, needlePaint);

    final nLabel = TextPainter(
      text: TextSpan(
        text: 'N ($facing)',
        style: const TextStyle(color: Color(0xFFFB923C), fontSize: 7.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    nLabel.paint(canvas, Offset(compassOffset.dx - nLabel.width / 2, compassOffset.dy + 16));
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalBlueprintPainter oldDelegate) {
    return oldDelegate.selectedRoomIndex != selectedRoomIndex ||
        oldDelegate.is3DIsometric != is3DIsometric ||
        oldDelegate.rooms != rooms;
  }
}
