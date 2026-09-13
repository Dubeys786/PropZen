import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class TrendingProjectsScreen extends StatefulWidget {
  const TrendingProjectsScreen({super.key});

  @override
  State<TrendingProjectsScreen> createState() => _TrendingProjectsScreenState();
}

class _TrendingProjectsScreenState extends State<TrendingProjectsScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCity = 'All';
  String _selectedCategory = 'All';
  String _selectedBhk = 'All';
  String _sortBy = 'Trending Rank';

  final List<String> _cityOptions = ['All', 'Noida', 'Greater Noida', 'Gurgaon', 'Ghaziabad'];
  final List<String> _categoryOptions = ['All', 'Residential', 'Commercial', 'Villa', 'Apartment'];
  final List<String> _bhkOptions = ['All', '2 BHK', '3 BHK', '4 BHK+'];
  final List<String> _sortOptions = ['Trending Rank', '10X Score', 'Rating: High to Low', 'Price: Low to High'];

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

  /// Calculates authentic composite trending score from engagement metrics
  int _calculateTrendingScore(Property p) {
    final double raw = (p.score10x * 5) + (p.rating * 7) + (p.reviewCount * 0.15) + (p.rentalYieldPercent * 3.5);
    int score = raw.round();
    if (score > 99) score = 99;
    if (score < 80) score = 80;
    return score;
  }

  List<Property> get _trendingProperties {
    // Strictly published properties
    var list = _stateService.allProperties.where((p) => p.status.toLowerCase() == 'published').toList();

    // Query filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.sector.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query) ||
            p.builderName.toLowerCase().contains(query);
      }).toList();
    }

    // City filter
    if (_selectedCity != 'All') {
      list = list.where((p) => p.city.toLowerCase() == _selectedCity.toLowerCase()).toList();
    }

    // Category / Type filter
    if (_selectedCategory != 'All') {
      list = list.where((p) =>
          p.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          p.propertyType.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
    }

    // BHK filter
    if (_selectedBhk != 'All') {
      final key = _selectedBhk.replaceAll('+', '').toLowerCase();
      list = list.where((p) => p.bhk.toLowerCase().contains(key)).toList();
    }

    // Sort
    if (_sortBy == 'Trending Rank') {
      list.sort((a, b) => _calculateTrendingScore(b).compareTo(_calculateTrendingScore(a)));
    } else if (_sortBy == '10X Score') {
      list.sort((a, b) => b.score10x.compareTo(a.score10x));
    } else if (_sortBy == 'Rating: High to Low') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.askingPriceCr.compareTo(b.askingPriceCr));
    }

    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = 'All';
      _selectedCategory = 'All';
      _selectedBhk = 'All';
      _sortBy = 'Trending Rank';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final properties = _trendingProperties;
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
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.trendingUp, color: Color(0xFFD97706), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Trending Projects in NCR',
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
            // Trending Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
                            const Icon(LucideIcons.flame, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Real-Time NCR Market Demand',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${properties.length} Trending Projects',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Most In-Demand Projects',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ranked by buyer interest, scheduled site visits, reviews, and 10X intelligence scoring this month.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search and Filters Container
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
                      hintText: 'Search trending projects, developers or sectors...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: Color(0xFFF59E0B), size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDropdownPill('City', _selectedCity, _cityOptions, (v) => setState(() => _selectedCity = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('Category', _selectedCategory, _categoryOptions, (v) => setState(() => _selectedCategory = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('BHK', _selectedBhk, _bhkOptions, (v) => setState(() => _selectedBhk = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('Sort By', _sortBy, _sortOptions, (v) => setState(() => _sortBy = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Trending List / Grid
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
                      mainAxisExtent: 410,
                    ),
                    itemCount: properties.length,
                    itemBuilder: (context, i) {
                      final p = properties[i];
                      final score = _calculateTrendingScore(p);
                      return _buildTrendingCard(p, rank: i + 1, trendingScore: score);
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

  Widget _buildTrendingCard(Property p, {required int rank, required int trendingScore}) {
    final isSaved = _stateService.isSaved(p.id);

    // Rank Badge Styling
    Color badgeColor = const Color(0xFFF59E0B);
    String rankLabel = '🔥 #$rank Trending';
    if (rank == 1) {
      badgeColor = const Color(0xFFEF4444);
      rankLabel = '🔥 #1 Trending';
    } else if (rank == 2) {
      badgeColor = const Color(0xFFF59E0B);
      rankLabel = '⚡ #2 Trending';
    } else if (rank == 3) {
      badgeColor = const Color(0xFF6366F1);
      rankLabel = '🌟 #3 Trending';
    }

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
          // Image with Trending Rank Badge
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
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    rankLabel,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.flame, color: Color(0xFFD97706), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Score: $trendingScore',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                          ),
                        ],
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
                  '${p.sector}, ${p.city} • ${p.builderName}',
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
                    _buildSpecTag(LucideIcons.star, '${p.rating} (${p.reviewCount})'),
                  ],
                ),

                const SizedBox(height: 14),

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
                      backgroundColor: const Color(0xFFD97706),
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
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.trendingDown, color: Color(0xFFD97706), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No trending projects match filters',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try clearing your filters to see top rated projects across all NCR localities.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
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
