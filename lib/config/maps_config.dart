import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';

/// Centralized Google Maps Configuration and Utility Service
class MapsConfig {
  /// Google Maps Web API Key
  /// In production, configure environment variable or restricted key.
  static const String webApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_WEB_API_KEY',
    defaultValue: 'AIzaSyDemoPropzenWebKeyForInteractiveMaps',
  );

  /// Default Camera Center Coordinates (NCR / Noida Sector 150 Prime Corridor)
  static const double defaultLatitude = 28.4354;
  static const double defaultLongitude = 77.4878;
  static const double defaultZoom = 15.5;

  /// Geocoding helper: resolves coordinates from stored property data, sector, and locality
  static Map<String, double> getCoordinatesForProperty(Property property) {
    if (property.latitude != 0.0 && property.longitude != 0.0 &&
        !property.latitude.isNaN && !property.longitude.isNaN) {
      return {'lat': property.latitude, 'lng': property.longitude};
    }

    final query = '${property.title} ${property.address} ${property.sector} ${property.city} ${property.locality}'.toLowerCase();

    for (final loc in ncrLocalities) {
      final title = (loc['title'] as String).toLowerCase();
      final locality = (loc['locality'] as String).toLowerCase();
      if (query.contains(locality) || query.contains(title)) {
        return {'lat': loc['lat'] as double, 'lng': loc['lng'] as double};
      }
    }

    if (query.contains('noida extension') || query.contains('greater noida west') || query.contains('happy trails')) {
      return {'lat': 28.6012, 'lng': 77.4421};
    }
    if (query.contains('gaur city')) {
      return {'lat': 28.6085, 'lng': 77.4298};
    }
    if (query.contains('ace divino')) {
      return {'lat': 28.6140, 'lng': 77.4520};
    }
    if (query.contains('150')) return {'lat': 28.4380, 'lng': 77.4850};
    if (query.contains('137')) return {'lat': 28.5148, 'lng': 77.4079};
    if (query.contains('142') || query.contains('advant')) return {'lat': 28.4980, 'lng': 77.4180};
    if (query.contains('62')) return {'lat': 28.6258, 'lng': 77.3639};
    if (query.contains('63') || query.contains('arbour')) return {'lat': 28.4019, 'lng': 77.1085};
    if (query.contains('gurugram') || query.contains('gurgaon')) return {'lat': 28.4595, 'lng': 77.0266};

    return {'lat': defaultLatitude, 'lng': defaultLongitude};
  }

  /// NCR Known Localities Registry for instant autocomplete & fast geocoding
  static const List<Map<String, dynamic>> ncrLocalities = [
    {
      'title': 'Sector 150, Noida',
      'subtitle': 'Noida-Greater Noida Expressway, UP',
      'lat': 28.4354,
      'lng': 77.4878,
      'city': 'Noida',
      'locality': 'Sector 150',
      'postalCode': '201310',
    },
    {
      'title': 'Sector 137, Noida',
      'subtitle': 'Near Metro Station, Noida, UP',
      'lat': 28.5148,
      'lng': 77.4079,
      'city': 'Noida',
      'locality': 'Sector 137',
      'postalCode': '201305',
    },
    {
      'title': 'Techzone 4, Greater Noida West',
      'subtitle': 'Gautam Buddha Nagar, UP',
      'lat': 28.5833,
      'lng': 77.4475,
      'city': 'Greater Noida',
      'locality': 'Techzone 4',
      'postalCode': '201306',
    },
    {
      'title': 'Sector 75, Noida',
      'subtitle': 'Golf City / Spectrum Mall, Noida, UP',
      'lat': 28.5772,
      'lng': 77.3824,
      'city': 'Noida',
      'locality': 'Sector 75',
      'postalCode': '201301',
    },
    {
      'title': 'Sector 52, Noida',
      'subtitle': 'Blue Line Metro Interchange, Noida, UP',
      'lat': 28.5910,
      'lng': 77.3688,
      'city': 'Noida',
      'locality': 'Sector 52',
      'postalCode': '201307',
    },
    {
      'title': 'Sector 67, Gurugram',
      'subtitle': 'Golf Course Extension Road, Gurugram, Haryana',
      'lat': 28.3842,
      'lng': 77.0546,
      'city': 'Gurugram',
      'locality': 'Sector 67',
      'postalCode': '122101',
    },
    {
      'title': 'New Gurgaon (Sector 84), Gurugram',
      'subtitle': 'Near Dwarka Expressway, Gurugram, Haryana',
      'lat': 28.4069,
      'lng': 76.9535,
      'city': 'Gurugram',
      'locality': 'Sector 84',
      'postalCode': '122004',
    },
    {
      'title': 'Sector 21, Dwarka, Delhi',
      'subtitle': 'Dwarka Express Metro & IGI Terminal 3, New Delhi',
      'lat': 28.5823,
      'lng': 77.0500,
      'city': 'Delhi',
      'locality': 'Dwarka',
      'postalCode': '110075',
    },
    {
      'title': 'Sector 78, Noida',
      'subtitle': 'Near Mahagun Mezzaria, Noida, UP',
      'lat': 28.5684,
      'lng': 77.3862,
      'city': 'Noida',
      'locality': 'Sector 78',
      'postalCode': '201307',
    },
    {
      'title': 'Sector 16B, Greater Noida West',
      'subtitle': 'Gautam Buddha Nagar, Greater Noida, UP',
      'lat': 28.6087,
      'lng': 77.4429,
      'city': 'Greater Noida',
      'locality': 'Sector 16B',
      'postalCode': '201308',
    },
    {
      'title': 'Sector 58, Gurugram',
      'subtitle': 'Golf Course Extension Road, Gurugram, Haryana',
      'lat': 28.4019,
      'lng': 77.1085,
      'city': 'Gurugram',
      'locality': 'Sector 58',
      'postalCode': '122011',
    },
    {
      'title': 'Cyber City, DLF Phase 2, Gurugram',
      'subtitle': 'Commercial IT Hub, Gurugram, Haryana',
      'lat': 28.4906,
      'lng': 77.0900,
      'city': 'Gurugram',
      'locality': 'Cyber City',
      'postalCode': '122002',
    },
    {
      'title': 'Sector 62, Noida',
      'subtitle': 'Institutional Area & Electronic City, Noida, UP',
      'lat': 28.6258,
      'lng': 77.3639,
      'city': 'Noida',
      'locality': 'Sector 62',
      'postalCode': '201309',
    },
  ];

  /// Launch Google Maps External Navigation
  static Future<bool> openInGoogleMaps({
    required double latitude,
    required double longitude,
    String? title,
  }) async {
    // Exact location navigation URI for Google Maps
    final query = '$latitude,$longitude';
    
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.platformDefault,
        );
      }
      return launched;
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
      return false;
    }
  }

  /// Clean, Modern Google Map Light Styling matching Propzen aesthetic
  static const String lightMapStyle = '''[
  {
    "featureType": "all",
    "elementType": "geometry",
    "stylers": [{"color": "#f8fafc"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#334155"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#ffffff"}, {"weight": 3}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#6366f1"}, {"weight": "bold"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#dcfce7"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#fef08a"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#facc15"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [{"color": "#e0e7ff"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#bae6fd"}]
  }
]''';

  /// Modern Dark Google Map Styling
  static const String darkMapStyle = '''[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#94a3b8"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0f172a"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#a855f7"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#064e3b"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#334155"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#ca8a04"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0c4a6e"}]
  }
]''';
}
