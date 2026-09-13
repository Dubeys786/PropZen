import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../screens/property_details_screen.dart';
import '../widgets/enquiry_auth_dialog.dart';
import 'drone_tour_section.dart';
import '../theme/app_theme.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final VoidCallback? onTapReport;
  final VoidCallback? onTapPhotos;
  final bool isCompact;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onTapReport,
    this.onTapPhotos,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final stateService = PropertyStateService.instance;

    return AnimatedBuilder(
      animation: stateService,
      builder: (context, _) {
        final isSaved = stateService.isSaved(property.id);
        final isCompared = stateService.isCompared(property.id);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: onTap ??
                () {
                  stateService.trackView(property.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => PropertyDetailsScreen(property: property, propertyId: property.id),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isCompared
                      ? AppTheme.primaryViolet
                      : AppTheme.borderLight,
                  width: isCompared ? 1.5 : 1.0,
                ),
                boxShadow: AppTheme.softCardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // IMAGE SECTION WITH BADGES
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          property.displayImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppTheme.surfaceHighlight,
                            child: const Center(
                              child: Icon(LucideIcons.image, color: AppTheme.textHint, size: 36),
                            ),
                          ),
                        ),
                      ),

                      // Gradient bottom overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.45),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Status Tag (e.g. New Launch / Price Drop / Featured / Trending)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: property.statusTag == 'Price Drop'
                                ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                                : (property.statusTag == 'Trending'
                                    ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                                    : AppTheme.primaryGradient),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            property.statusTag,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      // Favorite Heart Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: InkWell(
                          onTap: () {
                            stateService.toggleSave(property.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isSaved
                                      ? 'Removed from saved properties'
                                      : 'Saved to your favourites',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppTheme.primaryViolet,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isSaved ? AppTheme.coralDanger : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),

                      // RERA Badge & Rating (Bottom on Image)
                      Positioned(
                        bottom: 8,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (property.isPropZenVerified)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 12),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '✓ PropZen Verified',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF34D399),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (property.isPending || property.isUnderReview)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.clock, color: Colors.amber, size: 12),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '⏳ Verification In Progress',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.building, color: Color(0xFF38BDF8), size: 12),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          property.isReraApproved ? 'RERA Approved' : property.propertyType,
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF7DD3FC),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFBBF24), size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    property.rating.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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

                  // CONTENT SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Type Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                property.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Text(
                                property.propertyType,
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Sector / City
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 11,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${property.sector}, ${property.city}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Price & Original Discounted Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              property.formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (property.originalPriceCr != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '₹ ${(property.originalPriceCr! * 100).round()} L',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppTheme.textHint,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 2),

                        // Configuration & Area & Possession
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${property.bhk} • ${property.sqft} sq.ft',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryViolet,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '•',
                              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.availability,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        // 5. Drone Tour Preview / Unlock Bar (Universal for ALL properties)
                        const SizedBox(height: 6),
                        DroneTourSection(property: property),

                        const SizedBox(height: 6),

                        // ACTION BUTTONS (Compare, Enquire Now, View Details)
                        Row(
                          children: [
                            // Compare Icon Button
                            InkWell(
                              onTap: () {
                                final added = stateService.toggleCompare(property.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCompared
                                          ? 'Removed from comparison'
                                          : (added ? 'Added to comparison matrix' : 'Comparison limit reached (max 4)'),
                                    ),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppTheme.primaryViolet,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCompared
                                      ? AppTheme.primaryViolet.withOpacity(0.12)
                                      : AppTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCompared
                                        ? AppTheme.primaryViolet
                                        : AppTheme.borderLight,
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.scale,
                                  size: 14,
                                  color: isCompared ? AppTheme.primaryViolet : AppTheme.textMuted,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Enquire Now Button
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  EnquiryAuthDialog.show(
                                    context,
                                    actionLabel: 'Enquire for ${property.title}',
                                    onSuccess: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Enquiry submitted successfully for ${property.title}!'),
                                          backgroundColor: AppTheme.primaryViolet,
                                        ),
                                      );
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceSubtle,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Enquire Now',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // View Details Button
                            Expanded(
                              child: InkWell(
                                onTap: onTap ??
                                    () {
                                      debugPrint('VIEW DETAILS PROPERTY: ${property.title}');
                                      debugPrint('VIEW DETAILS PROPERTY ID: ${property.id}');
                                      stateService.trackView(property.id);
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (ctx) => PropertyDetailsScreen(property: property, propertyId: property.id),
                                        ),
                                      );
                                    },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'View Details',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
