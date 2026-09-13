import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PropzenBrandHeader extends StatelessWidget {
  final double? logoHeight;
  final double? logoWidth;
  final double? sloganFontSize;
  final double spacing;
  final bool isCompact;
  final CrossAxisAlignment alignment;
  final VoidCallback? onTap;

  const PropzenBrandHeader({
    super.key,
    this.logoHeight,
    this.logoWidth,
    this.sloganFontSize,
    this.spacing = 8.0,
    this.isCompact = false,
    this.alignment = CrossAxisAlignment.center,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && !isDesktop;

    // Slogan font size: Desktop 18-22px, Tablet 16-20px, Mobile 14-17px
    double defaultSloganSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);
    if (isCompact) {
      defaultSloganSize = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);
    }
    final actualSloganSize = sloganFontSize ?? defaultSloganSize;

    // Logo height defaults
    double defaultLogoHeight = isDesktop ? 54.0 : (isTablet ? 46.0 : 38.0);
    if (isCompact) {
      defaultLogoHeight = isDesktop ? 34.0 : (isTablet ? 30.0 : 26.0);
    }
    final actualLogoHeight = logoHeight ?? defaultLogoHeight;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        // Hindi Slogan above Logo
        Text(
          'सपनों का घर, अब स्मार्ट तरीके से',
          textAlign: TextAlign.center,
          style: GoogleFonts.hind(
            fontSize: actualSloganSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
            letterSpacing: 0.3,
            height: 1.2,
          ),
        ),

        SizedBox(height: isCompact ? 4.0 : spacing),

        // Propzen Logo Asset
        Image.asset(
          'assets/propzen_logo.png',
          height: actualLogoHeight,
          width: logoWidth,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, err, stack) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prop',
                style: GoogleFonts.poppins(
                  fontSize: actualLogoHeight * 0.65,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Zen',
                style: GoogleFonts.poppins(
                  fontSize: actualLogoHeight * 0.65,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return content;
  }
}
