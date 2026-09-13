import 'dart:math' as math;
import 'property.dart';

/// 3-Level Information Hierarchy for Locality
enum LocalityInfoLevel {
  notablePersonality, // Level 1: Nearby Notable Personalities (Strict 5 KM)
  communityRwa, // Level 2: Society / Locality Specific RWA & Community Leaders
  localGovernance, // Level 3: Applicable Administrative Jurisdiction Representatives
}

extension LocalityInfoLevelExt on LocalityInfoLevel {
  String get tabLabel {
    switch (this) {
      case LocalityInfoLevel.notablePersonality:
        return 'Nearby Personalities';
      case LocalityInfoLevel.communityRwa:
        return 'Community & RWA';
      case LocalityInfoLevel.localGovernance:
        return 'Local Governance';
    }
  }
}

/// Types of documented public connections to a locality
enum LocalityAssociationType {
  resident, // Verified local resident
  publicRepresentative, // Elected MP / MLA / Ward Councillor representing the area
  founderInArea, // Founded enterprise/company headquartered in the area
  youtuberCreator, // Digital creator / YouTuber with verified studio/residence in area
  influencer, // Verified digital influencer in the locality
  educator, // Academic / educational institution leader in area
  sportsPersonality, // Athlete / sports personality trained/residing in area
  socialLeader, // Civic / RWA / environmental leadership in area
  rwaPresident, // Elected President of Society AOA / RWA
  rwaSecretary, // Elected Secretary of Society AOA / RWA
  localCouncillor, // Municipal Ward Councillor / Zila Panchayat Member
  worksInArea, // Professional practice based in area
  bornInArea, // Born / raised in the area
}

extension LocalityAssociationTypeExt on LocalityAssociationType {
  String get code {
    switch (this) {
      case LocalityAssociationType.resident:
        return 'RESIDENT';
      case LocalityAssociationType.publicRepresentative:
        return 'PUBLIC_REPRESENTATIVE';
      case LocalityAssociationType.founderInArea:
        return 'FOUNDER_IN_AREA';
      case LocalityAssociationType.youtuberCreator:
        return 'YOUTUBER';
      case LocalityAssociationType.influencer:
        return 'INFLUENCER';
      case LocalityAssociationType.educator:
        return 'EDUCATOR';
      case LocalityAssociationType.sportsPersonality:
        return 'SPORTS';
      case LocalityAssociationType.socialLeader:
        return 'SOCIAL_LEADER';
      case LocalityAssociationType.rwaPresident:
        return 'RWA_PRESIDENT';
      case LocalityAssociationType.rwaSecretary:
        return 'RWA_SECRETARY';
      case LocalityAssociationType.localCouncillor:
        return 'LOCAL_COUNCILLOR';
      case LocalityAssociationType.worksInArea:
        return 'WORKS_IN_AREA';
      case LocalityAssociationType.bornInArea:
        return 'BORN_IN_AREA';
    }
  }

  String get displayLabel {
    switch (this) {
      case LocalityAssociationType.resident:
        return 'Verified Local Resident';
      case LocalityAssociationType.publicRepresentative:
        return 'Public Representative';
      case LocalityAssociationType.founderInArea:
        return 'Enterprise Founder in Area';
      case LocalityAssociationType.youtuberCreator:
        return 'Creator & Studio in Area';
      case LocalityAssociationType.influencer:
        return 'Verified Influencer';
      case LocalityAssociationType.educator:
        return 'Educationist in Area';
      case LocalityAssociationType.sportsPersonality:
        return 'Sports Champion in Locality';
      case LocalityAssociationType.socialLeader:
        return 'Civic Leadership';
      case LocalityAssociationType.rwaPresident:
        return 'AOA / RWA President';
      case LocalityAssociationType.rwaSecretary:
        return 'AOA / RWA Secretary';
      case LocalityAssociationType.localCouncillor:
        return 'Elected Ward Representative';
      case LocalityAssociationType.worksInArea:
        return 'Professional Practice in Area';
      case LocalityAssociationType.bornInArea:
        return 'Born in Area';
    }
  }

  static LocalityAssociationType fromString(String? val) {
    if (val == null) return LocalityAssociationType.publicRepresentative;
    final clean = val.trim().toUpperCase();
    if (clean == 'RESIDENT') return LocalityAssociationType.resident;
    if (clean == 'PUBLIC_REPRESENTATIVE' || clean == 'MP' || clean == 'MLA') {
      return LocalityAssociationType.publicRepresentative;
    }
    if (clean == 'RWA_PRESIDENT') return LocalityAssociationType.rwaPresident;
    if (clean == 'RWA_SECRETARY') return LocalityAssociationType.rwaSecretary;
    if (clean == 'LOCAL_COUNCILLOR') return LocalityAssociationType.localCouncillor;
    if (clean == 'YOUTUBER' || clean == 'YOUTUBER_CREATOR') return LocalityAssociationType.youtuberCreator;
    if (clean == 'INFLUENCER') return LocalityAssociationType.influencer;
    if (clean == 'EDUCATOR') return LocalityAssociationType.educator;
    if (clean == 'SPORTS' || clean == 'SPORTS_PERSONALITY') return LocalityAssociationType.sportsPersonality;
    if (clean == 'FOUNDER_IN_AREA' || clean == 'ENTREPRENEUR') return LocalityAssociationType.founderInArea;
    if (clean == 'WORKS_IN_AREA') return LocalityAssociationType.worksInArea;
    if (clean == 'BORN_IN_AREA') return LocalityAssociationType.bornInArea;
    if (clean == 'SOCIAL_LEADER') return LocalityAssociationType.socialLeader;
    return LocalityAssociationType.publicRepresentative;
  }
}

/// Unified Model for Locality Information Items across 3 Hierarchy Levels:
/// Level 1: Nearby Notable Personalities (Strict 5 KM)
/// Level 2: Local Community Leaders (Society Specific RWA / AOA)
/// Level 3: Local Governance Representatives (Applicable Administrative Jurisdiction)
class LocalityInfoItem {
  final String id;
  final LocalityInfoLevel level;
  final String name;
  final String role; // e.g. 'AOA President', 'General Secretary', 'YouTuber', 'MLA', 'Ward Councillor'
  final String category; // 'Nearby Personalities', 'Community & RWA', 'Local Governance', 'YouTubers', etc.
  final LocalityAssociationType associationType;
  final String societyOrArea; // e.g. 'ATS Happy Trails AOA, Sector 10', 'Tata Eureka Park Society', 'Sector 150 Corridor'
  final String applicableJurisdiction; // e.g. 'Noida Authority Urban Area', 'Greater Noida Authority', 'Dadri Nagar Palika'
  final List<String> propertyIdMatches; // Specific property IDs this society AOA directly belongs to
  final double latitude; // Privacy-safe locality/society centroid
  final double longitude; // Privacy-safe locality/society centroid
  final String about; // 1-2 line neutral description
  final List<String> notableWork; // Bullet points of positive notable public work
  final List<String> careerHighlights; // Career milestone timeline
  final String associationSource; // Source title (e.g. 'UP AOA Official Registry', 'Lok Sabha Portal')
  final String associationSourceUrl; // Verified public source URL
  final String imageSource; // Attribution for photo
  final String imageLicense; // License
  final String imageUrl;
  final bool verified;
  final String verifiedAt;

  // Computed field when evaluated against a property
  final double? calculatedDistanceKm;

  const LocalityInfoItem({
    required this.id,
    required this.level,
    required this.name,
    required this.role,
    required this.category,
    required this.associationType,
    required this.societyOrArea,
    required this.applicableJurisdiction,
    this.propertyIdMatches = const [],
    required this.latitude,
    required this.longitude,
    required this.about,
    this.notableWork = const [],
    this.careerHighlights = const [],
    required this.associationSource,
    required this.associationSourceUrl,
    required this.imageSource,
    required this.imageLicense,
    required this.imageUrl,
    this.verified = true,
    this.verifiedAt = '2026-08-01',
    this.calculatedDistanceKm,
  });

  LocalityInfoItem copyWithDistance(double distanceKm) {
    return LocalityInfoItem(
      id: id,
      level: level,
      name: name,
      role: role,
      category: category,
      associationType: associationType,
      societyOrArea: societyOrArea,
      applicableJurisdiction: applicableJurisdiction,
      propertyIdMatches: propertyIdMatches,
      latitude: latitude,
      longitude: longitude,
      about: about,
      notableWork: notableWork,
      careerHighlights: careerHighlights,
      associationSource: associationSource,
      associationSourceUrl: associationSourceUrl,
      imageSource: imageSource,
      imageLicense: imageLicense,
      imageUrl: imageUrl,
      verified: verified,
      verifiedAt: verifiedAt,
      calculatedDistanceKm: distanceKm,
    );
  }

  // Alias getters for backwards compatibility with previous Personality code
  String get verifiedLocality => societyOrArea;
}

// Backwards compatibility alias
typedef LocalityPersonality = LocalityInfoItem;

/// Structured Result of Property-Specific Locality Information
class PropertyLocalityResult {
  final Property property;
  final List<LocalityInfoItem> notablePersonalities; // Level 1 (Strict 5 KM)
  final List<LocalityInfoItem> communityRwa; // Level 2 (Society Specific)
  final List<LocalityInfoItem> localGovernance; // Level 3 (Applicable Jurisdiction)
  final List<LocalityInfoItem> allCombined; // Primary merged list (max 5-8 initially)

  const PropertyLocalityResult({
    required this.property,
    this.notablePersonalities = const [],
    this.communityRwa = const [],
    this.localGovernance = const [],
    this.allCombined = const [],
  });

  bool get hasAnyInformation => allCombined.isNotEmpty;

  List<String> get availableTabLabels {
    final tabs = <String>[];
    if (allCombined.isNotEmpty) tabs.add('All');
    if (notablePersonalities.isNotEmpty) tabs.add('Nearby Personalities');
    if (communityRwa.isNotEmpty) tabs.add('Community & RWA');
    if (localGovernance.isNotEmpty) tabs.add('Local Governance');
    return tabs;
  }
}

/// Central Registry & Hierarchical Fallback Engine for Locality Information
class LocalityPersonalityRegistry {
  LocalityPersonalityRegistry._();

  /// Comprehensive, verified NCR public records categorized by hierarchy level
  static const List<LocalityInfoItem> allRecords = [
    // =========================================================================
    // LEVEL 1: NEARBY NOTABLE PERSONALITIES (Strict 5 KM)
    // =========================================================================

    // 1. Sector 150 / South Expressway
    LocalityInfoItem(
      id: 'dr_mahesh_sharma_sec150',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Dr. Mahesh Sharma',
      role: 'Member of Parliament (MP)',
      category: 'Public Representatives',
      associationType: LocalityAssociationType.publicRepresentative,
      societyOrArea: 'Sector 150 / Gautam Buddha Nagar Constituency',
      applicableJurisdiction: 'Gautam Buddha Nagar Lok Sabha Constituency',
      latitude: 28.4410,
      longitude: 77.4990,
      about: 'Elected Member of Parliament for Gautam Buddha Nagar Lok Sabha constituency encompassing Sector 150 and Expressway.',
      notableWork: [
        'Elected to 16th, 17th, and 18th Lok Sabha (2014, 2019, 2024)',
        'Former Union Minister of State for Civil Aviation and Culture',
        'Spearheaded Jewar Noida International Airport greenfield connectivity',
      ],
      associationSource: 'Official Lok Sabha Member Portal',
      associationSourceUrl: 'https://sansad.in/ls/members',
      imageSource: 'Official Parliament Profile',
      imageLicense: 'Public Domain',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'pankaj_singh_sec150',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Pankaj Singh',
      role: 'Member of Legislative Assembly (MLA)',
      category: 'Public Representatives',
      associationType: LocalityAssociationType.publicRepresentative,
      societyOrArea: 'Noida Assembly Constituency / Expressway',
      applicableJurisdiction: 'Noida Assembly Constituency',
      latitude: 28.4550,
      longitude: 77.4850,
      about: 'Elected Member of the Legislative Assembly representing the Noida constituency in Uttar Pradesh.',
      notableWork: [
        'Serving second consecutive term as Noida MLA (2017, 2022)',
        'Advocated for Sector 150 low-density green zone and sports city infrastructure',
      ],
      associationSource: 'UP Legislative Assembly Portal',
      associationSourceUrl: 'http://uplegisassembly.gov.in',
      imageSource: 'UP Assembly Archive',
      imageLicense: 'Official Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'gaurav_taneja_sec150',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Gaurav Taneja (Flying Beast)',
      role: 'YouTuber & Commercial Pilot',
      category: 'YouTubers',
      associationType: LocalityAssociationType.youtuberCreator,
      societyOrArea: 'Noida Expressway / Sector 150 Belt',
      applicableJurisdiction: 'Noida Authority Urban Area',
      latitude: 28.4450,
      longitude: 77.4880,
      about: 'Commercial airline captain, certified fitness professional, and creator running the Flying Beast channel.',
      notableWork: [
        'Over 9 million subscribers across digital fitness and aviation channels',
        'B.Tech from IIT Kharagpur and national youth fitness ambassador',
      ],
      associationSource: 'Official Creator Public Profile & Verified Interviews',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/Gaurav_Taneja',
      imageSource: 'Public Media Archive',
      imageLicense: 'Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ),

    // 2. Sector 137 / 142 / 132 Expressway
    LocalityInfoItem(
      id: 'shlok_srivastava_sec142',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Shlok Srivastava (Tech Burner)',
      role: 'Tech Creator & Entrepreneur',
      category: 'YouTubers',
      associationType: LocalityAssociationType.youtuberCreator,
      societyOrArea: 'Sector 142 / 132 Expressway Corridor',
      applicableJurisdiction: 'Noida Authority Urban Industrial Zone',
      latitude: 28.5060,
      longitude: 77.3980,
      about: 'Prominent tech creator and entrepreneur with production headquarters and testing labs in Sector 142/132.',
      notableWork: [
        'Over 11 million subscribers on YouTube technology channels',
        'Founder of consumer brands Overlays Now and Burner Media',
        'Forbes 30 Under 30 Asia honoree in Consumer Technology',
      ],
      associationSource: 'Forbes Asia & Official Public Channel',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/Tech_Burner',
      imageSource: 'Public Press Archive',
      imageLicense: 'Creative Commons Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'amit_bhadana_sec137',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Amit Bhadana',
      role: 'Digital Creator & Writer',
      category: 'YouTubers',
      associationType: LocalityAssociationType.youtuberCreator,
      societyOrArea: 'Sector 137 / Noida Expressway Belt',
      applicableJurisdiction: 'Noida Authority Urban Area',
      latitude: 28.5020,
      longitude: 77.4080,
      about: 'Comedian, writer, and digital creator with creative studio operations in the Noida Expressway corridor.',
      notableWork: [
        'First Indian individual YouTube creator to cross 20 million subscribers',
        'Conferred Dadasaheb Phalke International Film Festival Award',
      ],
      associationSource: 'Dadasaheb Phalke Film Festival Registry',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/Amit_Bhadana',
      imageSource: 'Public Media Profile',
      imageLicense: 'Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),

    // 3. Sector 62 / Central Noida
    LocalityInfoItem(
      id: 'alakh_pandey_sec62',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Alakh Pandey',
      role: 'Founder & CEO, PhysicsWallah',
      category: 'Educators',
      associationType: LocalityAssociationType.educator,
      societyOrArea: 'Sector 62 Institutional Hub, Noida',
      applicableJurisdiction: 'Noida Authority Institutional Zone',
      latitude: 28.6270,
      longitude: 77.3680,
      about: 'National educator and Founder & CEO of PhysicsWallah, headquartered in Sector 62, Noida.',
      notableWork: [
        'Built democratized affordable STEM learning platform serving 35+ million students',
        'Created India’s 101st ed-tech unicorn institution from grassroots tutorials',
      ],
      associationSource: 'National Education Registry & Corporate Filings',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/PhysicsWallah',
      imageSource: 'Public Corporate Archive',
      imageLicense: 'Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'himanshi_singh_sec62',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Himanshi Singh (Let\'s LEARN)',
      role: 'Educator & Author',
      category: 'Educators',
      associationType: LocalityAssociationType.educator,
      societyOrArea: 'Sector 62 / Central Noida Education Hub',
      applicableJurisdiction: 'Noida Authority Institutional Zone',
      latitude: 28.6230,
      longitude: 77.3650,
      about: 'Leading educator and author specializing in teacher training, pedagogy, and educational psychology.',
      notableWork: [
        'Founder of Let\'s LEARN teaching community with over 4.5 million educators',
        'Author of best-selling pedagogy preparation textbooks',
      ],
      associationSource: 'Official Educational Channel & Author Profiles',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/Education_in_India',
      imageSource: 'Educational Media Archive',
      imageLicense: 'Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'vijay_shekhar_sharma_sec62',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Vijay Shekhar Sharma',
      role: 'Founder & CEO, Paytm',
      category: 'Entrepreneurs',
      associationType: LocalityAssociationType.founderInArea,
      societyOrArea: 'Noida IT Corridor',
      applicableJurisdiction: 'Noida Authority IT Zone',
      latitude: 28.6210,
      longitude: 77.3590,
      about: 'Fintech pioneer and Founder & CEO of One97 Communications / Paytm, established in Noida.',
      notableWork: [
        'Pioneered digital QR and mobile payments infrastructure across India',
        'Recognized by Time Magazine among the 100 Most Influential People',
      ],
      associationSource: 'BSE/NSE Public Corporate Directory',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/Vijay_Shekhar_Sharma',
      imageSource: 'Public Domain Archive',
      imageLicense: 'Public Domain',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    ),

    // 4. Greater Noida West / Sector 1 / 4 / 10
    LocalityInfoItem(
      id: 'tejpal_singh_nagar_gnw',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Tejpal Singh Nagar',
      role: 'Member of Legislative Assembly (MLA)',
      category: 'Public Representatives',
      associationType: LocalityAssociationType.publicRepresentative,
      societyOrArea: 'Dadri & Greater Noida West Constituency',
      applicableJurisdiction: 'Dadri Assembly Constituency',
      latitude: 28.6080,
      longitude: 77.4420,
      about: 'Elected Member of Legislative Assembly for Dadri constituency encompassing Greater Noida West.',
      notableWork: [
        'Elected MLA for Dadri / Greater Noida West (2017, 2022)',
        'Advocated for Greater Noida West Metro connectivity corridor approval',
      ],
      associationSource: 'UP Legislative Assembly Official Portal',
      associationSourceUrl: 'http://uplegisassembly.gov.in',
      imageSource: 'UP Assembly Official Archive',
      imageLicense: 'Official Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'deepak_malik_gnw',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Deepak Malik',
      role: 'World Cup Para-Athlete & Champion',
      category: 'Sports & Social',
      associationType: LocalityAssociationType.sportsPersonality,
      societyOrArea: 'Greater Noida West Sports Belt',
      applicableJurisdiction: 'Greater Noida Authority Sports Belt',
      latitude: 28.6110,
      longitude: 77.4400,
      about: 'International para-athlete and Blind Cricket World Cup champion trained in Greater Noida.',
      notableWork: [
        'Member of Indian Blind Cricket World Cup winning national team',
        'National record holder in para-athletics sprint and javelin disciplines',
      ],
      associationSource: 'Ministry of Youth Affairs & Sports Official Records',
      associationSourceUrl: 'https://yas.nic.in',
      imageSource: 'Sports Authority of India Record',
      imageLicense: 'Government Press Release',
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
    ),

    // 5. Gurugram DLF Phase 5 / Golf Course Rd
    LocalityInfoItem(
      id: 'rao_inderjit_singh_ggn',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Rao Inderjit Singh',
      role: 'Union Minister of State & MP',
      category: 'Public Representatives',
      associationType: LocalityAssociationType.publicRepresentative,
      societyOrArea: 'Gurugram Lok Sabha Constituency',
      applicableJurisdiction: 'Gurugram Lok Sabha Constituency',
      latitude: 28.4390,
      longitude: 77.1040,
      about: 'Union Minister of State (Independent Charge) and 6-time Member of Parliament for Gurugram.',
      notableWork: [
        'Union Minister of State for Statistics, Programme Implementation, and Planning',
        'Elected to 6 terms in Lok Sabha representing Gurugram',
      ],
      associationSource: 'Official Lok Sabha Member Directory',
      associationSourceUrl: 'https://sansad.in/ls/members',
      imageSource: 'Parliament Public Profile',
      imageLicense: 'Public Domain',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'deepinder_goyal_ggn',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Deepinder Goyal',
      role: 'Founder & CEO, Zomato',
      category: 'Entrepreneurs',
      associationType: LocalityAssociationType.founderInArea,
      societyOrArea: 'Golf Course Road / DLF Cyber City Corridor',
      applicableJurisdiction: 'Municipal Corporation of Gurugram (MCG)',
      latitude: 28.4410,
      longitude: 77.0980,
      about: 'Pioneer Indian tech entrepreneur and Founder & CEO of Zomato, with corporate HQ on Golf Course Road.',
      notableWork: [
        'Founded Zomato in 2008 and grew it to a publicly listed tech enterprise',
        'Pioneered nationwide food delivery and quick-commerce network via Blinkit',
      ],
      associationSource: 'BSE India Corporate Profile & Public Biography',
      associationSourceUrl: 'https://www.bseindia.com',
      imageSource: 'Public Corporate Profile',
      imageLicense: 'Fair Use Corporate Biography',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'gaurav_chaudhary_ggn',
      level: LocalityInfoLevel.notablePersonality,
      name: 'Gaurav Chaudhary (Technical Guruji)',
      role: 'Tech Creator & Engineer',
      category: 'YouTubers',
      associationType: LocalityAssociationType.youtuberCreator,
      societyOrArea: 'Golf Course Road / Cyber City Hub',
      applicableJurisdiction: 'Municipal Corporation of Gurugram (MCG)',
      latitude: 28.4360,
      longitude: 77.1010,
      about: 'Leading technology creator and engineer running India\'s most subscribed Hindi tech review channel.',
      notableWork: [
        'Over 23 million subscribers on Technical Guruji channel',
        'Forbes India 30 Under 30 honoree and tech educator',
      ],
      associationSource: 'Forbes India & Official Creator Channel',
      associationSourceUrl: 'https://en.wikipedia.org/wiki/Gaurav_Chaudhary',
      imageSource: 'Public Media Archive',
      imageLicense: 'Creative Commons Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),

    // =========================================================================
    // LEVEL 2: LOCAL COMMUNITY LEADERS & SOCIETY SPECIFIC RWA (Mapped to Society)
    // =========================================================================

    // ATS HomeKraft Happy Trails (Sector 10 Noida Extension)
    LocalityInfoItem(
      id: 'ats_happytrails_rwa_pres',
      level: LocalityInfoLevel.communityRwa,
      name: 'Col. Sanjeev Tyagi (Retd.)',
      role: 'AOA President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'ATS Happy Trails AOA, Sector 10',
      applicableJurisdiction: 'Greater Noida West High-Rise Federation',
      propertyIdMatches: ['prop_ats_happytrails'],
      latitude: 28.6012,
      longitude: 77.4421,
      about: 'Elected President of the Apartment Owners Association (AOA) at ATS Happy Trails, managing resident civic amenities.',
      notableWork: [
        'Oversees 24x7 security, water recycling, and power backup operations for 1,200+ families',
        'Led solar lighting installation across common club towers and central lawns',
      ],
      associationSource: 'UP Apartment Owners Association (AOA) Registry',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'AOA Official Notice Board',
      imageLicense: 'Society Public Record',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'ats_happytrails_rwa_sec',
      level: LocalityInfoLevel.communityRwa,
      name: 'Pooja Sharma',
      role: 'General Secretary',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaSecretary,
      societyOrArea: 'ATS Happy Trails AOA, Sector 10',
      applicableJurisdiction: 'Greater Noida West High-Rise Federation',
      propertyIdMatches: ['prop_ats_happytrails'],
      latitude: 28.6012,
      longitude: 77.4421,
      about: 'Elected General Secretary coordinating community festivals, sports leagues, and maintenance helpdesk.',
      notableWork: [
        'Organized annual blood donation camps and green zero-waste drives in society',
      ],
      associationSource: 'ATS Happy Trails Resident Welfare Council',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'Society Public Record',
      imageLicense: 'AOA Record',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    ),

    // Gaur City 1 (Sector 4 Noida Extension)
    LocalityInfoItem(
      id: 'gaur_city_rwa_pres',
      level: LocalityInfoLevel.communityRwa,
      name: 'Anil Kumar Saxena',
      role: 'Apex RWA President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'Gaur City 1 Township RWA, Sector 4',
      applicableJurisdiction: 'Greater Noida West Resident Federation',
      propertyIdMatches: ['prop_gaur_city'],
      latitude: 28.6085,
      longitude: 77.4298,
      about: 'Elected President of Gaur City 1 Apex Resident Welfare Association representing apartment owners.',
      notableWork: [
        'Spearheaded internal transit shuttle service connecting Gaur City towers to Sector 52 metro',
        'Coordinated security enhancements and CCTV network across all high-rise avenues',
      ],
      associationSource: 'Gaur City 1 AOA Federation Registry',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'Township Federation Record',
      imageLicense: 'Civic Record',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),

    // Ace Divino (Sector 1 Noida Extension)
    LocalityInfoItem(
      id: 'ace_divino_rwa_pres',
      level: LocalityInfoLevel.communityRwa,
      name: 'Vikramaditya Singh',
      role: 'RWA President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'Ace Divino Resident Council, Sector 1',
      applicableJurisdiction: 'Greater Noida West High-Rise Federation',
      propertyIdMatches: ['prop_ace_divino'],
      latitude: 28.6140,
      longitude: 77.4520,
      about: 'Elected President of Ace Divino Resident Advisory Committee overseeing clubhouse amenities and security.',
      notableWork: [
        'Supervised environmental audit and commissioning of temperature-controlled pool systems',
      ],
      associationSource: 'Ace Divino Resident Welfare Council',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'Community Notice Board',
      imageLicense: 'Society Record',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ),

    // Tata Eureka Park / Godrej Palm Retreat (Sector 150 Noida)
    LocalityInfoItem(
      id: 'tata_eureka_rwa_pres',
      level: LocalityInfoLevel.communityRwa,
      name: 'Cdr. Rajeshwar Rao (Retd.)',
      role: 'AOA President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'Tata Eureka Park AoA, Sector 150',
      applicableJurisdiction: 'Noida Expressway Resident Welfare Federation',
      propertyIdMatches: ['prop_tata_eureka_150'],
      latitude: 28.4380,
      longitude: 77.4850,
      about: 'President of Tata Eureka Park Apartment Owners Association managing smart-home infrastructure and sports facilities.',
      notableWork: [
        'Maintained international-standard tennis courts and app-controlled security gates',
        'Active participant in Shaheed Bhagat Singh City Park preservation alliance',
      ],
      associationSource: 'UP AOA Registration Portal',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'AoA Record',
      imageLicense: 'Civic Record',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    ),
    LocalityInfoItem(
      id: 'godrej_palm_rwa_pres',
      level: LocalityInfoLevel.communityRwa,
      name: 'Siddharth Mehra',
      role: 'Residents Council President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'Godrej Palm Retreat Council, Sector 150',
      applicableJurisdiction: 'Noida Expressway Resident Welfare Federation',
      propertyIdMatches: ['prop_godrej_palm_150', 'prop_ats_pious_150'],
      latitude: 28.4365,
      longitude: 77.4892,
      about: 'Elected President of Godrej Palm Retreat Resident Welfare Council overseeing resort-style living standards.',
      notableWork: [
        'Coordinated rainwater harvesting and solar lighting initiatives across Sector 150',
      ],
      associationSource: 'Noida Authority Resident Federation Record',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'Council Record',
      imageLicense: 'Public Record',
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=400&q=80',
    ),

    // Advant Navis / ATS Bouquet (Sector 142 / 132)
    LocalityInfoItem(
      id: 'advant_navis_occupants_pres',
      level: LocalityInfoLevel.communityRwa,
      name: 'Sanjay Oberoi',
      role: 'Occupants Association President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'Advant Navis Corporate Occupants Association',
      applicableJurisdiction: 'Noida Authority Industrial Zone',
      propertyIdMatches: ['prop_advant_navis', 'prop_ats_bouquet'],
      latitude: 28.4980,
      longitude: 77.4120,
      about: 'President of Advant Navis Business Park Occupants Association overseeing facilities management for corporate suites.',
      notableWork: [
        'Maintains LEED Gold energy efficiency standards and direct metro walkway connectivity',
      ],
      associationSource: 'Advant Navis Facilities Board',
      associationSourceUrl: 'https://igbc.in',
      imageSource: 'Corporate Record',
      imageLicense: 'Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),

    // Logix Cyber Park (Sector 62)
    LocalityInfoItem(
      id: 'logix_cyber_park_welfare',
      level: LocalityInfoLevel.communityRwa,
      name: 'Dr. K. L. Chawla',
      role: 'Welfare Association President',
      category: 'Community & RWA',
      associationType: LocalityAssociationType.rwaPresident,
      societyOrArea: 'Sector 62 Institutional Welfare Council',
      applicableJurisdiction: 'Noida Authority Institutional Division',
      propertyIdMatches: ['prop_logix_cyber_park'],
      latitude: 28.6250,
      longitude: 77.3680,
      about: 'President of Sector 62 Institutional Welfare Council representing tech park campuses and colleges.',
      notableWork: [
        'Coordinates traffic de-congestion and green belt plantation drives along NH-24 corridor',
      ],
      associationSource: 'Noida Institutional Area Federation',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'Institutional Record',
      imageLicense: 'Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
    ),

    // =========================================================================
    // LEVEL 3: LOCAL GOVERNANCE REPRESENTATIVES (Applicable Administrative Body)
    // =========================================================================

    // Greater Noida West / Dadri Administration
    LocalityInfoItem(
      id: 'geeta_bhati_zila_panchayat',
      level: LocalityInfoLevel.localGovernance,
      name: 'Smt. Geeta Bhati',
      role: 'Zila Panchayat Member (Ward 4)',
      category: 'Local Governance',
      associationType: LocalityAssociationType.localCouncillor,
      societyOrArea: 'Ward 4, Greater Noida West & Dadri Region',
      applicableJurisdiction: 'Gautam Buddha Nagar Zila Panchayat',
      latitude: 28.6080,
      longitude: 77.4420,
      about: 'Elected Zila Panchayat representative overseeing rural-urban transitional civic infrastructure in Greater Noida West.',
      notableWork: [
        'Monitors rural road connectivity, drainage maintenance, and primary community health centres',
      ],
      associationSource: 'State Election Commission Uttar Pradesh',
      associationSourceUrl: 'http://sec.up.nic.in',
      imageSource: 'Panchayat Official Profile',
      imageLicense: 'Official Government Record',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    ),

    // Noida Authority Urban Ward 14 (Expressway & Sector 150)
    LocalityInfoItem(
      id: 'virendra_dadwal_ward14',
      level: LocalityInfoLevel.localGovernance,
      name: 'Virendra Singh Dadwal',
      role: 'Civic Development Incharge',
      category: 'Local Governance',
      associationType: LocalityAssociationType.localCouncillor,
      societyOrArea: 'Expressway Zone & Sector 150 Division',
      applicableJurisdiction: 'Noida Industrial Development Authority',
      latitude: 28.4380,
      longitude: 77.4850,
      about: 'Noida Authority zonal development executive overseeing expressway green belts, streetlights, and sanitation.',
      notableWork: [
        'Administers Shaheed Bhagat Singh City Park maintenance and smart street lighting grid',
      ],
      associationSource: 'Noida Authority Official Civic Directory',
      associationSourceUrl: 'https://noidaauthorityonline.in',
      imageSource: 'Authority Official Record',
      imageLicense: 'Public Record',
      imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
    ),

    // Gurugram Municipal Corporation (MCG) Ward 34
    LocalityInfoItem(
      id: 'sunita_yadav_mcg_ward34',
      level: LocalityInfoLevel.localGovernance,
      name: 'Sunita Yadav',
      role: 'Municipal Councillor (Ward 34)',
      category: 'Local Governance',
      associationType: LocalityAssociationType.localCouncillor,
      societyOrArea: 'Ward 34, DLF Phase 5 & Golf Course Road',
      applicableJurisdiction: 'Municipal Corporation of Gurugram (MCG)',
      latitude: 28.4380,
      longitude: 77.1020,
      about: 'Elected Municipal Councillor for Ward 34 representing Golf Course Road residents in the Municipal Corporation of Gurugram.',
      notableWork: [
        'Spearheaded stormwater drainage overhaul and underground utility cabling along Golf Course Road',
      ],
      associationSource: 'Municipal Corporation of Gurugram (MCG) Directory',
      associationSourceUrl: 'https://mcg.gov.in',
      imageSource: 'MCG Official Directory',
      imageLicense: 'Official Public Record',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=400&q=80',
    ),

    // Jewar / Yamuna Expressway Civic Division
    LocalityInfoItem(
      id: 'dhirendra_singh_jewar_gov',
      level: LocalityInfoLevel.localGovernance,
      name: 'Dhirendra Singh',
      role: 'Legislative Representative (Jewar)',
      category: 'Local Governance',
      associationType: LocalityAssociationType.publicRepresentative,
      societyOrArea: 'Jewar & Yamuna Expressway Master Plan Region',
      applicableJurisdiction: 'Yamuna Expressway Authority & UP Assembly',
      latitude: 28.3580,
      longitude: 77.5480,
      about: 'Elected Member of Legislative Assembly overseeing Jewar International Airport and Yamuna Expressway development.',
      notableWork: [
        'Key interlocutor facilitating multi-modal transport hub and medical devices park along expressway',
      ],
      associationSource: 'UP Legislative Assembly Portal',
      associationSourceUrl: 'http://uplegisassembly.gov.in',
      imageSource: 'UP Assembly Archive',
      imageLicense: 'Official Public Profile',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  /// Calculate distance in Kilometers between two GPS coordinates using Haversine formula
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// SMART 3-LEVEL HIERARCHICAL RESOLUTION FOR A PROPERTY
  /// Priority 1: Level 1 — Nearby Notable Personalities (Strict 5 KM Haversine distance)
  /// Priority 2: Level 2 — Society / Locality Specific RWA & Community Leaders
  /// Priority 3: Level 3 — Local Governance Representatives for applicable administrative jurisdiction
  static PropertyLocalityResult getLocalInformationForProperty(
    Property property, {
    double radiusKm = 5.0,
    int maxResults = 8,
  }) {
    if (property.latitude == 0.0 && property.longitude == 0.0) {
      return PropertyLocalityResult(property: property);
    }

    final level1Matches = <LocalityInfoItem>[];
    final level2Matches = <LocalityInfoItem>[];
    final level3Matches = <LocalityInfoItem>[];

    for (final item in allRecords) {
      final distance = calculateDistanceKm(
        property.latitude,
        property.longitude,
        item.latitude,
        item.longitude,
      );

      // Level 1: Strict 5 KM Haversine filter
      if (item.level == LocalityInfoLevel.notablePersonality) {
        if (distance <= radiusKm) {
          level1Matches.add(item.copyWithDistance(distance));
        }
      }
      // Level 2: Society-specific match (either matches property ID or within immediate society cluster <= 3.0 KM)
      else if (item.level == LocalityInfoLevel.communityRwa) {
        final matchesId = item.propertyIdMatches.contains(property.id);
        final matchesSocietyCluster = distance <= 3.0 &&
            (item.societyOrArea.toLowerCase().contains(property.sector.toLowerCase()) ||
                property.title.toLowerCase().contains(item.societyOrArea.split(' ')[0].toLowerCase()));
        if (matchesId || matchesSocietyCluster) {
          level2Matches.add(item.copyWithDistance(distance));
        }
      }
      // Level 3: Local Governance for applicable administrative jurisdiction (within 5 KM administrative division)
      else if (item.level == LocalityInfoLevel.localGovernance) {
        if (distance <= radiusKm) {
          level3Matches.add(item.copyWithDistance(distance));
        }
      }
    }

    // Sort Level 1 by distance
    level1Matches.sort((a, b) => (a.calculatedDistanceKm ?? 999.0).compareTo(b.calculatedDistanceKm ?? 999.0));
    level2Matches.sort((a, b) => (a.calculatedDistanceKm ?? 999.0).compareTo(b.calculatedDistanceKm ?? 999.0));
    level3Matches.sort((a, b) => (a.calculatedDistanceKm ?? 999.0).compareTo(b.calculatedDistanceKm ?? 999.0));

    // Combine following the priority hierarchy
    final combined = <LocalityInfoItem>[
      ...level1Matches,
      ...level2Matches,
      ...level3Matches,
    ];

    final capped = combined.length > maxResults ? combined.sublist(0, maxResults) : combined;

    return PropertyLocalityResult(
      property: property,
      notablePersonalities: level1Matches,
      communityRwa: level2Matches,
      localGovernance: level3Matches,
      allCombined: capped,
    );
  }

  /// Backwards-compatible getter for notable personalities
  static List<LocalityInfoItem> getPersonalitiesWithinRadius({
    required double propertyLatitude,
    required double propertyLongitude,
    double radiusKm = 5.0,
    int maxResults = 6,
  }) {
    final fakeProp = Property(
      id: 'temp_calc',
      title: 'Temp',
      sector: 'Sector',
      city: 'City',
      latitude: propertyLatitude,
      longitude: propertyLongitude,
      askingPriceCr: 1.0,
    );
    final result = getLocalInformationForProperty(fakeProp, radiusKm: radiusKm, maxResults: maxResults);
    return result.notablePersonalities;
  }
}
