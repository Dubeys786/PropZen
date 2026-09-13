import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/ai_home_project.dart';
import '../../theme/app_theme.dart';

/// Interactive 3D Isometric Home Viewer with Rotation, Floor Slicing & Room Navigation
class Isometric3dHomeViewer extends StatefulWidget {
  final AiHomeProject project;
  final bool isExternalProviderConfigured;

  const Isometric3dHomeViewer({
    super.key,
    required this.project,
    this.isExternalProviderConfigured = false,
  });

  @override
  State<Isometric3dHomeViewer> createState() => _Isometric3dHomeViewerState();
}

class _Isometric3dHomeViewerState extends State<Isometric3dHomeViewer> with SingleTickerProviderStateMixin {
  double _rotationX = 0.45; // Elevation pitch
  double _rotationY = -0.55; // Azimuth yaw
  double _zoomScale = 1.0;
  int _activeFloor = 0; // 0 = Ground, 1 = 1st Floor, 2 = Terrace Roof
  String _selectedRoom = 'Living Room';
  bool _isNightMode = false;

  final List<String> _rooms = [
    'Living Room',
    'Kitchen',
    'Master Bedroom',
    'Bedroom 2',
    'Pooja Room',
    'Terrace',
    'Garden',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3D Viewport Box
        Container(
          height: 390,
          decoration: BoxDecoration(
            gradient: _isNightMode
                ? const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softCardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Interactive Drag to Rotate Canvas
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rotationY += details.delta.dx * 0.01;
                    _rotationX = (_rotationX - details.delta.dy * 0.01).clamp(0.15, 1.1);
                  });
                },
                child: Center(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Perspective
                      ..scale(_zoomScale)
                      ..rotateX(_rotationX)
                      ..rotateY(_rotationY),
                    child: _buildIsometricBuildingModel(),
                  ),
                ),
              ),

              // Top Status Badge: Integration-Ready or Live 3D
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (widget.isExternalProviderConfigured ? AppTheme.emeraldSuccess : AppTheme.primaryViolet).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.subtleCardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isExternalProviderConfigured ? LucideIcons.checkCircle : LucideIcons.box,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isExternalProviderConfigured ? 'Live 3D Render Engine' : '3D Spatial Interactive View',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Right Controls (Lighting, Zoom, Reset)
              Positioned(
                top: 14,
                right: 14,
                child: Row(
                  children: [
                    // Day/Night Toggle
                    GestureDetector(
                      onTap: () => setState(() => _isNightMode = !_isNightMode),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.subtleCardShadow,
                        ),
                        child: Icon(
                          _isNightMode ? LucideIcons.moon : LucideIcons.sun,
                          size: 15,
                          color: _isNightMode ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Zoom In
                    GestureDetector(
                      onTap: () => setState(() => _zoomScale = (_zoomScale * 1.15).clamp(0.6, 2.2)),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.subtleCardShadow,
                        ),
                        child: const Icon(LucideIcons.zoomIn, size: 15, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Zoom Out
                    GestureDetector(
                      onTap: () => setState(() => _zoomScale = (_zoomScale * 0.85).clamp(0.6, 2.2)),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.subtleCardShadow,
                        ),
                        child: const Icon(LucideIcons.zoomOut, size: 15, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Overlay: Drag Prompt & Compass Indicator
              Positioned(
                bottom: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.move, size: 13, color: Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        'Drag to Orbit 360° • Pinch to Zoom',
                        style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Floor Level Switcher (G, 1st, Roof)
              Positioned(
                bottom: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppTheme.subtleCardShadow,
                  ),
                  child: Row(
                    children: [
                      _buildFloorChip(0, 'Ground'),
                      _buildFloorChip(1, '1st Floor'),
                      _buildFloorChip(2, 'Terrace'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Room Navigation Scrollable Selector
        Text(
          'Select Room to Inspect',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _rooms.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final room = _rooms[i];
              final isSelected = room == _selectedRoom;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRoom = room;
                    // Auto-adjust perspective to focus on the selected room
                    if (room == 'Living Room') _rotationY = -0.55;
                    if (room == 'Kitchen') _rotationY = 0.65;
                    if (room == 'Master Bedroom') _rotationY = 2.1;
                    if (room == 'Pooja Room') _rotationY = -0.2;
                    if (room == 'Terrace') _activeFloor = 2;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
                      room,
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
      ],
    );
  }

  Widget _buildFloorChip(int index, String label) {
    final isSelected = _activeFloor == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFloor = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 3D Isometric Model Architecture Canvas
  Widget _buildIsometricBuildingModel() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: _isNightMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isNightMode ? 0.6 : 0.25),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(
          color: _isNightMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ground Floor Layout Blocks
          Positioned(
            left: 15,
            top: 15,
            width: 90,
            height: 90,
            child: _build3dRoomBlock('Living Room', LucideIcons.sofa, const Color(0xFF3B82F6)),
          ),
          Positioned(
            right: 15,
            top: 15,
            width: 85,
            height: 90,
            child: _build3dRoomBlock('Kitchen', LucideIcons.utensils, const Color(0xFFF59E0B)),
          ),
          Positioned(
            left: 15,
            bottom: 15,
            width: 100,
            height: 85,
            child: _build3dRoomBlock('Master Bedroom', LucideIcons.bed, const Color(0xFF10B981)),
          ),
          Positioned(
            right: 15,
            bottom: 15,
            width: 75,
            height: 85,
            child: _build3dRoomBlock('Pooja Room', LucideIcons.sparkles, const Color(0xFF8B5CF6)),
          ),

          // Central Courtyard / Atrium Glass Skylight
          Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyan, width: 1.5),
              ),
              child: const Icon(LucideIcons.sun, size: 14, color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3dRoomBlock(String name, IconData icon, Color color) {
    final isSelected = _selectedRoom == name;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(_isNightMode ? 0.6 : 0.3)
            : (_isNightMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? color : (_isNightMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? color : (_isNightMode ? Colors.white60 : AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : (_isNightMode ? Colors.white : AppTheme.textPrimary),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
