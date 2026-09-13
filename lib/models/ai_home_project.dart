import 'dart:convert';

/// Units of measurement for plot sizing
enum PlotUnit {
  feet('Feet', 'ft'),
  meters('Meters', 'm'),
  yards('Yards', 'sq yd');

  final String label;
  final String symbol;
  const PlotUnit(this.label, this.symbol);

  static PlotUnit fromString(String? val) {
    if (val == null) return PlotUnit.feet;
    final lower = val.toLowerCase();
    if (lower.contains('meter') || lower == 'm') return PlotUnit.meters;
    if (lower.contains('yard') || lower == 'yd') return PlotUnit.yards;
    return PlotUnit.feet;
  }
}

/// Plot shape options
enum PlotShape {
  rectangle('Rectangle', 'Standard rectangular plot'),
  square('Square', 'Equal width and length'),
  lShape('L-Shape', 'Corner or L-shaped contour'),
  custom('Custom', 'Irregular / customized contour');

  final String label;
  final String description;
  const PlotShape(this.label, this.description);

  static PlotShape fromString(String? val) {
    if (val == null) return PlotShape.rectangle;
    final lower = val.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
    if (lower.contains('square')) return PlotShape.square;
    if (lower.contains('lshape')) return PlotShape.lShape;
    if (lower.contains('custom')) return PlotShape.custom;
    return PlotShape.rectangle;
  }
}

/// Number of floors
enum FloorOption {
  ground('Ground', 'G Floor only', 1),
  gPlus1('G+1', 'Ground + 1st Floor', 2),
  gPlus2('G+2', 'Ground + 2 Floors', 3),
  gPlus3('G+3', 'Ground + 3 Floors', 4);

  final String label;
  final String description;
  final int count;
  const FloorOption(this.label, this.description, this.count);

  static FloorOption fromString(String? val) {
    if (val == null) return FloorOption.gPlus1;
    final lower = val.toLowerCase();
    if (lower == 'ground' || lower == 'g' || lower == '1') return FloorOption.ground;
    if (lower.contains('g+1') || lower.contains('g + 1') || lower == '2') return FloorOption.gPlus1;
    if (lower.contains('g+2') || lower.contains('g + 2') || lower == '3') return FloorOption.gPlus2;
    if (lower.contains('g+3') || lower.contains('g + 3') || lower == '4') return FloorOption.gPlus3;
    return FloorOption.gPlus1;
  }
}

/// Cardinal and Ordinal Directions
enum CompassDirection {
  north('N', 'North', 0, 'Kubera (Wealth & Prosperity)'),
  northEast('NE', 'North-East (Ishanya)', 45, 'Ishanya (Spiritual Energy & Clarity) - Ideal for Pooja'),
  east('E', 'East', 90, 'Indra & Surya (Health, Vitality & Fame)'),
  southEast('SE', 'South-East (Agni)', 135, 'Agni Corner (Fire Energy) - Ideal for Kitchen'),
  south('S', 'South', 180, 'Yama (Fame & Relaxation)'),
  southWest('SW', 'South-West (Nairutya)', 225, 'Nairutya (Stability & Strength) - Ideal for Master Bedroom'),
  west('W', 'West', 270, 'Varuna (Prosperity & Gains)'),
  northWest('NW', 'North-West (Vayu)', 315, 'Vayu Corner (Air & Circulation) - Ideal for Guest Room / Balcony');

  final String code;
  final String label;
  final double angleDegrees;
  final String vastuSignificance;
  const CompassDirection(this.code, this.label, this.angleDegrees, this.vastuSignificance);

  static CompassDirection fromString(String? val) {
    if (val == null) return CompassDirection.north;
    final upper = val.toUpperCase().trim();
    if (upper == 'NE' || upper.contains('NORTH-EAST') || upper.contains('NORTHEAST')) return CompassDirection.northEast;
    if (upper == 'SE' || upper.contains('SOUTH-EAST') || upper.contains('SOUTHEAST')) return CompassDirection.southEast;
    if (upper == 'SW' || upper.contains('SOUTH-WEST') || upper.contains('SOUTHWEST')) return CompassDirection.southWest;
    if (upper == 'NW' || upper.contains('NORTH-WEST') || upper.contains('NORTHWEST')) return CompassDirection.northWest;
    if (upper == 'E' || upper.contains('EAST')) return CompassDirection.east;
    if (upper == 'S' || upper.contains('SOUTH')) return CompassDirection.south;
    if (upper == 'W' || upper.contains('WEST')) return CompassDirection.west;
    return CompassDirection.north;
  }
}

/// Property Type
enum PropertyTypeChoice {
  independentHouse('Independent House', 'Standalone private residence'),
  villa('Villa', 'Luxury individual villa with garden'),
  duplex('Duplex', 'Two-floor interconnected residence'),
  farmhouse('Farmhouse', 'Expansive green lifestyle property');

  final String label;
  final String description;
  const PropertyTypeChoice(this.label, this.description);

  static PropertyTypeChoice fromString(String? val) {
    if (val == null) return PropertyTypeChoice.independentHouse;
    final lower = val.toLowerCase();
    if (lower.contains('villa')) return PropertyTypeChoice.villa;
    if (lower.contains('duplex')) return PropertyTypeChoice.duplex;
    if (lower.contains('farm')) return PropertyTypeChoice.farmhouse;
    return PropertyTypeChoice.independentHouse;
  }
}

/// Design Architectural Style
enum HomeDesignStyle {
  modern('Modern', 'Clean lines, geometric forms & ample glass'),
  luxury('Luxury', 'Grand double-height foyer, premium stone & brass accents'),
  minimalist('Minimalist', 'Clutter-free, functional flow with monochromatic tones'),
  indianTraditional('Indian Traditional', 'Jharokhas, courtyards, jaali work & warm teak wood'),
  contemporary('Contemporary', 'Harmonious blend of organic elements and smart automation'),
  modernIndian('Modern Indian', 'Fusion of traditional Indian motifs with sleek modern lines');

  final String label;
  final String description;
  const HomeDesignStyle(this.label, this.description);

  static HomeDesignStyle fromString(String? val) {
    if (val == null) return HomeDesignStyle.modern;
    final lower = val.toLowerCase();
    if (lower.contains('luxury')) return HomeDesignStyle.luxury;
    if (lower.contains('minimal')) return HomeDesignStyle.minimalist;
    if (lower.contains('traditional')) return HomeDesignStyle.indianTraditional;
    if (lower.contains('contemporary')) return HomeDesignStyle.contemporary;
    if (lower.contains('modern indian')) return HomeDesignStyle.modernIndian;
    return HomeDesignStyle.modern;
  }
}

/// Room entity within 2D Floor Plan
class AiFloorPlanRoom {
  final String id;
  final String name;
  final String type; // 'bedroom', 'living', 'kitchen', 'pooja', 'bath', 'balcony', 'parking', 'stairs'
  final String dimensions; // e.g. "14' × 16'"
  final double areaSqft;
  final double x; // Relative position 0.0 - 1.0
  final double y; // Relative position 0.0 - 1.0
  final double width; // Relative width 0.0 - 1.0
  final double height; // Relative height 0.0 - 1.0
  final String vastuZone; // e.g. "North-East (Ishanya)"
  final String vastuRating; // 'Excellent', 'Good', 'Neutral'
  final String description;
  final List<String> features;

  const AiFloorPlanRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.dimensions,
    required this.areaSqft,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.vastuZone,
    required this.vastuRating,
    required this.description,
    this.features = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'dimensions': dimensions,
        'area_sqft': areaSqft,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'vastu_zone': vastuZone,
        'vastu_rating': vastuRating,
        'description': description,
        'features': features,
      };

  factory AiFloorPlanRoom.fromMap(Map<String, dynamic> map) {
    return AiFloorPlanRoom(
      id: map['id'] ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] ?? 'Room',
      type: map['type'] ?? 'living',
      dimensions: map['dimensions'] ?? "12' × 14'",
      areaSqft: (map['area_sqft'] as num?)?.toDouble() ?? 168.0,
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      width: (map['width'] as num?)?.toDouble() ?? 0.5,
      height: (map['height'] as num?)?.toDouble() ?? 0.5,
      vastuZone: map['vastu_zone'] ?? 'North',
      vastuRating: map['vastu_rating'] ?? 'Good',
      description: map['description'] ?? '',
      features: List<String>.from(map['features'] ?? []),
    );
  }
}

/// Generated 2D Floor Plan Model
class AiFloorPlan {
  final String id;
  final int floorNumber; // 0 = Ground, 1 = 1st Floor
  final String floorTitle; // "Ground Floor Plan", "First Floor Plan"
  final double totalBuiltUpAreaSqft;
  final double carpetAreaSqft;
  final int vastuScore; // 0-100
  final List<String> vastuInsights;
  final List<AiFloorPlanRoom> rooms;
  final String? previewImageUrl;
  final String architecturalNote;

  const AiFloorPlan({
    required this.id,
    required this.floorNumber,
    required this.floorTitle,
    required this.totalBuiltUpAreaSqft,
    required this.carpetAreaSqft,
    required this.vastuScore,
    required this.vastuInsights,
    required this.rooms,
    this.previewImageUrl,
    this.architecturalNote = 'Designed with optimal cross-ventilation, natural sunlight path, and Vastu zoning.',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'floor_number': floorNumber,
        'floor_title': floorTitle,
        'total_built_up_area_sqft': totalBuiltUpAreaSqft,
        'carpet_area_sqft': carpetAreaSqft,
        'vastu_score': vastuScore,
        'vastu_insights': vastuInsights,
        'rooms': rooms.map((r) => r.toMap()).toList(),
        'preview_image_url': previewImageUrl,
        'architectural_note': architecturalNote,
      };

  factory AiFloorPlan.fromMap(Map<String, dynamic> map) {
    return AiFloorPlan(
      id: map['id'] ?? 'fp_${DateTime.now().millisecondsSinceEpoch}',
      floorNumber: map['floor_number'] ?? 0,
      floorTitle: map['floor_title'] ?? 'Ground Floor Plan',
      totalBuiltUpAreaSqft: (map['total_built_up_area_sqft'] as num?)?.toDouble() ?? 1000.0,
      carpetAreaSqft: (map['carpet_area_sqft'] as num?)?.toDouble() ?? 820.0,
      vastuScore: map['vastu_score'] ?? 92,
      vastuInsights: List<String>.from(map['vastu_insights'] ?? []),
      rooms: (map['rooms'] as List<dynamic>?)?.map((r) => AiFloorPlanRoom.fromMap(r as Map<String, dynamic>)).toList() ?? [],
      previewImageUrl: map['preview_image_url'],
      architecturalNote: map['architectural_note'] ?? '',
    );
  }
}

/// Facade Design Variant
class AiFacadeDesign {
  final String id;
  final String variantName; // "Design A (Modern Minimal)", "Design B (Contemporary Elegance)", "Design C (Modern Indian)"
  final String style;
  final String colorPalette;
  final String exteriorMaterials;
  final String lightingHighlights;
  final String? imageUrl;
  final List<String> tags;

  const AiFacadeDesign({
    required this.id,
    required this.variantName,
    required this.style,
    required this.colorPalette,
    required this.exteriorMaterials,
    required this.lightingHighlights,
    this.imageUrl,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'variant_name': variantName,
        'style': style,
        'color_palette': colorPalette,
        'exterior_materials': exteriorMaterials,
        'lighting_highlights': lightingHighlights,
        'image_url': imageUrl,
        'tags': tags,
      };

  factory AiFacadeDesign.fromMap(Map<String, dynamic> map) {
    return AiFacadeDesign(
      id: map['id'] ?? 'facade_${DateTime.now().millisecondsSinceEpoch}',
      variantName: map['variant_name'] ?? 'Design Variant',
      style: map['style'] ?? 'Modern',
      colorPalette: map['color_palette'] ?? 'Charcoal, Off-White & Warm Oak',
      exteriorMaterials: map['exterior_materials'] ?? 'Fluted Louvers, Textured Stucco, Stone Cladding',
      lightingHighlights: map['lighting_highlights'] ?? 'Recessed Warm LED Uplighters & Step Lights',
      imageUrl: map['image_url'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}

/// Interior Design Room Detail
class AiInteriorRoomDesign {
  final String roomName; // "Living Room", "Master Bedroom", "Modular Kitchen", "Pooja Room"
  final String style; // "Modern Luxury", "Minimalist Warm", "Scandinavian", etc.
  final String colorPreference; // "Neutral", "Warm", "Cool", "Earthy", "Bold"
  final String furniture;
  final String lighting;
  final String wallDesign;
  final String flooring;
  final String ceiling;
  final String decor;
  final String? imageUrl;
  final String estimatedFurnishingBudget;

  const AiInteriorRoomDesign({
    required this.roomName,
    required this.style,
    required this.colorPreference,
    required this.furniture,
    required this.lighting,
    required this.wallDesign,
    required this.flooring,
    required this.ceiling,
    required this.decor,
    this.imageUrl,
    required this.estimatedFurnishingBudget,
  });

  Map<String, dynamic> toMap() => {
        'room_name': roomName,
        'style': style,
        'color_preference': colorPreference,
        'furniture': furniture,
        'lighting': lighting,
        'wall_design': wallDesign,
        'flooring': flooring,
        'ceiling': ceiling,
        'decor': decor,
        'image_url': imageUrl,
        'estimated_furnishing_budget': estimatedFurnishingBudget,
      };

  factory AiInteriorRoomDesign.fromMap(Map<String, dynamic> map) {
    return AiInteriorRoomDesign(
      roomName: map['room_name'] ?? 'Living Room',
      style: map['style'] ?? 'Modern Luxury',
      colorPreference: map['color_preference'] ?? 'Warm Neutral',
      furniture: map['furniture'] ?? 'L-Shaped Velvet Sofa, Marble Coffee Table, Minimalist TV Console',
      lighting: map['lighting'] ?? 'Magnetic Track Lighting, 3000K Cove Lights, Statement Chandelier',
      wallDesign: map['wall_design'] ?? 'Fluted Charcoal Panels with Italian Stucco Finish',
      flooring: map['flooring'] ?? 'Italian Statuario Marble with Brass Inlays',
      ceiling: map['ceiling'] ?? 'Shadow Groove False Ceiling with Concealed Ambient LEDs',
      decor: map['decor'] ?? 'Minimal Brass Planters, Abstract Canvas Art, Sheer Drapes',
      imageUrl: map['image_url'],
      estimatedFurnishingBudget: map['estimated_furnishing_budget'] ?? '₹ 3.5 - 5.0 Lakhs',
    );
  }
}

/// Virtual Walkthrough Model
class AiWalkthrough {
  final String id;
  final String status; // 'ready', 'rendering', 'queued'
  final String? videoUrl;
  final String? webViewerUrl;
  final int durationSeconds;
  final List<String> cameraKeyframes;
  final String description;

  const AiWalkthrough({
    required this.id,
    required this.status,
    this.videoUrl,
    this.webViewerUrl,
    this.durationSeconds = 45,
    this.cameraKeyframes = const ['Main Entrance & Foyer', 'Double-Height Living Hall', 'Modern Kitchen & Dining', 'Master Suite & Balcony', 'Terrace Garden'],
    this.description = 'Cinematic 4K virtual tour sweeping across the house layout.',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'status': status,
        'video_url': videoUrl,
        'web_viewer_url': webViewerUrl,
        'duration_seconds': durationSeconds,
        'camera_keyframes': cameraKeyframes,
        'description': description,
      };

  factory AiWalkthrough.fromMap(Map<String, dynamic> map) {
    return AiWalkthrough(
      id: map['id'] ?? 'wt_${DateTime.now().millisecondsSinceEpoch}',
      status: map['status'] ?? 'ready',
      videoUrl: map['video_url'],
      webViewerUrl: map['web_viewer_url'],
      durationSeconds: map['duration_seconds'] ?? 45,
      cameraKeyframes: List<String>.from(map['camera_keyframes'] ?? ['Main Entrance', 'Living Hall', 'Kitchen', 'Master Bedroom', 'Terrace']),
      description: map['description'] ?? '',
    );
  }
}

/// Master AI Home Project Entity
class AiHomeProject {
  final String id;
  final String userId;
  final String projectName;
  
  // Step 1: Plot Details
  final double plotLength; // e.g. 50
  final double plotWidth; // e.g. 20
  final PlotUnit plotUnit; // feet, meters, yards
  final PlotShape plotShape; // rectangle, square, lShape, custom
  final double roadWidth; // e.g. 30 ft
  final FloorOption floors; // Ground, G+1, G+2, G+3
  final bool parkingRequired; // true/false
  final int parkingCarCount; // 1, 2, 3

  // Step 2: Vastu & Direction
  final CompassDirection roadDirection; // N, NE, E, SE, S, SW, W, NW
  final CompassDirection entranceDirection; // N, NE, E, SE, S, SW, W, NW
  final List<String> vastuPreferences; // list of checked vastu flags

  // Step 3: Home Requirements
  final PropertyTypeChoice propertyType; // Independent House, Villa, Duplex, Farmhouse
  final int bedrooms; // 1, 2, 3, 4, 5
  final int bathrooms; // 1, 2, 3, 4
  final String kitchenType; // 'Open Kitchen', 'Closed Kitchen', 'Modular Kitchen'
  final String livingRoomType; // 'Compact', 'Standard', 'Large', 'Luxury'
  final List<String> additionalSpaces; // ['Pooja Room', 'Home Office', 'Balcony', ...]
  final String budgetRange; // '₹30L – ₹50L', '₹50L – ₹1Cr', etc.
  final HomeDesignStyle designStyle; // Modern, Luxury, Minimalist, etc.

  // AI Generated Outputs
  final String status; // 'draft', 'generating', 'generated', 'customized'
  final List<AiFloorPlan> floorPlans;
  final List<AiFacadeDesign> facadeDesigns;
  final List<AiInteriorRoomDesign> interiorDesigns;
  final AiWalkthrough? walkthrough;

  // Metadata & Timestamps
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic> metadata;

  const AiHomeProject({
    required this.id,
    required this.userId,
    required this.projectName,
    required this.plotLength,
    required this.plotWidth,
    this.plotUnit = PlotUnit.feet,
    this.plotShape = PlotShape.rectangle,
    this.roadWidth = 30.0,
    this.floors = FloorOption.gPlus1,
    this.parkingRequired = true,
    this.parkingCarCount = 1,
    this.roadDirection = CompassDirection.north,
    this.entranceDirection = CompassDirection.northEast,
    this.vastuPreferences = const [
      'Vastu-friendly layout',
      'Maximum natural light',
      'Cross ventilation',
      'Separate pooja room',
    ],
    this.propertyType = PropertyTypeChoice.independentHouse,
    this.bedrooms = 3,
    this.bathrooms = 3,
    this.kitchenType = 'Modular Kitchen',
    this.livingRoomType = 'Standard',
    this.additionalSpaces = const ['Pooja Room', 'Balcony', 'Utility Room'],
    this.budgetRange = '₹50L – ₹1Cr',
    this.designStyle = HomeDesignStyle.modern,
    this.status = 'draft',
    this.floorPlans = const [],
    this.facadeDesigns = const [],
    this.interiorDesigns = const [],
    this.walkthrough,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Total plot area in sqft
  double get totalPlotAreaSqft {
    double factor = 1.0;
    if (plotUnit == PlotUnit.meters) factor = 10.7639;
    if (plotUnit == PlotUnit.yards) factor = 9.0;
    return (plotLength * plotWidth) * factor;
  }

  /// Formatted plot dimensions string e.g. "20 × 50 ft (1,000 sq ft)"
  String get formattedPlotDimensions {
    return '${plotWidth.toStringAsFixed(0)} × ${plotLength.toStringAsFixed(0)} ${plotUnit.symbol} (${totalPlotAreaSqft.round()} sq ft)';
  }

  /// Summary badge e.g. "3 BHK • G+1 • Modern"
  String get summaryBadge {
    return '$bedrooms BHK • ${floors.label} • ${designStyle.label}';
  }

  /// Creates a default new project with standard 20x50 ft plot
  factory AiHomeProject.defaultProject({String? userId, String? name}) {
    final now = DateTime.now().toIso8601String();
    return AiHomeProject(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId ?? 'usr_guest',
      projectName: name ?? 'My Dream Home Design',
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
      propertyType: PropertyTypeChoice.independentHouse,
      bedrooms: 3,
      bathrooms: 3,
      kitchenType: 'Modular Kitchen',
      livingRoomType: 'Standard',
      additionalSpaces: const ['Pooja Room', 'Balcony', 'Utility Room'],
      budgetRange: '₹50L – ₹1Cr',
      designStyle: HomeDesignStyle.modern,
      status: 'draft',
      floorPlans: const [],
      facadeDesigns: const [],
      interiorDesigns: const [],
      createdAt: now,
      updatedAt: now,
      metadata: const {},
    );
  }

  AiHomeProject copyWith({
    String? id,
    String? userId,
    String? projectName,
    double? plotLength,
    double? plotWidth,
    PlotUnit? plotUnit,
    PlotShape? plotShape,
    double? roadWidth,
    FloorOption? floors,
    bool? parkingRequired,
    int? parkingCarCount,
    CompassDirection? roadDirection,
    CompassDirection? entranceDirection,
    List<String>? vastuPreferences,
    PropertyTypeChoice? propertyType,
    int? bedrooms,
    int? bathrooms,
    String? kitchenType,
    String? livingRoomType,
    List<String>? additionalSpaces,
    String? budgetRange,
    HomeDesignStyle? designStyle,
    String? status,
    List<AiFloorPlan>? floorPlans,
    List<AiFacadeDesign>? facadeDesigns,
    List<AiInteriorRoomDesign>? interiorDesigns,
    AiWalkthrough? walkthrough,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AiHomeProject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectName: projectName ?? this.projectName,
      plotLength: plotLength ?? this.plotLength,
      plotWidth: plotWidth ?? this.plotWidth,
      plotUnit: plotUnit ?? this.plotUnit,
      plotShape: plotShape ?? this.plotShape,
      roadWidth: roadWidth ?? this.roadWidth,
      floors: floors ?? this.floors,
      parkingRequired: parkingRequired ?? this.parkingRequired,
      parkingCarCount: parkingCarCount ?? this.parkingCarCount,
      roadDirection: roadDirection ?? this.roadDirection,
      entranceDirection: entranceDirection ?? this.entranceDirection,
      vastuPreferences: vastuPreferences ?? this.vastuPreferences,
      propertyType: propertyType ?? this.propertyType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      kitchenType: kitchenType ?? this.kitchenType,
      livingRoomType: livingRoomType ?? this.livingRoomType,
      additionalSpaces: additionalSpaces ?? this.additionalSpaces,
      budgetRange: budgetRange ?? this.budgetRange,
      designStyle: designStyle ?? this.designStyle,
      status: status ?? this.status,
      floorPlans: floorPlans ?? this.floorPlans,
      facadeDesigns: facadeDesigns ?? this.facadeDesigns,
      interiorDesigns: interiorDesigns ?? this.interiorDesigns,
      walkthrough: walkthrough ?? this.walkthrough,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'project_name': projectName,
        'plot_length': plotLength,
        'plot_width': plotWidth,
        'plot_unit': plotUnit.name,
        'plot_shape': plotShape.name,
        'road_width': roadWidth,
        'road_direction': roadDirection.code,
        'entrance_direction': entranceDirection.code,
        'floors': floors.label,
        'parking': parkingRequired ? 'Yes ($parkingCarCount Car${parkingCarCount > 1 ? 's' : ''})' : 'No',
        'property_type': propertyType.label,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'kitchen_type': kitchenType,
        'budget': budgetRange,
        'design_style': designStyle.label,
        'vastu_preferences': vastuPreferences,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'metadata': {
          ...metadata,
          'living_room_type': livingRoomType,
          'additional_spaces': additionalSpaces,
          'parking_car_count': parkingCarCount,
          'floor_plans': floorPlans.map((f) => f.toMap()).toList(),
          'facade_designs': facadeDesigns.map((f) => f.toMap()).toList(),
          'interior_designs': interiorDesigns.map((i) => i.toMap()).toList(),
          if (walkthrough != null) 'walkthrough': walkthrough!.toMap(),
        },
      };

  factory AiHomeProject.fromMap(Map<String, dynamic> map) {
    final meta = map['metadata'] is Map<String, dynamic> ? (map['metadata'] as Map<String, dynamic>) : <String, dynamic>{};

    final fps = meta['floor_plans'] as List<dynamic>?;
    final fcs = meta['facade_designs'] as List<dynamic>?;
    final ints = meta['interior_designs'] as List<dynamic>?;
    final wtMap = meta['walkthrough'] as Map<String, dynamic>?;

    return AiHomeProject(
      id: map['id'] ?? 'proj_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id'] ?? 'usr_guest',
      projectName: map['project_name'] ?? 'My Home Design',
      plotLength: (map['plot_length'] as num?)?.toDouble() ?? 50.0,
      plotWidth: (map['plot_width'] as num?)?.toDouble() ?? 20.0,
      plotUnit: PlotUnit.fromString(map['plot_unit'] as String?),
      plotShape: PlotShape.fromString(map['plot_shape'] as String?),
      roadWidth: (map['road_width'] as num?)?.toDouble() ?? 30.0,
      floors: FloorOption.fromString(map['floors'] as String?),
      parkingRequired: (map['parking'] as String?)?.toLowerCase().startsWith('n') == true ? false : true,
      parkingCarCount: (meta['parking_car_count'] as num?)?.toInt() ?? 1,
      roadDirection: CompassDirection.fromString(map['road_direction'] as String?),
      entranceDirection: CompassDirection.fromString(map['entrance_direction'] as String?),
      vastuPreferences: List<String>.from(map['vastu_preferences'] ?? []),
      propertyType: PropertyTypeChoice.fromString(map['property_type'] as String?),
      bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 3,
      bathrooms: (map['bathrooms'] as num?)?.toInt() ?? 3,
      kitchenType: map['kitchen_type'] ?? 'Modular Kitchen',
      livingRoomType: meta['living_room_type'] ?? 'Standard',
      additionalSpaces: List<String>.from(meta['additional_spaces'] ?? ['Pooja Room', 'Balcony']),
      budgetRange: map['budget'] ?? '₹50L – ₹1Cr',
      designStyle: HomeDesignStyle.fromString(map['design_style'] as String?),
      status: map['status'] ?? 'draft',
      floorPlans: fps?.map((f) => AiFloorPlan.fromMap(f as Map<String, dynamic>)).toList() ?? [],
      facadeDesigns: fcs?.map((f) => AiFacadeDesign.fromMap(f as Map<String, dynamic>)).toList() ?? [],
      interiorDesigns: ints?.map((i) => AiInteriorRoomDesign.fromMap(i as Map<String, dynamic>)).toList() ?? [],
      walkthrough: wtMap != null ? AiWalkthrough.fromMap(wtMap) : null,
      createdAt: map['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] ?? DateTime.now().toIso8601String(),
      metadata: meta,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AiHomeProject.fromJson(String source) => AiHomeProject.fromMap(jsonDecode(source));
}
