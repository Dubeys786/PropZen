import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class PriceDropDealsScreen extends StatefulWidget {
  const PriceDropDealsScreen({super.key});

  @override
  State<PriceDropDealsScreen> createState() => _PriceDropDealsScreenState();
}

class _PriceDropDealsScreenState extends State<PriceDropDealsScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _selectedDiscount = 'All Deals';
  String _selectedCity = 'All';
  String _selectedBhk = 'All';
  String _sortBy = 'Highest % Drop';

  final List<String> _discountOptions = ['All Deals', '5%+ Drop', '10%+ Drop', '15%+ Drop'];
  final List<String> _cityOptions = ['All', 'Noida', 'Greater Noida', 'Gurgaon', 'Ghaziabad'];
  final List<String> _bhkOptions = ['All', '2 BHK', '3 BHK', '4 BHK+'];
  final List<String> _sortOptions = ['Highest % Drop', 'Highest ₹ Savings', 'Price: Low to High', '10X Score'];

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

  double _getOriginalPriceCr(Property p) {
    if (p.originalPriceCr != null && p.originalPriceCr! > p.askingPriceCr) {
      return p.originalPriceCr!;
    }
    if (p.fairValueCr > p.askingPriceCr) {
      return p.fairValueCr;
    }
    if (p.discountPercent != null && p.discountPercent! > 0) {
      return p.askingPriceCr / (1 - (p.discountPercent! / 100));
    }
    return p.askingPriceCr * 1.10; // 10% benchmark
  }

  double _getSavingsCr(Property p) {
    final orig = _getOriginalPriceCr(p);
    return double.parse((orig - p.askingPriceCr).toStringAsFixed(2));
  }

  int _getDropPercent(Property p) {
    if (p.discountPercent != null && p.discountPercent! > 0) {
      return p.discountPercent!;
    }
    final orig = _getOriginalPriceCr(p);
    if (orig <= p.askingPriceCr) return 0;
    return (((orig - p.askingPriceCr) / orig) * 100).round();
  }

  String _formatPriceCr(double priceCr) {
    if (priceCr >= 1.0) {
      final str = priceCr.toStringAsFixed(2);
      final clean = str.endsWith('.00')
          ? str.substring(0, str.length - 3)
          : (str.endsWith('0') ? str.substring(0, str.length - 1) : str);
      return '₹$clean Cr';
    } else {
      final lakhs = (priceCr * 100).round();
      return '₹$lakhs Lakh';
    }
  }

  List<Property> get _dealProperties {
    // Only published properties with actual price reduction
    var list = _stateService.allProperties.where((p) {
      if (p.status.toLowerCase() != 'published') return false;
      final dropPct = _getDropPercent(p);
      return dropPct >= 4; // Genuine discount
    }).toList();

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

    // BHK filter
    if (_selectedBhk != 'All') {
      final key = _selectedBhk.replaceAll('+', '').toLowerCase();
      list = list.where((p) => p.bhk.toLowerCase().contains(key)).toList();
    }

    // Min Discount filter
    if (_selectedDiscount == '5%+ Drop') {
      list = list.where((p) => _getDropPercent(p) >= 5).toList();
    } else if (_selectedDiscount == '10%+ Drop') {
      list = list.where((p) => _getDropPercent(p) >= 10).toList();
    } else if (_selectedDiscount == '15%+ Drop') {
      list = list.where((p) => _getDropPercent(p) >= 15).toList();
    }

    // Sort
    if (_sortBy == 'Highest % Drop') {
      list.sort((a, b) => _getDropPercent(b).compareTo(_getDropPercent(a)));
    } else if (_sortBy == 'Highest ₹ Savings') {
      list.sort((a, b) => _getSavingsCr(b).compareTo(_getSavingsCr(a)));
    } else if (_sortBy == 'Price: Low to High') {
      list.sort((a, b) => a.askingPriceCr.compareTo(b.askingPriceCr));
    } else if (_sortBy == '10X Score') {
      list.sort((a, b) => b.score10x.compareTo(a.score10x));
    }

    return list;
  }

  void _resetFilters() {
    setState(() {
      _selectedDiscount = 'All Deals';
      _selectedCity = 'All';
      _selectedBhk = 'All';
      _sortBy = 'Highest % Drop';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final properties = _dealProperties;
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
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.tag, color: Color(0xFFEF4444), size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Price Drop Deals',
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
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
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
                            const Icon(LucideIcons.badgePercent, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Builder Discounts',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${properties.length} Active Deals',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exclusive Price Drop Deals',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Direct developer rate cuts, festive discounts, and limited inventory reductions verified across NCR.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search & Filter Box
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
                      hintText: 'Search discounted projects, developers or sectors...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(LucideIcons.search, color: Color(0xFFEF4444), size: 18),
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
                        _buildDropdownPill('Discount', _selectedDiscount, _discountOptions, (v) => setState(() => _selectedDiscount = v)),
                        const SizedBox(width: 8),
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
                      mainAxisExtent: 430,
                    ),
                    itemCount: properties.length,
                    itemBuilder: (context, i) {
                      final p = properties[i];
                      return _buildPriceDropCard(p);
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

  Widget _buildPriceDropCard(Property p) {
    final isSaved = _stateService.isSaved(p.id);
    final origCr = _getOriginalPriceCr(p);
    final savingsCr = _getSavingsCr(p);
    final dropPct = _getDropPercent(p);

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
          // Image with Price Drop Badge
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
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.arrowDownRight, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$dropPct% Price Drop',
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
                // Price Comparison Box
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatPriceCr(p.askingPriceCr),
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatPriceCr(origCr),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldSuccess.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Save ${_formatPriceCr(savingsCr)}',
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
                    _buildSpecTag(LucideIcons.percent, '${p.rentalYieldPercent}% Yield'),
                  ],
                ),

                const SizedBox(height: 10),

                // Deal Callout Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.sparkles, color: Color(0xFFEF4444), size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Direct builder price drop. Fair value assessment at ${_formatPriceCr(p.fairValueCr)}.',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF991B1B), fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      backgroundColor: const Color(0xFFEF4444),
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
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.badgeAlert, color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'No price drop deals match filters',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Try lowering your minimum discount requirement to explore all discounted properties in NCR.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
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
