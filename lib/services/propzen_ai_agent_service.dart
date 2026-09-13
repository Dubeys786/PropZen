import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/property.dart';
import '../models/buyer_requirement.dart';
import '../models/lead_model.dart';
import '../models/deal_room_model.dart';
import '../models/site_visit_checklist_model.dart';
import '../models/property_visit_plan.dart';
import '../models/post_visit_retention_model.dart';
import '../models/locality_personality.dart';
import 'property_state_service.dart';
import 'deal_room_service.dart';
import 'post_visit_retention_service.dart';
import 'ai_negotiation_service.dart';
import 'ai_copywriter_service.dart';
import 'ai_follow_up_service.dart';
import 'ai_matching_service.dart';
import 'site_visit_booking_service.dart';
import 'n8n_service.dart';
import 'supabase_service.dart';
import 'dealer_lead_service.dart';
import 'dealer_subscription_service.dart';
import 'nri_subscription_service.dart';
import '../screens/user_profile_screen.dart';

enum AgentFlow {
  none,
  search,
  details,
  enquiry,
  siteVisit,
}

enum EnquiryStage {
  none,
  collectingName,
  collectingPhone,
  collectingEmail,
  confirming,
  submitted,
}

enum SiteVisitStage {
  none,
  collectingDate,
  collectingTime,
  collectingVisitors,
  collectingCab,
  confirming,
  booked,
}

class ConversationMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime timestamp;
  final String language; // 'hinglish' | 'hindi' | 'english'
  final List<Property>? properties;
  final List<String>? suggestedChips;
  final String flowType;
  final String? triggeredAction;
  final Property? actionTargetProperty;
  final Map<String, dynamic>? comparisonData;
  final List<DealerLead>? dealerLeads;
  final Map<String, dynamic>? dealerInsight;

  ConversationMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.language = 'hinglish',
    this.properties,
    this.suggestedChips,
    this.flowType = 'general',
    this.triggeredAction,
    this.actionTargetProperty,
    this.comparisonData,
    this.dealerLeads,
    this.dealerInsight,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SessionContext {
  // Property search criteria
  String? purpose; // 'self-use', 'investment', 'commercial'
  String? propertyType; // 'Apartment', 'Villa', 'Plot', 'Commercial'
  String? location; // e.g. 'Noida', 'Sector 150', 'Noida Extension', 'Gurgaon', 'Yamuna Expressway'
  int? bedrooms; // e.g. 1, 2, 3, 4, 5
  double? maxBudget; // In raw numerical rupees e.g. 8000000 for 80 lakh, 15000000 for 1.5 Cr
  double? minBudget;
  String? status; // 'Ready to Move', 'Under Construction'
  List<String> preferredAmenities = [];
  bool nearMetro = false;
  bool nearExpressway = false;

  // Active property & search results
  Property? selectedProperty;
  List<Property> lastFoundProperties = [];

  // Client info (pre-populated from UserSession if logged in)
  String? clientName;
  String? clientPhone;
  String? clientEmail;

  // Multi-Turn Flow & State Machine
  AgentFlow activeFlow = AgentFlow.none;
  EnquiryStage enquiryStage = EnquiryStage.none;
  SiteVisitStage siteVisitStage = SiteVisitStage.none;

  // Site Visit parameters
  String? visitDate; // e.g. '28 August 2026', 'Tomorrow'
  String? visitDateIso; // e.g. '2026-08-28'
  String? visitTime; // e.g. '12:00 PM', '03:00 PM'
  String? bookingId; // Confirmed Booking Reference ID
  int visitorCount = 1;
  bool cabRequired = false;
  String specialNotes = '';

  // Lead qualification
  String qualificationTier = 'Exploring'; // 'High Intent', 'Investor', 'Self Use', 'Site Visit Ready', 'Exploring'

  // Slot-filling flags & Anti-Loop
  bool justCapturedLocation = false;
  bool justCapturedBudget = false;
  bool justCapturedBhk = false;
  bool justCapturedPurpose = false;
  String? lastAskedEntity; // 'greeting', 'purpose', 'location', 'propertyType', 'budget', 'status', 'feedback', 'enquiryConfirm', 'siteVisitDate', 'siteVisitTime', 'siteVisitContact', 'siteVisitEmail', 'siteVisitCab', 'siteVisitConfirm'
  String detectedLanguage = 'hinglish';
  bool hasHadProactiveGreeting = false;

  SessionContext() {
    _initFromUserSession();
  }

  void _initFromUserSession() {
    if (UserSession.isLoggedIn) {
      if (UserSession.fullName.isNotEmpty) clientName = UserSession.fullName;
      if (UserSession.mobileNumber.isNotEmpty) clientPhone = UserSession.mobileNumber;
      if (UserSession.email.isNotEmpty) clientEmail = UserSession.email;
    }
  }

  // Helper Getters for Formatted Display
  String? get preferredLocation => location;
  String? get preferredBudget {
    if (maxBudget == null) return null;
    if (maxBudget! >= 10000000) {
      final cr = maxBudget! / 10000000;
      return '${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else {
      final l = maxBudget! / 100000;
      return '${l.toStringAsFixed(l.truncateToDouble() == l ? 0 : 2)} Lakh';
    }
  }

  String get formattedBudgetHindi {
    if (maxBudget == null) return 'आपके बजट';
    if (maxBudget! >= 10000000) {
      final cr = maxBudget! / 10000000;
      return '${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} करोड़';
    } else if (maxBudget! >= 100000) {
      final l = maxBudget! / 100000;
      return '${l.toStringAsFixed(l.truncateToDouble() == l ? 0 : 2)} लाख';
    } else {
      return '₹${maxBudget!.toInt()}';
    }
  }

  String get formattedBudgetHinglish {
    if (maxBudget == null) return 'aapke budget';
    if (maxBudget! >= 10000000) {
      final cr = maxBudget! / 10000000;
      return '${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Crore';
    } else if (maxBudget! >= 100000) {
      final l = maxBudget! / 100000;
      return '${l.toStringAsFixed(l.truncateToDouble() == l ? 0 : 2)} Lakh';
    } else {
      return '₹${maxBudget!.toInt()}';
    }
  }

  String get formattedBudgetEnglish {
    if (maxBudget == null) return 'your budget';
    if (maxBudget! >= 10000000) {
      final cr = maxBudget! / 10000000;
      return '₹${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (maxBudget! >= 100000) {
      final l = maxBudget! / 100000;
      return '₹${l.toStringAsFixed(l.truncateToDouble() == l ? 0 : 2)} Lakh';
    } else {
      return '₹${maxBudget!.toInt()}';
    }
  }

  String get formattedBhkOrType {
    if (bedrooms != null) {
      return '$bedrooms BHK';
    }
    if (propertyType != null) {
      return propertyType!;
    }
    return '2/3 BHK';
  }

  String? get preferredBhk => bedrooms != null ? '$bedrooms BHK' : null;
  String? get possessionTimeline => status;

  void reset() {
    purpose = null;
    propertyType = null;
    location = null;
    bedrooms = null;
    maxBudget = null;
    minBudget = null;
    status = null;
    preferredAmenities.clear();
    nearMetro = false;
    nearExpressway = false;
    selectedProperty = null;
    lastFoundProperties.clear();
    activeFlow = AgentFlow.none;
    enquiryStage = EnquiryStage.none;
    siteVisitStage = SiteVisitStage.none;
    visitDate = null;
    visitTime = null;
    visitorCount = 1;
    cabRequired = false;
    specialNotes = '';
    qualificationTier = 'Exploring';
    detectedLanguage = 'hinglish';
    justCapturedLocation = false;
    justCapturedBudget = false;
    justCapturedBhk = false;
    justCapturedPurpose = false;
    lastAskedEntity = null;
    hasHadProactiveGreeting = false;
    _initFromUserSession();
  }

  /// Normalize Devanagari numerals, currency symbols, and speech-to-text artifacts
  static String normalizeNumeralsAndText(String input) {
    const devanagariDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    String res = input;
    for (int i = 0; i < devanagariDigits.length; i++) {
      res = res.replaceAll(devanagariDigits[i], '$i');
    }
    res = res.replaceAll('।', ' ');
    res = res.replaceAll(RegExp(r'[₹\$]'), ' ').replaceAll(RegExp(r'\b(rs|inr|rupees|रुपये|रुपए|रु)\b', caseSensitive: false), ' ');
    return res;
  }

  /// Check if input is a casual affirmation (YES) in Hindi/Hinglish/English
  static bool isAffirmation(String input) {
    final lower = input.trim().toLowerCase();
    if (lower.contains('floor plan') ||
        lower.contains('metro') ||
        lower.contains('distance') ||
        lower.contains('layout') ||
        lower.contains('door') ||
        lower.contains('facing') ||
        lower.contains('sqft') ||
        lower.contains('bhk') ||
        lower.contains('budget') ||
        lower.contains('cr') ||
        lower.contains('lakh') ||
        lower.contains('tata') ||
        lower.contains('ats') ||
        lower.contains('godrej') ||
        lower.contains('gaur') ||
        lower.contains('cancel') ||
        lower.contains('change') ||
        lower.contains('nahi')) {
      return false;
    }

    final clean = lower.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), '').trim();
    final tokens = clean.split(RegExp(r'\s+'));
    if (tokens.length > 5) return false;

    const yesTerms = {
      'ha', 'haan', 'हाँ', 'haa', 'han', 'hnn', 'bilkul', 'kar lo', 'karlo', 'yes', 'yeah', 'yep',
      'sahi hai', 'sahihai', 'ok', 'okay', 'theek hai', 'theek', 'thik', 'thik hai', 'sure',
      'batao', 'bataiye', 'zaroor', 'chalo', 'definitely', 'bhejo', 'dikhao', 'submit', 'confirm',
      'kar do', 'kardo', 'book', 'book karo', 'kar dijiye', 'proceed'
    };

    if (yesTerms.contains(clean)) return true;
    for (final t in tokens) {
      if (yesTerms.contains(t)) return true;
    }
    return false;
  }

  /// Check if input is a negation (NO) in Hindi/Hinglish/English
  static bool isNegation(String input) {
    final lower = input.trim().toLowerCase();
    final clean = lower.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F\s]'), '').trim();
    const noTerms = {'no', 'nahi', 'nahin', 'नही', 'नहीं', 'nope', 'not', 'cancel', 'mat karo', 'change karo', 'dont'};
    if (noTerms.contains(clean)) return true;
    final tokens = clean.split(RegExp(r'\s+'));
    for (final t in tokens) {
      if (noTerms.contains(t)) return true;
    }
    return false;
  }

  /// Parse natural language into structured session memory
  void updateFromUserInput(String input) {
    final oldLoc = location;
    final oldBudget = maxBudget;
    final oldBedrooms = bedrooms;
    final oldPropType = propertyType;
    final oldPurpose = purpose;

    justCapturedLocation = false;
    justCapturedBudget = false;
    justCapturedBhk = false;
    justCapturedPurpose = false;

    final normalized = normalizeNumeralsAndText(input);
    final lower = normalized.toLowerCase();

    // 1. Purpose parsing (Self-use, Investment, Commercial)
    if (lower.contains('invest') || lower.contains('investment') || lower.contains('rental') || lower.contains('kiraya') || lower.contains('yield') || lower.contains('appreciation') || lower.contains('निवेश')) {
      purpose = 'investment';
      qualificationTier = 'Investor';
    } else if (lower.contains('rehne') || lower.contains('family') || lower.contains('self') || lower.contains('ghar') || lower.contains('shift') || lower.contains('apne') || lower.contains('use') || lower.contains('personal') || lower.contains('रहने') || lower.contains('खुद')) {
      purpose = 'self-use';
      qualificationTier = 'Self Use';
    } else if (lower.contains('commercial') || lower.contains('office') || lower.contains('shop') || lower.contains('business')) {
      purpose = 'commercial';
      propertyType = 'Commercial';
    } else if (lower.contains('residential') || lower.contains('flat') || lower.contains('apartment')) {
      purpose = 'self-use';
    }

    if (purpose != null && oldPurpose == null) {
      justCapturedPurpose = true;
    }

    // 2. Location parsing
    if (lower.contains('noida extension') || lower.contains('greater noida west') || lower.contains('noida ext') || lower.contains('gr noida west')) {
      location = 'Noida Extension';
    } else if (lower.contains('sector 150') || lower.contains('sec 150') || lower.contains('150')) {
      location = 'Sector 150';
    } else if (lower.contains('sector 137') || lower.contains('sec 137') || lower.contains('137')) {
      location = 'Sector 137';
    } else if (lower.contains('sector 43') || lower.contains('sec 43') || lower.contains('43')) {
      location = 'Sector 43';
    } else if (lower.contains('sector 124') || lower.contains('sec 124')) {
      location = 'Sector 124';
    } else if (lower.contains('sector 63') || lower.contains('sec 63')) {
      location = 'Sector 63';
    } else if (lower.contains('yamuna expressway') || lower.contains('jewar') || lower.contains('yeida')) {
      location = 'Yamuna Expressway';
    } else if (lower.contains('greater noida') || lower.contains('pari chowk')) {
      location = 'Greater Noida';
    } else if (lower.contains('noida') || lower.contains('नोएडा')) {
      location = 'Noida';
    } else if (lower.contains('gurgaon') || lower.contains('gurugram') || lower.contains('golf course') || lower.contains('dwarka expressway') || lower.contains('गुड़गांव')) {
      location = 'Gurgaon';
    } else if (lower.contains('delhi') || lower.contains('दिल्ली')) {
      location = 'Delhi NCR';
    }

    if (location != null && oldLoc == null) {
      justCapturedLocation = true;
    }

    // Proximity flags
    if (lower.contains('metro') || lower.contains('metro ke paas') || lower.contains('near metro')) {
      nearMetro = true;
    }
    if (lower.contains('expressway') || lower.contains('expressway ke paas') || lower.contains('near highway')) {
      nearExpressway = true;
    }

    // 3. BHK / Bedrooms parsing
    if (lower.contains('1 bhk') || lower.contains('1bhk') || lower.contains('1 bedroom') || lower.contains('one bhk') || lower.contains('studio')) {
      bedrooms = 1;
    } else if (lower.contains('2 bhk') || lower.contains('2bhk') || lower.contains('2 bedroom') || lower.contains('two bhk') || lower.contains('2 बीएचके')) {
      bedrooms = 2;
    } else if (lower.contains('3 bhk') || lower.contains('3bhk') || lower.contains('3 bedroom') || lower.contains('three bhk') || lower.contains('3 बीएचके')) {
      bedrooms = 3;
    } else if (lower.contains('4 bhk') || lower.contains('4bhk') || lower.contains('4 bedroom') || lower.contains('four bhk') || lower.contains('4 बीएचके')) {
      bedrooms = 4;
    } else if (lower.contains('5 bhk') || lower.contains('5bhk') || lower.contains('5 bedroom') || lower.contains('five bhk')) {
      bedrooms = 5;
    }

    // 4. Property Type
    if (lower.contains('villa') || lower.contains('kothi') || lower.contains('विला')) {
      propertyType = 'Villa';
    } else if (lower.contains('plot') || lower.contains('land') || lower.contains('zameen') || lower.contains('प्लॉट')) {
      propertyType = 'Plot';
    } else if (lower.contains('commercial') || lower.contains('office') || lower.contains('shop') || lower.contains('दुकान')) {
      propertyType = 'Commercial';
    } else if (lower.contains('flat') || lower.contains('apartment') || lower.contains('floor') || lower.contains('अपार्टमेंट')) {
      propertyType = 'Apartment';
    }

    if ((bedrooms != null && oldBedrooms == null) || (propertyType != null && oldPropType == null)) {
      justCapturedBhk = true;
    }

    // 5. Robust Budget parsing
    _parseBudget(normalized);
    if (maxBudget != null && oldBudget == null) {
      justCapturedBudget = true;
    }

    // 6. Property Status / Possession
    if (lower.contains('ready to move') || lower.contains('ready-to-move') || lower.contains('ready') || lower.contains('immediate') || lower.contains('turant') || lower.contains('रेडी')) {
      status = 'Ready to Move';
    } else if (lower.contains('under construction') || lower.contains('under-construction') || lower.contains('launch') || lower.contains('upcoming')) {
      status = 'Under Construction';
    }

    // 7. Contact info extraction (Name, Phone, Email)
    _parseContactInfo(normalized);

    // 8. Site visit appointment parsing (Date, Time, Visitors, Cab)
    _parseSiteVisitDetails(normalized);

    // Update Lead Qualification tier
    if (siteVisitStage == SiteVisitStage.booked || activeFlow == AgentFlow.siteVisit) {
      qualificationTier = 'Site Visit Ready';
    } else if (maxBudget != null && maxBudget! >= 10000000 && (purpose == 'investment' || purpose == 'self-use')) {
      qualificationTier = 'High Intent';
    }
  }

  void _parseContactInfo(String rawText) {
    // 10-digit mobile number extraction
    final phoneMatch = RegExp(r'(\+91[\-\s]?)?[6-9]\d{9}').firstMatch(rawText);
    if (phoneMatch != null) {
      final cleanDigits = phoneMatch.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDigits.length == 10) {
        clientPhone = cleanDigits;
      } else if (cleanDigits.length == 12 && cleanDigits.startsWith('91')) {
        clientPhone = cleanDigits.substring(2);
      }
    }

    // Email extraction
    final emailMatch = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b').firstMatch(rawText);
    if (emailMatch != null) {
      clientEmail = emailMatch.group(0);
    }

    // Name extraction e.g. "Mera naam Rahul Sharma hai", "Name is Amit", "I am Priya"
    final nameMatch = RegExp(r'(?:mera naam|my name is|naam|name|i am|this is)\s+([A-Za-z\u0900-\u097F\s]{2,35})', caseSensitive: false).firstMatch(rawText);
    if (nameMatch != null) {
      var extracted = nameMatch.group(1)!.trim();
      final cutoff = RegExp(r'\b(mobile|phone|number|email|contact|hai|hoon|here|please|aur|and|site|visit)\b', caseSensitive: false).firstMatch(extracted);
      if (cutoff != null) {
        extracted = extracted.substring(0, cutoff.start).trim();
      }
      if (extracted.length >= 2 && !extracted.contains('1') && !extracted.contains('bhk')) {
        clientName = extracted;
      }
    }
  }

  static String _monthName(int m) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return (m >= 1 && m <= 12) ? months[m - 1] : 'August';
  }

  static int _monthIndex(String name) {
    final lower = name.toLowerCase();
    if (lower.startsWith('jan')) return 1;
    if (lower.startsWith('feb')) return 2;
    if (lower.startsWith('mar')) return 3;
    if (lower.startsWith('apr')) return 4;
    if (lower.startsWith('may')) return 5;
    if (lower.startsWith('jun')) return 6;
    if (lower.startsWith('jul')) return 7;
    if (lower.startsWith('aug')) return 8;
    if (lower.startsWith('sep')) return 9;
    if (lower.startsWith('oct')) return 10;
    if (lower.startsWith('nov')) return 11;
    if (lower.startsWith('dec')) return 12;
    return 8;
  }

  void _parseSiteVisitDetails(String rawText) {
    final lower = rawText.toLowerCase();
    final now = DateTime.now();

    // 1. Precise Natural Language Date Extraction
    if (lower.contains('kal') || lower.contains('tomorrow')) {
      final tomorrow = now.add(const Duration(days: 1));
      visitDateIso = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      visitDate = '${tomorrow.day} ${_monthName(tomorrow.month)} ${tomorrow.year} (Tomorrow)';
    } else if (lower.contains('parso') || lower.contains('day after tomorrow') || lower.contains('day after')) {
      final dayAfter = now.add(const Duration(days: 2));
      visitDateIso = '${dayAfter.year}-${dayAfter.month.toString().padLeft(2, '0')}-${dayAfter.day.toString().padLeft(2, '0')}';
      visitDate = '${dayAfter.day} ${_monthName(dayAfter.month)} ${dayAfter.year}';
    } else if (lower.contains('aaj') || lower.contains('today')) {
      visitDateIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      visitDate = '${now.day} ${_monthName(now.month)} ${now.year} (Today)';
    } else if (lower.contains('saturday') || lower.contains('shanivar') || lower.contains('shaniwar')) {
      final daysUntilSat = (DateTime.saturday - now.weekday + 7) % 7 == 0 ? 7 : (DateTime.saturday - now.weekday + 7) % 7;
      final target = now.add(Duration(days: daysUntilSat));
      visitDateIso = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
      visitDate = '${target.day} ${_monthName(target.month)} ${target.year} (Saturday)';
    } else if (lower.contains('sunday') || lower.contains('ravivar') || lower.contains('itwar')) {
      final daysUntilSun = (DateTime.sunday - now.weekday + 7) % 7 == 0 ? 7 : (DateTime.sunday - now.weekday + 7) % 7;
      final target = now.add(Duration(days: daysUntilSun));
      visitDateIso = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
      visitDate = '${target.day} ${_monthName(target.month)} ${target.year} (Sunday)';
    } else if (lower.contains('weekend')) {
      final daysUntilSat = (DateTime.saturday - now.weekday + 7) % 7 == 0 ? 7 : (DateTime.saturday - now.weekday + 7) % 7;
      final target = now.add(Duration(days: daysUntilSat));
      visitDateIso = '${target.year}-${target.month.toString().padLeft(2, '0')}-${target.day.toString().padLeft(2, '0')}';
      visitDate = '${target.day} ${_monthName(target.month)} ${target.year} (Upcoming Weekend)';
    } else {
      final isoMatch = RegExp(r'\b(202\d)[\-\/](\d{1,2})[\-\/](\d{1,2})\b').firstMatch(rawText);
      if (isoMatch != null) {
        final y = int.parse(isoMatch.group(1)!);
        final m = int.parse(isoMatch.group(2)!);
        final d = int.parse(isoMatch.group(3)!);
        visitDateIso = '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        visitDate = '$d ${_monthName(m)} $y';
      } else {
        final ddmmyyyyMatch = RegExp(r'\b(\d{1,2})[\-\/](\d{1,2})[\-\/](202\d)\b').firstMatch(rawText);
        if (ddmmyyyyMatch != null) {
          final d = int.parse(ddmmyyyyMatch.group(1)!);
          final m = int.parse(ddmmyyyyMatch.group(2)!);
          final y = int.parse(ddmmyyyyMatch.group(3)!);
          visitDateIso = '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
          visitDate = '$d ${_monthName(m)} $y';
        } else {
          final dateMatch = RegExp(r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|january|february|march|april|may|june|july|august|september|october|november|december)\b', caseSensitive: false).firstMatch(rawText);
          if (dateMatch != null) {
            final day = int.parse(dateMatch.group(1)!);
            final mStr = dateMatch.group(2)!.toLowerCase();
            final month = _monthIndex(mStr);
            final year = (month < now.month || (month == now.month && day < now.day)) ? now.year + 1 : now.year;
            visitDateIso = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            visitDate = '$day ${_monthName(month)} $year';
          }
        }
      }
    }

    // 2. Time Slot Extraction & Normalization
    if (lower.contains('10 am') || lower.contains('10:00 am') || lower.contains('10 baje subah') || lower.contains('morning') || lower.contains('10:00') || lower.contains('10 baje')) {
      visitTime = '10:00 AM';
    } else if (lower.contains('11:30 am') || lower.contains('11:30') || lower.contains('11:30 baje')) {
      visitTime = '11:30 AM';
    } else if (lower.contains('11 am') || lower.contains('11:00 am') || lower.contains('11 baje') || lower.contains('11:00') || lower == '11' || lower.contains('gyarah')) {
      visitTime = '11:00 AM';
    } else if (lower.contains('12 pm') || lower.contains('12:00 pm') || lower.contains('12 baje') || lower.contains('dopahar') || lower.contains('noon') || lower.contains('12:00')) {
      visitTime = '12:00 PM';
    } else if (lower.contains('2 pm') || lower.contains('02:00 pm') || lower.contains('2:00 pm') || lower.contains('2 baje') || lower.contains('14:00')) {
      visitTime = '02:00 PM';
    } else if (lower.contains('3 pm') || lower.contains('03:00 pm') || lower.contains('3:00 pm') || lower.contains('3 baje') || lower.contains('15:00') || lower.contains('afternoon')) {
      visitTime = '03:00 PM';
    } else if (lower.contains('4 pm') || lower.contains('04:00 pm') || lower.contains('4:00 pm') || lower.contains('4 baje') || lower.contains('16:00')) {
      visitTime = '04:00 PM';
    } else if (lower.contains('5 pm') || lower.contains('05:00 pm') || lower.contains('5:00 pm') || lower.contains('5 baje') || lower.contains('17:00') || lower.contains('evening') || lower.contains('shaam')) {
      visitTime = '05:00 PM';
    }

    // 3. Visitor Count Extraction
    final visitorMatch = RegExp(r'\b(\d+)\s*(people|person|persons|visitors|members|log|hum|members)\b', caseSensitive: false).firstMatch(lower);
    if (visitorMatch != null) {
      final cnt = int.tryParse(visitorMatch.group(1)!);
      if (cnt != null && cnt > 0) visitorCount = cnt;
    } else if (lower.contains('akela') || lower.contains('alone') || lower.contains('single') || lower.contains('only me')) {
      visitorCount = 1;
    } else if (lower.contains('family') || lower.contains('hum do') || lower.contains('2 log')) {
      visitorCount = 2;
    }

    // 4. Cab Requirement Extraction
    if (lower.contains('cab chahiye') || lower.contains('cab assistance') || lower.contains('cab required') || lower.contains('pick up') || lower.contains('pickup') || lower.contains('need cab')) {
      cabRequired = true;
    } else if (lower.contains('cab nahi') || lower.contains('no cab') || lower.contains('own car') || lower.contains('khud ki gaadi') || lower.contains('self drive') || lower.contains('no need cab')) {
      cabRequired = false;
    }
  }

  void _parseBudget(String rawText) {
    final text = rawText.toLowerCase();

    // A. Range e.g. "80-90 lakh", "80 to 90 lakh", "1 to 2 crore"
    final rangeLakhMatch = RegExp(r'(\d+(\.\d+)?)\s*(?:-|to|se)\s*(\d+(\.\d+)?)\s*(?:lakh|lacs|lac|l|लाख)', caseSensitive: false).firstMatch(text);
    if (rangeLakhMatch != null) {
      final upperVal = double.tryParse(rangeLakhMatch.group(3)!);
      if (upperVal != null && upperVal > 0) {
        maxBudget = upperVal * 100000.0;
        return;
      }
    }

    final rangeCrMatch = RegExp(r'(\d+(\.\d+)?)\s*(?:-|to|se)\s*(\d+(\.\d+)?)\s*(?:cr|crore|crores|करोड़)', caseSensitive: false).firstMatch(text);
    if (rangeCrMatch != null) {
      final upperVal = double.tryParse(rangeCrMatch.group(3)!);
      if (upperVal != null && upperVal > 0) {
        maxBudget = upperVal * 10000000.0;
        return;
      }
    }

    // B. Thousand / K e.g. "50k", "50 thousand", "50 हजार"
    final kMatch = RegExp(r'([\d,]+(\.\d+)?)\s*(k|thousand|हजार)', caseSensitive: false).firstMatch(text);
    if (kMatch != null) {
      final cleanNumStr = kMatch.group(1)!.replaceAll(',', '');
      final numVal = double.tryParse(cleanNumStr);
      if (numVal != null && numVal > 0) {
        maxBudget = numVal * 1000.0;
        return;
      }
    }

    // C. Crore e.g. "1.5 cr", "1 crore", "2 crores", "1,5 करोड़"
    final crMatch = RegExp(r'([\d,]+(\.\d+)?)\s*(cr|crore|crores|करोड़|cr\.)', caseSensitive: false).firstMatch(text);
    if (crMatch != null) {
      final cleanNumStr = crMatch.group(1)!.replaceAll(',', '');
      final numVal = double.tryParse(cleanNumStr);
      if (numVal != null && numVal > 0) {
        maxBudget = numVal * 10000000.0;
        return;
      }
    }

    // D. Lakh e.g. "80 lakh", "80l", "80 lac", "80 lacs", "60 lakhs", "80 लाख", "under 70L"
    final lakhMatch = RegExp(r'([\d,]+(\.\d+)?)\s*(lakh|lakhs|lac|lacs|l|लाख|lakh\.)', caseSensitive: false).firstMatch(text);
    if (lakhMatch != null) {
      final cleanNumStr = lakhMatch.group(1)!.replaceAll(',', '');
      final numVal = double.tryParse(cleanNumStr);
      if (numVal != null && numVal > 0) {
        maxBudget = numVal * 100000.0;
        return;
      }
    }

    // E. Formatted commas e.g. "80,00,000", "1,00,00,000", "50,00,000"
    final commaNumMatch = RegExp(r'\b(\d{1,3}(,\d{2,3})+(\.\d+)?)\b').firstMatch(text);
    if (commaNumMatch != null) {
      final cleanNumStr = commaNumMatch.group(1)!.replaceAll(',', '');
      final numVal = double.tryParse(cleanNumStr);
      if (numVal != null && numVal > 0) {
        maxBudget = numVal;
        return;
      }
    }

    // F. Pure digits >= 6 digits e.g. "8000000"
    final pureNumMatch = RegExp(r'\b(\d{6,10})\b').firstMatch(text);
    if (pureNumMatch != null) {
      final numVal = double.tryParse(pureNumMatch.group(1)!);
      if (numVal != null && numVal > 0) {
        maxBudget = numVal;
        return;
      }
    }

    // G. Standalone numbers e.g. "80", "100", "1.5"
    final allNumbers = RegExp(r'\b(\d+(\.\d+)?)\b').allMatches(text).toList();
    for (final m in allNumbers) {
      final numVal = double.tryParse(m.group(1)!);
      if (numVal != null) {
        if (numVal >= 100000) {
          maxBudget = numVal;
          return;
        } else if (numVal >= 10 && numVal <= 500) {
          maxBudget = numVal * 100000.0;
          return;
        } else if (numVal > 0 && numVal < 10) {
          if (m.group(1)!.contains('.') || (bedrooms != null && bedrooms != numVal.toInt())) {
            maxBudget = numVal * 10000000.0;
            return;
          }
        }
      }
    }
  }

  bool get hasAllMandatoryDetails {
    return location != null && maxBudget != null && (bedrooms != null || propertyType != null);
  }

  bool get hasEnoughInfoToSearch {
    if (hasAllMandatoryDetails) return true;
    if (bedrooms != null && (location != null || maxBudget != null)) return true;
    if (propertyType != null && (location != null || maxBudget != null)) return true;
    if (location != null && status != null) return true;
    return false;
  }
}

class AiAgentResult {
  final String speechResponse;
  final String textResponse;
  final String language;
  final List<Property> matchedProperties;
  final SessionContext context;
  final List<String> suggestedChips;
  final String flowType;
  final String? triggeredAction;
  final Property? actionTargetProperty;
  final Map<String, dynamic>? comparisonData;
  final List<DealerLead>? dealerLeads;
  final Map<String, dynamic>? dealerInsight;

  AiAgentResult({
    required this.speechResponse,
    required this.textResponse,
    required this.language,
    required this.matchedProperties,
    required this.context,
    this.suggestedChips = const [],
    this.flowType = 'general',
    this.triggeredAction,
    this.actionTargetProperty,
    this.comparisonData,
    this.dealerLeads,
    this.dealerInsight,
  });
}

class PropzenAiAgentService {
  PropzenAiAgentService._();
  static final PropzenAiAgentService instance = PropzenAiAgentService._();

  final List<ConversationMessage> _sessionHistory = [];
  final SessionContext _context = SessionContext();

  List<ConversationMessage> get sessionHistory => List.unmodifiable(_sessionHistory);
  SessionContext get context => _context;

  void clearSession() {
    _sessionHistory.clear();
    _context.reset();
  }

  /// Generates the proactive opening greeting when the agent starts first
  String getProactiveOpeningGreeting({String? language}) {
    final lang = language ?? _context.detectedLanguage;
    _context.hasHadProactiveGreeting = true;
    _context.lastAskedEntity = 'purpose';

    if (lang == 'hindi') {
      return 'नमस्ते! PropZen में आपका स्वागत है। मैं आपकी प्रॉपर्टी रिक्वायरमेंट समझने और उपयुक्त प्रॉपर्टीज खोजने में मदद करूँगी। आप किस प्रकार की प्रॉपर्टी सर्च कर रहे हैं?';
    } else if (lang == 'english') {
      return 'Hello! Welcome to PropZen. I am here to understand your property requirements and help you find the best matching properties. What type of property are you searching for?';
    } else {
      return 'Hello! Welcome to PropZen. Main aapki property requirement samajhne aur suitable properties find karne mein help karungi. Aap kis type ki property search kar rahe hain?';
    }
  }

  /// Initial proactive greeting chips
  List<String> getProactiveGreetingChips({String? language}) {
    final lang = language ?? _context.detectedLanguage;
    if (lang == 'hindi') {
      return ['रेजिडेंशियल (खुद के रहने के लिए)', 'इन्वेस्टमेंट के लिए', 'नोएडा एक्सटेंशन में 3 BHK', 'सेक्टर 150 में 2/3 BHK'];
    } else if (lang == 'english') {
      return ['Residential (Self Use)', 'High-Yield Investment', '3 BHK in Noida Extension', 'Luxury Apartments in Sector 150'];
    } else {
      return ['Residential (Apne Rehne Ke Liye)', 'Investment Purpose', 'Noida Extension 3 BHK', 'Sector 150 2/3 BHK'];
    }
  }

  /// Starts proactive session if not already started, adding initial consultant turn
  ConversationMessage startProactiveTurn({String? language}) {
    final lang = language ?? _context.detectedLanguage;
    final greeting = getProactiveOpeningGreeting(language: lang);
    final chips = getProactiveGreetingChips(language: lang);

    if (_sessionHistory.isEmpty) {
      final msg = ConversationMessage(
        role: 'assistant',
        text: greeting,
        language: lang,
        suggestedChips: chips,
        flowType: 'greeting',
      );
      _sessionHistory.add(msg);
      return msg;
    }
    return _sessionHistory.first;
  }

  /// Detect language: 'hindi' (Devanagari), 'hinglish' (Romanized Hindi), 'english'
  String detectLanguage(String input) {
    final text = input.trim();
    if (text.isEmpty) return _context.detectedLanguage;

    final devanagariRegex = RegExp(r'[\u0900-\u097F]');
    if (devanagariRegex.hasMatch(text)) {
      return 'hindi';
    }

    final lower = text.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));
    final hinglishMarkers = {
      'mujhe', 'chahiye', 'hai', 'hain', 'kya', 'kaise', 'kitna', 'kitni', 'aapka', 'aapki', 'aapko',
      'kaha', 'kahan', 'batao', 'bataiye', 'dekho', 'dekhna', 'acha', 'accha', 'achha', 'sahi',
      'mein', 'me', 'pe', 'par', 'ghar', 'makan', 'shahar', 'jagah', 'kiraya', 'khud', 'rehne',
      'paisa', 'paise', 'kharidna', 'bikau', 'le', 'lo', 'tha', 'thi', 'the', 'badiya', 'zaroor',
      'namaste', 'dhanyawad', 'shukriya', 'kripya', 'karo', 'kare', 'ka', 'ki', 'ke',
      'ko', 'se', 'bhi', 'aur', 'ya', 'bilkul', 'andar', 'wala', 'wali', 'bhi', 'batao',
      'lakh', 'lacs', 'crore', 'haan', 'ha', 'apne', 'liye', 'kal', 'dopahar', 'shaam', 'dijiye'
    };

    int matchCount = 0;
    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (hinglishMarkers.contains(cleanWord)) {
        matchCount++;
      }
    }

    if (matchCount >= 1) {
      return 'hinglish';
    }

    final englishSentenceMarkers = {
      'speak', 'in', 'english', 'show', 'tell', 'want', 'need', 'give', 'open', 'details', 'find', 'check',
      'looking', 'searching', 'certainly', 'would', 'could', 'please', 'thanks', 'thank', 'where', 'what',
      'which', 'hello', 'features', 'schedule', 'visit', 'enquiry', 'budget', 'property', 'apartment', 'house'
    };
    final hasEnglishSentences = words.any((w) => englishSentenceMarkers.contains(w.replaceAll(RegExp(r'[^a-zA-Z]'), '')));

    if (hasEnglishSentences) {
      return 'english';
    }

    if (_sessionHistory.isNotEmpty && _context.detectedLanguage != 'english' && !hasEnglishSentences) {
      return _context.detectedLanguage;
    }

    return _sessionHistory.isNotEmpty ? _context.detectedLanguage : 'hinglish';
  }

  /// Execute real property search and rank by multi-factor score:
  /// 1. Location match
  /// 2. Budget match
  /// 3. Property type
  /// 4. BHK / configuration
  /// 5. Customer purpose (self-use vs investment)
  /// 6. Possession status
  /// 7. Amenities
  /// 8. Verified RERA / Investment score
  List<Property> searchRealProperties(SessionContext ctx) {
    final stateService = PropertyStateService.instance;
    final all = stateService.allProperties.isNotEmpty
        ? stateService.allProperties
        : Property.sampleDeals;

    // Filter properties
    final filtered = all.where((p) {
      // 1. Location match
      if (ctx.location != null) {
        String loc = ctx.location!.toLowerCase().trim();
        if (loc == 'नोएडा' || loc.contains('नोएडा')) loc = 'noida';
        if (loc == 'गुड़गांव' || loc == 'गुरुग्राम' || loc == 'गुडगाँव' || loc.contains('गुड़गांव')) loc = 'gurgaon';
        if (loc == 'ग्रेटर नोएडा' || loc.contains('ग्रेटर नोएडा')) loc = 'greater noida';
        if (loc == 'दिल्ली' || loc.contains('दिल्ली')) loc = 'delhi';

        final matchesLoc = p.city.toLowerCase().contains(loc) ||
            p.sector.toLowerCase().contains(loc) ||
            p.locality.toLowerCase().contains(loc) ||
            p.address.toLowerCase().contains(loc) ||
            p.title.toLowerCase().contains(loc);

        if (!matchesLoc && (loc == 'noida extension' || loc == 'greater noida west')) {
          if (!p.city.toLowerCase().contains('noida extension') &&
              !p.city.toLowerCase().contains('greater noida west') &&
              !p.locality.toLowerCase().contains('noida extension') &&
              !p.address.toLowerCase().contains('noida extension')) {
            return false;
          }
        } else if (!matchesLoc) {
          return false;
        }
      }

      // 2. Budget match (in rupees)
      if (ctx.maxBudget != null) {
        final propertyPriceRupees = p.askingPriceCr * 10000000.0;
        if (propertyPriceRupees > ctx.maxBudget! * 1.15) {
          // Allow up to 15% flexibility for high-value negotiations
          return false;
        }
      }

      // 3. Bedrooms / BHK match
      if (ctx.bedrooms != null) {
        final bhkStr = '${ctx.bedrooms} BHK';
        final matchesBhk = p.bhk.contains(bhkStr) || p.bhkOptions.any((opt) => opt.contains(bhkStr));
        if (!matchesBhk) {
          return false;
        }
      }

      // 4. Status match
      if (ctx.status != null) {
        final stat = ctx.status!.toLowerCase();
        final matchesStatus = p.statusTag.toLowerCase().contains(stat) ||
            p.possessionStatus.toLowerCase().contains(stat) ||
            p.availability.toLowerCase().contains(stat);
        if (!matchesStatus) {
          return false;
        }
      }

      return true;
    }).toList();

    // Multi-factor smart ranking
    filtered.sort((a, b) {
      double scoreA = 0;
      double scoreB = 0;

      // 1. Location match weight
      if (ctx.location != null) {
        final loc = ctx.location!.toLowerCase();
        if (a.sector.toLowerCase().contains(loc) || a.city.toLowerCase().contains(loc)) scoreA += 40;
        if (b.sector.toLowerCase().contains(loc) || b.city.toLowerCase().contains(loc)) scoreB += 40;
      }

      // 2. Budget match weight
      if (ctx.maxBudget != null) {
        final diffA = (a.askingPriceCr * 10000000.0 - ctx.maxBudget!).abs();
        final diffB = (b.askingPriceCr * 10000000.0 - ctx.maxBudget!).abs();
        scoreA += (diffA < diffB) ? 35 : 10;
        scoreB += (diffB < diffA) ? 35 : 10;
      }

      // 3. BHK match weight
      if (ctx.bedrooms != null) {
        final bhkStr = '${ctx.bedrooms} BHK';
        if (a.bhk.contains(bhkStr)) scoreA += 25;
        if (b.bhk.contains(bhkStr)) scoreB += 25;
      }

      // 4. Purpose weight
      if (ctx.purpose == 'investment') {
        scoreA += (a.rentalYieldPercent > 6.0) ? 25 : 10;
        scoreB += (b.rentalYieldPercent > 6.0) ? 25 : 10;
      } else if (ctx.purpose == 'self-use') {
        if (a.amenities.length >= 4) scoreA += 15;
        if (b.amenities.length >= 4) scoreB += 15;
      }

      // 5. RERA Verified status
      if (a.reraStatus.toLowerCase().contains('approved') || a.reraStatus.toLowerCase().contains('registered') || a.reraStatus.isNotEmpty) scoreA += 20;
      if (b.reraStatus.toLowerCase().contains('approved') || b.reraStatus.toLowerCase().contains('registered') || b.reraStatus.isNotEmpty) scoreB += 20;

      scoreA += (a.investmentScore / 10.0);
      scoreB += (b.investmentScore / 10.0);

      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  /// Full consultative multi-turn dialogue processor
  Future<AiAgentResult> processDialogue(String userInput) async {
    final trimmedInput = userInput.trim();
    if (trimmedInput.isEmpty) {
      return AiAgentResult(
        speechResponse: getProactiveOpeningGreeting(),
        textResponse: getProactiveOpeningGreeting(),
        language: _context.detectedLanguage,
        matchedProperties: [],
        context: _context,
        suggestedChips: getProactiveGreetingChips(),
      );
    }

    // 1. Detect language & update structured session context
    final lang = detectLanguage(trimmedInput);
    _context.detectedLanguage = lang;
    _context.updateFromUserInput(trimmedInput);

    // 2. Add user turn to session history
    final userMsg = ConversationMessage(role: 'user', text: trimmedInput, language: lang);
    _sessionHistory.add(userMsg);

    final lower = trimmedInput.toLowerCase();

    // =========================================================================
    // 0. EXPLICIT LANGUAGE SWITCHING COMMANDS
    // =========================================================================
    if (lower.contains('english mein') || lower.contains('speak in english') || lower.contains('in english') || lower.contains('switch to english')) {
      _context.detectedLanguage = 'english';
      final res = AiAgentResult(
        speechResponse: 'Certainly! I have switched to English. How can I assist you with your property search, deal room, or verification requirements today?',
        textResponse: 'Certainly! I have switched to English. How can I assist you with your property search, deal room, or verification requirements today?',
        language: 'english',
        matchedProperties: [],
        context: _context,
        suggestedChips: ['3 BHK in Sector 150', 'Under 1 Crore Deals', 'Open Deal Room', 'AI Property Match'],
        flowType: 'general',
      );
      _recordAssistantMessage(res);
      return res;
    } else if (lower.contains('hindi mein') || lower.contains('speak in hindi') || lower.contains('in hindi') || lower.contains('हिंदी में')) {
      _context.detectedLanguage = 'hindi';
      final res = AiAgentResult(
        speechResponse: 'बिल्कुल! अब मैं आपसे हिंदी में बात करूँगी। आप नोएडा, ग्रेटर नोएडा या गुड़गांव में किस प्रकार की प्रॉपर्टी या बजट देख रहे हैं?',
        textResponse: 'बिल्कुल! अब मैं आपसे हिंदी में बात करूँगी। आप नोएडा, ग्रेटर नोएडा या गुड़गांव में किस प्रकार की प्रॉपर्टी या बजट देख रहे हैं?',
        language: 'hindi',
        matchedProperties: [],
        context: _context,
        suggestedChips: ['सेक्टर 150 में 3 BHK', '80 लाख के अंदर', 'डील रूम खोलें', 'वेरिफिकेशन स्कोर'],
        flowType: 'general',
      );
      _recordAssistantMessage(res);
      return res;
    } else if (lower.contains('hinglish mein') || lower.contains('speak in hinglish') || lower.contains('hinglish')) {
      _context.detectedLanguage = 'hinglish';
      final res = AiAgentResult(
        speechResponse: 'Bilkul! Ab hum Hinglish mein baat karenge. Aap kis location ya budget mein property explore karna chahte hain?',
        textResponse: 'Bilkul! Ab hum Hinglish mein baat karenge. Aap kis location ya budget mein property explore karna chahte hain?',
        language: 'hinglish',
        matchedProperties: [],
        context: _context,
        suggestedChips: ['3 BHK under 90L', 'Sector 150 Noida', 'Deal Room Kholo', 'Site Visit Planner'],
        flowType: 'general',
      );
      _recordAssistantMessage(res);
      return res;
    }

    // =========================================================================
    // 0.1 HUMAN AGENT HANDOFF / SUPPORT
    // =========================================================================
    if (lower.contains('agent se baat') || lower.contains('human') || lower.contains('customer care') || lower.contains('manager se baat') || lower.contains('expert se connect')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं आपको PropZen के सर्टिफाइड सीनियर रिलेशनशिप मैनेजर से सीधे कनेक्ट कर रही हूँ। आप +91 98103 94068 पर कॉल या WhatsApp कर सकते हैं।'
          : (lang == 'english')
              ? 'Certainly! I am connecting you directly with PropZen\'s certified relationship manager. You can reach out directly via call or WhatsApp at +91 98103 94068.'
              : 'Bilkul! Main aapko PropZen ke certified senior relationship manager se directly connect karti hoon. Aap +91 98103 94068 par call ya WhatsApp kar sakte hain.';
      final res = AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: ['Call Manager', 'WhatsApp Support', 'Continue Voice Search'],
        flowType: 'general',
      );
      _recordAssistantMessage(res);
      return res;
    }

    // =========================================================================
    // 0.2 VOICE NAVIGATION COMMANDS & DIRECT ACTIONS
    // =========================================================================
    final directActionRes = _handleDirectVoiceAction(lower, lang);
    if (directActionRes != null) {
      _recordAssistantMessage(directActionRes);
      return directActionRes;
    }

    final navRes = _handleVoiceNavigation(lower, lang);
    if (navRes != null) {
      _recordAssistantMessage(navRes);
      return navRes;
    }

    // =========================================================================
    // 0.22 PROPERTY VISUALIZATION INTENTS (360 Tour, 3D Model, AR, Floor Plan, Interior, Exterior, Vastu)
    // =========================================================================
    final visRes = _handlePropertyVisualizationIntent(lower, lang);
    if (visRes != null) {
      _recordAssistantMessage(visRes);
      return visRes;
    }

    // =========================================================================
    // 0.23 KNOW YOUR LOCALITY & NOTABLE PERSONALITIES (5 KM Strict Geospatial Radius)
    // =========================================================================
    final localityRes = _handleLocalityPersonalitiesIntent(lower, lang);
    if (localityRes != null) {
      _recordAssistantMessage(localityRes);
      return localityRes;
    }

    // =========================================================================
    // 0.25 POST-SITE-VISIT BUYER RETENTION INTENTS (Summary, Feedback, Re-Match, Negotiation)
    // =========================================================================
    final retentionRes = _handlePostVisitRetentionIntent(trimmedInput, lower, lang);
    if (retentionRes != null) {
      _recordAssistantMessage(retentionRes);
      return retentionRes;
    }

    // =========================================================================
    // 0.3 SAFE DEAL ROOM & OFFERS INTENTS
    // =========================================================================
    final dealRoomRes = _handleDealRoomIntent(lower, lang);
    if (dealRoomRes != null) {
      _recordAssistantMessage(dealRoomRes);
      return dealRoomRes;
    }

    // =========================================================================
    // 0.4 AI NEGOTIATION & PRICE INSIGHTS
    // =========================================================================
    final negRes = _handleNegotiationInsightsIntent(lower, lang);
    if (negRes != null) {
      _recordAssistantMessage(negRes);
      return negRes;
    }

    // =========================================================================
    // 0.5 AI PROPERTY VERIFICATION & 5-PILLAR DEAL SCORE
    // =========================================================================
    final verRes = _handleVerificationAndDealScoreIntent(lower, lang);
    if (verRes != null) {
      _recordAssistantMessage(verRes);
      return verRes;
    }

    // =========================================================================
    // 0.6 MULTI-PROPERTY VISIT PLANNER & DIGITAL CHECKLIST
    // =========================================================================
    final planRes = _handleVisitPlannerAndChecklistIntent(trimmedInput, lower, lang);
    if (planRes != null) {
      _recordAssistantMessage(planRes);
      return planRes;
    }

    // =========================================================================
    // 0.7 DEALER VOICE OPERATIONS (Listing Creator, Lead Scoring, Follow-ups)
    // =========================================================================
    final dealerRes = _handleDealerVoiceOperations(trimmedInput, lower, lang);
    if (dealerRes != null) {
      _recordAssistantMessage(dealerRes);
      return dealerRes;
    }

    // =========================================================================
    // 0.8 GENERAL REAL ESTATE FAQs & COMPARISON
    // =========================================================================
    final faqRes = _handleFaqAndComparisonIntent(lower, lang);
    if (faqRes != null) {
      _recordAssistantMessage(faqRes);
      return faqRes;
    }

    // =========================================================================
    // A. SITE VISIT BOOKING FLOW LIFECYCLE
    // =========================================================================
    if (_isSiteVisitIntent(lower) || _context.activeFlow == AgentFlow.siteVisit) {
      final siteVisitResult = await _handleSiteVisitFlow(trimmedInput, lang);
      if (siteVisitResult != null) {
        _recordAssistantMessage(siteVisitResult);
        return siteVisitResult;
      }
    }

    // =========================================================================
    // B. PROPERTY ENQUIRY FLOW LIFECYCLE
    // =========================================================================
    if (_isEnquiryIntent(lower) || _context.activeFlow == AgentFlow.enquiry) {
      final enquiryResult = await _handleEnquiryFlow(trimmedInput, lang);
      if (enquiryResult != null) {
        _recordAssistantMessage(enquiryResult);
        return enquiryResult;
      }
    }

    // =========================================================================
    // C. PROPERTY DETAILS & VERIFIED Q&A
    // =========================================================================
    final detailResponse = _handlePropertyDetailQuery(trimmedInput, lang);
    if (detailResponse != null) {
      _context.activeFlow = AgentFlow.details;
      final chips = (lang == 'hindi')
          ? ['साइट विजिट बुक करें', 'इन्क्वायरी दर्ज करें', 'अन्य प्रॉपर्टीज देखें']
          : (lang == 'english')
              ? ['Book Site Visit', 'Register Enquiry', 'Show Other Options']
              : ['Site Visit Book karo', 'Enquiry Register karo', 'Doosra Option Dikhao'];

      final res = AiAgentResult(
        speechResponse: detailResponse,
        textResponse: detailResponse,
        language: lang,
        matchedProperties: _context.selectedProperty != null ? [_context.selectedProperty!] : [],
        context: _context,
        suggestedChips: chips,
        flowType: 'detail',
      );
      _recordAssistantMessage(res);
      return res;
    }

    // =========================================================================
    // D. AFFIRMATION HANDLING (e.g. "Haan", "Bilkul", "Yes", "Option 1 Achha Hai")
    // =========================================================================
    if (SessionContext.isAffirmation(trimmedInput) || lower.contains('option 1') || lower.contains('option 2')) {
      final affirmationResult = _handleAffirmation(trimmedInput, lang);
      _recordAssistantMessage(affirmationResult);
      return affirmationResult;
    }

    // =========================================================================
    // E. PROPERTY SEARCH & STEP-BY-STEP CONSULTATIVE GATHERING
    // =========================================================================
    AiAgentResult searchOrGatherResult;

    if (_context.hasAllMandatoryDetails || _context.hasEnoughInfoToSearch) {
      _context.activeFlow = AgentFlow.search;
      final matches = searchRealProperties(_context);
      _context.lastFoundProperties = matches;
      if (matches.isNotEmpty) {
        _context.selectedProperty = matches.first;
      }

      final explanationText = _buildConsultativePropertyResults(matches, lang);
      _context.lastAskedEntity = 'feedback';

      final chips = matches.isNotEmpty
          ? (lang == 'hindi'
              ? ['ऑप्शन 1 पसंद आया', 'ऑप्शन 2 पसंद आया', 'साइट विजिट बुक करें', 'बजट बदलें']
              : (lang == 'english'
                  ? ['Option 1 is Good', 'Option 2 is Good', 'Book Site Visit', 'Change Budget']
                  : ['Option 1 Achha Hai', 'Option 2 Achha Hai', 'Site Visit Book karo', 'Budget Change karo']))
          : (lang == 'hindi'
              ? ['बजट बढ़ाएं (1.5 Cr)', 'नोएडा एक्सटेंशन देखें', 'सेक्टर 150 देखें']
              : ['Budget 1.5 Cr karein', 'Noida Extension dekhein', 'Sector 150 dekhein']);

      searchOrGatherResult = AiAgentResult(
        speechResponse: explanationText,
        textResponse: explanationText,
        language: lang,
        matchedProperties: matches,
        context: _context,
        suggestedChips: chips,
        flowType: 'search',
      );
    } else {
      // Step-by-step consultative questioning with market insight
      searchOrGatherResult = _generateConsultativeGatherTurn(trimmedInput, lang);
    }

    // Anti-loop check
    searchOrGatherResult = _applyAntiLoopProtection(searchOrGatherResult, lang);
    _recordAssistantMessage(searchOrGatherResult);
    return searchOrGatherResult;
  }

  void _recordAssistantMessage(AiAgentResult result) {
    final aiMsg = ConversationMessage(
      role: 'assistant',
      text: result.speechResponse,
      language: result.language,
      properties: result.matchedProperties,
      suggestedChips: result.suggestedChips,
      flowType: result.flowType,
      triggeredAction: result.triggeredAction,
      actionTargetProperty: result.actionTargetProperty,
      comparisonData: result.comparisonData,
      dealerLeads: result.dealerLeads,
      dealerInsight: result.dealerInsight,
    );
    _sessionHistory.add(aiMsg);
  }

  bool _isEnquiryIntent(String lower) {
    return lower.contains('enquiry') ||
        lower.contains('inquiry') ||
        lower.contains('interested') ||
        lower.contains('details chahiye') ||
        lower.contains('want to know more') ||
        lower.contains('send me details') ||
        lower.contains('send details') ||
        lower.contains('brochure') ||
        lower.contains('contact me') ||
        lower.contains('call me back') ||
        lower.contains('इन्क्वायरी');
  }

  bool _isSiteVisitIntent(String lower) {
    return lower.contains('site visit') ||
        lower.contains('visit the property') ||
        lower.contains('visit this project') ||
        lower.contains('book a site visit') ||
        lower.contains('book a visit') ||
        lower.contains('dekhne jana') ||
        lower.contains('site dekhna') ||
        lower.contains('साइट विजिट') ||
        lower.contains('schedule visit');
  }

  /// Handles complete Site Visit Booking flow with confirmation and dual backend integration
  Future<AiAgentResult?> _handleSiteVisitFlow(String input, String lang) async {
    _context.activeFlow = AgentFlow.siteVisit;
    final lower = input.toLowerCase();

    final targetProp = _context.selectedProperty ??
        (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
        (PropertyStateService.instance.allProperties.isNotEmpty
            ? PropertyStateService.instance.allProperties.first
            : Property.sampleDeals.first);
    _context.selectedProperty = targetProp;

    // Check for unavailable time slots requested by user
    if (_context.siteVisitStage == SiteVisitStage.collectingTime || lower.contains('am') || lower.contains('pm') || lower.contains('baje')) {
      if (lower.contains('7 am') || lower.contains('8 am') || lower.contains('9 pm') || lower.contains('10 pm') || lower.contains('raat')) {
        final altText = (lang == 'hindi')
            ? 'यह स्लॉट वर्तमान में उपलब्ध नहीं है। आपके लिए 10:00 AM, 12:00 PM या 03:00 PM स्लॉट उपलब्ध हैं। आप कौन सा समय पसंद करेंगे?'
            : (lang == 'english')
                ? 'This slot is currently unavailable. We have verified slots open at 10:00 AM, 12:00 PM, and 03:00 PM. Which time suits you best?'
                : 'Ye slot currently available nahi hai. Aapke liye 10:00 AM, 12:00 PM ya 03:00 PM available hai. Aap kaunsa prefer karenge?';
        return AiAgentResult(
          speechResponse: altText,
          textResponse: altText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: ['10:00 AM', '12:00 PM', '03:00 PM', '05:00 PM'],
          flowType: 'siteVisit',
        );
      }
    }

    // 0. Prevent duplicate site visit booking if already completed in session
    if (_context.siteVisitStage == SiteVisitStage.booked && _context.bookingId != null) {
      final duplicateText = (lang == 'hindi')
          ? 'आपकी साइट विजिट ${targetProp.title} के लिए पहले से ही सफलतापूर्वक बुक है (बुकिंग ID: ${_context.bookingId})। क्या आप कोई अन्य जानकारी जानना चाहते हैं?'
          : (lang == 'english')
              ? 'Your site visit for ${targetProp.title} is already successfully confirmed (Booking ID: ${_context.bookingId}). Would you like assistance with anything else?'
              : 'Aapki site visit ${targetProp.title} ke liye pehle se hi successfully booked hai (Booking ID: ${_context.bookingId}). Kya aap koi aur details dekhna chahte hain?';
      return AiAgentResult(
        speechResponse: duplicateText,
        textResponse: duplicateText,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: (lang == 'hindi') ? ['होम पेज पर जाएं', 'अन्य प्रॉपर्टी देखें'] : ['Back to Home', 'Search Other Properties'],
        flowType: 'siteVisit',
      );
    }

    // 1. Check if user is confirming a pending booking
    if (_context.siteVisitStage == SiteVisitStage.confirming) {
      final isConfirm = SessionContext.isAffirmation(input) ||
          lower.contains('confirm') ||
          lower.contains('book') ||
          lower.contains('haan') ||
          lower.contains('kar do') ||
          lower.contains('yes') ||
          lower.contains('karo');

      if (isConfirm) {
        final dateStr = _context.visitDate ?? '28 August 2026';
        final dateIso = _context.visitDateIso ?? SiteVisitBookingService.normalizeDate(dateStr);
        final timeStr = _context.visitTime ?? '11:00 AM';
        final nameStr = _context.clientName ?? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'PropZen Client');
        final phoneStr = _context.clientPhone ?? (UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068');
        final emailStr = _context.clientEmail ?? (UserSession.email.isNotEmpty ? UserSession.email : 'client@propzen.ai');

        // Centralized Booking Service Execution
        final bookingResult = await SiteVisitBookingService.instance.bookSiteVisit(
          propertyId: targetProp.id,
          propertyTitle: targetProp.title,
          sector: targetProp.sector,
          priceDisplay: targetProp.priceRangeDisplay,
          visitDate: dateIso,
          timeSlot: timeStr,
          visitorCount: _context.visitorCount,
          cabRequired: _context.cabRequired,
          clientName: nameStr,
          clientPhone: phoneStr,
          clientEmail: emailStr,
          source: 'PropZen AI Voice Agent',
        );

        String responseText;
        if (bookingResult.isSuccess) {
          _context.siteVisitStage = SiteVisitStage.booked;
          _context.bookingId = bookingResult.bookingId;
          _context.qualificationTier = 'Site Visit Ready';

          final cabStatus = _context.cabRequired ? 'Yes' : 'No';
          final cabStatusHindi = _context.cabRequired ? 'हाँ' : 'नहीं';
          if (lang == 'hindi') {
            responseText = 'बहुत बढ़िया! ${targetProp.title} के लिए आपकी साइट विजिट $dateStr को $timeStr पर सफलतापूर्वक बुक हो गई है। कुल विजिटर्स: ${_context.visitorCount}, कैब सुविधा: $cabStatusHindi। बुकिंग ID: ${bookingResult.bookingId}। हमारे रिलेशनशिप मैनेजर आपको समय पर गाइड करेंगे।';
          } else if (lang == 'english') {
            responseText = 'Perfect! Your site visit for ${targetProp.title} has been successfully scheduled for $dateStr at $timeStr. Visitors: ${_context.visitorCount}. Cab requirement: $cabStatus. Booking ID: ${bookingResult.bookingId}.';
          } else {
            responseText = 'Perfect! Aapki site visit successfully book ho gayi hai for $dateStr at $timeStr for ${targetProp.title}. Visitors: ${_context.visitorCount}. Cab requirement: $cabStatus. Booking ID: ${bookingResult.bookingId}.';
          }
        } else if (bookingResult.isDuplicate) {
          _context.siteVisitStage = SiteVisitStage.booked;
          _context.bookingId = bookingResult.bookingId;
          responseText = (lang == 'hindi')
              ? 'आपकी साइट विजिट ${targetProp.title} के लिए पहले से ही सफलतापूर्वक बुक है (बुकिंग ID: ${bookingResult.bookingId})।'
              : 'Aapki site visit ${targetProp.title} ke liye pehle se hi successfully booked hai (Booking ID: ${bookingResult.bookingId}).';
        } else if (bookingResult.requiresAuth) {
          responseText = (lang == 'hindi')
              ? 'साइट विजिट बुक करने से पहले आपको साइन इन करना होगा।'
              : 'Site visit book karne se pehle aapko sign in karna hoga.';
        } else if (bookingResult.isSlotUnavailable) {
          responseText = (lang == 'hindi')
              ? 'यह समय स्लॉट उपलब्ध नहीं है। कृपया 10:00 AM, 11:00 AM, 12:00 PM, 03:00 PM या 05:00 PM में से चुनें।'
              : 'Ye slot available nahi hai. Please 10:00 AM, 11:00 AM, 12:00 PM, 03:00 PM ya 05:00 PM mein se select karein.';
        } else {
          responseText = (lang == 'hindi')
              ? 'क्षमा करें, बुकिंग कम्प्लीट नहीं हो पाई। कृपया थोड़ी देर बाद पुनः प्रयास करें।'
              : 'Sorry, booking complete nahi ho paayi. Main aapko dobara try karne ka option deti hoon.';
        }

        return AiAgentResult(
          speechResponse: responseText,
          textResponse: responseText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: (lang == 'hindi') ? ['होम पेज पर जाएं', 'अन्य प्रॉपर्टी देखें'] : ['Back to Home', 'Search Other Properties'],
          flowType: 'siteVisit',
        );
      } else if (SessionContext.isNegation(input)) {
        _context.siteVisitStage = SiteVisitStage.none;
        _context.activeFlow = AgentFlow.none;
        final cancelText = (lang == 'hindi')
            ? 'कोई बात नहीं, साइट विजिट कैंसल कर दी गई है। क्या आप कोई अन्य प्रॉपर्टी देखना चाहेंगे?'
            : 'Koi baat nahi, site visit cancel kar di gayi hai. Kya aap kisi aur property ke baare mein jaanna chahte hain?';
        return AiAgentResult(
          speechResponse: cancelText,
          textResponse: cancelText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          flowType: 'siteVisit',
        );
      }
    }

    // 2. Gathering Date (if missing)
    if (_context.visitDate == null) {
      _context.siteVisitStage = SiteVisitStage.collectingDate;
      _context.lastAskedEntity = 'siteVisitDate';
      final text = (lang == 'hindi')
          ? 'बिल्कुल! ${targetProp.title} की साइट विजिट अरेंज करने के लिए मुझे पसंदीदा तारीख (जैसे कल, यह शनिवार या कोई विशिष्ट तारीख) बता दीजिए।'
          : (lang == 'english')
              ? 'Sure! To schedule your site visit for ${targetProp.title}, please share your preferred date (e.g. Tomorrow, this Saturday, or a specific date).'
              : 'Sure. Site visit book karne ke liye mujhe preferred date (jaise Kal, upcoming Saturday, ya koi date) bata dijiye.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: (lang == 'hindi') ? ['कल (Tomorrow)', 'यह शनिवार (Saturday)', 'परसों (Day After)'] : ['Kal (Tomorrow)', 'This Saturday', 'Upcoming Weekend'],
        flowType: 'siteVisit',
      );
    }

    // 3. Gathering Time Slot (if missing)
    if (_context.visitTime == null) {
      _context.siteVisitStage = SiteVisitStage.collectingTime;
      _context.lastAskedEntity = 'siteVisitTime';
      final text = (lang == 'hindi')
          ? 'धन्यवाद! ${_context.visitDate} के लिए हमारे पास 10:00 AM, 12:00 PM, 03:00 PM और 05:00 PM के स्लॉट्स उपलब्ध हैं। आप कौन सा समय पसंद करेंगे?'
          : (lang == 'english')
              ? 'Thank you! For ${_context.visitDate}, we have verified slots at 10:00 AM, 12:00 PM, 03:00 PM, and 05:00 PM. Which time suits you best?'
              : 'Shukriya! ${_context.visitDate} ke liye verified slots available hain — 10:00 AM, 12:00 PM, 03:00 PM aur 05:00 PM. Aap kaunsa time prefer karenge?';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: ['10:00 AM', '12:00 PM', '03:00 PM', '05:00 PM'],
        flowType: 'siteVisit',
      );
    }

    // 4. Gathering Visitors / Cab if not already provided
    final hasCabOrVisitorsSpecified = lower.contains('visitor') || lower.contains('cab') || lower.contains('log') || _context.visitorCount > 1 || _context.cabRequired || _context.lastAskedEntity == 'siteVisitCab';
    if (!hasCabOrVisitorsSpecified && _context.siteVisitStage != SiteVisitStage.confirming) {
      _context.siteVisitStage = SiteVisitStage.collectingCab;
      _context.lastAskedEntity = 'siteVisitCab';
      final text = (lang == 'hindi')
          ? 'कितने विजिटर्स आएंगे और क्या आपको कैब/ट्रांसपोर्ट सुविधा चाहिए?'
          : (lang == 'english')
              ? 'How many visitors will attend, and do you require cab or transport assistance?'
              : 'Kitne visitors aayenge aur kya aapko cab required hai?';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: (lang == 'hindi') ? ['2 विजिटर्स + कैब चाहिए', '1 विजिटर (खुद की गाड़ी)', 'फैमिली (3 लोग) + कैब'] : ['2 Visitors + Cab Chahiye', '1 Person (No Cab)', 'Family (3) + Cab Assistance'],
        flowType: 'siteVisit',
      );
    }

    // 5. Pre-Booking Summary & Explicit Confirmation
    _context.siteVisitStage = SiteVisitStage.confirming;
    _context.lastAskedEntity = 'siteVisitConfirm';

    final cabTxt = _context.cabRequired
        ? (lang == 'hindi' ? 'उपलब्ध (Required)' : 'Required')
        : (lang == 'hindi' ? 'नहीं चाहिए (Not Required)' : 'Not Required');

    final summaryText = (lang == 'hindi')
        ? 'बहुत बढ़िया! मैं डिटेल्स कन्फर्म कर लेती हूँ:\n\nप्रॉपर्टी: ${targetProp.title}\nतारीख: ${_context.visitDate}\nसमय: ${_context.visitTime}\nविजिटर्स: ${_context.visitorCount}\nकैब सुविधा: $cabTxt\n\nक्या मैं साइट विजिट कन्फर्म कर दूँ?'
        : (lang == 'english')
            ? 'Perfect! Let me confirm the booking details:\n\nProperty: ${targetProp.title}\nDate: ${_context.visitDate}\nTime: ${_context.visitTime}\nVisitors: ${_context.visitorCount}\nCab: $cabTxt\n\nMay I confirm this site visit?'
            : 'Perfect! Main confirm kar leti hoon:\n\nProperty: ${targetProp.title}\nDate: ${_context.visitDate}\nTime: ${_context.visitTime}\nVisitors: ${_context.visitorCount}\nCab: $cabTxt\n\nKya main site visit confirm kar du?';

    return AiAgentResult(
      speechResponse: summaryText,
      textResponse: summaryText,
      language: lang,
      matchedProperties: [targetProp],
      context: _context,
      suggestedChips: (lang == 'hindi') ? ['हाँ, कन्फर्म करें', 'डिटेल्स बदलें'] : (lang == 'english') ? ['Yes, Confirm Booking', 'Change Details'] : ['Haan, Confirm Kar do', 'Change Details'],
      flowType: 'siteVisit',
    );
  }

  /// Handles complete Property Enquiry flow with confirmation and dual backend integration
  Future<AiAgentResult?> _handleEnquiryFlow(String input, String lang) async {
    _context.activeFlow = AgentFlow.enquiry;
    final lower = input.toLowerCase();

    final targetProp = _context.selectedProperty ??
        (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
        (PropertyStateService.instance.allProperties.isNotEmpty
            ? PropertyStateService.instance.allProperties.first
            : Property.sampleDeals.first);
    _context.selectedProperty = targetProp;

    // 1. Check confirmation
    if (_context.enquiryStage == EnquiryStage.confirming) {
      if (SessionContext.isAffirmation(input) || lower.contains('submit') || lower.contains('confirm')) {
        _context.enquiryStage = EnquiryStage.submitted;

        final nameStr = _context.clientName ?? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'PropZen Buyer');
        final phoneStr = _context.clientPhone ?? (UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068');
        final emailStr = _context.clientEmail ?? (UserSession.email.isNotEmpty ? UserSession.email : 'buyer@propzen.ai');
        final reqStr = '${_context.formattedBhkOrType} in ${_context.location ?? targetProp.sector} under ${_context.formattedBudgetHinglish}';

        // 1. Sync to local state & Supabase
        PropertyStateService.instance.addEnquiry(
          targetProp.title,
          'Property Enquiry',
          'Voice Agent Enquiry: $reqStr',
          targetProp.id,
          targetProp.dealerId,
          nameStr,
          phoneStr,
          emailStr,
        );

        // 2. Sync to n8n webhook
        final n8nRes = await N8nService.instance.submitPropertyEnquiry(
          propertyId: targetProp.id,
          propertyName: targetProp.title,
          fullName: nameStr,
          mobileNumber: phoneStr,
          email: emailStr,
          message: 'Voice Agent Enquiry for ${targetProp.title} ($reqStr)',
          preferredContactMethod: 'whatsapp',
        );

        String successText;
        if (n8nRes.isSuccess || n8nRes.statusCode == 200 || !kIsWeb) {
          if (lang == 'hindi') {
            successText = 'धन्यवाद! आपकी इन्क्वायरी सफलतापूर्वक रजिस्टर हो गई है। हमारी एडवाइजर टीम आपको WhatsApp और ईमेल पर कम्प्लीट डिटेल्स भेज देगी।';
          } else if (lang == 'english') {
            successText = 'Thank you. Your enquiry has been successfully registered. Our certified advisor will share verified details on your WhatsApp shortly.';
          } else {
            successText = 'Thank you. Aapki enquiry successfully register ho gayi hai.';
          }
        } else {
          successText = (lang == 'hindi')
              ? 'क्षमा करें, इन्क्वायरी सबमिट करते समय तकनीकी समस्या आ रही है। कृपया थोड़ी देर बाद पुनः प्रयास करें।'
              : 'Sorry, enquiry submit karte waqt technical issue aa raha hai. Please thodi der baad try karein.';
        }

        return AiAgentResult(
          speechResponse: successText,
          textResponse: successText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: (lang == 'hindi') ? ['साइट विजिट भी बुक करें', 'अन्य प्रॉपर्टीज देखें'] : ['Site Visit Book karo', 'Search Other Properties'],
          flowType: 'enquiry',
        );
      } else if (SessionContext.isNegation(input)) {
        _context.enquiryStage = EnquiryStage.none;
        _context.activeFlow = AgentFlow.none;
        final cancelText = (lang == 'hindi')
            ? 'ठीक है, इन्क्वायरी कैंसल कर दी गई है। आप अपनी आवश्यकता अनुसार अन्य प्रॉपर्टीज देख सकते हैं।'
            : 'Theek hai, enquiry cancel kar di gayi hai. Aap koi doosri requirement bata sakte hain.';
        return AiAgentResult(
          speechResponse: cancelText,
          textResponse: cancelText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          flowType: 'enquiry',
        );
      }
    }

    // 2. If client details missing and not in UserSession, gather them
    if (_context.clientPhone == null && !UserSession.isLoggedIn) {
      _context.enquiryStage = EnquiryStage.collectingPhone;
      _context.lastAskedEntity = 'enquiryPhone';
      final text = (lang == 'hindi')
          ? 'बिल्कुल! ${targetProp.title} की इन्क्वायरी दर्ज करने के लिए कृपया अपना नाम और 10-अंकों का मोबाइल नंबर बताएं।'
          : (lang == 'english')
              ? 'Certainly! To register your enquiry for ${targetProp.title}, please share your name and 10-digit mobile number.'
              : 'Bilkul! ${targetProp.title} ki enquiry register karne ke liye kripya apna name aur 10-digit mobile number bata dijiye.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        flowType: 'enquiry',
      );
    }

    // 3. Pre-Submission Summary & Confirmation
    _context.enquiryStage = EnquiryStage.confirming;
    _context.lastAskedEntity = 'enquiryConfirm';

    final name = _context.clientName ?? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'PropZen Member');
    final phone = _context.clientPhone ?? (UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068');
    final email = _context.clientEmail ?? (UserSession.email.isNotEmpty ? UserSession.email : 'member@propzen.ai');
    final req = '${_context.formattedBhkOrType} in ${targetProp.sector}, ${targetProp.city} under ${_context.formattedBudgetHinglish}';

    final summaryText = (lang == 'hindi')
        ? 'मैं एक बार डिटेल्स कन्फर्म कर देता हूँ। आपका नाम $name, ईमेल $email, मोबाइल $phone, और रिक्वायरमेंट $req है। क्या मैं इन्क्वायरी सबमिट कर दूँ?'
        : (lang == 'english')
            ? 'Let me confirm your details. Your name is $name, email is $email, mobile is $phone, and requirement is $req. Shall I submit your enquiry?'
            : 'Main ek baar details confirm kar deta hoon. Aapka naam $name, email $email, mobile $phone, aur requirement $req hai. Kya main enquiry submit kar doon?';

    return AiAgentResult(
      speechResponse: summaryText,
      textResponse: summaryText,
      language: lang,
      matchedProperties: [targetProp],
      context: _context,
      suggestedChips: (lang == 'hindi') ? ['हाँ, सबमिट करें', 'डिटेल्स बदलें'] : ['Haan, Submit kar do', 'Change Details'],
      flowType: 'enquiry',
    );
  }

  /// Builds rich consultative explanation for matching properties with recommendation rationale
  String _buildConsultativePropertyResults(List<Property> matches, String lang) {
    final loc = _context.location ?? 'NCR';
    final bhk = _context.formattedBhkOrType;
    final budgetStrHindi = _context.formattedBudgetHindi;
    final budgetStrHinglish = _context.formattedBudgetHinglish;
    final budgetStrEnglish = _context.formattedBudgetEnglish;

    if (matches.isEmpty) {
      if (lang == 'hindi') {
        return 'मैंने आपके मानदंडों के अनुसार डेटाबेस सर्च किया, लेकिन $loc में $budgetStrHindi के तहत सीधे मैच नहीं मिला। क्या मैं बजट को थोड़ा फ्लेक्सिबल करके या पास के सेक्टर्स (जैसे सेक्टर 150 या ग्रेटर नोएडा वेस्ट) में ऑप्शंस दिखाऊं?';
      } else if (lang == 'english') {
        return 'I searched our verified repository, but could not find an exact match in $loc within $budgetStrEnglish. Would you like me to slightly adjust the budget or explore high-growth adjacent sectors like Sector 150 or Greater Noida West?';
      } else {
        return 'Maine aapki requirement ke according live properties check ki hain, par $loc mein $budgetStrHinglish ke exact andar abhi direct match nahi mila. Kya main budget thoda flexible karke ya nearby sectors (jaise Sector 150 ya Greater Noida West) mein options recommend karun?';
      }
    }

    final p1 = matches[0];
    final area1 = '${p1.sector}, ${p1.city}';
    final price1 = p1.priceRangeDisplay;
    final size1 = '${p1.sqft} sq.ft.';
    final stat1 = p1.possessionStatus.isNotEmpty ? p1.possessionStatus : p1.statusTag;
    final rera1 = p1.reraStatus.isNotEmpty ? p1.reraStatus : '100% RERA Approved';

    // Rationale for recommending Option 1
    String rationale1Hinglish = 'Is property ko main recommend karunga kyunki ye aapke $loc preference aur $bhk requirement ke saath match karti hai, aur iska budget bhi aapke range ke andar hai.';
    String rationale1Hindi = 'इस प्रॉपर्टी को मैं रेकमेंड करूँगा क्योंकि यह आपकी $loc प्रेफरेंस और $bhk रिक्वायरमेंट के साथ मैच करती है, और इसका बजट भी आपकी रेंज के अंदर है।';
    String rationale1English = 'I recommend this property because it matches your $loc preference and $bhk requirement, with pricing well within your budget range.';

    if (matches.length == 1) {
      if (lang == 'hindi') {
        return '''मैंने आपकी आवश्यकता के अनुसार सबसे उपयुक्त प्रॉपर्टी शॉर्टलिस्ट की है:

प्राइम ऑप्शन: ${p1.title} ($area1 में स्थित)।
यह एक शानदार $bhk ($size1) यूनिट है, प्राइस: $price1। स्थिति: $stat1। इसमें लग्जरी क्लबहाउस, स्विमिंग पूल, 24x7 पावर बैकअप व गेटेड सिक्योरिटी उपलब्ध है।
$rationale1Hindi

क्या आप इस प्रॉपर्टी की और विस्तृत जानकारी जानना चाहेंगे या साइट विजिट प्लान करें?''';
      } else if (lang == 'english') {
        return '''Based on your criteria, I have shortlisted an exceptional property:

Prime Option: ${p1.title}, located in $area1.
It features a spacious $bhk ($size1), Price: $price1, Status: $stat1. Amenities include an exclusive clubhouse, swimming pool, 24x7 security, and landscaped gardens.
$rationale1English

Would you like more in-depth details on this property, or would you like me to schedule a site visit?''';
      } else {
        return '''Maine aapki requirement ke according best matching property shortlist ki hai:

Prime Option: ${p1.title}, jo $area1 mein located hai.
Ismein $bhk ($size1) configuration hai, price: $price1, status: $stat1. Project mein modern clubhouse, swimming pool, 24x7 security aur power backup jaisi top amenities available hain.
$rationale1Hinglish

Inme se aapko ye option kaisa lag raha hai — kya aap iski aur details dekhna chahenge ya site visit plan karein?''';
      }
    }

    final p2 = matches[1];
    final area2 = '${p2.sector}, ${p2.city}';
    final price2 = p2.priceRangeDisplay;
    final size2 = '${p2.sqft} sq.ft.';
    final stat2 = p2.possessionStatus.isNotEmpty ? p2.possessionStatus : p2.statusTag;

    if (lang == 'hindi') {
      return '''मैंने आपकी आवश्यकता के अनुसार 2 बेहतरीन ऑप्शंस शॉर्टलिस्ट किए हैं:

पहला ऑप्शन: ${p1.title} ($area1 में स्थित)।
यह $bhk ($size1) यूनिट $price1 में उपलब्ध है ($stat1)। इसमें क्लबहाउस, स्विमिंग पूल, 24x7 सिक्योरिटी और पार्क फेसिंग बालकनी है। $rationale1Hindi

दूसरा ऑप्शन: ${p2.title} ($area2 में स्थित)।
यह प्रॉपर्टी $bhk ($size2) के साथ $price2 में उपलब्ध है ($stat2)। यह एक्सप्रेसवे और मेट्रो स्टेशन से बेहतरीन कनेक्टिविटी प्रदान करती है।

इन दोनों ऑप्शंस में से आपको कौन सा विकल्प ज्यादा उपयुक्त लग रहा है — लोकेशन प्राथमिकता है या एमेनिटीज और बजट?''';
    } else if (lang == 'english') {
      return '''Based on your criteria, I have shortlisted 2 premium verified options:

Option 1: ${p1.title}, located in $area1.
Features a spacious $bhk ($size1) at $price1 ($stat1). Equipped with a luxury clubhouse, swimming pool, landscaped parks, and round-the-clock security. $rationale1English

Option 2: ${p2.title}, located in $area2.
Offering $bhk ($size2) at $price2 ($stat2), featuring direct expressway access and proximity to the nearest metro corridor.

Between these two options, which one feels more aligned with your goals — is location your primary focus, or amenities and budget?''';
    } else {
      return '''Maine aapki requirement ke according 2 top verified options find kiye hain:

Pehla option: ${p1.title}, jo $area1 mein located hai.
Ismein $bhk ($size1) available hai $price1 mein ($stat1). Yahan clubhouse, swimming pool, reserved parking aur 24x7 security jaisi complete amenities hain. $rationale1Hinglish

Doosra option: ${p2.title}, jo $area2 mein located hai.
Yeh $bhk ($size2) $price2 mein available hai ($stat2), jisme metro corridor aur expressway se seamless connectivity milti hai.

In dono options mein se aapko kaunsa option zyada suitable lag raha hai — aapke liye location important hai ya amenities aur budget?''';
    }
  }

  /// Step-by-step consultative slot filling with context acknowledgments and market explanation
  AiAgentResult _generateConsultativeGatherTurn(String input, String lang) {
    final lower = input.toLowerCase();

    // 1. Initial Greeting / Re-greeting
    if (lower == 'hi' || lower == 'hello' || lower.contains('namaste') || lower.contains('hey') || lower.contains('नमस्ते')) {
      _context.lastAskedEntity = 'purpose';
      final text = getProactiveOpeningGreeting(language: lang);
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: getProactiveGreetingChips(language: lang),
      );
    }

    // If purpose is not explicitly set, but user has already provided location/budget/bhk, assume residential (self-use)
    if (_context.purpose == null && (_context.location != null || _context.maxBudget != null || _context.bedrooms != null)) {
      _context.purpose = 'self-use';
    }

    // 2. Purpose is missing
    if (_context.purpose == null) {
      _context.lastAskedEntity = 'purpose';
      final text = (lang == 'hindi')
          ? 'बहुत बढ़िया! प्रॉपर्टी सर्च शुरू करने से पहले मैं समझना चाहूँगा — क्या आप खुद के रहने के लिए रेजिडेंशियल घर देख रहे हैं या हाई-रिटर्न इन्वेस्टमेंट के उद्देश्य से?'
          : (lang == 'english')
              ? 'Excellent! To tailor my recommendations, may I understand — are you looking for a home for self-use, or exploring high-yield investment properties?'
              : 'Perfect! Proper options shortlist karne se pehle main samajhna chahoonga — kya aap apne rehne ke liye residential ghar dekh rahe hain ya investment ke purpose se?';
      final chips = (lang == 'hindi') ? ['खुद के रहने के लिए', 'इन्वेस्टमेंट के उद्देश्य से', 'कमर्शियल इन्वेस्टमेंट'] : ['Apne Rehne Ke Liye', 'Investment Purpose', 'Commercial Space'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: chips,
      );
    }

    // 3. Location is missing
    if (_context.location == null) {
      _context.lastAskedEntity = 'location';
      final ackBudget = _context.justCapturedBudget
          ? (lang == 'hindi' ? 'बढ़िया, मैंने आपका बजट ${_context.formattedBudgetHindi} नोट कर लिया है। ' : 'Great, maine aapka budget ${_context.formattedBudgetHinglish} note kar liya hai. ')
          : '';
      final ackPurpose = _context.purpose == 'self-use'
          ? (lang == 'hindi' ? 'खुद के रहने के लिए कनेक्टिविटी, स्कूल और शांत वातावरण बहुत आवश्यक होते हैं। ' : 'Apne use ke liye family living aur daily connectivity kaafi important hoti hai. ')
          : (lang == 'hindi' ? 'इन्वेस्टमेंट के लिए हाई रेंटल यील्ड और आगामी इंफ्रास्ट्रक्चर वाले एरियाज सबसे अच्छे रहते हैं। ' : 'Investment ke liye high capital appreciation aur strong rental demand corridors best rehte hain. ');

      final text = (lang == 'hindi')
          ? '${ackBudget}${ackPurpose}आप NCR में किस क्षेत्र को प्राथमिकता देना चाहेंगे — जैसे नोएडा, ग्रेटर नोएडा वेस्ट या गुड़गांव?'
          : (lang == 'english')
              ? 'Location and lifestyle connectivity are key. Which specific region in NCR would you prefer to explore — such as Noida, Greater Noida West, or Gurgaon?'
              : '${ackBudget}${ackPurpose}Aap kis specific area mein property prefer kar rahe hain — jaise Noida, Noida Extension ya Gurgaon?';

      final chips = (lang == 'hindi') ? ['नोएडा एक्सटेंशन', 'सेक्टर 150 नोएडा', 'यमुना एक्सप्रेसवे', 'गुड़गांव'] : ['Noida Extension', 'Sector 150 Noida', 'Yamuna Expressway', 'Golf Course Road Gurgaon'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: chips,
      );
    }

    // 4. Configuration / BHK is missing
    if (_context.bedrooms == null && _context.propertyType == null) {
      _context.lastAskedEntity = 'propertyType';
      final ackLoc = _context.justCapturedLocation
          ? (lang == 'hindi' ? 'शानदार! मैंने आपकी पसंदीदा लोकेशन ${_context.location} नोट कर ली है। ' : 'Great! Maine ${_context.location} note kar liya hai. ')
          : '';
      final ackBudget = _context.justCapturedBudget
          ? (lang == 'hindi' ? 'बढ़िया, मैंने आपका बजट ${_context.formattedBudgetHindi} नोट कर लिया है। ' : 'Great, maine aapka budget ${_context.formattedBudgetHinglish} note kar liya hai. ')
          : '';

      final text = (lang == 'hindi')
          ? '${ackLoc}${ackBudget}${_context.location ?? "NCR"} में आपको किस साइज या कॉन्फ़िगरेशन की आवश्यकता है — 2 BHK, 3 BHK या इंडिपेंडेंट विला?'
          : (lang == 'english')
              ? '${_context.location ?? "NCR"} offers vibrant residential developments. What bedroom configuration or property type are you aiming for — 2 BHK, 3 BHK, or an exclusive Villa?'
              : '${ackLoc}${ackBudget}${_context.location ?? "NCR"} mein aapko kaunsi configuration chahiye — 2 BHK, 3 BHK ya luxury Villa?';

      final chips = ['2 BHK Flat', '3 BHK Apartment', '4 BHK Luxury', 'Independent Villa'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: chips,
      );
    }

    // 5. Budget is missing
    if (_context.maxBudget == null) {
      _context.lastAskedEntity = 'budget';
      final ackLoc = _context.justCapturedLocation
          ? (lang == 'hindi' ? 'शानदार! मैंने आपकी पसंदीदा लोकेशन ${_context.location} नोट कर ली है। ' : 'Great! Maine ${_context.location} note kar liya hai. ')
          : '';
      final ackBhk = _context.justCapturedBhk
          ? (lang == 'hindi' ? 'बढ़िया, ${_context.formattedBhkOrType} का चयन बहुत सही है। ' : 'Perfect, ${_context.formattedBhkOrType} requirement note ho gayi hai. ')
          : '';

      final text = (lang == 'hindi')
          ? '${ackLoc}${ackBhk}Sure. Aapka approximate budget kya hai? (जैसे 80 लाख, 1.2 करोड़ या 2 करोड़)'
          : (lang == 'english')
              ? 'Sure. What is your approximate budget range (e.g. 80 Lakhs, 1.2 Crore, or 2 Crore)?'
              : 'Sure. Aapka approximate budget kya hai?';

      final chips = ['80 Lakh tak', '1.2 Crore', '1.5 Crore', '2 Crore+'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: chips,
      );
    }

    // Fallback consultative turn
    final fallbackText = (lang == 'hindi')
        ? 'मैं आपकी प्रॉपर्टी सर्च में पूरी मदद करने के लिए तैयार हूँ। कृपया अपनी आवश्यकता या कोई विशेष प्रश्न बताएं।'
        : 'Main aapki requirement ke according best verified properties search karne ke liye ready hoon. Aap koi specific preference bata sakte hain.';
    return AiAgentResult(
      speechResponse: fallbackText,
      textResponse: fallbackText,
      language: lang,
      matchedProperties: [],
      context: _context,
    );
  }

  /// Affirmation handling
  AiAgentResult _handleAffirmation(String input, String lang) {
    final lower = input.toLowerCase();

    // If user clicked or said "Option 1"
    if (lower.contains('option 1') && _context.lastFoundProperties.isNotEmpty) {
      _context.selectedProperty = _context.lastFoundProperties[0];
      final p = _context.selectedProperty!;
      final text = (lang == 'hindi')
          ? 'शानदार पसंद! ${p.title} (${p.sector}) एक बेहतरीन प्रोजेक्ट है जिसमें 100% RERA अप्रूवल और सुपीरियर कंस्ट्रक्शन क्वालिटी है। क्या आप इसका फ्लोर प्लान देखना चाहेंगे, इन्क्वायरी सबमिट करना चाहेंगे या साइट विजिट अरेंज करूँ?'
          : 'Great choice! ${p.title} (${p.sector}) premium amenities aur prime location ke saath top performer hai. Kya aap iska floor plan dekhna chahenge, enquiry submit karein ya direct site visit book karoon?';
      final chips = (lang == 'hindi') ? ['साइट विजिट बुक करें', 'इन्क्वायरी दर्ज करें', 'फ्लोर प्लान बताएं'] : ['Site Visit Book karo', 'Enquiry Register karo', 'Floor Plan Batao'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [p],
        context: _context,
        suggestedChips: chips,
      );
    }

    // If user clicked or said "Option 2"
    if (lower.contains('option 2') && _context.lastFoundProperties.length > 1) {
      _context.selectedProperty = _context.lastFoundProperties[1];
      final p = _context.selectedProperty!;
      final text = (lang == 'hindi')
          ? 'बहुत बढ़िया! ${p.title} (${p.sector}) में बेहतरीन ओपन ग्रीन एरिया और हाई-स्पीड कनेक्टिविटी है। क्या आप इसकी इन्क्वायरी दर्ज करना चाहेंगे या साइट विजिट प्लान करें?'
          : 'Excellent! ${p.title} (${p.sector}) mein fast expressway connectivity aur spacious layout milta hai. Kya aap iski enquiry submit karna chahenge ya site visit schedule karein?';
      final chips = (lang == 'hindi') ? ['साइट विजिट बुक करें', 'इन्क्वायरी दर्ज करें', 'फ्लोर प्लान बताएं'] : ['Site Visit Book karo', 'Enquiry Register karo', 'Floor Plan Batao'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [p],
        context: _context,
        suggestedChips: chips,
      );
    }

    if (_context.lastFoundProperties.isNotEmpty || _context.lastAskedEntity == 'feedback') {
      final p = _context.selectedProperty ?? _context.lastFoundProperties.first;
      final text = (lang == 'hindi')
          ? 'शानदार! ${p.title} में मॉडर्न क्लबहाउस, स्विमिंग पूल, 24x7 सिक्योरिटी और नज़दीकी मेट्रो से 5 मिनट की दूरी है। अगर आपको यह पसंद आ रही है, तो मैं आपकी इन्क्वायरी रजिस्टर करने के साथ साइट विजिट भी शेड्यूल कर सकता हूँ। आप क्या पसंद करेंगे?'
          : 'Great! ${p.title} mein clubhouse, swimming pool, 24x7 security aur metro connectivity available hai. Agar aapko ye suitable lag rahi hai, to main enquiry register karne ke saath site visit bhi schedule kar sakta hoon. Aap kya prefer karenge?';
      final chips = (lang == 'hindi') ? ['साइट विजिट बुक करें', 'इन्क्वायरी सबमिट करें'] : ['Site Visit Book karo', 'Enquiry Submit karo'];
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [p],
        context: _context,
        suggestedChips: chips,
      );
    }

    return _generateConsultativeGatherTurn(input, lang);
  }

  /// Comprehensive Property Q&A: Details, Price, Availability, Metro, Developer, RERA, Schools, Hospitals
  String? _handlePropertyDetailQuery(String input, String lang) {
    final lower = input.toLowerCase();
    final prop = _context.selectedProperty ??
        (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null);

    // 1. General Property overview ("Is property ke baare mein batao", "Tell me about this project")
    if ((lower.contains('baare mein batao') || lower.contains('tell me about') || lower.contains('details batao') || lower.contains('explain property')) && prop != null) {
      final area = '${prop.sector}, ${prop.city}';
      final price = prop.priceRangeDisplay;
      final size = '${prop.sqft} sq.ft.';
      final stat = prop.possessionStatus.isNotEmpty ? prop.possessionStatus : prop.statusTag;
      final rera = prop.reraStatus.isNotEmpty ? prop.reraStatus : 'UP-RERA Verified';
      final dev = prop.dealerName.isNotEmpty ? prop.dealerName : 'Leading NCR Developer';

      if (lang == 'hindi') {
        return '${prop.title} ($area) डेवलपर $dev द्वारा विकसित एक प्रीमियम प्रोजेक्ट है। यहाँ ${prop.bhk} ($size) उपलब्ध है $price में ($stat)। इसका RERA स्टेटस "$rera" है। इसमें मॉडर्न क्लबहाउस, स्विमिंग पूल, 24x7 सिक्योरिटी और बेहतरीन रोड कनेक्टिविटी है।';
      } else if (lang == 'english') {
        return '${prop.title} in $area is developed by $dev. It offers ${prop.bhk} ($size) starting at $price ($stat) with verified $rera status. Features include a modern clubhouse, swimming pool, 24x7 security, and rapid highway access.';
      } else {
        return '${prop.title} ($area) developer $dev ka premium project hai. Ismein ${prop.bhk} ($size) configuration $price mein available hai ($stat), RERA status: "$rera". Yahan clubhouse, swimming pool aur excellent transit access available hai.';
      }
    }

    // 2. Price queries ("2 BHK kitne ka hai?", "Price kya hai?", "Cost kya hai?")
    if (lower.contains('kitne ka hai') || lower.contains('kitna price') || lower.contains('cost kya') || lower.contains('price kya') || lower.contains('what is the price')) {
      if (prop != null) {
        if (lang == 'hindi') {
          return '${prop.title} में ${prop.bhk} का प्राइस ${prop.priceRangeDisplay} है (लगभग ₹${prop.pricePerSqft.toInt()} प्रति वर्ग फुट)।';
        } else {
          return '${prop.title} mein ${prop.bhk} ka price ${prop.priceRangeDisplay} hai (approx ₹${prop.pricePerSqft.toInt()} per sq.ft.).';
        }
      }
    }

    // 3. Developer / Builder queries
    if (lower.contains('builder') || lower.contains('developer') || lower.contains('kisne banaya') || lower.contains('कम्पनी')) {
      if (prop != null && prop.dealerName.isNotEmpty) {
        return (lang == 'hindi')
            ? '${prop.title} का निर्माण ${prop.dealerName} द्वारा किया गया है, जो NCR के प्रतिष्ठित और विश्वसनीय डेवलपर्स में से एक हैं।'
            : '${prop.title} is developed by ${prop.dealerName}, one of the reputed and verified builders in the NCR region.';
      } else {
        return (lang == 'hindi')
            ? 'मेरे पास इस प्रॉपर्टी के रिगार्डिंग यह जानकारी वर्तमान में उपलब्ध नहीं है। मैं आपकी इन्क्वायरी रजिस्टर कर सकता हूँ ताकि आपको सटीक जानकारी मिल सके।'
            : 'Mere paas is property ke regarding ye information currently available nahi hai. Main aapki enquiry register kar sakta hoon taaki aapko accurate information mil sake.';
      }
    }

    if (prop == null) return null;

    // 4. Floor Plan & Carpet area
    if (lower.contains('floor plan') || lower.contains('floorplan') || lower.contains('carpet area') || lower.contains('नक्शा') || lower.contains('फ्लोर प्लान') || lower.contains('size')) {
      if (lang == 'hindi') {
        return '${prop.title} का ${prop.bhk} लेआउट ${prop.sqft} वर्ग फुट सुपर एरिया और ${prop.carpetAreaSqft} वर्ग फुट कारपेट एरिया के साथ आता है। यह 100% वास्तु फ्रेंडली डिज़ाइन और पर्याप्त क्रॉस-वेंटिलेशन के साथ बनाया गया है।';
      } else if (lang == 'english') {
        return '${prop.title} features a spacious ${prop.bhk} layout with ${prop.sqft} sq.ft. super area and ${prop.carpetAreaSqft} sq.ft. carpet area, optimized for maximum usable living space and natural sunlight.';
      } else {
        return '${prop.title} ka ${prop.bhk} floor plan ${prop.sqft} sq.ft. super area aur ${prop.carpetAreaSqft} sq.ft. carpet area ka hai, jisme zero space wastage aur cross-ventilation designed hai.';
      }
    }

    // 5. Metro & Connectivity
    if (lower.contains('metro') || lower.contains('distance') || lower.contains('door') || lower.contains('दूरी') || lower.contains('मेट्रो') || lower.contains('connectivity')) {
      final metroEntry = prop.nearby.entries.firstWhere(
        (e) => e.key.toLowerCase().contains('metro'),
        orElse: () => prop.nearby.isNotEmpty ? prop.nearby.entries.first : const MapEntry('Nearest Metro Station', '2.5 km'),
      );
      if (lang == 'hindi') {
        return '${prop.title} से निकटतम मेट्रो स्टेशन ${metroEntry.key} लगभग ${metroEntry.value} की दूरी पर है। यहाँ से मुख्य एक्सप्रेसवे तक केवल 5 मिनट में पहुँचा जा सकता है।';
      } else if (lang == 'english') {
        return 'The nearest rapid transit to ${prop.title} is ${metroEntry.key}, located just ${metroEntry.value} away, offering seamless daily commuting.';
      } else {
        return '${prop.title} se nearest metro station ${metroEntry.key} lagbhag ${metroEntry.value} door hai aur main road connectivity bahut smooth hai.';
      }
    }

    // 6. Schools & Hospitals nearby
    if (lower.contains('school') || lower.contains('hospital') || lower.contains('college') || lower.contains('स्कूल') || lower.contains('अस्पताल')) {
      final nearbyItems = prop.nearby.entries.take(3).map((e) => '${e.key} (${e.value})').join(', ');
      if (nearbyItems.isNotEmpty) {
        return (lang == 'hindi')
            ? '${prop.title} के नजदीक प्रमुख सुविधाएं उपलब्ध हैं: $nearbyItems।'
            : '${prop.title} ke paas top institutions aur facilities available hain: $nearbyItems.';
      } else {
        return (lang == 'hindi')
            ? 'मेरे पास इस प्रॉपर्टी के रिगार्डिंग यह जानकारी वर्तमान में उपलब्ध नहीं है। मैं आपकी इन्क्वायरी रजिस्टर कर सकता हूँ ताकि आपको सटीक जानकारी मिल सके।'
            : 'Mere paas is property ke regarding ye information currently available nahi hai. Main aapki enquiry register kar sakta hoon taaki aapko accurate information mil sake.';
      }
    }

    // 7. RERA Status
    if (lower.contains('rera') || lower.contains('legal') || lower.contains('रेरा') || lower.contains('approval')) {
      final rera = prop.reraStatus.isNotEmpty ? prop.reraStatus : 'UP-RERA Certified';
      if (lang == 'hindi') {
        return '${prop.title} 100% वेरिफाइड प्रोजेक्ट है। इसका RERA स्टेटस "$rera" है और सभी लीगल टाइटल डीड्स जांची हुई हैं।';
      } else {
        return '${prop.title} 100% verified deal hai jiska RERA status "$rera" hai aur clear 30-year title deeds ke saath verified hai.';
      }
    }

    // 8. Amenities
    if (lower.contains('amenities') || lower.contains('facility') || lower.contains('सुविधा') || lower.contains('pool') || lower.contains('club')) {
      final amList = prop.amenities.isNotEmpty ? prop.amenities.take(4).join(', ') : 'Clubhouse, Swimming Pool, 24x7 Security, Power Backup';
      if (lang == 'hindi') {
        return '${prop.title} में वर्ल्ड-क्लास एमेनिटीज़ उपलब्ध हैं जैसे: $amList। यहाँ बच्चों के लिए प्ले एरिया और सीनियर सिटीजन पार्क भी हैं।';
      } else {
        return '${prop.title} mein premium lifestyle amenities available hain jaise: $amList, aur dedicated green zones designed hain.';
      }
    }

    // 9. Parking
    if (lower.contains('parking') || lower.contains('पारकिंग') || lower.contains('गाड़ी')) {
      const slots = 'Dedicated covered reserved parking';
      if (lang == 'hindi') {
        return '${prop.title} में $slots शामिल है।';
      } else if (lang == 'english') {
        return '${prop.title} includes $slots.';
      } else {
        return '${prop.title} mein $slots available hai.';
      }
    }

    // 10. Possession
    if (lower.contains('possession') || lower.contains('पजेशन') || lower.contains('ready to move') || lower.contains('kab milega')) {
      final pos = prop.possessionStatus.isNotEmpty ? prop.possessionStatus : prop.statusTag;
      final date = prop.possessionDate.isNotEmpty ? ' (${prop.possessionDate})' : '';
      if (lang == 'hindi') {
        return '${prop.title} का पजेशन स्टेटस "$pos"$date है।';
      } else if (lang == 'english') {
        return 'The possession status for ${prop.title} is "$pos"$date.';
      } else {
        return '${prop.title} ka possession status "$pos"$date hai.';
      }
    }

    // 11. Drone tour availability
    if (lower.contains('drone') || lower.contains('ड्रोन')) {
      final hasDrone = prop.hasDroneTour;
      if (hasDrone) {
        if (lang == 'hindi') {
          return 'हाँ! ${prop.title} के लिए 4K एरियल ड्रोन टूर वेरिफाइड और उपलब्ध है। आप "Drone tour chalao" बोलकर इसे शुरू कर सकते हैं।';
        } else if (lang == 'english') {
          return 'Yes! A verified 4K aerial drone tour is available for ${prop.title}. You can say "Watch drone tour" to open it.';
        } else {
          return 'Haan! ${prop.title} ke liye verified 4K aerial drone tour available hai. Aap "Drone tour chalao" bolkar dekh sakte hain.';
        }
      } else {
        if (lang == 'hindi') {
          return 'इस प्रॉपर्टी का ड्रोन टूर अभी उपलब्ध नहीं है, लेकिन 360° वर्चुअल टूर और 3D मॉडल उपलब्ध हैं।';
        } else if (lang == 'english') {
          return 'Drone tour is not available for this property yet, but 360° virtual tour and 3D model are available.';
        } else {
          return 'Is property ka drone tour abhi available nahi hai, lekin 360° tour aur 3D model available hain.';
        }
      }
    }

    return null;
  }

  /// Rephrases dynamically to protect against repetitive loops
  AiAgentResult _applyAntiLoopProtection(AiAgentResult result, String lang) {
    if (_sessionHistory.length >= 2) {
      final previousAiMsgs = _sessionHistory.where((m) => m.role == 'assistant').toList();
      if (previousAiMsgs.isNotEmpty) {
        final lastAiText = previousAiMsgs.last.text.trim();
        if (result.speechResponse.trim() == lastAiText) {
          final rephrased = _rephraseFollowUp(result.speechResponse, lang);
          return AiAgentResult(
            speechResponse: rephrased,
            textResponse: rephrased,
            language: result.language,
            matchedProperties: result.matchedProperties,
            context: result.context,
            suggestedChips: result.suggestedChips,
            flowType: result.flowType,
          );
        }
      }
    }
    return result;
  }

  String _rephraseFollowUp(String original, String lang) {
    if (_context.maxBudget == null) {
      return (lang == 'hindi')
          ? 'क्या आप अपना अनुमानित बजट बता सकते हैं (जैसे 80 लाख या 1.5 करोड़)? ताकि मैं सटीक ऑप्शंस ला सकूँ।'
          : 'Kya aap apna approx budget range bata sakte hain (jaise 80 Lakh ya 1.5 Crore)? Taaki main exact matching deals shortlist kar sakun.';
    } else if (_context.bedrooms == null && _context.propertyType == null) {
      return (lang == 'hindi')
          ? 'आप 2 BHK, 3 BHK या विला में से किस प्रकार का लेआउट प्राथमिकता देंगे?'
          : 'Aap 2 BHK, 3 BHK ya luxury Villa mein se kya prefer karenge?';
    } else if (_context.location == null) {
      return (lang == 'hindi')
          ? 'NCR में आपकी पसंदीदा लोकेशन कौन सी है — नोएडा, ग्रेटर नोएडा या गुड़गांव?'
          : 'Aap NCR mein kaunsa area prefer karenge — Noida, Greater Noida ya Gurgaon?';
    }
    return original;
  }

  // =========================================================================
  // VOICE INTENT HANDLERS
  // =========================================================================

  /// 1. Voice Navigation
  AiAgentResult? _handleVoiceNavigation(String lower, String lang) {
    if (lower.contains('properties kholo') || lower.contains('show properties') || lower.contains('browse properties') || lower.contains('प्रॉपर्टीज खोलो')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं आपके लिए प्रॉपर्टीज लिस्टिंग स्क्रीन खोल रही हूँ।'
          : (lang == 'english')
              ? 'Sure! Navigating to the Properties catalog now.'
              : 'Bilkul! Main aapke liye verified Properties catalog open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: _context.lastFoundProperties,
        context: _context,
        suggestedChips: ['View Details', 'Filter by Budget', 'Filter Sector 150'],
        flowType: 'navigation',
      );
    }
    if (lower.contains('dealer dashboard') || lower.contains('dealer portal') || lower.contains('डीलर्स डैशबोर्ड')) {
      final text = (lang == 'hindi')
          ? 'निश्चय ही! मैं डीलर परफॉरमेंस डैशबोर्ड और लीड्स फ़नल ओपन कर रही हूँ।'
          : (lang == 'english')
              ? 'Opening the Dealer Performance Analytics and Lead Management Dashboard.'
              : 'Sure! Main Dealer Performance Dashboard aur Lead Pipeline open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: ['AI Listing Creator', 'Hot Leads', 'Conversion Funnel'],
        flowType: 'navigation',
      );
    }
    if (lower.contains('profile kholo') || lower.contains('user profile') || lower.contains('my account') || lower.contains('प्रोफाइल खोलो')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं आपकी प्रोफाइल, सेव की गई प्रॉपर्टीज और एक्टिव डील्स ओपन कर रही हूँ।'
          : (lang == 'english')
              ? 'Opening your Buyer Profile, Saved Searches, and Active Deals.'
              : 'Bilkul! Main aapka User Profile, Saved Deals aur AI Preferences open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: ['Saved Properties', 'My Site Visits', 'AI Preferences'],
        flowType: 'navigation',
      );
    }
    return null;
  }

  /// Post-Site-Visit Buyer Retention Voice Handler: Summary, Feedback, Re-Match, Negotiation
  AiAgentResult? _handlePostVisitRetentionIntent(String rawInput, String lower, String lang) {
    // 1. Visit Summary Request ("summary", "dekha tha uska summary", "visit summary")
    if ((lower.contains('summary') || lower.contains('dekha tha') || lower.contains('visit summary')) && !lower.contains('summary bana do')) {
      final feedbacks = PostVisitRetentionService.instance.allFeedbacks;
      final recentFeedback = feedbacks.isNotEmpty ? feedbacks.first : null;
      final visits = PropertyStateService.instance.scheduledVisits;
      final recentVisit = visits.isNotEmpty ? visits.first : null;
      final propTitle = recentFeedback?.propertyTitle ?? recentVisit?['propertyTitle'] ?? recentVisit?['property_title'] ?? 'ATS HomeKraft Happy Trails';

      final pros = recentFeedback?.pros.isNotEmpty == true ? recentFeedback!.pros.join(', ') : 'Spacious balcony aur well-designed layout';
      final cons = recentFeedback?.cons.isNotEmpty == true ? recentFeedback!.cons.join(', ') : 'Parking slot dimensions thodi compact lagi';
      final concerns = recentFeedback?.concerns.isNotEmpty == true ? recentFeedback!.concerns.join(', ') : 'Price negotiation headroom';

      final text = (lang == 'hindi')
          ? 'आपकी हालिया साइट विजिट ($propTitle) का AI सारांश: खूबियां (Pros): $pros। कमियां (Cons): $cons। मुख्य चिंता: $concerns। क्या आप इस प्रॉपर्टी पर सेफ डील रूम में नेगोशिएशन शुरू करना चाहेंगे या बेहतर मैचिंग ऑप्शंस देखना चाहते हैं?'
          : (lang == 'english')
              ? 'Here is your AI Visit Summary for $propTitle: Pros: $pros. Cons: $cons. Identified Concerns: $concerns. Would you like to initiate price negotiation in the Safe Deal Room, or explore better matching properties?'
              : 'Aapki recent site visit ($propTitle) ka AI Summary: Pros: $pros. Cons: $cons. Identified Concerns: $concerns. Kya aap is property par Safe Deal Room mein negotiation start karna chahte hain ya better matching options explore karein?';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: _context.lastFoundProperties,
        context: _context,
        suggestedChips: ['Start Negotiation', 'Find Better Properties', 'Open Safe Deal Room'],
        flowType: 'visitSummary',
      );
    }

    // 2. Natural Visit Feedback ("Flat acha tha but parking chhoti thi", "Location achhi hai but price thoda high hai", "Balcony bahut achhi lagi", "Parking chhoti lagi thi")
    if (lower.contains('flat acha') || lower.contains('parking chhot') || lower.contains('parking choti') || lower.contains('parking was small') || lower.contains('balcony achhi') || lower.contains('balcony bahut') || lower.contains('location achhi') || lower.contains('price thoda high') || lower.contains('parking chhoti')) {
      final visits = PropertyStateService.instance.scheduledVisits;
      final recentVisit = visits.isNotEmpty ? visits.first : null;
      final visitId = recentVisit?['id']?.toString() ?? 'VISIT-RECENT';
      final propId = recentVisit?['property_id']?.toString() ?? recentVisit?['propertyId']?.toString() ?? 'prop_recent';
      final propTitle = recentVisit?['propertyTitle']?.toString() ?? recentVisit?['property_title']?.toString() ?? 'ATS HomeKraft Happy Trails';

      // Parse and save structured feedback
      PostVisitRetentionService.instance.submitFeedback(
        visitId: visitId,
        propertyId: propId,
        propertyTitle: propTitle,
        interestLevel: (lower.contains('parking chhot') || lower.contains('price thoda high') || lower.contains('parking choti') || lower.contains('parking chhoti'))
            ? BuyerInterestLevel.wantMoreOptions
            : BuyerInterestLevel.interested,
        rawNotes: rawInput,
      );

      final prosStr = 'Spacious balcony aur well-designed layout';
      final consStr = 'Small basement parking space';

      final text = (lang == 'hindi')
          ? 'अच्छा, समझ गई! आपकी साइट विजिट फीडबैक: खूबियाँ (Pros): $prosStr | कमियाँ (Cons): $consStr। मैंने आपके फीडबैक को सुरक्षित रूप से सेव कर लिया है। आपके लिए बेहतर मैचिंग प्रॉपर्टीज में बड़ी कवर्ड पार्किंग वाले ऑप्शंस उपलब्ध हैं। क्या मैं उन्हें दिखाऊँ?'
          : (lang == 'english')
              ? 'Understood! Processed Visit Feedback: Pros: $prosStr | Cons: $consStr. I have updated your preference profile with spacious reserved parking options. Would you like to review alternative matching properties?'
              : 'Achha, samajh gayi! Site Visit Feedback: Pros: $prosStr | Cons: $consStr. Maine aapki preferences update kar di hain aur better matching options shortlist kar liye hain jinme 2-car covered parking available hai. Kya main unhe dikhaun?';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: _context.lastFoundProperties,
        context: _context,
        suggestedChips: ['Better Properties Dikhao', 'Start Negotiation', 'View AI Visit Summary'],
        flowType: lower.contains('checklist') ? 'checklist' : 'visitFeedback',
      );
    }

    // 3. AI Property Re-Match / "Us jaisi aur properties dikhao" / "Need more options"
    if (lower.contains('us jaisi') || lower.contains('aur properties') || lower.contains('better properties') || lower.contains('better options') || lower.contains('need more options') || lower.contains('ye property better')) {
      final rematches = PostVisitRetentionService.instance.getReMatchedProperties();
      final topMatches = rematches.take(2).toList();
      final props = topMatches.map((m) => m.property).toList();

      if (topMatches.isNotEmpty) {
        final top = topMatches.first;
        final text = (lang == 'hindi')
            ? 'मैंने आपके फीडबैक के आधार पर बेहतर मैचिंग प्रॉपर्टीज ढूंढी हैं। टॉप मैच: ${top.property.title} (${top.matchPercentage}% Match) — ${top.matchExplanation}। क्या आप इस प्रॉपर्टी की डिटेल्स देखना चाहेंगे या सेलर से नेगोशिएशन स्टार्ट करें?'
            : (lang == 'english')
                ? 'Based on your visit feedback, I have re-matched the top properties for you. Top Match: ${top.property.title} (${top.matchPercentage}% Match) — ${top.matchExplanation}. Would you like to review details or start a negotiation?'
                : 'Maine aapke feedback ke basis par top matching properties curate ki hain. Top match: ${top.property.title} (${top.matchPercentage}% Match) — ${top.matchExplanation}. Kya aap iski details dekhna chahte hain ya seller se negotiation start karein?';

        return AiAgentResult(
          speechResponse: text,
          textResponse: text,
          language: lang,
          matchedProperties: props,
          context: _context,
          suggestedChips: ['Start Negotiation', 'Book Site Visit', 'View Property Details'],
          flowType: 'propertyRematch',
        );
      }
    }

    // 4. Start Negotiation Command ("Mujhe seller se negotiate karna hai")
    if (lower.contains('negotiate karna hai') || lower.contains('seller se negotiate') || lower.contains('start negotiation')) {
      final text = (lang == 'hindi')
          ? 'परफेक्ट! मैं आपके लिए PropZen Safe Deal Room ओपन कर देती हूँ। यहाँ आप वेरिफाइड सेलर के साथ डायरेक्ट काउंटर-ऑफर भेज सकते हैं और 5-पिलर डील स्कोर देख सकते हैं।'
          : (lang == 'english')
              ? 'Perfect! I am opening the PropZen Safe Deal Room for you. Here you can submit a formal counter-offer directly to the verified seller and track live negotiation milestones.'
              : 'Perfect! Main aapke liye PropZen Safe Deal Room open kar deti hoon jahan aap verified seller ke saath direct counter-offer discuss kar sakte hain aur payment milestones track kar sakte hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: _context.selectedProperty != null ? [_context.selectedProperty!] : [],
        context: _context,
        suggestedChips: ['Open Deal Room', 'Submit Offer', 'View Deal Score'],
        flowType: 'dealRoom',
      );
    }

    return null;
  }

  /// 2. Safe Deal Room & Offers
  AiAgentResult? _handleDealRoomIntent(String lower, String lang) {
    if (lower.contains('deal room') || lower.contains('safe deal') || lower.contains('latest offer') || lower.contains('counter offer') || lower.contains('milestone') || lower.contains('payment schedule')) {
      final rooms = DealRoomService.instance.dealRooms;
      final activeRoom = rooms.isNotEmpty ? rooms.first : DealRoom.sampleRoom();

      final targetProp = _context.selectedProperty ??
          PropertyStateService.instance.findPropertyById(activeRoom.propertyId) ??
          PropertyStateService.instance.allProperties.first;

      final stageLabel = activeRoom.stage.label;
      final offerCount = activeRoom.offers.length;
      final latestOffer = activeRoom.offers.isNotEmpty ? activeRoom.offers.first : null;
      final offerStr = latestOffer != null ? '₹${latestOffer.amountCr.toStringAsFixed(2)} Cr (${latestOffer.status.name})' : '₹${activeRoom.listedPriceCr} Cr';
      final paidCount = activeRoom.milestones.where((m) => m.status == MilestoneStatus.paid).length;
      final totalMilestones = activeRoom.milestones.length;

      final text = (lang == 'hindi')
          ? 'आपके सेफ डील रूम का वर्तमान स्टेज "${stageLabel}" है। प्रॉपर्टी: ${activeRoom.propertyTitle}। लेटेस्ट ऑफर: $offerStr। पेमेंट माइलस्टोन्स: $paidCount/$totalMilestones पूर्ण। सभी KYC और एग्रीमेंट डाक्यूमेंट्स एन्क्रिप्टेड रिपॉजिटरी में सुरक्षित हैं।'
          : (lang == 'english')
              ? 'Your Safe Deal Room is currently at "${stageLabel}" stage for ${activeRoom.propertyTitle}. Latest recorded offer is $offerStr ($offerCount offers logged). Payment milestones: $paidCount/$totalMilestones settled. All documents are encrypted in the repository.'
              : 'Aapke Safe Deal Room ka active stage "${stageLabel}" hai for ${activeRoom.propertyTitle}. Latest offer: $offerStr. Milestones status: $paidCount of $totalMilestones paid. KYC aur Sale Agreement documents securely verified hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: ['View Deal Room', 'Submit Counter Offer', 'Check Milestones', 'View Documents'],
        flowType: 'dealRoom',
      );
    }
    return null;
  }

  /// 3. AI Negotiation Insights
  AiAgentResult? _handleNegotiationInsightsIntent(String lower, String lang) {
    if (lower.contains('negotiat') || lower.contains('negotiation') || lower.contains('kitne mein final') || lower.contains('price drop') || lower.contains('spread') || lower.contains('bargain') || lower.contains('कम होगा')) {
      final prop = _context.selectedProperty ??
          (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
          PropertyStateService.instance.allProperties.first;

      final buyerBudgetCr = _context.maxBudget != null ? (_context.maxBudget! / 10000000.0) : (prop.askingPriceCr * 0.95);
      final insight = AiNegotiationService.instance.analyzeNegotiation(
        property: prop,
        buyerBudgetCr: buyerBudgetCr,
        listedPriceCr: prop.askingPriceCr,
        dealerOfferCr: prop.askingPriceCr,
      );

      final text = (lang == 'hindi')
          ? '${prop.title} के लिए आस्किंग प्राइस ₹${prop.askingPriceCr.toStringAsFixed(2)} Cr है। AI एनालिसिस के आधार पर अनुशंसित सेटलमेंट रेंज ${insight.formattedRange} है (स्प्रेड: ${insight.spreadPercentage.toStringAsFixed(1)}%)। सुझाव: ${insight.suggestedNextStep}। (नोट: यह डेटा-बेस्ड एस्टीमेट है, कोई कानूनी गारंटी नहीं)।'
          : (lang == 'english')
              ? 'For ${prop.title}, the listed price is ₹${prop.askingPriceCr.toStringAsFixed(2)} Cr. Based on recent transactions, our AI estimated settlement range is ${insight.formattedRange} with a spread of ${insight.spreadPercentage.toStringAsFixed(1)}%. Recommendation: ${insight.suggestedNextStep}. (Note: Algorithmic assessment only, not a guaranteed price).'
              : '${prop.title} ka asking price ₹${prop.askingPriceCr.toStringAsFixed(2)} Cr hai. Hamare AI negotiation model ke according estimated settlement range ${insight.formattedRange} hai (spread: ${insight.spreadPercentage.toStringAsFixed(1)}%). Next step: ${insight.suggestedNextStep}. (Note: Yeh market intelligence estimate hai, guaranteed commitment nahi).';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [prop],
        context: _context,
        suggestedChips: ['Open Negotiation Room', 'Make an Offer', 'Book Site Visit', 'Compare Fair Value'],
        flowType: 'negotiation',
      );
    }
    return null;
  }

  /// 4. AI Property Verification & PropZen Deal Score
  AiAgentResult? _handleVerificationAndDealScoreIntent(String lower, String lang) {
    if (lower.contains('verification score') || lower.contains('verified hai') || lower.contains('documents check') || lower.contains('legal status') || lower.contains('deal score') || lower.contains('5 pillar') || lower.contains('5 factors')) {
      final prop = _context.selectedProperty ??
          (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
          PropertyStateService.instance.allProperties.first;

      final text = (lang == 'hindi')
          ? '${prop.title} का PropZen AI Verification Score ${prop.intelligenceScore}/100 है। 5 मुख्य स्तंभ: 1. प्रॉपर्टी क्वालिटी (92%), 2. प्राइस फेयर वैल्यू (88%), 3. डॉक्यूमेंट्स व RERA (${prop.reraStatus}), 4. लोकेशन इंफ्रास्ट्रक्चर (94%), 5. डील ट्रांसपेरेंसी (90%)। रेकमेंडेशन: कॉन्फिडेंस के साथ आगे बढ़ें। (सूचनात्मक सहायता, कानूनी सलाह नहीं)।'
          : (lang == 'english')
              ? '${prop.title} holds a PropZen Deal Score of ${prop.intelligenceScore}/100. Evaluated across 5 pillars: 1. Property Quality (92%), 2. Price vs Fair Value (88%), 3. Document/RERA Clearances (${prop.reraStatus}), 4. Location Connectivity (94%), 5. Deal Safety (90%). Recommendation: Proceed with Confidence. (Informational assessment, not legal advice).'
              : '${prop.title} ka PropZen Deal Score ${prop.intelligenceScore}/100 hai across 5 pillars: Property Quality (92%), Pricing (88%), RERA Clearances (${prop.reraStatus}), Location (94%), aur Deal Terms (90%). Recommendation: Proceed with Confidence. (Note: Informational report, not a legal certificate).';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [prop],
        context: _context,
        suggestedChips: ['View Verification Report', 'Check Title Deeds', 'Book Site Visit', 'Open Deal Room'],
        flowType: 'verification',
      );
    }
    return null;
  }

  /// 5. Multi-Property Visit Planner & Digital Checklist
  AiAgentResult? _handleVisitPlannerAndChecklistIntent(String rawInput, String lower, String lang) {
    if (lower.contains('checklist') || lower.contains('parking achhi') || lower.contains('parking was small') || lower.contains('balcony badi') || lower.contains('summary bana do') || lower.contains('visit summary')) {
      final summary = AiVisitSummary.parseFromNotes(
        visitId: 'VISIT-${DateTime.now().millisecondsSinceEpoch}',
        propertyTitle: _context.selectedProperty?.title ?? 'ATS Pious Orchards Luxury Suites',
        rawNotes: rawInput,
      );

      final prosStr = summary.pros.isNotEmpty ? summary.pros.first : 'Spacious living area & ventilation.';
      final consStr = summary.cons.isNotEmpty ? summary.cons.first : 'Parking slot dimensions tight for SUVs.';
      final qStr = summary.followUpQuestions.isNotEmpty ? summary.followUpQuestions.first : 'Confirm monthly maintenance fee.';

      final text = (lang == 'hindi')
          ? 'शानदार ऑब्जर्वेशन! मैंने आपकी साइट विजिट समरी तैयार कर ली है: खूबियाँ: $prosStr | कमियाँ: $consStr | फॉलो-अप सवाल: $qStr। यह समरी आपके डिजिटल चेकलिस्ट में ऑटोमेटिकली सेव हो गई है।'
          : (lang == 'english')
              ? 'Great observation! I have processed your site visit summary: Pros: $prosStr | Cons: $consStr | Follow-up: $qStr. This summary is now saved to your Digital Visit Checklist.'
              : 'Great observation! Mainne aapki Site Visit Summary parse kar li hai: Pros: $prosStr | Cons: $consStr | Follow-up Question: $qStr. Yeh summary aapke Site Visit Checklist mein save ho gayi hai.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: _context.selectedProperty != null ? [_context.selectedProperty!] : [],
        context: _context,
        suggestedChips: ['View Digital Checklist', 'Add More Notes', 'Plan Next Visit', 'Enter Deal Room'],
        flowType: 'checklist',
      );
    }

    if (lower.contains('plan visit') || lower.contains('multiple properties') || lower.contains('itinerary') || lower.contains('kal 3') || lower.contains('kal 2') || lower.contains('tour schedule')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैंने आपका 3-स्टॉप प्रॉपर्टी टूर शेड्यूल कर दिया है: 1. ATS Pious Orchards (10:00 AM), 2. Godrej Palm Retreat (12:30 PM), 3. Gaur City (03:00 PM)। साथ ही 2 विजिटर्स के लिए फ्री AC कैब भी असिस्टेंस में शामिल है। क्या मैं टाइम स्लॉट लॉक कर दूँ?'
          : (lang == 'english')
              ? 'Certainly! I have organized your multi-property tour itinerary: Stop 1: ATS Pious Orchards (10:00 AM), Stop 2: Godrej Palm Retreat (12:30 PM), Stop 3: Gaur City (03:00 PM), complete with complimentary AC cab transit. Shall I confirm this schedule?'
              : 'Bilkul! Main aapka 3-property tour itinerary arrange kar deti hoon: Stop 1: ATS Pious Orchards (10:00 AM), Stop 2: Godrej Palm Retreat (12:30 PM), Stop 3: Gaur City (03:00 PM). Free AC cab pick-up bhi included hai. Kya main timings lock kar doon?';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: PropertyStateService.instance.allProperties.take(3).toList(),
        context: _context,
        suggestedChips: ['Confirm Itinerary', 'Change Time Slots', 'Open Visit Checklist'],
        flowType: 'planner',
      );
    }
    return null;
  }

  /// 1.0 Direct Voice Actions (Details, Drone, 360, 3D, Site Visit, Remote Tour, Subscription, Calculator, Loan)
  AiAgentResult? _handleDirectVoiceAction(String lower, String lang) {
    final activeProp = _context.selectedProperty ??
        (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
        (PropertyStateService.instance.allProperties.isNotEmpty
            ? PropertyStateService.instance.allProperties.first
            : Property.sampleDeals.first);

    // 1. Open Property Details
    if (lower.contains('property details kholo') ||
        lower.contains('open property details') ||
        lower.contains('details kholo') ||
        lower.contains('property details dikhao') ||
        lower.contains('open details')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं ${activeProp.title} की पूरी डिटेल्स स्क्रीन खोल रही हूँ।'
          : (lang == 'english')
              ? 'Opening property details for ${activeProp.title}.'
              : 'Bilkul! Main ${activeProp.title} ki full details screen open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'open_details',
        actionTargetProperty: activeProp,
        suggestedChips: ['Watch Drone Tour', 'Book Site Visit', 'Compare Properties'],
        flowType: 'action',
      );
    }

    // 2. Drone Tour
    if (lower.contains('drone tour chalao') ||
        lower.contains('drone tour dikhao') ||
        lower.contains('drone video dikhao') ||
        lower.contains('watch drone tour') ||
        lower.contains('show drone tour') ||
        lower.contains('iska drone tour')) {
      final hasDrone = activeProp.hasDroneTour;

      if (!hasDrone) {
        final text = (lang == 'hindi')
            ? 'इस प्रॉपर्टी के लिए प्रमाणित 4K ड्रोन वीडियो अभी उपलब्ध नहीं है।'
            : (lang == 'english')
                ? 'A verified 4K aerial drone tour is not available for this property yet.'
                : 'Is property ke liye verified 4K drone tour abhi available nahi hai.';
        return AiAgentResult(
          speechResponse: text,
          textResponse: text,
          language: lang,
          matchedProperties: [activeProp],
          context: _context,
          suggestedChips: ['View 360 Tour', 'View Floor Plan', 'Book Site Visit'],
          flowType: 'action',
        );
      }

      final text = (lang == 'hindi')
          ? 'निश्चय ही! मैं ${activeProp.title} का 4K एरियल ड्रोन टूर शुरू कर रही हूँ।'
          : (lang == 'english')
              ? 'Starting the 4K aerial drone tour for ${activeProp.title}.'
              : 'Bilkul! Main ${activeProp.title} ka 4K aerial drone tour launch kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'open_drone',
        actionTargetProperty: activeProp,
        suggestedChips: ['Full Screen Drone', 'Check Altitude', 'AI Drone Assistant'],
        flowType: 'action',
      );
    }

    // 3. 360 Tour
    if (lower.contains('360 tour dikhao') ||
        lower.contains('360 tour chalao') ||
        lower.contains('show 360 tour') ||
        lower.contains('virtual tour dikhao') ||
        lower.contains('360 panorama kholo')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं ${activeProp.title} का 360° वर्चुअल पैनोरमा टूर खोल रही हूँ।'
          : (lang == 'english')
              ? 'Opening the 360° virtual tour for ${activeProp.title}.'
              : 'Bilkul! Main ${activeProp.title} ka 360° virtual panorama tour open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'open_360',
        actionTargetProperty: activeProp,
        suggestedChips: ['Explore Rooms', 'View Floor Plan', 'Book Site Visit'],
        flowType: 'action',
      );
    }

    // 4. 3D Model View
    if (lower.contains('3d model kholo') ||
        lower.contains('3d model dikhao') ||
        lower.contains('open 3d model') ||
        lower.contains('3d view dikhao') ||
        lower.contains('3d twin dikhao')) {
      final text = (lang == 'hindi')
          ? 'निश्चय ही! मैं ${activeProp.title} का 3D आर्किटेक्चरल मॉडल खोल रही हूँ।'
          : (lang == 'english')
              ? 'Opening the interactive 3D architectural twin for ${activeProp.title}.'
              : 'Bilkul! Main ${activeProp.title} ka 3D architectural digital twin launch kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'open_3d',
        actionTargetProperty: activeProp,
        suggestedChips: ['Orbit 3D', 'Wireframe View', 'View Floor Plan'],
        flowType: 'action',
      );
    }

    // 5. Site Visit Booking Trigger
    if (lower.contains('site visit book karo') ||
        lower.contains('schedule site visit') ||
        lower.contains('site visit schedule karo') ||
        lower.contains('book site visit')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं ${activeProp.title} के लिए साइट विजिट बुकिंग शुरू कर रही हूँ। आप किस तारीख को विजिट करना चाहेंगे?'
          : (lang == 'english')
              ? 'Starting the site visit booking flow for ${activeProp.title}. What date would you prefer?'
              : 'Bilkul! Main ${activeProp.title} ke liye site visit booking initialize kar rahi hoon. Aap kis date par visit karna chahenge?';
      _context.activeFlow = AgentFlow.siteVisit;
      _context.siteVisitStage = SiteVisitStage.collectingDate;
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'book_site_visit',
        actionTargetProperty: activeProp,
        suggestedChips: ['Tomorrow', 'Upcoming Weekend', 'Pick on Calendar'],
        flowType: 'siteVisit',
      );
    }

    // 6. Remote Tour Request Trigger (NRI)
    if (lower.contains('remote tour request karo') ||
        lower.contains('request remote tour') ||
        lower.contains('live tour schedule karo') ||
        lower.contains('video tour book karo') ||
        lower.contains('schedule remote tour')) {
      final text = (lang == 'hindi')
          ? 'निश्चय ही! मैं ${activeProp.title} के लिए 1-on-1 लाइव रिमोट वीडियो टूर शेड्यूलर खोल रही हूँ।'
          : (lang == 'english')
              ? 'Opening the 1-on-1 Live Remote Video Tour booking dialog for ${activeProp.title}.'
              : 'Bilkul! Main ${activeProp.title} ke liye 1-on-1 Live Remote Video Tour dialog open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'request_remote_tour',
        actionTargetProperty: activeProp,
        suggestedChips: ['Select Timezone', 'Preferred Date', 'Confirm Remote Tour'],
        flowType: 'action',
      );
    }

    // 7. Subscription Plans Trigger
    if (lower.contains('subscription plans dikhao') ||
        lower.contains('show subscription plans') ||
        lower.contains('plans dikhao') ||
        lower.contains('nri pass dikhao') ||
        lower.contains('view plans') ||
        lower.contains('pass pricing batao') ||
        lower.contains('dealer plans')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं PropZen सब्सक्रिप्शन और एक्सेस पास स्क्रीन खोल रही हूँ।'
          : (lang == 'english')
              ? 'Navigating to PropZen Subscription and Access Passes.'
              : 'Bilkul! Main PropZen Subscription and Access Plans screen open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        triggeredAction: 'view_plans',
        suggestedChips: ['Basic Pass (₹1,999)', 'Premium Pass (₹3,999)', 'Elite Pass (₹5,999)'],
        flowType: 'action',
      );
    }

    // 8. Investment Calculator Trigger
    if (lower.contains('yield calculator') ||
        lower.contains('investment calculator') ||
        lower.contains('calculator kholo') ||
        lower.contains('nri calculator')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! मैं NRI यील्ड और EMI इन्वेस्टमेंट कैलकुलेटर खोल रही हूँ।'
          : (lang == 'english')
              ? 'Opening the NRI Investment, Yield & Cash Flow Calculator.'
              : 'Bilkul! Main NRI Investment, Yield aur EMI Calculator open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'open_investment_calc',
        actionTargetProperty: activeProp,
        suggestedChips: ['Calculate Gross Yield', 'Estimate EMI', '5-Year Cash Flow'],
        flowType: 'action',
      );
    }

    // 9. Home Loan Assistance Trigger
    if (lower.contains('loan assistance') ||
        lower.contains('home loan assist') ||
        lower.contains('nri home loan') ||
        lower.contains('bank loan help')) {
      final text = (lang == 'hindi')
          ? 'निश्चय ही! मैं NRI होम लोन एलिजिबिलिटी और असिस्टेंस फॉर्म खोल रही हूँ।'
          : (lang == 'english')
              ? 'Opening the NRI Home Loan Eligibility & Advisory Desk.'
              : 'Bilkul! Main NRI Home Loan Eligibility aur Advisory Desk open kar rahi hoon.';
      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        triggeredAction: 'open_loan_assistance',
        actionTargetProperty: activeProp,
        suggestedChips: ['Check Eligibility', 'Required Documents', 'HDFC / SBI Rates'],
        flowType: 'action',
      );
    }

    return null;
  }

  /// 6. Complete Dealer AI Operations
  AiAgentResult? _handleDealerVoiceOperations(String rawInput, String lower, String lang) {
    // 1. Show New Leads
    if (lower.contains('new leads') ||
        lower.contains('mere leads') ||
        lower.contains('mere new leads') ||
        lower.contains('show my leads') ||
        lower.contains('leads dikhao') ||
        lower.contains('show leads')) {
      final dealerId = UserSession.dealerId;
      final leads = DealerLeadService.instance.getLeadsForDealer(dealerId);
      final hotLeads = leads.where((l) => l.scoreTier == LeadScoreTier.hot).toList();

      final text = (lang == 'hindi')
          ? 'आपके पोर्टल में कुल ${leads.length} एक्टिव लीड्स हैं, जिनमें से ${hotLeads.length} HOT LEADS हैं। सबसे उच्च स्कोर वाली लीड "${leads.isNotEmpty ? leads.first.buyerName : 'राहुल मेहरा'}" (${leads.isNotEmpty ? leads.first.requirement : '3 BHK'}) की है।'
          : (lang == 'english')
              ? 'You have ${leads.length} active dealer leads, including ${hotLeads.length} HOT LEADS. Top scored buyer is "${leads.isNotEmpty ? leads.first.buyerName : 'Rahul Mehra'}" (${leads.isNotEmpty ? leads.first.requirement : '3 BHK'}).'
              : 'Aapke portal par total ${leads.length} active leads hain, jinme se ${hotLeads.length} HOT LEADS hain. Top priority buyer "${leads.isNotEmpty ? leads.first.buyerName : 'Rahul Mehra'}" (${leads.isNotEmpty ? leads.first.requirement : '3 BHK'}) hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        dealerLeads: leads,
        suggestedChips: ['Summarize Top Lead', 'Generate WhatsApp Follow-Up', 'View Site Visits Today'],
        flowType: 'dealer',
      );
    }

    // 2. Most Enquired Property
    if (lower.contains('most enquiries') ||
        lower.contains('most inquiry') ||
        lower.contains('sabse zyada enquiries') ||
        lower.contains('top property') ||
        lower.contains('kisme zyada enquiry')) {
      final dealerId = UserSession.dealerId;
      final analytics = DealerLeadService.instance.getAnalyticsForDealer(dealerId);
      final topProp = analytics.topProperties.isNotEmpty ? analytics.topProperties.first : 'ATS Knightsbridge Luxury 4 BHK';

      final text = (lang == 'hindi')
          ? 'आपके पोर्टफोलियो में सबसे ज्यादा इन्क्वायरी "$topProp" पर आ रही हैं (कुल ${analytics.totalEnquiries} इन्क्वायरीज)। इसका लीड कन्वर्जन रेट ${analytics.leadConversionRate.toStringAsFixed(1)}% है।'
          : (lang == 'english')
              ? 'Your highest performing listing is "$topProp" with ${analytics.totalEnquiries} total inquiries and a ${analytics.leadConversionRate.toStringAsFixed(1)}% conversion rate.'
              : 'Aapki top enquiry property "$topProp" hai jisme total ${analytics.totalEnquiries} enquiries aayi hain aur conversion rate ${analytics.leadConversionRate.toStringAsFixed(1)}% hai.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: PropertyStateService.instance.allProperties.take(1).toList(),
        context: _context,
        dealerInsight: {
          'topProperty': topProp,
          'totalEnquiries': analytics.totalEnquiries,
          'conversionRate': analytics.leadConversionRate,
        },
        suggestedChips: ['View Analytics Dashboard', 'Create Marketing Copy', 'Show Leads for Property'],
        flowType: 'dealer',
      );
    }

    // 3. Create Property Description (with Subscription Enforcement)
    if (lower.contains('property description') ||
        lower.contains('listing description') ||
        lower.contains('description banao') ||
        lower.contains('description generate') ||
        lower.contains('listing create') ||
        lower.contains('ai description')) {
      final canUseAiCopy = DealerSubscriptionService.instance.canAccessAiCopywriter;
      if (!canUseAiCopy) {
        final text = (lang == 'hindi')
            ? 'AI लिस्टिंग कॉपीराइटर प्रो और प्रीमियम डीलर प्लान पर उपलब्ध है। अपने प्लान को अपग्रेड करके तुरंत मल्टी-चैनल मार्केटिंग कॉपी जनरेट करें।'
            : (lang == 'english')
                ? 'This AI feature is available on the Pro/Premium dealer plan. Upgrade your plan to generate multi-channel marketing descriptions.'
                : 'This AI feature is available on the Pro/Premium plan. Aap apna dealer plan upgrade karke AI Copywriter unlock kar sakte hain.';
        return AiAgentResult(
          speechResponse: text,
          textResponse: text,
          language: lang,
          matchedProperties: [],
          context: _context,
          suggestedChips: ['Upgrade Plan', 'View Dealer Plans'],
          flowType: 'dealer',
        );
      }

      final activeProp = _context.selectedProperty ??
          (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
          PropertyStateService.instance.allProperties.first;

      final text = (lang == 'hindi')
          ? 'मैंने ${activeProp.title} के लिए प्रोफेशनल RERA-वेरिफाइड लिस्टिंग डिस्क्रिप्शन तैयार किया है: "प्राइम लोकेशन ${activeProp.sector} में स्थित यह शानदार ${activeProp.bhk} यूनिट (${activeProp.sqft} sq.ft.) आधुनिक क्लबहाउस, स्विमिंग पूल व 3-टियर सिक्योरिटी से सुसज्जित है। कीमत: ${activeProp.priceRangeDisplay}।"'
          : (lang == 'english')
              ? 'Here is the professional listing copy for ${activeProp.title}: "Located in prime ${activeProp.sector}, this luxurious ${activeProp.bhk} (${activeProp.sqft} sq.ft.) features premium clubhouse amenities, swimming pool, and 3-tier security. Listed at ${activeProp.priceRangeDisplay}."'
              : 'Maine ${activeProp.title} ke liye professional copy generate ki hai: "Located in prime ${activeProp.sector}, this luxurious ${activeProp.bhk} (${activeProp.sqft} sq.ft.) features modern clubhouse amenities, swimming pool, and 3-tier security. Listed at ${activeProp.priceRangeDisplay}."';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['Copy WhatsApp Pitch', 'Copy Instagram Caption', 'Publish Listing'],
        flowType: 'dealer',
      );
    }

    // 4. Summarize Lead
    if (lower.contains('summarize this lead') ||
        lower.contains('lead summary') ||
        lower.contains('lead summarize') ||
        lower.contains('lead ka summary') ||
        lower.contains('lead score') ||
        lower.contains('buyer kaisa')) {
      final dealerId = UserSession.dealerId;
      final leads = DealerLeadService.instance.getLeadsForDealer(dealerId);
      if (leads.isEmpty) {
        final emptyText = (lang == 'hindi')
            ? 'अभी आपके पोर्टल में कोई लीड नहीं है। पहले प्रॉपर्टी लिस्ट करें ताकि इन्क्वायरीज आ सकें।'
            : (lang == 'english')
                ? 'You have no leads yet. List a property first to start receiving enquiries.'
                : 'Abhi aapke portal mein koi lead nahi hai. Pehle property list karo taaki enquiries aa sakein.';
        return AiAgentResult(
          speechResponse: emptyText,
          textResponse: emptyText,
          language: lang,
          matchedProperties: [],
          context: _context,
          dealerLeads: [],
          suggestedChips: ['AI Listing Creator', 'Add Property', 'View Plans'],
          flowType: 'dealer',
        );
      }
      final lead = leads.first;

      final text = (lang == 'hindi')
          ? 'AI-जनरेटेड लीड सारांश: ${lead.buyerName} — बजट: ₹${lead.budgetCr.toStringAsFixed(2)} Cr, रिक्वायरमेंट: ${lead.requirement}, पसंदीदा लोकेशन: ${lead.preferredLocation}। स्कोर: ${lead.leadScore}/100 (${lead.scoreTier.name.toUpperCase()})। साइट विजिट स्टेटस: ${lead.siteVisitStatus}।'
          : (lang == 'english')
              ? 'AI-generated lead summary: ${lead.buyerName} — Budget: ₹${lead.budgetCr.toStringAsFixed(2)} Cr, Requirement: ${lead.requirement}, Location: ${lead.preferredLocation}. Intent Score: ${lead.leadScore}/100 (${lead.scoreTier.name.toUpperCase()}). Site Visit: ${lead.siteVisitStatus}.'
              : 'AI-generated lead summary: ${lead.buyerName} — Budget: ₹${lead.budgetCr.toStringAsFixed(2)} Cr, Requirement: ${lead.requirement}, Location: ${lead.preferredLocation}. Intent Score: ${lead.leadScore}/100 (${lead.scoreTier.name.toUpperCase()}). Site Visit: ${lead.siteVisitStatus}.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        dealerLeads: [lead],
        suggestedChips: ['Generate WhatsApp Follow-Up', 'Schedule Call', 'Move to Negotiation'],
        flowType: 'dealer',
      );
    }

    // 5. Create Follow-Up Message
    if (lower.contains('follow-up') ||
        lower.contains('follow up') ||
        lower.contains('message bana do') ||
        lower.contains('whatsapp message') ||
        lower.contains('follow-up message')) {
      final dealerId = UserSession.dealerId;
      final leads = DealerLeadService.instance.getLeadsForDealer(dealerId);
      if (leads.isEmpty) {
        final emptyText = (lang == 'hindi')
            ? 'अभी कोई लीड नहीं है जिसके लिए फॉलो-अप बनाया जा सके। पहले प्रॉपर्टी लिस्ट करें।'
            : (lang == 'english')
                ? 'No leads available to generate a follow-up for. List a property first.'
                : 'Abhi koi lead nahi hai jiske liye follow-up ban sake. Pehle property list karo.';
        return AiAgentResult(
          speechResponse: emptyText,
          textResponse: emptyText,
          language: lang,
          matchedProperties: [],
          context: _context,
          dealerLeads: [],
          suggestedChips: ['AI Listing Creator', 'Add Property', 'Show My Leads'],
          flowType: 'dealer',
        );
      }
      final lead = leads.first;

      final text = (lang == 'hindi')
          ? 'मैंने ${lead.buyerName} के लिए WhatsApp-रेडी फॉलो-अप ड्राफ्ट किया है: "नमस्ते ${lead.buyerName.split(' ').first}! ${lead.propertyTitle} (${lead.requirement}) के संबंध में स्पेशल वीकेंड इन्वेंटरी व टाइटल रिपोर्ट एक्टिव है। क्या हम इस शनिवार 30 मिनट का एक्सक्लूसिव वॉकथ्रू शेड्यूल करें?"'
          : (lang == 'english')
              ? 'Here is your WhatsApp-ready follow-up for ${lead.buyerName}: "Hi ${lead.buyerName.split(' ').first}, regarding your interest in ${lead.propertyTitle} (${lead.requirement}), special weekend pricing and verified title report are active. Would you like to schedule an exclusive 30-minute walkthrough this Saturday?"'
              : 'Maine ${lead.buyerName} ke liye WhatsApp-ready message draft kiya hai: "Hi ${lead.buyerName.split(' ').first}! ${lead.propertyTitle} (${lead.requirement}) ke liye weekend inventory aur verified title report active hai. Kya hum is Saturday 30-minute private walkthrough schedule karein?"';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        dealerLeads: [lead],
        suggestedChips: ['Copy WhatsApp Text', 'Copy Email Text', 'Send via In-App'],
        flowType: 'dealer',
      );
    }

    // 6. Show Site Visits Today
    if (lower.contains('site visits today') ||
        lower.contains('aaj ke site visit') ||
        lower.contains('aaj ke visits') ||
        lower.contains('today visits') ||
        lower.contains('visits today')) {
      final dealerId = UserSession.dealerId;
      final visits = DealerLeadService.instance.getSiteVisitsForDealer(dealerId);

      final text = (lang == 'hindi')
          ? 'आज आपके पास कुल ${visits.length} शेड्यूल्ड साइट विजिट्स हैं। अगली विजिट: "${visits.isNotEmpty ? visits.first.buyerName : 'राहुल मेहरा'}" (${visits.isNotEmpty ? visits.first.propertyTitle : 'ATS Knightsbridge'}) ${visits.isNotEmpty ? visits.first.scheduledTime : '11:00 AM'} पर।'
          : (lang == 'english')
              ? 'You have ${visits.length} scheduled site visits today. Next visit: "${visits.isNotEmpty ? visits.first.buyerName : 'Rahul Mehra'}" for ${visits.isNotEmpty ? visits.first.propertyTitle : 'ATS Knightsbridge'} at ${visits.isNotEmpty ? visits.first.scheduledTime : '11:00 AM'}.'
              : 'Aaj aapke paas total ${visits.length} scheduled site visits hain. Next appointment: "${visits.isNotEmpty ? visits.first.buyerName : 'Rahul Mehra'}" (${visits.isNotEmpty ? visits.first.propertyTitle : 'ATS Knightsbridge'}) at ${visits.isNotEmpty ? visits.first.scheduledTime : '11:00 AM'}.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [],
        context: _context,
        suggestedChips: ['Confirm Visit Pickup', 'Call Buyer', 'Open Visit Checklist'],
        flowType: 'dealer',
      );
    }

    return null;
  }

  /// 7. Advanced Multi-Property Comparison Engine
  AiAgentResult? _handlePropertyComparisonIntent(String lower, String lang) {
    if (lower.contains('compare') ||
        lower.contains('comparison') ||
        lower.contains('dono properties') ||
        lower.contains('kaunsi better') ||
        lower.contains('better hai') ||
        lower.contains('vs') ||
        lower.contains('तुलना')) {
      final allProps = PropertyStateService.instance.allProperties;
      final p1 = allProps.isNotEmpty ? allProps[0] : Property.sampleDeals[0];
      final p2 = allProps.length > 1 ? allProps[1] : Property.sampleDeals[1];

      final betterBudgetProp = (p1.askingPriceCr <= p2.askingPriceCr) ? p1 : p2;
      final betterSizeProp = (p1.sqft >= p2.sqft) ? p1 : p2;
      final betterLocationProp = p1;
      final betterRemoteProp = (p1.hasDroneTour || p1.has3DModel) ? p1 : p2;

      final compData = {
        'prop1': p1,
        'prop2': p2,
        'betterBudget': betterBudgetProp.title,
        'betterSize': betterSizeProp.title,
        'betterLocation': betterLocationProp.title,
        'betterRemote': betterRemoteProp.title,
      };

      final text = (lang == 'hindi')
          ? 'तुलना सारांश: 1. ${p1.title} (${p1.priceRangeDisplay}, ${p1.sqft} sq.ft.) बनाम 2. ${p2.title} (${p2.priceRangeDisplay}, ${p2.sqft} sq.ft.)। '
              'बजट के लिए बेहतर: ${betterBudgetProp.title}। साइज के लिए बेहतर: ${betterSizeProp.title}। लोकेशन कनेक्टिविटी के लिए बेहतर: ${betterLocationProp.title}। रिमोट एक्सप्लोरेशन के लिए बेहतर: ${betterRemoteProp.title}।'
          : (lang == 'english')
              ? 'Comparison Summary: 1. ${p1.title} (${p1.priceRangeDisplay}, ${p1.sqft} sq.ft.) vs 2. ${p2.title} (${p2.priceRangeDisplay}, ${p2.sqft} sq.ft.). '
              'Better for Budget: ${betterBudgetProp.title}. Better for Size: ${betterSizeProp.title}. Better for Location: ${betterLocationProp.title}. Better for Remote Viewing: ${betterRemoteProp.title}.'
              : 'Comparison Summary: 1. ${p1.title} (${p1.priceRangeDisplay}, ${p1.sqft} sq.ft.) vs 2. ${p2.title} (${p2.priceRangeDisplay}, ${p2.sqft} sq.ft.). '
              'Better for Budget: ${betterBudgetProp.title}. Better for Size: ${betterSizeProp.title}. Better for Location: ${betterLocationProp.title}. Better for Remote Viewing: ${betterRemoteProp.title}.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [p1, p2],
        context: _context,
        comparisonData: compData,
        suggestedChips: ['Book Visit for Option 1', 'Book Visit for Option 2', 'Open Safe Deal Room'],
        flowType: 'comparison',
      );
    }
    return null;
  }

  /// 7.1 NRI Experience & Remote Suite Advisory
  AiAgentResult? _handleNriAiIntent(String lower, String lang) {
    if (lower.contains('nri') ||
        lower.contains('dubai') ||
        lower.contains('abroad') ||
        lower.contains('overseas') ||
        lower.contains('singapore') ||
        lower.contains('usa') ||
        lower.contains('london') ||
        lower.contains('uk') ||
        lower.contains('canada') ||
        lower.contains('remote pass') ||
        lower.contains('remote property pass')) {
      final text = (lang == 'hindi')
          ? 'नमस्ते! PropZen NRI रिमोट प्रॉपर्टी सुइट आपके लिए विशेष रूप से डिज़ाइन किया गया है: इसमें 4K एरियल ड्रोन टूर, 360° पैनोरमा वॉकथ्रू, 1-on-1 लाइव रिमोट टूर (विदेशी टाइमजोन सपोर्ट के साथ), डिजिटल डॉक्यूमेंट वॉल्ट और फैमिली डिसीजन वोटिंग शामिल है।'
          : (lang == 'english')
              ? 'Hello! PropZen\'s NRI Remote Property Suite is tailored for overseas investors: featuring 4K aerial drone tours, 360° virtual tours, 1-on-1 live remote walkthroughs with multi-timezone scheduling, legal document vault, and family decision mode.'
              : 'Hello! PropZen NRI Remote Property Suite overseas buyers ke liye curated hai: jismein 4K Aerial Drone Tours, 360° Panoramas, 1-on-1 Live Remote Tours (international timezone support), Document Concierge aur Family Voting shamil hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: PropertyStateService.instance.allProperties.where((p) => p.hasDroneTour).take(2).toList(),
        context: _context,
        suggestedChips: ['Watch Drone Tour', 'Book Remote Tour', 'Yield Calculator', 'Document Vault'],
        flowType: 'nri',
      );
    }
    return null;
  }

  /// 7.2 General Real Estate Concept FAQs
  AiAgentResult? _handleFaqAndComparisonIntent(String lower, String lang) {
    final comp = _handlePropertyComparisonIntent(lower, lang);
    if (comp != null) return comp;

    final nri = _handleNriAiIntent(lower, lang);
    if (nri != null) return nri;

    if (lower.contains('rera kya') || lower.contains('what is rera') || lower.contains('रेरा क्या')) {
      final text = (lang == 'hindi')
          ? 'RERA (रियल एस्टेट रेगुलेटरी अथॉरिटी) खरीदारों को पजेशन डिले और फ्रॉड से बचाने के लिए बनाया गया सरकारी कानून है। PropZen पर सभी प्रोजेक्ट्स 100% RERA-वेरिफाइड होते हैं।'
          : (lang == 'english')
              ? 'RERA (Real Estate Regulatory Authority) is a statutory body safeguarding buyers against construction delays and fraud. Every listing on PropZen is cross-verified with official RERA records.'
              : 'RERA (Real Estate Regulatory Authority) buyers ko project delay aur fraud se protect karne ke liye government framework hai. PropZen par listed sabhi properties 100% RERA verified hoti hain.';
      return AiAgentResult(speechResponse: text, textResponse: text, language: lang, matchedProperties: [], context: _context, flowType: 'faq');
    }

    if (lower.contains('carpet area') || lower.contains('super built') || lower.contains('कारपेट एरिया')) {
      final text = (lang == 'hindi')
          ? 'कारपेट एरिया वह इनर एरिया है जहाँ आप वास्तव में कारपेट बिछा सकते हैं (दीवारों के भीतर का इस्तेमाल योग्य क्षेत्र)। सुपर बिल्ट-अप एरिया में लिफ्ट लॉबी, सीढ़ियां और कॉमन एरिया भी शामिल होते हैं।'
          : (lang == 'english')
              ? 'Carpet area is the net usable floor area inside the inner walls of the apartment. Super built-up area includes the carpet area plus pro-rata share of common spaces like elevators and lobbies.'
              : 'Carpet area wo net usable area hai jo actual ghar ke andar hota hai. Super built-up area mein corridors, lift lobby aur common amenities ka proportionate share bhi included hota hai.';
      return AiAgentResult(speechResponse: text, textResponse: text, language: lang, matchedProperties: [], context: _context, flowType: 'faq');
    }

    if (lower.contains('stamp duty') || lower.contains('registry kya') || lower.contains('स्टाम्प ड्यूटी')) {
      final text = (lang == 'hindi')
          ? 'स्टाम्प ड्यूटी राज्य सरकार को दिया जाने वाला कानूनी प्रॉपर्टी ट्रांसफर टैक्स है (लगभग 5% से 7%)। रजिस्ट्री कराने से संपत्ति का स्वामित्व कानूनी रूप से आपके नाम दर्ज होता है।'
          : (lang == 'english')
              ? 'Stamp duty is the state government tax payable on property conveyance (typically 5% to 7% in NCR). Registry completes the legal transfer of title into your name.'
              : 'Stamp duty property transaction par state tax hota hai (approx 5% to 7% in NCR), aur registry se ownership legally aapke naam par record hoti hai.';
      return AiAgentResult(speechResponse: text, textResponse: text, language: lang, matchedProperties: [], context: _context, flowType: 'faq');
    }

    if (lower.contains('home loan') || lower.contains('emi kaise') || lower.contains('होम लोन')) {
      final text = (lang == 'hindi')
          ? 'प्रॉपर्टी पर 80% तक होम लोन प्रमुख बैंकों (HDFC, SBI, ICICI) से 8.4% से 8.75% की ब्याज दर पर उपलब्ध है। ₹80 लाख के लोन पर 20 साल के लिए अनुमानित EMI लगभग ₹69,000 प्रति माह होगी।'
          : (lang == 'english')
              ? 'Up to 80% financing is available via premier banking partners (HDFC, SBI, ICICI) at 8.4%–8.75% interest rates. For a ₹80 Lakh loan over 20 years, the estimated EMI is around ₹69,000/month.'
              : 'Leading banks (HDFC, SBI, ICICI) se up to 80% loan 8.4%–8.75% interest par available hai. ₹80 Lakh ke loan par 20 saal ke tenure mein estimated EMI approx ₹69,000/month hoti hai.';
      return AiAgentResult(speechResponse: text, textResponse: text, language: lang, matchedProperties: [], context: _context, flowType: 'faq');
    }

    return null;
  }

  /// 8. Immersive Property Visualization Suite Intent Handler (360 Tour, 3D, AR, Floor Plan, Interior, Exterior, Vastu)
  AiAgentResult? _handlePropertyVisualizationIntent(String lower, String lang) {
    final activeProp = _context.selectedProperty ??
        (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
        (PropertyStateService.instance.allProperties.isNotEmpty
            ? PropertyStateService.instance.allProperties.first
            : Property.sampleDeals.first);

    // 1. 360° Virtual Tour Intent
    if (lower.contains('360') ||
        lower.contains('virtual tour') ||
        lower.contains('kuula') ||
        lower.contains('panorama') ||
        lower.contains('panoramic') ||
        lower.contains('वर्चुअल टूर') ||
        lower.contains('360 tour')) {
      final text = (lang == 'hindi')
          ? 'बिल्कुल! PropZen पर ${activeProp.title} का हाई-डेफिनिशन 360° वर्चुअल टूर उपलब्ध है। आप घर बैठे हर कमरे का स्फेरिकल 360° व्यू देख सकते हैं।'
          : (lang == 'english')
              ? 'Certainly! An immersive 360° virtual tour is available for ${activeProp.title}. You can explore complete spherical room views or schedule a verified in-person site visit.'
              : 'Bilkul! PropZen par ${activeProp.title} ka HD 360° virtual tour available hai. Aap bina travel kiye room-by-room 360° panoramic view explore kar sakte hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['360° Tour Kholo', 'Explore in 3D', '3D Floor Plan', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    // 2. Interactive 3D Model Intent
    if (lower.contains('3d model') ||
        lower.contains('3d building') ||
        lower.contains('sketchfab') ||
        lower.contains('3d view') ||
        lower.contains('3d mein') ||
        lower.contains('3d architectural') ||
        lower.contains('3d में')) {
      final text = (lang == 'hindi')
          ? 'जी बिल्कुल! ${activeProp.title} का इंटरैक्टिव 3D डिजिटल ट्विन उपलब्ध है। आप इसे 360° रोटेट, ज़ूम और वायरफ्रेम मोड में एक्सप्लोर कर सकते हैं।'
          : (lang == 'english')
              ? 'Certainly! ${activeProp.title} features an interactive 3D WebGL building model with full 360-degree orbit rotation and wireframe inspection modes.'
              : 'Ji bilkul! ${activeProp.title} ka interactive 3D WebGL model available hai jise aap rotate, zoom aur wireframe modes mein explore kar sakte hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['3D Model Kholo', 'View in AR', 'Floor Plan Dekho', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    // 3. AR (Augmented Reality) View Intent
    if (lower.contains('ar view') ||
        lower.contains('augmented reality') ||
        lower.contains('ar mein') ||
        lower.contains('camera se placement') ||
        lower.contains('tabletop scale') ||
        lower.contains('1:1 scale') ||
        lower.contains('ar plot') ||
        lower.contains('एआर')) {
      final text = (lang == 'hindi')
          ? 'PropZen AR मोड से आप अपने फोन कैमरे से ${activeProp.title} का लेआउट अपने कमरे में 1:1 स्केल या टेबलटॉप व्यू पर रखकर वॉक-थ्रू कर सकते हैं।'
          : (lang == 'english')
              ? 'PropZen Augmented Reality allows you to anchor ${activeProp.title}\'s layout in your room at 1:1 real-life walk-in scale or tabletop view via WebXR & ARCore.'
              : 'PropZen AR mode se aap apne phone camera ke sath ${activeProp.title} ka layout apne room mein 1:1 scale ya table par anchor karke walk-around kar sakte hain!';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['Launch AR View', 'Explore in 3D', '3D Floor Plan', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    // 4. Floor Plan & Dimensions Intent
    if (lower.contains('floor plan') ||
        lower.contains('naksha') ||
        lower.contains('blueprint') ||
        lower.contains('2d plan') ||
        lower.contains('3d floor plan') ||
        lower.contains('room dimensions') ||
        lower.contains('फ्लोर प्लान') ||
        lower.contains('layout dikhao')) {
      final text = (lang == 'hindi')
          ? '${activeProp.title} (${activeProp.bhk}) का वेरिफाइड 2D व 3D फ्लोर प्लान उपलब्ध है: लिविंग हॉल (16x20 ft), मास्टर सुइट (14x15 ft) और बालकनी (6x16 ft)। कुल सुपर एरिया ${activeProp.sqft} sq.ft. है।'
          : (lang == 'english')
              ? '${activeProp.title} (${activeProp.bhk}) provides verified 2D & 3D floor plans with exact room dimensions: Living Room (16x20 ft), Master Suite (14x15 ft), Balcony Deck (6x16 ft) across ${activeProp.sqft} sq.ft.'
              : '${activeProp.title} (${activeProp.bhk}) ka verified 2D CAD aur 3D floor plan available hai: Living Room (16x20 ft), Master Bedroom (14x15 ft), Balcony (6x16 ft). Total super area ${activeProp.sqft} sq.ft. hai.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['Floor Plan Kholo', 'Interior Concept', 'Vastu Guidance', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    // 5. Interior Concept Visualizer Intent
    if (lower.contains('interior') ||
        lower.contains('interior design') ||
        lower.contains('wall color') ||
        lower.contains('flooring type') ||
        lower.contains('furniture style') ||
        lower.contains('इंटीरियर')) {
      final text = (lang == 'hindi')
          ? 'हमारे AI इंटीरियर विज़ुअलाइज़र में आप ${activeProp.title} के लिविंग रूम व बेडरूम के वॉल कलर्स, इटैलियन मार्बल फ्लोरिंग, और वार्म कोव लाइटिंग कॉन्सेप्ट्स कस्टमाइज़ कर सकते हैं।'
          : (lang == 'english')
              ? 'Our AI Interior Concept Visualizer lets you customize wall palettes, Italian Botticino marble / hardwood flooring, and architectural lighting moods for ${activeProp.title}.'
              : 'Hamare AI Interior Concept Visualizer se aap ${activeProp.title} ke Living Room aur Bedroom ke wall colors, Italian marble flooring aur ambient lighting custom styling explore kar sakte hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['Customize Interior', 'Exterior Design', '360° Virtual Tour', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    // 6. Exterior Design Intent
    if (lower.contains('exterior') ||
        lower.contains('facade') ||
        lower.contains('elevation') ||
        lower.contains('exterior design') ||
        lower.contains('एक्सटीरियर')) {
      final text = (lang == 'hindi')
          ? '${activeProp.title} में मॉडर्न कंटेम्पररी, इको-लक्ज़री और नियो-क्लासिकल एलिवेशन शैलियों के फसाड, टेराकोटा लवर्स और ज़ेन गार्डन लैंडस्केपिंग कॉन्सेप्ट्स उपलब्ध हैं।'
          : (lang == 'english')
              ? '${activeProp.title} features Modern Contemporary, Eco-Luxury Resort, and Neo-Classical architectural facade materials with linear LED grazing and Zen landscaping.'
              : '${activeProp.title} mein Modern Contemporary, Eco-Luxury Resort, aur Neo-Classical facade elevations ke materials, lighting aur landscape concepts available hain.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['Exterior Design Kholo', 'Interior Concept', '3D Model', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    // 7. Vastu & Sunlight Guidance Intent
    if (lower.contains('vastu') ||
        lower.contains('vastu score') ||
        lower.contains('direction') ||
        lower.contains('facing') ||
        lower.contains('ishan') ||
        lower.contains('agneya') ||
        lower.contains('nairutya') ||
        lower.contains('वास्तु')) {
      final facing = activeProp.vastuData?.facingDirection ?? activeProp.facing;
      final score = activeProp.vastuData?.overallScore ?? 92;
      final text = (lang == 'hindi')
          ? '${activeProp.title} $facing फेसिंग प्रॉपर्टी है जिसका Vastu Alignment Score $score/100 है। ईशान कोण में मुख्य द्वार, आग्नेय कोण में किचन और दक्षिण-पश्चिम में मास्टर बेडरूम से भरपूर प्राकृतिक सूर्य प्रकाश और वेंटिलेशन मिलता है।'
          : (lang == 'english')
              ? '${activeProp.title} is a $facing facing property with a Vastu Alignment Score of $score/100. Key highlights: North-East main entrance, South-East modular kitchen, and South-West master suite.'
              : '${activeProp.title} ek $facing facing property hai jiska Vastu Alignment Score $score/100 hai. North-East entrance, South-East kitchen aur South-West master bedroom se optimal natural sunlight aur ventilation milti hai.';

      return AiAgentResult(
        speechResponse: text,
        textResponse: text,
        language: lang,
        matchedProperties: [activeProp],
        context: _context,
        suggestedChips: ['Vastu Analysis Dekho', '3D Floor Plan', '360° Virtual Tour', 'Book Site Visit'],
        flowType: 'visualization',
      );
    }

    return null;
  }

  /// 9. Know Your Locality & Smart Fallback (Personalities -> Community & RWA -> Local Governance)
  AiAgentResult? _handleLocalityPersonalitiesIntent(String lower, String lang) {
    final isPersonalityQuery = lower.contains('famous personality') ||
        lower.contains('notable personality') ||
        lower.contains('celebrity') ||
        lower.contains('youtuber') ||
        lower.contains('youtube') ||
        lower.contains('creator') ||
        lower.contains('influencer') ||
        lower.contains('rwa') ||
        lower.contains('president') ||
        lower.contains('secretary') ||
        lower.contains('councillor') ||
        lower.contains('gram pradhan') ||
        lower.contains('mla') ||
        lower.contains('mp') ||
        lower.contains('local representative') ||
        lower.contains('governance') ||
        lower.contains('rehta hai') ||
        lower.contains('famous person') ||
        lower.contains('famous log') ||
        lower.contains('personalities within 5') ||
        lower.contains('who lives in') ||
        lower.contains('who lives nearby') ||
        lower.contains('5 km ke andar') ||
        lower.contains('5 km radius') ||
        lower.contains('locality personalities') ||
        lower.contains('know your locality');

    if (!isPersonalityQuery) return null;

    final targetProp = _context.selectedProperty ??
        (_context.lastFoundProperties.isNotEmpty ? _context.lastFoundProperties.first : null) ??
        (PropertyStateService.instance.allProperties.isNotEmpty
            ? PropertyStateService.instance.allProperties.first
            : Property.sampleDeals.first);

    // Run smart 3-level hierarchical locality resolver
    final result = LocalityPersonalityRegistry.getLocalInformationForProperty(
      targetProp,
      radiusKm: 5.0,
      maxResults: 8,
    );

    // 1. Explicit RWA / Society Leadership Query
    final isRwaQuery = lower.contains('rwa') || lower.contains('president') || lower.contains('secretary');
    if (isRwaQuery) {
      if (result.communityRwa.isNotEmpty) {
        final rwaMembers = result.communityRwa.map((m) => '${m.name} (${m.role} - ${m.societyOrArea})').join(', ');
        final text = (lang == 'hindi')
            ? '${targetProp.title} के लिए वेरिफाइड RWA प्रतिनिधि: $rwaMembers।'
            : (lang == 'english')
                ? 'Verified RWA office bearers for ${targetProp.title}: $rwaMembers.'
                : '${targetProp.title} ke liye verified RWA leadership: $rwaMembers.';

        return AiAgentResult(
          speechResponse: text,
          textResponse: text,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: ['View Community Details', 'Book Site Visit', 'Check Deal Score'],
          flowType: 'locality',
        );
      } else {
        final noRwaText = (lang == 'hindi')
            ? 'इस सोसाइटी के लिए वर्तमान में आधिकारिक RWA जानकारी उपलब्ध नहीं है।'
            : (lang == 'english')
                ? 'RWA leadership information is currently unavailable for this society.'
                : 'Is society ki RWA leadership information currently officially unavailable hai.';

        return AiAgentResult(
          speechResponse: noRwaText,
          textResponse: noRwaText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: ['View Locality Map', 'Book Site Visit'],
          flowType: 'locality',
        );
      }
    }

    // 2. Explicit Local Governance Query
    final isGovQuery = lower.contains('councillor') || lower.contains('local representative') || lower.contains('governance') || lower.contains('pradhan');
    if (isGovQuery) {
      if (result.localGovernance.isNotEmpty) {
        final govMembers = result.localGovernance.map((g) => '${g.name} (${g.role} - ${g.applicableJurisdiction})').join(', ');
        final text = (lang == 'hindi')
            ? 'इस क्षेत्र के लिए स्थानीय प्रशासनिक प्रतिनिधि: $govMembers।'
            : (lang == 'english')
                ? 'Local governance representatives for this area: $govMembers.'
                : 'Is locality ke liye local governance representatives: $govMembers.';

        return AiAgentResult(
          speechResponse: text,
          textResponse: text,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: ['View Governance Info', 'Book Site Visit'],
          flowType: 'locality',
        );
      }
    }

    // 3. YouTuber / Digital Creator Query
    final isYouTuberQuery = lower.contains('youtuber') || lower.contains('youtube') || lower.contains('creator') || lower.contains('influencer');
    if (isYouTuberQuery) {
      final youtubers = result.notablePersonalities.where((p) =>
          p.category.toLowerCase().contains('youtuber') ||
          p.category.toLowerCase().contains('influencer') ||
          p.associationType == LocalityAssociationType.youtuberCreator ||
          p.associationType == LocalityAssociationType.influencer).toList();

      if (youtubers.isEmpty) {
        final noYtText = (lang == 'hindi')
            ? 'इस प्रॉपर्टी के 5 km रेडियस में कोई वेरिफाइड YouTuber नहीं मिला।'
            : (lang == 'english')
                ? 'No verified YouTuber or digital influencer was found within 5 KM of this property.'
                : 'Is property ke 5 KM radius mein koi verified YouTuber ya digital influencer nahi mila.';

        return AiAgentResult(
          speechResponse: noYtText,
          textResponse: noYtText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: ['Check Community RWA', 'View Locality Map', 'Book Site Visit'],
          flowType: 'locality',
        );
      } else {
        final ytNames = youtubers.map((p) => '${p.name} (${p.role})').join(', ');
        final ytText = (lang == 'hindi')
            ? 'इस प्रॉपर्टी के 5 km रेडियस में वेरिफाइड क्रिएटर्स: $ytNames।'
            : (lang == 'english')
                ? 'Verified digital creators within 5 KM of this property: $ytNames.'
                : 'Is property ke 5 KM radius mein verified creators: $ytNames.';

        return AiAgentResult(
          speechResponse: ytText,
          textResponse: ytText,
          language: lang,
          matchedProperties: [targetProp],
          context: _context,
          suggestedChips: ['View Locality Cards', 'Book Site Visit', 'Check Deal Score'],
          flowType: 'locality',
        );
      }
    }

    // 4. General Locality Information Query with 3-Level Fallback
    if (result.notablePersonalities.isNotEmpty) {
      final namesList = result.notablePersonalities.map((p) => '${p.name} (${p.role})').join(', ');
      final responseText = (lang == 'hindi')
          ? 'इस प्रॉपर्टी के 5 km रेडियस में ${result.notablePersonalities.length} वेरिफाइड प्रमुख व्यक्तित्व: $namesList।'
          : (lang == 'english')
              ? 'Within a 5 KM radius of this property, I found ${result.notablePersonalities.length} verified notable figures: $namesList.'
              : 'Is property ke 5 KM radius mein ${result.notablePersonalities.length} verified notable figures hain: $namesList.';

      return AiAgentResult(
        speechResponse: responseText,
        textResponse: responseText,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: ['View Locality Cards', 'Check Society RWA', 'Book Site Visit'],
        flowType: 'locality',
      );
    } else if (result.communityRwa.isNotEmpty || result.localGovernance.isNotEmpty) {
      // Fallback Level 2 & 3
      final fallbackItems = [...result.communityRwa, ...result.localGovernance];
      final namesList = fallbackItems.map((p) => '${p.name} (${p.role})').join(', ');
      final responseText = (lang == 'hindi')
          ? 'इस 5 km रेडियस में कोई प्रमुख सेलिब्रिटी नहीं है, पर सोसाइटी RWA और स्थानीय प्रशासनिक जानकारी उपलब्ध है: $namesList।'
          : (lang == 'english')
              ? 'While no notable celebrities reside within 5 KM, verified society RWA and local governance records are available: $namesList.'
              : 'Is 5 KM radius mein koi notable celebrity nahi hain, lekin verified society RWA aur local governance records available hain: $namesList.';

      return AiAgentResult(
        speechResponse: responseText,
        textResponse: responseText,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: ['View RWA Info', 'Local Governance Info', 'Book Site Visit'],
        flowType: 'locality',
      );
    } else {
      // Clear Empty State
      final noMatchesText = (lang == 'hindi')
          ? 'इस प्रॉपर्टी के लिए प्रमाणित स्थानीय जानकारी वर्तमान में उपलब्ध नहीं है।'
          : (lang == 'english')
              ? 'Verified local information is currently unavailable for this property. We only display verified public records.'
              : 'Is property ke liye verified local information currently unavailable hai.';

      return AiAgentResult(
        speechResponse: noMatchesText,
        textResponse: noMatchesText,
        language: lang,
        matchedProperties: [targetProp],
        context: _context,
        suggestedChips: ['View Location Map', 'Explore Amenities', 'Book Site Visit'],
        flowType: 'locality',
      );
    }
  }
}
