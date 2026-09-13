/// 360° Virtual Tour Room Node
class VirtualTourRoom {
  final String id; // e.g. 'living-room', 'master-suite', 'balcony-deck', 'kitchen'
  final String name; // e.g. 'Living & Dining Hall', 'Master Suite'
  final String imageUrl; // High-res equirectangular 360 panoramic image URL for THIS room
  final String area; // e.g. '320 sq.ft.'
  final String? panoramaEmbedUrl; // Optional room-specific Kuula/Matterport embed node
  final String iconType; // 'sofa', 'bed', 'sun', 'utensils', 'bath', 'compass'

  const VirtualTourRoom({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.area = '',
    this.panoramaEmbedUrl,
    this.iconType = 'sofa',
  });

  bool get hasValidImage => imageUrl.trim().isNotEmpty && (imageUrl.startsWith('http://') || imageUrl.startsWith('https://') || imageUrl.startsWith('assets/'));

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'area': area,
        'panorama_embed_url': panoramaEmbedUrl,
        'icon_type': iconType,
      };

  factory VirtualTourRoom.fromMap(Map<String, dynamic> map) => VirtualTourRoom(
        id: map['id']?.toString() ?? 'room-${DateTime.now().millisecondsSinceEpoch}',
        name: map['name']?.toString() ?? 'Room View',
        imageUrl: map['image_url']?.toString() ?? map['imageUrl']?.toString() ?? '',
        area: map['area']?.toString() ?? '',
        panoramaEmbedUrl: map['panorama_embed_url']?.toString() ?? map['panoramaEmbedUrl']?.toString(),
        iconType: map['icon_type']?.toString() ?? map['iconType']?.toString() ?? 'sofa',
      );
}

/// 360° Virtual Tour Data Model
class VirtualTourData {
  final String? panoramaUrl; // Main 360 tour URL or web viewer URL
  final String provider; // 'kuula', 'matterport', 'custom_360', 'panoramic_image'
  final String title;
  final bool isAvailable;
  final List<VirtualTourRoom> rooms;
  final String? previewThumbnail;

  const VirtualTourData({
    this.panoramaUrl,
    this.provider = 'kuula',
    this.title = '360° Virtual Tour',
    this.isAvailable = true,
    this.rooms = const [],
    this.previewThumbnail,
  });

  String get url => panoramaUrl ?? (rooms.isNotEmpty ? rooms.first.imageUrl : '');

  bool get hasValidUrl => (panoramaUrl != null && panoramaUrl!.trim().isNotEmpty) || rooms.any((r) => r.hasValidImage);

  VirtualTourRoom? get initialRoom => rooms.isNotEmpty ? rooms.first : null;

  Map<String, dynamic> toMap() => {
        'panorama_url': panoramaUrl,
        'url': panoramaUrl,
        'provider': provider,
        'title': title,
        'is_available': isAvailable,
        'rooms': rooms.map((r) => r.toMap()).toList(),
        'preview_thumbnail': previewThumbnail,
      };

  factory VirtualTourData.fromMap(Map<String, dynamic> map) {
    final rawRooms = map['rooms'] as List<dynamic>? ?? [];
    return VirtualTourData(
      panoramaUrl: map['panorama_url']?.toString() ?? map['url']?.toString(),
      provider: map['provider']?.toString() ?? 'kuula',
      title: map['title']?.toString() ?? '360° Virtual Tour',
      isAvailable: map['is_available'] == true || map['isAvailable'] == true || map['enabled'] == true,
      rooms: rawRooms.map((r) => VirtualTourRoom.fromMap(r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r as Map))).toList(),
      previewThumbnail: map['preview_thumbnail']?.toString() ?? map['previewThumbnail']?.toString(),
    );
  }
}

/// Interactive 3D Model Data Model
class Model3DData {
  final String? modelId; // e.g. Sketchfab model UID
  final String? embedUrl; // Embed URL or iframe source
  final String? directModelUrl; // GLB/GLTF/USDZ file
  final String provider; // 'sketchfab', 'google_model_viewer', 'three_js', 'webgl'
  final String title;
  final bool isAvailable;
  final String? thumbnail;

  const Model3DData({
    this.modelId,
    this.embedUrl,
    this.directModelUrl,
    this.provider = 'sketchfab',
    this.title = 'Interactive 3D Model',
    this.isAvailable = true,
    this.thumbnail,
  });

  bool get hasValidModel => (modelId != null && modelId!.trim().isNotEmpty) || (embedUrl != null && embedUrl!.trim().isNotEmpty);

  Map<String, dynamic> toMap() => {
        'model_id': modelId,
        'embed_url': embedUrl,
        'direct_model_url': directModelUrl,
        'provider': provider,
        'title': title,
        'is_available': isAvailable,
        'thumbnail': thumbnail,
      };

  factory Model3DData.fromMap(Map<String, dynamic> map) => Model3DData(
        modelId: map['model_id']?.toString() ?? map['modelId']?.toString(),
        embedUrl: map['embed_url']?.toString() ?? map['embedUrl']?.toString(),
        directModelUrl: map['direct_model_url']?.toString() ?? map['directModelUrl']?.toString(),
        provider: map['provider']?.toString() ?? 'sketchfab',
        title: map['title']?.toString() ?? 'Interactive 3D Model',
        isAvailable: map['is_available'] == true || map['isAvailable'] == true,
        thumbnail: map['thumbnail']?.toString(),
      );
}

/// AR (Augmented Reality) Property / Plot Visualization Data
class ArModelData {
  final String? glbUrl;
  final String? usdzUrl;
  final String title;
  final double defaultScale;
  final bool isAvailable;

  const ArModelData({
    this.glbUrl,
    this.usdzUrl,
    this.title = 'AR Property Visualization',
    this.defaultScale = 1.0,
    this.isAvailable = true,
  });

  bool get hasValidArAsset => (glbUrl != null && glbUrl!.isNotEmpty) || (usdzUrl != null && usdzUrl!.isNotEmpty);

  Map<String, dynamic> toMap() => {
        'glb_url': glbUrl,
        'usdz_url': usdzUrl,
        'title': title,
        'default_scale': defaultScale,
        'is_available': isAvailable,
      };

  factory ArModelData.fromMap(Map<String, dynamic> map) => ArModelData(
        glbUrl: map['glb_url']?.toString() ?? map['glbUrl']?.toString(),
        usdzUrl: map['usdz_url']?.toString() ?? map['usdzUrl']?.toString(),
        title: map['title']?.toString() ?? 'AR Property Visualization',
        defaultScale: (map['default_scale'] as num?)?.toDouble() ?? 1.0,
        isAvailable: map['is_available'] == true || map['isAvailable'] == true,
      );
}

/// Individual Room Floor Plan Specification
class FloorPlanRoom {
  final String name;
  final String roomType; // 'livingRoom', 'masterBedroom', 'bedroom', 'kitchen', 'bathroom', 'balcony', 'utility'
  final int areaSqFt;
  final String dimensions; // e.g. "14'0\" x 18'6\""
  final String floorLevel;
  final List<String> features;

  const FloorPlanRoom({
    required this.name,
    required this.roomType,
    required this.areaSqFt,
    required this.dimensions,
    this.floorLevel = 'Ground / Main Level',
    this.features = const [],
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'room_type': roomType,
        'area_sqft': areaSqFt,
        'dimensions': dimensions,
        'floor_level': floorLevel,
        'features': features,
      };

  factory FloorPlanRoom.fromMap(Map<String, dynamic> map) => FloorPlanRoom(
        name: map['name']?.toString() ?? 'Room',
        roomType: map['room_type']?.toString() ?? map['roomType']?.toString() ?? 'bedroom',
        areaSqFt: (map['area_sqft'] as num?)?.toInt() ?? (map['areaSqFt'] as num?)?.toInt() ?? 150,
        dimensions: map['dimensions']?.toString() ?? '12\'0" x 14\'0"',
        floorLevel: map['floor_level']?.toString() ?? map['floorLevel']?.toString() ?? 'Main Level',
        features: (map['features'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

/// Interactive Floor Plan Suite Data
class FloorPlanData {
  final String? floorPlan2DUrl;
  final String? floorPlan3DUrl;
  final int totalAreaSqFt;
  final int carpetAreaSqFt;
  final List<FloorPlanRoom> rooms;
  final List<String> keyHighlights;

  const FloorPlanData({
    this.floorPlan2DUrl,
    this.floorPlan3DUrl,
    required this.totalAreaSqFt,
    required this.carpetAreaSqFt,
    this.rooms = const [],
    this.keyHighlights = const [],
  });

  Map<String, dynamic> toMap() => {
        'floor_plan_2d_url': floorPlan2DUrl,
        'floor_plan_3d_url': floorPlan3DUrl,
        'total_area_sqft': totalAreaSqFt,
        'carpet_area_sqft': carpetAreaSqFt,
        'rooms': rooms.map((r) => r.toMap()).toList(),
        'key_highlights': keyHighlights,
      };

  factory FloorPlanData.fromMap(Map<String, dynamic> map) => FloorPlanData(
        floorPlan2DUrl: map['floor_plan_2d_url']?.toString() ?? map['floorPlan2DUrl']?.toString() ?? map['floor_plan_url']?.toString(),
        floorPlan3DUrl: map['floor_plan_3d_url']?.toString() ?? map['floorPlan3DUrl']?.toString(),
        totalAreaSqFt: (map['total_area_sqft'] as num?)?.toInt() ?? (map['totalAreaSqFt'] as num?)?.toInt() ?? 1500,
        carpetAreaSqFt: (map['carpet_area_sqft'] as num?)?.toInt() ?? (map['carpetAreaSqFt'] as num?)?.toInt() ?? 1150,
        rooms: (map['rooms'] as List?)?.map((r) => FloorPlanRoom.fromMap(r as Map<String, dynamic>)).toList() ?? const [],
        keyHighlights: (map['key_highlights'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

/// Interior Visualization Options
class InteriorConcept {
  final String roomName;
  final String roomType; // 'livingRoom', 'masterBedroom', 'kitchen', 'bathroom', 'balcony'
  final String previewImage;
  final List<String> wallColors;
  final List<String> flooringOptions;
  final List<String> furnitureStyles;
  final List<String> lightingConcepts;
  final List<String> finishMaterials;

  const InteriorConcept({
    required this.roomName,
    required this.roomType,
    required this.previewImage,
    this.wallColors = const ['Alabaster White', 'Warm Greige', 'Sage Green', 'Royal Navy', 'Champagne Beige'],
    this.flooringOptions = const ['Italian Botticino Marble', 'Herringbone Hardwood', 'Matte Vitrified 1200x600', 'Polished Terrazzo'],
    this.furnitureStyles = const ['Contemporary Minimalist', 'Modern Scandinavian', 'Luxury Velvet & Brass', 'Art Deco Classical'],
    this.lightingConcepts = const ['Warm Cove Ambient (2700K)', 'Architectural Magnetic Track', 'Sculptural Chandelier Accent', 'Recessed Downlight Grid'],
    this.finishMaterials = const ['Fluted Oak Wood Panels', 'Brushed Brass Metalwork', 'Calacatta Quartz Countertops', 'Textured Linen Drapery'],
  });

  Map<String, dynamic> toMap() => {
        'room_name': roomName,
        'room_type': roomType,
        'preview_image': previewImage,
        'wall_colors': wallColors,
        'flooring_options': flooringOptions,
        'furniture_styles': furnitureStyles,
        'lighting_concepts': lightingConcepts,
        'finish_materials': finishMaterials,
      };

  factory InteriorConcept.fromMap(Map<String, dynamic> map) => InteriorConcept(
        roomName: map['room_name']?.toString() ?? map['roomName']?.toString() ?? 'Living Area',
        roomType: map['room_type']?.toString() ?? map['roomType']?.toString() ?? 'livingRoom',
        previewImage: map['preview_image']?.toString() ?? map['previewImage']?.toString() ?? '',
        wallColors: (map['wall_colors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        flooringOptions: (map['flooring_options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        furnitureStyles: (map['furniture_styles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        lightingConcepts: (map['lighting_concepts'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        finishMaterials: (map['finish_materials'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

/// Exterior Design Visualization Options
class ExteriorConcept {
  final String styleName; // 'Modern', 'Contemporary', 'Minimal', 'Luxury'
  final String facadeMaterial;
  final String exteriorColor;
  final String lightingConcept;
  final String landscapingConcept;
  final String previewImage;

  const ExteriorConcept({
    required this.styleName,
    required this.facadeMaterial,
    required this.exteriorColor,
    required this.lightingConcept,
    required this.landscapingConcept,
    required this.previewImage,
  });

  Map<String, dynamic> toMap() => {
        'style_name': styleName,
        'facade_material': facadeMaterial,
        'exterior_color': exteriorColor,
        'lighting_concept': lightingConcept,
        'landscaping_concept': landscapingConcept,
        'preview_image': previewImage,
      };

  factory ExteriorConcept.fromMap(Map<String, dynamic> map) => ExteriorConcept(
        styleName: map['style_name']?.toString() ?? map['styleName']?.toString() ?? 'Modern',
        facadeMaterial: map['facade_material']?.toString() ?? map['facadeMaterial']?.toString() ?? 'Terracotta Louvers & Glass',
        exteriorColor: map['exterior_color']?.toString() ?? map['exteriorColor']?.toString() ?? 'Charcoal Gray & Warm White',
        lightingConcept: map['lighting_concept']?.toString() ?? map['lightingConcept']?.toString() ?? 'Linear Facade Grazers (3000K)',
        landscapingConcept: map['landscaping_concept']?.toString() ?? map['landscapingConcept']?.toString() ?? 'Lush Zen Garden with Water Cascade',
        previewImage: map['preview_image']?.toString() ?? map['previewImage']?.toString() ?? '',
      );
}

/// Vastu Room Guidance Item
class VastuRoomItem {
  final String room;
  final String actualDirection;
  final String idealDirection;
  final String status; // 'Optimal', 'Favorable', 'Neutral', 'Attention Needed'
  final String note;

  const VastuRoomItem({
    required this.room,
    required this.actualDirection,
    required this.idealDirection,
    required this.status,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'room': room,
        'actual_direction': actualDirection,
        'ideal_direction': idealDirection,
        'status': status,
        'note': note,
      };

  factory VastuRoomItem.fromMap(Map<String, dynamic> map) => VastuRoomItem(
        room: map['room']?.toString() ?? 'Room',
        actualDirection: map['actual_direction']?.toString() ?? map['actualDirection']?.toString() ?? 'North',
        idealDirection: map['ideal_direction']?.toString() ?? map['idealDirection']?.toString() ?? 'North-East',
        status: map['status']?.toString() ?? 'Optimal',
        note: map['note']?.toString() ?? 'Well-aligned with traditional natural light and air flow principles.',
      );
}

/// Vastu Guidance Suite Data
class VastuGuidanceData {
  final String facingDirection; // 'North', 'East', 'North-East', 'North-West', 'South', 'West', 'South-East', 'South-West'
  final int overallScore; // e.g. 88 / 100
  final String entranceDirection;
  final String kitchenDirection;
  final String masterBedroomDirection;
  final String livingAreaDirection;
  final String balconyDirection;
  final String toiletDirection;
  final List<VastuRoomItem> roomDetails;
  final List<String> keyObservations;
  final String informationalDisclaimer;

  const VastuGuidanceData({
    required this.facingDirection,
    this.overallScore = 88,
    required this.entranceDirection,
    required this.kitchenDirection,
    required this.masterBedroomDirection,
    required this.livingAreaDirection,
    required this.balconyDirection,
    required this.toiletDirection,
    this.roomDetails = const [],
    this.keyObservations = const [],
    this.informationalDisclaimer =
        'Disclaimer: This analysis provides traditional Vastu-based informational guidance and natural sunlight orientation considerations. It is not scientific or legal advice.',
  });

  Map<String, dynamic> toMap() => {
        'facing_direction': facingDirection,
        'overall_score': overallScore,
        'entrance_direction': entranceDirection,
        'kitchen_direction': kitchenDirection,
        'master_bedroom_direction': masterBedroomDirection,
        'living_area_direction': livingAreaDirection,
        'balcony_direction': balconyDirection,
        'toilet_direction': toiletDirection,
        'room_details': roomDetails.map((r) => r.toMap()).toList(),
        'key_observations': keyObservations,
        'informational_disclaimer': informationalDisclaimer,
      };

  factory VastuGuidanceData.fromMap(Map<String, dynamic> map) => VastuGuidanceData(
        facingDirection: map['facing_direction']?.toString() ?? map['facingDirection']?.toString() ?? 'North-East',
        overallScore: (map['overall_score'] as num?)?.toInt() ?? (map['overallScore'] as num?)?.toInt() ?? 88,
        entranceDirection: map['entrance_direction']?.toString() ?? map['entranceDirection']?.toString() ?? 'North-East',
        kitchenDirection: map['kitchen_direction']?.toString() ?? map['kitchenDirection']?.toString() ?? 'South-East',
        masterBedroomDirection: map['master_bedroom_direction']?.toString() ?? map['masterBedroomDirection']?.toString() ?? 'South-West',
        livingAreaDirection: map['living_area_direction']?.toString() ?? map['livingAreaDirection']?.toString() ?? 'North / East',
        balconyDirection: map['balcony_direction']?.toString() ?? map['balconyDirection']?.toString() ?? 'East Facing',
        toiletDirection: map['toilet_direction']?.toString() ?? map['toiletDirection']?.toString() ?? 'North-West',
        roomDetails: (map['room_details'] as List?)?.map((r) => VastuRoomItem.fromMap(r as Map<String, dynamic>)).toList() ?? const [],
        keyObservations: (map['key_observations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        informationalDisclaimer: map['informational_disclaimer']?.toString() ??
            'Disclaimer: This analysis provides traditional Vastu-based informational guidance and natural sunlight orientation considerations. It is not scientific or legal advice.',
      );
}
