import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/ai_home_project.dart';
import '../../theme/app_theme.dart';

/// Visual Interactive Compass Widget for Vastu & Road Direction Selection
class VisualCompassSelector extends StatefulWidget {
  final CompassDirection selectedRoadDirection;
  final CompassDirection selectedEntranceDirection;
  final ValueChanged<CompassDirection> onRoadDirectionChanged;
  final ValueChanged<CompassDirection> onEntranceDirectionChanged;

  const VisualCompassSelector({
    super.key,
    required this.selectedRoadDirection,
    required this.selectedEntranceDirection,
    required this.onRoadDirectionChanged,
    required this.onEntranceDirectionChanged,
  });

  @override
  State<VisualCompassSelector> createState() => _VisualCompassSelectorState();
}

class _VisualCompassSelectorState extends State<VisualCompassSelector> {
  // Mode: 0 = Main Road Direction, 1 = Main Entrance Direction
  int _activeMode = 0;

  @override
  Widget build(BuildContext context) {
    final currentTargetDirection = _activeMode == 0 ? widget.selectedRoadDirection : widget.selectedEntranceDirection;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector Switch: Road vs Entrance
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeMode = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeMode == 0 ? AppTheme.primaryViolet : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _activeMode == 0 ? AppTheme.subtleCardShadow : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 15,
                            color: _activeMode == 0 ? Colors.white : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Main Road (${widget.selectedRoadDirection.code})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _activeMode == 0 ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeMode = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeMode == 1 ? AppTheme.primaryViolet : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _activeMode == 1 ? AppTheme.subtleCardShadow : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.doorOpen,
                            size: 15,
                            color: _activeMode == 1 ? Colors.white : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Entrance (${widget.selectedEntranceDirection.code})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _activeMode == 1 ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Visual Circular Compass Dial
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Dial Ring
                  CustomPaint(
                    size: const Size(250, 250),
                    painter: _CompassDialPainter(
                      activeDirection: currentTargetDirection,
                      accentColor: AppTheme.primaryViolet,
                    ),
                  ),

                  // Center Needle & Status Core
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryViolet.withOpacity(0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeMode == 0 ? LucideIcons.compass : LucideIcons.home,
                          size: 20,
                          color: AppTheme.primaryViolet,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentTargetDirection.code,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${currentTargetDirection.angleDegrees.toInt()}°',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 8 Directional Touch Nodes
                  ...CompassDirection.values.map((dir) {
                    final isSelected = dir == currentTargetDirection;
                    final isRoad = dir == widget.selectedRoadDirection;
                    final isEntrance = dir == widget.selectedEntranceDirection;

                    final radius = 104.0;
                    final rad = (dir.angleDegrees - 90) * (math.pi / 180.0);
                    final dx = radius * math.cos(rad);
                    final dy = radius * math.sin(rad);

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: GestureDetector(
                        onTap: () {
                          if (_activeMode == 0) {
                            widget.onRoadDirectionChanged(dir);
                          } else {
                            widget.onEntranceDirectionChanged(dir);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.primaryViolet
                                : (isRoad || isEntrance
                                    ? AppTheme.primaryViolet.withOpacity(0.15)
                                    : AppTheme.surfaceHighlight),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryViolet
                                  : (isRoad || isEntrance
                                      ? AppTheme.primaryViolet
                                      : AppTheme.borderLight),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? AppTheme.subtleCardShadow : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dir.code,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Selected Direction Details & Vastu Guidance
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.purpleSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderPurple),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 16, color: AppTheme.primaryViolet),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentTargetDirection.label} Alignment',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentTargetDirection.vastuSignificance,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
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
}

/// Custom Dial Painter
class _CompassDialPainter extends CustomPainter {
  final CompassDirection activeDirection;
  final Color accentColor;

  _CompassDialPainter({
    required this.activeDirection,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Outer Circle Track
    final ringPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Inner Dashed Track
    final innerRingPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 24, innerRingPaint);

    // Cardinal Spokes (N, E, S, W)
    final spokePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 360; i += 45) {
      final rad = (i - 90) * (math.pi / 180.0);
      final p1 = Offset(center.dx + (radius - 18) * math.cos(rad), center.dy + (radius - 18) * math.sin(rad));
      final p2 = Offset(center.dx + radius * math.cos(rad), center.dy + radius * math.sin(rad));
      canvas.drawLine(p1, p2, spokePaint);
    }

    // Active Direction Glow Arc
    final activeRad = (activeDirection.angleDegrees - 90) * (math.pi / 180.0);
    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      activeRad - 0.25,
      0.5,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.activeDirection != activeDirection;
  }
}
