import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/ai_service_tool_data.dart';
import '../services/supabase_service.dart';
import 'service_detail_screen.dart';
import 'ai_tool_detail_screen.dart';

/// Dedicated PropZen Service Hub Page (/services)
/// Features general real-estate services: Home Design, Interior Design, Exterior Design,
/// Property Visualization, Vastu Consultancy, Document Verification, Loan Consultancy,
/// Construction Support, and Drone Tour.
class AllFeaturesScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const AllFeaturesScreen({super.key, this.onNavigateTab});

  @override
  State<AllFeaturesScreen> createState() => _AllFeaturesScreenState();
}

class _AllFeaturesScreenState extends State<AllFeaturesScreen> {
  String? _selectedCategory; // null or 'All Services' = all categories
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<AiServiceTool> _services = [];

  static const List<String> _categoryList = [
    'All Services',
    'Home Design',
    'Interior Design',
    'Exterior Design',
    'Property Visualization',
    'Vastu Consultancy',
    'Document Verification',
    'Loan Consultancy',
    'Construction Support',
    'Drone Tour',
  ];

  @override
  void initState() {
    super.initState();
    _services = List.from(AiServiceRegistry.allTools);
    _loadServicesFromBackend();
  }

  Future<void> _loadServicesFromBackend() async {
    try {
      final data = await SupabaseService.instance.fetchServices();
      if (mounted && data.isNotEmpty) {
        setState(() {
          _services = data;
        });
      }
    } catch (_) {
      // Gracefully falls back to registry
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _isLoading = false;
    });
  }

  void _selectCategory(String? category) {
    if (category == null || category == 'All Services' || _selectedCategory == category) {
      setState(() {
        _selectedCategory = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _openServiceDetail(BuildContext context, AiServiceTool tool) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          title: tool.title,
          category: tool.primaryCategory,
          description: tool.fullDescription.isNotEmpty ? tool.fullDescription : tool.shortDescription,
          icon: tool.icon,
          accentColor: tool.accentColor,
          features: tool.features,
          startingPrice: tool.price != null && tool.price! > 0
              ? '₹${tool.price!.toInt()}'
              : 'Consultation Included',
          estimatedTime: tool.badgeLabel,
          imageUrl: tool.uniqueImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _searchQuery.toLowerCase().trim();

    // Use either backend services or dynamic registry
    final currentTools = _services.isNotEmpty ? _services : AiServiceRegistry.allTools;

    // Filter tools dynamically by category and search keyword (DEFAULT: ALL VISIBLE)
    final filteredTools = currentTools.where((tool) {
      // 1. Category Filter Match
      if (_selectedCategory != null && _selectedCategory != 'All Services') {
        final selectedNorm = _selectedCategory!.trim().toLowerCase();
        final primaryNorm = tool.primaryCategory.trim().toLowerCase();
        final matchesCategory = primaryNorm == selectedNorm ||
            tool.allCategories.any((c) => c.trim().toLowerCase() == selectedNorm);
        if (!matchesCategory) return false;
      }

      // 2. Keyword & Multi-field Search Match
      if (query.isNotEmpty) {
        final matchesQuery = tool.title.toLowerCase().contains(query) ||
            tool.primaryCategory.toLowerCase().contains(query) ||
            tool.shortDescription.toLowerCase().contains(query) ||
            tool.fullDescription.toLowerCase().contains(query) ||
            tool.searchKeywords.any((k) => k.toLowerCase().contains(query)) ||
            tool.features.any((f) => f.toLowerCase().contains(query));
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              'PropZen Service Hub',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Title & Subtitle
                _buildHeaderSection(),

                const SizedBox(height: 20),

                // 2. Search Bar with Dynamic Query Trigger
                _buildSearchBar(),

                const SizedBox(height: 16),

                // 3. Category Selection Filter Chips
                _buildCategoryPills(),

                const SizedBox(height: 24),

                // 4. Results Container / Loading / Empty State / All Services Grid
                if (_isLoading)
                  _buildLoadingState()
                else if (filteredTools.isEmpty)
                  _buildNoMatchesFoundState()
                else
                  _buildToolsGrid(filteredTools),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'VERIFIED REAL ESTATE SERVICES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryViolet,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'PropZen Service Hub',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Everything you need to design, verify, finance and complete your property journey.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textHint),
          prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppTheme.primaryViolet),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categoryList.map((cat) {
          final isAllServices = cat == 'All Services';
          final isSelected = isAllServices
              ? (_selectedCategory == null || _selectedCategory == 'All Services')
              : (_selectedCategory?.toLowerCase() == cat.toLowerCase());

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryViolet,
              backgroundColor: AppTheme.cardWhite,
              side: BorderSide(
                color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                if (isAllServices) {
                  _selectCategory(null);
                } else {
                  _selectCategory(selected ? cat : null);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryViolet,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Filtering services...',
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesFoundState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.coralDanger.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.searchX, size: 36, color: AppTheme.coralDanger),
          ),
          const SizedBox(height: 16),
          Text(
            'No services found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Try another search.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(LucideIcons.rotateCcw, size: 14),
            label: const Text('View All Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(List<AiServiceTool> tools) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1024) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 640) {
          crossAxisCount = 2;
        }

        double childAspectRatio = 0.85;
        if (constraints.maxWidth >= 1024) {
          childAspectRatio = 0.88;
        } else if (constraints.maxWidth >= 640) {
          childAspectRatio = 0.86;
        } else {
          childAspectRatio = 0.82;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _buildToolCard(tool);
          },
        );
      },
    );
  }

  Widget _buildToolCard(AiServiceTool tool) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openServiceDetail(context, tool),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Visual Header with Unique Imagery
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: tool.uniqueImageUrl.isNotEmpty
                        ? Image.network(
                            tool.uniqueImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppTheme.surfaceHighlight,
                              child: Center(
                                child: Icon(tool.icon, size: 36, color: tool.accentColor.withOpacity(0.5)),
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceHighlight,
                            child: Center(
                              child: Icon(tool.icon, size: 36, color: tool.accentColor.withOpacity(0.5)),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Badge Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tool.accentColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        tool.badgeLabel,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Category Pill
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tool.primaryCategory,
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: tool.accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(tool.icon, color: tool.accentColor, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tool.title,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Short Description
                      Text(
                        tool.shortDescription.isNotEmpty ? tool.shortDescription : tool.fullDescription,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Action Buttons: View Details & Explore
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () => _openServiceDetail(context, tool),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tool.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Explore Service',
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(LucideIcons.arrowRight, size: 14),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
