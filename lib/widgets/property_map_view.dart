import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../screens/property_details_screen.dart';
import '../theme/app_theme.dart';

/// Lightweight Property Locality Grid View (No Google Maps dependency)
class PropertyMapView extends StatelessWidget {
  final List<Property> properties;
  final double height;

  const PropertyMapView({
    super.key,
    required this.properties,
    this.height = 480,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceContainer : AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        itemCount: properties.length,
        separatorBuilder: (ctx, i) => Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
        itemBuilder: (ctx, i) {
          final prop = properties[i];
          return ListTile(
            leading: const Icon(LucideIcons.mapPin, color: AppTheme.primaryViolet),
            title: Text(prop.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('${prop.sector}, ${prop.city} • ${prop.formattedPrice}', style: GoogleFonts.inter(fontSize: 11)),
            trailing: const Icon(LucideIcons.arrowRight, size: 16, color: AppTheme.primaryViolet),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop, propertyId: prop.id)),
              );
            },
          );
        },
      ),
    );
  }
}
