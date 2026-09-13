import 'property.dart';

class PropertyFilter {
  String city;
  String locality;
  String propertyType; // All, Apartment/Flat, Villa, Plot, Commercial, PG/Co-living
  double? minPriceCr;
  double? maxPriceCr;
  List<String> bhkList; // ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK']
  int? minAreaSqft;
  int? maxAreaSqft;
  String possession; // All, Ready to Move, Under Construction, Upcoming
  String propertyStatus; // All, New Launch, Resale, Featured, Trending, Price Drop Deals
  Set<String> amenities;
  bool? reraApprovedOnly;
  String furnishing; // All, Fully Furnished, Semi Furnished, Unfurnished
  String builderOrDealer;
  String sortBy; // Recommended, Price Low to High, Price High to Low, Newest, Most Viewed

  PropertyFilter({
    this.city = 'All',
    this.locality = 'All',
    this.propertyType = 'All',
    this.minPriceCr,
    this.maxPriceCr,
    List<String>? bhkList,
    this.minAreaSqft,
    this.maxAreaSqft,
    this.possession = 'All',
    this.propertyStatus = 'All',
    Set<String>? amenities,
    this.reraApprovedOnly,
    this.furnishing = 'All',
    this.builderOrDealer = 'All',
    this.sortBy = 'Recommended',
  })  : bhkList = bhkList ?? [],
        amenities = amenities ?? {};

  PropertyFilter clone() {
    return PropertyFilter(
      city: city,
      locality: locality,
      propertyType: propertyType,
      minPriceCr: minPriceCr,
      maxPriceCr: maxPriceCr,
      bhkList: List.from(bhkList),
      minAreaSqft: minAreaSqft,
      maxAreaSqft: maxAreaSqft,
      possession: possession,
      propertyStatus: propertyStatus,
      amenities: Set.from(amenities),
      reraApprovedOnly: reraApprovedOnly,
      furnishing: furnishing,
      builderOrDealer: builderOrDealer,
      sortBy: sortBy,
    );
  }

  void reset() {
    city = 'All';
    locality = 'All';
    propertyType = 'All';
    minPriceCr = null;
    maxPriceCr = null;
    bhkList.clear();
    minAreaSqft = null;
    maxAreaSqft = null;
    possession = 'All';
    propertyStatus = 'All';
    amenities.clear();
    reraApprovedOnly = null;
    furnishing = 'All';
    builderOrDealer = 'All';
    sortBy = 'Recommended';
  }

  int get activeFilterCount {
    int count = 0;
    if (city != 'All' && city.isNotEmpty) count++;
    if (locality != 'All' && locality.isNotEmpty) count++;
    if (propertyType != 'All' && propertyType.isNotEmpty) count++;
    if (minPriceCr != null || maxPriceCr != null) count++;
    if (bhkList.isNotEmpty) count++;
    if (minAreaSqft != null || maxAreaSqft != null) count++;
    if (possession != 'All' && possession.isNotEmpty) count++;
    if (propertyStatus != 'All' && propertyStatus.isNotEmpty) count++;
    if (amenities.isNotEmpty) count += amenities.length;
    if (reraApprovedOnly == true) count++;
    if (furnishing != 'All' && furnishing.isNotEmpty) count++;
    if (builderOrDealer != 'All' && builderOrDealer.isNotEmpty) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  /// Exact AND Evaluation Logic
  bool matches(Property p) {
    // City filter
    if (city != 'All' && city.isNotEmpty) {
      final cLower = city.toLowerCase();
      final pCityLower = p.city.toLowerCase();
      if (cLower == 'gurgaon' || cLower == 'gurugram') {
        if (!pCityLower.contains('gurgaon') && !pCityLower.contains('gurugram')) {
          return false;
        }
      } else if (!pCityLower.contains(cLower)) {
        return false;
      }
    }

    // Locality / Sector filter
    if (locality != 'All' && locality.isNotEmpty) {
      if (!p.sector.toLowerCase().contains(locality.toLowerCase())) {
        return false;
      }
    }

    // Property Type filter
    if (propertyType != 'All' && propertyType.isNotEmpty) {
      final pType = p.propertyType.toLowerCase();
      final selType = propertyType.toLowerCase();
      if (selType == 'apartment' || selType == 'flat') {
        if (!pType.contains('flat') && !pType.contains('apartment')) return false;
      } else if (selType == 'villa') {
        if (!pType.contains('villa')) return false;
      } else if (selType == 'plot') {
        if (!pType.contains('plot')) return false;
      } else if (selType == 'commercial') {
        if (p.category.toLowerCase() != 'commercial' && !pType.contains('office') && !pType.contains('shop')) return false;
      } else if (selType.contains('pg') || selType.contains('co-living')) {
        if (!pType.contains('pg') && !pType.contains('co-living')) return false;
      } else if (!pType.contains(selType) && !p.category.toLowerCase().contains(selType)) {
        return false;
      }
    }

    // Budget Range filter (Min & Max Price)
    if (minPriceCr != null) {
      if (p.askingPriceCr < minPriceCr!) return false;
    }
    if (maxPriceCr != null) {
      if (p.askingPriceCr > maxPriceCr!) return false;
    }

    // BHK filter
    if (bhkList.isNotEmpty) {
      bool bhkMatched = false;
      for (final bhk in bhkList) {
        final b = bhk.toLowerCase().replaceAll(' ', '');
        final propBhk = p.bhk.toLowerCase().replaceAll(' ', '');
        if (b.contains('5+') || b.contains('5')) {
          if (propBhk.contains('5') || propBhk.contains('6') || propBhk.contains('penthouse')) {
            bhkMatched = true;
            break;
          }
        } else if (b.contains('1bhk') && propBhk.contains('1')) {
          bhkMatched = true;
          break;
        } else if (b.contains('2bhk') && propBhk.contains('2')) {
          bhkMatched = true;
          break;
        } else if (b.contains('3bhk') && propBhk.contains('3')) {
          bhkMatched = true;
          break;
        } else if (b.contains('4bhk') && propBhk.contains('4')) {
          bhkMatched = true;
          break;
        } else if (propBhk.contains(b)) {
          bhkMatched = true;
          break;
        }
      }
      if (!bhkMatched) return false;
    }

    // Area SqFt filter
    if (minAreaSqft != null && p.sqft < minAreaSqft!) {
      return false;
    }
    if (maxAreaSqft != null && p.sqft > maxAreaSqft!) {
      return false;
    }

    // Possession Status
    if (possession != 'All' && possession.isNotEmpty) {
      final pPos = p.availability.toLowerCase();
      final selPos = possession.toLowerCase();
      if (selPos.contains('ready') && !pPos.contains('ready')) return false;
      if (selPos.contains('under') && !pPos.contains('under')) return false;
      if (selPos.contains('upcoming') && !pPos.contains('upcoming') && !pPos.contains('launch')) return false;
    }

    // Property Status (New Launch, Resale, Featured, Trending, Price Drop)
    if (propertyStatus != 'All' && propertyStatus.isNotEmpty) {
      final statusLower = propertyStatus.toLowerCase();
      final pStatusLower = p.statusTag.toLowerCase();
      if (!pStatusLower.contains(statusLower) &&
          !p.description.toLowerCase().contains(statusLower)) {
        return false;
      }
    }

    // Amenities (All selected amenities must be present)
    if (amenities.isNotEmpty) {
      final pAmenities = p.amenities.map((a) => a.toLowerCase()).toSet();
      for (final a in amenities) {
        final aLower = a.toLowerCase();
        bool found = false;
        for (final pa in pAmenities) {
          if (pa.contains(aLower) || aLower.contains(pa)) {
            found = true;
            break;
          }
        }
        if (!found) return false;
      }
    }

    // RERA Approved
    if (reraApprovedOnly == true && !p.isReraApproved) {
      return false;
    }

    // Furnishing
    if (furnishing != 'All' && furnishing.isNotEmpty) {
      final pFurn = p.furnishing.toLowerCase();
      final selFurn = furnishing.toLowerCase();
      if (selFurn.contains('fully') && !pFurn.contains('fully') && !pFurn.contains('furnished')) return false;
      if (selFurn.contains('semi') && !pFurn.contains('semi')) return false;
      if (selFurn.contains('unfurnished') && !pFurn.contains('unfurnished')) return false;
    }

    // Dealer / Builder
    if (builderOrDealer != 'All' && builderOrDealer.isNotEmpty) {
      final bOrD = builderOrDealer.toLowerCase();
      if (!p.builderName.toLowerCase().contains(bOrD) &&
          !p.dealerName.toLowerCase().contains(bOrD)) {
        return false;
      }
    }

    return true;
  }

  /// Sorts a list of properties according to `sortBy`
  List<Property> applySorting(List<Property> list) {
    final sorted = List<Property>.from(list);
    switch (sortBy) {
      case 'Price Low to High':
        sorted.sort((a, b) => a.askingPriceCr.compareTo(b.askingPriceCr));
        break;
      case 'Price High to Low':
        sorted.sort((a, b) => b.askingPriceCr.compareTo(a.askingPriceCr));
        break;
      case 'Newest':
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Most Viewed':
        sorted.sort((a, b) => b.intelligenceScore.compareTo(a.intelligenceScore));
        break;
      case 'Recommended':
      default:
        sorted.sort((a, b) => b.score10x.compareTo(a.score10x));
        break;
    }
    return sorted;
  }
}

class PropertyFilterEngine {
  static List<Property> filterProperties({
    List<Property>? source,
    String? category,
    String? subtype,
    String? bhk,
    String? budget,
    String? sector,
    String? searchQuery,
    bool? onlyVerified,
    bool? onlyReadyToMove,
    Set<String>? amenities,
  }) {
    final list = source ?? Property.sampleDeals;
    final filter = PropertyFilter();

    if (category != null && category != 'All') filter.propertyType = category;
    if (subtype != null && subtype != 'All') filter.propertyType = subtype;
    if (bhk != null && bhk != 'All BHK') filter.bhkList = [bhk];
    if (sector != null && sector != 'All Sectors') filter.locality = sector;
    if (onlyVerified == true) filter.reraApprovedOnly = true;
    if (onlyReadyToMove == true) filter.possession = 'Ready to Move';
    if (amenities != null && amenities.isNotEmpty) filter.amenities = Set.from(amenities);

    if (budget != null && budget != 'All Budgets') {
      if (budget.contains('50L')) filter.maxPriceCr = 0.50;
      if (budget.contains('1 Cr')) filter.maxPriceCr = 1.00;
    }

    var result = list.where((p) => filter.matches(p)).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((p) =>
          p.title.toLowerCase().contains(q) ||
          p.sector.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.builderName.toLowerCase().contains(q)).toList();
    }

    return result;
  }
}
