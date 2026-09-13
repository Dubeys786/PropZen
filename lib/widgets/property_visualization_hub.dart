import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../routes/app_routes.dart';
import 'property_360_tour_viewer.dart';
import 'property_3d_model_viewer.dart';
import 'property_floor_plan_viewer.dart';
import 'property_vastu_guidance_viewer.dart';
import '../theme/app_theme.dart';

/// Experience This Property — Premium Visualization Tools Hub
/// Features 5 interactive tools in a balanced, full-width responsive grid:
/// 1. 360° Virtual Tour
/// 2. Explore in 3D
/// 3. View in AR
/// 4. Floor Plan
/// 5. Vastu Guidance
class PropertyVisualizationHub extends StatelessWidget {
  final Property property;

  const PropertyVisualizationHub({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon + Title + PROPERTY TOOLS Badge + Subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 17),
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
                            'Experience This Property',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PROPERTY TOOLS',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryViolet,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Explore this property virtually with 360° tours, 3D visualization, AR, floor plans and Vastu insights.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Full-Width Responsive 5-Tool Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int crossAxisCount = 1;
              double childAspectRatio = 0.85;

              if (width >= 1150) {
                // Desktop: 5 columns in 1 single row
                crossAxisCount = 5;
                childAspectRatio = 0.52; // ~390–420px height
              } else if (width >= 768) {
                // Tablet: 3 columns
                crossAxisCount = 3;
                childAspectRatio = 0.56; // ~390–415px height
              } else if (width >= 500) {
                // Small tablet / Mobile wide: 2 columns
                crossAxisCount = 2;
                childAspectRatio = 0.62; // ~385–410px height
              } else {
                // Compact mobile: 2 columns if width >= 340, else 1
                crossAxisCount = width >= 340 ? 2 : 1;
                childAspectRatio = width >= 340 ? 0.44 : 0.80;
              }

              // Dynamic Floor Plan Badge from current property configuration
              final dynamicBhkBadge = property.bhk.isNotEmpty
                  ? property.bhk
                  : (property.propertyType.isNotEmpty ? property.propertyType : 'LAYOUT');

              final tools = [
                // Card 1: 360° Virtual Tour (Purple Accent)
                _ToolData(
                  title: '360° Virtual Tour',
                  description: 'Take an immersive 360° walkthrough of this property and explore every space before your visit.',
                  benefits: const [
                    'HD panoramic view',
                    'Explore every room',
                    'View the property remotely',
                  ],
                  ctaLabel: property.hasVirtualTour ? 'Start Virtual Tour →' : 'Coming Soon',
                  badge: property.hasVirtualTour ? 'LIVE' : 'SOON',
                  isAvailable: property.hasVirtualTour,
                  icon: LucideIcons.glasses,
                  accentColor: const Color(0xFF7C3AED),
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  onTap: property.hasVirtualTour
                      ? () => Property360TourViewer.show(context, property)
                      : () {},
                ),

                // Card 2: Explore in 3D (Teal Accent)
                _ToolData(
                  title: 'Explore in 3D',
                  description: 'Explore an interactive 3D model of the property and understand its layout, spaces and interiors.',
                  benefits: const [
                    'Interactive 3D model',
                    'Rotate and zoom',
                    'Explore the layout',
                  ],
                  ctaLabel: property.has3DModel ? 'Open 3D View →' : 'Coming Soon',
                  badge: property.has3DModel ? '3D MODEL' : 'SOON',
                  isAvailable: property.has3DModel,
                  icon: LucideIcons.box,
                  accentColor: const Color(0xFF0D9488),
                  gradientColors: const [Color(0xFF14B8A6), Color(0xFF0F766E)],
                  onTap: property.has3DModel
                      ? () => Property3DModelViewer.show(context, property)
                      : () {},
                ),

                // Card 3: View in AR (Blue Accent)
                _ToolData(
                  title: 'View in AR',
                  description: 'Visualize this property in augmented reality and understand how the space looks at real scale.',
                  benefits: const [
                    'Real-scale visualization',
                    'View spaces through camera',
                    'Interactive AR experience',
                  ],
                  ctaLabel: 'Try AR View →',
                  badge: 'AUGMENTED',
                  isAvailable: true,
                  icon: LucideIcons.scan,
                  accentColor: const Color(0xFF2563EB),
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.propertyArRoute(property.id),
                      arguments: property,
                    );
                  },
                ),

                // Card 4: Floor Plan (Orange Accent)
                _ToolData(
                  title: 'Floor Plan',
                  description: 'View the detailed floor plan with room dimensions, layout and space configuration.',
                  benefits: const [
                    'Room dimensions',
                    'Layout overview',
                    'Space planning',
                  ],
                  ctaLabel: 'View Floor Plan →',
                  badge: dynamicBhkBadge,
                  isAvailable: true,
                  icon: LucideIcons.layoutTemplate,
                  accentColor: const Color(0xFFEA580C),
                  gradientColors: const [Color(0xFFF97316), Color(0xFFC2410C)],
                  onTap: () => PropertyFloorPlanViewer.show(context, property),
                ),

                // Card 5: Vastu Guidance (Pink Accent)
                _ToolData(
                  title: 'Vastu Guidance',
                  description: 'Get property-specific Vastu insights based on direction, layout and placement.',
                  benefits: [
                    'Direction analysis (${property.facing})',
                    'Room placement insights',
                    'Personalized suggestions',
                  ],
                  ctaLabel: 'Check Vastu →',
                  badge: 'DIRECTIONAL',
                  isAvailable: true,
                  icon: LucideIcons.compass,
                  accentColor: const Color(0xFFE11D48),
                  gradientColors: const [Color(0xFFF43F5E), Color(0xFFBE123C)],
                  onTap: () => PropertyVastuGuidanceViewer.show(context, property),
                ),
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final tool = tools[index];
                  return _buildToolCard(context, tool);
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // 3. Subtle Service Hub Link
          InkWell(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.services),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.sparkles, size: 15, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Need custom Home Design, Legal Verification, or Loan Consultancy?',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Explore Services →',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, _ToolData tool) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.isAvailable ? tool.onTap : null,
        borderRadius: BorderRadius.circular(18),
        hoverColor: const Color(0xFFF1F5F9),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x03000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: 44x44 Rounded Square Icon + Top-Right Pill Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: tool.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: tool.gradientColors.first.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(tool.icon, color: Colors.white, size: 20),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: tool.accentColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tool.badge,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: tool.accentColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                tool.title,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Short 2-3 Line Description
              Text(
                tool.description,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF475569),
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // 3 Small Benefits Bullet Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tool.benefits.map((benefit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tool.accentColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            benefit,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: const Color(0xFF64748B),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 6),
              const Divider(height: 8, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 6),

              // Bottom CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: tool.isAvailable ? tool.onTap : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tool.isAvailable ? tool.accentColor : const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    tool.ctaLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolData {
  final String title;
  final String description;
  final List<String> benefits;
  final String ctaLabel;
  final String badge;
  final bool isAvailable;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ToolData({
    required this.title,
    required this.description,
    required this.benefits,
    required this.ctaLabel,
    required this.badge,
    required this.isAvailable,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.onTap,
  });
}
