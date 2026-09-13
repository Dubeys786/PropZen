import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../config/maps_config.dart';
import '../theme/app_theme.dart';

/// Web-Compatible, Platform-Agnostic Interactive Property Location Map
/// Works seamlessly across Web, Windows, macOS, Linux, iOS, and Android
/// with zero native TargetPlatform exceptions.
class InteractivePropertyMap extends StatefulWidget {
  final Property property;
  final double? customHeight;
  final bool showAddressCard;
  final bool showHeader;
  final bool showControls;
  final bool isInteractive;

  const InteractivePropertyMap({
    super.key,
    required this.property,
    this.customHeight,
    this.showAddressCard = true,
    this.showHeader = true,
    this.showControls = true,
    this.isInteractive = true,
  });

  @override
  State<InteractivePropertyMap> createState() => _InteractivePropertyMapState();
}

enum MapLayerType { roadmap, satellite, terrain }

class _InteractivePropertyMapState extends State<InteractivePropertyMap>
    with SingleTickerProviderStateMixin {
  late double _lat;
  late double _lng;
  late double _initialLat;
  late double _initialLng;

  double _zoom = 15.0;
  MapLayerType _currentLayer = MapLayerType.roadmap;
  Offset _panOffset = Offset.zero;
  bool _hasError = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _resolveCoordinates();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _pulseController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant InteractivePropertyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.id != widget.property.id ||
        oldWidget.property.latitude != widget.property.latitude ||
        oldWidget.property.longitude != widget.property.longitude) {
      _resolveCoordinates();
      _panOffset = Offset.zero;
      _zoom = 15.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _resolveCoordinates() {
    try {
      final coords = MapsConfig.getCoordinatesForProperty(widget.property);
      _lat = coords['lat'] ?? MapsConfig.defaultLatitude;
      _lng = coords['lng'] ?? MapsConfig.defaultLongitude;

      if (_lat == 0.0 || _lng == 0.0 || _lat.isNaN || _lng.isNaN) {
        _lat = MapsConfig.defaultLatitude;
        _lng = MapsConfig.defaultLongitude;
      }

      _initialLat = _lat;
      _initialLng = _lng;
      _hasError = false;
    } catch (_) {
      _lat = MapsConfig.defaultLatitude;
      _lng = MapsConfig.defaultLongitude;
      _initialLat = _lat;
      _initialLng = _lng;
      _hasError = true;
    }
  }

  void _zoomIn() {
    if (_zoom < 19.0) {
      setState(() => _zoom = math.min(19.0, _zoom + 1.0));
    }
  }

  void _zoomOut() {
    if (_zoom > 11.0) {
      setState(() => _zoom = math.max(11.0, _zoom - 1.0));
    }
  }

  void _recenter() {
    setState(() {
      _lat = _initialLat;
      _lng = _initialLng;
      _panOffset = Offset.zero;
      _zoom = 15.0;
    });
  }

  void _openExternalDirections() async {
    final query = Uri.encodeComponent('${widget.property.title}, ${widget.property.fullAddress}');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_lat,$_lng($query)');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Calculates dynamic Map Tile URL based on standard Slippy Map Tile conventions
  String _getTileUrl(int x, int y, int z) {
    if (_currentLayer == MapLayerType.satellite) {
      // High-res satellite / hybrid tiles
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
    } else if (_currentLayer == MapLayerType.terrain) {
      // Topographic terrain tiles
      return 'https://a.tile.opentopomap.org/$z/$x/$y.png';
    } else {
      // Clean modern Positron / Voyager vector raster tiles
      return 'https://basemaps.cartocdn.com/rastertiles/voyager/$z/$x/$y.png';
    }
  }

  int _lon2tileX(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).floor();
  }

  int _lat2tileY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * (1 << z)).floor();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    // Sensible responsive map container heights
    final responsiveHeight = widget.customHeight ??
        (isDesktop ? 380.0 : (isTablet ? 320.0 : 260.0));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Header
          if (widget.showHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primaryViolet),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Property Location',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.property.sector}, ${widget.property.city}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Get Directions secondary button
                  OutlinedButton.icon(
                    onPressed: _openExternalDirections,
                    icon: const Icon(LucideIcons.navigation, size: 12, color: AppTheme.primaryViolet),
                    label: Text(
                      'Get Directions',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: Color(0xFFDDD6FE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],

          // Interactive Map View Canvas
          SizedBox(
            height: responsiveHeight,
            width: double.infinity,
            child: _hasError ? _buildFallbackCard() : _buildInteractiveMapArea(responsiveHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapArea(double height) {
    final z = _zoom.floor();
    final centerTileX = _lon2tileX(_lng, z);
    final centerTileY = _lat2tileY(_lat, z);

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // 1. Gesture Detector for Panning / Dragging
        GestureDetector(
          onPanUpdate: widget.isInteractive
              ? (details) {
                  setState(() {
                    _panOffset += details.delta;
                  });
                }
              : null,
          child: Container(
            color: _currentLayer == MapLayerType.satellite ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            child: Stack(
              children: [
                // 3x3 Tile Grid rendered smoothly
                Positioned.fill(
                  child: Center(
                    child: Transform.translate(
                      offset: _panOffset,
                      child: SizedBox(
                        width: 768,
                        height: 768,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 9,
                          itemBuilder: (ctx, i) {
                            final dx = (i % 3) - 1;
                            final dy = (i ~/ 3) - 1;
                            final tileX = centerTileX + dx;
                            final tileY = centerTileY + dy;
                            final url = _getTileUrl(tileX, tileY, z);

                            return Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildVectorFallbackTile(dx, dy),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Map Grid overlay & Vector Roads
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(
                      isDark: _currentLayer == MapLayerType.satellite,
                      panOffset: _panOffset,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Pulsing Pinpoint Marker for Current Property
        Center(
          child: Transform.translate(
            offset: _panOffset + const Offset(0, -20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Property Name & Price Callout Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: AppTheme.primaryViolet, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.emeraldSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          widget.property.title,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.property.formattedPrice,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryViolet,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Pulsing Pin Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(LucideIcons.home, color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Map Controls (Zoom +, Zoom -, Layer Switcher, Recenter)
        if (widget.showControls) ...[
          // Top Right Controls (Layer Switcher)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLayerButton(MapLayerType.roadmap, 'Map'),
                  const SizedBox(width: 3),
                  _buildLayerButton(MapLayerType.satellite, 'Satellite'),
                  const SizedBox(width: 3),
                  _buildLayerButton(MapLayerType.terrain, 'Terrain'),
                ],
              ),
            ),
          ),

          // Bottom Right Zoom Controls & Recenter
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapActionButton(
                  icon: LucideIcons.plus,
                  onTap: _zoomIn,
                  tooltip: 'Zoom In',
                ),
                const SizedBox(height: 6),
                _buildMapActionButton(
                  icon: LucideIcons.minus,
                  onTap: _zoomOut,
                  tooltip: 'Zoom Out',
                ),
                const SizedBox(height: 6),
                _buildMapActionButton(
                  icon: LucideIcons.crosshair,
                  onTap: _recenter,
                  tooltip: 'Recenter on Property',
                ),
              ],
            ),
          ),

          // Bottom Left Coordinates Badge
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Lat: ${_lat.toStringAsFixed(4)} • Lng: ${_lng.toStringAsFixed(4)} • Zoom: ${_zoom.toStringAsFixed(0)}x',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLayerButton(MapLayerType type, String label) {
    final isSelected = _currentLayer == type;
    return InkWell(
      onTap: () => setState(() => _currentLayer = type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 16, color: const Color(0xFF1E293B)),
          ),
        ),
      ),
    );
  }

  Widget _buildVectorFallbackTile(int dx, int dy) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Center(
        child: Icon(LucideIcons.map, size: 24, color: Colors.black.withOpacity(0.08)),
      ),
    );
  }

  Widget _buildFallbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.mapPinOff, size: 32, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text(
              'Location map unavailable',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Property location: ${widget.property.sector}, ${widget.property.city}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openExternalDirections,
              icon: const Icon(LucideIcons.navigation, size: 13),
              label: const Text('Open Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for subtle aesthetic grid and expressway lines
class _MapGridPainter extends CustomPainter {
  final bool isDark;
  final Offset panOffset;

  _MapGridPainter({required this.isDark, required this.panOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : const Color(0xFF94A3B8).withOpacity(0.12)
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.12) : const Color(0xFFCBD5E1).withOpacity(0.5)
      ..strokeWidth = 3.0;

    final step = 60.0;
    final offsetX = panOffset.dx % step;
    final offsetY = panOffset.dy % step;

    for (double x = offsetX - step; x < size.width + step; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = offsetY - step; y < size.height + step; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Expressway curved arterial line
    final path = Path()
      ..moveTo(0, size.height * 0.75 + panOffset.dy * 0.5)
      ..quadraticBezierTo(
        size.width * 0.4 + panOffset.dx * 0.5,
        size.height * 0.35 + panOffset.dy * 0.5,
        size.width,
        size.height * 0.2 + panOffset.dy * 0.5,
      );

    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset || oldDelegate.isDark != isDark;
  }
}
