import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/nearby_category_taxonomy.dart';
import '../models/property.dart';
import '../services/nearby_search_service.dart';
import '../theme/app_theme.dart';

class NearbyServicesScreen extends StatefulWidget {
  final Property? sourceProperty;
  final String initialCategory;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? locationName;

  const NearbyServicesScreen({
    super.key,
    this.sourceProperty,
    this.initialCategory = NearbyCategoryTaxonomy.school,
    this.initialLatitude,
    this.initialLongitude,
    this.locationName,
  });

  @override
  State<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends State<NearbyServicesScreen> {
  final NearbySearchService _searchService = NearbySearchService.instance;

  late String _selectedCategory;
  double _selectedRadiusKm = 5.0; // Default 5 km (Options: 1, 2, 5, 10)
  double _selectedMinRating = 0.0; // Options: 0.0 (Any), 4.0, 4.5
  bool _openNowOnly = false;
  bool _verifiedOnly = false;

  late double _latitude;
  late double _longitude;
  late String _locationTitle;

  bool _isLoading = true;
  String? _errorMessage;
  List<NearbyPlaceItem> _places = [];

  final List<double> _radiusOptions = [1.0, 2.0, 5.0, 10.0];
  final List<double> _ratingOptions = [0.0, 4.0, 4.5];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;

    // Resolve center coordinates
    if (widget.sourceProperty != null) {
      _latitude = widget.sourceProperty!.latitude != 0.0
          ? widget.sourceProperty!.latitude
          : 28.4595;
      _longitude = widget.sourceProperty!.longitude != 0.0
          ? widget.sourceProperty!.longitude
          : 77.5020;
      _locationTitle = widget.sourceProperty!.title;
    } else {
      _latitude = widget.initialLatitude ?? 28.4600; // Sector 150 Noida Benchmark
      _longitude = widget.initialLongitude ?? 77.5020;
      _locationTitle = widget.locationName ?? 'Sector 150, Noida';
    }

    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchNearbyPlaces(
        latitude: _latitude,
        longitude: _longitude,
        category: _selectedCategory,
        radiusKm: _selectedRadiusKm,
        minRating: _selectedMinRating,
        openNow: _openNowOnly ? true : null,
        isVerified: _verifiedOnly ? true : null,
      );

      if (mounted) {
        setState(() {
          _places = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load ${_getCategoryDef().displayName.toLowerCase()} right now.';
        });
      }
    }
  }

  NearbyCategoryDefinition _getCategoryDef() {
    return NearbyCategoryTaxonomy.getDefinition(_selectedCategory);
  }

  void _onCategorySelected(String catId) {
    if (_selectedCategory == catId) return;
    setState(() {
      _selectedCategory = catId;
    });
    _loadNearbyPlaces();
  }

  void _onRadiusSelected(double radius) {
    if (_selectedRadiusKm == radius) return;
    setState(() {
      _selectedRadiusKm = radius;
    });
    _loadNearbyPlaces();
  }

  void _onRatingSelected(double minRating) {
    if (_selectedMinRating == minRating) return;
    setState(() {
      _selectedMinRating = minRating;
    });
    _loadNearbyPlaces();
  }

  void _expandRadius() {
    double nextRadius = 10.0;
    if (_selectedRadiusKm < 2.0) {
      nextRadius = 2.0;
    } else if (_selectedRadiusKm < 5.0) {
      nextRadius = 5.0;
    } else if (_selectedRadiusKm < 10.0) {
      nextRadius = 10.0;
    }
    _onRadiusSelected(nextRadius);
  }

  void _launchMaps(NearbyPlaceItem item) async {
    final query = Uri.encodeComponent('${item.name}, ${item.address}');
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}($query)');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _callPlace(NearbyPlaceItem item) async {
    if (item.phone == null || item.phone!.isEmpty) return;
    final url = Uri.parse('tel:${item.phone}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final catDef = _getCategoryDef();
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(catDef.icon, color: AppTheme.primaryViolet, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${catDef.displayName} Nearby',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            Text(
              'Near $_locationTitle • Haversine Radius ${_selectedRadiusKm.toInt()} km',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // TOP CATEGORY SELECTOR BAR (26 Taxonomy Categories)
          // -------------------------------------------------------------------
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: NearbyCategoryTaxonomy.definitions.map((def) {
                  final isSelected = def.id == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        def.icon,
                        size: 14,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      label: Text(
                        def.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: AppTheme.primaryViolet,
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                      ),
                      onSelected: (_) => _onCategorySelected(def.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderLight),

          // -------------------------------------------------------------------
          // EXACT FILTERS BAR (Radius, Rating, Open Now, Verified)
          // -------------------------------------------------------------------
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text('Radius: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(width: 4),
                  ..._radiusOptions.map((r) {
                    final isSel = _selectedRadiusKm == r;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSel,
                        label: Text('${r.toInt()} km', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.textPrimary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSel ? const Color(0xFF10B981) : AppTheme.borderLight),
                        onSelected: (_) => _onRadiusSelected(r),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: AppTheme.borderLight),
                  const SizedBox(width: 12),

                  Text('Rating: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(width: 4),
                  ..._ratingOptions.map((rat) {
                    final isSel = _selectedMinRating == rat;
                    final label = rat == 0.0 ? 'Any' : '${rat}+ ⭐';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: isSel,
                        label: Text(label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.textPrimary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                        selectedColor: const Color(0xFFF59E0B),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSel ? const Color(0xFFF59E0B) : AppTheme.borderLight),
                        onSelected: (_) => _onRatingSelected(rat),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Container(height: 20, width: 1, color: AppTheme.borderLight),
                  const SizedBox(width: 12),

                  // Open Now Filter
                  FilterChip(
                    selected: _openNowOnly,
                    label: Text('Open Now', style: TextStyle(fontSize: 11, color: _openNowOnly ? Colors.white : AppTheme.textPrimary, fontWeight: _openNowOnly ? FontWeight.bold : FontWeight.normal)),
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _openNowOnly ? const Color(0xFF2563EB) : AppTheme.borderLight),
                    onSelected: (val) {
                      setState(() => _openNowOnly = val);
                      _loadNearbyPlaces();
                    },
                  ),
                  const SizedBox(width: 6),

                  // Verified Filter
                  FilterChip(
                    selected: _verifiedOnly,
                    label: Text('Verified', style: TextStyle(fontSize: 11, color: _verifiedOnly ? Colors.white : AppTheme.textPrimary, fontWeight: _verifiedOnly ? FontWeight.bold : FontWeight.normal)),
                    selectedColor: const Color(0xFF7C3AED),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _verifiedOnly ? const Color(0xFF7C3AED) : AppTheme.borderLight),
                    onSelected: (val) {
                      setState(() => _verifiedOnly = val);
                      _loadNearbyPlaces();
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderLight),

          // -------------------------------------------------------------------
          // RESULTS LIST / LOADING / ERROR / ZERO RESULT STATE
          // -------------------------------------------------------------------
          Expanded(
            child: _isLoading
                ? _buildLoadingState(catDef)
                : _errorMessage != null
                    ? _buildErrorState()
                    : _places.isEmpty
                        ? _buildZeroResultState(catDef)
                        : _buildResultsList(isDesktop, isTablet, catDef),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(NearbyCategoryDefinition catDef) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryViolet),
          const SizedBox(height: 16),
          Text(
            'Finding ${catDef.displayName.toLowerCase()} near you...',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Applying strict category validation & Haversine distance calculations',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppTheme.amberWarning),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Unable to load places right now.',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.refreshCw, size: 16, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _loadNearbyPlaces,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroResultState(NearbyCategoryDefinition catDef) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(catDef.icon, size: 44, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${catDef.displayName.toLowerCase()} found within ${_selectedRadiusKm.toInt()} km.',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'PropZen strict search returned 0 matches for this category in the selected radius.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_selectedRadiusKm < 10.0)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.maximize2, size: 16, color: Colors.white),
                label: Text(
                  'Expand to 10 km',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _expandRadius,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(bool isDesktop, bool isTablet, NearbyCategoryDefinition catDef) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Icon(catDef.icon, size: 16, color: AppTheme.primaryViolet),
                const SizedBox(width: 8),
                Text(
                  'Showing ${_places.length} verified ${catDef.displayName.toLowerCase()} within ${_selectedRadiusKm.toInt()} km',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const Spacer(),
                Text(
                  'Sorted by Distance',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Grid / List
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 210,
            ),
            itemCount: _places.length,
            itemBuilder: (context, index) {
              final item = _places[index];
              return _buildPlaceCard(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(NearbyPlaceItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Distance Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.distanceKm} km away',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Subcategory & Rating
          Row(
            children: [
              Text(
                item.subcategory,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(LucideIcons.star, size: 12, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text(
                    '${item.rating}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  Text(
                    ' (${item.reviewCount})',
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Address
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.address,
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Badges: Open Now & Verified
          Row(
            children: [
              if (item.isOpenNow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('OPEN NOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ),
              if (item.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Action Buttons: Directions & Call
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _launchMaps(item),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppTheme.primaryViolet),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.navigation, size: 12, color: AppTheme.primaryViolet),
                  label: Text('Directions', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ),
              ),
              if (item.phone != null && item.phone!.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _callPlace(item),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.phone, size: 14, color: AppTheme.textPrimary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
