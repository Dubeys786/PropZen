import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class NewLaunchProjectsScreen extends StatefulWidget {
  const NewLaunchProjectsScreen({super.key});

  @override
  State<NewLaunchProjectsScreen> createState() => _NewLaunchProjectsScreenState();
}

class _NewLaunchProjectsScreenState extends State<NewLaunchProjectsScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedTab = 'All Launches'; // All Launches, New Launch, Pre-Launch, Under Construction
  String _selectedCity = 'All';
  String _selectedBhk = 'All';
  String _sortBy = 'Possession Timeline';

  final List<String> _tabs = ['All Launches', 'New Launch', 'Pre-Launch', 'Under Construction'];
  final List<String> _cityOptions = ['All', 'Noida', 'Greater Noida', 'Gurgaon', 'Ghaziabad'];
  final List<String> _bhkOptions = ['All', '2 BHK', '3 BHK', '4 BHK+'];
  final List<String> _sortOptions = ['Possession Timeline', 'Price: Low to High', 'Price: High to Low', '10X Score'];

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

  String _getLaunchStage(Property p) {
    if (p.statusTag.toLowerCase() == 'new launch') return 'New Launch';
    if (p.availability.toLowerCase().contains('upcoming') || p.statusTag.toLowerCase().contains('pre')) return 'Pre-Launch';
    if (p.availability.toLowerCase().contains('under') || p.possessionStatus.toLowerCase().contains('under')) return 'Under Construction';
    return 'New Launch';
  }

  List<Property> get _launchProperties {
    // Only published properties that represent new/upcoming/pre-launch projects
    var list = _stateService.allProperties.where((p) {
      if (p.status.toLowerCase() != 'published') return false;
      final stage = _getLaunchStage(p);
      if (_selectedTab == 'New Launch') return stage == 'New Launch';
      if (_selectedTab == 'Pre-Launch') return stage == 'Pre-Launch';
      if (_selectedTab == 'Under Construction') return stage == 'Under Construction';
      return true; // All Launches
    }).toList();

    // Query Search
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.sector.toLowerCase().contains(query) ||
            p.city.toLowerCase().contains(query) ||
            p.builderName.toLowerCase().contains(query) ||
            p.reraId.toLowerCase().contains(query);
      }).toList();
    }

    // City Filter
    if (_selectedCity != 'All') {
      list = list.where((p) => p.city.toLowerCase() == _selectedCity.toLowerCase()).toList();
    }

    // BHK Filter
    if (_selectedBhk != 'All') {
      final key = _selectedBhk.replaceAll('+', '').toLowerCase();
      list = list.where((p) => p.bhk.toLowerCase().contains(key)).toList();
    }

    // Sort
    if (_sortBy == 'Possession Timeline') {
      list.sort((a, b) => a.possessionDate.compareTo(b.possessionDate));
    } else if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.askingPriceCr.compareTo(b.askingPriceCr));
    } else if (_sortBy == 'Price: High to Low') {
      list.sort((a, b) => b.askingPriceCr.compareTo(a.askingPriceCr));
    } else if (_sortBy == '10X Score') {
      list.sort((a, b) => b.score10x.compareTo(a.score10x));
    }

    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedTab = 'All Launches';
      _selectedCity = 'All';
      _selectedBhk = 'All';
      _sortBy = 'Possession Timeline';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final properties = _launchProperties;
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
                color: const Color(0xFF38BDF8).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkle, color: Color(0xFF0284C7), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'New Launch Projects',
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
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
                            const Icon(LucideIcons.rocket, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Inaugural & Pre-Launch Inventory',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${properties.length} New Projects',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exclusive New Launches in NCR',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Get early-bird pricing, flexible construction-linked payment plans, and priority unit allocations.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Launch Stage Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tabs.map((t) {
                  final isSel = _selectedTab == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: isSel,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel ? Colors.white : AppTheme.textPrimary,
                      ),
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedTab = t);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Search and Filters Bar
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
                      hintText: 'Search launch project, builder, sector or RERA ID...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF0284C7), size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildDropdownPill('City', _selectedCity, _cityOptions, (v) => setState(() => _selectedCity = v)),
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

            // Projects Grid
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
                      return _buildNewLaunchCard(p);
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

  Widget _buildNewLaunchCard(Property p) {
    final isSaved = _stateService.isSaved(p.id);
    final stage = _getLaunchStage(p);

    Color badgeColor = const Color(0xFF0284C7);
    IconData badgeIcon = LucideIcons.rocket;
    if (stage == 'Pre-Launch') {
      badgeColor = const Color(0xFF8B5CF6);
      badgeIcon = LucideIcons.sparkles;
    } else if (stage == 'Under Construction') {
      badgeColor = const Color(0xFFF59E0B);
      badgeIcon = LucideIcons.hardHat;
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
          // Image Header with Stage Pill
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        stage,
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
                        color: const Color(0xFF0284C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${p.pricePerSqft.toInt()}/sqft',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
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
                    _buildSpecTag(LucideIcons.shieldCheck, 'RERA ${p.isReraApproved ? "Approved" : "Pending"}'),
                  ],
                ),
                const SizedBox(height: 10),

                // Possession Timeline Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, color: Color(0xFF0284C7), size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Possession: ${p.possessionDate}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),

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
                      backgroundColor: const Color(0xFF0284C7),
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
                color: const Color(0xFF0284C7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, color: Color(0xFF0284C7), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No new launch projects match filters',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try selecting "All Launches" or resetting your city and BHK filters to see new inventory in NCR.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
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
