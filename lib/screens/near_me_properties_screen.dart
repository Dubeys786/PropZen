
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/drone_tour_section.dart';
import 'property_details_screen.dart';

class NearMePropertiesScreen extends StatefulWidget {
  const NearMePropertiesScreen({super.key});

  @override
  State<NearMePropertiesScreen> createState() => _NearMePropertiesScreenState();
}

class _NearMePropertiesScreenState extends State<NearMePropertiesScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _hasLocationPermission = true;
  double _userLatitude = 28.5355; // Central Noida / NCR benchmark
  double _userLongitude = 77.3910;
  String _userLocationName = 'Sector 62, Noida (Current Location)';

  double _selectedRadiusKm = 25.0; // 5, 10, 25, 50 (All NCR)
  String _selectedCity = 'All';
  String _selectedBhk = 'All';
  String _sortBy = 'Distance: Nearest First';

  final List<double> _radiusOptions = [5.0, 10.0, 25.0, 50.0];
  final List<String> _cityOptions = ['All', 'Noida', 'Greater Noida', 'Gurgaon', 'Ghaziabad'];
  final List<String> _bhkOptions = ['All', '2 BHK', '3 BHK', '4 BHK+'];
  final List<String> _sortOptions = ['Distance: Nearest First', 'Price: Low to High', 'Price: High to Low', '10X Score'];

  @override
  void initState() {
    super.initState();
    _stateService.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _stateService.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  /// True Haversine formula calculation in Kilometers
  double _calculateDistanceKm(double propLat, double propLng) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        math.cos((propLat - _userLatitude) * p) / 2 +
        math.cos(_userLatitude * p) *
            math.cos(propLat * p) *
            (1 - math.cos((propLng - _userLongitude) * p)) /
            2;
    final double dist = 12742 * math.asin(math.sqrt(a)); // 2 * R * asin...
    return double.parse(dist.toStringAsFixed(1));
  }

  List<MapEntry<Property, double>> get _nearbyPropertiesWithDistance {
    // Only published properties
    var list = _stateService.allProperties.where((p) => p.status.toLowerCase() == 'published').toList();

    // Query filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.sector.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query) ||
            p.address.toLowerCase().contains(query);
      }).toList();
    }

    // City filter
    if (_selectedCity != 'All') {
      list = list.where((p) => p.city.toLowerCase() == _selectedCity.toLowerCase()).toList();
    }

    // BHK filter
    if (_selectedBhk != 'All') {
      final key = _selectedBhk.replaceAll('+', '').toLowerCase();
      list = list.where((p) => p.bhk.toLowerCase().contains(key)).toList();
    }

    // Calculate distance pairs
    var pairs = list.map((p) => MapEntry(p, _calculateDistanceKm(p.latitude, p.longitude))).toList();

    // Radius filter (if not 50 km which means All NCR)
    if (_selectedRadiusKm < 50.0) {
      pairs = pairs.where((e) => e.value <= _selectedRadiusKm).toList();
    }

    // Sort
    if (_sortBy == 'Distance: Nearest First') {
      pairs.sort((a, b) => a.value.compareTo(b.value));
    } else if (_sortBy == 'Price: Low to High') {
      pairs.sort((a, b) => a.key.askingPriceCr.compareTo(b.key.askingPriceCr));
    } else if (_sortBy == 'Price: High to Low') {
      pairs.sort((a, b) => b.key.askingPriceCr.compareTo(a.key.askingPriceCr));
    } else if (_sortBy == '10X Score') {
      pairs.sort((a, b) => b.key.score10x.compareTo(a.key.score10x));
    }

    return pairs;
  }

  void _requestLocationPermission() {
    setState(() {
      _hasLocationPermission = true;
      _userLatitude = 28.5355;
      _userLongitude = 77.3910;
      _userLocationName = 'Sector 62, Noida (GPS Active)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location calibrated successfully. Showing nearest properties in NCR.'),
        backgroundColor: AppTheme.emeraldSuccess,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pairs = _nearbyPropertiesWithDistance;
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;

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
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.mapPin, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Properties Near Me',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: !_hasLocationPermission
          ? _buildPermissionDeniedView()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPS Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.navigation, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'GPS ACTIVE',
                                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _userLocationName,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              Text(
                                '${pairs.length} published properties within ${_selectedRadiusKm >= 50 ? "All NCR" : "${_selectedRadiusKm.toInt()} km"}',
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _requestLocationPermission,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Calibrate',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search and Radius Controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search locality, sector or property...',
                            hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                            prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF10B981), size: 18),
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Radius Filter Selector
                        Row(
                          children: [
                            Text('Distance Radius: ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _radiusOptions.map((r) {
                                    final isSel = _selectedRadiusKm == r;
                                    final label = r >= 50 ? 'All NCR' : '< ${r.toInt()} km';
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(label),
                                        selected: isSel,
                                        selectedColor: const Color(0xFF10B981),
                                        backgroundColor: AppTheme.surfaceSubtle,
                                        labelStyle: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          color: isSel ? Colors.white : AppTheme.textPrimary,
                                        ),
                                        onSelected: (sel) {
                                          if (sel) setState(() => _selectedRadiusKm = r);
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Sort & Filters Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildDropdownPill('City', _selectedCity, _cityOptions, (v) => setState(() => _selectedCity = v)),
                              const SizedBox(width: 8),
                              _buildDropdownPill('BHK', _selectedBhk, _bhkOptions, (v) => setState(() => _selectedBhk = v)),
                              const SizedBox(width: 8),
                              _buildDropdownPill('Sort', _sortBy, _sortOptions, (v) => setState(() => _sortBy = v)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nearby Property Grid
                  if (pairs.isEmpty)
                    _buildEmptyState()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int cols = isDesktop ? 3 : (isTablet ? 2 : 1);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 400,
                          ),
                          itemCount: pairs.length,
                          itemBuilder: (context, i) {
                            final entry = pairs[i];
                            return _buildNearbyPropertyCard(entry.key, entry.value);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdownPill(String label, String currentVal, List<String> options, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButton<String>(
        value: currentVal,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: Colors.white,
        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text('$label: $opt'))).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildNearbyPropertyCard(Property p, double distanceKm) {
    final isSaved = _stateService.isSaved(p.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header with Distance Pill
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  p.dynamicImageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.surfaceSubtle,
                    child: const Icon(LucideIcons.image, color: AppTheme.textMuted, size: 32),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.navigation, color: Colors.white, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        '$distanceKm km away',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () => _stateService.toggleSave(p.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : AppTheme.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Card Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.formattedPrice,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '10X Score: ${p.score10x}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  p.title,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 11, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${p.sector}, ${p.city}',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Specs Pills
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildSpecTag(LucideIcons.home, p.bhk),
                    _buildSpecTag(LucideIcons.maximize2, '${p.sqft} sq.ft'),
                    _buildSpecTag(LucideIcons.percent, '${p.rentalYieldPercent}% Yield'),
                  ],
                ),

                const SizedBox(height: 10),

                // Drone Tour Section (Universal for ALL properties)
                DroneTourSection(property: p),

                const SizedBox(height: 12),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint('VIEW DETAILS PROPERTY: ${p.title}');
                      debugPrint('VIEW DETAILS PROPERTY ID: ${p.id}');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p, propertyId: p.id)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('View Details', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.textMuted),
          const SizedBox(width: 3),
          Text(text, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softCardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.mapPinOff, color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Location Access Required',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Location permission is required to find properties near you and calculate real-time driving distances in NCR.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _requestLocationPermission,
              icon: const Icon(LucideIcons.navigation, size: 16),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.mapPinOff, color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No properties found within radius',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try increasing the search radius to 25 km or All NCR to explore more locality deals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => setState(() => _selectedRadiusKm = 50.0),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Expand to All NCR'),
            ),
          ],
        ),
      ),
    );
  }
}
