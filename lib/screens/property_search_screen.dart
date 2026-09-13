import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import '../widgets/empty_state_view.dart';
import 'property_details_screen.dart';
import 'dynamic_filter_screen.dart';

class PropertySearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? title;
  final String? filterTag;
  final String? propertyType;
  final String? amenity;
  final String? category;
  final String? initialCategoryChip;

  const PropertySearchScreen({
    super.key,
    this.initialQuery,
    this.title,
    this.filterTag,
    this.propertyType,
    this.amenity,
    this.category,
    this.initialCategoryChip,
  });

  @override
  State<PropertySearchScreen> createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  late final TextEditingController _searchController;
  String _query = '';
  String? _selectedTag;
  String? _selectedCategoryChip;

  final List<String> _categoryChips = const [
    'Noida Extension',
    'Sector 150',
    'Yamuna Expressway',
    '2 BHK Apartments',
    '3 BHK Apartments',
    'Luxury Villas',
    'Commercial Offices',
    'Ready to Move Flats',
  ];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _selectedTag = widget.filterTag;
    _selectedCategoryChip = widget.initialCategoryChip;
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Property> get _filteredResults {
    // Only published properties from PropertyStateService (Supabase + local)
    var all = PropertyStateService.instance.allProperties.where((p) => p.isPublished).toList();

    // 1. Category Chip Filter
    if (_selectedCategoryChip != null && _selectedCategoryChip!.isNotEmpty) {
      final chip = _selectedCategoryChip!;
      if (chip == 'Noida Extension') {
        all = all.where((p) {
          final str = '${p.locality} ${p.sector} ${p.address} ${p.city} ${p.title}'.toLowerCase();
          return str.contains('noida extension') || str.contains('greater noida west');
        }).toList();
      } else if (chip == 'Sector 150') {
        all = all.where((p) {
          final str = '${p.locality} ${p.sector} ${p.address} ${p.title}'.toLowerCase();
          return str.contains('sector 150') || str.contains('sector-150') || str.contains('sec 150') || str.contains('150');
        }).toList();
      } else if (chip == 'Yamuna Expressway') {
        all = all.where((p) {
          final str = '${p.locality} ${p.sector} ${p.address} ${p.title}'.toLowerCase();
          return str.contains('yamuna');
        }).toList();
      } else if (chip == '2 BHK Apartments') {
        all = all.where((p) {
          final bhk = p.bhk.trim().toLowerCase();
          final type = p.propertyType.toLowerCase();
          return bhk == '2 bhk' && (type.contains('apartment') || type.contains('flat') || type.contains('residential') || type.contains('home'));
        }).toList();
      } else if (chip == '3 BHK Apartments') {
        all = all.where((p) {
          final bhk = p.bhk.trim().toLowerCase();
          final type = p.propertyType.toLowerCase();
          return bhk == '3 bhk' && (type.contains('apartment') || type.contains('flat') || type.contains('residential') || type.contains('home'));
        }).toList();
      } else if (chip == 'Luxury Villas') {
        all = all.where((p) {
          final type = p.propertyType.toLowerCase();
          final title = p.title.toLowerCase();
          return type.contains('villa') || title.contains('villa');
        }).toList();
      } else if (chip == 'Commercial Offices') {
        all = all.where((p) {
          final type = p.propertyType.toLowerCase();
          final cat = p.category.toLowerCase();
          return type.contains('commercial') || type.contains('office') || cat == 'commercial';
        }).toList();
      } else if (chip == 'Ready to Move Flats') {
        all = all.where((p) {
          final avail = p.availability.toLowerCase();
          final poss = p.possessionDate.toLowerCase();
          final tag = p.statusTag.toLowerCase();
          final isReady = avail.contains('ready') || poss.contains('ready') || tag.contains('ready');
          final type = p.propertyType.toLowerCase();
          final isFlat = type.contains('apartment') || type.contains('flat') || type.contains('residence') || type.contains('residential');
          return isReady && isFlat;
        }).toList();
      }
    }

    // 2. Filter by Tag if specified
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      if (_selectedTag == 'Price Drop') {
        all = all.where((p) => p.statusTag == 'Price Drop' || (p.discountPercent != null && p.discountPercent! > 0)).toList();
      } else if (_selectedTag == 'Trending') {
        all = all.where((p) => p.statusTag == 'Trending').toList();
      } else if (_selectedTag == 'New Launch') {
        all = all.where((p) => p.statusTag == 'New Launch' || p.availability.toLowerCase().contains('under') || p.availability.toLowerCase().contains('upcoming')).toList();
      } else if (_selectedTag == 'Featured') {
        all = all.where((p) => p.statusTag == 'Featured').toList();
      } else if (_selectedTag == 'Verified') {
        all = all.where((p) => p.isVerified || p.isReraApproved).toList();
      }
    }

    // 3. Filter by Property Type / Category / Amenity if passed as route args
    if (widget.propertyType != null && widget.propertyType!.isNotEmpty) {
      all = all.where((p) => p.propertyType.toLowerCase().contains(widget.propertyType!.toLowerCase())).toList();
    }

    if (widget.category != null && widget.category!.isNotEmpty) {
      all = all.where((p) => p.category.toLowerCase().contains(widget.category!.toLowerCase())).toList();
    }

    if (widget.amenity != null && widget.amenity!.isNotEmpty) {
      all = all.where((p) => p.amenities.any((a) => a.toLowerCase().contains(widget.amenity!.toLowerCase()))).toList();
    }

    // 4. Search Query Filter (working seamlessly in combination with Category Chip)
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase().trim();
      all = all.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.sector.toLowerCase().contains(q) ||
            p.locality.toLowerCase().contains(q) ||
            p.city.toLowerCase().contains(q) ||
            p.builderName.toLowerCase().contains(q) ||
            p.dealerName.toLowerCase().contains(q) ||
            p.propertyType.toLowerCase().contains(q) ||
            p.bhk.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }

    return all;
  }

  void _onSelectCategoryChip(String chip) {
    setState(() {
      if (_selectedCategoryChip == chip) {
        _selectedCategoryChip = null; // Toggle off if already selected
      } else {
        _selectedCategoryChip = chip;
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _query = '';
      _searchController.clear();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryChip = null;
      _query = '';
      _searchController.clear();
    });
  }

  String get _headerTitle {
    final count = _filteredResults.length;
    if (_selectedCategoryChip != null && _query.trim().isNotEmpty) {
      return 'Results for "$_selectedCategoryChip" matching "${_query.trim()}" ($count)';
    } else if (_selectedCategoryChip != null) {
      return 'Results for "$_selectedCategoryChip" ($count)';
    } else if (_query.trim().isNotEmpty) {
      return 'Results for "${_query.trim()}" ($count)';
    } else {
      return 'All Available Properties ($count)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PropertyStateService.instance,
      builder: (context, _) {
        final results = _filteredResults;
        final screenTitle = widget.title ?? (_selectedTag != null ? '$_selectedTag Properties' : 'Properties');
        final hasActiveFilters = _selectedCategoryChip != null || _query.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            title: Text(
              screenTitle,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.slidersHorizontal, color: AppTheme.primaryViolet, size: 20),
                tooltip: 'Advanced Filters',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const DynamicFilterScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                children: [
                  // Search Input Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
                    onChanged: (val) => setState(() => _query = val),
                    decoration: InputDecoration(
                      hintText: 'Search by location, project, builder or BHK...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primaryViolet, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, color: AppTheme.textMuted, size: 18),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Category Filter Chips (Horizontal on mobile, Wrap on tablet/desktop)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktopOrTablet = constraints.maxWidth >= 600;
                  if (isDesktopOrTablet) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categoryChips.map((chip) {
                          final isSelected = _selectedCategoryChip == chip;
                          return ActionChip(
                            label: Text(
                              chip,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                            backgroundColor: isSelected ? AppTheme.primaryViolet : AppTheme.surfaceSubtle,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                            ),
                            onPressed: () => _onSelectCategoryChip(chip),
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categoryChips.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final chip = _categoryChips[i];
                        final isSelected = _selectedCategoryChip == chip;
                        return ActionChip(
                          label: Text(
                            chip,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                          backgroundColor: isSelected ? AppTheme.primaryViolet : AppTheme.surfaceSubtle,
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                          ),
                          onPressed: () => _onSelectCategoryChip(chip),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Results Header Count & Clear Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _headerTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasActiveFilters)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_query.isNotEmpty && _selectedCategoryChip != null)
                            TextButton(
                              onPressed: _clearSearch,
                              child: Text('Clear Search', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                            ),
                          TextButton(
                            onPressed: _clearAllFilters,
                            child: Text('Clear Filters', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Results Grid / List / Empty State
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: EmptyStateView(
                          title: 'No properties found',
                          message: hasActiveFilters
                              ? 'No properties found matching your selected filters.'
                              : 'Real properties from the backend/database will appear here once added.',
                          icon: LucideIcons.searchX,
                          actionLabel: hasActiveFilters ? 'Clear Filters' : null,
                          onAction: hasActiveFilters ? _clearAllFilters : null,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 1;
                          if (constraints.maxWidth >= 1000) {
                            crossAxisCount = 3;
                          } else if (constraints.maxWidth >= 600) {
                            crossAxisCount = 2;
                          }

                          final double aspectRatio = crossAxisCount >= 3
                              ? 0.78
                              : (crossAxisCount == 2
                                  ? 0.72
                                  : (constraints.maxWidth < 360 ? 0.65 : 0.70));

                          return GridView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: results.length,
                            itemBuilder: (ctx, i) {
                              final prop = results[i];
                              return PropertyCard(
                                property: prop,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => PropertyDetailsScreen(property: prop, propertyId: prop.id),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
