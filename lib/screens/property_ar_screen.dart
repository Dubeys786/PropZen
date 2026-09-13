import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../widgets/property_ar_view_dialog.dart';

/// PropZen Internal AR Screen
/// Route: /property/:id/ar or /ar/:propertyId
/// Renders the complete in-app AR property placement experience for the selected property.
class PropertyArScreen extends StatefulWidget {
  final Property? property;
  final String? propertyId;

  const PropertyArScreen({
    super.key,
    this.property,
    this.propertyId,
  });

  @override
  State<PropertyArScreen> createState() => _PropertyArScreenState();
}

class _PropertyArScreenState extends State<PropertyArScreen> {
  late Property _property;

  @override
  void initState() {
    super.initState();
    _property = _resolveProperty();
  }

  Property _resolveProperty() {
    if (widget.property != null) return widget.property!;

    final id = widget.propertyId;
    if (id != null && id.isNotEmpty) {
      final fromState = PropertyStateService.instance.findPropertyById(id);
      if (fromState != null) return fromState;

      try {
        return Property.sampleDeals.firstWhere((p) => p.id == id);
      } catch (_) {}
    }

    // Default fallback to first sample deal
    return Property.sampleDeals.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
          tooltip: 'Back to Property Details',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _property.title,
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_property.sector}, ${_property.city} • AR Experience',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF38BDF8)),
                const SizedBox(width: 4),
                Text(
                  'AR EXPERIENCE',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: PropertyArViewDialog(
              property: _property,
              isPage: true,
            ),
          ),
        ),
      ),
    );
  }
}
