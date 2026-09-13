import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class ThreeDPropertyViewerScreen extends StatefulWidget {
  final String propertyTitle;

  const ThreeDPropertyViewerScreen({
    super.key,
    required this.propertyTitle,
  });

  @override
  State<ThreeDPropertyViewerScreen> createState() => _ThreeDPropertyViewerScreenState();
}

class _ThreeDPropertyViewerScreenState extends State<ThreeDPropertyViewerScreen> {
  double _rotationAngle = 0.0;
  double _scale = 1.0;
  int _activeFloor = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.propertyTitle,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // 3D Isometric Architectural Canvas
          Center(
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _scale = (_scale * details.scale).clamp(0.6, 2.5);
                  _rotationAngle += details.rotation;
                });
              },
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateX(0.5)
                  ..rotateZ(_rotationAngle)
                  ..scale(_scale),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.primaryViolet, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryViolet.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Grid lines
                      CustomPaint(
                        size: const Size(320, 320),
                        painter: _IsometricGridPainter(),
                      ),
                      // Living zone
                      Positioned(
                        left: 20,
                        top: 20,
                        width: 140,
                        height: 140,
                        child: _buildZoneCard('Living Hall', '18 × 22 ft', const Color(0xFF4F46E5)),
                      ),
                      // Kitchen zone
                      Positioned(
                        right: 20,
                        top: 20,
                        width: 120,
                        height: 100,
                        child: _buildZoneCard('Agni Kitchen', '12 × 14 ft', const Color(0xFFE11D48)),
                      ),
                      // Master Bedroom zone
                      Positioned(
                        left: 20,
                        bottom: 20,
                        width: 150,
                        height: 130,
                        child: _buildZoneCard('Master Suite', '16 × 18 ft', const Color(0xFF059669)),
                      ),
                      // Balcony zone
                      Positioned(
                        right: 20,
                        bottom: 20,
                        width: 90,
                        height: 150,
                        child: _buildZoneCard('Deck Balcony', '8 × 20 ft', const Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floor Selector & Rotation Controls
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.layers, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text('Floor:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Ground (L1)'),
                        selected: _activeFloor == 1,
                        selectedColor: AppTheme.primaryViolet,
                        onSelected: (_) => setState(() => _activeFloor = 1),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Upper (L2)'),
                        selected: _activeFloor == 2,
                        selectedColor: AppTheme.primaryViolet,
                        onSelected: (_) => setState(() => _activeFloor = 2),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.rotateCw, color: Colors.white),
                    onPressed: () => setState(() => _rotationAngle += 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(String name, String dims, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(dims, style: GoogleFonts.inter(fontSize: 9, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _IsometricGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += 32) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 32) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
