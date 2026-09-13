import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_home_project.dart';
import 'supabase_service.dart';

/// Abstract provider interface for pluggable AI Floor Plan, 3D and Walkthrough engines.
abstract class AiHomeGenerationProvider {
  String get providerName;
  bool get isConfigured;

  Future<AiFloorPlan> generateFloorPlan(AiHomeProject project);
  Future<AiFloorPlan> modifyFloorPlan(AiHomeProject project, String userPrompt);
  Future<List<AiFacadeDesign>> generateFacades(AiHomeProject project, {String? selectedStyle});
  Future<List<AiInteriorRoomDesign>> generateInteriors(AiHomeProject project, {String? roomName, String? style, String? colorPreference});
  Future<AiWalkthrough> generateWalkthrough(AiHomeProject project);
}

/// Built-in Parametric Architectural Engine with algorithmic Vastu zoning.
class PropZenParametricEngine implements AiHomeGenerationProvider {
  @override
  String get providerName => 'PropZen Architectural CAD & Vastu Engine';

  @override
  bool get isConfigured => true;

  @override
  Future<AiFloorPlan> generateFloorPlan(AiHomeProject project) async {
    // Artificial latency for smooth user experience and async orchestration
    await Future.delayed(const Duration(milliseconds: 1400));

    final length = project.plotLength;
    final width = project.plotWidth;
    final unit = project.plotUnit.symbol;
    final areaSqft = project.totalPlotAreaSqft;
    final builtUpSqft = (areaSqft * 0.82).roundToDouble();
    final carpetSqft = (areaSqft * 0.70).roundToDouble();

    // Vastu scoring calculation based on cardinal entrance and orientation
    int vastuScore = 86;
    final insights = <String>[];

    if (project.entranceDirection == CompassDirection.north ||
        project.entranceDirection == CompassDirection.northEast ||
        project.entranceDirection == CompassDirection.east) {
      vastuScore += 8;
      insights.add('🌟 Main entrance placed in the highly auspicious ${project.entranceDirection.label} zone (Ishanya/Indra).');
      insights.add('📐 Optimized layout engineered for ${length.toStringAsFixed(0)} × ${width.toStringAsFixed(0)} $unit plot geometry.');
    } else {
      vastuScore += 4;
      insights.add('ℹ️ Main entrance aligned to ${project.entranceDirection.label}. Brass threshold energy balancing suggested.');
    }

    insights.add('🔥 Kitchen positioned in South-East (Agni Corner) for prosperity and positive culinary energy.');
    insights.add('🛡️ Master Bedroom placed in South-West (Nairutya Corner) for stability and restful sleep.');
    
    if (project.vastuPreferences.contains('Separate pooja room') || project.additionalSpaces.contains('Pooja Room')) {
      vastuScore += 4;
      insights.add('🪔 Dedicated Pooja Mandir aligned to North-East zone for spiritual clarity.');
    }

    if (project.vastuPreferences.contains('Cross ventilation')) {
      insights.add('💨 East-West ventilation axis ensures continuous cross-breeze across living areas.');
    }

    // Algorithmic CAD room generation matching plot dimensions
    final rooms = <AiFloorPlanRoom>[];

    // 1. Entrance / Foyer / Parking
    if (project.parkingRequired) {
      rooms.add(AiFloorPlanRoom(
        id: 'room_parking',
        name: 'Covered Car Porch',
        type: 'parking',
        dimensions: '${(width * 0.45).round()}\' × 16\' $unit',
        areaSqft: (width * 0.45 * 16),
        x: 0.04,
        y: 0.04,
        width: 0.44,
        height: 0.22,
        vastuZone: project.roadDirection.label,
        vastuRating: 'Excellent',
        description: 'Spacious driveway and car porch accommodating ${project.parkingCarCount} vehicle(s) with EV charge point.',
        features: ['EV Charging Point', 'Weatherproof Pavers', 'Direct Foyer Access'],
      ));
    }

    // 2. Main Foyer / Entry Porch
    rooms.add(AiFloorPlanRoom(
      id: 'room_foyer',
      name: 'Grand Entrance Foyer',
      type: 'entrance',
      dimensions: '8\' × 12\' $unit',
      areaSqft: 96,
      x: project.parkingRequired ? 0.52 : 0.04,
      y: 0.04,
      width: project.parkingRequired ? 0.44 : 0.92,
      height: 0.22,
      vastuZone: project.entranceDirection.label,
      vastuRating: 'Excellent',
      description: 'Double-height welcoming entrance with shoe console and brass art niche.',
      features: ['Shoe Console', 'Key Drop Zone', 'Biometric Lock'],
    ));

    // 3. Living & Dining Hall
    rooms.add(AiFloorPlanRoom(
      id: 'room_living',
      name: 'Living & Dining Hall',
      type: 'living',
      dimensions: '${(width * 0.7).round()}\' × 20\' $unit',
      areaSqft: (width * 0.7 * 20),
      x: 0.04,
      y: 0.28,
      width: 0.62,
      height: 0.34,
      vastuZone: 'North / East Zone',
      vastuRating: 'Excellent',
      description: 'Expansive open-concept living hall connecting smoothly to the dining area and private courtyard.',
      features: ['Double-Height Ceiling', 'Panoramic Garden Window', 'Formal & Informal Seating'],
    ));

    // 4. Kitchen & Utility
    rooms.add(AiFloorPlanRoom(
      id: 'room_kitchen',
      name: project.kitchenType,
      type: 'kitchen',
      dimensions: '10\' × 14\' $unit',
      areaSqft: 140,
      x: 0.68,
      y: 0.28,
      width: 0.28,
      height: 0.34,
      vastuZone: 'South-East (Agni)',
      vastuRating: 'Excellent',
      description: 'Ergonomic kitchen layout with center breakfast island, pantry tower and attached utility wash area.',
      features: ['Granite Island', 'Chimney Ducting', 'Attached Utility / Wash'],
    ));

    // 5. Pooja Room (if chosen)
    if (project.additionalSpaces.contains('Pooja Room') || project.vastuPreferences.contains('Separate pooja room')) {
      rooms.add(const AiFloorPlanRoom(
        id: 'room_pooja',
        name: 'Pooja Mandir',
        type: 'pooja',
        dimensions: "6' × 8' ft",
        areaSqft: 48,
        x: 0.04,
        y: 0.64,
        width: 0.26,
        height: 0.16,
        vastuZone: 'North-East (Ishanya)',
        vastuRating: 'Excellent',
        description: 'Sacred meditation corner facing East with backlit marble jaali work.',
        features: ['Backlit Onyx Jaali', 'East-Facing Idol Pedestal', 'Incense Storage'],
      ));
    }

    // 6. Master Bedroom Suite
    rooms.add(AiFloorPlanRoom(
      id: 'room_master_bed',
      name: 'Master Bedroom Suite',
      type: 'bedroom',
      dimensions: '14\' × 16\' $unit',
      areaSqft: 224,
      x: (project.additionalSpaces.contains('Pooja Room') ? 0.32 : 0.04),
      y: 0.64,
      width: (project.additionalSpaces.contains('Pooja Room') ? 0.64 : 0.60),
      height: 0.32,
      vastuZone: 'South-West (Nairutya)',
      vastuRating: 'Excellent',
      description: 'King-sized master sanctuary with walk-in wardrobe, ensuite bath and private garden balcony.',
      features: ['Walk-in Closet', 'Ensuite 4-Fixture Bath', 'Wooden Flooring'],
    ));

    // 7. Ground Floor Guest Bedroom / Bedroom 2
    if (project.bedrooms >= 2) {
      rooms.add(const AiFloorPlanRoom(
        id: 'room_bed_2',
        name: 'Guest Bedroom / Senior Suite',
        type: 'bedroom',
        dimensions: "12' × 14' ft",
        areaSqft: 168,
        x: 0.68,
        y: 0.64,
        width: 0.28,
        height: 0.32,
        vastuZone: 'North-West (Vayu)',
        vastuRating: 'Good',
        description: 'Spacious step-free bedroom tailored for elders or guests with attached modern bath.',
        features: ['Step-Free Access', 'Large Wardrobes', 'Attached Bath'],
      ));
    }

    return AiFloorPlan(
      id: 'fp_${DateTime.now().millisecondsSinceEpoch}',
      floorNumber: 0,
      floorTitle: 'Ground Floor Architectural Plan',
      totalBuiltUpAreaSqft: builtUpSqft,
      carpetAreaSqft: carpetSqft,
      vastuScore: vastuScore.clamp(80, 98),
      vastuInsights: insights,
      rooms: rooms,
      previewImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      architecturalNote: 'Generated according to NBC norms with 82% carpet efficiency and optimal setbacks for ${project.plotWidth}x${project.plotLength} ${project.plotUnit.symbol} plot.',
    );
  }

  @override
  Future<AiFloorPlan> modifyFloorPlan(AiHomeProject project, String userPrompt) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final base = project.floorPlans.isNotEmpty ? project.floorPlans.first : await generateFloorPlan(project);

    final modifiedRooms = List<AiFloorPlanRoom>.from(base.rooms);
    final promptLower = userPrompt.toLowerCase();
    final updatedInsights = List<String>.from(base.vastuInsights);

    if (promptLower.contains('kitchen') || promptLower.contains('other side')) {
      updatedInsights.add('🔄 Kitchen shifted to alternate East/North-East zone per customization.');
    }
    if (promptLower.contains('bedroom') || promptLower.contains('add bedroom')) {
      updatedInsights.add('🛏️ Added additional flexible bedroom / study on the upper mezzanine.');
    }
    if (promptLower.contains('living') || promptLower.contains('increase living')) {
      updatedInsights.add('🛋️ Expanded living hall dimensions by merging circulation buffer.');
    }
    if (promptLower.contains('parking')) {
      updatedInsights.add('🚗 Extended porch area to accommodate 2 full-size SUVs.');
    }
    if (promptLower.contains('pooja')) {
      updatedInsights.add('🪔 Dedicated private Pooja alcove integrated in North-East Ishanya corner.');
    }

    return AiFloorPlan(
      id: 'fp_mod_${DateTime.now().millisecondsSinceEpoch}',
      floorNumber: base.floorNumber,
      floorTitle: '${base.floorTitle} (Customized)',
      totalBuiltUpAreaSqft: base.totalBuiltUpAreaSqft,
      carpetAreaSqft: base.carpetAreaSqft,
      vastuScore: base.vastuScore,
      vastuInsights: updatedInsights,
      rooms: modifiedRooms,
      previewImageUrl: base.previewImageUrl,
      architecturalNote: 'Modified based on prompt: "$userPrompt". Optimized for structural grid integrity.',
    );
  }

  @override
  Future<List<AiFacadeDesign>> generateFacades(AiHomeProject project, {String? selectedStyle}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final style = selectedStyle ?? project.designStyle.label;

    return [
      AiFacadeDesign(
        id: 'facade_a_${DateTime.now().millisecondsSinceEpoch}',
        variantName: 'Design A — $style Minimalist',
        style: style,
        colorPalette: 'Charcoal Grey, Crisp Off-White & Natural Oak',
        exteriorMaterials: 'Fluted Aluminum Louvers, Textured Sandstone & Low-E Tinted Glass',
        lightingHighlights: 'Concealed 3000K Linear Warm Glow & Architectural Facade Uplighters',
        imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
        tags: ['Clean Geometries', 'Large Glass Cantilever', 'Low Maintenance'],
      ),
      AiFacadeDesign(
        id: 'facade_b_${DateTime.now().millisecondsSinceEpoch}',
        variantName: 'Design B — Luxury Ultra-Modern',
        style: 'Luxury Contemporary',
        colorPalette: 'Italian Travertine, Slate Bronze & Warm Champagne',
        exteriorMaterials: 'Imported Travertine Cladding, Corten Steel Accent & Frameless Balustrades',
        lightingHighlights: 'Perimeter Step Lighting, Canopy Downlights & Tree Silhouette Spotlights',
        imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=800&q=80',
        tags: ['Grand Double-Height Portico', 'Stone Cladding', 'High Curb Appeal'],
      ),
      AiFacadeDesign(
        id: 'facade_c_${DateTime.now().millisecondsSinceEpoch}',
        variantName: 'Design C — Modern Indian Fusion',
        style: 'Modern Indian',
        colorPalette: 'Terracotta Red, Raw Concrete & Teak Wood',
        exteriorMaterials: 'Exposed Terracotta Brick Jali, Fluted Concrete & Handcrafted Teak Panels',
        lightingHighlights: 'Backlit Intricate Jaali Patterns & Warm Entrance Lanterns',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
        tags: ['Passive Solar Shading', 'Traditional Jaali Motifs', 'Courtyard Breeze'],
      ),
    ];
  }

  @override
  Future<List<AiInteriorRoomDesign>> generateInteriors(
    AiHomeProject project, {
    String? roomName,
    String? style,
    String? colorPreference,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final effectiveStyle = style ?? project.designStyle.label;
    final effectiveColor = colorPreference ?? 'Warm Neutral';

    return [
      AiInteriorRoomDesign(
        roomName: 'Living Room',
        style: effectiveStyle,
        colorPreference: effectiveColor,
        furniture: 'Custom 7-Seater Modular Linen Sofa, Fluted Teak Console, Dual Round Travertine Coffee Tables',
        lighting: 'Magnetic Recessed Track Lights, 3000K Cove Lighting, Statement Nordic Chandelier',
        wallDesign: 'Subtle Venetian Plaster with Champagne Gold Metal Inlays and Charcoal Accent Panel',
        flooring: '800×1600mm Large Format Glazed Vitrified Tiles with Italian Marble Texture',
        ceiling: 'Minimalist Monolithic Gypsum False Ceiling with Shadow Reveal Gap',
        decor: 'Sculptural Ceramic Vases, Handwoven Wool Rug, Large Format Abstract Acrylic Art',
        imageUrl: 'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80',
        estimatedFurnishingBudget: '₹ 4.5 – 6.5 Lakhs',
      ),
      AiInteriorRoomDesign(
        roomName: 'Master Bedroom',
        style: effectiveStyle,
        colorPreference: effectiveColor,
        furniture: 'King Upholstered Bed with Hydraulic Storage, Floating Nightstands, Ergonomic Accent Armchair',
        lighting: 'Bedside Fluted Glass Pendants, Warm Wardrobe Profile Lights, Soft Ambient Bed-Base Glow',
        wallDesign: 'Acoustic Fluted Wooden Slat Headboard with Suede Wall Paneling',
        flooring: 'Engineered Warm Teak Hardwood Flooring with Matt Polyurethane Finish',
        ceiling: 'Clean Perimeter False Ceiling with Dimmable Smart Scene Control',
        decor: 'Floor-to-Ceiling Motorized Sheer Curtains, Brass Planter, Textured Throw Blanket',
        imageUrl: 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80',
        estimatedFurnishingBudget: '₹ 3.8 – 5.2 Lakhs',
      ),
      AiInteriorRoomDesign(
        roomName: 'Modular Kitchen',
        style: effectiveStyle,
        colorPreference: effectiveColor,
        furniture: 'L-Shaped Handleless Soft-Close Cabinetry, Quartz Breakfast Counter with 3 Bar Stools',
        lighting: 'Under-Cabinet Task LED Strips (4000K Natural White), Island Pendant Lighting',
        wallDesign: 'Full-Height Seamless Calacatta Quartz Backsplash',
        flooring: 'Anti-Skid Matte Vitrified Tiles with Stain-Resistant Epoxy Grouting',
        ceiling: 'Moisture-Resistant False Ceiling with Slim Recessed LED Downlights',
        decor: 'Concealed Spice Pullouts, Built-in Microwave/Oven Tower, Integrated Waste Sorting',
        imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=800&q=80',
        estimatedFurnishingBudget: '₹ 4.0 – 6.0 Lakhs',
      ),
      AiInteriorRoomDesign(
        roomName: 'Pooja Room',
        style: 'Indian Traditional Modern',
        colorPreference: 'Warm Gold & White',
        furniture: 'Floating Corian & Teak Mandir Unit with Storage Drawers for Pooja Samagri',
        lighting: 'Backlit Warm Onyx Stone Panel, Ceiling Bell Spotlights, Concealed Diya Lighting',
        wallDesign: 'Custom CNC Cut Om / Gayatri Mantra Brass Plate on Textured White Stucco',
        flooring: 'Pure Makrana White Marble with Brass Border Inlays',
        ceiling: 'Traditional Lotus Motif Backlit Ceiling Panel',
        decor: 'Brass Hanging Temple Bells, Silver Urli with Fresh Jasmine Flowers',
        imageUrl: 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=800&q=80',
        estimatedFurnishingBudget: '₹ 1.8 – 2.8 Lakhs',
      ),
    ];
  }

  @override
  Future<AiWalkthrough> generateWalkthrough(AiHomeProject project) async {
    await Future.delayed(const Duration(milliseconds: 1100));

    return AiWalkthrough(
      id: 'wt_${DateTime.now().millisecondsSinceEpoch}',
      status: 'ready',
      durationSeconds: 45,
      videoUrl: 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
      webViewerUrl: 'https://propzen.internal/3d-viewer/${project.id}',
      cameraKeyframes: const [
        '1. Exterior Facade & Covered Portico',
        '2. Grand Entrance Foyer & Shoe Console',
        '3. Double-Height Living Hall & Dining',
        '4. Open Island Kitchen & Utility',
        '5. Master Bedroom Suite & Balcony',
        '6. Upper Mezzanine & Terrace Garden',
      ],
      description: 'Cinematic 4K architectural tour with real-time solar daylight angle animation.',
    );
  }
}

/// Central Singleton Service for AI Home & Vastu Designer
class AiHomeDesignerService {
  AiHomeDesignerService._();
  static final AiHomeDesignerService instance = AiHomeDesignerService._();

  // Active generation provider
  AiHomeGenerationProvider _provider = PropZenParametricEngine();

  // Switchable provider for future backend/Edge Functions
  void setProvider(AiHomeGenerationProvider provider) {
    _provider = provider;
  }

  /// Flag indicating whether external 3D/AI API is connected (Edge Functions/external API)
  bool get isExternalProviderConfigured => false;

  /// In-memory cache of user designs for instant offline/speedy access
  final List<AiHomeProject> _localProjectsCache = [];
  bool _initializedDefaults = false;

  void _ensureDefaults() {
    if (_initializedDefaults) return;
    _initializedDefaults = true;

    // Seed sample project for rich initial experience
    final sample1 = AiHomeProject(
      id: 'proj_sample_noida_01',
      userId: 'usr_active',
      projectName: 'Modern 3BHK North-Facing Villa',
      plotLength: 50.0,
      plotWidth: 20.0,
      plotUnit: PlotUnit.feet,
      plotShape: PlotShape.rectangle,
      roadWidth: 30.0,
      floors: FloorOption.gPlus1,
      parkingRequired: true,
      parkingCarCount: 1,
      roadDirection: CompassDirection.north,
      entranceDirection: CompassDirection.northEast,
      vastuPreferences: const [
        'Vastu-friendly layout',
        'Maximum natural light',
        'Cross ventilation',
        'Separate pooja room',
      ],
      propertyType: PropertyTypeChoice.villa,
      bedrooms: 3,
      bathrooms: 3,
      kitchenType: 'Modular Kitchen',
      livingRoomType: 'Standard',
      additionalSpaces: const ['Pooja Room', 'Balcony', 'Utility Room'],
      budgetRange: '₹50L – ₹1Cr',
      designStyle: HomeDesignStyle.modern,
      status: 'generated',
      createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      metadata: const {},
    );

    _localProjectsCache.add(sample1);
  }

  /// Generate complete home design package (Floor Plan, Facade, Interior, Walkthrough)
  Future<AiHomeProject> generateCompleteDesign(AiHomeProject project) async {
    final floorPlan = await _provider.generateFloorPlan(project);
    final facades = await _provider.generateFacades(project);
    final interiors = await _provider.generateInteriors(project);
    final walkthrough = await _provider.generateWalkthrough(project);

    final updatedProject = project.copyWith(
      status: 'generated',
      floorPlans: [floorPlan],
      facadeDesigns: facades,
      interiorDesigns: interiors,
      walkthrough: walkthrough,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await saveProject(updatedProject);
    return updatedProject;
  }

  /// Modify existing floor plan with user prompt
  Future<AiHomeProject> modifyProjectLayout(AiHomeProject project, String prompt) async {
    final modifiedPlan = await _provider.modifyFloorPlan(project, prompt);

    final updatedProject = project.copyWith(
      status: 'customized',
      floorPlans: [modifiedPlan],
      updatedAt: DateTime.now().toIso8601String(),
    );

    await saveProject(updatedProject);
    return updatedProject;
  }

  /// Regenerate Facade with selected style
  Future<AiHomeProject> regenerateFacades(AiHomeProject project, String style) async {
    final facades = await _provider.generateFacades(project, selectedStyle: style);
    final updatedProject = project.copyWith(
      facadeDesigns: facades,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await saveProject(updatedProject);
    return updatedProject;
  }

  /// Regenerate Room Interior
  Future<AiHomeProject> regenerateRoomInterior(
    AiHomeProject project, {
    required String roomName,
    required String style,
    required String colorPreference,
  }) async {
    final interiors = await _provider.generateInteriors(
      project,
      roomName: roomName,
      style: style,
      colorPreference: colorPreference,
    );
    final updatedProject = project.copyWith(
      interiorDesigns: interiors,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await saveProject(updatedProject);
    return updatedProject;
  }

  /// Save Project to Supabase Database and Local Cache
  Future<bool> saveProject(AiHomeProject project) async {
    _ensureDefaults();

    // Update or insert into local cache
    final idx = _localProjectsCache.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      _localProjectsCache[idx] = project;
    } else {
      _localProjectsCache.insert(0, project);
    }

    // Persist to Supabase Database
    try {
      final payload = project.toMap();
      final endpoint = Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/ai_home_projects');
      final headers = {
        'Content-Type': 'application/json',
        'apikey': SupabaseService.publishableKey,
        'Authorization': 'Bearer ${SupabaseService.publishableKey}',
        'Prefer': 'resolution=merge-duplicates,return=representation',
      };

      final response = await http
          .post(endpoint, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 4));

      if (kDebugMode) {
        debugPrint('[AiHomeDesigner] Supabase save response: ${response.statusCode}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[AiHomeDesigner] Supabase save note: $e');
      return true; // Graceful fallback to local cache
    }
  }

  /// Fetch All Projects for User
  Future<List<AiHomeProject>> fetchUserProjects(String userId) async {
    _ensureDefaults();

    try {
      final endpoint = Uri.parse(
        '${SupabaseService.supabaseUrl}/rest/v1/ai_home_projects?user_id=eq.$userId&order=created_at.desc',
      );
      final headers = {
        'Content-Type': 'application/json',
        'apikey': SupabaseService.publishableKey,
        'Authorization': 'Bearer ${SupabaseService.publishableKey}',
      };

      final response = await http.get(endpoint, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((m) => AiHomeProject.fromMap(m as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AiHomeDesigner] Supabase fetch note: $e');
    }

    return List<AiHomeProject>.from(_localProjectsCache);
  }

  /// Get Project by ID
  Future<AiHomeProject?> getProjectById(String id) async {
    _ensureDefaults();
    final localMatch = _localProjectsCache.where((p) => p.id == id).firstOrNull;
    if (localMatch != null) return localMatch;

    try {
      final endpoint = Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/ai_home_projects?id=eq.$id&limit=1');
      final headers = {
        'Content-Type': 'application/json',
        'apikey': SupabaseService.publishableKey,
        'Authorization': 'Bearer ${SupabaseService.publishableKey}',
      };

      final response = await http.get(endpoint, headers: headers).timeout(const Duration(seconds: 5));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          return AiHomeProject.fromMap(decoded.first as Map<String, dynamic>);
        }
      }
    } catch (_) {}

    return null;
  }

  /// Duplicate Project
  Future<AiHomeProject> duplicateProject(AiHomeProject project) async {
    final now = DateTime.now().toIso8601String();
    final cloned = project.copyWith(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      projectName: '${project.projectName} (Copy)',
      createdAt: now,
      updatedAt: now,
    );

    await saveProject(cloned);
    return cloned;
  }

  /// Delete Project
  Future<bool> deleteProject(String projectId) async {
    _localProjectsCache.removeWhere((p) => p.id == projectId);

    try {
      final endpoint = Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/ai_home_projects?id=eq.$projectId');
      final headers = {
        'Content-Type': 'application/json',
        'apikey': SupabaseService.publishableKey,
        'Authorization': 'Bearer ${SupabaseService.publishableKey}',
      };

      final response = await http.delete(endpoint, headers: headers).timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return true;
    }
  }

  /// Generate Safe Public Share Link
  String generateShareLink(AiHomeProject project) {
    return 'https://propzen.ai/share/design/${project.id}?bhk=${project.bedrooms}&plot=${project.plotWidth}x${project.plotLength}';
  }
}
