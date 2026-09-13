import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/maps_config.dart';
import '../theme/app_theme.dart';

/// Result object returned by LocationPickerScreen
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String locality;
  final String postalCode;
  final String placeId;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.locality,
    required this.postalCode,
    this.placeId = '',
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String? initialCity;
  final String? initialLocality;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.initialCity,
    this.initialLocality,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  late double _currentLat;
  late double _currentLng;
  late String _currentAddress;
  late String _currentCity;
  late String _currentLocality;
  late String _currentPostalCode;

  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _currentLat = (widget.initialLatitude != null && widget.initialLatitude != 0.0)
        ? widget.initialLatitude!
        : MapsConfig.defaultLatitude;
    _currentLng = (widget.initialLongitude != null && widget.initialLongitude != 0.0)
        ? widget.initialLongitude!
        : MapsConfig.defaultLongitude;
    _currentAddress = widget.initialAddress ?? 'Sector 150, Noida-Greater Noida Expressway, Noida, UP';
    _currentCity = widget.initialCity ?? 'Noida';
    _currentLocality = widget.initialLocality ?? 'Sector 150';
    _currentPostalCode = '201310';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final clean = query.toLowerCase().trim();
    final matches = MapsConfig.ncrLocalities.where((loc) {
      final title = (loc['title'] as String).toLowerCase();
      final subtitle = (loc['subtitle'] as String).toLowerCase();
      final city = (loc['city'] as String).toLowerCase();
      return title.contains(clean) || subtitle.contains(clean) || city.contains(clean);
    }).toList();

    setState(() {
      _searchResults = matches;
      _isSearching = true;
    });
  }

  void _selectLocality(Map<String, dynamic> loc) {
    final lat = loc['lat'] as double;
    final lng = loc['lng'] as double;
    final title = loc['title'] as String;
    final city = loc['city'] as String;
    final locality = loc['locality'] as String;
    final postalCode = loc['postalCode'] as String? ?? '';

    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _currentAddress = '$title, $city';
      _currentCity = city;
      _currentLocality = locality;
      _currentPostalCode = postalCode;
      _isSearching = false;
      _searchController.text = title;
    });
  }

  void _confirmSelection() {
    final result = LocationResult(
      latitude: _currentLat,
      longitude: _currentLng,
      address: _currentAddress,
      city: _currentCity,
      locality: _currentLocality,
      postalCode: _currentPostalCode,
      placeId: 'ncr_loc_${_currentLocality.toLowerCase().replaceAll(' ', '_')}',
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Property Location',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Box
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search locality or sector (e.g. Sector 150 Noida, Dwarka)...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textHint),
                      prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.primaryViolet),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                if (_isSearching && _searchResults.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                      boxShadow: AppTheme.softCardShadow,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      separatorBuilder: (ctx, i) => Divider(height: 1, color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                      itemBuilder: (ctx, i) {
                        final item = _searchResults[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primaryViolet),
                          title: Text(item['title'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('${item['subtitle']} • ${item['city']}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.textHint),
                          onTap: () => _selectLocality(item),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Selected Location Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.borderLight),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.mapPin, color: AppTheme.primaryViolet, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Location',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                ),
                                Text(
                                  _currentAddress,
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildBadge('City', _currentCity),
                          _buildBadge('Locality', _currentLocality),
                          _buildBadge('PIN', _currentPostalCode),
                          _buildBadge('Lat', _currentLat.toStringAsFixed(4)),
                          _buildBadge('Lng', _currentLng.toStringAsFixed(4)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Popular NCR Sectors
                Text('Popular NCR Sectors & Localities', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: MapsConfig.ncrLocalities.map((loc) {
                    final isSelected = _currentLocality == loc['locality'];
                    return ActionChip(
                      backgroundColor: isSelected ? AppTheme.primaryViolet : (isDark ? AppTheme.darkSurface : Colors.white),
                      side: BorderSide(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight),
                      avatar: Icon(LucideIcons.mapPin, size: 14, color: isSelected ? Colors.white : AppTheme.primaryViolet),
                      label: Text(
                        '${loc['locality']} (${loc['city']})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      onPressed: () => _selectLocality(loc),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmSelection,
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Confirm & Use This Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
      ),
    );
  }
}
