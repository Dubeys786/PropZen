import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property_visit_plan.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'site_visit_checklist_screen.dart';
import 'property_details_screen.dart';
import 'user_profile_screen.dart';

class PropertyVisitPlannerScreen extends StatefulWidget {
  const PropertyVisitPlannerScreen({super.key});

  @override
  State<PropertyVisitPlannerScreen> createState() => _PropertyVisitPlannerScreenState();
}

class _PropertyVisitPlannerScreenState extends State<PropertyVisitPlannerScreen> {
  late PropertyVisitPlan _plan;
  bool _isAddingStop = false;

  @override
  void initState() {
    super.initState();
    _plan = PropertyVisitPlan.samplePlan(UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer');
  }

  void _addPropertyToPlan(Property prop) {
    final newStop = PlannedVisitStop(
      id: 'STOP-${DateTime.now().millisecondsSinceEpoch}',
      propertyId: prop.id,
      propertyTitle: prop.title,
      propertySector: '${prop.effectiveLocality}, ${prop.city}',
      propertyImage: prop.dynamicImageUrl,
      askingPriceCr: prop.askingPriceCr,
      timeSlot: '${10 + _plan.stops.length * 2}:00 PM',
      durationMinutes: 45,
      visitorCount: 2,
      cabRequired: true,
      notes: 'Evaluate floor plan and society clubhouse.',
    );

    setState(() {
      final updatedStops = List<PlannedVisitStop>.from(_plan.stops)..add(newStop);
      _plan = PropertyVisitPlan(
        id: _plan.id,
        buyerId: _plan.buyerId,
        planTitle: _plan.planTitle,
        visitDate: _plan.visitDate,
        preferredCabPickupLocation: _plan.preferredCabPickupLocation,
        stops: updatedStops,
      );
      _isAddingStop = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${prop.title} to your Visit Itinerary!'), backgroundColor: AppTheme.primaryViolet),
    );
  }

  void _removeStop(int index) {
    setState(() {
      final updatedStops = List<PlannedVisitStop>.from(_plan.stops)..removeAt(index);
      _plan = PropertyVisitPlan(
        id: _plan.id,
        buyerId: _plan.buyerId,
        planTitle: _plan.planTitle,
        visitDate: _plan.visitDate,
        preferredCabPickupLocation: _plan.preferredCabPickupLocation,
        stops: updatedStops,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProperties = PropertyStateService.instance.allProperties;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.calendarDays, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan My Property Visits',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  'Multi-Property Tour Itinerary & Cab Coordinator',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isAddingStop = !_isAddingStop),
            icon: Icon(_isAddingStop ? LucideIcons.x : LucideIcons.plus, size: 16, color: AppTheme.primaryViolet),
            label: Text(_isAddingStop ? 'Close' : 'Add Property', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Itinerary Summary Card
                _buildItineraryHeaderCard(),
                const SizedBox(height: 20),

                // Add Property Dropdown Area
                if (_isAddingStop) _buildAddPropertySelector(allProperties),

                // Timeline Tour Stops
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Planned Tour Route (${_plan.stops.length} Stops)',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Sequential Time Slots',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_plan.stops.isEmpty)
                  _buildEmptyStopsView()
                else
                  ..._plan.stops.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final stop = entry.value;
                    final isLast = idx == _plan.stops.length - 1;
                    return _buildTimelineStopItem(idx + 1, stop, isLast);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_plan.planTitle, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 13, color: AppTheme.primaryViolet),
                      const SizedBox(width: 6),
                      Text(_plan.visitDate, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.car, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text('Free Cab Included', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pickup Point: ${_plan.preferredCabPickupLocation}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddPropertySelector(List<Property> allProperties) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Property to Add to Tour Itinerary:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: allProperties.length,
              separatorBuilder: (c, i) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final p = allProperties[i];
                return InkWell(
                  onTap: () => _addPropertyToPlan(p),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(p.dynamicImageUrl, width: 50, height: 50, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${p.bhk} • ₹${p.askingPriceCr} Cr', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text('+ Add to Tour', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStopItem(int stopNumber, PlannedVisitStop stop, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline column
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryViolet.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Center(
                child: Text('$stopNumber', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 140,
                color: AppTheme.primaryViolet.withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Right Stop Content Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.subtleCardShadow,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 12, color: AppTheme.primaryViolet),
                          const SizedBox(width: 5),
                          Text(stop.timeSlot, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeStop(stopNumber - 1),
                      icon: const Icon(LucideIcons.trash2, size: 14, color: AppTheme.coralDanger),
                      tooltip: 'Remove stop',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(stop.propertyImage, width: 70, height: 70, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stop.propertyTitle, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(stop.propertySector, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Text('₹ ${stop.askingPriceCr.toStringAsFixed(2)} Cr',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (stop.notes.isNotEmpty)
                  Text('Notes: ${stop.notes}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 10),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => SiteVisitChecklistScreen(
                                propertyId: stop.propertyId,
                                propertyTitle: stop.propertyTitle,
                                visitId: stop.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.clipboardCheck, size: 13),
                        label: Text('Open Site Checklist', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final prop = PropertyStateService.instance.findPropertyById(stop.propertyId);
                          if (prop != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => PropertyDetailsScreen(property: prop, propertyId: prop.id),
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.navigation, size: 13),
                        label: Text('Property Details', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStopsView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.calendarX, size: 36, color: AppTheme.textMuted),
            const SizedBox(height: 10),
            Text('No Stops Added Yet', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Click "+ Add Property" above to create your multi-property inspection route.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
