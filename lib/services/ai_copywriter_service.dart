import '../models/property.dart';

class GeneratedListingCopy {
  final String headline;
  final String professionalDescription;
  final List<String> highlights;
  final List<String> keySellingPoints;
  final String amenitiesSummary;
  final String locationSummary;
  final String buyerFriendlyPitch;
  final String whatsAppText;
  final String instagramCaption;

  GeneratedListingCopy({
    required this.headline,
    required this.professionalDescription,
    required this.highlights,
    required this.keySellingPoints,
    required this.amenitiesSummary,
    required this.locationSummary,
    required this.buyerFriendlyPitch,
    required this.whatsAppText,
    required this.instagramCaption,
  });

  Map<String, dynamic> toMap() => {
        'headline': headline,
        'professionalDescription': professionalDescription,
        'highlights': highlights,
        'keySellingPoints': keySellingPoints,
        'amenitiesSummary': amenitiesSummary,
        'locationSummary': locationSummary,
        'buyerFriendlyPitch': buyerFriendlyPitch,
        'whatsAppText': whatsAppText,
        'instagramCaption': instagramCaption,
      };
}

class AiCopywriterService {
  AiCopywriterService._();
  static final AiCopywriterService instance = AiCopywriterService._();

  /// Generates 8 multi-channel marketing & listing assets from property metadata
  Future<GeneratedListingCopy> generateListingCopy({
    required String title,
    required String propertyType,
    required String location,
    required String city,
    required double priceCr,
    required double sqft,
    required String bhk,
    required String furnishing,
    required String possession,
    required List<String> amenities,
    required String landmarks,
    required String dealerName,
    required String dealerPhone,
  }) async {
    // Artificial mini delay for responsive AI generation feedback
    await Future.delayed(const Duration(milliseconds: 650));

    final String priceStr = priceCr > 0 ? '₹${priceCr.toStringAsFixed(2)} Cr' : 'Price on Request';
    final String areaStr = '${sqft.round()} sq. ft.';
    final String effectiveLoc = location.isNotEmpty ? location : '$city Expressway';

    final headline = '✨ Luxury $bhk $propertyType in $effectiveLoc | $priceStr | $possession';

    final professionalDescription =
        'Experience distinguished modern living with this impeccably designed $bhk $propertyType situated in the prime corridor of $effectiveLoc, $city. '
        'Spanning an expansive $areaStr, this $furnishing residence offers optimal cross-ventilation, abundant natural daylight, and panoramic community vistas. '
        'Engineered to meet institutional-grade construction standards, the development provides resort-style luxury infrastructure and seamless connectivity to prime commercial hubs and transport links.';

    final highlights = [
      'Prime $effectiveLoc location with immediate expressway access',
      'Spacious $bhk layout ($areaStr) with 3-side open ventilation',
      'Status: $possession ($furnishing finish)',
      '100% Power backup with 3-tier gated security infrastructure',
      'RERA approved project with transparent title documentation',
    ];

    final keySellingPoints = [
      'High rental yield potential estimated at 4.2% - 5.1% per annum',
      'Direct proximity to upcoming metro connectivity and top schools',
      'Dedicated basement parking slot and high-speed OTIS elevators',
      'Zero brokerage assistance and direct institutional dealer facilitation',
    ];

    final amenitiesListStr = amenities.isNotEmpty ? amenities.join(' • ') : 'Club House • Swimming Pool • Gymnasium • 24/7 Security';
    final amenitiesSummary = 'Exclusive access to state-of-the-art community lifestyle amenities including $amenitiesListStr.';

    final locationSummary = landmarks.isNotEmpty
        ? 'Strategically situated in $effectiveLoc. Key landmarks nearby include: $landmarks. Seamless access to airport expressways and regional IT corridors.'
        : 'Strategically situated in $effectiveLoc with under 10 minutes drive to major metro corridors, commercial malls, and renowned healthcare institutions.';

    final buyerFriendlyPitch =
        'If you are seeking a dream family residence or a high-appreciation asset in $city, this $bhk at $effectiveLoc offers unmatched value at $priceStr. '
        'Ready for seamless site inspections with verified title paperwork.';

    final whatsAppText = '''
🏡 *NEW EXCLUSIVE LISTING ALERT* 🏡
📍 *$title — $effectiveLoc, $city*

✨ *Configuration:* $bhk $propertyType ($areaStr)
💰 *Price:* $priceStr ($furnishing)
🔑 *Possession:* $possession
🛡️ *PropZen Status:* Verified Documentation ✓

🌟 *Key Highlights:*
• $amenitiesListStr
• Direct access to $effectiveLoc
• 24/7 Gated Security & Power Backup

📲 *Book Private Site Visit & Get Brochure:*
📞 Contact: $dealerName ($dealerPhone)
🔗 Powered by PropZen Real Estate Platform
''';

    final instagramCaption = '''
Elevate your lifestyle with this stunning $bhk $propertyType in the heart of $effectiveLoc, $city! ✨🏡

📐 Size: $areaStr | 💰 Price: $priceStr
🛋️ Finish: $furnishing | 🔑 Status: $possession
🏊 Amenities: $amenitiesListStr

📍 Prime connectivity with high appreciation potential.

💬 Drop a comment or DM "PROPERTITY" to schedule an exclusive VIP site visit!

#PropZen #RealEstate #$city #LuxuryLiving #${bhk.replaceAll(' ', '')} #NCRProperties #DreamHome #PropertyInvestment #Realtor
''';

    return GeneratedListingCopy(
      headline: headline,
      professionalDescription: professionalDescription,
      highlights: highlights,
      keySellingPoints: keySellingPoints,
      amenitiesSummary: amenitiesSummary,
      locationSummary: locationSummary,
      buyerFriendlyPitch: buyerFriendlyPitch,
      whatsAppText: whatsAppText.trim(),
      instagramCaption: instagramCaption.trim(),
    );
  }
}
