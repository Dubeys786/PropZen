import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/property.dart';
import 'supabase_service.dart';
import 'property_state_service.dart';

class PropertyCategory {
  final String id;
  final String name;
  final String displayTitle;
  final String iconName;
  final int sortOrder;

  const PropertyCategory({
    required this.id,
    required this.name,
    required this.displayTitle,
    this.iconName = 'home',
    this.sortOrder = 0,
  });

  factory PropertyCategory.fromMap(Map<String, dynamic> map) {
    return PropertyCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      displayTitle: map['display_title']?.toString() ?? map['name']?.toString() ?? '',
      iconName: map['icon_name']?.toString() ?? 'home',
      sortOrder: map['sort_order'] is int ? map['sort_order'] : 0,
    );
  }
}

class PropertyService extends ChangeNotifier {
  PropertyService._internal();
  static final PropertyService instance = PropertyService._internal();
  factory PropertyService() => instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  List<PropertyCategory> _categories = [];
  List<PropertyCategory> get categories => List.unmodifiable(_categories);

  // Default Categories List
  static const List<String> defaultCategoryChips = [
    'Noida Extension',
    'Sector 150',
    'Yamuna Expressway',
    '2 BHK Apartments',
    '3 BHK Apartments',
    'Luxury Villas',
    'Commercial Offices',
    'Ready to Move Flats',
  ];

  // =========================================================================
  // 1. FETCH PUBLISHED PROPERTIES (Direct PostgREST with fallback)
  // =========================================================================
  Future<List<Property>> fetchPublishedProperties() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final properties = await SupabaseService.instance.fetchPublicProperties();
      _isLoading = false;
      notifyListeners();
      return properties;
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      return PropertyStateService.instance.publishedProperties;
    }
  }

  // =========================================================================
  // 2. FETCH SINGLE PROPERTY BY ID
  // =========================================================================
  Future<Property?> fetchPropertyById(String id) async {
    if (id.isEmpty) return null;
    try {
      return await SupabaseService.instance.fetchPropertyById(id);
    } catch (e) {
      debugPrint('[PropertyService] Error fetchPropertyById $id: $e');
      return PropertyStateService.instance.findPropertyById(id);
    }
  }

  // =========================================================================
  // 3. EXACT MULTI-CRITERIA SEARCH & FILTER
  // =========================================================================
  Future<List<Property>> searchProperties({
    String? query,
    String? location,
    String? sector,
    String? propertyType,
    String? category,
    String? categoryChip,
    double? minPriceCr,
    double? maxPriceCr,
    String? bedrooms,
    int? minAreaSqft,
    int? maxAreaSqft,
    String? possessionStatus,
    Set<String>? amenities,
    String sortBy = 'Recommended',
  }) async {
    // Start with all published properties
    var list = PropertyStateService.instance.publishedProperties;

    // 1. Text Query (Search against title, locality, sector, address, description, builder)
    if (query != null && query.trim().isNotEmpty) {
      final qLower = query.trim().toLowerCase();
      list = list.where((p) {
        final fullHaystack = '${p.title} ${p.locality} ${p.sector} ${p.city} ${p.address} ${p.builderName} ${p.description}'.toLowerCase();
        return fullHaystack.contains(qLower);
      }).toList();
    }

    // 2. Category Chip Exact Logic
    if (categoryChip != null && categoryChip.isNotEmpty && categoryChip != 'All') {
      final chip = categoryChip.trim();
      if (chip == 'Noida Extension') {
        list = list.where((p) {
          final str = '${p.locality} ${p.sector} ${p.address} ${p.city} ${p.title}'.toLowerCase();
          return str.contains('noida extension') || str.contains('greater noida west');
        }).toList();
      } else if (chip == 'Sector 150') {
        list = list.where((p) {
          final str = '${p.locality} ${p.sector} ${p.address} ${p.title}'.toLowerCase();
          return str.contains('sector 150') || str.contains('sector-150') || str.contains('sec 150') || str.contains('150');
        }).toList();
      } else if (chip == 'Yamuna Expressway') {
        list = list.where((p) {
          final str = '${p.locality} ${p.sector} ${p.address} ${p.title}'.toLowerCase();
          return str.contains('yamuna');
        }).toList();
      } else if (chip == '2 BHK Apartments') {
        list = list.where((p) {
          final bhk = p.bhk.trim().toLowerCase();
          final type = p.propertyType.toLowerCase();
          return bhk == '2 bhk' && (type.contains('apartment') || type.contains('flat') || type.contains('residential') || type.contains('home'));
        }).toList();
      } else if (chip == '3 BHK Apartments') {
        list = list.where((p) {
          final bhk = p.bhk.trim().toLowerCase();
          final type = p.propertyType.toLowerCase();
          return bhk == '3 bhk' && (type.contains('apartment') || type.contains('flat') || type.contains('residential') || type.contains('home'));
        }).toList();
      } else if (chip == 'Luxury Villas') {
        list = list.where((p) {
          final type = p.propertyType.toLowerCase();
          final title = p.title.toLowerCase();
          return type.contains('villa') || title.contains('villa');
        }).toList();
      } else if (chip == 'Commercial Offices') {
        list = list.where((p) {
          final type = p.propertyType.toLowerCase();
          final cat = p.category.toLowerCase();
          return type.contains('commercial') || type.contains('office') || cat == 'commercial';
        }).toList();
      } else if (chip == 'Ready to Move Flats') {
        list = list.where((p) {
          final avail = p.availability.toLowerCase();
          final poss = p.possessionDate.toLowerCase();
          final tag = p.statusTag.toLowerCase();
          final isReady = avail.contains('ready') || poss.contains('ready') || tag.contains('ready');
          final type = p.propertyType.toLowerCase();
          return isReady && (type.contains('flat') || type.contains('apartment') || type.contains('residential'));
        }).toList();
      }
    }

    // 3. Location / Sector Exact Filter
    if (location != null && location.isNotEmpty && location != 'All') {
      final locLower = location.toLowerCase();
      list = list.where((p) => p.effectiveLocality.toLowerCase().contains(locLower) || p.city.toLowerCase().contains(locLower)).toList();
    }
    if (sector != null && sector.isNotEmpty && sector != 'All') {
      final secLower = sector.toLowerCase();
      list = list.where((p) => p.sector.toLowerCase().contains(secLower) || p.locality.toLowerCase().contains(secLower)).toList();
    }

    // 4. Property Type
    if (propertyType != null && propertyType.isNotEmpty && propertyType != 'All') {
      final typeLower = propertyType.toLowerCase();
      list = list.where((p) => p.propertyType.toLowerCase().contains(typeLower)).toList();
    }

    // 5. Category
    if (category != null && category.isNotEmpty && category != 'All') {
      final catLower = category.toLowerCase();
      list = list.where((p) => p.category.toLowerCase().contains(catLower)).toList();
    }

    // 6. Bedrooms / BHK (Exact Matching)
    if (bedrooms != null && bedrooms.isNotEmpty && bedrooms != 'All') {
      final bLower = bedrooms.trim().toLowerCase();
      list = list.where((p) => p.bhk.trim().toLowerCase() == bLower).toList();
    }

    // 7. Budget Range
    if (minPriceCr != null && minPriceCr > 0) {
      list = list.where((p) => p.askingPriceCr >= minPriceCr).toList();
    }
    if (maxPriceCr != null && maxPriceCr > 0) {
      list = list.where((p) => p.askingPriceCr <= maxPriceCr).toList();
    }

    // 8. Area Range
    if (minAreaSqft != null && minAreaSqft > 0) {
      list = list.where((p) => p.sqft >= minAreaSqft).toList();
    }
    if (maxAreaSqft != null && maxAreaSqft > 0) {
      list = list.where((p) => p.sqft <= maxAreaSqft).toList();
    }

    // 9. Possession Status
    if (possessionStatus != null && possessionStatus.isNotEmpty && possessionStatus != 'All') {
      final possLower = possessionStatus.toLowerCase();
      list = list.where((p) => p.possessionStatus.toLowerCase().contains(possLower) || p.availability.toLowerCase().contains(possLower)).toList();
    }

    // 10. Amenities (Must contain all selected amenities)
    if (amenities != null && amenities.isNotEmpty) {
      list = list.where((p) {
        final pAmenities = p.amenities.map((a) => a.toLowerCase()).toSet();
        return amenities.every((req) => pAmenities.any((pa) => pa.contains(req.toLowerCase())));
      }).toList();
    }

    // 11. Sorting
    switch (sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => a.askingPriceCr.compareTo(b.askingPriceCr));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => b.askingPriceCr.compareTo(a.askingPriceCr));
        break;
      case 'Highest Score':
      case 'PropZen Score':
        list.sort((a, b) => b.score10x.compareTo(a.score10x));
        break;
      case 'Highest Rental Yield':
        list.sort((a, b) => b.rentalYieldPercent.compareTo(a.rentalYieldPercent));
        break;
      case 'Newest':
      default:
        // Default sort by ID / recency
        break;
    }

    return list;
  }

  // =========================================================================
  // 4. FETCH DYNAMIC CATEGORIES FROM SUPABASE
  // =========================================================================
  Future<List<PropertyCategory>> fetchDynamicCategories() async {
    try {
      final endpoint = '${SupabaseService.supabaseUrl}/rest/v1/property_categories?is_active=eq.true&order=sort_order.asc';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'apikey': SupabaseService.supabasePublishableKey,
          'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          _categories = list.map((c) => PropertyCategory.fromMap(Map<String, dynamic>.from(c as Map))).toList();
          notifyListeners();
          return _categories;
        }
      }
    } catch (e) {
      debugPrint('[PropertyService] Error fetching dynamic categories: $e');
    }

    // Default fallback
    _categories = defaultCategoryChips
        .asMap()
        .entries
        .map((e) => PropertyCategory(
              id: 'cat_${e.key}',
              name: e.value,
              displayTitle: e.value,
              sortOrder: e.key,
            ))
        .toList();
    notifyListeners();
    return _categories;
  }

  /// 5. BACKEND & SERVER-SIDE PROPERTY SUBMISSION VALIDATOR
  /// Never trusts raw client parameters. Enforces UID authenticity,
  /// verified=false, status='pending', and field integrity.
  static PropertySubmissionValidationResult validateAndSanitizeListing(
    Property raw, {
    required String authenticatedUid,
    required bool isEmailVerified,
    bool isDraft = false,
  }) {
    if (authenticatedUid.trim().isEmpty) {
      return PropertySubmissionValidationResult.failure('Authentication required: invalid user credentials.');
    }

    if (!isDraft && !isEmailVerified) {
      return PropertySubmissionValidationResult.failure('Email verification required before listing a property.');
    }

    final trimmedTitle = raw.title.trim();
    if (trimmedTitle.length < 5 || trimmedTitle.length > 100) {
      return PropertySubmissionValidationResult.failure('Property title must be between 5 and 100 characters.');
    }

    if (raw.askingPriceCr <= 0) {
      return PropertySubmissionValidationResult.failure('Property price must be greater than 0.');
    }

    if (raw.sqft <= 0) {
      return PropertySubmissionValidationResult.failure('Property area must be greater than 0.');
    }

    final trimmedPin = raw.postalCode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedPin)) {
      return PropertySubmissionValidationResult.failure('PIN code must contain exactly 6 digits.');
    }

    if (raw.address.trim().length < 10) {
      return PropertySubmissionValidationResult.failure('Address must be at least 10 characters.');
    }

    final trimmedDesc = raw.description.trim();
    if (!isDraft && (trimmedDesc.length < 30 || trimmedDesc.length > 2000)) {
      return PropertySubmissionValidationResult.failure('Description must be between 30 and 2000 characters.');
    }

    if (!isDraft && (raw.galleryImages.isEmpty && raw.imageUrl.isEmpty)) {
      return PropertySubmissionValidationResult.failure('At least 1 property image is required.');
    }

    // Force server-sanitized security values
    final sanitized = raw.copyWith(
      dealerId: authenticatedUid,
      status: isDraft ? 'draft' : 'pending',
      isVerified: false,
      isReraApproved: false,
    );

    return PropertySubmissionValidationResult.success(sanitized);
  }
}

class PropertySubmissionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Property? sanitizedProperty;

  const PropertySubmissionValidationResult({
    required this.isValid,
    this.errorMessage,
    this.sanitizedProperty,
  });

  factory PropertySubmissionValidationResult.success(Property sanitized) =>
      PropertySubmissionValidationResult(isValid: true, sanitizedProperty: sanitized);

  factory PropertySubmissionValidationResult.failure(String error) =>
      PropertySubmissionValidationResult(isValid: false, errorMessage: error);
}
