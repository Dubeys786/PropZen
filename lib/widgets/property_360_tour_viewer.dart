import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../models/property_visualization_model.dart';
import '../services/property_visualization_service.dart';
import '../screens/site_visit_booking_screen.dart';
import '../theme/app_theme.dart';

/// Interactive 360° Virtual Property Tour Viewer
/// Supports property-specific 360 room-by-room panoramas, interactive pan/zoom,
/// room filter pills, fullscreen mode, WhatsApp sharing, and direct site visit bridge.
class Property360TourViewer extends StatefulWidget {
  final Property property;

  const Property360TourViewer({super.key, required this.property});

  static void show(BuildContext context, Property property) {
    PropertyVisualizationService.instance.logVisualizationEvent(
      eventName: 'virtual_tour_opened',
      propertyId: property.id,
      propertyTitle: property.title,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Property360TourViewer(property: property),
    );
  }

  @override
  State<Property360TourViewer> createState() => _Property360TourViewerState();
}

class _Property360TourViewerState extends State<Property360TourViewer> {
  bool _isFullscreen = false;
  double _zoomLevel = 1.0;
  bool _isLoading = true;
  bool _hasImageError = false;
  VirtualTourRoom? _selectedRoom;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _initializeTour();
  }

  @override
  void didUpdateWidget(Property360TourViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property.id != widget.property.id) {
      _initializeTour();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _initializeTour() {
    final tour = widget.property.virtualTour;
    if (tour != null && tour.rooms.isNotEmpty) {
      _selectedRoom = tour.rooms.first;
    } else {
      _selectedRoom = null;
    }

    _isLoading = true;
    _hasImageError = false;
    _zoomLevel = 1.0;
    _transformationController.value = Matrix4.identity();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _selectRoom(VirtualTourRoom room) {
    if (_selectedRoom?.id == room.id && !_hasImageError) return;

    setState(() {
      _selectedRoom = room;
      _isLoading = true;
      _hasImageError = false;
      _zoomLevel = 1.0;
      _transformationController.value = Matrix4.identity();
    });

    PropertyVisualizationService.instance.logVisualizationEvent(
      eventName: 'virtual_tour_room_switched',
      propertyId: widget.property.id,
      propertyTitle: widget.property.title,
      extraData: {'room_id': room.id, 'room_name': room.name},
    );

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  IconData _getRoomIcon(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'bed':
        return LucideIcons.bed;
      case 'sun':
        return LucideIcons.sun;
      case 'utensils':
      case 'kitchen':
        return LucideIcons.utensils;
      case 'bath':
      case 'bathroom':
        return LucideIcons.bath;
      case 'compass':
        return LucideIcons.compass;
      case 'sofa':
      default:
        return LucideIcons.sofa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prop = widget.property;
    final tour = prop.virtualTour;
    final hasTour = prop.hasVirtualTour && (tour != null && tour.isAvailable);
    final rooms = tour?.rooms ?? const [];

    final mediaHeight = MediaQuery.of(context).size.height;
    final dialogHeight = _isFullscreen ? mediaHeight : mediaHeight * 0.90;

    return Container(
      height: dialogHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120), // Premium dark theater mode
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Header Bar
          _buildHeaderBar(prop, hasTour),
          const Divider(height: 1, color: Color(0xFF1E293B)),

          // 2. Room Selector Filter Pills (Visible ONLY if multiple rooms exist)
          if (hasTour && rooms.isNotEmpty) _buildRoomSelectorBar(rooms),

          // 3. 360 Tour Viewer Canvas / Fallback State
          Expanded(
            child: hasTour ? _buildActiveTourView(prop, tour!) : _buildUnavailableState(prop),
          ),

          // 4. Bottom Action Bar & Site Visit Bridge
          _buildBottomBar(prop, hasTour),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(Property prop, bool hasTour) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.glasses, size: 18, color: Color(0xFFA78BFA)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '360° Virtual Tour',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasTour ? const Color(0xFF10B981).withOpacity(0.2) : Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasTour ? 'HD 360° PANORAMA' : 'COMING SOON',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: hasTour ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _selectedRoom != null
                      ? '${prop.title} • ${_selectedRoom!.name} (${prop.sector}, ${prop.city})'
                      : '${prop.title} • ${prop.sector}, ${prop.city}',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // WhatsApp Share
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white70, size: 19),
            tooltip: 'Share Virtual Tour',
            onPressed: () => PropertyVisualizationService.instance.shareOnWhatsApp(
              property: prop,
              visualizationType: '360_tour',
              roomName: _selectedRoom?.name,
            ),
          ),
          // Fullscreen Toggle
          IconButton(
            icon: Icon(_isFullscreen ? LucideIcons.minimize2 : LucideIcons.maximize2, color: Colors.white, size: 19),
            tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
            onPressed: () => setState(() => _isFullscreen = !_isFullscreen),
          ),
          // Close Button
          IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
            tooltip: 'Close Tour',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelectorBar(List<VirtualTourRoom> rooms) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: rooms.map((room) {
            final isSelected = _selectedRoom?.id == room.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _selectRoom(room),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFA78BFA) : const Color(0xFF334155),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryViolet.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRoomIcon(room.iconType),
                        size: 13,
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        room.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                        ),
                      ),
                      if (room.area.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.2) : Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            room.area,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveTourView(Property prop, VirtualTourData tour) {
    final activeRoom = _selectedRoom ?? tour.initialRoom;
    final imageUrl = activeRoom?.imageUrl ?? '';

    if (imageUrl.isEmpty) {
      return _buildUnavailableState(prop);
    }

    final uniqueKey = ValueKey('${prop.id}-${activeRoom?.id ?? "default"}');

    return Stack(
      key: uniqueKey,
      children: [
        // Interactive 360 Canvas with Pan & Zoom
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.8,
            maxScale: 2.5,
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // High-Res Panoramic 360 Backdrop
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_hasImageError) {
                          setState(() => _hasImageError = true);
                        }
                      });
                      return _buildImageErrorView();
                    },
                  ),

                  // Ambient Vignette Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),

                  // 360 Orientation Compass & Drag Indicator Overlay
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.move, color: Color(0xFFA78BFA), size: 14),
                              const SizedBox(width: 8),
                              Text(
                                'Drag & Swipe to Explore 360° View',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Room Info Badge (Bottom-Left)
                  if (activeRoom != null)
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getRoomIcon(activeRoom.iconType), size: 13, color: const Color(0xFFA78BFA)),
                            const SizedBox(width: 6),
                            Text(
                              activeRoom.area.isNotEmpty
                                  ? '${activeRoom.name} (${activeRoom.area})'
                                  : activeRoom.name,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Smooth Loading Transition Overlay
        if (_isLoading)
          Container(
            color: const Color(0xFF0B1120),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFA78BFA), strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    _selectedRoom != null ? 'Loading ${_selectedRoom!.name}...' : 'Loading 360° Environment...',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
              ),
              child: const Icon(LucideIcons.alertTriangle, size: 36, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load this 360° view',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your internet connection or try again.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedRoom != null) {
                  _selectRoom(_selectedRoom!);
                } else {
                  _initializeTour();
                }
              },
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState(Property prop) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(LucideIcons.glasses, size: 40, color: Color(0xFFA78BFA)),
            ),
            const SizedBox(height: 16),
            Text(
              '360° Virtual Tour Not Available Yet',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'The verified dealer is currently capturing high-resolution 360° spherical scans for ${prop.title}. You can explore the verified 2D/3D Floor Plan or schedule a site visit.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SiteVisitBookingScreen(property: prop),
                  ),
                );
              },
              icon: const Icon(LucideIcons.calendarCheck, size: 16),
              label: const Text('Schedule In-Person Site Visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(Property prop, bool hasTour) {
    final tour = prop.virtualTour;
    final webUrl = _selectedRoom?.panoramaEmbedUrl ?? tour?.panoramaUrl ?? prop.virtualTourUrl;
    final hasValidWebUrl = webUrl != null && webUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          if (hasTour) ...[
            // Zoom Out
            IconButton(
              icon: const Icon(LucideIcons.zoomOut, color: Colors.white70, size: 17),
              tooltip: 'Zoom Out',
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel - 0.2).clamp(0.8, 2.5);
                  _transformationController.value = Matrix4.identity()..scale(_zoomLevel);
                });
              },
            ),
            Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
            // Zoom In
            IconButton(
              icon: const Icon(LucideIcons.zoomIn, color: Colors.white70, size: 17),
              tooltip: 'Zoom In',
              onPressed: () {
                setState(() {
                  _zoomLevel = (_zoomLevel + 0.2).clamp(0.8, 2.5);
                  _transformationController.value = Matrix4.identity()..scale(_zoomLevel);
                });
              },
            ),
            const SizedBox(width: 8),

            // Open in External Web Viewer (Kuula / Matterport) if configured
            if (hasValidWebUrl)
              OutlinedButton.icon(
                onPressed: () {
                  final formattedUrl = PropertyVisualizationService.instance.format360TourEmbedUrl(webUrl);
                  launchUrl(Uri.parse(formattedUrl), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(LucideIcons.externalLink, size: 13),
                label: const Text('Open Web Viewer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
          ],

          const Spacer(),

          // Book Site Visit Connection (Passes CURRENT property)
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
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
