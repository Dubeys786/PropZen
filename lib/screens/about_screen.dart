import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            borderColor: AppTheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'About PropZen',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Intelligence-First Real Estate Platform built for high-stakes property investments in the National Capital Region.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OUR MISSION & TRACK RECORD',
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
                const Divider(color: AppTheme.outline, height: 20),
                Text(
                  'We eliminate informational asymmetry in real estate transactions. Using Bloomberg-terminal grade analytics, we evaluate fair market transaction prices, rental yields, and growth catalysts across 120+ NCR micro-markets.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.onSurface, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPillar('₹5,400 Cr+', 'Evaluated'),
                    _buildPillar('120+', 'Micro-Markets'),
                    _buildPillar('99.4%', 'Accuracy'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildPillar(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
        Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}
