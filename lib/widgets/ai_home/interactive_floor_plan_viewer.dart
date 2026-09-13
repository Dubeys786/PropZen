import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/ai_home_project.dart';
import '../../theme/app_theme.dart';

/// High-Resolution Interactive 2D CAD Floor Plan Viewer with Zoom, Pan, and Room Highlights
class InteractiveFloorPlanViewer extends StatefulWidget {
  final AiFloorPlan floorPlan;
  final AiHomeProject project;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onRegenerate;
  final VoidCallback? onCustomize;

  const InteractiveFloorPlanViewer({
    super.key,
    required this.floorPlan,
    required this.project,
    this.onDownload,
    this.onShare,
    this.onRegenerate,
    this.onCustomize,
  });

  @override
  State<InteractiveFloorPlanViewer> createState() => _InteractiveFloorPlanViewerState();
}

class _InteractiveFloorPlanViewerState extends State<InteractiveFloorPlanViewer> {
  final TransformationController _transformationController = TransformationController();
  AiFloorPlanRoom? _selectedRoom;
  bool _showDimensions = true;
  bool _showVastuTags = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final Matrix4 current = _transformationController.value;
    _transformationController.value = current.scaled(1.25, 1.25);
  }

  void _zoomOut() {
    final Matrix4 current = _transformationController.value;
    _transformationController.value = current.scaled(0.8, 0.8);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
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
              '${widget.floorPlan.floorTitle} — Fullscreen CAD View',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.download, color: Colors.white),
                onPressed: widget.onDownload,
              ),
              IconButton(
                icon: const Icon(LucideIcons.share2, color: Colors.white),
                onPressed: widget.onShare,
              ),
            ],
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildCadPlanCanvas(isDark: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Viewer Toolbar & Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Vastu Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 14, color: AppTheme.emeraldSuccess),
                    const SizedBox(width: 5),
                    Text(
                      'Vastu Score: ${widget.floorPlan.vastuScore}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emeraldSuccess,
                      ),
                    ),
                  ],
                ),
              ),

              // Zoom & View Action Buttons
              Row(
                children: [
                  _buildToolButton(LucideIcons.zoomIn, 'Zoom In', _zoomIn),
                  const SizedBox(width: 6),
                  _buildToolButton(LucideIcons.zoomOut, 'Zoom Out', _zoomOut),
                  const SizedBox(width: 6),
                  _buildToolButton(LucideIcons.rotateCcw, 'Reset', _resetZoom),
                  const SizedBox(width: 6),
                  _buildToolButton(LucideIcons.maximize2, 'Fullscreen', _openFullscreenModal),
                ],
              ),
            ],
          ),
        ),

        // CAD Floor Plan Interactive Viewport
        Container(
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            border: const Border(
              left: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Grid Background
              Positioned.fill(
                child: CustomPaint(
                  painter: _BlueprintGridPainter(),
                ),
              ),

              // Interactive Pan & Zoom Canvas
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.8,
                maxScale: 3.5,
                boundaryMargin: const EdgeInsets.all(40),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildCadPlanCanvas(isDark: false),
                  ),
                ),
              ),

              // Dimension / Vastu overlay toggles overlaying top-left
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.subtleCardShadow,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _showDimensions = !_showDimensions),
                        child: Row(
                          children: [
                            Icon(
                              _showDimensions ? LucideIcons.checkSquare : LucideIcons.square,
                              size: 14,
                              color: AppTheme.primaryViolet,
                            ),
                            const SizedBox(width: 4),
                            Text('Dimensions', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _showVastuTags = !_showVastuTags),
                        child: Row(
                          children: [
                            Icon(
                              _showVastuTags ? LucideIcons.checkSquare : LucideIcons.square,
                              size: 14,
                              color: AppTheme.primaryViolet,
                            ),
                            const SizedBox(width: 4),
                            Text('Vastu Zones', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected Room Tooltip Banner
              if (_selectedRoom != null)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.info, size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedRoom!.name} (${_selectedRoom!.dimensions})',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                '${_selectedRoom!.vastuZone} • ${_selectedRoom!.description}',
                                style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white.withOpacity(0.9)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedRoom = null),
                          child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCadPlanCanvas({required bool isDark}) {
    final length = widget.project.plotLength;
    final width = widget.project.plotWidth;
    final aspectRatio = width / (length > 0 ? length : 50);

    // Bounded drawing box
    final boxWidth = 320.0;
    final boxHeight = (320.0 / (aspectRatio > 0 ? aspectRatio : 0.4)).clamp(220.0, 320.0);

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF0F172A),
          width: 3,
        ),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Stack(
        children: [
          // Plot Boundary Dimensions Labels
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${widget.project.plotWidth.toStringAsFixed(0)} ${widget.project.plotUnit.symbol}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : AppTheme.textMuted,
                ),
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
                  '${widget.project.plotLength.toStringAsFixed(0)} ${widget.project.plotUnit.symbol}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          ),

          // Render Rooms from Floor Plan
          ...widget.floorPlan.rooms.map((room) {
            final isSelected = _selectedRoom?.id == room.id;
            final roomLeft = room.x * boxWidth;
            final roomTop = room.y * boxHeight;
            final roomW = room.width * boxWidth;
            final roomH = room.height * boxHeight;

            final roomBgColor = _getRoomColor(room.type, isDark, isSelected);

            return Positioned(
              left: roomLeft,
              top: roomTop,
              width: roomW,
              height: roomH,
              child: GestureDetector(
                onTap: () => setState(() => _selectedRoom = room),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: roomBgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryViolet
                          : (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getRoomIcon(room.type),
                        size: 14,
                        color: isSelected ? AppTheme.primaryViolet : (isDark ? Colors.white70 : AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        room.name,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryViolet : (isDark ? Colors.white : AppTheme.textPrimary),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_showDimensions)
                        Text(
                          room.dimensions,
                          style: GoogleFonts.inter(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white60 : AppTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (_showVastuTags && roomW > 70 && roomH > 50)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldSuccess.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            room.vastuZone.split(' ').first,
                            style: GoogleFonts.inter(
                              fontSize: 6.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.emeraldSuccess,
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

  Color _getRoomColor(String type, bool isDark, bool isSelected) {
    if (isSelected) {
      return AppTheme.primaryViolet.withOpacity(isDark ? 0.35 : 0.15);
    }
    if (isDark) {
      switch (type) {
        case 'living':
          return const Color(0xFF334155);
        case 'kitchen':
          return const Color(0xFF451A03).withOpacity(0.5);
        case 'pooja':
          return const Color(0xFF78350F).withOpacity(0.5);
        case 'bedroom':
          return const Color(0xFF1E293B);
        case 'parking':
          return const Color(0xFF0F172A);
        default:
          return const Color(0xFF1E293B);
      }
    } else {
      switch (type) {
        case 'living':
          return const Color(0xFFEFF6FF); // Light blue
        case 'kitchen':
          return const Color(0xFFFEF3C7); // Light amber
        case 'pooja':
          return const Color(0xFFFDF4FF); // Light purple
        case 'bedroom':
          return const Color(0xFFF0FDF4); // Light emerald
        case 'parking':
          return const Color(0xFFF1F5F9); // Light slate
        default:
          return const Color(0xFFF8FAFC);
      }
    }
  }

  IconData _getRoomIcon(String type) {
    switch (type) {
      case 'living':
        return LucideIcons.sofa;
      case 'kitchen':
        return LucideIcons.utensils;
      case 'pooja':
        return LucideIcons.sparkles;
      case 'bedroom':
        return LucideIcons.bed;
      case 'parking':
        return LucideIcons.car;
      case 'entrance':
        return LucideIcons.doorOpen;
      default:
        return LucideIcons.layout;
    }
  }

  Widget _buildToolButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHighlight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Icon(icon, size: 15, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

/// Architectural Blueprint Grid Painter
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.6)
      ..strokeWidth = 0.6;

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
