import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../models/property_visualization_model.dart';
import 'ar_capability_helper.dart';

class PropertyVisualizationService {
  PropertyVisualizationService._();
  static final PropertyVisualizationService instance = PropertyVisualizationService._();

  // Active analytics logs in session
  final List<Map<String, dynamic>> _analyticsEvents = [];
  List<Map<String, dynamic>> get analyticsEvents => List.unmodifiable(_analyticsEvents);

  /// 1. Log Visualization Analytics Event
  void logVisualizationEvent({
    required String eventName,
    required String propertyId,
    required String propertyTitle,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? extraData,
  }) {
    _analyticsEvents.add({
      'eventName': eventName,
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': parameters ?? extraData ?? {},
    });
    if (kDebugMode) {
      print('[Visualization Analytics] $eventName -> $propertyTitle ($propertyId)');
    }
  }

  /// 2. Format Kuula / 360 Tour Embed URL with fullscreen, VR, and clean UI parameters
  String format360TourEmbedUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.contains('kuula.co')) {
      if (!trimmed.contains('logo=')) {
        final separator = trimmed.contains('?') ? '&' : '?';
        return '$trimmed${separator}logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1';
      }
      return trimmed;
    }

    if (trimmed.contains('matterport.com')) {
      if (!trimmed.contains('play=')) {
        final separator = trimmed.contains('?') ? '&' : '?';
        return '$trimmed${separator}play=1&qs=1&brand=0&title=0';
      }
      return trimmed;
    }

    return trimmed;
  }

  /// 3. Format Sketchfab 3D Embed URL
  String formatSketchfabEmbedUrl({String? modelId, String? rawUrl}) {
    if (modelId != null && modelId.trim().isNotEmpty) {
      return 'https://sketchfab.com/models/${modelId.trim()}/embed?autostart=1&internal=1&tracking=0&ui_infos=0&ui_watermark_link=0&ui_watermark=0&ui_animations=1&ui_controls=1';
    }

    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      final trimmed = rawUrl.trim();
      if (trimmed.contains('sketchfab.com') && !trimmed.contains('/embed')) {
        return '${trimmed.replaceAll('/3d-models/', '/models/')}/embed?autostart=1&internal=1&tracking=0&ui_infos=0&ui_watermark_link=0';
      }
      return trimmed;
    }

    return '';
  }

  /// Check if a model URL is an external demo, test, or unsafe URL.
  /// PropZen must NEVER use demo models (Astronaut, chair, robot) or modelviewer.dev links.
  static bool isDemoOrUnsafeModelUrl(String? url) {
    if (url == null || url.trim().isEmpty) return true;
    final lower = url.trim().toLowerCase();
    return lower.contains('modelviewer.dev') ||
        lower.contains('googlechromelabs.github.io') ||
        lower.contains('astronaut.glb') ||
        lower.contains('neilarmstrong') ||
        lower.contains('chair') ||
        lower.contains('robot') ||
        lower.contains('sample_object');
  }

  /// Whether the property has a valid, non-demo AR model available
  bool hasValidArModel(Property property) {
    final url = property.arModelUrl;
    return url != null && url.trim().isNotEmpty && !isDemoOrUnsafeModelUrl(url);
  }

  /// 4. Generate Google SceneViewer / Native AR Intent URL
  /// Strictly NO external demo/example URLs (such as modelviewer.dev).
  /// Never returns intent:// on web browsers to prevent opening blank tabs or protocol errors.
  String generateArLaunchUrl({
    required String glbUrl,
    required String propertyTitle,
    String? usdzUrl,
  }) {
    if (isDemoOrUnsafeModelUrl(glbUrl)) {
      return '';
    }

    // Web browsers must never navigate to intent:// or external demo URLs.
    // They remain within PropZen and display the in-app AR/3D viewer.
    if (kIsWeb) {
      return '';
    }

    // Native Android SceneViewer Intent (for Android native app only)
    final isNativeAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (isNativeAndroid) {
      return 'intent://arvr.google.com/scene-viewer/1.0?file=${Uri.encodeComponent(glbUrl)}&mode=ar_preferred&title=${Uri.encodeComponent(propertyTitle)}#Intent;scheme=https;package=com.google.android.googlequicksearchbox;action=android.intent.action.VIEW;end;';
    }

    // Native iOS AR QuickLook (for iOS native app with USDZ)
    final isNativeIOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (isNativeIOS && usdzUrl != null && usdzUrl.trim().isNotEmpty && !isDemoOrUnsafeModelUrl(usdzUrl)) {
      return usdzUrl.trim();
    }

    return '';
  }

  /// 5. Check if AR room placement is supported on the current device.
  /// Requires mobile device with camera capability. Desktop browsers return false.
  bool isArSupportedOnCurrentDevice() {
    return ArCapabilityHelper.isArSupported();
  }

  /// 6. Generate Property-Specific Vastu Guidance dynamically based on facing
  VastuGuidanceData generateVastuForProperty(Property property) {
    final facingNorm = property.facing.trim().toLowerCase();

    if (facingNorm.contains('north-east') || facingNorm.contains('northeast')) {
      return const VastuGuidanceData(
        facingDirection: 'North-East (Ishanya)',
        overallScore: 92,
        entranceDirection: 'North-East (Ishanya Corner)',
        kitchenDirection: 'South-East (Agneya Corner)',
        masterBedroomDirection: 'South-West (Nairutya Corner)',
        livingAreaDirection: 'North / East Facing',
        balconyDirection: 'East Facing (Morning Sun)',
        toiletDirection: 'North-West (Vayavya Corner)',
        keyObservations: [
          'Main entrance faces North-East (Ishan Corner), maximizing morning natural light and positive cross-breeze.',
          'Kitchen positioned in South-East (Agneya Corner) for optimal energy and ventilation circulation.',
          'Master Bedroom located in South-West stability zone for peaceful living.',
          'Large East-facing panoramic balcony provides abundant natural sunlight throughout morning hours.',
        ],
        roomDetails: [
          VastuRoomItem(room: 'Main Entrance', actualDirection: 'North-East', idealDirection: 'North-East', status: 'Optimal', note: 'Ishan corner entrance allows abundant sunrise illumination.'),
          VastuRoomItem(room: 'Kitchen', actualDirection: 'South-East', idealDirection: 'South-East', status: 'Optimal', note: 'Agneya fire element placement aligns with natural air currents.'),
          VastuRoomItem(room: 'Master Bedroom', actualDirection: 'South-West', idealDirection: 'South-West', status: 'Optimal', note: 'Nairutya earth element placement ensures privacy and tranquility.'),
          VastuRoomItem(room: 'Living Room', actualDirection: 'North-East', idealDirection: 'North-East / East', status: 'Favorable', note: 'Spacious central hub welcomes cross-ventilation.'),
          VastuRoomItem(room: 'Balcony', actualDirection: 'East', idealDirection: 'East / North', status: 'Optimal', note: 'East facing orientation provides refreshing morning sunlight.'),
          VastuRoomItem(room: 'Washroom / Toilets', actualDirection: 'North-West', idealDirection: 'North-West / West', status: 'Favorable', note: 'Vayavya wind direction placement keeps primary living spaces fresh.'),
        ],
      );
    }

    if (facingNorm.contains('east')) {
      return const VastuGuidanceData(
        facingDirection: 'East (Indra)',
        overallScore: 88,
        entranceDirection: 'East Facing',
        kitchenDirection: 'South-East (Agneya)',
        masterBedroomDirection: 'South-West (Nairutya)',
        livingAreaDirection: 'East / North-East',
        balconyDirection: 'East Facing',
        toiletDirection: 'North-West',
        keyObservations: [
          'Direct East-facing entrance welcomes natural morning sunlight.',
          'Balcony positioned to capture dawn breezes and natural daylight.',
          'South-West master bedroom ensures structural stability and sound sleep.',
        ],
        roomDetails: [
          VastuRoomItem(room: 'Main Entrance', actualDirection: 'East', idealDirection: 'East / North-East', status: 'Optimal', note: 'Welcomes early morning sun rays.'),
          VastuRoomItem(room: 'Kitchen', actualDirection: 'South-East', idealDirection: 'South-East', status: 'Optimal', note: 'Fire element correctly aligned.'),
          VastuRoomItem(room: 'Master Bedroom', actualDirection: 'South-West', idealDirection: 'South-West', status: 'Optimal', note: 'South-West earth stability.'),
          VastuRoomItem(room: 'Living Area', actualDirection: 'East', idealDirection: 'East', status: 'Favorable', note: 'Bright social zone.'),
          VastuRoomItem(room: 'Balcony', actualDirection: 'East', idealDirection: 'East', status: 'Optimal', note: 'Excellent morning illumination.'),
        ],
      );
    }

    if (facingNorm.contains('north')) {
      return const VastuGuidanceData(
        facingDirection: 'North (Kuber)',
        overallScore: 86,
        entranceDirection: 'North Facing',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'North / North-East',
        balconyDirection: 'North Facing',
        toiletDirection: 'North-West',
        keyObservations: [
          'North entrance aligned with Kuber financial prosperity zone and soft indirect daylight.',
          'Living space enjoys glare-free northern lighting throughout the afternoon.',
          'Kitchen in South-East prevents cooking heat from entering living quarters.',
        ],
        roomDetails: [
          VastuRoomItem(room: 'Main Entrance', actualDirection: 'North', idealDirection: 'North / North-East', status: 'Optimal', note: 'Kuber prosperity zone with cool daylight.'),
          VastuRoomItem(room: 'Kitchen', actualDirection: 'South-East', idealDirection: 'South-East', status: 'Optimal', note: 'Agneya quadrant ensures proper ventilation.'),
          VastuRoomItem(room: 'Master Bedroom', actualDirection: 'South-West', idealDirection: 'South-West', status: 'Optimal', note: 'Nairutya stability quadrant.'),
          VastuRoomItem(room: 'Living Area', actualDirection: 'North', idealDirection: 'North', status: 'Favorable', note: 'Pleasant daylight without harsh heat.'),
        ],
      );
    }

    // Default Vastu Guidance for Other Directions (West / South / Mixed)
    return VastuGuidanceData(
      facingDirection: property.facing.isNotEmpty ? property.facing : 'North-East',
      overallScore: 84,
      entranceDirection: '${property.facing} Entrance',
      kitchenDirection: 'South-East',
      masterBedroomDirection: 'South-West',
      livingAreaDirection: 'Central Foyer',
      balconyDirection: '${property.facing} Balcony',
      toiletDirection: 'North-West',
      keyObservations: [
        'Optimized room zoning provides balanced daylight distribution across bedrooms and living area.',
        'Bedrooms positioned away from high-traffic entrance for maximum privacy and noise isolation.',
        'Cross-ventilation between opposite windows ensures continuous fresh air circulation.',
      ],
      roomDetails: const [
        VastuRoomItem(room: 'Main Entrance', actualDirection: 'Main Corridor', idealDirection: 'North-East / East', status: 'Favorable', note: 'Functional entrance foyer with privacy buffer.'),
        VastuRoomItem(room: 'Kitchen', actualDirection: 'South-East', idealDirection: 'South-East', status: 'Optimal', note: 'Agneya fire quadrant with external utility balcony.'),
        VastuRoomItem(room: 'Master Bedroom', actualDirection: 'South-West', idealDirection: 'South-West', status: 'Optimal', note: 'Peaceful rear placement ensuring restful sleep.'),
        VastuRoomItem(room: 'Living Area', actualDirection: 'Central', idealDirection: 'East / North', status: 'Favorable', note: 'Spacious central hub connecting all rooms.'),
      ],
    );
  }

  /// 7. Generate WhatsApp Sharing message for visualizations
  String generateWhatsAppShareText({
    required Property property,
    required String visualizationType,
    String? roomName,
  }) {
    final title = property.title;
    final location = '${property.sector}, ${property.city}';
    final price = property.priceRangeDisplay;

    switch (visualizationType) {
      case '360_tour':
        final tourUrl = property.virtualTour?.panoramaUrl ?? property.virtualTourUrl ?? 'https://propzen.ai/property/${property.id}';
        final roomSnippet = (roomName != null && roomName.isNotEmpty) ? ' (Room: $roomName)' : '';
        return 'Namaste! Check out the 360° Virtual Tour for *$title*$roomSnippet ($location) on PropZen:\n\n🔗 Virtual Tour: $tourUrl\n💰 Price: $price\n✨ 100% Verified NCR Property\n\nExplore on PropZen: https://propzen.ai/property/${property.id}';
      case '3d_model':
        return 'Namaste! Explore the interactive 3D Building Model for *$title* ($location) on PropZen:\n\n🏢 3D Model: https://propzen.ai/property/${property.id}#3d\n💰 Price: $price\n📐 Configuration: ${property.bhk} (${property.sqft} sq.ft.)\n\nView details on PropZen!';
      case 'floor_plan':
        return 'Namaste! Here is the verified architectural Floor Plan for *$title* ($location):\n\n📐 Layout: ${property.bhk} (${property.sqft} sq.ft.)\n💰 Price: $price\n\nCheck room dimensions and 3D floor plan on PropZen: https://propzen.ai/property/${property.id}';
      case 'vastu':
        final score = property.vastuData?.overallScore ?? 90;
        final facing = property.vastuData?.facingDirection ?? property.facing;
        return 'Namaste! Vastu-based informational guidance for *$title* ($location):\n\n🧭 Facing: $facing\n⭐ Vastu Score: $score/100\n🚪 Entrance: ${property.vastuData?.entranceDirection ?? "North-East"}\n\nView full analysis on PropZen: https://propzen.ai/property/${property.id}';
      default:
        return 'Namaste! Check out *$title* ($location) listed for $price on PropZen.\n\nExplore verified property details: https://propzen.ai/property/${property.id}';
    }
  }

  /// 8. Share visualization on WhatsApp
  Future<bool> shareOnWhatsApp({
    required Property property,
    required String visualizationType,
    String? roomName,
  }) async {
    final message = generateWhatsAppShareText(
      property: property,
      visualizationType: visualizationType,
      roomName: roomName,
    );

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = 'https://wa.me/?text=$encodedMessage';

    try {
      final uri = Uri.parse(whatsappUrl);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
