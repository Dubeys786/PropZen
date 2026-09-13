import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/ai_service_tool_data.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/propzen_voice_agent_modal.dart';
import '../theme/responsive_layout.dart';
import 'property_search_screen.dart';
import 'ai_advisor_chat_screen.dart';
import 'service_detail_screen.dart';
import 'ai_tool_detail_screen.dart';
import 'admin_panel_screen.dart';
import 'find_my_perfect_property_screen.dart';
import 'near_me_properties_screen.dart';
import 'ai_listing_creator_screen.dart';
import 'dealer_dashboard_screen.dart';
import 'all_features_screen.dart';
import 'user_profile_screen.dart';
import 'finance_tools_hub_screen.dart';
import 'credit_score_center_screen.dart';
import 'city_intelligence_hub_screen.dart';
import 'explore_india_screen.dart';
import 'market_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final bool showOnlyPropertiesSection;

  const HomeScreen({
    super.key,
    this.onNavigateTab,
    this.showOnlyPropertiesSection = false,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  final ScrollController _scrollController = ScrollController();

  // Search Bar States
  String _selectedSearchTab = 'Buy'; // Buy, Rent, PG/Co-living, Commercial
  final TextEditingController _searchController = TextEditingController();
  String _selectedPropType = 'Property Type';
  String _selectedBudget = 'Budget';

  // Featured Properties Filter Tab
  String _selectedFeaturedTab = 'All'; // All, New Launch, Ready to Move, Price Drop

  // Countdown Timer for Deal of the Day
  late Timer _timer;
  int _secondsRemaining = (12 * 3600) + (45 * 60) + 30;

  final List<String> _propertyTypeDropdowns = [
    'Property Type',
    'Apartment / Flat',
    'Villa',
    'Plot',
    'Commercial',
    'PG / Co-living',
  ];

  final List<String> _budgetDropdowns = [
    'Budget',
    'Under ₹50L',
    '₹50L - ₹1 Cr',
    '₹1 Cr - ₹2 Cr',
    '₹2 Cr - ₹5 Cr',
    '₹5 Cr+',
  ];

  // Smart Discovery Categories
  final List<Map<String, dynamic>> _smartDiscoveryCategories = [
    {'label': '2 BHK', 'icon': LucideIcons.home, 'type': 'bhk', 'value': 2},
    {'label': '3 BHK', 'icon': LucideIcons.building, 'type': 'bhk', 'value': 3},
    {'label': 'Luxury Villas', 'icon': LucideIcons.sparkles, 'type': 'propertyType', 'value': 'Villa'},
    {'label': 'Ready to Move', 'icon': LucideIcons.checkCircle2, 'type': 'availability', 'value': 'Ready to Move'},
    {'label': 'Commercial', 'icon': LucideIcons.briefcase, 'type': 'propertyType', 'value': 'Commercial'},
    {'label': 'Plots', 'icon': LucideIcons.map, 'type': 'propertyType', 'value': 'Plot'},
    {'label': 'Noida', 'icon': LucideIcons.mapPin, 'type': 'location', 'value': 'Noida'},
    {'label': 'Greater Noida', 'icon': LucideIcons.mapPin, 'type': 'location', 'value': 'Greater Noida'},
    {'label': 'Yamuna Expressway', 'icon': LucideIcons.navigation, 'type': 'location', 'value': 'Yamuna Expressway'},
    {'label': 'Noida Extension', 'icon': LucideIcons.compass, 'type': 'location', 'value': 'Noida Extension'},
  ];

  // Why PropZen Items
  final List<Map<String, dynamic>> _whyChoosePropZenItems = [
    {
      'title': 'AI-Powered Discovery',
      'desc': 'Find properties matching your real requirements.',
      'icon': LucideIcons.sparkles,
      'color': AppTheme.primaryViolet,
    },
    {
      'title': 'Property Verification',
      'desc': 'Get structured property verification information.',
      'icon': LucideIcons.shieldCheck,
      'color': AppTheme.emeraldSuccess,
    },
    {
      'title': 'Smart Site Visits',
      'desc': 'Book and manage property visits easily.',
      'icon': LucideIcons.calendarCheck,
      'color': AppTheme.indigoPrimary,
    },
    {
      'title': 'Complete Deal Journey',
      'desc': 'From discovery to documentation and deal management.',
      'icon': LucideIcons.briefcase,
      'color': const Color(0xFFF59E0B),
    },
  ];

  // PropZen AI Feature Cards
  final List<Map<String, dynamic>> _aiFeatureCards = [
    {
      'id': 'ai_advisor',
      'title': 'AI Property Advisor',
      'desc': 'Intelligent conversational matching based on your lifestyle & budget.',
      'icon': LucideIcons.messageSquare,
      'color': AppTheme.primaryViolet,
    },
    {
      'id': 'ai_voice_agent',
      'title': 'AI Voice Agent',
      'desc': 'Instant multilingual voice Q&A and hands-free site visit booking.',
      'icon': LucideIcons.mic,
      'color': const Color(0xFF4F46E5),
    },
    {
      'id': 'ai_matching',
      'title': 'AI Property Matching',
      'desc': 'Deep questionnaire matching algorithm tailored to your lifestyle.',
      'icon': LucideIcons.sparkles,
      'color': const Color(0xFF06B6D4),
    },
    {
      'id': 'ai_listing_creator',
      'title': 'AI Listing Creator',
      'desc': 'Generate high-converting property descriptions & social posts.',
      'icon': LucideIcons.fileText,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'ai_lead_scoring',
      'title': 'AI Lead Scoring',
      'desc': 'Predict buyer intent & match top-converting leads for dealers.',
      'icon': LucideIcons.trendingUp,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'ai_verification',
      'title': 'AI Property Verification',
      'desc': 'Automated document, title & RERA legal compliance checking.',
      'icon': LucideIcons.shieldCheck,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  // 8 Selected Services for Service Hub
  final List<Map<String, dynamic>> _servicesHubItems = [
    {
      'id': 'ai_home_designer',
      'title': 'Home Design',
      'category': 'Architecture',
      'icon': LucideIcons.home,
      'desc': 'Complete architectural layout & 3D space planning',
      'imageUrl': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_interior_designer',
      'title': 'Interior Design',
      'category': 'Interior Design',
      'icon': LucideIcons.palette,
      'desc': 'Turnkey modular design by top architects',
      'imageUrl': 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_exterior_designer',
      'title': 'Exterior Design',
      'category': 'Exterior Design',
      'icon': LucideIcons.layers,
      'desc': 'Modern elevation & landscape visualization',
      'imageUrl': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_vastu',
      'title': 'Vastu Consultancy',
      'category': 'Vastu Consultancy',
      'icon': LucideIcons.compass,
      'desc': 'Scientific Vastu energy assessment & remedies',
      'imageUrl': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_document_verification',
      'title': 'Document Verification',
      'category': 'Legal & Title',
      'icon': LucideIcons.fileCheck,
      'desc': '30-year registry title search & RERA compliance audit',
      'imageUrl': 'https://images.unsplash.com/photo-1450133064473-71024230f91b?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_loan_consultancy',
      'title': 'Loan Consultancy',
      'category': 'Finance',
      'icon': LucideIcons.indianRupee,
      'desc': 'Doorstep banking & lowest EMI rate comparison',
      'imageUrl': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_construction_estimator',
      'title': 'Construction Support',
      'category': 'Engineering',
      'icon': LucideIcons.hammer,
      'desc': 'Certified civil engineering supervision & material BOQ',
      'imageUrl': 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=600&q=80',
    },
    {
      'id': 'ai_3d_visualization',
      'title': '3D Visualization',
      'category': 'Visualization',
      'icon': LucideIcons.box,
      'desc': 'Interactive 3D model & AR walkthrough staging',
      'imageUrl': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _executeSearch() {
    final q = _searchController.text.trim();
    _stateService.updateFilter((f) {
      f.reset();
      if (_selectedSearchTab == 'Commercial') f.propertyType = 'Commercial';
      if (_selectedSearchTab == 'PG/Co-living') f.propertyType = 'PG/Co-living';
      if (_selectedPropType != 'Property Type') f.propertyType = _selectedPropType;

      if (_selectedBudget == 'Under ₹50L') f.maxPriceCr = 0.50;
      if (_selectedBudget == '₹50L - ₹1 Cr') {
        f.minPriceCr = 0.50;
        f.maxPriceCr = 1.00;
      }
      if (_selectedBudget == '₹1 Cr - ₹2 Cr') {
        f.minPriceCr = 1.00;
        f.maxPriceCr = 2.00;
      }
      if (_selectedBudget == '₹2 Cr - ₹5 Cr') {
        f.minPriceCr = 2.00;
        f.maxPriceCr = 5.00;
      }
      if (_selectedBudget == '₹5 Cr+') f.minPriceCr = 5.00;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PropertySearchScreen(
          initialQuery: q,
          propertyType: _selectedPropType != 'Property Type' ? _selectedPropType : null,
          category: _selectedSearchTab != 'Buy' ? _selectedSearchTab : null,
        ),
      ),
    );
  }

  void _handleSmartCategoryClick(Map<String, dynamic> cat) {
    final type = cat['type'] as String;
    final value = cat['value'];
    final label = cat['label'] as String;

    if (type == 'bhk') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PropertySearchScreen(
            initialQuery: '$value BHK',
            title: '$label Properties',
          ),
        ),
      );
    } else if (type == 'propertyType') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PropertySearchScreen(
            propertyType: value as String,
            title: label,
          ),
        ),
      );
    } else if (type == 'availability') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PropertySearchScreen(
            initialQuery: value as String,
            title: label,
          ),
        ),
      );
    } else if (type == 'location') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PropertySearchScreen(
            initialQuery: value as String,
            title: 'Properties in $label',
          ),
        ),
      );
    }
  }

  void _handleAiFeatureClick(String id) {
    switch (id) {
      case 'ai_advisor':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const AiAdvisorChatScreen()),
        );
        break;
      case 'ai_voice_agent':
        PropzenVoiceAgentModal.show(context);
        break;
      case 'ai_matching':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const FindMyPerfectPropertyScreen()),
        );
        break;
      case 'ai_listing_creator':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const AiListingCreatorScreen()),
        );
        break;
      case 'ai_lead_scoring':
        if (widget.onNavigateTab != null) {
          widget.onNavigateTab!(12); // Dealer Portal tab
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const DealerDashboardScreen()),
          );
        }
        break;
      case 'ai_verification':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const AiToolDetailScreen(toolType: 'ai_document_verification'),
          ),
        );
        break;
    }
  }

  List<Property> get _filteredFeaturedProperties {
    var list = _stateService.allProperties;
    if (_selectedFeaturedTab == 'New Launch') {
      return list.where((p) => p.statusTag == 'New Launch').toList();
    } else if (_selectedFeaturedTab == 'Ready to Move') {
      return list.where((p) => p.availability.toLowerCase().contains('ready')).toList();
    } else if (_selectedFeaturedTab == 'Price Drop') {
      return list.where((p) => p.statusTag == 'Price Drop' || (p.discountPercent != null && p.discountPercent! > 0)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return AnimatedBuilder(
      animation: _stateService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          body: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ResponsiveLayout.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. HERO SECTION
                    // ==========================================
                    _buildHeroSection(isDesktop, isTablet),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 1.5. DEALER PORTAL ENTRY CARD (STRICTLY FOR DEALER)
                    // ==========================================
                    ValueListenableBuilder<String>(
                      valueListenable: UserSession.roleTierNotifier,
                      builder: (ctx, _, __) {
                        if (!UserSession.isDealer) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildDealerPortalHomeCard(context, isDesktop, isTablet),
                        );
                      },
                    ),

                    // ==========================================
                    // 2. AI PROPERTY ADVISOR CARD
                    // ==========================================
                    _buildAiPropertyAdvisorCard(isDesktop, isTablet),

                    const SizedBox(height: 36),

                    // ==========================================
                    // 3. FEATURED PROPERTIES SECTION
                    // ==========================================
                    _buildFeaturedPropertiesSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 4. SMART PROPERTY DISCOVERY ("Explore Properties Your Way")
                    // ==========================================
                    _buildSmartDiscoverySection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 4.5. NOT BUYING A PROPERTY RIGHT NOW? SECTION
                    // ==========================================
                    _buildNotBuyingRightNowSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 5. WHY PROPZEN TRUST SECTION
                    // ==========================================
                    _buildWhyChoosePropZenSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 6. POWERED BY PROPZEN AI
                    // ==========================================
                    _buildPoweredByAiSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 7. PROPZEN SERVICE HUB
                    // ==========================================
                    _buildServiceHubSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 8. HOW PROPZEN WORKS (4-Step Visual Flow)
                    // ==========================================
                    _buildHowPropZenWorksSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 9. LOCALITY INTELLIGENCE ("Know Your Locality")
                    // ==========================================
                    _buildLocalityIntelligenceSection(isDesktop, isTablet),

                    const SizedBox(height: 40),

                    // ==========================================
                    // 10. FINAL CTA & FOOTER
                    // ==========================================
                    _buildFinalCtaSection(isDesktop, isTablet),

                    _buildFooter(isDesktop, isTablet),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // SECTION BUILDERS
  // =========================================================================

  /// 1. HERO SECTION
  Widget _buildHeroSection(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1424),
        border: Border(bottom: BorderSide(color: Color(0xFF1E263D))),
      ),
      child: Stack(
        children: [
          // Background Architecture Visual
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(color: const Color(0xFF0F1424)),
            ),
          ),

          // Deep Dark Gradient Overlay for Supreme Contrast and Readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xF20A0D18),
                    Color(0xDF0A0D18),
                    Color(0x990A0D18),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // Hero Foreground Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 50 : (isTablet ? 28 : 18),
              vertical: isDesktop ? 44 : 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles, color: AppTheme.purpleLight, size: 13),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'AI-POWERED REAL ESTATE PLATFORM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: AppTheme.purpleLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main Heading
                Text(
                  'Find Your Perfect Property, Smarter.',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 42 : (isTablet ? 32 : 26),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.18,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                // Supporting Text
                Text(
                  'AI-powered property discovery, verification and site visits — all in one place.',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 16 : (isTablet ? 14 : 13),
                    color: const Color(0xFFCBD5E1),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 24),

                // CTAs Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Primary CTA: Find My Perfect Property
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const FindMyPerfectPropertyScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                      label: Text(
                        'Find My Perfect Property',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),

                    // Secondary CTA: Explore Properties
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const PropertySearchScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF94A3B8), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Explore Properties',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                    // Talk to PropZen AI Voice Agent Button
                    ElevatedButton.icon(
                      onPressed: () => PropzenVoiceAgentModal.show(context),
                      icon: const Icon(LucideIcons.mic, size: 16, color: Colors.white),
                      label: Text(
                        'Talk to PropZen AI',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Search & Filter Box
                _buildSearchFilterBox(isDesktop, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Search Filter Box inside Hero Section
  Widget _buildSearchFilterBox(bool isDesktop, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Tabs: Buy, Rent, PG/Co-living, Commercial
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Buy', 'Rent', 'PG/Co-living', 'Commercial'].map((tab) {
                  final isSel = _selectedSearchTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSearchTab = tab),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.primaryViolet.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isSel ? Border.all(color: AppTheme.primaryViolet) : null,
                        ),
                        child: Text(
                          tab,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? AppTheme.primaryViolet : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(color: AppTheme.borderLight, height: 16),

          // Search Inputs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: isDesktop
                ? Row(
                    children: [
                      // Location Text Field
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search by location, project or property type',
                            hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 13),
                            prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primaryViolet, size: 18),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _executeSearch(),
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppTheme.borderLight),
                      const SizedBox(width: 12),

                      // Property Type Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButton<String>(
                          value: _selectedPropType,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          underline: const SizedBox.shrink(),
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                          items: _propertyTypeDropdowns.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedPropType = val!),
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppTheme.borderLight),
                      const SizedBox(width: 12),

                      // Budget Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButton<String>(
                          value: _selectedBudget,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          underline: const SizedBox.shrink(),
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                          items: _budgetDropdowns.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedBudget = val!),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Search Action Button
                      ElevatedButton.icon(
                        onPressed: _executeSearch,
                        icon: const Icon(LucideIcons.search, size: 16, color: Colors.white),
                        label: Text(
                          'Search Properties',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by location, project or property type',
                          hintStyle: GoogleFonts.inter(color: AppTheme.textHint, fontSize: 13),
                          prefixIcon: const Icon(LucideIcons.search, color: AppTheme.primaryViolet, size: 18),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _executeSearch(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedPropType,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                underline: const SizedBox.shrink(),
                                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 12),
                                items: _propertyTypeDropdowns.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) => setState(() => _selectedPropType = val!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedBudget,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                underline: const SizedBox.shrink(),
                                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 12),
                                items: _budgetDropdowns.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (val) => setState(() => _selectedBudget = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _executeSearch,
                          icon: const Icon(LucideIcons.search, size: 16, color: Colors.white),
                          label: Text(
                            'Search Properties',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryViolet,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 2. AI PROPERTY ADVISOR CARD
  Widget _buildAiPropertyAdvisorCard(bool isDesktop, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 20),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 22 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFBF9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A7C3AED),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: isDesktop
            ? Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
                    ),
                    child: const Icon(LucideIcons.bot, color: AppTheme.primaryViolet, size: 26),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not sure what property is right for you?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tell PropZen your budget and preferences. Our AI will find the best matches for you.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const AiAdvisorChatScreen()),
                      );
                    },
                    icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                    label: Text(
                      'Ask AI Advisor',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.bot, color: AppTheme.primaryViolet, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Not sure what property is right for you?',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tell PropZen your budget and preferences. Our AI will find the best matches for you.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const AiAdvisorChatScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                      label: Text(
                        'Ask AI Advisor',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 3. FEATURED PROPERTIES SECTION
  Widget _buildFeaturedPropertiesSection(bool isDesktop, bool isTablet) {
    final properties = _filteredFeaturedProperties;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header & View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Properties',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Handpicked verified properties in prime NCR corridors',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const PropertySearchScreen(title: 'All Featured Properties')),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowRight, size: 14, color: AppTheme.primaryViolet),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'New Launch', 'Ready to Move', 'Price Drop'].map((tab) {
                final isSel = _selectedFeaturedTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSel,
                    selectedColor: AppTheme.primaryViolet,
                    backgroundColor: AppTheme.surfaceSubtle,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? Colors.white : AppTheme.textSecondary,
                    ),
                    onSelected: (_) => setState(() => _selectedFeaturedTab = tab),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 18),

          // Properties Grid / Skeletons
          if (properties.isEmpty) ...[
            EmptyStateView(
              title: 'No properties found',
              message: 'Try adjusting your filters or search keywords.',
              actionLabel: 'Clear Filters',
              onAction: () => setState(() => _selectedFeaturedTab = 'All'),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth >= 1100
                    ? 4
                    : (constraints.maxWidth >= 720 ? 2 : 1);
                final double aspectRatio = crossAxisCount == 4
                    ? 0.73
                    : (crossAxisCount == 2
                        ? 0.70
                        : (constraints.maxWidth < 360 ? 0.65 : 0.68));

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: properties.length,
                  itemBuilder: (ctx, i) {
                    final prop = properties[i];
                    return PropertyCard(property: prop);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 4. SMART PROPERTY DISCOVERY SECTION ("Explore Properties Your Way")
  Widget _buildSmartDiscoverySection(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Properties Your Way',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Quick-filter by bedroom configuration, property category and prime NCR locations.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _smartDiscoveryCategories.map((cat) {
              return InkWell(
                onTap: () => _handleSmartCategoryClick(cat),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: const [
                      BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat['icon'] as IconData, size: 16, color: AppTheme.primaryViolet),
                      const SizedBox(width: 8),
                      Text(
                        cat['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 4.5. NOT BUYING A PROPERTY RIGHT NOW? SECTION
  Widget _buildNotBuyingRightNowSection(bool isDesktop, bool isTablet) {
    final cards = [
      {
        'icon': LucideIcons.calculator,
        'color': const Color(0xFF7C3AED),
        'title': 'Home Loan EMI',
        'desc': 'Calculate your monthly EMI and interest schedule.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 0))),
      },
      {
        'icon': LucideIcons.shieldCheck,
        'color': const Color(0xFF2563EB),
        'title': 'Credit Score',
        'desc': 'Understand your credit readiness and loan health.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen())),
      },
      {
        'icon': LucideIcons.wallet,
        'color': const Color(0xFF10B981),
        'title': 'Home Budget',
        'desc': 'Know how much home you can comfortably afford.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 1))),
      },
      {
        'icon': LucideIcons.scale,
        'color': const Color(0xFF0D9488),
        'title': 'Rent vs Buy',
        'desc': 'Compare your options over a 10-year wealth outlook.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 2))),
      },
      {
        'icon': LucideIcons.mapPin,
        'color': const Color(0xFFF59E0B),
        'title': 'Explore Cities',
        'desc': 'Discover areas, connectivity, and average prices.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen())),
      },
      {
        'icon': LucideIcons.train,
        'color': const Color(0xFF6366F1),
        'title': 'Connectivity',
        'desc': 'Check metro, airport, and highway access corridors.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen())),
      },
      {
        'icon': LucideIcons.plane,
        'color': const Color(0xFFEC4899),
        'title': 'Explore Destinations',
        'desc': 'Discover premium places and weekend getaways.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen())),
      },
      {
        'icon': LucideIcons.barChart2,
        'color': const Color(0xFF8B5CF6),
        'title': 'Property Trends',
        'desc': 'Explore real-time market prices and demand trends.',
        'action': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketHubScreen())),
      },
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sparkles, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not buying a property right now?',
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 20 : 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'PropZen has useful tools for your money, home and lifestyle.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Grid of 8 interactive cards
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int columns = isDesktop ? 4 : (isTablet ? 2 : 1);
              final cardWidth = (width - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: cards.map((c) {
                  final icon = c['icon'] as IconData;
                  final color = c['color'] as Color;
                  final title = c['title'] as String;
                  final desc = c['desc'] as String;
                  final action = c['action'] as VoidCallback;

                  return InkWell(
                    onTap: action,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: cardWidth,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Explore Tool',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(LucideIcons.chevronRight, size: 13, color: color),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 5. WHY PROPZEN TRUST SECTION
  Widget _buildWhyChoosePropZenSection(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose PropZen?',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'A modern, intelligence-first real estate experience built on trust and verification.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth >= 1000
                  ? 4
                  : (constraints.maxWidth >= 600 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.8,
                ),
                itemCount: _whyChoosePropZenItems.length,
                itemBuilder: (ctx, i) {
                  final item = _whyChoosePropZenItems[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc'] as String,
                                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 6. POWERED BY PROPZEN AI
  Widget _buildPoweredByAiSection(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.sparkles, color: AppTheme.primaryViolet, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Powered by PropZen AI',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          Text(
            'Proprietary real estate AI tools engineered for buyers, investors and verified dealers.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth >= 1050
                  ? 3
                  : (constraints.maxWidth >= 650 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.9,
                ),
                itemCount: _aiFeatureCards.length,
                itemBuilder: (ctx, i) {
                  final tool = _aiFeatureCards[i];
                  return InkWell(
                    onTap: () => _handleAiFeatureClick(tool['id'] as String),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: AppTheme.subtleCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (tool['color'] as Color).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tool['title'] as String,
                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(LucideIcons.arrowUpRight, size: 14, color: AppTheme.textHint),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tool['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 7. PROPZEN SERVICE HUB
  Widget _buildServiceHubSection(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PropZen Service Hub',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'End-to-end verified real estate, design and legal services.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(13); // All Features & Services Hub
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => AllFeaturesScreen(onNavigateTab: widget.onNavigateTab)),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore All Services',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                      ),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowRight, size: 14, color: AppTheme.primaryViolet),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth >= 1000
                  ? 4
                  : (constraints.maxWidth >= 600 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: crossAxisCount == 1 ? 3.4 : 2.5,
                ),
                itemCount: _servicesHubItems.length,
                itemBuilder: (ctx, i) {
                  final s = _servicesHubItems[i];
                  return InkWell(
                    onTap: () {
                      final toolId = s['id'] as String?;
                      final registeredTool = toolId != null ? AiServiceRegistry.getById(toolId) : null;
                      if (registeredTool != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            settings: RouteSettings(name: registeredTool.routePath),
                            builder: (ctx) => AiToolDetailScreen(toolType: registeredTool.id),
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => ServiceDetailScreen(
                              title: s['title'] as String,
                              category: s['category'] as String? ?? 'SERVICES',
                              description: s['desc'] as String,
                              icon: s['icon'] as IconData,
                              accentColor: AppTheme.primaryViolet,
                              features: const ['Certified Specialist', 'Instant Callback', 'Zero Hidden Fees'],
                              startingPrice: 'Free Consultation',
                              estimatedTime: '24 Hours',
                              imageUrl: s['imageUrl'] as String? ??
                                  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=600&q=80',
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: AppTheme.subtleCardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s['icon'] as IconData, color: AppTheme.primaryViolet, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  s['title'] as String,
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  s['desc'] as String,
                                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.textHint),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 8. HOW PROPZEN WORKS (4-Step Visual Section)
  Widget _buildHowPropZenWorksSection(bool isDesktop, bool isTablet) {
    final steps = [
      {
        'num': '01',
        'title': 'Discover',
        'desc': 'Find properties matching your needs.',
        'icon': LucideIcons.search,
      },
      {
        'num': '02',
        'title': 'Verify',
        'desc': 'Review available property verification information.',
        'icon': LucideIcons.fileCheck2,
      },
      {
        'num': '03',
        'title': 'Visit',
        'desc': 'Schedule your site visit.',
        'icon': LucideIcons.calendarCheck,
      },
      {
        'num': '04',
        'title': 'Decide',
        'desc': 'Compare, negotiate and move forward.',
        'icon': LucideIcons.checkCheck,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How PropZen Works',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          Text(
            'Your transparent, 4-step path from search to ownership.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth >= 1000
                  ? 4
                  : (constraints.maxWidth >= 600 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.8,
                ),
                itemCount: steps.length,
                itemBuilder: (ctx, i) {
                  final step = steps[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              step['num'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryViolet,
                              ),
                            ),
                            Icon(step['icon'] as IconData, size: 18, color: const Color(0xFF64748B)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['title'] as String,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc'] as String,
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 9. LOCALITY INTELLIGENCE ("Know Your Locality")
  Widget _buildLocalityIntelligenceSection(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 24 : 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.subtleCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.mapPin, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Know Your Locality',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Understand the area around your property before you decide.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLocalityPill('Nearby Places', LucideIcons.navigation),
                _buildLocalityPill('Connectivity', LucideIcons.train),
                _buildLocalityPill('Local Amenities', LucideIcons.trees),
                _buildLocalityPill('Local Insights', LucideIcons.barChart2),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const NearMePropertiesScreen()),
                  );
                },
                icon: const Icon(LucideIcons.compass, size: 15, color: Colors.white),
                label: Text(
                  'Explore Locality',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalityPill(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  /// 10. FINAL CTA SECTION
  Widget _buildFinalCtaSection(bool isDesktop, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: EdgeInsets.all(isDesktop ? 32 : 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(color: Color(0x337C3AED), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Your Next Property Starts Here.',
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 26 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Discover smarter. Verify confidently. Visit easily.',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 14 : 12,
                color: const Color(0xFFE2E8F0),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const PropertySearchScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryViolet,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Explore Properties',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const AiAdvisorChatScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Talk to AI Advisor',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// FOOTER
  Widget _buildFooter(bool isDesktop, bool isTablet) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 40),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : (isTablet ? 30 : 20),
        vertical: 36,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1424),
        border: Border(top: BorderSide(color: Color(0xFF1E263D))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.home, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'PropZen',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'AI-Powered Real Estate Discovery & Intelligence Platform',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Admin Portal Link Button (Visible strictly for authorized admins)
          AnimatedBuilder(
            animation: Listenable.merge([
              UserSession.isLoggedInNotifier,
              UserSession.roleTierNotifier,
              UserSession.emailNotifier,
            ]),
            builder: (context, _) {
              final bool isAuthorizedAdmin = UserSession.isAdmin;
              if (!isAuthorizedAdmin) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      '🔐 PropZen Command Center / Admin Portal',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              );
            },
          ),
          Text(
            '© 2026 PropZen Technologies Inc. All rights reserved.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Designed & Developed by Sakshi Dubey',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDealerPortalHomeCard(BuildContext context, bool isDesktop, bool isTablet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF31104B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A7C3AED),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          final button = ElevatedButton.icon(
            onPressed: () {
              if (widget.onNavigateTab != null) {
                widget.onNavigateTab!(12);
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DealerDashboardScreen()),
                );
              }
            },
            icon: const Icon(LucideIcons.arrowRight, size: 16),
            label: Text(
              'Open Dealer Portal',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'AUTHORIZED DEALER',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PropZen Partner Desk',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC4B5FD), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dealer Portal',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage properties • High-intent Leads • Site Visits & Negotiation Rooms',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.briefcase, size: 22, color: Color(0xFFDDD6FE)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: details),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: button),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.briefcase, size: 28, color: Color(0xFFDDD6FE)),
              ),
              const SizedBox(width: 20),
              Expanded(child: details),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}
