import 'package:flutter/foundation.dart';

enum SupplierCategory {
  cement,
  steel,
  bricks,
  tiles,
  electrical,
  plumbing,
  paint,
  hardware,
  contractors,
  architects,
  interior;

  String get displayName {
    switch (this) {
      case SupplierCategory.cement:
        return 'Cement & Concrete';
      case SupplierCategory.steel:
        return 'TMT Steel & Iron';
      case SupplierCategory.bricks:
        return 'Bricks & AAC Blocks';
      case SupplierCategory.tiles:
        return 'Tiles & Marble';
      case SupplierCategory.electrical:
        return 'Electrical & Wiring';
      case SupplierCategory.plumbing:
        return 'Plumbing & Pipes';
      case SupplierCategory.paint:
        return 'Paint & Waterproofing';
      case SupplierCategory.hardware:
        return 'Hardware & Fasteners';
      case SupplierCategory.contractors:
        return 'Civil & Labour Contractors';
      case SupplierCategory.architects:
        return 'Architects & Planners';
      case SupplierCategory.interior:
        return 'Interior & Woodwork';
    }
  }

  static SupplierCategory fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower.contains('cement')) return SupplierCategory.cement;
    if (lower.contains('steel')) return SupplierCategory.steel;
    if (lower.contains('brick') || lower.contains('block')) return SupplierCategory.bricks;
    if (lower.contains('tile') || lower.contains('marble')) return SupplierCategory.tiles;
    if (lower.contains('electric') || lower.contains('wire')) return SupplierCategory.electrical;
    if (lower.contains('plumb') || lower.contains('pipe')) return SupplierCategory.plumbing;
    if (lower.contains('paint')) return SupplierCategory.paint;
    if (lower.contains('contract') || lower.contains('labour')) return SupplierCategory.contractors;
    if (lower.contains('arch')) return SupplierCategory.architects;
    if (lower.contains('interior')) return SupplierCategory.interior;
    return SupplierCategory.hardware;
  }
}

class SupplierModel {
  final String supplierId;
  final String businessName;
  final SupplierCategory category;
  final String subCategory;
  final String description;
  final String phone;
  final String whatsapp;
  final String email;
  final String address;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final double latitude;
  final double longitude;
  final double serviceRadiusKm;
  final List<String> products;
  final String priceRange;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String verificationStatus; // VERIFIED, PENDING_VERIFICATION, REJECTED
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierModel({
    required this.supplierId,
    required this.businessName,
    required this.category,
    required this.subCategory,
    required this.description,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.address,
    required this.locality,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.serviceRadiusKm = 25.0,
    this.products = const [],
    this.priceRange = '₹₹ (Standard)',
    this.rating = 4.8,
    this.reviewCount = 24,
    this.isVerified = true,
    this.verificationStatus = 'VERIFIED',
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map, String id) {
    return SupplierModel(
      supplierId: id,
      businessName: map['businessName']?.toString() ?? 'Verified Supplier',
      category: SupplierCategory.fromString(map['category']?.toString() ?? 'cement'),
      subCategory: map['subCategory']?.toString() ?? 'Bulk Materials',
      description: map['description']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      whatsapp: map['whatsapp']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      locality: map['locality']?.toString() ?? '',
      city: map['city']?.toString() ?? 'Noida',
      state: map['state']?.toString() ?? 'Uttar Pradesh',
      pincode: map['pincode']?.toString() ?? '201301',
      latitude: double.tryParse(map['latitude']?.toString() ?? '') ?? 28.5355,
      longitude: double.tryParse(map['longitude']?.toString() ?? '') ?? 77.3910,
      serviceRadiusKm: double.tryParse(map['serviceRadiusKm']?.toString() ?? '25') ?? 25.0,
      products: map['products'] is List ? List<String>.from(map['products']) : [],
      priceRange: map['priceRange']?.toString() ?? '₹₹ (Standard)',
      rating: double.tryParse(map['rating']?.toString() ?? '4.8') ?? 4.8,
      reviewCount: int.tryParse(map['reviewCount']?.toString() ?? '24') ?? 24,
      isVerified: map['isVerified'] == true || map['verificationStatus'] == 'VERIFIED',
      verificationStatus: map['verificationStatus']?.toString() ?? 'VERIFIED',
      logoUrl: map['logoUrl']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'supplierId': supplierId,
        'businessName': businessName,
        'category': category.name,
        'subCategory': subCategory,
        'description': description,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'address': address,
        'locality': locality,
        'city': city,
        'state': state,
        'pincode': pincode,
        'latitude': latitude,
        'longitude': longitude,
        'serviceRadiusKm': serviceRadiusKm,
        'products': products,
        'priceRange': priceRange,
        'rating': rating,
        'reviewCount': reviewCount,
        'isVerified': isVerified,
        'verificationStatus': verificationStatus,
        'logoUrl': logoUrl,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class SupplierQuoteRequest {
  final String requestId;
  final String supplierId;
  final String userId;
  final String userName;
  final String userPhone;
  final String materialNeeded;
  final String quantity;
  final String siteLocation;
  final String status;
  final DateTime createdAt;

  const SupplierQuoteRequest({
    required this.requestId,
    required this.supplierId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.materialNeeded,
    required this.quantity,
    required this.siteLocation,
    this.status = 'PENDING',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'supplierId': supplierId,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'materialNeeded': materialNeeded,
        'quantity': quantity,
        'siteLocation': siteLocation,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
