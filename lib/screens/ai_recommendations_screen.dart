import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/drone_tour_section.dart';
import 'property_details_screen.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() => _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedBudget = 'All';
  String _selectedBhk = 'All';
  String _selectedCity = 'All';
  String _selectedPurpose = 'All';
  String _sortBy = 'Match %';

  final List<String> _budgetOptions = ['All', 'Under ₹1 Cr', '₹1 Cr - ₹2 Cr', '₹2 Cr+'];
  final List<String> _bhkOptions = ['All', '2 BHK', '3 BHK', '4 BHK+'];
  final List<String> _cityOptions = ['All', 'Noida', 'Greater Noida', 'Gurgaon'];
  final List<String> _purposeOptions = ['All', 'Family End-Use', 'High ROI Investment', 'Luxury Living'];
  final List<String> _sortOptions = ['Match %', '10X Score', 'Price: Low to High', 'Price: High to Low'];

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

  int _calculateMatchPercentage(Property p) {
    int score = (p.score10x * 8).round(); // Base 72 - 80

    // Budget match
    if (_selectedBudget == 'Under ₹1 Cr' && p.askingPriceCr < 1.0) score += 7;
    if (_selectedBudget == '₹1 Cr - ₹2 Cr' && p.askingPriceCr >= 1.0 && p.askingPriceCr <= 2.0) score += 7;
    if (_selectedBudget == '₹2 Cr+' && p.askingPriceCr > 2.0) score += 7;

    // BHK match
    if (_selectedBhk != 'All' && p.bhk.toLowerCase().contains(_selectedBhk.toLowerCase().replaceAll('+', ''))) {
      score += 7;
    }

    // City match
    if (_selectedCity != 'All' && p.city.toLowerCase() == _selectedCity.toLowerCase()) {
      score += 6;
    }

    // Purpose match
    if (_selectedPurpose == 'High ROI Investment' && p.rentalYieldPercent >= 4.5) score += 6;
    if (_selectedPurpose == 'Luxury Living' && p.askingPriceCr >= 1.5) score += 6;
    if (_selectedPurpose == 'Family End-Use' && p.amenities.length >= 5) score += 6;

    if (score > 99) score = 99;
    if (score < 78) score = 78;
    return score;
  }

  String _getMatchRationale(Property p, int matchPct) {
    if (p.rentalYieldPercent >= 4.8) {
      return 'Top match: Exceptional ${p.rentalYieldPercent}% rental yield and 10X Score of ${p.score10x} in ${p.sector}.';
    } else if (p.askingPriceCr < p.fairValueCr) {
      final discount = ((p.fairValueCr - p.askingPriceCr) / p.fairValueCr * 100).round();
      return 'Value pick: Priced $discount% below fair market assessment with world-class facilities.';
    } else if (p.bhk.contains('3') || p.bhk.contains('4')) {
      return 'Spacious family layout with prime corridor connectivity and verified ownership.';
    }
    return 'Intelligent recommendation matching your lifestyle profile with ${p.score10x} AI score.';
  }

  List<Property> get _filteredProperties {
    // Only published properties
    var list = _stateService.allProperties.where((p) => p.status.toLowerCase() == 'published').toList();

    // Query Search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.sector.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query) ||
            p.builderName.toLowerCase().contains(query);
      }).toList();
    }

    // Budget Filter
    if (_selectedBudget == 'Under ₹1 Cr') {
      list = list.where((p) => p.askingPriceCr < 1.0).toList();
    } else if (_selectedBudget == '₹1 Cr - ₹2 Cr') {
      list = list.where((p) => p.askingPriceCr >= 1.0 && p.askingPriceCr <= 2.0).toList();
    } else if (_selectedBudget == '₹2 Cr+') {
      list = list.where((p) => p.askingPriceCr > 2.0).toList();
    }

    // BHK Filter
    if (_selectedBhk != 'All') {
      final key = _selectedBhk.replaceAll('+', '').toLowerCase();
      list = list.where((p) => p.bhk.toLowerCase().contains(key)).toList();
    }

    // City Filter
    if (_selectedCity != 'All') {
      list = list.where((p) => p.city.toLowerCase() == _selectedCity.toLowerCase()).toList();
    }

    // Purpose Filter
    if (_selectedPurpose == 'High ROI Investment') {
      list = list.where((p) => p.rentalYieldPercent >= 4.5).toList();
    } else if (_selectedPurpose == 'Luxury Living') {
      list = list.where((p) => p.askingPriceCr >= 1.5).toList();
    }

    // Sort
    if (_sortBy == 'Match %') {
      list.sort((a, b) => _calculateMatchPercentage(b).compareTo(_calculateMatchPercentage(a)));
    } else if (_sortBy == '10X Score') {
      list.sort((a, b) => b.score10x.compareTo(a.score10x));
    } else if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.askingPriceCr.compareTo(b.askingPriceCr));
    } else if (_sortBy == 'Price: High to Low') {
      list.sort((a, b) => b.askingPriceCr.compareTo(a.askingPriceCr));
    }

    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedBudget = 'All';
      _selectedBhk = 'All';
      _selectedCity = 'All';
      _selectedPurpose = 'All';
      _sortBy = 'Match %';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final properties = _filteredProperties;
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
                color: AppTheme.primaryViolet.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, color: AppTheme.primaryViolet, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Recommendations',
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Filters',
            icon: const Icon(LucideIcons.rotateCcw, color: AppTheme.textSecondary, size: 20),
            onPressed: _resetFilters,
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.cpu, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Propzen 10X Match Engine',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${properties.length} Matches Found',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Curated AI Recommendations',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Matched using real-time yield telemetry, infrastructure proximity & verified builder ratings in NCR.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search and Sort Bar
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
                      hintText: 'Search by property name, locality or builder...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primaryViolet, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filter Row 1: Budget & BHK
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDropdownPill('Budget', _selectedBudget, _budgetOptions, (v) => setState(() => _selectedBudget = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('BHK', _selectedBhk, _bhkOptions, (v) => setState(() => _selectedBhk = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('City', _selectedCity, _cityOptions, (v) => setState(() => _selectedCity = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('Purpose', _selectedPurpose, _purposeOptions, (v) => setState(() => _selectedPurpose = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('Sort By', _sortBy, _sortOptions, (v) => setState(() => _sortBy = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Property Grid
            if (properties.isEmpty)
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
                      mainAxisExtent: 420,
                    ),
                    itemCount: properties.length,
                    itemBuilder: (context, i) {
                      final p = properties[i];
                      final matchPct = _calculateMatchPercentage(p);
                      final rationale = _getMatchRationale(p, matchPct);
                      return _buildPropertyCard(p, matchPct, rationale);
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
    final isSelected = currentVal != 'All' && currentVal != options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryViolet.withOpacity(0.1) : AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight),
      ),
      child: DropdownButton<String>(
        value: currentVal,
        isDense: true,
        underline: const SizedBox.shrink(),
        dropdownColor: Colors.white,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppTheme.primaryViolet : AppTheme.textPrimary,
        ),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text('$label: $opt'))).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
      ),
    );
  }

  Widget _buildPropertyCard(Property p, int matchPct, String rationale) {
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
          // Image Header with Match Badge
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
                    color: AppTheme.primaryViolet,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$matchPct% Match',
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

          // Content
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
                        color: AppTheme.emeraldSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '10X: ${p.score10x}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
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
                Text(
                  '${p.sector}, ${p.city}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

                // AI Match Rationale Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.lightbulb, color: Color(0xFFF59E0B), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rationale,
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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
                      backgroundColor: AppTheme.primaryViolet,
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
                color: AppTheme.primaryViolet.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.searchX, color: AppTheme.primaryViolet, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No properties found',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your budget, BHK, or locality filters to see more recommendations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
