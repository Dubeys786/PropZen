import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/social_config.dart';

/// Floating Instagram and WhatsApp Social Media Icons Widget
/// Positioned vertically: Instagram on top, WhatsApp below.
/// Clean official brand aesthetics matching reference image with white squircle cards and brand outline icons.
class FloatingSocialButtons extends StatelessWidget {
  final double? bottomOffset;
  final double? rightOffset;

  const FloatingSocialButtons({
    super.key,
    this.bottomOffset,
    this.rightOffset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final iconSize = isDesktop ? 46.0 : (isTablet ? 42.0 : 40.0);
    final glyphSize = isDesktop ? 26.0 : (isTablet ? 23.0 : 22.0);
    final spacing = isDesktop ? 14.0 : (isTablet ? 13.0 : 11.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. Instagram Floating Icon (Top)
        _SocialIconButton(
          key: const Key('floating_instagram_button'),
          semanticLabel: 'Open PropZen Instagram',
          tooltip: 'Open PropZen Instagram',
          size: iconSize,
          backgroundColor: Colors.white,
          shadowColor: const Color(0xFFE1306C).withOpacity(0.25),
          customChild: Icon(
            LucideIcons.instagram,
            size: glyphSize,
            color: const Color(0xFFE1306C),
          ),
          onTap: () => _openUrl(SocialConfig.instagramUrl),
        ),

        SizedBox(height: spacing),

        // 2. WhatsApp Floating Icon (Bottom) - Exact Outline Speech Bubble with Handset
        _SocialIconButton(
          key: const Key('floating_whatsapp_button'),
          semanticLabel: 'Chat with PropZen on WhatsApp',
          tooltip: 'Chat with PropZen on WhatsApp',
          size: iconSize,
          backgroundColor: Colors.white,
          shadowColor: const Color(0xFF25D366).withOpacity(0.30),
          customChild: WhatsAppOutlineWidget(
            size: glyphSize,
            color: const Color(0xFF25D366),
          ),
          onTap: () => _openUrl(SocialConfig.whatsappChatUrl),
        ),
      ],
    );
  }

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[FloatingSocialButtons] Could not launch $urlString: $e');
    }
  }
}

/// Custom Vector WhatsApp Outline Icon matching official brand geometry
class WhatsAppOutlineWidget extends StatelessWidget {
  final double size;
  final Color color;

  const WhatsAppOutlineWidget({
    super.key,
    this.size = 24.0,
    this.color = const Color(0xFF25D366),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppOutlinePainter(color: color),
    );
  }
}

class _WhatsAppOutlinePainter extends CustomPainter {
  final Color color;

  const _WhatsAppOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;

    // Stroke paint for outer speech bubble
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Fill paint for inner phone handset
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Circular Speech Bubble with Tail at Bottom-Left
    final cx = 12.0 * scale;
    final cy = 11.2 * scale;
    final r = 8.6 * scale;

    final bubblePath = Path();
    // Arc clockwise from ~102 deg (1.78 rad) to ~142 deg (2.48 rad)
    const startAngle = 2.48;
    const sweepAngle = 2 * 3.141592653589793 - (2.48 - 1.78);
    bubblePath.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
    );
    // Draw triangular speech tail to bottom-left (~7 o'clock)
    bubblePath.lineTo(3.6 * scale, 19.8 * scale);
    bubblePath.lineTo(cx + r * 0.20, cy + r * 0.98);

    canvas.drawPath(bubblePath, strokePaint);

    // 2. Centered Phone Handset
    canvas.save();
    canvas.translate(cx, cy);

    final handsetPath = Path();
    final hs = scale * 0.85;

    // Ergonomic handset receiver shape
    handsetPath.moveTo(-3.2 * hs, -1.8 * hs);
    handsetPath.cubicTo(-3.2 * hs, -3.0 * hs, -2.0 * hs, -4.0 * hs, -0.6 * hs, -4.0 * hs);
    handsetPath.cubicTo(0.2 * hs, -4.0 * hs, 0.9 * hs, -3.5 * hs, 1.3 * hs, -2.8 * hs);
    handsetPath.lineTo(2.2 * hs, -1.2 * hs);
    handsetPath.cubicTo(2.5 * hs, -0.6 * hs, 2.3 * hs, 0.1 * hs, 1.8 * hs, 0.5 * hs);
    handsetPath.lineTo(0.9 * hs, 1.2 * hs);
    handsetPath.cubicTo(1.5 * hs, 2.4 * hs, 2.5 * hs, 3.4 * hs, 3.7 * hs, 4.0 * hs);
    handsetPath.lineTo(4.4 * hs, 3.1 * hs);
    handsetPath.cubicTo(4.8 * hs, 2.6 * hs, 5.5 * hs, 2.4 * hs, 6.1 * hs, 2.7 * hs);
    handsetPath.lineTo(7.8 * hs, 3.6 * hs);
    handsetPath.cubicTo(8.5 * hs, 4.0 * hs, 9.0 * hs, 4.7 * hs, 9.0 * hs, 5.5 * hs);
    handsetPath.cubicTo(9.0 * hs, 6.9 * hs, 8.0 * hs, 8.2 * hs, 6.6 * hs, 8.2 * hs);
    handsetPath.cubicTo(0.6 * hs, 8.2 * hs, -3.2 * hs, 4.2 * hs, -3.2 * hs, -1.8 * hs);
    handsetPath.close();

    canvas.translate(-2.7 * hs, -2.1 * hs);
    canvas.drawPath(handsetPath, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SocialIconButton extends StatefulWidget {
  final String semanticLabel;
  final String tooltip;
  final double size;
  final Color backgroundColor;
  final Color shadowColor;
  final Widget customChild;
  final VoidCallback onTap;

  const _SocialIconButton({
    super.key,
    required this.semanticLabel,
    required this.tooltip,
    required this.size,
    required this.backgroundColor,
    required this.shadowColor,
    required this.customChild,
    required this.onTap,
  });

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: true,
      child: Tooltip(
        message: widget.tooltip,
        preferBelow: false,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: _isHovered ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: _isHovered ? 14 : 8,
                      spreadRadius: _isHovered ? 1 : 0,
                      offset: Offset(0, _isHovered ? 5 : 3),
                    ),
                    BoxShadow(
                      color: widget.shadowColor,
                      blurRadius: _isHovered ? 10 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.customChild,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
