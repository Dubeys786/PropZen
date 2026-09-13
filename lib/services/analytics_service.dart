import 'package:flutter/foundation.dart';

class TrustAnalyticsSnapshot {
  final int totalPropertyViews;
  final int totalVerificationViews;
  final int totalExploreAreaClicks;
  final int totalEnquiries;
  final int totalWhatsAppConversions;
  final int totalSiteVisitsBooked;
  final double verificationCompletionRate; // e.g. 94.2%
  final double propertyToEnquiryConversion; // e.g. 8.4%
  final double locationResolutionSuccessRate; // e.g. 99.1%

  const TrustAnalyticsSnapshot({
    required this.totalPropertyViews,
    required this.totalVerificationViews,
    required this.totalExploreAreaClicks,
    required this.totalEnquiries,
    required this.totalWhatsAppConversions,
    required this.totalSiteVisitsBooked,
    required this.verificationCompletionRate,
    required this.propertyToEnquiryConversion,
    required this.locationResolutionSuccessRate,
  });
}

class AnalyticsService extends ChangeNotifier {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();
  factory AnalyticsService() => instance;

  int _propertyViews = 1240;
  int _verificationViews = 840;
  int _exploreAreaClicks = 620;
  int _enquiries = 145;
  int _whatsappConversions = 112;
  int _siteVisits = 48;

  int get propertyViews => _propertyViews;
  int get verificationViews => _verificationViews;
  int get exploreAreaClicks => _exploreAreaClicks;
  int get enquiries => _enquiries;
  int get whatsappConversions => _whatsappConversions;
  int get siteVisits => _siteVisits;

  void trackPropertyView(String propertyId) {
    _propertyViews++;
    notifyListeners();
  }

  void trackVerificationView(String propertyId, String verificationType) {
    _verificationViews++;
    notifyListeners();
  }

  void trackExploreAreaClick(String propertyId, String pincode) {
    _exploreAreaClicks++;
    notifyListeners();
  }

  void trackEnquiryClick(String propertyId) {
    _enquiries++;
    notifyListeners();
  }

  void trackWhatsAppConversion(String leadId) {
    _whatsappConversions++;
    notifyListeners();
  }

  void trackSiteVisitBooked(String propertyId) {
    _siteVisits++;
    notifyListeners();
  }

  TrustAnalyticsSnapshot getSnapshot() {
    final enquiryConversion = _propertyViews > 0 ? (_enquiries / _propertyViews) * 100 : 0.0;
    return TrustAnalyticsSnapshot(
      totalPropertyViews: _propertyViews,
      totalVerificationViews: _verificationViews,
      totalExploreAreaClicks: _exploreAreaClicks,
      totalEnquiries: _enquiries,
      totalWhatsAppConversions: _whatsappConversions,
      totalSiteVisitsBooked: _siteVisits,
      verificationCompletionRate: 94.8,
      propertyToEnquiryConversion: enquiryConversion,
      locationResolutionSuccessRate: 99.4,
    );
  }
}
