import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Input field specification for an AI Tool with clean empty default state
class AiToolInputField {
  final String key;
  final String label;
  final String hint;
  final String type; // 'text', 'number', 'dropdown', 'slider', 'chips', 'upload'
  final String defaultValue;
  final List<String>? options;
  final double? min;
  final double? max;
  final String? suffix;

  const AiToolInputField({
    required this.key,
    required this.label,
    required this.hint,
    this.type = 'text',
    this.defaultValue = '',
    this.options,
    this.min,
    this.max,
    this.suffix,
  });
}

/// Model definition for all PropZen Real-Estate Services & Tools
class AiServiceTool {
  final String id;
  final String slug;
  final String routePath;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String primaryCategory;
  final List<String> allCategories;
  final List<String> searchKeywords;
  final IconData icon;
  final Color accentColor;
  final String uniqueImageUrl;
  final String badgeLabel;
  final String buttonLabel;
  final List<String> features;
  final List<AiToolInputField> inputs;
  final String? disclaimer;
  final String? location;
  final double? price;
  final double? rating;
  final String? serviceType;
  final String? availability;
  final String? provider;

  const AiServiceTool({
    required this.id,
    required this.slug,
    required this.routePath,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.primaryCategory,
    required this.allCategories,
    required this.searchKeywords,
    required this.icon,
    required this.accentColor,
    required this.uniqueImageUrl,
    this.badgeLabel = 'AI POWERED',
    this.buttonLabel = 'Generate Analysis',
    required this.features,
    required this.inputs,
    this.disclaimer,
    this.location,
    this.price,
    this.rating,
    this.serviceType,
    this.availability,
    this.provider,
  });

  /// Category alias
  String get category => primaryCategory;

  /// Parse from dynamic Map / database record safely
  factory AiServiceTool.fromMap(Map<String, dynamic> map) {
    final title = (map['title'] ?? map['name'] ?? map['service_name'] ?? '').toString().trim();
    final id = (map['id'] ?? map['service_id'] ?? title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')).toString().trim();
    final slug = (map['slug'] ?? id.replaceAll('ai_', '').replaceAll('_', '-')).toString().trim();
    final primaryCategory = (map['category'] ?? map['primary_category'] ?? 'General').toString().trim();

    List<String> allCategories = [];
    if (map['all_categories'] is List) {
      allCategories = (map['all_categories'] as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (map['categories'] is List) {
      allCategories = (map['categories'] as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else if (primaryCategory.isNotEmpty) {
      allCategories = [primaryCategory];
    } else {
      allCategories = [];
    }

    List<String> searchKeywords = [];
    if (map['search_keywords'] is List) {
      searchKeywords = (map['search_keywords'] as List).map((e) => e.toString().trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
    } else if (map['keywords'] is List) {
      searchKeywords = (map['keywords'] as List).map((e) => e.toString().trim().toLowerCase()).where((s) => s.isNotEmpty).toList();
    } else {
      searchKeywords = [title.toLowerCase(), primaryCategory.toLowerCase(), slug];
    }

    List<String> features = [];
    if (map['features'] is List) {
      features = (map['features'] as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      final str = val.toString().replaceAll(',', '').trim();
      final match = RegExp(r'[0-9]+(\.[0-9]+)?').firstMatch(str);
      if (match != null) {
        return double.tryParse(match.group(0)!);
      }
      return null;
    }

    return AiServiceTool(
      id: id,
      slug: slug,
      routePath: (map['route_path'] ?? '/ai-tools/$slug').toString(),
      title: title,
      shortDescription: (map['short_description'] ?? map['description'] ?? '').toString().trim(),
      fullDescription: (map['full_description'] ?? map['description'] ?? map['short_description'] ?? '').toString().trim(),
      primaryCategory: primaryCategory,
      allCategories: allCategories,
      searchKeywords: searchKeywords,
      icon: _parseIcon(map['icon']?.toString()),
      accentColor: _parseColor(map['accent_color']?.toString()),
      uniqueImageUrl: (map['image_url'] ?? map['unique_image_url'] ?? map['image'] ?? '').toString().trim(),
      badgeLabel: (map['badge_label'] ?? map['badge'] ?? 'VERIFIED').toString().trim(),
      buttonLabel: (map['button_label'] ?? 'Launch Service').toString().trim(),
      features: features,
      inputs: const [],
      disclaimer: map['disclaimer']?.toString(),
      location: map['location']?.toString().trim(),
      price: parseDouble(map['price'] ?? map['starting_price'] ?? map['budget']),
      rating: parseDouble(map['rating'] ?? map['rate']),
      serviceType: map['service_type']?.toString().trim(),
      availability: map['availability']?.toString().trim(),
      provider: (map['provider'] ?? map['provider_name'] ?? map['dealer'] ?? map['dealer_name'])?.toString().trim(),
    );
  }

  static IconData _parseIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return LucideIcons.sparkles;
    switch (iconName.toLowerCase()) {
      case 'home':
        return LucideIcons.home;
      case 'layout':
        return LucideIcons.layout;
      case 'palette':
        return LucideIcons.palette;
      case 'building':
        return LucideIcons.building;
      case 'compass':
        return LucideIcons.compass;
      case 'box':
        return LucideIcons.box;
      case 'filecheck':
      case 'file_check':
        return LucideIcons.fileCheck;
      case 'indianrupee':
      case 'landmark':
      case 'loan':
        return LucideIcons.indianRupee;
      case 'hammer':
      case 'hardhat':
        return LucideIcons.hammer;
      case 'messages':
      case 'messagessquare':
        return LucideIcons.messagesSquare;
      case 'plane':
      case 'drone':
        return LucideIcons.plane;
      case 'video':
        return LucideIcons.video;
      case 'shield':
        return LucideIcons.shield;
      default:
        return LucideIcons.sparkles;
    }
  }

  static Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF6D28D9);
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.replaceAll('#', '');
        return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
      }
      if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      }
    } catch (_) {}
    return const Color(0xFF6D28D9);
  }
}

/// Registry containing all complete official Service Hub Tools (Clean initial states without pre-filled mock records)
class AiServiceRegistry {
  AiServiceRegistry._();

  /// Standard predefined categories for the Service Hub
  static const List<String> standardCategories = [
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

  /// Built-in clean tools list with unique domain-specific imagery and exact category mappings
  static final List<AiServiceTool> _builtInTools = [
    // 01. Home Design (AI Floor Plan)
    const AiServiceTool(
      id: 'ai_floor_plan',
      slug: 'floor-plan',
      routePath: '/ai-tools/floor-plan',
      title: 'AI Floor Plan',
      shortDescription: 'Generate custom architectural 2D CAD blueprints and Vastu zoning for your plot.',
      fullDescription: 'PropZen parametric architectural engine generates compliant 2D layouts customized to your exact plot dimensions, setbacks, and room specifications.',
      primaryCategory: 'Home Design',
      allCategories: ['Home Design', 'Floor Plan', 'Design', 'Architecture'],
      searchKeywords: ['home design', 'ai floor plan', 'floor', 'plan', 'cad', '2d', 'blueprint', 'layout', 'plot', 'architect'],
      icon: LucideIcons.layout,
      accentColor: Color(0xFF4F46E5),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'CAD READY',
      buttonLabel: 'Generate 2D Floor Plan',
      features: ['2D Architectural CAD Layout', 'Precise Room Dimensions', 'Vastu Shastra Zoning', 'Circulation Efficiency Score'],
      inputs: [
        AiToolInputField(key: 'plotWidth', label: 'Plot Width (ft)', hint: 'e.g. 30'),
        AiToolInputField(key: 'plotLength', label: 'Plot Length (ft)', hint: 'e.g. 50'),
        AiToolInputField(
          key: 'facing',
          label: 'Entrance Facing Direction',
          hint: 'Select Direction',
          type: 'dropdown',
          defaultValue: 'North-East',
          options: ['North-East', 'North', 'East', 'North-West', 'South-East', 'West', 'South', 'South-West'],
        ),
        AiToolInputField(
          key: 'floors',
          label: 'Number of Floors',
          hint: 'Select Structure',
          type: 'dropdown',
          defaultValue: 'Double Story (G+1)',
          options: ['Single Story (G)', 'Double Story (G+1)', 'Triplex (G+2)', 'Stilt + 4 Builder Floor'],
        ),
        AiToolInputField(
          key: 'bedrooms',
          label: 'Bedrooms (BHK)',
          hint: 'Select Configuration',
          type: 'dropdown',
          defaultValue: '3 BHK',
          options: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK Luxury Villa'],
        ),
      ],
      disclaimer: 'Generated CAD layouts are conceptual spatial schemes. Consult a licensed civil engineer before construction.',
    ),

    // 02. AI Home Designer (Interior Design)
    const AiServiceTool(
      id: 'ai_home_designer',
      slug: 'home-designer',
      routePath: '/ai-tools/home-designer',
      title: 'AI Home Designer',
      shortDescription: 'Interactive room staging, material moodboards, and turnkey interior cost estimation.',
      fullDescription: 'Transform any room with bespoke material palettes, Italian vitrified flooring, acoustic slat panelling, and turnkey execution budgets.',
      primaryCategory: 'Interior Design',
      allCategories: ['Interior Design', 'Design', 'Interiors', 'Home Decor'],
      searchKeywords: ['home', 'designer', 'interior', 'interior design', 'room', 'living', 'furniture', 'decor'],
      icon: LucideIcons.home,
      accentColor: Color(0xFF7C3AED),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'AI DESIGN',
      buttonLabel: 'Generate Room Design',
      features: ['Turnkey Cost Estimation', 'Material Moodboard & Specs', 'Custom Furniture Breakdown', 'Lighting & False Ceiling Scheme'],
      inputs: [
        AiToolInputField(
          key: 'roomType',
          label: 'Target Room',
          hint: 'Select Room',
          type: 'dropdown',
          defaultValue: 'Living & Dining Hall',
          options: ['Living & Dining Hall', 'Master Bedroom Suite', 'Modular Kitchen', 'Kids Bedroom', 'Home Office Studio', 'Balcony Garden'],
        ),
        AiToolInputField(
          key: 'style',
          label: 'Design Aesthetic',
          hint: 'Select Style',
          type: 'dropdown',
          defaultValue: 'Modern Minimalist',
          options: ['Modern Minimalist', 'Contemporary Luxury', 'Scandinavian Warmth', 'Traditional Indian Heritage', 'Industrial Chic'],
        ),
        AiToolInputField(key: 'roomSize', label: 'Room Dimensions', hint: 'e.g. 20x16 ft'),
        AiToolInputField(
          key: 'colorPref',
          label: 'Color Palette Mood',
          hint: 'Select Color Theme',
          type: 'dropdown',
          defaultValue: 'Warm Earthy Neutrals',
          options: ['Warm Earthy Neutrals', 'Cool Slate & Indigo', 'Sage Green & Wood', 'Monochrome Charcoal', 'Royal Emerald & Gold'],
        ),
        AiToolInputField(key: 'budget', label: 'Target Furnishing Budget', hint: 'e.g. ₹ 8L - ₹ 12L'),
      ],
    ),

    // 03. Vastu Consultancy
    const AiServiceTool(
      id: 'ai_vastu',
      slug: 'vastu',
      routePath: '/ai-tools/vastu',
      title: 'Vastu Consultancy',
      shortDescription: 'Comprehensive Vastu Shastra audit, directional energy mapping, and non-demolition remedies.',
      fullDescription: 'Evaluate Vedic directional alignment for main entrance, kitchen Agni zone, master bedroom Nairutya, and Brahmasthan spatial balance.',
      primaryCategory: 'Vastu Consultancy',
      allCategories: ['Vastu Consultancy', 'Vastu', 'Consultancy', 'Vedic'],
      searchKeywords: ['vastu', 'vastu consultancy', 'shastra', 'energy', 'direction', 'north', 'east', 'remedies', 'ishanya'],
      icon: LucideIcons.compass,
      accentColor: Color(0xFFD97706),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'VEDIC AUDIT',
      buttonLabel: 'Analyze Vastu Score',
      features: ['Vastu Harmony Score / 100', 'Directional Zone Mapping', 'Non-Demolition Remedies', 'Auspicious Energy Guidelines'],
      inputs: [
        AiToolInputField(
          key: 'propertyDirection',
          label: 'Main Entrance Facing',
          hint: 'Select Entrance Facing',
          type: 'dropdown',
          defaultValue: 'North-East (Ishanya)',
          options: ['North-East (Ishanya)', 'North (Kuber)', 'East (Indra)', 'South-East (Agni)', 'South (Yama)', 'South-West (Nairutya)', 'West (Varuna)', 'North-West (Vayu)'],
        ),
        AiToolInputField(
          key: 'kitchenZone',
          label: 'Kitchen Location',
          hint: 'Select Kitchen Zone',
          type: 'dropdown',
          defaultValue: 'South-East (Agni - Best)',
          options: ['South-East (Agni - Best)', 'North-West (Vayu)', 'North-East (Ishanya)', 'South-West (Nairutya)'],
        ),
        AiToolInputField(
          key: 'masterBedZone',
          label: 'Master Bedroom Location',
          hint: 'Select Master Bedroom Zone',
          type: 'dropdown',
          defaultValue: 'South-West (Nairutya - Ideal)',
          options: ['South-West (Nairutya - Ideal)', 'South', 'West', 'North-West'],
        ),
        AiToolInputField(
          key: 'plotShape',
          label: 'Plot / Floor Shape',
          hint: 'Select Shape',
          type: 'dropdown',
          defaultValue: 'Rectangular / Square (Ideal)',
          options: ['Rectangular / Square (Ideal)', 'Gomukhi (Cow Faced)', 'Shermukhi (Lion Faced)', 'Irregular Polygon'],
        ),
      ],
      disclaimer: 'Vastu reports are spiritual spatial recommendations. Apply in synergy with architectural guidelines.',
    ),

    // 04. Property Visualization (3D Spatial Staging)
    const AiServiceTool(
      id: 'ai_3d_visualization',
      slug: 'property-visualization',
      routePath: '/ai-tools/property-visualization',
      title: 'Property Visualization',
      shortDescription: 'AR/VR spatial staging, wall & floor color simulation, and photorealistic 3D rendering.',
      fullDescription: 'Experience immersive virtual staging with real-time daylight simulation, texture mapping, and spatial walkthrough previews.',
      primaryCategory: 'Property Visualization',
      allCategories: ['Property Visualization', '3D Visualization', 'Visualization', 'AR/VR'],
      searchKeywords: ['3d', 'property visualization', 'visualization', 'ar', 'vr', 'spatial', 'staging', 'render', 'virtual'],
      icon: LucideIcons.box,
      accentColor: Color(0xFF2563EB),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
      badgeLabel: '3D SPATIAL',
      buttonLabel: 'Generate 3D Spatial Staging',
      features: ['AR Virtual Staging', 'Dynamic Lighting Preview', 'Material Swatch Customization', '360° Panorama View'],
      inputs: [
        AiToolInputField(
          key: 'propertyType',
          label: 'Property Type',
          hint: 'Select Property Type',
          type: 'dropdown',
          defaultValue: '3 BHK Apartment',
          options: ['2 BHK Apartment', '3 BHK Apartment', '4 BHK Luxury Floor', 'Independent Villa', 'Studio Penthouse', 'Commercial Space'],
        ),
        AiToolInputField(
          key: 'visualMode',
          label: 'Visualization Mode',
          hint: 'Select Mode',
          type: 'dropdown',
          defaultValue: 'Furnished AR Staging',
          options: ['Furnished AR Staging', 'Daylight / Night Photorealistic Lighting', 'Material & Texture Color Swap', 'Virtual 360 Walkthrough'],
        ),
        AiToolInputField(key: 'roomArea', label: 'Carpet Area (sq.ft.)', hint: 'e.g. 1850'),
      ],
    ),

    // 05. Drone Tour
    const AiServiceTool(
      id: 'ai_drone_tour',
      slug: 'drone-tour',
      routePath: '/ai-tools/drone-tour',
      title: 'Drone Tour',
      shortDescription: 'High-definition 4K aerial mapping, sector radius analysis, and highway corridor views.',
      fullDescription: 'Explore aerial footage and corridor topography across NCR with precision landmark distance overlays and 360° aerial panoramas.',
      primaryCategory: 'Drone Tour',
      allCategories: ['Drone Tour', 'Property Visualization', 'Visualization', 'Drone'],
      searchKeywords: ['drone', 'drone tour', 'aerial', '4k', 'video', 'mapping', 'sector', 'metro', 'highway'],
      icon: LucideIcons.plane,
      accentColor: Color(0xFF0D9488),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=800&q=80',
      badgeLabel: '4K AERIAL',
      buttonLabel: 'Simulate Drone Flyover',
      features: ['4K Aerial Video Simulation', 'Sector Infrastructure Overlay', 'Expressway Distance Vector', 'Landmark Line of Sight'],
      inputs: [
        AiToolInputField(key: 'sector', label: 'Target Sector / Micro-Market', hint: 'e.g. Sector 150, Noida'),
        AiToolInputField(
          key: 'radius',
          label: 'Aerial Mapping Radius',
          hint: 'Select Radius',
          type: 'dropdown',
          defaultValue: '3 KM Sector Radius',
          options: ['1 KM Local Radius', '3 KM Sector Radius', '5 KM Expressway & Metro Corridor'],
        ),
        AiToolInputField(
          key: 'flightElevation',
          label: 'Flight Altitude',
          hint: 'Select Elevation',
          type: 'dropdown',
          defaultValue: 'Mid Altitude (120m) - Sector Connectivity',
          options: ['Low Altitude (50m) - Facade & Amenities', 'Mid Altitude (120m) - Sector Connectivity', 'High Altitude (300m) - Horizon View'],
        ),
      ],
    ),

    // 06. Document Verification
    const AiServiceTool(
      id: 'ai_document_verification',
      slug: 'document-verification',
      routePath: '/ai-tools/document-verification',
      title: 'Document Verification',
      shortDescription: '30-year legal title check, RERA registration audit, and encumbrance verification.',
      fullDescription: 'Comprehensive real-estate legal intelligence engine auditing title deed chain, municipal approvals, and RERA compliance.',
      primaryCategory: 'Document Verification',
      allCategories: ['Document Verification', 'Documents', 'Legal', 'RERA'],
      searchKeywords: ['document', 'document verification', 'verification', 'rera', 'legal', 'title', 'deed', 'registry', 'encumbrance'],
      icon: LucideIcons.fileCheck,
      accentColor: Color(0xFFDC2626),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1450133064473-71024230f91b?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'LEGAL AUDIT',
      buttonLabel: 'Verify Legal Document',
      features: ['30-Year Title Search Checklist', 'RERA Encumbrance Audit', 'High Court Advocate Verified Guidelines', 'Risk Index Assessment'],
      inputs: [
        AiToolInputField(
          key: 'docType',
          label: 'Document Category',
          hint: 'Select Document Type',
          type: 'dropdown',
          defaultValue: 'RERA Project Registration Certificate',
          options: ['RERA Project Registration Certificate', '30-Year Chain Sale Deed Registry', 'Noida / Greater Noida Authority Allotment Letter', 'Encumbrance Certificate (Form 15/16)', 'Occupancy / Completion Certificate (OC/CC)'],
        ),
        AiToolInputField(key: 'reraNumber', label: 'RERA Registration / Deed Number', hint: 'e.g. UPRERAPRJ123456'),
        AiToolInputField(key: 'documentFile', label: 'Upload Document for AI Audit', hint: 'Select PDF or Image', type: 'upload'),
      ],
      disclaimer: 'Online verification is an initial AI diligence audit. Consult a licensed High Court advocate before executing financial transactions.',
    ),

    // 07. Cinematic 3D Video (Property Visualization)
    const AiServiceTool(
      id: 'ai_property_video',
      slug: '3d-video',
      routePath: '/ai-tools/3d-video',
      title: 'Cinematic 3D Video',
      shortDescription: 'Ultra HD 4K architectural video storyboard and cinematic walkthrough tour.',
      fullDescription: 'Generate dynamic video scenes, lighting transitions, and voiceover scripts tailored to showcase luxury developments.',
      primaryCategory: 'Property Visualization',
      allCategories: ['Property Visualization', '3D Video', 'Visualization', 'Video'],
      searchKeywords: ['video', '3d video', 'cinematic', 'walkthrough', 'storyboard', 'reel', 'render', 'property visualization'],
      icon: LucideIcons.video,
      accentColor: Color(0xFF9333EA),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?auto=format&fit=crop&w=800&q=80',
      badgeLabel: '4K CINEMA',
      buttonLabel: 'Generate Video Storyboard',
      features: ['Scene-by-Scene Pacing', 'Golden Hour Lighting Simulation', 'Voiceover Audio Prompts', 'Social Media Aspect Ratio Ready'],
      inputs: [
        AiToolInputField(
          key: 'videoStyle',
          label: 'Cinematic Aesthetic',
          hint: 'Select Style',
          type: 'dropdown',
          defaultValue: 'Sunset Golden Hour Luxury',
          options: ['Sunset Golden Hour Luxury', 'Clean Daylight Architectural Film', 'Dynamic Fast-Cut Reel for Socials', '4K VR Immersive Walkthrough'],
        ),
        AiToolInputField(
          key: 'duration',
          label: 'Video Duration',
          hint: 'Select Duration',
          type: 'dropdown',
          defaultValue: '60 Seconds (Showcase Teaser)',
          options: ['30 Seconds (Social Reel)', '60 Seconds (Showcase Teaser)', '120 Seconds (Full Property Tour)'],
        ),
        AiToolInputField(key: 'propertyTitle', label: 'Property / Project Name', hint: 'e.g. ATS Happy Trails, Sector 10'),
      ],
    ),

    // 08. Interior Designing
    const AiServiceTool(
      id: 'ai_interior_designer',
      slug: 'interior-design',
      routePath: '/ai-tools/interior-design',
      title: 'Interior Designing',
      shortDescription: 'Turnkey modular kitchen, custom woodwork, and luxury residential interior staging.',
      fullDescription: 'Compute accurate material quantities, hardware specifications, and contractor milestone budgets for luxury interiors.',
      primaryCategory: 'Interior Design',
      allCategories: ['Interior Design', 'Design', 'Interiors', 'Modular Kitchen'],
      searchKeywords: ['interior', 'interior design', 'modular', 'kitchen', 'wardrobe', 'woodwork', 'turnkey', 'furnishing'],
      icon: LucideIcons.palette,
      accentColor: Color(0xFFDB2777),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'INTERIORS',
      buttonLabel: 'Calculate Interior Specs',
      features: ['Modular Kitchen Sizing', 'Marine Ply Material Specs', 'Hardware Brand Allocation', 'Turnaround Timeline Estimator'],
      inputs: [
        AiToolInputField(
          key: 'scope',
          label: 'Project Scope',
          hint: 'Select Scope',
          type: 'dropdown',
          defaultValue: 'Full Home Turnkey Interiors',
          options: ['Full Home Turnkey Interiors', 'Modular Kitchen & Wardrobes Only', 'Living & Dining Experience Zone', 'Luxury Master Suite'],
        ),
        AiToolInputField(key: 'carpetArea', label: 'Carpet Area (sq.ft.)', hint: 'e.g. 1450'),
        AiToolInputField(
          key: 'finishQuality',
          label: 'Material Finish Grade',
          hint: 'Select Grade',
          type: 'dropdown',
          defaultValue: 'Premium Marine Ply with Acrylic/PU Gloss',
          options: ['Standard High-Density HDF', 'Premium Marine Ply with Acrylic/PU Gloss', 'Ultra-Luxury Italian Veneer & Sintered Stone'],
        ),
      ],
    ),

    // 09. Facade Designer (Exterior Design)
    const AiServiceTool(
      id: 'ai_facade_designer',
      slug: 'facade-designer',
      routePath: '/ai-tools/facade-designer',
      title: 'Facade Designer',
      shortDescription: 'Modern elevation architecture, weather-shield exterior coatings, and LED facade lighting.',
      fullDescription: 'Custom architectural facade elevations for independent villas, builder floors, and modern luxury homes.',
      primaryCategory: 'Exterior Design',
      allCategories: ['Exterior Design', 'Exterior', 'Facade', 'Design', 'Architecture', 'Elevation'],
      searchKeywords: ['exterior', 'exterior design', 'facade', 'facade designer', 'elevation', 'architecture', 'frontage', 'coating', 'villa'],
      icon: LucideIcons.building,
      accentColor: Color(0xFFEA580C),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'ELEVATION',
      buttonLabel: 'Generate Facade Concept',
      features: ['Exterior Material Specification', 'Cantilever & Louver Details', 'Facade LED Accent Schematics', 'Weatherproofing Benchmark'],
      inputs: [
        AiToolInputField(
          key: 'archStyle',
          label: 'Architectural Style',
          hint: 'Select Elevation Style',
          type: 'dropdown',
          defaultValue: 'Modern Cantilever Glass',
          options: ['Modern Cantilever Glass', 'Classical Neoclassical Stucco', 'Contemporary Louvered & Wood Slat', 'Ultra-Modern Brutalist Stone'],
        ),
        AiToolInputField(
          key: 'buildingType',
          label: 'Structure Type',
          hint: 'Select Structure',
          type: 'dropdown',
          defaultValue: 'Independent Villa / Kothi',
          options: ['Independent Villa / Kothi', 'Low-Rise Builder Floor (G+4)', 'Commercial Retail Building', 'Farmhouse Retreat'],
        ),
        AiToolInputField(key: 'frontage', label: 'Plot Frontage (ft)', hint: 'e.g. 40 ft'),
      ],
    ),

    // 10. Construction Support (Estimator)
    const AiServiceTool(
      id: 'ai_construction_estimator',
      slug: 'construction-support',
      routePath: '/ai-tools/construction-support',
      title: 'Construction Support',
      shortDescription: 'Material cost breakdown, civil engineering BOQ estimation, and milestone timeline schedules.',
      fullDescription: 'Compute comprehensive Bill of Quantities (BOQ) including cement, steel, brickwork, labor, and electrical finishes.',
      primaryCategory: 'Construction Support',
      allCategories: ['Construction Support', 'Construction', 'Engineering', 'BOQ'],
      searchKeywords: ['construction', 'construction support', 'estimator', 'boq', 'cement', 'steel', 'civil', 'contractor', 'cost'],
      icon: LucideIcons.hammer,
      accentColor: Color(0xFFCA8A04),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'BOQ ENGINE',
      buttonLabel: 'Compute BOQ Estimate',
      features: ['Civil Material Quantity Forecast', 'Steel & Cement Grade Calculator', 'Milestone Payment Schedule', 'Labor Index Benchmarks'],
      inputs: [
        AiToolInputField(key: 'builtUpArea', label: 'Built-Up Area (sq.ft.)', hint: 'e.g. 3200'),
        AiToolInputField(
          key: 'qualityTier',
          label: 'Construction Specification Tier',
          hint: 'Select Quality Tier',
          type: 'dropdown',
          defaultValue: 'Premium Grade (₹2,150/sq.ft.)',
          options: ['Standard Quality (₹1,650/sq.ft.)', 'Premium Grade (₹2,150/sq.ft.)', 'Ultra Luxury Designer Villa (₹2,950/sq.ft.)'],
        ),
        AiToolInputField(
          key: 'foundationType',
          label: 'Foundation Depth & Type',
          hint: 'Select Foundation Type',
          type: 'dropdown',
          defaultValue: 'Isolated Column Footing',
          options: ['Isolated Column Footing', 'Raft Foundation (Clay/Soft Soil)', 'Pile Foundation'],
        ),
      ],
    ),

    // 11. Loan Consultancy
    const AiServiceTool(
      id: 'ai_loan_consultancy',
      slug: 'loan-consultancy',
      routePath: '/ai-tools/loan-consultancy',
      title: 'Loan Consultancy',
      shortDescription: 'Instant EMI computation, bank interest comparisons, and PMAY subsidy eligibility.',
      fullDescription: 'Compare verified home loan interest rates across 20+ partner banks with instant amortization tables and eligibility calculations.',
      primaryCategory: 'Loan Consultancy',
      allCategories: ['Loan Consultancy', 'Loan', 'Finance', 'Banking', 'Consultancy'],
      searchKeywords: ['loan', 'loan consultancy', 'emi', 'finance', 'interest', 'bank', 'mortgage', 'subsidy', 'eligibility'],
      icon: LucideIcons.indianRupee,
      accentColor: Color(0xFF15803D),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'LOWEST EMI',
      buttonLabel: 'Compare Bank Rates',
      features: ['Monthly EMI Breakdown', 'Bank Rate Matrix', 'Interest vs Principal Chart', 'Processing Fee Waiver Check'],
      inputs: [
        AiToolInputField(key: 'propertyPrice', label: 'Property Price (₹ in Crores)', hint: 'e.g. 1.5'),
        AiToolInputField(
          key: 'downPaymentPct',
          label: 'Down Payment Percentage',
          hint: 'Select Down Payment',
          type: 'dropdown',
          defaultValue: '20%',
          options: ['10%', '15%', '20%', '25%', '30%'],
        ),
        AiToolInputField(key: 'interestRate', label: 'Interest Rate (%)', hint: 'e.g. 8.4'),
        AiToolInputField(
          key: 'loanDuration',
          label: 'Loan Tenure',
          hint: 'Select Tenure',
          type: 'dropdown',
          defaultValue: '20 Years',
          options: ['10 Years', '15 Years', '20 Years', '25 Years', '30 Years'],
        ),
      ],
    ),

    // 12. AI Property Recommendations
    const AiServiceTool(
      id: 'ai_property_recommendation',
      slug: 'recommendations',
      routePath: '/ai-tools/recommendations',
      title: 'AI Recommendations',
      shortDescription: 'Machine learning match advisor matching verified NCR properties to your bespoke criteria.',
      fullDescription: 'Evaluate verified NCR deals, circle rates, connectivity scores, and appreciation metrics tailored to your budget and lifestyle.',
      primaryCategory: 'AI Recommendations',
      allCategories: ['AI Recommendations', 'Intelligence', 'Advisory', 'Smart Match'],
      searchKeywords: ['recommendations', 'ai recommendations', 'ai', 'match', 'properties', 'deals', 'smart', 'advisory'],
      icon: LucideIcons.sparkles,
      accentColor: Color(0xFF6D28D9),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'SMART MATCH',
      buttonLabel: 'Find Matching Deals',
      features: ['High-Growth Corridor Score', 'Verified RERA Safety Audit', 'Rental Yield Projection', 'Builder Track Record Index'],
      inputs: [
        AiToolInputField(
          key: 'preferredCity',
          label: 'Target Region',
          hint: 'Select Region',
          type: 'dropdown',
          defaultValue: 'Noida & Noida Expressway',
          options: ['Noida & Noida Expressway', 'Greater Noida West (Noida Extension)', 'Yamuna Expressway (Jewar Hub)', 'Gurgaon (Golf Course & Dwarka Exp)', 'Delhi NCR Central'],
        ),
        AiToolInputField(key: 'budget', label: 'Target Budget', hint: 'e.g. ₹ 1.25 Cr'),
        AiToolInputField(
          key: 'bhk',
          label: 'Desired Configuration',
          hint: 'Select BHK',
          type: 'dropdown',
          defaultValue: '3 BHK',
          options: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'Villa / Penthouse', 'Residential Plot'],
        ),
        AiToolInputField(
          key: 'possession',
          label: 'Possession Timeline',
          hint: 'Select Timeline',
          type: 'dropdown',
          defaultValue: 'Ready to Move (Immediate)',
          options: ['Ready to Move (Immediate)', 'Under Construction (Within 1 Year)', 'New Pre-Launch (2-3 Years)'],
        ),
      ],
    ),

    // 13. Customer Discussion Forum
    const AiServiceTool(
      id: 'ai_customer_forum',
      slug: 'customer-forum',
      routePath: '/ai-tools/customer-forum',
      title: 'Community Forum',
      shortDescription: 'Interactive verified buyer community, builder reviews, and NCR locality discussions.',
      fullDescription: 'Connect with verified property owners, ask legal queries, and review builder delivery track records across NCR micro-markets.',
      primaryCategory: 'Community Forum',
      allCategories: ['Community Forum', 'Community', 'Forum', 'Buyers'],
      searchKeywords: ['forum', 'community forum', 'community', 'reviews', 'discussion', 'buyers', 'q&a', 'ncr', 'feedback'],
      icon: LucideIcons.messagesSquare,
      accentColor: Color(0xFF4F46E5),
      uniqueImageUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80',
      badgeLabel: 'COMMUNITY',
      buttonLabel: 'Search Discussions',
      features: ['Verified Buyer Insights', 'Micro-Market Threads', 'Builder Delivery Ratings', 'Legal Advice Exchange'],
      inputs: [
        AiToolInputField(
          key: 'topicCategory',
          label: 'Discussion Category',
          hint: 'Select Category',
          type: 'dropdown',
          defaultValue: 'Sector 150 Noida Infrastructure & Metro',
          options: ['Sector 150 Noida Infrastructure & Metro', 'Noida Extension Greater Noida West Delivery', 'Jewar Airport & Yamuna Expressway Plots', 'Builder Registry & Delay Complaints', 'Home Loan Rates & Bank Negotiation'],
        ),
        AiToolInputField(key: 'searchQuery', label: 'Search Question / Topic', hint: 'Type topic or question...'),
      ],
    ),
  ];

  /// Active tools list in memory
  static List<AiServiceTool> _activeTools = List.from(_builtInTools);

  /// Get all registered tools
  static List<AiServiceTool> get allTools => List.unmodifiable(_activeTools);

  /// Dynamic category list derived from standard categories & registered tools
  static List<String> get categories {
    final list = <String>[];
    for (final cat in standardCategories) {
      if (!list.contains(cat)) list.add(cat);
    }
    for (final tool in _activeTools) {
      if (tool.primaryCategory.isNotEmpty && !list.contains(tool.primaryCategory)) {
        list.add(tool.primaryCategory);
      }
    }
    return list;
  }

  /// Set tools dynamically (e.g. from backend)
  static void setTools(List<AiServiceTool> tools) {
    if (tools.isNotEmpty) {
      _activeTools = List.from(tools);
    } else {
      _activeTools = List.from(_builtInTools);
    }
  }

  /// Add or update a tool
  static void addTool(AiServiceTool tool) {
    _activeTools.removeWhere((t) => t.id == tool.id);
    _activeTools.add(tool);
  }

  /// Reset to clean default tools
  static void resetTools() {
    _activeTools = List.from(_builtInTools);
  }

  /// Clear all active tools
  static void clearTools() {
    _activeTools = [];
  }

  /// Find tool by slug (e.g. 'home-design' or 'vastu')
  static AiServiceTool? getBySlug(String slug) {
    try {
      final clean = slug.trim().toLowerCase();
      return _activeTools.firstWhere(
        (t) => t.slug.trim().toLowerCase() == clean || t.id.trim().toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find tool by ID (e.g. 'ai_floor_plan')
  static AiServiceTool? getById(String id) {
    try {
      final clean = id.trim().toLowerCase();
      return _activeTools.firstWhere(
        (t) => t.id.trim().toLowerCase() == clean || t.slug.trim().toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Resolve route path to matching tool
  static AiServiceTool? getByRoute(String route) {
    try {
      final clean = route.replaceAll('/ai-tools/', '').trim().toLowerCase();
      return getBySlug(clean);
    } catch (_) {
      return null;
    }
  }
}
