import 'property_visualization_model.dart';
import 'property_media_item.dart';

class Property {
  final String id;
  final String title;
  final String sector;
  final String city;
  final String locality;
  final String address;
  final String postalCode;
  final String placeId;
  final double latitude;
  final double longitude;
  final String category; // Residential, Commercial, Industrial, Agricultural, PG/Co-living
  final String propertyType; // Apartment, Flat, Plot, Villa, Office Space, Retail Shop, Warehouse, PG/Co-living, Agricultural Land
  final double askingPriceCr;
  final double fairValueCr;
  final double? originalPriceCr;
  final int? discountPercent;
  final String priceRangeDisplay;
  final double pricePerSqft;
  final double score10x;
  final double rentalYieldPercent;
  final int sqft;
  final int carpetAreaSqft;
  final String bhk;
  final List<String> bhkOptions;
  final String imageUrl;
  final List<String> galleryImages;
  final bool isVerified;
  final bool isZeroBroker;
  final bool isReraApproved;
  final String reraId;
  final String statusTag; // New Launch, Trending, Price Drop, Featured, Ready to Move
  final double rating;
  final int reviewCount;
  final String builderName;
  final String projectName;
  final int? floorNumber;
  final int? totalFloors;
  final int? parkingSlots;
  final String constructionStatus;
  final String contactPreference;
  final int viewsCount;
  final int enquiriesCount;
  final int siteVisitsCount;
  final int leadsCount;
  final List<PropertyMediaItem> mediaList;

  // Dealer & Contact Information
  final String dealerId;
  final String dealerName;
  final String dealerPhone;
  final String dealerEmail;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String possessionDate;

  // Property Approval System Extensions
  final String status; // 'pending', 'under_review', 'approved', 'published', 'rejected', 'needs_correction'
  final String? adminNote; // Reason for rejection / Admin review feedback
  final String? approvedAt;
  final String? approvedBy;
  final String reraStatus;
  final String possessionStatus;
  final String furnishingStatus;
  final String? createdAt;
  final String? updatedAt;

  // Dealer Terms & Declaration System Extensions
  final bool termsAccepted;
  final String termsVersion;
  final String? termsAcceptedAt;
  final String? termsAcceptedBy;
  final bool declarationAccuracyAccepted;
  final bool declarationAuthorizationAccepted;
  final bool declarationContentRightsAccepted;
  final bool declarationPricingAccepted;
  final bool declarationReviewAccepted;
  final bool declarationTermsAccepted;
  final Map<String, dynamic>? declarations;

  // Property Intelligence Extensions
  final String facing; // East, North, West, South, North-East
  final String furnishing; // Fully Furnished, Semi-Furnished, Unfurnished
  final String availability; // Ready to Move, Under Construction, Upcoming
  final List<String> amenities;
  final String? reraDocumentUrl;
  final String? floorPlanUrl;
  final String description;
  final int intelligenceScore; // e.g. 88 / 100
  final int investmentScore; // e.g. 92 / 100
  final String ownershipStatus; // Verified, Pending
  final String documentStatus; // Verified, Partially Verified
  final String riskLevel; // LOW, MEDIUM, HIGH
  final Map<String, String> nearby;

  // Property Visualization Ecosystem Extensions
  final VirtualTourData? virtualTour;
  final String? virtualTourUrl;
  final String? model3DUrl;
  final String? model3DId;
  final String? arModelUrl;
  final String? floorPlan2DUrl;
  final String? floorPlan3DUrl;
  final List<FloorPlanRoom> floorPlanRooms;
  final List<InteriorConcept> interiorConcepts;
  final List<ExteriorConcept> exteriorConcepts;
  final VastuGuidanceData? vastuData;

  // NRI Drone Tour Ecosystem Extensions
  final bool droneTourAvailable;
  final String? droneTourUrl;
  final String? droneTourThumbnail;
  final String? droneTourDuration;
  final String? droneTourAccessType; // e.g. 'nri_exclusive'
  final int droneFlightAltitudeMeters; // e.g. 120
  final List<String> droneAerialPoints;

  // Smart Media & Video Optimization Extensions
  final String? youtubeVideoId;
  final String? youtubeUrl;
  final String? optimizedThumbnailUrl;
  final String? optimizedMediumUrl;

  // AI Intelligence, Verification & Lifecycle Extensions
  final String duplicateStatus; // 'normal', 'possible_duplicate', 'confirmed_duplicate'
  final String? duplicateOfPropertyId;
  final String availabilityStatus; // 'Available', 'Reserved', 'Sold', 'Rented', 'Unavailable'
  final int qualityScore; // 0 - 100
  final bool reReviewRequired;
  final String? internalAdminNotes;

  static const Property empty = Property(
    id: '',
    title: '',
    sector: '',
    city: '',
    category: 'Residential',
    propertyType: 'Apartment',
    askingPriceCr: 0.0,
    fairValueCr: 0.0,
    pricePerSqft: 0.0,
    score10x: 0.0,
    rentalYieldPercent: 0.0,
    sqft: 0,
    bhk: '',
    imageUrl: '',
    droneTourAvailable: false,
    droneFlightAltitudeMeters: 100,
    droneAerialPoints: [],
  );

  const Property({
    required this.id,
    required this.title,
    required this.sector,
    required this.city,
    this.reraDocumentUrl,
    this.floorPlanUrl,
    this.locality = '',
    this.address = '',
    this.postalCode = '',
    this.placeId = '',
    this.latitude = 28.4354,
    this.longitude = 77.4878,
    this.category = 'Residential',
    this.propertyType = 'Apartment',
    required this.askingPriceCr,
    this.fairValueCr = 0.0,
    this.originalPriceCr,
    this.discountPercent,
    this.priceRangeDisplay = '',
    this.pricePerSqft = 0.0,
    this.score10x = 9.0,
    this.rentalYieldPercent = 4.5,
    this.sqft = 1500,
    this.carpetAreaSqft = 0,
    this.bhk = '3 BHK',
    this.bhkOptions = const [],
    this.imageUrl = '',
    this.galleryImages = const [],
    this.isVerified = true,
    this.isZeroBroker = true,
    this.isReraApproved = true,
    this.reraId = 'UPRERAPRJ123456',
    this.statusTag = 'New Launch',
    this.rating = 4.5,
    this.reviewCount = 128,
    this.builderName = 'Propzen Prime Developers',
    this.projectName = '',
    this.floorNumber,
    this.totalFloors,
    this.parkingSlots = 1,
    this.constructionStatus = 'Ready to Move',
    this.contactPreference = 'WhatsApp & Call',
    this.viewsCount = 0,
    this.enquiriesCount = 0,
    this.siteVisitsCount = 0,
    this.leadsCount = 0,
    this.mediaList = const [],
    this.dealerId = '',
    this.dealerName = '',
    this.dealerPhone = '',
    this.dealerEmail = '',
    this.contactName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.possessionDate = 'Dec 2026',
    this.status = 'published',
    this.adminNote,
    this.approvedAt,
    this.approvedBy,
    this.reraStatus = 'Approved',
    this.possessionStatus = 'Ready to Move',
    this.furnishingStatus = 'Semi-Furnished',
    this.createdAt,
    this.updatedAt,
    this.termsAccepted = true,
    this.termsVersion = '2026.1',
    this.termsAcceptedAt,
    this.termsAcceptedBy,
    this.declarationAccuracyAccepted = true,
    this.declarationAuthorizationAccepted = true,
    this.declarationContentRightsAccepted = true,
    this.declarationPricingAccepted = true,
    this.declarationReviewAccepted = true,
    this.declarationTermsAccepted = true,
    this.declarations,
    this.facing = 'East',
    this.furnishing = 'Semi-Furnished',
    this.availability = 'Ready to Move',
    this.amenities = const [
      'Clubhouse',
      'Swimming Pool',
      'Gymnasium',
      '24x7 Security',
      'Power Backup',
      'Children Play Area',
      'EV Charging Point'
    ],
    this.description =
        'Premium luxury property located in a prime growth corridor with world-class amenities, high rental yield potential, 3-tier security, and modern sustainable architecture.',
    this.intelligenceScore = 88,
    this.investmentScore = 92,
    this.ownershipStatus = 'Verified',
    this.documentStatus = 'Verified',
    this.riskLevel = 'LOW',
    this.nearby = const {},
    this.virtualTour,
    this.virtualTourUrl,
    this.model3DUrl,
    this.model3DId,
    this.arModelUrl,
    this.floorPlan2DUrl,
    this.floorPlan3DUrl,
    this.floorPlanRooms = const [],
    this.interiorConcepts = const [],
    this.exteriorConcepts = const [],
    this.vastuData,
    this.droneTourAvailable = false,
    this.droneTourUrl,
    this.droneTourThumbnail,
    this.droneTourDuration = '2:45',
    this.droneTourAccessType = 'nri_exclusive',
    this.droneFlightAltitudeMeters = 120,
    this.droneAerialPoints = const [],
    this.youtubeVideoId,
    this.youtubeUrl,
    this.optimizedThumbnailUrl,
    this.optimizedMediumUrl,
    this.duplicateStatus = 'normal',
    this.duplicateOfPropertyId,
    this.availabilityStatus = 'Available',
    this.qualityScore = 88,
    this.reReviewRequired = false,
    this.internalAdminNotes,
  });

  /// YouTube Video Integration Helpers
  bool get hasYoutubeVideo => (youtubeVideoId != null && youtubeVideoId!.trim().isNotEmpty) || (youtubeUrl != null && youtubeUrl!.trim().isNotEmpty);
  String get youtubeThumbnailUrl => (youtubeVideoId != null && youtubeVideoId!.isNotEmpty)
      ? 'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg'
      : (youtubeUrl != null ? 'https://img.youtube.com/vi/${youtubeUrl!.split("v=").last.split("&").first}/hqdefault.jpg' : '');
  String get officialYoutubeWatchUrl => youtubeVideoId != null && youtubeVideoId!.isNotEmpty
      ? 'https://www.youtube.com/watch?v=$youtubeVideoId'
      : (youtubeUrl ?? '');

  /// Responsive Optimized Images (Fast Card Loading vs HD Gallery Zoom)
  String get displayImageUrl => (optimizedMediumUrl != null && optimizedMediumUrl!.isNotEmpty)
      ? optimizedMediumUrl!
      : dynamicImageUrl;

  String get thumbnailImageUrl => (optimizedThumbnailUrl != null && optimizedThumbnailUrl!.isNotEmpty)
      ? optimizedThumbnailUrl!
      : dynamicImageUrl;

  /// Verification & Lifecycle Convenience Getters
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isSuspended => status.toLowerCase() == 'suspended';
  bool get isVerifiedStatus => status.toLowerCase() == 'verified';
  bool get isPropZenVerified => (isVerified || isVerifiedStatus) && !isPending && !isRejected && !isSuspended && !isDraft;
  bool get isAvailable => availabilityStatus.toLowerCase() == 'available' && !isSold;
  bool get isSold => availabilityStatus.toUpperCase() == 'SOLD';
  bool get isUnderOffer => availabilityStatus.toUpperCase() == 'UNDER_OFFER';
  bool get locationVerified => (latitude != 0.0 && longitude != 0.0 && postalCode.isNotEmpty);
  bool get isLocationVerified => locationVerified;

  /// Human-Readable Standard PropZen Property ID
  String get propzenId {
    final prefix = city.toLowerCase().contains('noida')
        ? 'PZ-NOI'
        : ((city.toLowerCase().contains('gurgaon') || city.toLowerCase().contains('gurugram'))
            ? 'PZ-GGN'
            : (city.toLowerCase().contains('delhi') ? 'PZ-DEL' : 'PZ-NCR'));
    final hashNum = (id.hashCode.abs() % 900000) + 100000;
    return '$prefix-$hashNum';
  }

  /// Verification Freshness & Aging
  DateTime get lastCheckedAt => DateTime.tryParse(updatedAt ?? '') ?? DateTime.now().subtract(const Duration(days: 3));
  int get verificationAgeDays => DateTime.now().difference(lastCheckedAt).inDays.abs();
  bool get isReverificationRequired => verificationAgeDays > 90;
  String get freshnessDisplay => verificationAgeDays <= 1 ? 'Verified recently' : 'Verified $verificationAgeDays days ago';
  String get dealerResponseTimeText => 'Usually responds within 15 mins';

  /// Visualization Capability Flags
  bool get hasDroneTour => droneTourAvailable && droneTourUrl != null && droneTourUrl!.trim().isNotEmpty;
  bool get hasVirtualTour =>
      (virtualTour != null && virtualTour!.isAvailable && (virtualTour!.rooms.isNotEmpty || (virtualTour!.panoramaUrl != null && virtualTour!.panoramaUrl!.isNotEmpty))) ||
      (virtualTourUrl != null && virtualTourUrl!.trim().isNotEmpty);
  bool get has3DModel => (model3DUrl != null && model3DUrl!.trim().isNotEmpty) || (model3DId != null && model3DId!.trim().isNotEmpty);
  bool get hasArModel => arModelUrl != null && arModelUrl!.trim().isNotEmpty;
  bool get hasFloorPlan => (floorPlanUrl != null && floorPlanUrl!.isNotEmpty) || (floorPlan2DUrl != null && floorPlan2DUrl!.isNotEmpty) || (floorPlan3DUrl != null && floorPlan3DUrl!.isNotEmpty) || floorPlanRooms.isNotEmpty;
  bool get hasInteriorVisualization => interiorConcepts.isNotEmpty;
  bool get hasExteriorVisualization => exteriorConcepts.isNotEmpty;
  bool get hasVastuData => vastuData != null;

  /// Name alias for compatibility
  String get name => title;

  /// Effective locality (falls back to sector if locality is empty)
  String get effectiveLocality => locality.isNotEmpty ? locality : sector;

  /// Full formatted address
  String get fullAddress {
    if (address.isNotEmpty) return address;
    final parts = <String>[];
    if (effectiveLocality.isNotEmpty) parts.add(effectiveLocality);
    if (city.isNotEmpty) parts.add(city);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }

  /// Formatted price text helper
  String get formattedPrice {
    if (priceRangeDisplay.isNotEmpty) return priceRangeDisplay;
    if (askingPriceCr >= 1.0) {
      final str = askingPriceCr.toStringAsFixed(2);
      final clean = str.endsWith('.00')
          ? str.substring(0, str.length - 3)
          : (str.endsWith('0') ? str.substring(0, str.length - 1) : str);
      return '₹$clean Cr';
    } else {
      final lakhs = (askingPriceCr * 100).round();
      return '₹$lakhs L';
    }
  }

  /// Dynamic Image URL fallback for standard assets
  String get dynamicImageUrl {
    if (imageUrl.isNotEmpty) return imageUrl;
    final seed = id.hashCode.abs();
    final imagePool = [
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=1000&q=80',
      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1000&q=80',
    ];
    return imagePool[seed % imagePool.length];
  }

  /// Dynamic Gallery Images for photo viewer & property details
  List<String> get dynamicGalleryImages {
    if (galleryImages.isNotEmpty) return galleryImages;
    final seed = id.hashCode.abs();
    return [
      dynamicImageUrl,
      'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1000&q=80&sig=${seed + 1}',
      'https://images.unsplash.com/photo-1600585154526-990dced4db0d?auto=format&fit=crop&w=1000&q=80&sig=${seed + 2}',
      'https://images.unsplash.com/photo-1600573472550-8090b5e0745e?auto=format&fit=crop&w=1000&q=80&sig=${seed + 3}',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1000&q=80&sig=${seed + 4}',
    ];
  }

  // Approval Status Convenience Getters
  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'pending_review';
  bool get isUnderReview => status.toLowerCase() == 'under_review';
  bool get isApproved => status.toLowerCase() == 'approved' || status.toLowerCase() == 'published' || status.toLowerCase() == 'verified';
  bool get isPublished => status.toLowerCase() == 'published' || status.toLowerCase() == 'approved' || status.toLowerCase() == 'verified';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isNeedsCorrection => status.toLowerCase() == 'needs_correction' || status.toLowerCase() == 'correction_required';
  double get price => askingPriceCr * 10000000;

  /// JSON / Map Serialization (n8n & Supabase backend compatible)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'sector': sector,
      'city': city,
      'locality': effectiveLocality,
      'address': fullAddress,
      'postalCode': postalCode,
      'postal_code': postalCode,
      'placeId': placeId,
      'place_id': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'propertyType': propertyType,
      'property_type': propertyType,
      'askingPriceCr': askingPriceCr,
      'price_cr': askingPriceCr,
      'price': askingPriceCr > 0 ? (askingPriceCr * 10000000) : 0,
      'fairValueCr': fairValueCr,
      'originalPriceCr': originalPriceCr,
      'discountPercent': discountPercent,
      'priceRangeDisplay': priceRangeDisplay,
      'pricePerSqft': pricePerSqft,
      'score10x': score10x,
      'rentalYieldPercent': rentalYieldPercent,
      'sqft': sqft,
      'area': sqft,
      'carpetAreaSqft': carpetAreaSqft,
      'carpet_area': carpetAreaSqft,
      'bhk': bhk,
      'bhkOptions': bhkOptions,
      'imageUrl': imageUrl,
      'image_url': imageUrl,
      'galleryImages': galleryImages,
      'images': galleryImages.isNotEmpty ? galleryImages : [dynamicImageUrl],
      'isVerified': isVerified,
      'isZeroBroker': isZeroBroker,
      'isReraApproved': isReraApproved,
      'reraId': reraId,
      'statusTag': statusTag,
      'rating': rating,
      'reviewCount': reviewCount,
      'builderName': builderName,
      'projectName': projectName,
      'project_name': projectName,
      'floorNumber': floorNumber,
      'floor_number': floorNumber,
      'totalFloors': totalFloors,
      'total_floors': totalFloors,
      'parkingSlots': parkingSlots,
      'parking_slots': parkingSlots,
      'constructionStatus': constructionStatus,
      'construction_status': constructionStatus,
      'contactPreference': contactPreference,
      'contact_preference': contactPreference,
      'viewsCount': viewsCount,
      'views_count': viewsCount,
      'enquiriesCount': enquiriesCount,
      'enquiries_count': enquiriesCount,
      'siteVisitsCount': siteVisitsCount,
      'site_visits_count': siteVisitsCount,
      'leadsCount': leadsCount,
      'leads_count': leadsCount,
      'mediaList': mediaList.map((m) => m.toMap()).toList(),
      'media_list': mediaList.map((m) => m.toMap()).toList(),
      'dealerId': dealerId,
      'dealer_id': dealerId,
      'dealerName': dealerName,
      'dealerPhone': dealerPhone,
      'dealerEmail': dealerEmail,
      'dealer_email': dealerEmail,
      'contactName': contactName,
      'contact_name': contactName,
      'contactPhone': contactPhone,
      'contact_phone': contactPhone,
      'contactEmail': contactEmail,
      'contact_email': contactEmail,
      'possessionDate': possessionDate,
      'status': status,
      'adminNote': adminNote,
      'admin_note': adminNote,
      'approvedAt': approvedAt,
      'approved_at': approvedAt,
      'approvedBy': approvedBy,
      'approved_by': approvedBy,
      'reraStatus': reraStatus,
      'rera_status': reraStatus,
      'possessionStatus': possessionStatus,
      'possession_status': possessionStatus,
      'furnishingStatus': furnishingStatus,
      'furnishing_status': furnishingStatus,
      'createdAt': createdAt,
      'created_at': createdAt,
      'updatedAt': updatedAt,
      'updated_at': updatedAt,
      'termsAccepted': termsAccepted,
      'terms_accepted': termsAccepted,
      'termsVersion': termsVersion,
      'terms_version': termsVersion,
      'termsAcceptedAt': termsAcceptedAt,
      'terms_accepted_at': termsAcceptedAt,
      'termsAcceptedBy': termsAcceptedBy,
      'terms_accepted_by': termsAcceptedBy,
      'declarationAccuracyAccepted': declarationAccuracyAccepted,
      'declaration_accuracy_accepted': declarationAccuracyAccepted,
      'declarationAuthorizationAccepted': declarationAuthorizationAccepted,
      'declaration_authorization_accepted': declarationAuthorizationAccepted,
      'declarationContentRightsAccepted': declarationContentRightsAccepted,
      'declaration_content_rights_accepted': declarationContentRightsAccepted,
      'declarationPricingAccepted': declarationPricingAccepted,
      'declaration_pricing_accepted': declarationPricingAccepted,
      'declarationReviewAccepted': declarationReviewAccepted,
      'declaration_review_accepted': declarationReviewAccepted,
      'declarationTermsAccepted': declarationTermsAccepted,
      'declaration_terms_accepted': declarationTermsAccepted,
      'declarations': declarations ??
          {
            'accuracy': declarationAccuracyAccepted,
            'authorization': declarationAuthorizationAccepted,
            'content_rights': declarationContentRightsAccepted,
            'pricing': declarationPricingAccepted,
            'review_consent': declarationReviewAccepted,
            'terms_agreement': declarationTermsAccepted,
          },
      'facing': facing,
      'furnishing': furnishing,
      'availability': availability,
      'amenities': amenities,
      'description': description,
      'intelligenceScore': intelligenceScore,
      'investmentScore': investmentScore,
      'ownershipStatus': ownershipStatus,
      'documentStatus': documentStatus,
      'riskLevel': riskLevel,
      'nearby': nearby,
      'nearby_infrastructure': nearby,
      'floorPlanUrl': floorPlanUrl,
      'floor_plan_url': floorPlanUrl,
      'reraDocumentUrl': reraDocumentUrl,
      'rera_document_url': reraDocumentUrl,
      'virtual_tour': virtualTour?.toMap(),
      'virtualTour': virtualTour?.toMap(),
      'virtualTourUrl': virtualTour?.panoramaUrl ?? virtualTourUrl,
      'virtual_tour_url': virtualTour?.panoramaUrl ?? virtualTourUrl,
      'model3DUrl': model3DUrl,
      'model_3d_url': model3DUrl,
      'model3DId': model3DId,
      'model_3d_id': model3DId,
      'arModelUrl': arModelUrl,
      'ar_model_url': arModelUrl,
      'floorPlan2DUrl': floorPlan2DUrl,
      'floor_plan_2d_url': floorPlan2DUrl,
      'floorPlan3DUrl': floorPlan3DUrl,
      'floor_plan_3d_url': floorPlan3DUrl,
      'floorPlanRooms': floorPlanRooms.map((r) => r.toMap()).toList(),
      'floor_plan_rooms': floorPlanRooms.map((r) => r.toMap()).toList(),
      'interiorConcepts': interiorConcepts.map((i) => i.toMap()).toList(),
      'interior_concepts': interiorConcepts.map((i) => i.toMap()).toList(),
      'exteriorConcepts': exteriorConcepts.map((e) => e.toMap()).toList(),
      'exterior_concepts': exteriorConcepts.map((e) => e.toMap()).toList(),
      'vastuData': vastuData?.toMap(),
      'vastu_data': vastuData?.toMap(),
      'droneTourAvailable': droneTourAvailable,
      'drone_tour_available': droneTourAvailable,
      'droneTourUrl': droneTourUrl,
      'drone_tour_url': droneTourUrl,
      'droneTourThumbnail': droneTourThumbnail,
      'drone_tour_thumbnail': droneTourThumbnail,
      'droneTourDuration': droneTourDuration,
      'drone_tour_duration': droneTourDuration,
      'droneTourAccessType': droneTourAccessType,
      'drone_tour_access_type': droneTourAccessType,
      'droneFlightAltitudeMeters': droneFlightAltitudeMeters,
      'drone_flight_altitude_meters': droneFlightAltitudeMeters,
      'droneAerialPoints': droneAerialPoints,
      'drone_aerial_points': droneAerialPoints,
      'youtubeVideoId': youtubeVideoId,
      'youtube_video_id': youtubeVideoId,
      'youtubeUrl': youtubeUrl,
      'youtube_url': youtubeUrl,
      'optimizedThumbnailUrl': optimizedThumbnailUrl,
      'optimized_thumbnail_url': optimizedThumbnailUrl,
      'optimizedMediumUrl': optimizedMediumUrl,
      'optimized_medium_url': optimizedMediumUrl,
      'duplicate_status': duplicateStatus,
      'duplicate_of_property_id': duplicateOfPropertyId,
      'availability_status': availabilityStatus,
      'quality_score': qualityScore,
      're_review_required': reReviewRequired,
      'internal_admin_notes': internalAdminNotes,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  /// Deserialization from Map / JSON
  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id']?.toString() ?? 'prop_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title']?.toString() ?? map['name']?.toString() ?? 'Property Listing',
      sector: map['sector']?.toString() ?? map['locality']?.toString() ?? 'Noida',
      city: map['city']?.toString() ?? 'Noida',
      locality: map['locality']?.toString() ?? map['sector']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      postalCode: map['postalCode']?.toString() ?? map['postal_code']?.toString() ?? map['pincode']?.toString() ?? '',
      placeId: map['placeId']?.toString() ?? map['place_id']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 28.4354,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 77.4878,
      category: map['category']?.toString() ?? 'Residential',
      propertyType: map['propertyType']?.toString() ?? map['property_type']?.toString() ?? 'Apartment',
      askingPriceCr: (map['askingPriceCr'] as num?)?.toDouble() ?? (map['price_cr'] as num?)?.toDouble() ?? ((map['price'] as num?) != null ? (map['price'] as num).toDouble() / 10000000 : 0.0),
      fairValueCr: (map['fairValueCr'] as num?)?.toDouble() ?? (map['askingPriceCr'] as num?)?.toDouble() ?? 0.0,
      originalPriceCr: (map['originalPriceCr'] as num?)?.toDouble(),
      discountPercent: (map['discountPercent'] as num?)?.toInt(),
      priceRangeDisplay: map['priceRangeDisplay']?.toString() ?? map['price']?.toString() ?? '',
      pricePerSqft: (map['pricePerSqft'] as num?)?.toDouble() ?? 0.0,
      score10x: (map['score10x'] as num?)?.toDouble() ?? 9.0,
      rentalYieldPercent: (map['rentalYieldPercent'] as num?)?.toDouble() ?? 4.5,
      sqft: (map['sqft'] as num?)?.toInt() ?? (map['area'] as num?)?.toInt() ?? 1000,
      carpetAreaSqft: (map['carpetAreaSqft'] as num?)?.toInt() ?? (map['carpet_area'] as num?)?.toInt() ?? 800,
      bhk: map['bhk']?.toString() ?? '2 BHK',
      bhkOptions: (map['bhkOptions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: map['imageUrl']?.toString() ?? map['image_url']?.toString() ?? '',
      galleryImages: (map['galleryImages'] as List?)?.map((e) => e.toString()).toList() ??
          (map['images'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      isVerified: map['isVerified'] == true || map['is_verified'] == true,
      isZeroBroker: map['isZeroBroker'] != false,
      isReraApproved: map['isReraApproved'] != false,
      reraId: map['reraId']?.toString() ?? map['rera_id']?.toString() ?? 'UPRERAPRJ123456',
      statusTag: map['statusTag']?.toString() ?? map['status_tag']?.toString() ?? 'Featured',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 50,
      builderName: map['builderName']?.toString() ?? map['developer']?.toString() ?? 'Propzen Prime Developers',
      projectName: map['projectName']?.toString() ?? map['project_name']?.toString() ?? '',
      floorNumber: (map['floorNumber'] as num?)?.toInt() ?? (map['floor_number'] as num?)?.toInt() ?? (map['floor'] as num?)?.toInt(),
      totalFloors: (map['totalFloors'] as num?)?.toInt() ?? (map['total_floors'] as num?)?.toInt(),
      parkingSlots: (map['parkingSlots'] as num?)?.toInt() ?? (map['parking_slots'] as num?)?.toInt() ?? (map['parking'] as num?)?.toInt() ?? 1,
      constructionStatus: map['constructionStatus']?.toString() ?? map['construction_status']?.toString() ?? 'Ready to Move',
      contactPreference: map['contactPreference']?.toString() ?? map['contact_preference']?.toString() ?? 'WhatsApp & Call',
      viewsCount: (map['viewsCount'] as num?)?.toInt() ?? (map['views_count'] as num?)?.toInt() ?? (map['views'] as num?)?.toInt() ?? 0,
      enquiriesCount: (map['enquiriesCount'] as num?)?.toInt() ?? (map['enquiries_count'] as num?)?.toInt() ?? (map['enquiries'] as num?)?.toInt() ?? 0,
      siteVisitsCount: (map['siteVisitsCount'] as num?)?.toInt() ?? (map['site_visits_count'] as num?)?.toInt() ?? (map['site_visits'] as num?)?.toInt() ?? 0,
      leadsCount: (map['leadsCount'] as num?)?.toInt() ?? (map['leads_count'] as num?)?.toInt() ?? (map['leads'] as num?)?.toInt() ?? 0,
      mediaList: (map['mediaList'] as List?)?.map((m) => PropertyMediaItem.fromMap(m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map))).toList() ??
          (map['media_list'] as List?)?.map((m) => PropertyMediaItem.fromMap(m is Map<String, dynamic> ? m : Map<String, dynamic>.from(m as Map))).toList() ??
          const [],
      dealerId: map['dealerId']?.toString() ?? map['dealer_id']?.toString() ?? '',
      dealerName: map['dealerName']?.toString() ?? map['contact_name']?.toString() ?? '',
      dealerPhone: map['dealerPhone']?.toString() ?? map['contact_phone']?.toString() ?? '',
      dealerEmail: map['dealerEmail']?.toString() ?? map['dealer_email']?.toString() ?? map['contact_email']?.toString() ?? '',
      contactName: map['contactName']?.toString() ?? map['contact_name']?.toString() ?? map['owner_name']?.toString() ?? '',
      contactPhone: map['contactPhone']?.toString() ?? map['contact_phone']?.toString() ?? map['owner_phone']?.toString() ?? '',
      contactEmail: map['contactEmail']?.toString() ?? map['contact_email']?.toString() ?? '',
      possessionDate: map['possessionDate']?.toString() ?? 'Ready to Move',
      status: map['status']?.toString() ?? 'published',
      adminNote: map['adminNote']?.toString() ?? map['admin_note']?.toString(),
      approvedAt: map['approvedAt']?.toString() ?? map['approved_at']?.toString(),
      approvedBy: map['approvedBy']?.toString() ?? map['approved_by']?.toString(),
      reraStatus: map['reraStatus']?.toString() ?? map['rera_status']?.toString() ?? 'Approved',
      possessionStatus: map['possessionStatus']?.toString() ?? map['possession_status']?.toString() ?? 'Ready to Move',
      furnishingStatus: map['furnishingStatus']?.toString() ?? map['furnishing_status']?.toString() ?? 'Semi-Furnished',
      createdAt: map['createdAt']?.toString() ?? map['created_at']?.toString(),
      updatedAt: map['updatedAt']?.toString() ?? map['updated_at']?.toString(),
      termsAccepted: map['termsAccepted'] == true || map['terms_accepted'] == true,
      termsVersion: map['termsVersion']?.toString() ?? map['terms_version']?.toString() ?? '1.0',
      termsAcceptedAt: map['termsAcceptedAt']?.toString() ?? map['terms_accepted_at']?.toString(),
      termsAcceptedBy: map['termsAcceptedBy']?.toString() ?? map['terms_accepted_by']?.toString(),
      declarationAccuracyAccepted: map['declarationAccuracyAccepted'] == true || map['declaration_accuracy_accepted'] == true,
      declarationAuthorizationAccepted: map['declarationAuthorizationAccepted'] == true || map['declaration_authorization_accepted'] == true,
      declarationContentRightsAccepted: map['declarationContentRightsAccepted'] == true || map['declaration_content_rights_accepted'] == true,
      declarationPricingAccepted: map['declarationPricingAccepted'] == true || map['declaration_pricing_accepted'] == true,
      declarationReviewAccepted: map['declarationReviewAccepted'] == true || map['declaration_review_accepted'] == true,
      declarationTermsAccepted: map['declarationTermsAccepted'] == true || map['declaration_terms_accepted'] == true,
      declarations: map['declarations'] as Map<String, dynamic>?,
      facing: map['facing']?.toString() ?? 'East',
      furnishing: map['furnishing']?.toString() ?? map['furnishing_status']?.toString() ?? 'Semi-Furnished',
      availability: map['availability']?.toString() ?? map['possession_status']?.toString() ?? 'Ready to Move',
      amenities: (map['amenities'] as List?)?.map((e) => e.toString()).toList() ?? const [
        'Club House',
        'Swimming Pool',
        'Gym',
        '24/7 Security',
        'Power Backup',
        'Lift',
        'Parking'
      ],
      description: map['description']?.toString() ?? 'Premium property in prime growth corridor.',
      intelligenceScore: (map['intelligenceScore'] as num?)?.toInt() ?? 88,
      investmentScore: (map['investmentScore'] as num?)?.toInt() ?? 92,
      ownershipStatus: map['ownershipStatus']?.toString() ?? 'Verified',
      documentStatus: map['documentStatus']?.toString() ?? 'Verified',
      riskLevel: map['riskLevel']?.toString() ?? 'LOW',
      floorPlanUrl: map['floorPlanUrl']?.toString() ?? map['floor_plan_url']?.toString() ?? map['floor_plan']?.toString(),
      reraDocumentUrl: map['reraDocumentUrl']?.toString() ?? map['rera_document_url']?.toString(),
      virtualTour: map['virtualTour'] != null
          ? VirtualTourData.fromMap(map['virtualTour'] is Map<String, dynamic> ? map['virtualTour'] : Map<String, dynamic>.from(map['virtualTour'] as Map))
          : (map['virtual_tour'] != null
              ? VirtualTourData.fromMap(map['virtual_tour'] is Map<String, dynamic> ? map['virtual_tour'] : Map<String, dynamic>.from(map['virtual_tour'] as Map))
              : (map['virtualTourUrl'] != null || map['virtual_tour_url'] != null
                  ? VirtualTourData(panoramaUrl: (map['virtualTourUrl'] ?? map['virtual_tour_url'])?.toString())
                  : null)),
      virtualTourUrl: map['virtualTourUrl']?.toString() ?? map['virtual_tour_url']?.toString(),
      model3DUrl: map['model3DUrl']?.toString() ?? map['model_3d_url']?.toString(),
      model3DId: map['model3DId']?.toString() ?? map['model_3d_id']?.toString(),
      arModelUrl: map['arModelUrl']?.toString() ?? map['ar_model_url']?.toString(),
      floorPlan2DUrl: map['floorPlan2DUrl']?.toString() ?? map['floor_plan_2d_url']?.toString() ?? map['floorPlanUrl']?.toString() ?? map['floor_plan_url']?.toString(),
      floorPlan3DUrl: map['floorPlan3DUrl']?.toString() ?? map['floor_plan_3d_url']?.toString(),
      floorPlanRooms: (map['floorPlanRooms'] as List?)?.map((r) => FloorPlanRoom.fromMap(r as Map<String, dynamic>)).toList() ??
          (map['floor_plan_rooms'] as List?)?.map((r) => FloorPlanRoom.fromMap(r as Map<String, dynamic>)).toList() ??
          const [],
      interiorConcepts: (map['interiorConcepts'] as List?)?.map((i) => InteriorConcept.fromMap(i as Map<String, dynamic>)).toList() ??
          (map['interior_concepts'] as List?)?.map((i) => InteriorConcept.fromMap(i as Map<String, dynamic>)).toList() ??
          const [],
      exteriorConcepts: (map['exteriorConcepts'] as List?)?.map((e) => ExteriorConcept.fromMap(e as Map<String, dynamic>)).toList() ??
          (map['exterior_concepts'] as List?)?.map((e) => ExteriorConcept.fromMap(e as Map<String, dynamic>)).toList() ??
          const [],
      vastuData: map['vastuData'] != null
          ? VastuGuidanceData.fromMap(map['vastuData'] as Map<String, dynamic>)
          : (map['vastu_data'] != null ? VastuGuidanceData.fromMap(map['vastu_data'] as Map<String, dynamic>) : null),
      droneTourAvailable: map['droneTourAvailable'] == true || map['drone_tour_available'] == true,
      droneTourUrl: map['droneTourUrl']?.toString() ?? map['drone_tour_url']?.toString(),
      droneTourThumbnail: map['droneTourThumbnail']?.toString() ?? map['drone_tour_thumbnail']?.toString(),
      droneTourDuration: map['droneTourDuration']?.toString() ?? map['drone_tour_duration']?.toString() ?? '2:45',
      droneTourAccessType: map['droneTourAccessType']?.toString() ?? map['drone_tour_access_type']?.toString() ?? 'nri_exclusive',
      droneFlightAltitudeMeters: (map['droneFlightAltitudeMeters'] as num?)?.toInt() ?? (map['drone_flight_altitude_meters'] as num?)?.toInt() ?? 120,
      droneAerialPoints: (map['droneAerialPoints'] as List?)?.map((e) => e.toString()).toList() ??
          (map['drone_aerial_points'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      youtubeVideoId: map['youtubeVideoId']?.toString() ?? map['youtube_video_id']?.toString(),
      youtubeUrl: map['youtubeUrl']?.toString() ?? map['youtube_url']?.toString(),
      optimizedThumbnailUrl: map['optimizedThumbnailUrl']?.toString() ?? map['optimized_thumbnail_url']?.toString(),
      optimizedMediumUrl: map['optimizedMediumUrl']?.toString() ?? map['optimized_medium_url']?.toString(),
      duplicateStatus: map['duplicate_status']?.toString() ?? map['duplicateStatus']?.toString() ?? 'normal',
      duplicateOfPropertyId: map['duplicate_of_property_id']?.toString() ?? map['duplicateOfPropertyId']?.toString(),
      availabilityStatus: map['availability_status']?.toString() ?? map['availability']?.toString() ?? 'Available',
      qualityScore: (map['quality_score'] as num?)?.toInt() ?? (map['intelligenceScore'] as num?)?.toInt() ?? 88,
      reReviewRequired: map['re_review_required'] == true || map['reReviewRequired'] == true,
      internalAdminNotes: map['internal_admin_notes']?.toString() ?? map['internalAdminNotes']?.toString(),
      nearby: (map['nearby'] is Map)
          ? (map['nearby'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : ((map['nearby_infrastructure'] is Map)
              ? (map['nearby_infrastructure'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
              : ((map['infrastructure'] is Map)
                  ? (map['infrastructure'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
                  : const {})),
    );
  }

  factory Property.fromJson(Map<String, dynamic> json) => Property.fromMap(json);

  Property copyWith({
    String? id,
    String? title,
    String? sector,
    String? city,
    String? locality,
    String? address,
    String? postalCode,
    String? placeId,
    double? latitude,
    double? longitude,
    String? category,
    String? propertyType,
    double? askingPriceCr,
    double? fairValueCr,
    double? originalPriceCr,
    int? discountPercent,
    String? priceRangeDisplay,
    double? pricePerSqft,
    double? score10x,
    double? rentalYieldPercent,
    int? sqft,
    int? carpetAreaSqft,
    String? bhk,
    List<String>? bhkOptions,
    String? imageUrl,
    List<String>? galleryImages,
    bool? isVerified,
    bool? isZeroBroker,
    bool? isReraApproved,
    String? reraId,
    String? statusTag,
    double? rating,
    int? reviewCount,
    String? builderName,
    String? dealerId,
    String? dealerName,
    String? dealerPhone,
    String? dealerEmail,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? possessionDate,
    String? status,
    String? adminNote,
    String? approvedAt,
    String? approvedBy,
    String? reraStatus,
    String? possessionStatus,
    String? furnishingStatus,
    String? createdAt,
    String? updatedAt,
    bool? termsAccepted,
    String? termsVersion,
    String? termsAcceptedAt,
    String? termsAcceptedBy,
    bool? declarationAccuracyAccepted,
    bool? declarationAuthorizationAccepted,
    bool? declarationContentRightsAccepted,
    bool? declarationPricingAccepted,
    bool? declarationReviewAccepted,
    bool? declarationTermsAccepted,
    Map<String, dynamic>? declarations,
    String? facing,
    String? furnishing,
    String? availability,
    List<String>? amenities,
    String? description,
    int? intelligenceScore,
    int? investmentScore,
    String? ownershipStatus,
    String? documentStatus,
    String? riskLevel,
    Map<String, String>? nearby,
    String? floorPlanUrl,
    String? reraDocumentUrl,
    VirtualTourData? virtualTour,
    String? virtualTourUrl,
    String? model3DUrl,
    String? model3DId,
    String? arModelUrl,
    String? floorPlan2DUrl,
    String? floorPlan3DUrl,
    List<FloorPlanRoom>? floorPlanRooms,
    List<InteriorConcept>? interiorConcepts,
    List<ExteriorConcept>? exteriorConcepts,
    VastuGuidanceData? vastuData,
    bool? droneTourAvailable,
    String? droneTourUrl,
    String? droneTourThumbnail,
    String? droneTourDuration,
    String? droneTourAccessType,
    int? droneFlightAltitudeMeters,
    List<String>? droneAerialPoints,
    String? youtubeVideoId,
    String? youtubeUrl,
    String? optimizedThumbnailUrl,
    String? optimizedMediumUrl,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      sector: sector ?? this.sector,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      propertyType: propertyType ?? this.propertyType,
      askingPriceCr: askingPriceCr ?? this.askingPriceCr,
      fairValueCr: fairValueCr ?? this.fairValueCr,
      originalPriceCr: originalPriceCr ?? this.originalPriceCr,
      discountPercent: discountPercent ?? this.discountPercent,
      priceRangeDisplay: priceRangeDisplay ?? this.priceRangeDisplay,
      pricePerSqft: pricePerSqft ?? this.pricePerSqft,
      score10x: score10x ?? this.score10x,
      rentalYieldPercent: rentalYieldPercent ?? this.rentalYieldPercent,
      sqft: sqft ?? this.sqft,
      carpetAreaSqft: carpetAreaSqft ?? this.carpetAreaSqft,
      bhk: bhk ?? this.bhk,
      bhkOptions: bhkOptions ?? this.bhkOptions,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      isVerified: isVerified ?? this.isVerified,
      isZeroBroker: isZeroBroker ?? this.isZeroBroker,
      isReraApproved: isReraApproved ?? this.isReraApproved,
      reraId: reraId ?? this.reraId,
      statusTag: statusTag ?? this.statusTag,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      builderName: builderName ?? this.builderName,
      dealerId: dealerId ?? this.dealerId,
      dealerName: dealerName ?? this.dealerName,
      dealerPhone: dealerPhone ?? this.dealerPhone,
      dealerEmail: dealerEmail ?? this.dealerEmail,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      possessionDate: possessionDate ?? this.possessionDate,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      reraStatus: reraStatus ?? this.reraStatus,
      possessionStatus: possessionStatus ?? this.possessionStatus,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsVersion: termsVersion ?? this.termsVersion,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      termsAcceptedBy: termsAcceptedBy ?? this.termsAcceptedBy,
      declarationAccuracyAccepted: declarationAccuracyAccepted ?? this.declarationAccuracyAccepted,
      declarationAuthorizationAccepted: declarationAuthorizationAccepted ?? this.declarationAuthorizationAccepted,
      declarationContentRightsAccepted: declarationContentRightsAccepted ?? this.declarationContentRightsAccepted,
      declarationPricingAccepted: declarationPricingAccepted ?? this.declarationPricingAccepted,
      declarationReviewAccepted: declarationReviewAccepted ?? this.declarationReviewAccepted,
      declarationTermsAccepted: declarationTermsAccepted ?? this.declarationTermsAccepted,
      declarations: declarations ?? this.declarations,
      facing: facing ?? this.facing,
      furnishing: furnishing ?? this.furnishing,
      availability: availability ?? this.availability,
      amenities: amenities ?? this.amenities,
      description: description ?? this.description,
      intelligenceScore: intelligenceScore ?? this.intelligenceScore,
      investmentScore: investmentScore ?? this.investmentScore,
      ownershipStatus: ownershipStatus ?? this.ownershipStatus,
      documentStatus: documentStatus ?? this.documentStatus,
      riskLevel: riskLevel ?? this.riskLevel,
      nearby: nearby ?? this.nearby,
      floorPlanUrl: floorPlanUrl ?? this.floorPlanUrl,
      reraDocumentUrl: reraDocumentUrl ?? this.reraDocumentUrl,
      virtualTour: virtualTour ?? this.virtualTour,
      virtualTourUrl: virtualTourUrl ?? this.virtualTourUrl,
      model3DUrl: model3DUrl ?? this.model3DUrl,
      model3DId: model3DId ?? this.model3DId,
      arModelUrl: arModelUrl ?? this.arModelUrl,
      floorPlan2DUrl: floorPlan2DUrl ?? this.floorPlan2DUrl,
      floorPlan3DUrl: floorPlan3DUrl ?? this.floorPlan3DUrl,
      floorPlanRooms: floorPlanRooms ?? this.floorPlanRooms,
      interiorConcepts: interiorConcepts ?? this.interiorConcepts,
      exteriorConcepts: exteriorConcepts ?? this.exteriorConcepts,
      vastuData: vastuData ?? this.vastuData,
      droneTourAvailable: droneTourAvailable ?? this.droneTourAvailable,
      droneTourUrl: droneTourUrl ?? this.droneTourUrl,
      droneTourThumbnail: droneTourThumbnail ?? this.droneTourThumbnail,
      droneTourDuration: droneTourDuration ?? this.droneTourDuration,
      droneTourAccessType: droneTourAccessType ?? this.droneTourAccessType,
      droneFlightAltitudeMeters: droneFlightAltitudeMeters ?? this.droneFlightAltitudeMeters,
      droneAerialPoints: droneAerialPoints ?? this.droneAerialPoints,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      optimizedThumbnailUrl: optimizedThumbnailUrl ?? this.optimizedThumbnailUrl,
      optimizedMediumUrl: optimizedMediumUrl ?? this.optimizedMediumUrl,
    );
  }

  /// Centralized Sample Properties with authentic NCR locality coordinates & full addresses for all 8 categories
  static const List<Property> sampleDeals = <Property>[
    // 1. ATS HOMEKRAFT HAPPY TRAILS (Noida Extension)
    Property(
      id: 'prop_ats_happytrails',
      title: 'ATS HomeKraft Happy Trails',
      sector: 'Sector 10, Noida Extension',
      city: 'Noida Extension',
      locality: 'Noida Extension',
      address: 'Plot GH-02, Sector 10, Greater Noida West / Noida Extension, Uttar Pradesh',
      postalCode: '201308',
      placeId: 'ChIJ_ats_happytrails_noida_ext',
      latitude: 28.6012,
      longitude: 77.4421,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 0.78,
      fairValueCr: 0.84,
      originalPriceCr: 0.84,
      priceRangeDisplay: '₹78 Lakh',
      pricePerSqft: 6782,
      score10x: 9.3,
      rentalYieldPercent: 4.9,
      sqft: 1150,
      carpetAreaSqft: 920,
      bhk: '2 BHK',
      bhkOptions: ['2 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ15574',
      statusTag: 'Ready to Move',
      rating: 4.8,
      reviewCount: 142,
      builderName: 'ATS HomeKraft',
      dealerId: '',
      dealerName: '',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      facing: 'North-East',
      amenities: [
        'Swimming Pool',
        'Gym',
        'Club House',
        'Parking',
        'Security',
        'Garden',
        'Lift',
        'Power Backup',
      ],
      description:
          'Premium 2 BHK apartment in ATS HomeKraft Happy Trails, Sector 10 Noida Extension. Green-facing corner unit with modern clubhouse and excellent connectivity to Central Noida.',
      nearby: {
        'Gaur City Mall': '2.5 km',
        'Sector 52 Metro': '8.0 km',
        'Fortis Hospital': '9.5 km',
        'FNG Expressway': '3.8 km',
      },
      virtualTour: VirtualTourData(
        title: 'ATS HomeKraft 360° Virtual Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'living-room',
            name: 'Living & Dining Hall',
            area: '320 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'master-suite',
            name: 'Master Suite',
            area: '210 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'balcony-deck',
            name: 'Panoramic Deck Balcony',
            area: '95 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
          VirtualTourRoom(
            id: 'modular-kitchen',
            name: 'Modular Chef Kitchen',
            area: '110 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1920&q=80',
            iconType: 'utensils',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed?autostart=1&internal=1&tracking=0&ui_infos=0&ui_watermark_link=0',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/ats_happytrails_ar.glb',
      floorPlan2DUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      floorPlan3DUrl: 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
      floorPlanRooms: [
        FloorPlanRoom(name: 'Living & Dining Hall', roomType: 'livingRoom', areaSqFt: 320, dimensions: '16\'0" x 20\'0"', features: ['East Balcony Access', 'Vitrified Marble Tiles']),
        FloorPlanRoom(name: 'Master Suite', roomType: 'masterBedroom', areaSqFt: 210, dimensions: '14\'0" x 15\'0"', features: ['Attached Bath', 'Walk-in Wardrobe Niche']),
        FloorPlanRoom(name: 'Guest / Child Bedroom', roomType: 'bedroom', areaSqFt: 160, dimensions: '12\'0" x 13\'4"', features: ['Wide Corner Window', 'Dedicated Wardrobe']),
        FloorPlanRoom(name: 'Modular Chef Kitchen', roomType: 'kitchen', areaSqFt: 110, dimensions: '10\'0" x 11\'0"', features: ['Utility Balcony Attached', 'Granite Platform']),
        FloorPlanRoom(name: 'Panoramic Deck Balcony', roomType: 'balcony', areaSqFt: 95, dimensions: '6\'0" x 16\'0"', features: ['Garden Facing View', 'Anti-skid Ceramic Tiles']),
        FloorPlanRoom(name: 'Ensuite Master Bath', roomType: 'bathroom', areaSqFt: 55, dimensions: '7\'0" x 8\'0"', features: ['Glass Shower Cubicle', 'Grohe Fittings']),
      ],
      interiorConcepts: [
        InteriorConcept(
          roomName: 'Living Room',
          roomType: 'livingRoom',
          previewImage: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
          wallColors: ['Alabaster White', 'Warm Greige', 'Sage Green Accent', 'Royal Navy'],
          flooringOptions: ['Italian Botticino Marble', 'Engineered Oak Hardwood', 'Matte Vitrified 1200x600'],
          furnitureStyles: ['Contemporary Minimalist', 'Modern Scandinavian', 'Luxury Velvet & Brass'],
          lightingConcepts: ['Warm Cove Ambient (2700K)', 'Architectural Magnetic Track', 'Sculptural Chandelier'],
          finishMaterials: ['Fluted Oak Panels', 'Brushed Brass Trims', 'Textured Linen Drapery'],
        ),
        InteriorConcept(
          roomName: 'Master Bedroom',
          roomType: 'masterBedroom',
          previewImage: 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
          wallColors: ['Misty Blue', 'Champagne Beige', 'Terracotta Accent', 'Charcoal Velvet'],
          flooringOptions: ['Warm Walnut Herringbone', 'Plush Silk Carpet', 'Light Maple Wood'],
          furnitureStyles: ['Bespoke Upholstered King', 'Scandinavian Platform Bed', 'Italian Leather Silhouette'],
          lightingConcepts: ['Dimmable Bedside Pendants', 'Concealed Headboard LEDs', 'Warm Reading Sconces'],
          finishMaterials: ['Tufted Leather Headboard', 'Acoustic Wood Slats', 'Blackout Velvet Curtains'],
        ),
        InteriorConcept(
          roomName: 'Modular Kitchen',
          roomType: 'kitchen',
          previewImage: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1200&q=80',
          wallColors: ['Crisp White Backsplash', 'Anthracite Matte', 'Sage Forest Green', 'Cashmere Gray'],
          flooringOptions: ['Anti-skid Quartz Terrazzo', 'Large Format Vitrified', 'Slate Gray Ceramic'],
          furnitureStyles: ['Handleless Soft-Close Acrylic', 'European Fluted Glass Upper', 'Matte Lacquered Island'],
          lightingConcepts: ['Under-Cabinet Task Lighting', 'Pendant Lights over Breakfast Bar', 'Profile Toe-Kick LEDs'],
          finishMaterials: ['Calacatta Gold Quartz', 'Brushed Copper Hardware', 'Heat-Resistant Glass Panel'],
        ),
      ],
      exteriorConcepts: [
        ExteriorConcept(
          styleName: 'Modern Contemporary',
          facadeMaterial: 'Terracotta Louvers, High-Grade Glass & Weather-shield White',
          exteriorColor: 'Warm White & Charcoal Gray',
          lightingConcept: 'Linear Facade Grazers (3000K Warm Glow)',
          landscapingConcept: 'Lush Japanese Zen Garden & Reflection Pool',
          previewImage: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        ),
        ExteriorConcept(
          styleName: 'Eco-Luxury Resort',
          facadeMaterial: 'Vertical Green Living Walls, Teak Wood Battens & Travertine Stone',
          exteriorColor: 'Earthy Sandstone & Forest Emerald',
          lightingConcept: 'Concealed Warm Tree Uplights & Canopy Glow',
          landscapingConcept: 'Tropical Palms, Waterfalls & Infinity Deck',
          previewImage: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        ),
        ExteriorConcept(
          styleName: 'Neo-Classical Minimalist',
          facadeMaterial: 'Dholpur Sandstone Cladding, Fluted Cornices & Black Aluminum Glass',
          exteriorColor: 'Beige Roman Stucco & Jet Black Trim',
          lightingConcept: 'Dramatic Uplight Sconces on Structural Columns',
          landscapingConcept: 'Symmetrical Manicured Lawns & Fountain Plaza',
          previewImage: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
        ),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'North-East',
        overallScore: 92,
        entranceDirection: 'North-East (Ishan Corner)',
        kitchenDirection: 'South-East (Agneya Corner)',
        masterBedroomDirection: 'South-West (Nairutya Corner)',
        livingAreaDirection: 'North / East Facing',
        balconyDirection: 'East Facing (Morning Sun)',
        toiletDirection: 'North-West (Vayavya Corner)',
        keyObservations: [
          'Main entrance faces North-East (Ishan Corner), maximizing morning natural light and positive cross-breeze.',
          'Kitchen positioned in South-East (Agneya Corner) for optimal energy and ventilation circulation.',
          'Master Bedroom located in South-West stability zone for peaceful living.',
          'Large East-facing panoramic balcony provides abundant natural sunlight throughout the morning hours.',
        ],
        roomDetails: [
          VastuRoomItem(room: 'Main Entrance', actualDirection: 'North-East', idealDirection: 'North-East', status: 'Optimal', note: 'Ishan corner entrance allows abundant sunrise illumination.'),
          VastuRoomItem(room: 'Kitchen', actualDirection: 'South-East', idealDirection: 'South-East', status: 'Optimal', note: 'Agneya fire element placement aligns with natural air currents.'),
          VastuRoomItem(room: 'Master Bedroom', actualDirection: 'South-West', idealDirection: 'South-West', status: 'Optimal', note: 'Nairutya earth element placement ensures privacy and tranquility.'),
          VastuRoomItem(room: 'Living Room', actualDirection: 'North-East', idealDirection: 'North-East / East', status: 'Favorable', note: 'Spacious central hub welcomes cross-ventilation.'),
          VastuRoomItem(room: 'Balcony', actualDirection: 'East', idealDirection: 'East / North', status: 'Optimal', note: 'East facing orientation provides refreshing morning sunlight.'),
          VastuRoomItem(room: 'Washroom / Toilets', actualDirection: 'North-West', idealDirection: 'North-West / West', status: 'Favorable', note: 'Vayavya wind direction placement keeps primary living spaces fresh.'),
        ],
      ),
      droneTourAvailable: true,
      droneTourUrl: 'https://assets.mixkit.co/videos/preview/mixkit-aerial-view-of-a-modern-residential-complex-41484-large.mp4',
      droneTourThumbnail: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
      droneTourDuration: '2:45',
      droneFlightAltitudeMeters: 120,
      droneAerialPoints: [
        'Tower A & B Quad 360°',
        'Clubhouse & Olympic Pool',
        'Green Buffer Belt',
        'FNG Corridor View',
      ],
    ),

    // 2. GAUR CITY (Noida Extension)
    Property(
      id: 'prop_gaur_city',
      title: 'Gaur City',
      sector: 'Sector 4, Noida Extension',
      city: 'Noida Extension',
      locality: 'Noida Extension',
      address: 'Gaur City 1, Sector 4, Greater Noida West / Noida Extension, Uttar Pradesh',
      postalCode: '201308',
      placeId: 'ChIJ_gaur_city_noida_ext',
      latitude: 28.6085,
      longitude: 77.4298,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 1.05,
      fairValueCr: 1.12,
      originalPriceCr: 1.12,
      priceRangeDisplay: '₹1.05 Crore',
      pricePerSqft: 7241,
      score10x: 9.4,
      rentalYieldPercent: 5.1,
      sqft: 1450,
      carpetAreaSqft: 1180,
      bhk: '3 BHK',
      bhkOptions: ['3 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ6782',
      statusTag: 'Ready to Move',
      rating: 4.7,
      reviewCount: 188,
      builderName: 'Gaurs Group',
      dealerId: '',
      dealerName: '',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        'Swimming Pool',
        'Gym',
        'Shopping Complex',
        'Club House',
        'Security',
        'Lift',
        'Parking',
      ],
      description:
          'Spacious 3 BHK apartment in Gaur City, Noida Extension right opposite Gaur City Mall with ready metro link and 100+ retail outlets within township.',
      nearby: {
        'Gaur City Mall': '100 m',
        'Char Murti Chowk': '500 m',
        'Sector 52 Metro': '7.2 km',
        'NH-24 Expressway': '5.0 km',
      },
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: null,
      floorPlanRooms: [
        FloorPlanRoom(name: 'Living & Dining Hall', roomType: 'livingRoom', areaSqFt: 340, dimensions: '17\'0" x 20\'0"', features: ['Mall View Balcony Access', 'Imported Tiles']),
        FloorPlanRoom(name: 'Master Bedroom Suite', roomType: 'masterBedroom', areaSqFt: 220, dimensions: '14\'0" x 16\'0"', features: ['Ensuite Bath', 'Dressing Niche']),
        FloorPlanRoom(name: 'Bedroom 2', roomType: 'bedroom', areaSqFt: 170, dimensions: '12\'0" x 14\'2"', features: ['Corner Bay Window', 'Attached Bath']),
        FloorPlanRoom(name: 'Bedroom 3', roomType: 'bedroom', areaSqFt: 140, dimensions: '11\'0" x 13\'0"', features: ['Wide Window', 'Study Desk Space']),
        FloorPlanRoom(name: 'Modular Kitchen', roomType: 'kitchen', areaSqFt: 115, dimensions: '10\'0" x 11\'6"', features: ['Utility Balcony Attached', 'Quartz Counter']),
        FloorPlanRoom(name: 'Panoramic Deck Balcony', roomType: 'balcony', areaSqFt: 105, dimensions: '6\'0" x 17\'6"', features: ['Char Murti Chowk View', 'Anti-skid Ceramic']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'East (Indra)',
        overallScore: 88,
        entranceDirection: 'East Facing Entrance',
        kitchenDirection: 'South-East (Agneya)',
        masterBedroomDirection: 'South-West (Nairutya)',
        livingAreaDirection: 'East Facing',
        balconyDirection: 'East Facing Deck',
        toiletDirection: 'North-West',
        keyObservations: [
          'Direct East-facing entrance welcomes natural morning sunlight.',
          'Balcony positioned to capture dawn breezes and natural daylight.',
          'South-West master bedroom ensures structural stability and peaceful sleep.',
        ],
      ),
    ),

    // 3. ACE DIVINO (Noida Extension)
    Property(
      id: 'prop_ace_divino',
      title: 'Ace Divino',
      sector: 'Sector 1, Noida Extension',
      city: 'Noida Extension',
      locality: 'Noida Extension',
      address: 'Plot GH-01, Sector 1, Greater Noida West / Noida Extension, Uttar Pradesh',
      postalCode: '201308',
      placeId: 'ChIJ_ace_divino_noida_ext',
      latitude: 28.6140,
      longitude: 77.4520,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 1.25,
      fairValueCr: 1.35,
      priceRangeDisplay: '₹1.25 Crore',
      pricePerSqft: 7575,
      score10x: 9.5,
      rentalYieldPercent: 4.7,
      sqft: 1650,
      carpetAreaSqft: 1320,
      bhk: '3 BHK',
      bhkOptions: ['3 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ3898',
      statusTag: 'New Launch',
      rating: 4.9,
      reviewCount: 96,
      builderName: 'Ace Group',
      dealerId: 'DLR-NOIDA-102',
      dealerName: 'Sunita Sharma',
      possessionDate: 'Dec 2026',
      availability: 'Under Construction',
      furnishing: 'Unfurnished',
      facing: 'North',
      amenities: [
        'Zen Garden',
        'Skywalk',
        'Temperature Controlled Pool',
        'Gym',
        'Club House',
        'Amphitheatre',
        'Security',
        'Lift',
      ],
      description:
          'Modern 3 BHK luxury apartment in Ace Divino, Noida Extension. Features Zen garden, amphitheatre, temperature-controlled swimming pool, and skywalk.',
      nearby: {
        'FNG Expressway': '2.0 km',
        'Sector 76 Metro': '6.5 km',
        'Yatharth Super Speciality Hospital': '4.0 km',
        'Gaur City Plaza': '3.1 km',
      },
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: null,
      floorPlanRooms: [
        FloorPlanRoom(name: 'Grand Living & Dining', roomType: 'livingRoom', areaSqFt: 360, dimensions: '18\'0" x 20\'0"', features: ['Skywalk View Balcony', 'Imported Marble']),
        FloorPlanRoom(name: 'Zen Master Suite', roomType: 'masterBedroom', areaSqFt: 230, dimensions: '15\'0" x 15\'4"', features: ['Attached Bath', 'Walk-in Wardrobe']),
        FloorPlanRoom(name: 'Bedroom 2', roomType: 'bedroom', areaSqFt: 180, dimensions: '13\'0" x 14\'0"', features: ['Garden Facing View', 'Ensuite Bath']),
        FloorPlanRoom(name: 'Bedroom 3', roomType: 'bedroom', areaSqFt: 150, dimensions: '12\'0" x 12\'6"', features: ['Large Corner Window', 'Dedicated Niche']),
        FloorPlanRoom(name: 'Modular Island Kitchen', roomType: 'kitchen', areaSqFt: 125, dimensions: '10\'6" x 12\'0"', features: ['Dry + Wet Utility', 'Granite Platform']),
        FloorPlanRoom(name: 'Skywalk Balcony Deck', roomType: 'balcony', areaSqFt: 110, dimensions: '6\'0" x 18\'4"', features: ['Pool & Zen Garden View', 'Anti-skid Flooring']),
      ],
      vastuData: VastuGuidanceData(
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
          'Living space enjoys glare-free northern lighting throughout afternoon.',
          'Kitchen in South-East prevents cooking heat from entering living quarters.',
        ],
      ),
    ),

    // 4. TATA EUREKA PARK (Sector 150, Noida)
    Property(
      id: 'prop_tata_eureka_150',
      title: 'Tata Eureka Park',
      sector: 'Sector 150',
      city: 'Noida',
      locality: 'Sector 150',
      address: 'Plot SC-01, Sector 150, Noida-Greater Noida Expressway, Noida, Uttar Pradesh',
      postalCode: '201310',
      placeId: 'ChIJ_tata_eureka_150_noida',
      latitude: 28.4380,
      longitude: 77.4850,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 0.95,
      fairValueCr: 1.02,
      originalPriceCr: 1.02,
      priceRangeDisplay: '₹95 Lakh',
      pricePerSqft: 7600,
      score10x: 9.5,
      rentalYieldPercent: 4.8,
      sqft: 1250,
      carpetAreaSqft: 980,
      bhk: '2 BHK',
      bhkOptions: ['2 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ5448',
      statusTag: 'Ready to Move',
      rating: 4.9,
      reviewCount: 165,
      builderName: 'Tata Housing',
      dealerId: '',
      dealerName: '',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        'App-Controlled Home Automation',
        'Swimming Pool',
        'Gym',
        'Club House',
        'Tennis Court',
        'Security',
        'Lift',
        'Power Backup',
      ],
      description:
          'Smart 2 BHK smart-home automated apartment in Tata Eureka Park, Sector 150 Noida. App-controlled lighting, digital locks, and international-standard sports arena.',
      nearby: {
        'Sector 148 Metro': '1.5 km',
        'Shaheed Bhagat Singh Park': '600 m',
        'Noida Expressway': '1.2 km',
        'Jewar Airport Link': '30 km',
      },
      virtualTour: VirtualTourData(
        title: 'Tata Eureka Park 360° Smart Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'smart-hall',
            name: 'Smart Living Hall',
            area: '290 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'master-bedroom',
            name: 'Master Bedroom',
            area: '190 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'tech-balcony',
            name: 'Expressway View Balcony',
            area: '85 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
    ),

    // 5. ATS PIOUS ORCHARDS (Sector 150, Noida)
    Property(
      id: 'prop_ats_pious_150',
      title: 'ATS Pious Orchards',
      sector: 'Sector 150',
      city: 'Noida',
      locality: 'Sector 150',
      address: 'Sector 150, Noida-Greater Noida Expressway, Noida, Uttar Pradesh',
      postalCode: '201310',
      placeId: 'ChIJ_ats_pious_150_noida',
      latitude: 28.4320,
      longitude: 77.4910,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 1.55,
      fairValueCr: 1.68,
      originalPriceCr: 1.68,
      priceRangeDisplay: '₹1.55 Crore',
      pricePerSqft: 8857,
      score10x: 9.6,
      rentalYieldPercent: 4.6,
      sqft: 1750,
      carpetAreaSqft: 1420,
      bhk: '3 BHK',
      bhkOptions: ['3 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ18324',
      statusTag: 'Ready to Move',
      rating: 4.9,
      reviewCount: 154,
      builderName: 'ATS Greens',
      dealerId: 'DLR-NOIDA-102',
      dealerName: 'Sunita Sharma',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        'Orchard Walkways',
        'Infinity Pool',
        'Gym',
        'Club House',
        'River View Deck',
        'Security',
        'Lift',
      ],
      description:
          'Low-density 3 BHK river-view residence in ATS Pious Orchards, Sector 150 Noida. 80% green landscape, orchards, jogging track, and state-of-the-art clubhouse.',
      nearby: {
        'Yamuna Riverfront': '400 m',
        'Sector 148 Metro': '2.0 km',
        'Amity University': '15 km',
        'Jaypee Hospital': '12 km',
      },
      virtualTour: VirtualTourData(
        title: 'ATS Pious Orchards 360° Riverfront Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'pious-living',
            name: 'River View Drawing Room',
            area: '380 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'pious-master',
            name: 'Orchard Master Suite',
            area: '240 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'pious-deck',
            name: 'Yamuna Riverfront Balcony Deck',
            area: '130 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/ats_pious_orchards_ar.glb',
      floorPlanRooms: [
        FloorPlanRoom(name: 'River View Drawing & Dining', roomType: 'livingRoom', areaSqFt: 380, dimensions: '19\'0" x 20\'0"', features: ['Yamuna River View Deck', 'Italian Botticino Marble']),
        FloorPlanRoom(name: 'Orchard Master Suite', roomType: 'masterBedroom', areaSqFt: 240, dimensions: '15\'0" x 16\'0"', features: ['Attached Bath', 'Walk-in Wardrobe']),
        FloorPlanRoom(name: 'Bedroom 2', roomType: 'bedroom', areaSqFt: 190, dimensions: '13\'6" x 14\'0"', features: ['Garden View', 'Attached Washroom']),
        FloorPlanRoom(name: 'Bedroom 3 / Study', roomType: 'bedroom', areaSqFt: 160, dimensions: '12\'0" x 13\'4"', features: ['Corner Bay Window', 'Study Desk Space']),
        FloorPlanRoom(name: 'Modular Chef Kitchen', roomType: 'kitchen', areaSqFt: 130, dimensions: '11\'0" x 12\'0"', features: ['Dry Pantry', 'Granite Slab Counter']),
        FloorPlanRoom(name: 'Riverfront Panoramic Deck', roomType: 'balcony', areaSqFt: 130, dimensions: '7\'0" x 18\'6"', features: ['Unobstructed Green Riverfront', 'Anti-skid Decking']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'North-East (Ishanya)',
        overallScore: 92,
        entranceDirection: 'North-East Entrance',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'East Facing Riverfront',
        balconyDirection: 'North-East Deck',
        toiletDirection: 'North-West',
        keyObservations: [
          'North-East entrance aligns with positive solar illumination and river cross-ventilation.',
          'Kitchen in South-East corresponds to Vedic fire quadrant.',
          'Master bedroom in South-West stability zone ensures tranquility.',
        ],
      ),
    ),

    // 6. GODREJ PALM RETREAT (Sector 150, Noida)
    Property(
      id: 'prop_godrej_palm_150',
      title: 'Godrej Palm Retreat',
      sector: 'Sector 150',
      city: 'Noida',
      locality: 'Sector 150',
      address: 'Plot SC-02, Sector 150, Noida-Greater Noida Expressway, Noida, Uttar Pradesh',
      postalCode: '201310',
      placeId: 'ChIJ_godrej_palm_150_noida',
      latitude: 28.4365,
      longitude: 77.4892,
      category: 'Residential',
      propertyType: 'Luxury Apartment',
      askingPriceCr: 1.85,
      fairValueCr: 2.05,
      priceRangeDisplay: '₹1.85 Crore',
      pricePerSqft: 9736,
      score10x: 9.7,
      rentalYieldPercent: 4.5,
      sqft: 1900,
      carpetAreaSqft: 1550,
      bhk: '3 BHK',
      bhkOptions: ['3 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600573472591-ee6b68d14c68?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ7456',
      statusTag: 'New Launch',
      rating: 4.8,
      reviewCount: 110,
      builderName: 'Godrej Properties',
      dealerId: 'DLR-NOIDA-104',
      dealerName: 'Rohan Gupta',
      possessionDate: 'Mar 2027',
      availability: 'Under Construction',
      furnishing: 'Unfurnished',
      amenities: [
        'Floating Cabanas',
        'Sunken Amphitheatre',
        'Resort Pool',
        'Gym',
        'Sky Terrace Gardens',
        'Security',
        'Lift',
      ],
      description:
          'Resort-style 3 BHK luxury residence in Godrej Palm Retreat, Sector 150 Noida. Floating cabanas, sunken amphitheatre, and sky terrace gardens.',
      nearby: {
        'Shaheed Bhagat Singh Park': '500 m',
        'Noida Expressway': '1.0 km',
        'Pari Chowk': '7.2 km',
        'Jewar Airport Link': '28 km',
      },
      virtualTour: VirtualTourData(
        title: 'Godrej Palm Retreat Resort 360° Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'resort-lounge',
            name: 'Resort Living Lounge',
            area: '380 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'presidential-suite',
            name: 'Presidential Suite',
            area: '240 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'sunken-deck',
            name: 'Sunken Deck & Pool View',
            area: '120 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/godrej_palm_retreat_ar.glb',
      floorPlanRooms: [
        FloorPlanRoom(name: 'Resort Living & Dining Lounge', roomType: 'livingRoom', areaSqFt: 380, dimensions: '19\'0" x 20\'0"', features: ['Sunken Deck Access', 'Imported Marble']),
        FloorPlanRoom(name: 'Presidential Master Suite', roomType: 'masterBedroom', areaSqFt: 240, dimensions: '15\'0" x 16\'0"', features: ['Attached Bath', 'Walk-in Closet']),
        FloorPlanRoom(name: 'Resort Guest Bedroom', roomType: 'bedroom', areaSqFt: 190, dimensions: '13\'6" x 14\'0"', features: ['Pool View', 'Ensuite Bath']),
        FloorPlanRoom(name: 'Bedroom 3 / Studio', roomType: 'bedroom', areaSqFt: 160, dimensions: '12\'0" x 13\'4"', features: ['Large Window', 'Balcony Attached']),
        FloorPlanRoom(name: 'Gourmet Kitchen', roomType: 'kitchen', areaSqFt: 130, dimensions: '11\'0" x 12\'0"', features: ['Island Platform', 'Utility Space']),
        FloorPlanRoom(name: 'Sunken Deck & Cabana Balcony', roomType: 'balcony', areaSqFt: 120, dimensions: '7\'0" x 17\'0"', features: ['Resort Pool View', 'Teak Wood Tiles']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'East (Indra)',
        overallScore: 88,
        entranceDirection: 'East Facing Entrance',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'East Facing',
        balconyDirection: 'East Facing Pool Deck',
        toiletDirection: 'North-West',
        keyObservations: [
          'Direct East entrance receives early morning sunlight.',
          'Resort balcony captures eastern morning breezes.',
          'Master bedroom in South-West stability zone.',
        ],
      ),
    ),

    // 7. JAYPEE GREENS WISH TOWN (Yamuna Expressway)
    Property(
      id: 'prop_jaypee_wishtown',
      title: 'Jaypee Greens Wish Town',
      sector: 'Sector 128',
      city: 'Noida',
      locality: 'Yamuna Expressway',
      address: 'Sector 128, Noida-Greater Noida Expressway / Yamuna Expressway Link, Noida, Uttar Pradesh',
      postalCode: '201304',
      placeId: 'ChIJ_jaypee_wishtown_noida',
      latitude: 28.5280,
      longitude: 77.3620,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 0.72,
      fairValueCr: 0.79,
      originalPriceCr: 0.79,
      priceRangeDisplay: '₹72 Lakh',
      pricePerSqft: 6000,
      score10x: 9.1,
      rentalYieldPercent: 5.0,
      sqft: 1200,
      carpetAreaSqft: 960,
      bhk: '2 BHK',
      bhkOptions: ['2 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ9123',
      statusTag: 'Ready to Move',
      rating: 4.6,
      reviewCount: 128,
      builderName: 'Jaypee Greens',
      dealerId: '',
      dealerName: '',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        '18-Hole Golf Course',
        'Hospital On-Campus',
        'Swimming Pool',
        'Gym',
        'Club House',
        'Security',
        'Lift',
      ],
      description:
          'Gated 2 BHK golf-view apartment in Jaypee Greens Wish Town along Expressway. Features 18-hole golf course, Jaypee hospital on campus, and quick Delhi access.',
      nearby: {
        'Jaypee Multi-speciality Hospital': '300 m',
        'Noida Expressway': '200 m',
        'Kalindi Kunj / Delhi Border': '6.5 km',
        'Sector 137 Metro': '3.2 km',
      },
      virtualTour: VirtualTourData(
        title: 'Jaypee Greens Wish Town 360° Golf Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'jaypee-living',
            name: 'Golf View Living Hall',
            area: '310 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'jaypee-master',
            name: 'Master Suite',
            area: '200 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'jaypee-balcony',
            name: '18-Hole Golf Course Balcony',
            area: '90 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/godrej_golflinks_villa_ar.glb',
      floorPlanRooms: [
        FloorPlanRoom(name: 'Living & Dining Hall', roomType: 'livingRoom', areaSqFt: 310, dimensions: '16\'0" x 19\'4"', features: ['Golf Course Balcony Access', 'Marble Tiles']),
        FloorPlanRoom(name: 'Master Bedroom', roomType: 'masterBedroom', areaSqFt: 200, dimensions: '14\'0" x 14\'4"', features: ['Attached Bathroom', 'Wardrobe Niche']),
        FloorPlanRoom(name: 'Guest Bedroom 2', roomType: 'bedroom', areaSqFt: 160, dimensions: '12\'0" x 13\'4"', features: ['Golf Greens View', 'Corner Window']),
        FloorPlanRoom(name: 'Kitchen', roomType: 'kitchen', areaSqFt: 100, dimensions: '9\'6" x 10\'6"', features: ['Granite Slab', 'Utility Balcony']),
        FloorPlanRoom(name: 'Golf View Balcony', roomType: 'balcony', areaSqFt: 90, dimensions: '6\'0" x 15\'0"', features: ['18-Hole Golf Course View', 'Anti-skid Flooring']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'North-East (Ishanya)',
        overallScore: 92,
        entranceDirection: 'North-East Entrance',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'North-East Facing',
        balconyDirection: 'East Golf View',
        toiletDirection: 'North-West',
        keyObservations: [
          'North-East entrance allows optimal sunrise illumination and cross-ventilation.',
          'Golf course balcony receives morning sun without harsh western heat.',
        ],
      ),
    ),

    // 8. GAUR YAMUNA CITY (Yamuna Expressway)
    Property(
      id: 'prop_gaur_yamuna_city',
      title: 'Gaur Yamuna City',
      sector: 'Sector 19, Yamuna Expressway',
      city: 'Greater Noida',
      locality: 'Yamuna Expressway',
      address: 'Sector 19, Yamuna Expressway, Near Jewar Airport, Greater Noida, Uttar Pradesh',
      postalCode: '203201',
      placeId: 'ChIJ_gaur_yamuna_city',
      latitude: 28.3610,
      longitude: 77.5420,
      category: 'Residential',
      propertyType: 'Apartment',
      askingPriceCr: 0.98,
      fairValueCr: 1.08,
      originalPriceCr: 1.08,
      priceRangeDisplay: '₹98 Lakh',
      pricePerSqft: 6322,
      score10x: 9.3,
      rentalYieldPercent: 5.2,
      sqft: 1550,
      carpetAreaSqft: 1250,
      bhk: '3 BHK',
      bhkOptions: ['3 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ4410',
      statusTag: 'Ready to Move',
      rating: 4.7,
      reviewCount: 140,
      builderName: 'Gaurs Group',
      dealerId: 'DLR-GRNOIDA-103',
      dealerName: 'Vikas Malhotra',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        'Lake Park',
        'Sports Complex',
        'Swimming Pool',
        'Gym',
        'Club House',
        'Security',
        'Lift',
      ],
      description:
          'Integrated township 3 BHK apartment in Gaur Yamuna City right on Yamuna Expressway. Close to upcoming Jewar International Airport and F1 Buddh Circuit.',
      nearby: {
        'Jewar International Airport': '18 km',
        'Buddh International F1 Circuit': '3.5 km',
        'Eastern Peripheral Expressway': '5.2 km',
        'Galgotias University': '6.8 km',
      },
    ),

    // 9. ATS ALLURE (Yamuna Expressway)
    Property(
      id: 'prop_ats_allure',
      title: 'ATS Allure',
      sector: 'Sector 22D, Yamuna Expressway',
      city: 'Greater Noida',
      locality: 'Yamuna Expressway',
      address: 'Sector 22D, Yamuna Expressway, Greater Noida, Uttar Pradesh',
      postalCode: '203201',
      placeId: 'ChIJ_ats_allure_yamuna',
      latitude: 28.3450,
      longitude: 77.5580,
      category: 'Residential',
      propertyType: 'Luxury Apartment',
      askingPriceCr: 1.15,
      fairValueCr: 1.25,
      priceRangeDisplay: '₹1.15 Crore',
      pricePerSqft: 6764,
      score10x: 9.4,
      rentalYieldPercent: 4.8,
      sqft: 1700,
      carpetAreaSqft: 1380,
      bhk: '3 BHK',
      bhkOptions: ['3 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ9821',
      statusTag: 'New Launch',
      rating: 4.8,
      reviewCount: 88,
      builderName: 'ATS Greens',
      dealerId: 'DLR-GRNOIDA-103',
      dealerName: 'Vikas Malhotra',
      possessionDate: 'Nov 2026',
      availability: 'Under Construction',
      furnishing: 'Unfurnished',
      amenities: [
        'Swimming Pool',
        'Tennis Courts',
        'Gym',
        'Club House',
        'Lush Green Parks',
        'Security',
        'Lift',
      ],
      description:
          'Contemporary 3 BHK luxury residence in ATS Allure on Yamuna Expressway. Strategic high-growth corridor with proximity to Olympic city and Film City.',
      nearby: {
        'Proposed Film City': '4.0 km',
        'Jewar Airport Link': '16 km',
        'Pari Chowk': '14 km',
        'Noida International University': '5.5 km',
      },
    ),

    // 10. GAUR SAUNDARYAM VILLAS (Luxury Villas)
    Property(
      id: 'prop_gaur_saundaryam_villas',
      title: 'Gaur Saundaryam Villas',
      sector: 'Techzone 4',
      city: 'Greater Noida West',
      locality: 'Noida Extension',
      address: 'Techzone 4, Greater Noida West / Noida Extension, Uttar Pradesh',
      postalCode: '201306',
      placeId: 'ChIJ_gaur_saundaryam_villas',
      latitude: 28.5833,
      longitude: 77.4475,
      category: 'Residential',
      propertyType: 'Luxury Villa',
      askingPriceCr: 2.45,
      fairValueCr: 2.70,
      originalPriceCr: 2.70,
      priceRangeDisplay: '₹2.45 Crore',
      pricePerSqft: 8750,
      score10x: 9.6,
      rentalYieldPercent: 4.2,
      sqft: 2800,
      carpetAreaSqft: 2400,
      bhk: '4 BHK',
      bhkOptions: ['4 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ11245',
      statusTag: 'Ready to Move',
      rating: 4.9,
      reviewCount: 132,
      builderName: 'Gaurs Group',
      dealerId: 'DLR-GRNOIDA-103',
      dealerName: 'Vikas Malhotra',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        'Private Garden',
        'Terrace Deck',
        'Swimming Pool',
        'Gym',
        'Club House',
        'Italian Marble Flooring',
        '2 Car Parking Porch',
        '24x7 Security',
      ],
      description:
          'Exclusive 4 BHK duplex luxury villa in Gaur Saundaryam, Greater Noida West. Private landscaped lawn, terrace deck, Italian marble flooring and private car porch.',
      nearby: {
        'Gaur City Mall': '3.0 km',
        'Sector 52 Metro': '8.5 km',
        'Fortis Hospital': '9.8 km',
        'FNG Expressway': '4.5 km',
      },
    ),

    // 11. GODREJ GOLF LINKS VILLA (Luxury Villas)
    Property(
      id: 'prop_godrej_golflinks_villa',
      title: 'Godrej Golf Links Villa',
      sector: 'Sector 27',
      city: 'Greater Noida',
      locality: 'Greater Noida',
      address: 'Sector 27, Near Pari Chowk, Greater Noida, Uttar Pradesh',
      postalCode: '201308',
      placeId: 'ChIJ_godrej_golflinks_villa',
      latitude: 28.4720,
      longitude: 77.5120,
      category: 'Residential',
      propertyType: 'Luxury Villa',
      askingPriceCr: 3.20,
      fairValueCr: 3.50,
      originalPriceCr: 3.50,
      priceRangeDisplay: '₹3.20 Crore',
      pricePerSqft: 10000,
      score10x: 9.8,
      rentalYieldPercent: 4.0,
      sqft: 3200,
      carpetAreaSqft: 2750,
      bhk: '4 BHK',
      bhkOptions: ['4 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ27320',
      statusTag: 'Ready to Move',
      rating: 5.0,
      reviewCount: 168,
      builderName: 'Godrej Properties',
      dealerId: 'DLR-GRNOIDA-103',
      dealerName: 'Vikas Malhotra',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Fully Furnished',
      amenities: [
        '9-Hole Golf Course Views',
        'Private Pool Provision',
        'Master Jacuzzi',
        'Club House',
        'Gym',
        'Double Height Living',
        'Security',
      ],
      description:
          'Palatial 4 BHK golf-side villa in Godrej Golf Links, Greater Noida. 9-hole golf course, private pool provision, double-height living room and master suite jacuzzi.',
      nearby: {
        'Pari Chowk': '2.0 km',
        'Jaypee Greens Golf Course': '3.2 km',
        'Alpha 1 Metro': '2.5 km',
        'Yatharth Hospital': '3.0 km',
      },
      virtualTour: VirtualTourData(
        title: 'Godrej Golf Links Villa 360° Palatial Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'villa-foyer',
            name: 'Double-Height Grand Foyer',
            area: '520 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'villa-master',
            name: 'Presidential Master Suite',
            area: '340 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'villa-pool',
            name: 'Private Plunge Pool & Pergola',
            area: '240 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/jaypee_villa_ar.glb',
      floorPlanRooms: [
        FloorPlanRoom(name: 'Double-Height Grand Foyer', roomType: 'livingRoom', areaSqFt: 520, dimensions: '22\'0" x 26\'0"', features: ['Private Courtyard Access', 'Italian Botticino']),
        FloorPlanRoom(name: 'Presidential Master Suite', roomType: 'masterBedroom', areaSqFt: 340, dimensions: '18\'0" x 20\'0"', features: ['Jacuzzi Ensuite', 'Walk-in Dressing Suite']),
        FloorPlanRoom(name: 'Guest Garden Suite', roomType: 'bedroom', areaSqFt: 250, dimensions: '15\'0" x 16\'8"', features: ['Private Lawn Patio', 'Attached Bath']),
        FloorPlanRoom(name: 'Bedroom 3 / Upper Lounge', roomType: 'bedroom', areaSqFt: 220, dimensions: '14\'0" x 16\'0"', features: ['Golf Greens View', 'Balcony Attached']),
        FloorPlanRoom(name: 'Gourmet Island Kitchen', roomType: 'kitchen', areaSqFt: 180, dimensions: '12\'0" x 15\'0"', features: ['Central Island', 'Dry + Wet Pantry']),
        FloorPlanRoom(name: 'Poolside Pergola Deck', roomType: 'balcony', areaSqFt: 240, dimensions: '12\'0" x 20\'0"', features: ['Private Pool', 'Teak Wood Decking']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'East (Indra)',
        overallScore: 94,
        entranceDirection: 'East Facing Grand Portico',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'East / North-East',
        balconyDirection: 'East Golf View',
        toiletDirection: 'North-West',
        keyObservations: [
          'Palatial East-facing grand portico entrance captures auspicious morning energy.',
          'Double-height ceiling enhances natural air circulation and vertical daylight.',
          'Private pool in North-East quadrant brings serene water element balance.',
        ],
      ),
    ),

    // 12. JAYPEE GREENS VILLA (Luxury Villas)
    Property(
      id: 'prop_jaypee_villa',
      title: 'Jaypee Greens Villa',
      sector: 'Pari Chowk',
      city: 'Greater Noida',
      locality: 'Greater Noida',
      address: 'Jaypee Greens Estate, Near Pari Chowk, Greater Noida, Uttar Pradesh',
      postalCode: '201310',
      placeId: 'ChIJ_jaypee_greens_villa',
      latitude: 28.4680,
      longitude: 77.5050,
      category: 'Residential',
      propertyType: 'Luxury Villa',
      askingPriceCr: 4.50,
      fairValueCr: 4.90,
      originalPriceCr: 4.90,
      priceRangeDisplay: '₹4.50 Crore',
      pricePerSqft: 10714,
      score10x: 9.9,
      rentalYieldPercent: 3.8,
      sqft: 4200,
      carpetAreaSqft: 3650,
      bhk: '5 BHK',
      bhkOptions: ['5 BHK'],
      imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ45001',
      statusTag: 'Ready to Move',
      rating: 5.0,
      reviewCount: 195,
      builderName: 'Jaypee Greens',
      dealerId: 'DLR-GRNOIDA-103',
      dealerName: 'Vikas Malhotra',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Fully Furnished',
      amenities: [
        'Greg Norman Golf Course',
        'Private Infinity Plunge Pool',
        'Servant Quarters',
        'Spa & Sauna',
        'Smart Home Integration',
        'Private Lawn',
        'Security',
      ],
      description:
          'Ultra-luxury 5 BHK signature estate villa in Jaypee Greens. Greg Norman championship golf views, private infinity plunge pool, and servant quarters.',
      nearby: {
        'Pari Chowk': '1.2 km',
        'Delta 1 Metro': '2.1 km',
        'The Grand Venice Mall': '3.5 km',
        'Yamuna Expressway Entry': '3.0 km',
      },
      virtualTour: VirtualTourData(
        title: 'Jaypee Greens Estate Villa 360° Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'estate-foyer',
            name: 'Grand Estate Drawing Foyer',
            area: '620 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'estate-master',
            name: 'Royal Master Suite',
            area: '420 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'estate-infinity',
            name: 'Golf View Infinity Deck',
            area: '310 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/dlf_camellias_ar.glb',
      floorPlanRooms: [
        FloorPlanRoom(name: 'Double-Height Grand Foyer', roomType: 'livingRoom', areaSqFt: 620, dimensions: '24\'0" x 28\'0"', features: ['Golf Course Panorama', 'Statuary Marble']),
        FloorPlanRoom(name: 'Royal Master Suite', roomType: 'masterBedroom', areaSqFt: 420, dimensions: '20\'0" x 22\'0"', features: ['Private Terrace', 'Spa Bathroom']),
        FloorPlanRoom(name: 'Junior Master Suite', roomType: 'bedroom', areaSqFt: 300, dimensions: '16\'0" x 19\'0"', features: ['Walk-in Closet', 'Attached Bath']),
        FloorPlanRoom(name: 'Guest Pavilion Suite', roomType: 'bedroom', areaSqFt: 260, dimensions: '15\'0" x 17\'4"', features: ['Private Garden Access', 'Ensuite Bath']),
        FloorPlanRoom(name: 'Chef Kitchen & Butler Pantry', roomType: 'kitchen', areaSqFt: 220, dimensions: '14\'0" x 16\'0"', features: ['Sub-Zero Provision', 'Dry + Wet Zones']),
        FloorPlanRoom(name: 'Infinity Plunge Pool Deck', roomType: 'balcony', areaSqFt: 310, dimensions: '14\'0" x 22\'0"', features: ['Championship Golf Course View', 'Private Jacuzzi']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'North-East (Ishanya)',
        overallScore: 96,
        entranceDirection: 'North-East Portico',
        kitchenDirection: 'South-East',
        masterBedroomDirection: 'South-West',
        livingAreaDirection: 'North-East Golf Front',
        balconyDirection: 'North-East Plunge Pool',
        toiletDirection: 'North-West',
        keyObservations: [
          'Championship golf orientation with pristine North-East morning light and mountain air currents.',
          'Nairutya master suite grounding provides peaceful, deep sleep environment.',
        ],
      ),
    ),

    // 13. ATS BOUQUET (Commercial Offices)
    Property(
      id: 'prop_ats_bouquet',
      title: 'ATS Bouquet',
      sector: 'Sector 132',
      city: 'Noida',
      locality: 'Sector 132',
      address: 'Plot 2A, Sector 132, Noida-Greater Noida Expressway, Noida, Uttar Pradesh',
      postalCode: '201304',
      placeId: 'ChIJ_ats_bouquet_132',
      latitude: 28.5080,
      longitude: 77.3820,
      category: 'Commercial',
      propertyType: 'Commercial Office',
      askingPriceCr: 1.10,
      fairValueCr: 1.20,
      originalPriceCr: 1.20,
      priceRangeDisplay: '₹1.10 Crore',
      pricePerSqft: 12941,
      score10x: 9.4,
      rentalYieldPercent: 7.5,
      sqft: 850,
      carpetAreaSqft: 680,
      bhk: 'Commercial Office',
      bhkOptions: ['Commercial Office'],
      imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ13210',
      statusTag: 'Ready to Move',
      rating: 4.8,
      reviewCount: 115,
      builderName: 'ATS Greens',
      dealerId: '',
      dealerName: '',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Semi Furnished',
      amenities: [
        'Grade-A Corporate Tower',
        'High-Speed Elevators',
        'Central Air Conditioning',
        '100% Power Backup',
        'Basement Parking',
        'Cafeteria & Lounge',
        '24x7 Security',
      ],
      description:
          'Grade-A commercial office space in ATS Bouquet, Sector 132 Noida along Expressway. High rental yield with fortune 500 corporate tenants in vicinity.',
      nearby: {
        'Noida Expressway': '100 m',
        'Sector 137 Metro': '1.8 km',
        'Jaypee Hospital': '1.5 km',
        'Amity University': '8.0 km',
      },
    ),

    // 14. ADVANT NAVIS BUSINESS PARK (Commercial Offices)
    Property(
      id: 'prop_advant_navis',
      title: 'Advant Navis Business Park',
      sector: 'Sector 142',
      city: 'Noida',
      locality: 'Sector 142',
      address: 'Plot 7, Sector 142, Noida-Greater Noida Expressway, Noida, Uttar Pradesh',
      postalCode: '201305',
      placeId: 'ChIJ_advant_navis_142',
      latitude: 28.4980,
      longitude: 77.4120,
      category: 'Commercial',
      propertyType: 'Commercial Office',
      askingPriceCr: 1.65,
      fairValueCr: 1.80,
      originalPriceCr: 1.80,
      priceRangeDisplay: '₹1.65 Crore',
      pricePerSqft: 13750,
      score10x: 9.7,
      rentalYieldPercent: 8.2,
      sqft: 1200,
      carpetAreaSqft: 980,
      bhk: 'Commercial Office',
      bhkOptions: ['Commercial Office'],
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ14207',
      statusTag: 'Ready to Move',
      rating: 4.9,
      reviewCount: 174,
      builderName: 'Advant Group',
      dealerId: 'DLR-NOIDA-102',
      dealerName: 'Sunita Sharma',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Fully Furnished',
      amenities: [
        'Direct Metro Walkway',
        'LEED Gold Certified',
        'Food Court & Fine Dining',
        'Multi-Tier Security',
        'Automated Valet Parking',
        'High-Speed Fibre Internet',
      ],
      description:
          'Iconic commercial office suite in Advant Navis Business Park directly connected to Sector 142 Metro. LEED Gold certified corporate towers.',
      nearby: {
        'Sector 142 Metro Station': '50 m',
        'Noida Expressway': '100 m',
        'Sector 137': '2.1 km',
        'Mahamaya Flyover': '12 km',
      },
      virtualTour: VirtualTourData(
        title: 'Advant Navis Grade-A Office 360° Tour',
        panoramaUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
        provider: 'kuula',
        isAvailable: true,
        rooms: [
          VirtualTourRoom(
            id: 'advant-floor',
            name: 'Open Executive Floor',
            area: '650 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sofa',
          ),
          VirtualTourRoom(
            id: 'advant-boardroom',
            name: 'Glass Boardroom Suite',
            area: '240 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=1920&q=80',
            iconType: 'bed',
          ),
          VirtualTourRoom(
            id: 'advant-metro',
            name: 'Metro Connector Atrium',
            area: '310 sq.ft.',
            imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1920&q=80',
            iconType: 'sun',
          ),
        ],
      ),
      virtualTourUrl: 'https://kuula.co/share/collection/7l1vX?logo=1&info=1&fs=1&vr=0&sd=1&thumbs=1',
      model3DUrl: 'https://sketchfab.com/models/6b8563a3d2424855a02102ba694e9f56/embed',
      model3DId: '6b8563a3d2424855a02102ba694e9f56',
      arModelUrl: 'https://propzen.ai/models/properties/advant_navis_office_ar.glb',
      floorPlanRooms: [
        FloorPlanRoom(name: 'Main Workstation Bay', roomType: 'office', areaSqFt: 650, dimensions: '26\'0" x 25\'0"', features: ['Open Workstation Plan', 'Underfloor Trunking']),
        FloorPlanRoom(name: 'Executive Boardroom', roomType: 'meeting', areaSqFt: 240, dimensions: '15\'0" x 16\'0"', features: ['Acoustic Glazing', 'AV Presentation Wall']),
        FloorPlanRoom(name: 'Director Suite', roomType: 'cabin', areaSqFt: 180, dimensions: '12\'0" x 15\'0"', features: ['Expressway Facing', 'Private Washroom Attached']),
        FloorPlanRoom(name: 'Pantry & Cafeteria', roomType: 'kitchen', areaSqFt: 130, dimensions: '10\'0" x 13\'0"', features: ['Wet Pantry Counter', 'Coffee Niche']),
      ],
      vastuData: VastuGuidanceData(
        facingDirection: 'North (Kuber)',
        overallScore: 92,
        entranceDirection: 'North Facing Reception',
        kitchenDirection: 'South-East Pantry',
        masterBedroomDirection: 'South-West Director Cabin',
        livingAreaDirection: 'North Open Bay',
        balconyDirection: 'North Expressway Glazing',
        toiletDirection: 'North-West',
        keyObservations: [
          'North-facing reception aligned with commercial prosperity and glare-free natural lighting.',
          'Director cabin in South-West stability position supports leadership and focus.',
        ],
      ),
    ),

    // 15. LOGIX CYBER PARK (Commercial Offices)
    Property(
      id: 'prop_logix_cyber_park',
      title: 'Logix Cyber Park',
      sector: 'Sector 62',
      city: 'Noida',
      locality: 'Sector 62',
      address: 'C-28/29, Sector 62, Noida, Uttar Pradesh',
      postalCode: '201309',
      placeId: 'ChIJ_logix_cyber_park_62',
      latitude: 28.6250,
      longitude: 77.3680,
      category: 'Commercial',
      propertyType: 'Commercial Office',
      askingPriceCr: 1.35,
      fairValueCr: 1.48,
      originalPriceCr: 1.48,
      priceRangeDisplay: '₹1.35 Crore',
      pricePerSqft: 13500,
      score10x: 9.5,
      rentalYieldPercent: 7.8,
      sqft: 1000,
      carpetAreaSqft: 820,
      bhk: 'Commercial Office',
      bhkOptions: ['Commercial Office'],
      imageUrl: 'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1497215728101-856f4ea42174?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
      ],
      isVerified: true,
      isReraApproved: true,
      reraId: 'UPRERAPRJ62028',
      statusTag: 'Ready to Move',
      rating: 4.7,
      reviewCount: 136,
      builderName: 'Logix Group',
      dealerId: '',
      dealerName: '',
      possessionDate: 'Ready to Move',
      availability: 'Ready to Move',
      furnishing: 'Fully Furnished',
      amenities: [
        'IT Park Facility',
        'Auditorium',
        'Gym & Wellness Centre',
        'High Speed Lifts',
        '24x7 Power Backup',
        'Multi-Cuisine Cafeteria',
      ],
      description:
          'Furnished IT/Commercial office space in Logix Cyber Park, Sector 62 Noida. Near Electronic City Metro Station with full power backup and central AC.',
      nearby: {
        'Noida Electronic City Metro': '650 m',
        'NH-24 / Delhi-Meerut Expressway': '1.2 km',
        'Fortis Hospital Noida': '1.8 km',
        'Indirapuram Habitat Centre': '3.5 km',
      },
    ),
  ];
}

class PropertyFilterEngine {
  static List<Property> filter({
    required List<Property> sourceList,
    String? selectedCategory,
    String? selectedSubtype,
    String? selectedBhk,
    String? selectedBudget,
    String? selectedSector,
    String? selectedPlotSqft,
    String? selectedFurnishing,
    String? searchQuery,
    bool? onlyVerified,
    bool? onlyReadyToMove,
    Set<String>? selectedAmenities,
  }) {
    var list = List<Property>.from(sourceList);

    // Category Filter
    if (selectedCategory != null && selectedCategory != 'All') {
      final cat = selectedCategory.toLowerCase();
      if (cat == 'buy') {
        list = list.where((p) => p.category.toLowerCase() != 'pg').toList();
      } else if (cat == 'rent') {
        list = list.where((p) => p.rentalYieldPercent >= 5.0 || p.category.toLowerCase() == 'pg/co-living').toList();
      } else if (cat == 'plots') {
        list = list.where((p) => p.propertyType.toLowerCase().contains('plot') || p.bhk.toLowerCase().contains('plot') || p.category.toLowerCase().contains('plot')).toList();
      } else if (cat == 'residential') {
        list = list.where((p) => p.category.toLowerCase() == 'residential').toList();
      } else if (cat == 'commercial') {
        list = list.where((p) => p.category.toLowerCase() == 'commercial').toList();
      } else if (cat == 'agricultural') {
        list = list.where((p) => p.category.toLowerCase() == 'agricultural' || p.category.toLowerCase() == 'industrial').toList();
      }
    }

    // Amenities (AND logic)
    if (selectedAmenities != null && selectedAmenities.isNotEmpty) {
      for (final a in selectedAmenities) {
        final aLower = a.toLowerCase();
        list = list.where((p) {
          return p.amenities.any((pa) {
            final paLower = pa.toLowerCase();
            if (aLower.contains('pool') && paLower.contains('pool')) return true;
            if (aLower.contains('gym') && paLower.contains('gym')) return true;
            if (aLower.contains('security') && paLower.contains('security')) return true;
            if (aLower.contains('club') && paLower.contains('club')) return true;
            if (aLower.contains('ev') && (paLower.contains('ev') || paLower.contains('charging'))) return true;
            if (aLower.contains('park') && (paLower.contains('park') || paLower.contains('garden'))) return true;
            if (aLower.contains('sports') && (paLower.contains('sports') || paLower.contains('court'))) return true;
            if (aLower.contains('kids') || aLower.contains('children')) {
              if (paLower.contains('kids') || paLower.contains('children') || paLower.contains('play')) return true;
            }
            return paLower.contains(aLower) || aLower.contains(paLower);
          });
        }).toList();
      }
    }

    return list;
  }
}
