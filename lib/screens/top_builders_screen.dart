import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'builder_details_screen.dart';

class BuilderInfo {
  final String name;
  final String logoUrl;
  final String headquarters;
  final String establishedYear;
  final double rating;
  final int deliveredProjects;
  final String description;
  final List<String> primaryLocalities;

  const BuilderInfo({
    required this.name,
    this.logoUrl = '',
    required this.headquarters,
    required this.establishedYear,
    required this.rating,
    required this.deliveredProjects,
    required this.description,
    required this.primaryLocalities,
  });
}

class TopBuildersScreen extends StatefulWidget {
  const TopBuildersScreen({super.key});

  @override
  State<TopBuildersScreen> createState() => _TopBuildersScreenState();
}

class _TopBuildersScreenState extends State<TopBuildersScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCity = 'All';
  String _sortBy = 'Listing Count';

  final List<String> _cityOptions = ['All', 'Noida', 'Greater Noida', 'Gurgaon', 'Ghaziabad'];
  final List<String> _sortOptions = ['Listing Count', 'Rating: High to Low', 'Established Year', 'A-Z Name'];

  final List<BuilderInfo> _knownBuilders = const [
    BuilderInfo(
      name: 'Skyline Infratech',
      headquarters: 'Sector 150, Noida',
      establishedYear: '2010',
      rating: 4.8,
      deliveredProjects: 18,
      description: 'Pioneer in sports-centric luxury residential high-rises and sustainable green architecture in Noida Expressway.',
      primaryLocalities: ['Sector 150', 'Sector 148', 'Noida Expressway'],
    ),
    BuilderInfo(
      name: 'Elite Group',
      headquarters: 'Sector 137, Noida',
      establishedYear: '2006',
      rating: 4.9,
      deliveredProjects: 26,
      description: 'Award-winning developer known for transit-oriented high-speed metro-connected residences in central Noida.',
      primaryLocalities: ['Sector 137', 'Sector 143', 'Noida'],
    ),
    BuilderInfo(
      name: 'Green Valley Infra',
      headquarters: 'Techzone 4, Greater Noida',
      establishedYear: '2012',
      rating: 4.7,
      deliveredProjects: 14,
      description: 'Specialists in gated luxury villa communities, private landscaping, and low-density luxury living in Greater Noida West.',
      primaryLocalities: ['Techzone 4', 'Greater Noida West', 'Noida Extension'],
    ),
    BuilderInfo(
      name: 'Signature Global / Commercial Hub',
      headquarters: 'Sector 62, Noida',
      establishedYear: '2014',
      rating: 4.6,
      deliveredProjects: 22,
      description: 'Grade-A institutional commercial office spaces, tech parks, and lockable retail shops with high rental yields.',
      primaryLocalities: ['Sector 62', 'Sector 63', 'Electronic City'],
    ),
    BuilderInfo(
      name: 'Godrej Properties',
      headquarters: 'Golf Course Road, Gurgaon',
      establishedYear: '1990',
      rating: 4.9,
      deliveredProjects: 65,
      description: 'Nationwide premium developer with a legacy of environmental excellence, state-of-the-art designs, and punctual delivery.',
      primaryLocalities: ['Sector 150', 'Golf Course Ext', 'Sohna Road'],
    ),
    BuilderInfo(
      name: 'DLF Group',
      headquarters: 'Gurgaon, Haryana',
      establishedYear: '1946',
      rating: 4.9,
      deliveredProjects: 90,
      description: 'India’s largest publicly listed real estate entity crafting integrated super-luxury townships and prime commercial centers.',
      primaryLocalities: ['Cyber City', 'Golf Course Road', 'DLF Phase 5'],
    ),
    BuilderInfo(
      name: 'M3M India',
      headquarters: 'Golf Course Ext Road, Gurgaon',
      establishedYear: '2010',
      rating: 4.7,
      deliveredProjects: 38,
      description: 'Transforming luxury living and boutique retail avenues with ultra-modern architectural standards across NCR.',
      primaryLocalities: ['Golf Course Ext', 'Sector 65', 'Dwarka Expressway'],
    ),
    BuilderInfo(
      name: 'ATS Infrastructure',
      headquarters: 'Noida Expressway, Uttar Pradesh',
      establishedYear: '1998',
      rating: 4.8,
      deliveredProjects: 42,
      description: 'Synonymous with lush green Spanish and Greco-Roman architecture, generous floorplans, and superior construction quality.',
      primaryLocalities: ['Sector 150', 'Sector 152', 'Indirapuram'],
    ),
  ];

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

  int _getPublishedPropertyCount(String builderName) {
    return _stateService.allProperties.where((p) {
      if (p.status.toLowerCase() != 'published') return false;
      return p.builderName.toLowerCase().trim() == builderName.toLowerCase().trim() ||
          p.title.toLowerCase().contains(builderName.toLowerCase().split(' ').first);
    }).length;
  }

  List<BuilderInfo> get _filteredBuilders {
    var list = List<BuilderInfo>.from(_knownBuilders);

    // Query Search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((b) {
        return b.name.toLowerCase().contains(query) ||
            b.headquarters.toLowerCase().contains(query) ||
            b.primaryLocalities.any((loc) => loc.toLowerCase().contains(query));
      }).toList();
    }

    // City Filter
    if (_selectedCity != 'All') {
      list = list.where((b) {
        return b.headquarters.toLowerCase().contains(_selectedCity.toLowerCase()) ||
            b.primaryLocalities.any((loc) => loc.toLowerCase().contains(_selectedCity.toLowerCase()));
      }).toList();
    }

    // Sort
    if (_sortBy == 'Listing Count') {
      list.sort((a, b) => _getPublishedPropertyCount(b.name).compareTo(_getPublishedPropertyCount(a.name)));
    } else if (_sortBy == 'Rating: High to Low') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_sortBy == 'Established Year') {
      list.sort((a, b) => a.establishedYear.compareTo(b.establishedYear));
    } else if (_sortBy == 'A-Z Name') {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = 'All';
      _sortBy = 'Listing Count';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final builders = _filteredBuilders;
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
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.building, color: Color(0xFF8B5CF6), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Top Builders & Developers',
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
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
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
                            const Icon(LucideIcons.award, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Developer Network',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${builders.length} Verified Partners',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'NCR’s Most Trusted Builders',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Explore RERA-compliant builders with proven execution track records, zero litigation risks, and high capital appreciation.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search and Filters Box
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
                      hintText: 'Search builder by name, headquarters or localities...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF8B5CF6), size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filters Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDropdownPill('Region', _selectedCity, _cityOptions, (v) => setState(() => _selectedCity = v)),
                        const SizedBox(width: 8),
                        _buildDropdownPill('Sort By', _sortBy, _sortOptions, (v) => setState(() => _sortBy = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Builders Grid
            if (builders.isEmpty)
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
                      mainAxisExtent: 310,
                    ),
                    itemCount: builders.length,
                    itemBuilder: (context, i) {
                      final b = builders[i];
                      final count = _getPublishedPropertyCount(b.name);
                      return _buildBuilderCard(b, count);
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

  Widget _buildBuilderCard(BuilderInfo b, int publishedCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                ),
                child: const Center(
                  child: Icon(LucideIcons.building, color: Color(0xFF8B5CF6), size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(LucideIcons.checkCircle2, color: AppTheme.emeraldSuccess, size: 14),
                      ],
                    ),
                    Text(
                      'HQ: ${b.headquarters}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            b.description,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Key Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _buildCardStat('${b.deliveredProjects}+ Delivered', LucideIcons.checkSquare),
                _buildCardStat('${b.rating} ★', LucideIcons.star),
                _buildCardStat('$publishedCount Listings', LucideIcons.home),
              ],
            ),
          ),

          const Spacer(),

          // View Properties Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BuilderDetailsScreen(
                      builderName: b.name,
                      logoUrl: b.logoUrl,
                      description: b.description,
                      establishedYear: b.establishedYear,
                      rating: b.rating,
                      totalDeliveredProjects: b.deliveredProjects,
                      headquarters: b.headquarters,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('View Properties ($publishedCount)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStat(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
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
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.building2, color: Color(0xFF8B5CF6), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No builders match filters',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search query or region filter to view top developers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
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
