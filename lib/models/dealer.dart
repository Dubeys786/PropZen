class Dealer {
  final String id;
  final String? userId;
  final String name;
  final String agency;
  final String companyName;
  final String photoUrl;
  final String reraNumber;
  final bool isVerified;
  final String verificationStatus; // 'pending', 'verified', 'rejected', 'suspended'
  final int experienceYears;
  final String location;
  final String city;
  final List<String> areasServed;
  final int activeListingsCount;
  final double rating;
  final int reviewCount;
  final String phone;
  final String email;
  final String whatsapp;
  final String specialization;
  final List<String> languages;
  final int intelligenceScore; // e.g. 92 / 100
  final int responseRatePercent; // e.g. 94%
  final String responseTimeStr; // e.g. "Replies within 15 minutes"
  final bool identityVerified;
  final bool businessVerified;
  final bool contactVerified;
  final bool listingsVerified;
  final List<String> badges;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic>? licenseInformation;
  final String? createdAt;

  const Dealer({
    required this.id,
    this.userId,
    required this.name,
    required this.agency,
    String? companyName,
    required this.photoUrl,
    required this.reraNumber,
    this.isVerified = true,
    this.verificationStatus = 'verified',
    required this.experienceYears,
    required this.location,
    required this.city,
    required this.areasServed,
    required this.activeListingsCount,
    required this.rating,
    required this.reviewCount,
    this.phone = '+91 98103 94068',
    this.email = 'dealer@propzen.ai',
    this.whatsapp = '+91 98103 94068',
    required this.specialization,
    this.languages = const ['English', 'Hindi'],
    this.intelligenceScore = 92,
    this.responseRatePercent = 94,
    this.responseTimeStr = 'Usually replies within 15 mins',
    this.identityVerified = true,
    this.businessVerified = true,
    this.contactVerified = true,
    this.listingsVerified = true,
    this.badges = const ['Verified Dealer', 'Top Rated', 'Fast Responder'],
    this.reviews = const [
      {
        'user': 'Amit Verma',
        'rating': 5.0,
        'date': '2026-08-10',
        'comment': 'Very helpful and professional advisor. Showed authentic verified plot registries in Sector 150.',
      },
      {
        'user': 'Pooja Gupta',
        'rating': 4.9,
        'date': '2026-08-04',
        'comment': 'Smooth deal closure for 3BHK flat in Sector 137. Zero broker hassle.',
      }
    ],
    this.licenseInformation,
    this.createdAt,
  }) : companyName = companyName ?? agency;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'company_name': companyName,
      'agency': agency,
      'phone': phone,
      'email': email,
      'verification_status': verificationStatus,
      'license_information': licenseInformation ?? {'rera_number': reraNumber},
      'rera_number': reraNumber,
      'city': city,
      'experience_years': experienceYears,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory Dealer.fromMap(Map<String, dynamic> map) {
    final agencyName = map['company_name'] ?? map['agency'] ?? map['name'] ?? 'PropZen Partner';
    final rera = map['rera_registration_number'] ?? map['rera_number'] ?? (map['license_information']?['rera_number'] ?? 'UPRERA-VERIFIED');
    final status = map['verification_status']?.toString() ?? 'pending';

    return Dealer(
      id: map['id']?.toString() ?? 'DLR-${DateTime.now().millisecondsSinceEpoch}',
      userId: map['user_id']?.toString(),
      name: map['name'] ?? map['full_name'] ?? agencyName,
      agency: agencyName,
      companyName: agencyName,
      photoUrl: map['photo_url'] ?? map['profile_image'] ?? 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
      reraNumber: rera.toString(),
      isVerified: status == 'verified' || map['is_verified'] == true,
      verificationStatus: status,
      experienceYears: map['experience_years'] is int ? map['experience_years'] : (int.tryParse(map['experience_years']?.toString() ?? '5') ?? 5),
      location: map['address'] ?? map['location'] ?? map['city'] ?? 'Sector 150, Noida',
      city: map['city'] ?? 'Noida',
      areasServed: map['operating_sectors'] is List ? List<String>.from(map['operating_sectors']) : ['Sector 150', 'Sector 137', 'Noida Expressway'],
      activeListingsCount: map['active_listings_count'] is int ? map['active_listings_count'] : 12,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 4.9,
      reviewCount: map['review_count'] is int ? map['review_count'] : 45,
      phone: map['phone'] ?? '+91 98103 94068',
      email: map['email'] ?? 'dealer@propzen.ai',
      whatsapp: map['whatsapp'] ?? map['phone'] ?? '+91 98103 94068',
      specialization: map['specialization'] ?? 'Residential & Commercial Luxury Properties',
      licenseInformation: map['license_information'] is Map ? Map<String, dynamic>.from(map['license_information']) : null,
      createdAt: map['created_at']?.toString(),
    );
  }

  static List<Dealer> sampleDealers = const [
    Dealer(
      id: 'DLR-NOIDA-101',
      name: 'Rajesh Varma',
      agency: 'PropZen Prime Realty Solutions',
      photoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=400&q=80',
      reraNumber: 'UPRERAAGT12894',
      isVerified: true,
      verificationStatus: 'verified',
      experienceYears: 12,
      location: 'Sector 150, Noida Expressway',
      city: 'Noida',
      areasServed: ['Sector 150', 'Sector 137', 'Sector 75', 'Noida Expressway'],
      activeListingsCount: 48,
      rating: 4.95,
      reviewCount: 124,
      specialization: 'Noida Expressway Plots & Highrise Luxury Flats',
      intelligenceScore: 95,
      responseRatePercent: 98,
      responseTimeStr: 'Replies within 10 mins',
      badges: ['Verified Dealer', 'Top Rated', 'Premium Dealer', 'Fast Responder'],
    ),
    Dealer(
      id: 'DLR-GUR-202',
      name: 'Ananya Kapoor',
      agency: 'Apex Capital Property Advisory',
      photoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
      reraNumber: 'HRERA-GGM-2024-402',
      isVerified: true,
      verificationStatus: 'verified',
      experienceYears: 9,
      location: 'Golf Course Road, Gurgaon',
      city: 'Gurgaon',
      areasServed: ['Golf Course Rd', 'Golf Course Ext', 'DLF Cyber City', 'Sector 54'],
      activeListingsCount: 32,
      rating: 4.90,
      reviewCount: 98,
      specialization: 'Gurgaon Luxury Penthouse & Commercial IT Hubs',
      intelligenceScore: 92,
      responseRatePercent: 94,
      responseTimeStr: 'Replies within 15 mins',
      badges: ['Verified Dealer', 'Top Rated', 'Experienced Dealer'],
    ),
    Dealer(
      id: 'DLR-GNOIDA-303',
      name: 'Vikram Singh',
      agency: 'NCR Heritage Lands & Enclaves',
      photoUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
      reraNumber: 'UPRERAAGT99401',
      isVerified: true,
      verificationStatus: 'verified',
      experienceYears: 15,
      location: 'Greater Noida West',
      city: 'Greater Noida',
      areasServed: ['Greater Noida West', 'Surajpur', 'Yamuna Expressway'],
      activeListingsCount: 65,
      rating: 4.88,
      reviewCount: 156,
      specialization: 'Gated Plots & Industrial Manufacturing Plots',
      intelligenceScore: 94,
      responseRatePercent: 96,
      responseTimeStr: 'Replies within 12 mins',
      badges: ['Verified Dealer', 'Premium Dealer', 'Experienced Dealer'],
    ),
  ];
}
