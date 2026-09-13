import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/ai_home_project.dart';
import '../theme/app_theme.dart';
import 'ai_home_designer_wizard_screen.dart';
import 'my_ai_designs_screen.dart';

/// Landing Screen for AI Home & Vastu Designer
class AiHomeDesignerLandingScreen extends StatelessWidget {
  final AiHomeProject? initialProject;

  const AiHomeDesignerLandingScreen({super.key, this.initialProject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.home, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'AI Home & Vastu Designer',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyAiDesignsScreen()),
              );
            },
            icon: const Icon(LucideIcons.folderHeart, size: 16, color: AppTheme.primaryViolet),
            label: Text(
              'My Designs',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Premium Hero Card with Badges
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF7C3AED), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryViolet.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Badges in responsive Wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildHeroBadge('✨ AI POWERED', const Color(0xFFA78BFA)),
                          _buildHeroBadge('🧭 100% VASTU', const Color(0xFF34D399)),
                          _buildHeroBadge('📐 2D FLOOR PLAN', const Color(0xFF60A5FA)),
                          _buildHeroBadge('🏠 3D HOME VIEWER', const Color(0xFFF472B6)),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),

                      // Hindi Main Headline & English Subtitle
                      Text(
                        'आपके सपनों के घर का स्मार्ट डिज़ाइन',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 8),

                      Text(
                        'प्लॉट की जानकारी दें और AI से अपना Vastu-friendly floor plan, 3D home और exterior design तैयार करें।',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: Colors.white.withOpacity(0.92),
                          height: 1.45,
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 24),

                      // Action CTAs: Start Designing & View My Designs
                      LayoutBuilder(
                        builder: (context, ctaConstraints) {
                          final isCompact = ctaConstraints.maxWidth < 360;
                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AiHomeDesignerWizardScreen(initialProject: initialProject),
                                      ),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.sparkles, size: 18),
                                  label: const Text('Start Designing'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryViolet,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const MyAiDesignsScreen()),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.folder, size: 16),
                                  label: const Text('View My Designs'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AiHomeDesignerWizardScreen(initialProject: initialProject),
                                      ),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.sparkles, size: 18),
                                  label: const Text('Start Designing'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryViolet,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const MyAiDesignsScreen()),
                                  );
                                },
                                icon: const Icon(LucideIcons.folder, size: 16),
                                label: const Text('View My Designs'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          );
                        },
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Step-by-Step 9 Features Showcase Grid
                Text(
                  'What You Get with AI Home Designer',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 550;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isWide ? 1.3 : 1.15,
                      children: [
                        _buildFeatureCard(
                          icon: LucideIcons.compass,
                          title: 'Vastu Alignment',
                          subtitle: 'Agni kitchen, Ishanya pooja & Nairutya master suite zones.',
                          color: const Color(0xFF10B981),
                        ),
                        _buildFeatureCard(
                          icon: LucideIcons.layout,
                          title: '2D Architectural Plan',
                          subtitle: 'Precision CAD layout with exact room dimensions.',
                          color: const Color(0xFF3B82F6),
                        ),
                        _buildFeatureCard(
                          icon: LucideIcons.box,
                          title: '3D Home Explorer',
                          subtitle: 'Orbit 360°, inspect room slices and day/night views.',
                          color: const Color(0xFF8B5CF6),
                        ),
                        _buildFeatureCard(
                          icon: LucideIcons.home,
                          title: 'Facade Studio',
                          subtitle: 'Compare Modern, Luxury and Heritage elevations.',
                          color: const Color(0xFFF59E0B),
                        ),
                        _buildFeatureCard(
                          icon: LucideIcons.sofa,
                          title: 'Interior Designer',
                          subtitle: 'Room-by-room material, lighting & furnishing specs.',
                          color: const Color(0xFFEC4899),
                        ),
                        _buildFeatureCard(
                          icon: LucideIcons.video,
                          title: 'Virtual Walkthrough',
                          subtitle: 'Cinematic 4K walkthrough video preview.',
                          color: const Color(0xFF06B6D4),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 3. Quick Start Templates
                Text(
                  'Popular Plot Templates in NCR',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),

                _buildTemplateCard(
                  context,
                  title: 'Standard 1,000 sq ft (20 × 50 ft)',
                  subtitle: 'North-Facing • 3 BHK + Pooja • G+1 Duplex',
                  vastuScore: '94%',
                  length: 50,
                  width: 20,
                  bhk: 3,
                  direction: CompassDirection.north,
                ),
                const SizedBox(height: 10),
                _buildTemplateCard(
                  context,
                  title: 'Corner Villa (30 × 60 ft)',
                  subtitle: 'North-East Facing • 4 BHK + Double Porch • G+2 Villa',
                  vastuScore: '96%',
                  length: 60,
                  width: 30,
                  bhk: 4,
                  direction: CompassDirection.northEast,
                ),
                const SizedBox(height: 10),
                _buildTemplateCard(
                  context,
                  title: 'Luxury Estate (40 × 80 ft)',
                  subtitle: 'East-Facing • 5+ BHK + Courtyard & Pool • G+2',
                  vastuScore: '98%',
                  length: 80,
                  width: 40,
                  bhk: 5,
                  direction: CompassDirection.east,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String vastuScore,
    required double length,
    required double width,
    required int bhk,
    required CompassDirection direction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.purpleSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderPurple),
            ),
            child: Center(
              child: Icon(LucideIcons.home, size: 20, color: AppTheme.primaryViolet),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldSuccess.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Vastu: $vastuScore',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.arrowRightCircle, color: AppTheme.primaryViolet),
            onPressed: () {
              final customProject = AiHomeProject.defaultProject(
                name: title,
              ).copyWith(
                plotLength: length,
                plotWidth: width,
                bedrooms: bhk,
                roadDirection: direction,
                entranceDirection: direction,
              );

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AiHomeDesignerWizardScreen(initialProject: customProject),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
