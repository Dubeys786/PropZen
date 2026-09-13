import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isCompact;

  const EmptyStateView({
    super.key,
    this.icon = LucideIcons.building2,
    required this.title,
    this.message = 'There is currently no data to display. Real data from the backend will appear here automatically.',
    this.actionLabel,
    this.onAction,
    bool isCompact = false,
    bool? compact,
  }) : isCompact = compact ?? isCompact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: isCompact ? 380 : 480),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 20 : 32,
          vertical: isCompact ? 28 : 44,
        ),
        margin: EdgeInsets.all(isCompact ? 12 : 20),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight, width: 1),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 16 : 22),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.18), width: 1.5),
              ),
              child: Icon(
                icon,
                size: isCompact ? 30 : 42,
                color: AppTheme.primaryViolet,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isCompact ? 16 : 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isCompact ? 12 : 13,
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: isCompact ? 18 : 26),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 20 : 28,
                    vertical: isCompact ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.poppins(
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
