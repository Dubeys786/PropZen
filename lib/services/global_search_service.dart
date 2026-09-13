import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/global_search_item.dart';
import '../routes/app_routes.dart';
import '../screens/user_profile_screen.dart';
import '../screens/dealers_directory_screen.dart';
import '../screens/market_hub_screen.dart';
import '../screens/property_search_screen.dart';
import '../screens/property_compare_screen.dart';
import '../screens/my_site_visits_screen.dart';
import '../screens/deal_room_screen.dart';
import '../screens/site_visit_booking_screen.dart';
import '../screens/my_propzen_dashboard_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/post_property_screen.dart';
import '../screens/dual_auth_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/ai_tool_detail_screen.dart';
import '../screens/new_launch_projects_screen.dart';
import '../screens/legal_hub_screen.dart';
import '../screens/public_property_verification_screen.dart';
import '../screens/drone_tour_subscription_screen.dart';
import '../screens/finance_tools_hub_screen.dart';
import '../screens/credit_score_center_screen.dart';
import '../screens/city_intelligence_hub_screen.dart';
import '../screens/explore_india_screen.dart';
import '../screens/property_tools_screen.dart';
import '../widgets/propzen_voice_agent_modal.dart';
import '../widgets/become_dealer_dialog.dart';
import '../screens/nearby_services_screen.dart';
import '../models/nearby_category_taxonomy.dart';
import 'search_storage.dart';

/// Centralized Search Engine for PropZen Navigation, Tools, Services & Features
class GlobalSearchService extends ChangeNotifier {
  GlobalSearchService._internal() {
    _initIndex();
    _loadRecentSearches();
  }

  static final GlobalSearchService instance = GlobalSearchService._internal();

  final List<GlobalSearchItem> _items = [];
  final List<String> _recentSearches = [];

  List<GlobalSearchItem> get allItems {
    final isAdmin = UserSession.isAdmin;
    final isDealer = UserSession.isDealer;
    return List.unmodifiable(_items.where((item) {
      if (item.id == 'command_center' && !isAdmin) return false;
      if (item.id == 'dealer_portal' && !isDealer) return false;
      return true;
    }));
  }
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  // ===========================================================================
  // RECENT SEARCHES PERSISTENCE & MANAGEMENT
  // ===========================================================================

  void _loadRecentSearches() {
    try {
      final stored = SearchStorage.loadRecentSearches();
      if (stored.isNotEmpty) {
        _recentSearches.addAll(stored);
      } else {
        // Default starter searches matching reference specs
        _recentSearches.addAll([
          'Home Loan',
          'AI Match',
          'Vastu Consultation',
          'Dealers Directory',
        ]);
        SearchStorage.saveRecentSearches(_recentSearches);
      }
    } catch (_) {
      _recentSearches.addAll([
        'Home Loan',
        'AI Match',
        'Vastu Consultation',
        'Dealers Directory',
      ]);
    }
  }

  void addRecentSearch(String term) {
    final cleaned = term.trim();
    if (cleaned.isEmpty) return;

    _recentSearches.removeWhere((item) => item.toLowerCase() == cleaned.toLowerCase());
    _recentSearches.insert(0, cleaned);

    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
    SearchStorage.saveRecentSearches(_recentSearches);
    notifyListeners();
  }

  void removeRecentSearch(String term) {
    _recentSearches.removeWhere((item) => item.toLowerCase() == term.toLowerCase());
    SearchStorage.saveRecentSearches(_recentSearches);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    SearchStorage.saveRecentSearches(_recentSearches);
    notifyListeners();
  }

  // ===========================================================================
  // SEARCH EXECUTION & ROLE-AWARE RANKING
  // ===========================================================================

  List<GlobalSearchItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final isDealer = UserSession.isDealer;
    final isAdmin = UserSession.isAdmin;

    // Split multi-word queries for partial/broad matching
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    final scoredItems = <_ScoredItem>[];

    for (final item in _items) {
      // 1. Role-based security check: hide unauthorized items
      if (item.id == 'dealer_portal' && !isDealer) continue;
      if (item.id == 'command_center' && !isAdmin) continue;

      final titleLower = item.title.toLowerCase();
      final descLower = item.description.toLowerCase();
      final catLower = item.category.displayName.toLowerCase();

      int score = 0;

      // 1. Exact title match (highest score)
      if (titleLower == q) {
        score += 120;
      }
      // 2. Title starts with query
      else if (titleLower.startsWith(q)) {
        score += 80;
      }
      // 3. Title contains query
      else if (titleLower.contains(q)) {
        score += 45;
      }

      // 4. Keyword exact & prefix matches
      for (final kw in item.keywords) {
        final kwLower = kw.toLowerCase();
        if (kwLower == q) {
          score += 65;
        } else if (kwLower.startsWith(q)) {
          score += 35;
        } else if (kwLower.contains(q)) {
          score += 20;
        }
      }

      // 5. Multi-token match across title, keywords, or description
      if (tokens.length > 1) {
        bool allTokensMatch = true;
        for (final token in tokens) {
          final inTitle = titleLower.contains(token);
          final inDesc = descLower.contains(token);
          final inKeywords = item.keywords.any((k) => k.toLowerCase().contains(token));
          if (!inTitle && !inDesc && !inKeywords) {
            allTokensMatch = false;
            break;
          }
        }
        if (allTokensMatch) {
          score += 40;
        }
      }

      // 6. Category match
      if (catLower.contains(q)) {
        score += 20;
      }

      // 7. Description match
      if (descLower.contains(q)) {
        score += 10;
      }

      if (score > 0) {
        scoredItems.add(_ScoredItem(item: item, score: score));
      }
    }

    // Sort descending by relevance score
    scoredItems.sort((a, b) => b.score.compareTo(a.score));

    return scoredItems.map((e) => e.item).toList();
  }

  // ===========================================================================
  // CURATED CATEGORY GETTERS FOR EMPTY-QUERY STATE (4 COLUMNS)
  // ===========================================================================

  /// Column 1: Popular Searches
  List<GlobalSearchItem> get popularSearchItems => _getItemsByIds([
        'popular_properties',
        'my_dashboard',
        'home_loan',
        'ai_match',
        'site_visits',
        'dealers_directory',
        'market_hub',
        'popular_compare',
      ]);

  /// Column 2: Quick Access
  List<GlobalSearchItem> get quickAccessItems => _getItemsByIds([
        'my_dashboard',
        'profile',
        'saved_properties',
        'compare_properties',
        'site_visits',
        'my_deals',
      ]);

  /// Column 3: Services
  List<GlobalSearchItem> get serviceItems => _getItemsByIds([
        'home_loan',
        'property_loan',
        'vastu_consultation',
        'interior_design',
        'exterior_design',
        'property_verification',
        'legal_verification',
        'drone_tour',
      ]);

  /// Column 4: Discover
  List<GlobalSearchItem> get discoverItems => _getItemsByIds([
        'upcoming_projects',
        'hot_deals',
        'verified_properties',
        'services_hub',
        'blog_insights',
        'become_dealer',
      ]);

  List<GlobalSearchItem> _getItemsByIds(List<String> ids) {
    final result = <GlobalSearchItem>[];
    for (final id in ids) {
      for (final item in _items) {
        if (item.id == id) {
          result.add(item);
          break;
        }
      }
    }
    return result;
  }

  // ===========================================================================
  // MASTER SEARCH INDEX REGISTRATION
  // ===========================================================================

  void _initIndex() {
    _items.clear();
    _items.addAll([
      // -----------------------------------------------------------------------
      // 1. POPULAR & CORE PROPERTY ITEMS
      // -----------------------------------------------------------------------
      const GlobalSearchItem(
        id: 'popular_properties',
        title: 'Properties',
        description: 'Buy, Rent & Invest',
        category: GlobalSearchCategory.property,
        keywords: ['property', 'properties', 'listings', 'buy', 'rent', 'invest', 'flats', 'apartments', 'villas', 'plots'],
        icon: LucideIcons.home,
        tabIndex: 1,
        route: AppRoutes.properties,
      ),

      const GlobalSearchItem(
        id: 'properties',
        title: 'Properties',
        description: 'Find verified properties, apartments, villas & plots in NCR',
        category: GlobalSearchCategory.property,
        keywords: ['property', 'properties', 'listings', 'buy', 'rent', 'invest', 'flats', 'apartments', 'villas'],
        icon: LucideIcons.building,
        tabIndex: 1,
        route: AppRoutes.properties,
      ),

      const GlobalSearchItem(
        id: 'home',
        title: 'Home',
        description: 'PropZen homepage, featured listings & smart discovery',
        category: GlobalSearchCategory.page,
        keywords: ['home', 'homepage', 'main', 'landing', 'start', 'propzen'],
        icon: LucideIcons.home,
        tabIndex: 0,
        route: AppRoutes.home,
      ),

      GlobalSearchItem(
        id: 'list_property',
        title: 'List Your Property',
        description: 'Post your flat, villa, or commercial property for free',
        category: GlobalSearchCategory.property,
        keywords: ['property', 'list property', 'list your property', 'post property', 'sell', 'rent out', 'owner listing'],
        icon: LucideIcons.plusCircle,
        badgeText: 'FREE',
        onNavigate: (ctx) => _openListPropertyGate(ctx),
      ),

      const GlobalSearchItem(
        id: 'saved_properties',
        title: 'Saved Properties',
        description: 'Wishlisted properties & shortlists',
        category: GlobalSearchCategory.account,
        keywords: ['saved', 'saved properties', 'property', 'wishlist', 'favorites', 'bookmarks', 'shortlist'],
        icon: LucideIcons.heart,
        accentColor: Color(0xFFEC4899),
        tabIndex: 5,
        route: AppRoutes.savedProperties,
      ),

      GlobalSearchItem(
        id: 'deals',
        title: 'Deals',
        description: 'Browse discounted & price-drop property deals',
        category: GlobalSearchCategory.feature,
        keywords: ['deal', 'deals', 'price drop', 'discount', 'offers', 'savings'],
        icon: LucideIcons.tag,
        accentColor: const Color(0xFFEF4444),
        onNavigate: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => const PropertySearchScreen(filterTag: 'Price Drop', title: 'Price Drop Deals'),
            ),
          );
        },
      ),

      GlobalSearchItem(
        id: 'hot_deals',
        title: 'Hot Deals',
        description: 'Exclusive price-drop alerts & distress property deals',
        category: GlobalSearchCategory.feature,
        keywords: ['deal', 'deals', 'hot deals', 'price drop', 'discount', 'offers', 'savings'],
        icon: LucideIcons.flame,
        accentColor: const Color(0xFFEF4444),
        onNavigate: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => const PropertySearchScreen(filterTag: 'Price Drop', title: 'Price Drop Deals'),
            ),
          );
        },
      ),

      GlobalSearchItem(
        id: 'my_deals',
        title: 'My Deals',
        description: 'Real-time property negotiations & private deal rooms',
        category: GlobalSearchCategory.account,
        keywords: ['deal', 'deals', 'my deals', 'deal room', 'negotiations', 'offers', 'transaction'],
        icon: LucideIcons.briefcase,
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const DealRoomScreen(dealRoomId: '')));
        },
      ),

      GlobalSearchItem(
        id: 'upcoming_projects',
        title: 'Upcoming Projects',
        description: 'Explore newly launched residential & commercial projects in NCR',
        category: GlobalSearchCategory.property,
        keywords: ['upcoming projects', 'new launch', 'projects', 'builder', 'pre launch', 'under construction'],
        icon: LucideIcons.sparkles,
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NewLaunchProjectsScreen()));
        },
      ),

      GlobalSearchItem(
        id: 'verified_properties',
        title: 'Verified Properties',
        description: 'Browse 100% legal & title-checked verified properties',
        category: GlobalSearchCategory.verification,
        keywords: ['verified properties', 'property', 'verified', 'safe', 'legal check', 'rera verified'],
        icon: LucideIcons.checkCircle2,
        accentColor: const Color(0xFF10B981),
        onNavigate: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => const PropertySearchScreen(filterTag: 'Verified', title: 'Verified Properties'),
            ),
          );
        },
      ),

      // -----------------------------------------------------------------------
      // 2. FINANCIAL & LOAN SERVICES
      // -----------------------------------------------------------------------
      GlobalSearchItem(
        id: 'home_loan',
        title: 'Home Loan',
        description: 'Get loan assistance',
        category: GlobalSearchCategory.financial,
        keywords: ['loan', 'home loan', 'housing loan', 'interest', 'banks', 'mortgage', 'finance', 'emi assistance'],
        icon: LucideIcons.indianRupee,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => _openAiTool(ctx, 'ai_loan_consultancy'),
      ),

      GlobalSearchItem(
        id: 'property_loan',
        title: 'Property Loan',
        description: 'Loan against property & LAP',
        category: GlobalSearchCategory.financial,
        keywords: ['loan', 'property loan', 'loan against property', 'lap', 'commercial loan', 'plot loan'],
        icon: LucideIcons.badgePercent,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => _openAiTool(ctx, 'ai_loan_consultancy'),
      ),

      GlobalSearchItem(
        id: 'loan_consultancy',
        title: 'Loan Consultancy',
        description: 'AI-assisted mortgage matching & documentation guidance',
        category: GlobalSearchCategory.financial,
        keywords: ['loan', 'loan consultancy', 'advisor', 'finance', 'eligibility', 'cibil', 'sanction'],
        icon: LucideIcons.calculator,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => _openAiTool(ctx, 'ai_loan_consultancy'),
      ),

      const GlobalSearchItem(
        id: 'emi_calculator',
        title: 'Home Loan EMI Calculator',
        description: 'Calculate monthly loan installments & amortization schedules',
        category: GlobalSearchCategory.financial,
        keywords: ['emi', 'home loan emi', 'loan calculator', 'calculator', 'interest rate', 'monthly installment', 'loan'],
        icon: LucideIcons.calculator,
        tabIndex: 8,
        route: AppRoutes.emiCalculator,
      ),

      GlobalSearchItem(
        id: 'home_affordability',
        title: 'Home Affordability Calculator',
        description: 'Know how much home you can comfortably afford based on income and savings',
        category: GlobalSearchCategory.financial,
        keywords: ['budget', 'home budget', 'affordability', 'home affordability', 'calculator', 'eligibility', 'loan eligibility'],
        icon: LucideIcons.wallet,
        accentColor: const Color(0xFF10B981),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 1))),
      ),

      GlobalSearchItem(
        id: 'home_loan_readiness',
        title: 'Home Loan Readiness',
        description: 'Assess debt-to-income and savings readiness for a home loan',
        category: GlobalSearchCategory.financial,
        keywords: ['loan', 'readiness', 'loan readiness', 'are you ready for a home loan', 'credit readiness', 'eligibility'],
        icon: LucideIcons.checkCircle2,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen())),
      ),

      GlobalSearchItem(
        id: 'credit_score_center',
        title: 'Credit Score Center',
        description: 'Credit score ranges, factors, and mortgage readiness education',
        category: GlobalSearchCategory.financial,
        keywords: ['credit', 'credit score', 'cibil', 'credit health', 'credit score center', 'credit report'],
        icon: LucideIcons.shieldCheck,
        accentColor: const Color(0xFF2563EB),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen())),
      ),

      GlobalSearchItem(
        id: 'rent_vs_buy',
        title: 'Rent vs Buy Calculator',
        description: 'Compare 10-year wealth outcomes between renting and buying a home',
        category: GlobalSearchCategory.financial,
        keywords: ['rent', 'rent vs buy', 'buy vs rent', 'compare rent', 'calculator', 'rental vs ownership'],
        icon: LucideIcons.scale,
        accentColor: const Color(0xFF0D9488),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 2))),
      ),

      GlobalSearchItem(
        id: 'stamp_duty_calculator',
        title: 'Stamp Duty Calculator',
        description: 'Government registry charges & stamp duty verified by state departments',
        category: GlobalSearchCategory.financial,
        keywords: ['stamp duty', 'stamp', 'registration', 'registry', 'government charges', 'calculator'],
        icon: LucideIcons.receipt,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 3))),
      ),

      GlobalSearchItem(
        id: 'property_roi',
        title: 'Property ROI Calculator',
        description: 'Estimate rental yields, capital gains, and investment returns',
        category: GlobalSearchCategory.financial,
        keywords: ['roi', 'property roi', 'return on investment', 'rental yield', 'calculator', 'yield'],
        icon: LucideIcons.trendingUp,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen(initialTabIndex: 4))),
      ),

      GlobalSearchItem(
        id: 'interior_cost_calculator',
        title: 'Interior Cost Calculator',
        description: 'Calculate modular kitchen, woodwork, and turnkey interior budgets',
        category: GlobalSearchCategory.feature,
        keywords: ['interior', 'interior cost', 'interior calculator', 'home design', 'renovation', 'modular kitchen', 'woodwork'],
        icon: LucideIcons.palette,
        accentColor: const Color(0xFFEC4899),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 0))),
      ),

      GlobalSearchItem(
        id: 'renovation_calculator',
        title: 'Renovation Cost Calculator',
        description: 'Estimate tiling, civil work, bathroom overhaul, and painting budgets',
        category: GlobalSearchCategory.feature,
        keywords: ['renovation', 'renovation calculator', 'remodel', 'civil work', 'repairs'],
        icon: LucideIcons.wrench,
        accentColor: const Color(0xFF6366F1),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 1))),
      ),

      GlobalSearchItem(
        id: 'vastu_tool',
        title: 'Vastu Tool',
        description: 'Traditional educational guidance on directions and room placements',
        category: GlobalSearchCategory.feature,
        keywords: ['vastu', 'vastu tool', 'vastu shastra', 'direction', 'traditional vastu'],
        icon: LucideIcons.compass,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 2))),
      ),

      GlobalSearchItem(
        id: 'document_checklist',
        title: 'Property Document Checklist',
        description: 'Essential legal document checklists for buyers, sellers, dealers & builders',
        category: GlobalSearchCategory.verification,
        keywords: ['checklist', 'document checklist', 'property documents', 'legal documents', 'title deed'],
        icon: LucideIcons.listChecks,
        accentColor: const Color(0xFF10B981),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PropertyToolsScreen(initialTabIndex: 3))),
      ),

      GlobalSearchItem(
        id: 'city_intelligence',
        title: 'Noida City Intelligence',
        description: 'Explore Noida price trends, sectors, rental yields, and metro connectivity',
        category: GlobalSearchCategory.feature,
        keywords: ['noida', 'city', 'city intelligence', 'gurgaon', 'delhi', 'bangalore', 'mumbai', 'hyderabad', 'jaipur', 'greater noida'],
        icon: LucideIcons.building,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen())),
      ),

      GlobalSearchItem(
        id: 'connectivity_explorer',
        title: 'Connectivity Explorer',
        description: 'Check metro, airport, expressways, and highway connectivity for any area',
        category: GlobalSearchCategory.feature,
        keywords: ['metro', 'connectivity', 'connectivity explorer', 'airport', 'expressway', 'transit', 'railway'],
        icon: LucideIcons.train,
        accentColor: const Color(0xFF2563EB),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen())),
      ),

      GlobalSearchItem(
        id: 'commute_calculator',
        title: 'Commute Calculator',
        description: 'Estimate commute duration, distance, and transit options to your workplace',
        category: GlobalSearchCategory.feature,
        keywords: ['commute', 'commute calculator', 'travel time', 'distance', 'transit'],
        icon: LucideIcons.clock,
        accentColor: const Color(0xFF0D9488),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen())),
      ),

      GlobalSearchItem(
        id: 'future_infrastructure',
        title: 'Future Infrastructure',
        description: 'Upcoming Jewar Airport, expressways, metro extensions, and RRTS projects',
        category: GlobalSearchCategory.feature,
        keywords: ['infrastructure', 'upcoming infrastructure', 'future infrastructure', 'jewar', 'expressways', 'projects'],
        icon: LucideIcons.construction,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen())),
      ),

      // -----------------------------------------------------------------------
      // EXACT CATEGORY SEARCH INTENTS (STRICT FILTERING & INTENT ROUTING)
      // -----------------------------------------------------------------------
      GlobalSearchItem(
        id: 'schools_nearby',
        title: 'Schools Nearby',
        description: 'Strict search for primary, CBSE, IB & international schools',
        category: GlobalSearchCategory.service,
        keywords: ['school', 'schools', 'schools nearby', 'schools near me', 'nearby schools', 'best schools near this property', 'school around this property', 'cbse schools'],
        icon: LucideIcons.graduationCap,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.school))),
      ),

      GlobalSearchItem(
        id: 'hospitals_nearby',
        title: 'Hospitals Nearby',
        description: 'Strict search for multi-speciality tertiary care hospitals',
        category: GlobalSearchCategory.service,
        keywords: ['hospital', 'hospitals', 'hospitals nearby', 'hospitals near me', 'nearby hospitals', 'emergency healthcare'],
        icon: LucideIcons.heartPulse,
        accentColor: const Color(0xFFEF4444),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.hospital))),
      ),

      GlobalSearchItem(
        id: 'restaurants_nearby',
        title: 'Restaurants Nearby',
        description: 'Strict search for restaurants & family eateries',
        category: GlobalSearchCategory.service,
        keywords: ['restaurant', 'restaurants', 'restaurants nearby', 'restaurants near me', 'food nearby', 'dining'],
        icon: LucideIcons.utensils,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.restaurant))),
      ),

      GlobalSearchItem(
        id: 'metro_nearby',
        title: 'Metro Stations',
        description: 'Strict search for NMRC Aqua Line & DMRC Blue Line metro stations',
        category: GlobalSearchCategory.service,
        keywords: ['metro', 'metro station', 'metro stations', 'metro nearby', 'metro connectivity', 'subway'],
        icon: LucideIcons.train,
        accentColor: const Color(0xFF2563EB),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.metroStation))),
      ),

      GlobalSearchItem(
        id: 'tourist_places_nearby',
        title: 'Tourist Places',
        description: 'Strict search for tourist attractions, parks & monuments',
        category: GlobalSearchCategory.service,
        keywords: ['tourist', 'tourist places', 'tourist places nearby', 'tourist spots', 'attractions'],
        icon: LucideIcons.compass,
        accentColor: const Color(0xFF0D9488),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.touristAttraction))),
      ),

      GlobalSearchItem(
        id: 'malls_nearby',
        title: 'Shopping Malls',
        description: 'Strict search for shopping malls & highstreet retail centers',
        category: GlobalSearchCategory.service,
        keywords: ['mall', 'malls', 'shopping mall', 'shopping malls', 'malls nearby', 'markets'],
        icon: LucideIcons.shoppingBag,
        accentColor: const Color(0xFFEC4899),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.mall))),
      ),

      GlobalSearchItem(
        id: 'petrol_pumps_nearby',
        title: 'Petrol Pumps',
        description: 'Strict search for 24/7 petrol pumps & EV charging stations',
        category: GlobalSearchCategory.service,
        keywords: ['petrol pump', 'petrol pumps', 'petrol pumps nearby', 'petrol pump near me', 'fuel station', 'ev charging'],
        icon: LucideIcons.fuel,
        accentColor: const Color(0xFF10B981),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.petrolPump))),
      ),

      GlobalSearchItem(
        id: 'banks_nearby',
        title: 'Banks',
        description: 'Strict search for commercial bank branches',
        category: GlobalSearchCategory.service,
        keywords: ['bank', 'banks', 'banks nearby', 'bank near me'],
        icon: LucideIcons.landmark,
        accentColor: const Color(0xFF2563EB),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.bank))),
      ),

      GlobalSearchItem(
        id: 'atms_nearby',
        title: 'ATMs',
        description: 'Strict search for 24/7 ATM kiosks',
        category: GlobalSearchCategory.service,
        keywords: ['atm', 'atms', 'atms nearby', 'atm near me'],
        icon: LucideIcons.creditCard,
        accentColor: const Color(0xFF6366F1),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.atm))),
      ),

      GlobalSearchItem(
        id: 'gyms_nearby',
        title: 'Gyms & Fitness',
        description: 'Strict search for gymnasiums & fitness clubs',
        category: GlobalSearchCategory.service,
        keywords: ['gym', 'gyms', 'gyms nearby', 'gym near me', 'fitness centre'],
        icon: LucideIcons.dumbbell,
        accentColor: const Color(0xFF8B5CF6),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const NearbyServicesScreen(initialCategory: NearbyCategoryTaxonomy.gym))),
      ),

      GlobalSearchItem(
        id: 'explore_india_goa',
        title: 'Goa Destination Guide',
        description: 'Explore Goa beaches, heritage Latin Quarter, itineraries, and travel costs',
        category: GlobalSearchCategory.feature,
        keywords: ['goa', 'explore india', 'destinations', 'travel', 'vacation', 'beach', 'weekend getaways'],
        icon: LucideIcons.palmtree,
        accentColor: const Color(0xFF0D9488),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen())),
      ),

      GlobalSearchItem(
        id: 'weekend_getaways',
        title: 'Weekend Getaways',
        description: 'Short scenic escapes within 2 to 6 hours drive from your city',
        category: GlobalSearchCategory.feature,
        keywords: ['weekend', 'weekend getaways', 'trips', 'road trip', 'travel', 'holiday'],
        icon: LucideIcons.sun,
        accentColor: const Color(0xFFF59E0B),
        onNavigate: (ctx) => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const ExploreIndiaScreen())),
      ),

      // -----------------------------------------------------------------------
      // 3. AI & DESIGN SERVICES
      // -----------------------------------------------------------------------
      const GlobalSearchItem(
        id: 'ai_match',
        title: 'AI Match',
        description: 'Find perfect properties',
        category: GlobalSearchCategory.feature,
        keywords: ['ai', 'ai match', 'match', 'recommendation', 'lifestyle', 'assistant', 'smart match'],
        icon: LucideIcons.sparkles,
        accentColor: Color(0xFF7C3AED),
        badgeText: 'AI',
        tabIndex: 2,
        route: AppRoutes.aiAdvisor,
      ),

      GlobalSearchItem(
        id: 'talk_to_propzen_ai',
        title: 'Talk to PropZen AI',
        description: 'Interactive voice property search and conversational intelligence',
        category: GlobalSearchCategory.feature,
        keywords: ['ai', 'talk to propzen ai', 'voice agent', 'voice', 'speak', 'audio', 'chat with ai'],
        icon: LucideIcons.mic,
        accentColor: const Color(0xFF4F46E5),
        badgeText: 'VOICE',
        onNavigate: (ctx) => PropzenVoiceAgentModal.show(ctx),
      ),

      GlobalSearchItem(
        id: 'interior_design',
        title: 'Interior Design',
        description: 'Generative AI interior themes, furniture staging & color palettes',
        category: GlobalSearchCategory.service,
        keywords: ['interior', 'interior design', 'decor', 'furniture', 'living room', 'renovation', 'modular kitchen'],
        icon: LucideIcons.armchair,
        accentColor: const Color(0xFF8B5CF6),
        onNavigate: (ctx) => _openAiTool(ctx, 'ai_interior_designer'),
      ),

      GlobalSearchItem(
        id: 'exterior_design',
        title: 'Exterior Design',
        description: 'Modern villa facades, architectural elevations & landscaping',
        category: GlobalSearchCategory.service,
        keywords: ['exterior', 'exterior design', 'elevation', 'facade', 'villa design', 'balcony', 'architecture'],
        icon: LucideIcons.palette,
        accentColor: const Color(0xFF0EA5E9),
        onNavigate: (ctx) => _openAiTool(ctx, 'ai_exterior_designer'),
      ),

      GlobalSearchItem(
        id: 'vastu_consultation',
        title: 'Vastu Consultation',
        description: 'Vastu compliance score, direction orientation & remedies',
        category: GlobalSearchCategory.service,
        keywords: ['vastu', 'vastu consultation', 'vastu shastra', 'compass', 'direction', 'north east', 'energy'],
        icon: LucideIcons.compass,
        accentColor: const Color(0xFFD97706),
        onNavigate: (ctx) => _openAiTool(ctx, 'ai_vastu'),
      ),

      GlobalSearchItem(
        id: 'drone_tour',
        title: 'Drone Tour',
        description: '4K Ultra-HD aerial drone flyovers & neighborhood inspection',
        category: GlobalSearchCategory.service,
        keywords: ['drone', 'drone tour', 'aerial', '4k video', 'skyview', 'flyover', 'neighborhood'],
        icon: LucideIcons.camera,
        accentColor: const Color(0xFFEC4899),
        badgeText: '4K HD',
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const DroneTourSubscriptionScreen()));
        },
      ),

      // -----------------------------------------------------------------------
      // 4. VERIFICATION & LEGAL SERVICES
      // -----------------------------------------------------------------------
      GlobalSearchItem(
        id: 'property_verification',
        title: 'Property Verification',
        description: 'Public verification check, RERA authenticity & ownership status',
        category: GlobalSearchCategory.verification,
        keywords: ['verification', 'property', 'property verification', 'verify', 'rera check', 'owner title', 'encumbrance'],
        icon: LucideIcons.shieldCheck,
        accentColor: const Color(0xFF10B981),
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PublicPropertyVerificationScreen()));
        },
      ),

      GlobalSearchItem(
        id: 'legal_verification',
        title: 'Legal Verification',
        description: 'Comprehensive legal clearance desk, dispute check & lawyer audit',
        category: GlobalSearchCategory.verification,
        keywords: ['verification', 'legal', 'legal verification', 'lawyer', 'due diligence', 'title clearance', 'court dispute', 'legal opinion'],
        icon: LucideIcons.scale,
        accentColor: const Color(0xFF047857),
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const LegalHubScreen()));
        },
      ),

      GlobalSearchItem(
        id: 'blog_insights',
        title: 'Blog & Insights',
        description: 'Real estate market insights, articles & trends',
        category: GlobalSearchCategory.feature,
        keywords: ['blog', 'blog & insights', 'insights', 'articles', 'news', 'market analysis', 'expert opinion', 'read'],
        icon: LucideIcons.newspaper,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Blog & Insights: Latest market trends and news available in Market Hub.'),
              backgroundColor: Color(0xFF7C3AED),
            ),
          );
        },
      ),

      // -----------------------------------------------------------------------
      // 5. SITE VISITS & MARKET INTELLIGENCE (PRESERVED)
      // -----------------------------------------------------------------------
      GlobalSearchItem(
        id: 'site_visits',
        title: 'Site Visits',
        description: 'Schedule & manage visits',
        category: GlobalSearchCategory.feature,
        keywords: ['site', 'site visits', 'site visit', 'tours', 'schedule visit', 'property visit', 'booked visits'],
        icon: LucideIcons.calendarCheck,
        tabIndex: 3,
        route: AppRoutes.bookVisit,
        onNavigate: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (_) => MySiteVisitsScreen(onNavigateTab: (t) {}),
            ),
          );
        },
      ),

      GlobalSearchItem(
        id: 'book_site_visit',
        title: 'Book a Site Visit',
        description: 'Schedule a free guided site tour with a verified NCR expert',
        category: GlobalSearchCategory.feature,
        keywords: ['site', 'book a site visit', 'site visit', 'schedule visit', 'tour', 'inspect property'],
        icon: LucideIcons.calendarPlus,
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const SiteVisitBookingScreen()));
        },
      ),

      GlobalSearchItem(
        id: 'market_hub',
        title: 'Market Hub',
        description: 'Market insights & trends',
        category: GlobalSearchCategory.feature,
        keywords: ['market', 'market hub', 'market intelligence', 'trends', 'price index', 'analytics', 'noida rates', 'gurgaon rates'],
        icon: LucideIcons.trendingUp,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const MarketHubScreen()));
        },
      ),

      const GlobalSearchItem(
        id: 'popular_compare',
        title: 'Compare',
        description: 'Compare properties',
        category: GlobalSearchCategory.feature,
        keywords: ['compare', 'compare properties', 'comparison', 'side by side'],
        icon: LucideIcons.columns,
        tabIndex: 7,
        route: AppRoutes.compare,
        onNavigate: _navigateToCompare,
      ),

      const GlobalSearchItem(
        id: 'compare_properties',
        title: 'Compare Properties',
        description: 'Side-by-side comparison of prices, carpet area, Vastu & trust scores',
        category: GlobalSearchCategory.feature,
        keywords: ['compare', 'compare properties', 'comparison', 'side by side', 'price per sqft', 'amenities'],
        icon: LucideIcons.columns,
        tabIndex: 7,
        route: AppRoutes.compare,
        onNavigate: _navigateToCompare,
      ),

      const GlobalSearchItem(
        id: 'services_hub',
        title: 'Services Hub',
        description: 'All 12+ real estate AI tools, financial & legal services',
        category: GlobalSearchCategory.service,
        keywords: ['services', 'services hub', 'all features', 'tools', 'hub', 'all services'],
        icon: LucideIcons.layoutGrid,
        tabIndex: 13,
        route: AppRoutes.services,
      ),

      // -----------------------------------------------------------------------
      // 6. DEALERS & PARTNERS (ROLE-GUARDED)
      // -----------------------------------------------------------------------
      GlobalSearchItem(
        id: 'dealers_directory',
        title: 'Dealers Directory',
        description: 'Connect with dealers',
        category: GlobalSearchCategory.page,
        keywords: ['dealer', 'dealers', 'dealers directory', 'broker', 'agent', 'consultant', 'partners'],
        icon: LucideIcons.users,
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const DealersDirectoryScreen()));
        },
      ),

      GlobalSearchItem(
        id: 'become_dealer',
        title: 'Become a Dealer / Partner',
        description: 'Join PropZen broker network & unlock AI lead management tools',
        category: GlobalSearchCategory.account,
        keywords: ['dealer', 'become a dealer', 'become a partner', 'broker join', 'partner registration', 'agent network'],
        icon: LucideIcons.userPlus,
        accentColor: const Color(0xFF7C3AED),
        onNavigate: (ctx) => BecomeDealerDialog.show(ctx),
      ),

      GlobalSearchItem(
        id: 'dealer_portal',
        title: 'Dealer Portal',
        description: 'Exclusive portal for verified partners to manage inventory & leads',
        category: GlobalSearchCategory.account,
        keywords: ['dealer', 'dealer portal', 'dealer dashboard', 'broker portal', 'leads', 'client management'],
        icon: LucideIcons.layoutDashboard,
        badgeText: 'PORTAL',
        tabIndex: 12,
        route: AppRoutes.dealerDashboard,
        onNavigate: (ctx) {
          if (!UserSession.isDealer) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Access Denied: Dealer Portal is restricted to verified Partners & Dealers.'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
            return;
          }
          Navigator.of(ctx).pushNamed(AppRoutes.dealerDashboard);
        },
      ),

      // -----------------------------------------------------------------------
      // 7. USER ACCOUNT, DASHBOARD & ADMIN
      // -----------------------------------------------------------------------
      GlobalSearchItem(
        id: 'my_dashboard',
        title: 'Dashboard',
        description: 'View your overview',
        category: GlobalSearchCategory.account,
        keywords: ['dashboard', 'my dashboard', 'propzen dashboard', 'overview', 'activity'],
        icon: LucideIcons.layoutDashboard,
        onNavigate: (ctx) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const MyPropzenDashboardScreen()));
        },
      ),

      const GlobalSearchItem(
        id: 'profile',
        title: 'My Profile',
        description: 'Account settings, verified badge, residency & subscription status',
        category: GlobalSearchCategory.account,
        keywords: ['dashboard', 'profile', 'my profile', 'account', 'user profile', 'settings', 'subscription', 'nri status'],
        icon: LucideIcons.user,
        tabIndex: 4,
        route: AppRoutes.profile,
      ),

      const GlobalSearchItem(
        id: 'notifications',
        title: 'Notifications',
        description: 'Price drop alerts, visit reminders & transaction updates',
        category: GlobalSearchCategory.account,
        keywords: ['notifications', 'alerts', 'messages', 'updates', 'bell'],
        icon: LucideIcons.bell,
        tabIndex: 6,
        route: AppRoutes.notifications,
      ),

      GlobalSearchItem(
        id: 'command_center',
        title: 'Command Center',
        description: 'Super admin moderation desk, audit log & backend controls',
        category: GlobalSearchCategory.account,
        keywords: ['admin', 'command center', 'super admin', 'moderation', 'audit log'],
        icon: LucideIcons.shieldAlert,
        accentColor: const Color(0xFFDC2626),
        badgeText: 'ADMIN',
        onNavigate: (ctx) {
          if (!UserSession.isAdmin) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Access Denied: Command Center is restricted to authorized Administrators.'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
            return;
          }
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
        },
      ),
    ]);
  }

  static void _navigateToCompare(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PropertyCompareScreen()));
  }

  // Helper to open AI tool details cleanly
  void _openAiTool(BuildContext context, String toolId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiToolDetailScreen(toolType: toolId),
      ),
    );
  }

  // Helper to trigger authenticated list property gate
  void _openListPropertyGate(BuildContext context) {
    if (!UserSession.isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const DualAuthScreen(redirectRoute: AppRoutes.listProperty),
        ),
      );
      return;
    }

    if (!UserSession.isEmailVerified) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => EmailVerificationGateScreen(
            redirectRoute: AppRoutes.listProperty,
            onVerified: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (ctx2) => PostPropertyScreen(onNavigateTab: (t) => Navigator.of(ctx2).pop()),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PostPropertyScreen(onNavigateTab: (t) => Navigator.of(ctx).pop()),
      ),
    );
  }
}

class _ScoredItem {
  final GlobalSearchItem item;
  final int score;

  const _ScoredItem({required this.item, required this.score});
}
