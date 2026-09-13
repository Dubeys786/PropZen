import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/filter_model.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';

class DynamicFilterScreen extends StatefulWidget {
  final VoidCallback? onApply;

  const DynamicFilterScreen({super.key, this.onApply});

  @override
  State<DynamicFilterScreen> createState() => _DynamicFilterScreenState();
}

class _DynamicFilterScreenState extends State<DynamicFilterScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  late PropertyFilter _tempFilter;

  final List<String> _cities = ['All', 'Noida', 'Greater Noida', 'Gurugram', 'Delhi'];
  final List<String> _propertyTypes = ['All', 'Apartment', 'Villa', 'Plot', 'Commercial', 'PG/Co-living'];
  final List<String> _bhkOptions = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK'];
  final List<String> _possessionOptions = ['All', 'Ready to Move', 'Under Construction', 'Upcoming'];
  final List<String> _statusOptions = ['All', 'New Launch', 'Trending', 'Price Drop', 'Featured'];
  final List<String> _furnishingOptions = ['All', 'Fully Furnished', 'Semi-Furnished', 'Unfurnished'];
  final List<String> _sortOptions = ['Recommended', 'Price Low to High', 'Price High to Low', 'Newest', 'Most Viewed'];

  final List<String> _amenitiesList = [
    'Club House',
    'Swimming Pool',
    'Gym',
    '24/7 Security',
    'Children Play Area',
    'Landscaped Garden',
    'Power Backup',
    'Lift',
    'Sports Facilities',
    'Parking'
  ];

  @override
  void initState() {
    super.initState();
    _tempFilter = _stateService.currentFilter.clone();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _tempFilter.activeFilterCount;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Advanced Filters',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _tempFilter.reset();
              });
            },
            child: Text(
              'Reset All',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. City / Location
            _buildSectionTitle('City / Location', LucideIcons.mapPin),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cities.map((city) {
                final isSel = _tempFilter.city == city;
                return ChoiceChip(
                  label: Text(city),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (sel) => setState(() => _tempFilter.city = city),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 2. Property Type
            _buildSectionTitle('Property Type', LucideIcons.home),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _propertyTypes.map((type) {
                final isSel = _tempFilter.propertyType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (sel) => setState(() => _tempFilter.propertyType = type),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 3. BHK Configuration (Multi-select)
            _buildSectionTitle('BHK Configuration', LucideIcons.layers),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bhkOptions.map((bhk) {
                final isSel = _tempFilter.bhkList.contains(bhk);
                return FilterChip(
                  label: Text(bhk),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textSecondary,
                  ),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _tempFilter.bhkList.add(bhk);
                      } else {
                        _tempFilter.bhkList.remove(bhk);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 4. Budget Range
            _buildSectionTitle('Budget Range', LucideIcons.indianRupee),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBudgetChip('All Budgets', null, null),
                _buildBudgetChip('Under ₹50L', null, 0.50),
                _buildBudgetChip('₹50L - ₹1 Cr', 0.50, 1.00),
                _buildBudgetChip('₹1 Cr - ₹2 Cr', 1.00, 2.00),
                _buildBudgetChip('₹2 Cr - ₹5 Cr', 2.00, 5.00),
                _buildBudgetChip('₹5 Cr+', 5.00, null),
              ],
            ),

            const SizedBox(height: 24),

            // 5. Possession Status
            _buildSectionTitle('Possession Status', LucideIcons.calendarCheck),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _possessionOptions.map((pos) {
                final isSel = _tempFilter.possession == pos;
                return ChoiceChip(
                  label: Text(pos),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (sel) => setState(() => _tempFilter.possession = pos),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 6. Property Status Tag
            _buildSectionTitle('Property Tag', LucideIcons.tag),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((status) {
                final isSel = _tempFilter.propertyStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (sel) => setState(() => _tempFilter.propertyStatus = status),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 7. Amenities (Multi-select)
            _buildSectionTitle('Amenities & Features', LucideIcons.sparkles),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _amenitiesList.map((amenity) {
                final isSel = _tempFilter.amenities.contains(amenity);
                return FilterChip(
                  label: Text(amenity),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textSecondary,
                  ),
                  onSelected: (sel) {
                    setState(() {
                      if (sel) {
                        _tempFilter.amenities.add(amenity);
                      } else {
                        _tempFilter.amenities.remove(amenity);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 8. Furnishing
            _buildSectionTitle('Furnishing Status', LucideIcons.sofa),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _furnishingOptions.map((furn) {
                final isSel = _tempFilter.furnishing == furn;
                return ChoiceChip(
                  label: Text(furn),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (sel) => setState(() => _tempFilter.furnishing = furn),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 9. RERA Verified Only Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: AppTheme.emeraldSuccess, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RERA Approved Properties Only',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          Text(
                            'Verified state government registry registration',
                            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Switch(
                    value: _tempFilter.reraApprovedOnly == true,
                    activeColor: AppTheme.primaryViolet,
                    onChanged: (val) {
                      setState(() {
                        _tempFilter.reraApprovedOnly = val ? true : null;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 10. Sort By
            _buildSectionTitle('Sort Properties By', LucideIcons.arrowUpDown),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((s) {
                final isSel = _tempFilter.sortBy == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: isSel,
                  selectedColor: AppTheme.primaryViolet,
                  backgroundColor: AppTheme.surfaceSubtle,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.white : AppTheme.textPrimary,
                  ),
                  onSelected: (sel) => setState(() => _tempFilter.sortBy = s),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _stateService.updateFilter((f) {
                    f.city = _tempFilter.city;
                    f.locality = _tempFilter.locality;
                    f.propertyType = _tempFilter.propertyType;
                    f.minPriceCr = _tempFilter.minPriceCr;
                    f.maxPriceCr = _tempFilter.maxPriceCr;
                    f.bhkList = List.from(_tempFilter.bhkList);
                    f.minAreaSqft = _tempFilter.minAreaSqft;
                    f.maxAreaSqft = _tempFilter.maxAreaSqft;
                    f.possession = _tempFilter.possession;
                    f.propertyStatus = _tempFilter.propertyStatus;
                    f.amenities = Set.from(_tempFilter.amenities);
                    f.reraApprovedOnly = _tempFilter.reraApprovedOnly;
                    f.furnishing = _tempFilter.furnishing;
                    f.builderOrDealer = _tempFilter.builderOrDealer;
                    f.sortBy = _tempFilter.sortBy;
                  });

                  if (widget.onApply != null) {
                    widget.onApply!();
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  activeCount > 0 ? 'Apply Filters ($activeCount Active)' : 'Apply All Properties',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryViolet),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetChip(String label, double? min, double? max) {
    final isSel = _tempFilter.minPriceCr == min && _tempFilter.maxPriceCr == max;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: AppTheme.primaryViolet,
      backgroundColor: AppTheme.surfaceSubtle,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? Colors.white : AppTheme.textPrimary,
      ),
      onSelected: (sel) {
        setState(() {
          _tempFilter.minPriceCr = min;
          _tempFilter.maxPriceCr = max;
        });
      },
    );
  }
}
