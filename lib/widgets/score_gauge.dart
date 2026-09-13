import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ScoreGauge extends StatelessWidget {
  final double score;
  final double size;
  final String label;

  const ScoreGauge({
    super.key,
    required this.score,
    this.size = 130,
    this.label = 'EXCELLENT BUY',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 1,
          )
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                score.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: size * 0.075,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryViolet,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
  }
}
