import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/ai_service_tool_data.dart';
import '../screens/main_shell.dart';
import '../screens/property_search_screen.dart';
import '../screens/property_details_screen.dart';
import '../screens/property_ar_screen.dart';
import '../screens/dynamic_filter_screen.dart';
import '../screens/ai_advisor_chat_screen.dart';
import '../screens/all_features_screen.dart';
import '../screens/my_enquiries_screen.dart';
import '../screens/site_visit_booking_screen.dart';
import '../screens/wishlist_screen.dart';
import '../screens/property_compare_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/emi_calculator_screen.dart';
import '../screens/dealers_directory_screen.dart';
import '../screens/market_hub_screen.dart';
import '../screens/about_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/dual_auth_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/dealer_dashboard_screen.dart';
import '../screens/finance_tools_hub_screen.dart';
import '../screens/credit_score_center_screen.dart';
import '../screens/city_intelligence_hub_screen.dart';
import '../screens/explore_india_screen.dart';
import '../screens/property_tools_screen.dart';
import '../screens/dealer_properties_screen.dart';
import '../screens/post_property_screen.dart';
import '../screens/dealer_leads_screen.dart';
import '../screens/dealer_site_visits_screen.dart';
import '../screens/dealer_profile_screen.dart';
import '../screens/dealer_access_denied_screen.dart';
import '../screens/service_partner_portal_screen.dart';
import '../screens/service_partner_access_denied_screen.dart';
import '../screens/service_partners/loan_partner_dashboard.dart';
import '../screens/service_partners/home_design_partner_dashboard.dart';
import '../screens/service_partners/vastu_partner_dashboard.dart';
import '../screens/service_partners/construction_partner_dashboard.dart';
import '../screens/service_partners/property_verification_partner_dashboard.dart';
import '../screens/service_partners/virtual_3d_partner_dashboard.dart';
import '../screens/service_partners/select_service_portal_screen.dart';
import '../screens/service_partners/service_partner_status_screen.dart';
import '../widgets/service_partner_route_guard.dart';
import '../models/service_request_model.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/ai_tool_detail_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/ai_home_designer_landing_screen.dart';
import '../screens/ai_home_designer_wizard_screen.dart';
import '../screens/my_ai_designs_screen.dart';
import '../models/ai_home_project.dart';
import '../screens/buyer_requirements_screen.dart';
import '../screens/property_visit_planner_screen.dart';
import '../screens/ai_listing_creator_screen.dart';
import '../screens/deal_room_screen.dart';
import '../screens/negotiation_room_screen.dart';
import '../screens/site_visit_checklist_screen.dart';
import '../screens/loan_advisor_screen.dart';
import '../screens/loan_application_wizard_screen.dart';
import '../screens/design_studio_screen.dart';
import '../screens/reporter_feed_screen.dart';
import '../screens/reporter_studio_screen.dart';
import '../screens/super_dashboard_screen.dart';
import '../screens/vendor_wallet_dashboard_screen.dart';
import '../screens/nri_smart_valuation_screen.dart';
import '../screens/nri_ai_advisor_chat_screen.dart';
import '../screens/programmatic_seo_screen.dart';
import '../screens/area_discovery_screen.dart';
import '../screens/loan_comparison_screen.dart';
import '../screens/supplier_directory_screen.dart';
import '../screens/forum_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/nri_hub_screen.dart';
import '../screens/region_management_screen.dart';
import '../screens/construction_progress_screen.dart';
import '../screens/public_property_verification_screen.dart';
import '../screens/property_comparison_screen.dart';
import '../screens/my_propzen_dashboard_screen.dart';
import '../screens/nearby_services_screen.dart';
import '../services/property_state_service.dart';
import '../widgets/auth_gate.dart';
import '../widgets/admin_route_guard.dart';
import '../crm/widgets/crm_route_guard.dart';
import '../crm/widgets/crm_sidebar.dart';
import '../crm/screens/crm_shell_screen.dart';
import '../crm/screens/crm_lead_details_screen.dart';
import '../crm/screens/crm_customer_360_screen.dart';
import '../verification/screens/trust_engine_screen.dart';
import '../verification/models/trust_engine_models.dart';

class AppRoutes {
  static const String root = '/';
  static const String home = '/home';
  static const String properties = '/properties';
  static const String propertyDetails = '/property-details';
  static const String propertyAr = '/property-ar';
  static String propertyArRoute(String propertyId) => '/property/$propertyId/ar';
  static const String listProperty = '/list-property';
  static const String postProperty = '/post-property';
  static const String areaDiscovery = '/area-discovery';
  static const String nearbyServices = '/nearby-services';
  static const String loanComparison = '/loan-comparison';
  static const String constructionMarketplace = '/construction-marketplace';
  static const String forum = '/forum';
  static const String chat = '/chat';
  static const String nriHub = '/nri-hub';
  static const String regions = '/regions';
  static const String constructionProgress = '/construction-progress';
  static const String verifyProperty = '/verify-property';
  static const String trustEngine = '/trust-engine';
  static const String compareProperties = '/compare-properties';
  static const String myPropzen = '/my-propzen';
  static const String search = '/search';
  static const String filters = '/filters';
  static const String aiAdvisor = '/ai-advisor';
  static const String services = '/services';
  static const String deals = '/deals';
  static const String enquiry = '/enquiry';
  static const String bookVisit = '/book-visit';
  static const String savedProperties = '/saved-properties';
  static const String compare = '/compare';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String helpSupport = '/help-support';
  static const String emiCalculator = '/emi-calculator';
  static const String dealers = '/dealers';
  static const String marketHub = '/market-hub';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String aiTool = '/ai-tool';
  static const String locationPicker = '/location-picker';
  static const String aiHomeDesigner = '/ai-home-designer';
  static const String aiHomeDesignerWizard = '/ai-home-designer/wizard';
  static const String myAiDesigns = '/ai-home-designer/my-designs';

  // Dedicated AI Tool Named Routes
  static const String aiFloorPlan = '/ai-tools/floor-plan';
  static const String aiHomeDesignerTool = '/ai-tools/home-designer';
  static const String ai3dVisualization = '/ai-tools/3d-visualization';
  static const String aiFacadeDesigner = '/ai-tools/facade-designer';
  static const String aiInteriorDesigner = '/ai-tools/interior-designer';
  static const String aiExteriorDesigner = '/ai-tools/exterior-designer';
  static const String aiVastu = '/ai-tools/vastu';
  static const String aiDroneTour = '/ai-tools/drone-tour';
  static const String aiPropertyVideo = '/ai-tools/property-video';
  static const String aiDocumentVerification = '/ai-tools/document-verification';
  static const String aiLoanConsultancy = '/ai-tools/loan-consultancy';
  static const String aiPropertyComparison = '/ai-tools/property-comparison';
  static const String aiPropertyValuation = '/ai-tools/property-valuation';
  static const String aiPropertyRecommendation = '/ai-tools/property-recommendation';

  // Everyday Utility & Tools Routes
  static const String financeTools = '/finance-tools';
  static const String creditScoreCenter = '/credit-score';
  static const String cityIntelligence = '/city-intelligence';
  static const String exploreIndia = '/explore-india';
  static const String propertyTools = '/property-tools';

  // Distinct Role-Based Portal Routes
  static const String buyerDashboard = '/buyer-dashboard';
  static const String dealerPortal = '/dealer-portal';
  static const String servicePartnerPortal = '/service-partner-portal';
  static const String servicePartnerAccessDenied = '/service-partner/access-denied';

  // Completely Separate Service Partner Portals
  static const String loanPartnerPortal = '/service-partner/loan';
  static const String homeDesignPartnerPortal = '/service-partner/home-design';
  static const String vastuPartnerPortal = '/service-partner/vastu';
  static const String constructionPartnerPortal = '/service-partner/construction';
  static const String propertyVerificationPartnerPortal = '/service-partner/property-verification';
  static const String virtual3dPartnerPortal = '/service-partner/virtual-3d';
  static const String selectServicePortal = '/service-partner/select-portal';
  static const String servicePartnerStatus = '/service-partner/status';

  /// Helper to get route string by specialized service category
  static String getPartnerPortalRouteForCategory(ServiceCategoryType category) {
    switch (category) {
      case ServiceCategoryType.loan:
        return loanPartnerPortal;
      case ServiceCategoryType.homeDesign:
        return homeDesignPartnerPortal;
      case ServiceCategoryType.vastu:
        return vastuPartnerPortal;
      case ServiceCategoryType.construction:
        return constructionPartnerPortal;
      case ServiceCategoryType.propertyVerification:
        return propertyVerificationPartnerPortal;
      case ServiceCategoryType.visualization:
        return virtual3dPartnerPortal;
    }
  }

  /// Helper to build dedicated dashboard widget for specialized service category
  static Widget buildPartnerDashboardForCategory(ServiceCategoryType category) {
    switch (category) {
      case ServiceCategoryType.loan:
        return const LoanPartnerDashboard();
      case ServiceCategoryType.homeDesign:
        return const HomeDesignPartnerDashboard();
      case ServiceCategoryType.vastu:
        return const VastuPartnerDashboard();
      case ServiceCategoryType.construction:
        return const ConstructionPartnerDashboard();
      case ServiceCategoryType.propertyVerification:
        return const PropertyVerificationPartnerDashboard();
      case ServiceCategoryType.visualization:
        return const Virtual3DPartnerDashboard();
    }
  }

  // Dealer routes
  static const String dealerLogin = '/dealer/login';
  static const String dealerRegister = '/dealer/register';
  static const String dealerDashboard = '/dealer/dashboard';
  static const String dealerProperties = '/dealer/properties';
  static const String dealerAddProperty = '/dealer/add-property';
  static const String dealerLeads = '/dealer/leads';
  static const String dealerSiteVisits = '/dealer/site-visits';
  static const String dealerBookings = '/dealer/bookings';
  static const String dealerAnalytics = '/dealer/analytics';
  static const String dealerProfile = '/dealer/profile';
  static const String dealerSettings = '/dealer/settings';

  // Buyer & Dealer Ecosystem Routes
  static const String buyerRequirements = '/buyer-requirements';
  static const String visitPlanner = '/visit-planner';
  static const String aiListingCreator = '/ai-listing-creator';
  static const String dealRoom = '/deal-room';
  static const String negotiationRoom = '/negotiation-room';
  static const String siteVisitChecklist = '/site-visit-checklist';

  // Production Modules (Loan, Design, Reporter, Super Dashboard, Wallet, NRI Valuation, NRI AI Advisor)
  static const String loanAdvisor = '/loan-advisor';
  static const String loanApplication = '/loan-application';
  static const String designStudio = '/design-studio';
  static const String reporterFeed = '/reporter-feed';
  static const String reporterStudio = '/reporter-studio';
  static const String superDashboard = '/super-dashboard';
  static const String vendorWallet = '/vendor-wallet';
  static const String nriValuation = '/nri-valuation';
  static const String nriAiAdvisor = '/nri-ai-advisor';

  // Admin & Command Panel routes
  static const String admin = '/admin';
  static const String adminPanel = '/admin-panel';
  static const String adminDashboard = '/admin-dashboard';
  static const String commandCenter = '/command-center';
  static const String adminCommandCenter = '/admin-command-center';
  static const String adminPropertyVerification = '/admin/property-verification';
  static const String commandPanel = '/command-panel';
  static const String commandPanelCrm = '/command-panel/crm';
  static const String commandPanelCrmLeads = '/command-panel/crm/leads';
  static const String commandPanelCrmCustomers = '/command-panel/crm/customers';
  static const String commandPanelCrmFollowUps = '/command-panel/crm/follow-ups';
  static const String commandPanelCrmTasks = '/command-panel/crm/tasks';
  static const String commandPanelCrmProperties = '/command-panel/crm/properties';
  static const String commandPanelCrmSiteVisits = '/command-panel/crm/site-visits';
  static const String commandPanelCrmWhatsApp = '/command-panel/crm/whatsapp';
  static const String commandPanelCrmCampaigns = '/command-panel/crm/campaigns';
  static const String commandPanelCrmAnalytics = '/command-panel/crm/analytics';

  // Enterprise Standalone CRM Routes
  static const String crm = '/crm';
  static const String crmLeads = '/crm/leads';
  static const String crmFollowUps = '/crm/follow-ups';
  static const String crmTasks = '/crm/tasks';
  static const String crmCampaigns = '/crm/campaigns';
  static const String crmWhatsApp = '/crm/whatsapp';
  static const String crmProperties = '/crm/properties';
  static const String crmCustomers = '/crm/customers';
  static const String crmAnalytics = '/crm/analytics';

  /// Returns destination route string by authenticated role and specialization
  static String getPostLoginDestination() {
    if (UserSession.isAdmin) return admin;
    if (UserSession.isDealer) return dealerPortal;
    if (UserSession.isServicePartner) {
      final profile = UserSession.currentServicePartnerProfile;
      // If profile is missing, pending, suspended, or unapproved -> Status gate
      if (profile == null || !profile.isApproved || profile.isSuspended) {
        return servicePartnerStatus;
      }
      final approved = profile.approvedCategoryTypes;
      // Missing specialization -> Status gate (DO NOT default to Loan Partner!)
      if (approved.isEmpty) {
        return servicePartnerStatus;
      }
      // Multi-service approved partner -> Portal selector
      if (approved.length > 1) {
        return selectServicePortal;
      }
      // Single specialized approved partner -> Dedicated portal
      return getPartnerPortalRouteForCategory(approved.first);
    }
    return buyerDashboard;
  }

  /// Centralized Post-Login & Post-Signup Navigation Routing
  /// Routes strictly by backend authenticated role and specialization:
  /// - ADMIN -> /admin
  /// - DEALER -> /dealer-portal
  /// - SERVICE_PARTNER:
  ///     - Multiple approved services -> /service-partner/select-portal
  ///     - Single approved service -> /service-partner/<slug>
  /// - BUYER -> /buyer-dashboard
  static void navigateToPostLoginDestination(BuildContext context) {
    if (UserSession.isAdmin) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(settings: const RouteSettings(name: admin), builder: (_) => const AdminPanelScreen()),
        (route) => false,
      );
    } else if (UserSession.isDealer) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(settings: const RouteSettings(name: dealerPortal), builder: (_) => const DealerDashboardScreen()),
        (route) => false,
      );
    } else if (UserSession.isServicePartner) {
      final profile = UserSession.currentServicePartnerProfile;
      final approved = profile?.approvedCategoryTypes ?? [];
      if (profile == null || !profile.isApproved || profile.isSuspended || approved.isEmpty) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: servicePartnerStatus),
            builder: (_) => const ServicePartnerStatusScreen(),
          ),
          (route) => false,
        );
      } else if (approved.length > 1) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: const RouteSettings(name: selectServicePortal),
            builder: (_) => const SelectServicePortalScreen(),
          ),
          (route) => false,
        );
      } else {
        final category = approved.first;
        final targetRoute = getPartnerPortalRouteForCategory(category);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            settings: RouteSettings(name: targetRoute),
            builder: (_) => buildPartnerDashboardForCategory(category),
          ),
          (route) => false,
        );
      }
    } else {
      // Default: Buyer Dashboard (MainShell Tab 0)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(settings: const RouteSettings(name: buyerDashboard), builder: (_) => const MainShell(initialIndex: 0)),
        (route) => false,
      );
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // Handle dynamic /command-panel/crm/leads/:id route
    if (routeName.startsWith('/command-panel/crm/leads/')) {
      final leadId = routeName.replaceFirst('/command-panel/crm/leads/', '').trim();
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AdminRouteGuard(
          allowCrmRoles: true,
          child: AdminPanelScreen(
            initialNavIndex: 21,
            initialLeadId: leadId.isNotEmpty ? leadId : null,
          ),
        ),
      );
    }

    // Handle dynamic and dedicated /ai-tools/* routes
    if (routeName.startsWith('/ai-tools/')) {
      final slug = routeName.replaceFirst('/ai-tools/', '').trim();
      final tool = AiServiceRegistry.getBySlug(slug) ?? AiServiceRegistry.getById(slug);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AiToolDetailScreen(
          toolType: tool?.id ?? slug,
          title: tool?.title,
          category: tool?.primaryCategory,
          description: tool?.shortDescription,
          icon: tool?.icon,
          accentColor: tool?.accentColor,
        ),
      );
    }

    // Handle dedicated and dynamic Property AR routes (/property/:id/ar, /ar/:id, /property-ar)
    if ((routeName.startsWith('/property/') && (routeName.endsWith('/ar') || routeName.contains('/ar?'))) ||
        routeName.startsWith('/ar/') ||
        routeName == propertyAr) {
      Property? prop;
      String? propId;

      if (settings.arguments is Property) {
        prop = settings.arguments as Property;
        propId = prop.id;
      } else if (settings.arguments is String) {
        propId = settings.arguments as String;
      } else if (settings.arguments is Map) {
        final map = settings.arguments as Map;
        prop = map['property'] as Property?;
        propId = (map['id'] ?? map['propertyId'])?.toString();
      }

      if ((propId == null || propId.isEmpty) && prop == null) {
        final uri = Uri.tryParse(routeName);
        if (uri != null) {
          propId = uri.queryParameters['id'] ?? uri.queryParameters['propertyId'];
          if (propId == null && uri.pathSegments.length >= 2) {
            if (uri.pathSegments.first == 'property' && uri.pathSegments.length >= 3) {
              propId = uri.pathSegments[1];
            } else if (uri.pathSegments.first == 'ar' && uri.pathSegments.length >= 2) {
              propId = uri.pathSegments[1];
            }
          }
        }
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PropertyArScreen(property: prop, propertyId: propId),
      );
    }

    // Handle dynamic property details routes (/property-details, /property-details/:id, /property/:id)
    if (routeName.startsWith('/property-details') || routeName.startsWith('/property/')) {
      Property? prop;
      String? propId;

      if (settings.arguments is Property) {
        prop = settings.arguments as Property;
        propId = prop.id;
      } else if (settings.arguments is String) {
        propId = settings.arguments as String;
      } else if (settings.arguments is Map) {
        final map = settings.arguments as Map;
        prop = map['property'] as Property?;
        propId = (map['id'] ?? map['propertyId'])?.toString();
      }

      if ((propId == null || propId.isEmpty) && prop == null) {
        final uri = Uri.tryParse(routeName);
        if (uri != null) {
          propId = uri.queryParameters['id'] ?? uri.queryParameters['propertyId'];
          if (propId == null && uri.pathSegments.length >= 2) {
            propId = uri.pathSegments[1];
          }
        }
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PropertyDetailsScreen(property: prop, propertyId: propId),
      );
    }

    // Handle Programmatic SEO routes (/property-rates/*, /insights/*, /buy/*, /rent/*)
    if (routeName.startsWith('/property-rates') ||
        routeName.startsWith('/insights') ||
        routeName.startsWith('/buy/') ||
        routeName.startsWith('/rent/')) {
      final uri = Uri.tryParse(routeName) ?? Uri.parse('/property-rates/noida/sector-150');
      final segs = uri.pathSegments;

      String city = 'Noida';
      String location = 'Sector 150';
      String? propType;

      if (routeName.startsWith('/property-rates')) {
        if (segs.length >= 2) city = segs[1].replaceAll('-', ' ');
        if (segs.length >= 3) {
          location = segs[2].replaceAll('-', ' ');
        } else {
          location = city;
        }
      } else if (routeName.startsWith('/insights')) {
        if (segs.length >= 2) {
          location = segs[1].replaceAll('-property-rates-trends', '').replaceAll('-', ' ');
        }
      } else if (routeName.startsWith('/buy/') || routeName.startsWith('/rent/')) {
        if (segs.length >= 2) propType = segs[1].replaceAll('-', ' ');
        if (segs.length >= 3) city = segs[2].replaceAll('-', ' ');
        location = city;
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => ProgrammaticSeoScreen(
          location: location,
          city: city,
          propertyType: propType,
        ),
      );
    }

    if (routeName.startsWith('/verify/property/')) {
      final segs = Uri.parse(routeName).pathSegments;
      final propId = segs.length >= 3 ? segs[2] : null;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PublicPropertyVerificationScreen(propertyId: propId),
      );
    }

    // Handle dynamic CRM routes (/crm/leads/:id, /crm/customers/:id)
    if (routeName.startsWith('/crm/leads/') && routeName.length > '/crm/leads/'.length) {
      final leadId = routeName.replaceFirst('/crm/leads/', '').split('?').first;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => CrmRouteGuard(
          redirectRoute: routeName,
          builder: (_) => CrmLeadDetailsScreen(leadId: leadId),
        ),
      );
    }

    if (routeName.startsWith('/crm/customers/') && routeName.length > '/crm/customers/'.length) {
      final custId = routeName.replaceFirst('/crm/customers/', '').split('?').first;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => CrmRouteGuard(
          redirectRoute: routeName,
          builder: (_) => CrmCustomer360Screen(initialCustomerId: custId),
        ),
      );
    }

    switch (settings.name) {
      case root:
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0));
      case financeTools:
        return MaterialPageRoute(builder: (_) => const FinanceToolsHubScreen());
      case creditScoreCenter:
        return MaterialPageRoute(builder: (_) => const CreditScoreCenterScreen());
      case cityIntelligence:
        return MaterialPageRoute(builder: (_) => const CityIntelligenceHubScreen());
      case exploreIndia:
        return MaterialPageRoute(builder: (_) => const ExploreIndiaScreen());
      case nearbyServices:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => NearbyServicesScreen(
            initialCategory: args?['category'] as String? ?? 'school',
            sourceProperty: args?['property'] as Property?,
          ),
        );
      case propertyTools:
        return MaterialPageRoute(builder: (_) => const PropertyToolsScreen());
      case properties:
      case search:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PropertySearchScreen(
            initialQuery: args?['query'] as String?,
            title: args?['title'] as String?,
            filterTag: args?['tag'] as String?,
            propertyType: args?['type'] as String?,
            amenity: args?['amenity'] as String?,
          ),
        );
      case propertyDetails:
        Property? prop;
        String? propId;
        if (settings.arguments is Property) {
          prop = settings.arguments as Property;
          propId = prop.id;
        } else if (settings.arguments is String) {
          propId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          prop = map['property'] as Property?;
          propId = (map['id'] ?? map['propertyId'])?.toString();
        }
        return MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: prop, propertyId: propId));
      case propertyAr:
        Property? prop;
        String? propId;
        if (settings.arguments is Property) {
          prop = settings.arguments as Property;
          propId = prop.id;
        } else if (settings.arguments is String) {
          propId = settings.arguments as String;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          prop = map['property'] as Property?;
          propId = (map['id'] ?? map['propertyId'])?.toString();
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PropertyArScreen(property: prop, propertyId: propId),
        );
      case trustEngine:
      case verifyProperty:
        Property? prop;
        if (settings.arguments is Property) {
          prop = settings.arguments as Property;
        } else if (settings.arguments is String) {
          prop = PropertyStateService.instance.findPropertyById(settings.arguments as String);
        }
        PropertyDetailsInput? details;
        if (prop != null) {
          details = PropertyDetailsInput(
            propertyType: prop.propertyType.isNotEmpty ? prop.propertyType : 'Residential Apartment',
            address: prop.address.isNotEmpty ? prop.address : prop.title,
            city: prop.city.isNotEmpty ? prop.city : 'Noida',
            sectorLocality: prop.sector.isNotEmpty ? prop.sector : 'Sector 104',
            ownerName: prop.dealerName.isNotEmpty ? prop.dealerName : 'Vikramaditya Sharma',
            area: prop.sqft > 0 ? prop.sqft.toString() : '2150',
            unit: 'Sq.Ft.',
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TrustEngineScreen(initialDetails: details),
        );
      case compareProperties:
        return MaterialPageRoute(builder: (_) => const PropertyComparisonScreen());
      case myPropzen:
        return MaterialPageRoute(builder: (_) => const MyPropzenDashboardScreen());
      case areaDiscovery:
        Property? prop;
        String? pincode;
        String? locality;
        if (settings.arguments is Property) {
          prop = settings.arguments as Property;
        } else if (settings.arguments is Map) {
          final map = settings.arguments as Map;
          prop = map['property'] as Property?;
          pincode = map['pincode']?.toString();
          locality = map['locality']?.toString();
        } else if (settings.arguments is String) {
          locality = settings.arguments as String;
        }
        return MaterialPageRoute(
          builder: (_) => AreaDiscoveryScreen(
            sourceProperty: prop,
            pincode: pincode,
            locality: locality,
          ),
        );
      case loanComparison:
        double price = 10000000;
        if (settings.arguments is double) {
          price = settings.arguments as double;
        } else if (settings.arguments is Property) {
          price = (settings.arguments as Property).askingPriceCr * 10000000;
        }
        return MaterialPageRoute(builder: (_) => LoanComparisonScreen(initialPrice: price));
      case constructionMarketplace:
        return MaterialPageRoute(builder: (_) => const SupplierDirectoryScreen());
      case forum:
        return MaterialPageRoute(builder: (_) => const ForumScreen());
      case chat:
        String? convId;
        if (settings.arguments is String) convId = settings.arguments as String;
        return MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId));
      case nriHub:
        return MaterialPageRoute(builder: (_) => const NriHubScreen());
      case regions:
        return MaterialPageRoute(builder: (_) => const RegionManagementScreen());
      case constructionProgress:
        Property prop;
        if (settings.arguments is Property) {
          prop = settings.arguments as Property;
        } else {
          prop = PropertyStateService.instance.allProperties.isNotEmpty
              ? PropertyStateService.instance.allProperties.first
              : Property.empty;
        }
        return MaterialPageRoute(builder: (_) => ConstructionProgressScreen(property: prop));
      case filters:
        return MaterialPageRoute(builder: (_) => const DynamicFilterScreen());
      case aiAdvisor:
        return MaterialPageRoute(builder: (_) => const AiAdvisorChatScreen());
      case services:
        return MaterialPageRoute(builder: (_) => const AllFeaturesScreen());
      case deals:
        return MaterialPageRoute(
          builder: (_) => const PropertySearchScreen(
            title: 'Price Drop Deals',
            filterTag: 'Price Drop',
          ),
        );
      case enquiry:
        return MaterialPageRoute(builder: (_) => const MyEnquiriesScreen());
      case bookVisit:
        final prop = settings.arguments as Property?;
        return MaterialPageRoute(builder: (_) => SiteVisitBookingScreen(property: prop));
      case savedProperties:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      case compare:
        return MaterialPageRoute(builder: (_) => const PropertyCompareScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());
      case emiCalculator:
        return MaterialPageRoute(builder: (_) => const EmiCalculatorScreen());
      case dealers:
        return MaterialPageRoute(builder: (_) => const DealersDirectoryScreen());
      case marketHub:
        return MaterialPageRoute(builder: (_) => const MarketHubScreen());
      case about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      case contact:
        return MaterialPageRoute(builder: (_) => const ContactScreen());
      case aiTool:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AiToolDetailScreen(
            toolType: args?['toolType'] ?? 'general',
            title: args?['title'] ?? 'AI Intelligence Tool',
            category: args?['category'] ?? 'AI Tools',
            description: args?['description'] ?? 'PropZen institutional AI analysis tool.',
            icon: args?['icon'] ?? Icons.auto_awesome,
            accentColor: args?['accentColor'] ?? const Color(0xFF7C3AED),
            actionButtonText: args?['actionButtonText'] ?? 'Execute Tool',
          ),
        );
      case locationPicker:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LocationPickerScreen(
            initialLatitude: args?['latitude'] as double?,
            initialLongitude: args?['longitude'] as double?,
            initialAddress: args?['address'] as String?,
            initialCity: args?['city'] as String?,
            initialLocality: args?['locality'] as String?,
          ),
        );
      case aiHomeDesigner:
        final args = settings.arguments as Map<String, dynamic>?;
        final proj = args?['project'] as AiHomeProject?;
        return MaterialPageRoute(builder: (_) => AiHomeDesignerLandingScreen(initialProject: proj));
      case aiHomeDesignerWizard:
        final args = settings.arguments as Map<String, dynamic>?;
        final proj = args?['project'] as AiHomeProject?;
        final step = args?['step'] as int? ?? 0;
        return MaterialPageRoute(builder: (_) => AiHomeDesignerWizardScreen(initialProject: proj, initialStep: step));
      case myAiDesigns:
        return MaterialPageRoute(builder: (_) => const MyAiDesignsScreen());

      // Buyer Dashboard route (Strict role check)
      case buyerDashboard:
        if (UserSession.isLoggedIn && UserSession.isDealer && !UserSession.isAdmin) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: dealerPortal),
            builder: (_) => const DealerDashboardScreen(),
          );
        }
        if (UserSession.isLoggedIn && UserSession.isServicePartner && !UserSession.isAdmin) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: servicePartnerPortal),
            builder: (_) => const ServicePartnerPortalScreen(),
          );
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const MainShell(initialIndex: 0));

      // Dealer routes (STRICT ROLE-GUARDED: DEALER role strictly enforced)
      case dealerPortal:
      case dealerLogin:
      case dealerRegister:
      case dealerDashboard:
      case dealerProperties:
      case dealerLeads:
      case dealerSiteVisits:
      case dealerBookings:
      case dealerAnalytics:
      case dealerProfile:
        if (settings.name == dealerLogin) {
          return MaterialPageRoute(builder: (_) => const DualAuthScreen());
        }
        if (settings.name == dealerRegister) {
          return MaterialPageRoute(builder: (_) => const DualAuthScreen(initialSignUp: true));
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthRouteBarrier(
            builder: (_) {
              if (!UserSession.isLoggedIn) {
                return DualAuthScreen(redirectRoute: settings.name);
              }
              if (!UserSession.isDealer && !UserSession.isAdmin) {
                return const DealerAccessDeniedScreen();
              }
              if (settings.name == dealerProperties) {
                return const DealerPropertiesScreen();
              } else if (settings.name == dealerLeads) {
                return const DealerLeadsScreen();
              } else if (settings.name == dealerSiteVisits || settings.name == dealerBookings) {
                return const DealerSiteVisitsScreen();
              } else if (settings.name == dealerProfile) {
                return const DealerProfileScreen();
              }
              return const DealerDashboardScreen();
            },
          ),
        );

      // Dedicated Separate Service Partner Portals (Strict Role & Specialization Guarded)
      case loanPartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _guardServicePartnerRoute(
            category: ServiceCategoryType.loan,
            dashboardBuilder: () => const LoanPartnerDashboard(),
            redirectRoute: loanPartnerPortal,
          ),
        );

      case homeDesignPartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _guardServicePartnerRoute(
            category: ServiceCategoryType.homeDesign,
            dashboardBuilder: () => const HomeDesignPartnerDashboard(),
            redirectRoute: homeDesignPartnerPortal,
          ),
        );

      case vastuPartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _guardServicePartnerRoute(
            category: ServiceCategoryType.vastu,
            dashboardBuilder: () => const VastuPartnerDashboard(),
            redirectRoute: vastuPartnerPortal,
          ),
        );

      case constructionPartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _guardServicePartnerRoute(
            category: ServiceCategoryType.construction,
            dashboardBuilder: () => const ConstructionPartnerDashboard(),
            redirectRoute: constructionPartnerPortal,
          ),
        );

      case propertyVerificationPartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _guardServicePartnerRoute(
            category: ServiceCategoryType.propertyVerification,
            dashboardBuilder: () => const PropertyVerificationPartnerDashboard(),
            redirectRoute: propertyVerificationPartnerPortal,
          ),
        );

      case virtual3dPartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => _guardServicePartnerRoute(
            category: ServiceCategoryType.visualization,
            dashboardBuilder: () => const Virtual3DPartnerDashboard(),
            redirectRoute: virtual3dPartnerPortal,
          ),
        );

      case selectServicePortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthRouteBarrier(
            builder: (_) {
              if (!UserSession.isLoggedIn) {
                return const DualAuthScreen(redirectRoute: selectServicePortal);
              }
              if (!UserSession.isServicePartner && !UserSession.isAdmin) {
                return const ServicePartnerAccessDeniedScreen();
              }
              if (UserSession.isAdmin) {
                return const SelectServicePortalScreen();
              }
              final profile = UserSession.currentServicePartnerProfile;
              if (profile == null || !profile.isApproved || profile.isSuspended) {
                return const ServicePartnerStatusScreen();
              }
              final approved = profile.approvedCategoryTypes;
              if (approved.isEmpty) {
                return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.missingSpecialization);
              }
              if (approved.length == 1) {
                return buildPartnerDashboardForCategory(approved.first);
              }
              return const SelectServicePortalScreen();
            },
          ),
        );

      case servicePartnerStatus:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthRouteBarrier(
            builder: (_) {
              if (!UserSession.isLoggedIn) {
                return const DualAuthScreen(redirectRoute: servicePartnerStatus);
              }
              if (!UserSession.isServicePartner && !UserSession.isAdmin) {
                return const ServicePartnerAccessDeniedScreen();
              }
              return const ServicePartnerStatusScreen();
            },
          ),
        );

      // Legacy fallback: automatically route to the partner's primary approved portal
      case servicePartnerPortal:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthRouteBarrier(
            builder: (_) {
              if (!UserSession.isLoggedIn) {
                return const DualAuthScreen(redirectRoute: servicePartnerPortal);
              }
              if (!UserSession.isServicePartner && !UserSession.isAdmin) {
                return const ServicePartnerAccessDeniedScreen();
              }
              if (UserSession.isAdmin) {
                return const SelectServicePortalScreen();
              }
              final profile = UserSession.currentServicePartnerProfile;
              if (profile == null || !profile.isApproved || profile.isSuspended) {
                return const ServicePartnerStatusScreen();
              }
              final approved = profile.approvedCategoryTypes;
              if (approved.isEmpty) {
                return const ServicePartnerStatusScreen(forcedStatus: ServicePartnerStatusType.missingSpecialization);
              }
              if (approved.length > 1) {
                return const SelectServicePortalScreen();
              }
              return buildPartnerDashboardForCategory(approved.first);
            },
          ),
        );

      case servicePartnerAccessDenied:
        return MaterialPageRoute(settings: settings, builder: (_) => const ServicePartnerAccessDeniedScreen());

      // Property Listing Protected Routes
      case listProperty:
      case postProperty:
      case dealerAddProperty:
        if (!UserSession.isLoggedIn) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const DualAuthScreen(redirectRoute: AppRoutes.listProperty),
          );
        }
        if (!UserSession.isEmailVerified) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const EmailVerificationGateScreen(redirectRoute: AppRoutes.listProperty),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PostPropertyScreen(),
        );
      case dealerSettings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      // Ecosystem Routes
      case buyerRequirements:
        return MaterialPageRoute(builder: (_) => const BuyerRequirementsScreen());
      case visitPlanner:
        return MaterialPageRoute(builder: (_) => const PropertyVisitPlannerScreen());
      case aiListingCreator:
        return MaterialPageRoute(builder: (_) => const AiListingCreatorScreen());
      case dealRoom:
        final args = settings.arguments as Map<String, dynamic>?;
        final roomId = args?['roomId'] as String? ?? 'DEAL-SAMPLE-01';
        return MaterialPageRoute(builder: (_) => DealRoomScreen(dealRoomId: roomId));
      case negotiationRoom:
        final args = settings.arguments as Map<String, dynamic>?;
        final prop = args?['property'] as Property? ?? Property.sampleDeals.first;
        return MaterialPageRoute(builder: (_) => NegotiationRoomScreen(property: prop));
      case siteVisitChecklist:
        final args = settings.arguments as Map<String, dynamic>?;
        final propId = args?['propertyId'] as String? ?? 'PROP-01';
        final propTitle = args?['propertyTitle'] as String? ?? 'Property Checklist';
        final visitId = args?['visitId'] as String? ?? 'VISIT-01';
        return MaterialPageRoute(
          builder: (_) => SiteVisitChecklistScreen(
            propertyId: propId,
            propertyTitle: propTitle,
            visitId: visitId,
          ),
        );

      // Production Modules
      case loanAdvisor:
        return MaterialPageRoute(builder: (_) => const LoanAdvisorScreen());
      case loanApplication:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => LoanApplicationWizardScreen(
            prefillPropertyTitle: args?['propertyTitle'] as String?,
            prefillPropertyPrice: args?['propertyPrice'] as double?,
          ),
        );
      case designStudio:
        return MaterialPageRoute(builder: (_) => const DesignStudioScreen());
      case reporterFeed:
        return MaterialPageRoute(builder: (_) => const ReporterFeedScreen());
      case reporterStudio:
        return MaterialPageRoute(builder: (_) => const ReporterStudioScreen());
      case superDashboard:
        return MaterialPageRoute(settings: settings, builder: (_) => const SuperDashboardScreen());
      case vendorWallet:
        return MaterialPageRoute(settings: settings, builder: (_) => const VendorWalletDashboardScreen());
      case nriValuation:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => NriSmartValuationScreen(
            initialProperty: args?['property'] as Property?,
          ),
        );
      case nriAiAdvisor:
        return MaterialPageRoute(builder: (_) => const NriAiAdvisorChatScreen());

      // Admin routes (Strictly protected by AdminRouteGuard)
      case admin:
      case adminPanel:
      case adminDashboard:
      case commandCenter:
      case adminCommandCenter:
      case 'admin':
      case 'admin-panel':
      case 'admin-dashboard':
      case 'admin-portal':
      case 'command-center':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(),
        );

      case adminPropertyVerification:
      case 'admin/property-verification':
      case '/command-center/property-verification':
      case 'command-center/property-verification':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: false,
            child: AdminPanelScreen(initialNavIndex: 2),
          ),
        );

      // PropZen Command Panel & CRM Integrated Routes (allowCrmRoles: true)
      case commandPanel:
      case 'command-panel':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 0),
          ),
        );
      case commandPanelCrm:
      case 'command-panel/crm':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 20),
          ),
        );
      case commandPanelCrmLeads:
      case 'command-panel/crm/leads':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 21),
          ),
        );
      case commandPanelCrmCustomers:
      case 'command-panel/crm/customers':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 22),
          ),
        );
      case commandPanelCrmFollowUps:
      case 'command-panel/crm/follow-ups':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 23),
          ),
        );
      case commandPanelCrmTasks:
      case 'command-panel/crm/tasks':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 24),
          ),
        );
      case commandPanelCrmProperties:
      case 'command-panel/crm/properties':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 25),
          ),
        );
      case commandPanelCrmSiteVisits:
      case 'command-panel/crm/site-visits':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 26),
          ),
        );
      case commandPanelCrmWhatsApp:
      case 'command-panel/crm/whatsapp':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 27),
          ),
        );
      case commandPanelCrmCampaigns:
      case 'command-panel/crm/campaigns':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 28),
          ),
        );
      case commandPanelCrmAnalytics:
      case 'command-panel/crm/analytics':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdminRouteGuard(
            allowCrmRoles: true,
            child: AdminPanelScreen(initialNavIndex: 29),
          ),
        );

      // Enterprise CRM Module Routes (Strict Role & Identity Guarded)
      case crm:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crm,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.dashboard),
          ),
        );
      case crmLeads:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmLeads,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.leads),
          ),
        );
      case crmFollowUps:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmFollowUps,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.followUps),
          ),
        );
      case crmTasks:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmTasks,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.tasks),
          ),
        );
      case crmCampaigns:
      case crmWhatsApp:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmCampaigns,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.campaigns),
          ),
        );
      case crmProperties:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmProperties,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.properties),
          ),
        );
      case crmCustomers:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmCustomers,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.customers),
          ),
        );
      case crmAnalytics:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CrmRouteGuard(
            redirectRoute: crmAnalytics,
            builder: (_) => const CrmShellScreen(initialTab: CrmTab.analytics),
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0));
    }
  }

  /// Strict Authorization Guard for Separate Service Partner Portals
  static Widget _guardServicePartnerRoute({
    required ServiceCategoryType category,
    required Widget Function() dashboardBuilder,
    required String redirectRoute,
  }) {
    return ServicePartnerRouteGuard(
      requiredCategory: category,
      builder: (_) => dashboardBuilder(),
    );
  }
}

