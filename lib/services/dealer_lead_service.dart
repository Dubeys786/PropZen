import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lead_model.dart';
import '../models/site_visit_model.dart';
import '../models/dealer_notification_model.dart';
import '../models/property.dart';
import 'razorpay_checkout_service.dart';
import 'property_state_service.dart';

class DealerAnalyticsData {
  final int totalProperties;
  final int activeListings;
  final int pendingProperties;
  final int totalViews;
  final int totalEnquiries;
  final int totalLeads;
  final int qualifiedLeads;
  final int siteVisitsCount;
  final int completedSiteVisits;
  final int conversionsCount;
  final double leadConversionRate;
  final double siteVisitConversionRate;
  final List<Property> topProperties;

  const DealerAnalyticsData({
    required this.totalProperties,
    required this.activeListings,
    required this.pendingProperties,
    required this.totalViews,
    required this.totalEnquiries,
    required this.totalLeads,
    required this.qualifiedLeads,
    required this.siteVisitsCount,
    required this.completedSiteVisits,
    required this.conversionsCount,
    required this.leadConversionRate,
    required this.siteVisitConversionRate,
    required this.topProperties,
  });
}

class DealerLeadService extends ChangeNotifier {
  DealerLeadService._internal();

  static final DealerLeadService instance = DealerLeadService._internal();

  final List<DealerLead> _leads = [];
  final List<DealerSiteVisit> _siteVisits = [];
  final List<DealerNotification> _notifications = [];

  List<DealerLead> get allLeads => List.unmodifiable(_leads);
  List<DealerSiteVisit> get allSiteVisits => List.unmodifiable(_siteVisits);
  List<DealerNotification> get allNotifications => List.unmodifiable(_notifications);

  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  void initializeSampleLeads({bool enableMockFallback = false}) {
    _initSampleData(enableSampleFallback: enableMockFallback);
  }

  /// Get leads strictly filtered by dealerId (Tenant Isolation)
  List<DealerLead> getLeadsForDealer(String dealerId) {
    if (dealerId.isEmpty) return const [];
    return _leads.where((l) => l.dealerId == dealerId).toList();
  }

  /// Get site visits strictly filtered by dealerId (Tenant Isolation)
  List<DealerSiteVisit> getSiteVisitsForDealer(String dealerId) {
    if (dealerId.isEmpty) return const [];
    return _siteVisits.where((v) => v.dealerId == dealerId).toList();
  }

  /// Get notifications strictly filtered by dealerId (Tenant Isolation)
  List<DealerNotification> getNotificationsForDealer(String dealerId) {
    if (dealerId.isEmpty) return const [];
    return _notifications.where((n) => n.dealerId == dealerId).toList();
  }

  /// Calculate real performance analytics for dealer
  DealerAnalyticsData getAnalyticsForDealer(String dealerId) {
    return computeAnalyticsForDealer(dealerId);
  }

  // =========================================================================
  // LEAD PIPELINE ACTIONS
  // =========================================================================

  /// Buyer submits Enquiry -> creates Lead & sends Dealer Notification
  Future<DealerLead> createLeadFromEnquiry({
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    required Property property,
    String? requirement,
    String? message,
  }) async {
    final leadId = 'LEAD-${DateTime.now().millisecondsSinceEpoch}';
    final targetPrice = property.askingPriceCr > 0 ? property.askingPriceCr : 1.5;

    final newLead = DealerLead(
      id: leadId,
      dealerId: property.dealerId,
      buyerId: buyerId,
      buyerName: buyerName.isNotEmpty ? buyerName : 'Verified Buyer',
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      requirement: requirement ?? '${property.bhk} in ${property.effectiveLocality}',
      budgetCr: targetPrice,
      preferredLocation: property.effectiveLocality,
      propertyId: property.id,
      propertyTitle: property.title,
      enquiryStatus: 'New',
      leadScore: 82,
      scoreTier: LeadScoreTier.hot,
      notes: message != null && message.isNotEmpty ? ['Initial enquiry: "$message"'] : ['Enquiry submitted via PropZen Mobile App'],
      lastActivity: 'Submitted enquiry on ${property.title}',
      lastActivityTime: DateTime.now(),
    );

    _leads.insert(0, newLead);

    // Send Dealer Notification
    sendNotification(
      dealerId: newLead.dealerId,
      type: DealerNotificationType.newEnquiry,
      title: 'New Enquiry: ${property.title} 📩',
      message: '${newLead.buyerName} submitted an enquiry for ${property.title} (${property.formattedPrice}).',
      propertyId: property.id,
      propertyTitle: property.title,
      leadId: newLead.id,
    );

    notifyListeners();
    return newLead;
  }

  /// Dealer updates lead status in pipeline
  void updateLeadStatus({
    required String leadId,
    required String newStatus,
    String? note,
  }) {
    final idx = _leads.indexWhere((l) => l.id == leadId);
    if (idx != -1) {
      final current = _leads[idx];
      final updatedNotes = List<String>.from(current.notes);
      if (note != null && note.isNotEmpty) {
        updatedNotes.insert(0, '[${DateTime.now().hour}:${DateTime.now().minute}] $note');
      } else {
        updatedNotes.insert(0, 'Status moved to $newStatus');
      }

      _leads[idx] = current.copyWith(
        enquiryStatus: newStatus,
        notes: updatedNotes,
        lastActivity: 'Status updated to $newStatus',
        lastActivityTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // =========================================================================
  // SITE VISIT ACTIONS
  // =========================================================================

  /// Buyer books a Site Visit -> linked to Dealer with Notification
  Future<DealerSiteVisit> bookSiteVisit({
    required Property property,
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required String buyerEmail,
    required String scheduledDate,
    required String scheduledTime,
    int visitorCount = 1,
    bool cabRequired = false,
    String? pickupLocation,
    String? notes,
  }) async {
    final visitId = 'VISIT-${DateTime.now().millisecondsSinceEpoch}';
    final targetDealerId = property.dealerId;

    final newVisit = DealerSiteVisit(
      id: visitId,
      propertyId: property.id,
      propertyTitle: property.title,
      propertySector: property.effectiveLocality,
      buyerId: buyerId,
      buyerName: buyerName.isNotEmpty ? buyerName : 'Verified Visitor',
      buyerPhone: buyerPhone,
      buyerEmail: buyerEmail,
      dealerId: targetDealerId,
      dealerName: property.dealerName.isNotEmpty ? property.dealerName : 'Verified Dealer',
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      visitorCount: visitorCount,
      cabRequired: cabRequired,
      pickupLocation: pickupLocation,
      notes: notes,
      status: SiteVisitStatus.requested,
      createdAt: DateTime.now(),
    );

    _siteVisits.insert(0, newVisit);

    // Also link or update lead in pipeline
    final existingLeadIdx = _leads.indexWhere((l) => l.buyerPhone == buyerPhone && l.propertyId == property.id);
    if (existingLeadIdx != -1) {
      _leads[existingLeadIdx] = _leads[existingLeadIdx].copyWith(
        enquiryStatus: 'Site Visit',
        siteVisitStatus: 'Requested',
        lastActivity: 'Site visit booked for $scheduledDate at $scheduledTime',
        lastActivityTime: DateTime.now(),
      );
    } else {
      _leads.insert(
        0,
        DealerLead(
          id: 'LEAD-VISIT-${DateTime.now().millisecondsSinceEpoch}',
          dealerId: targetDealerId,
          buyerId: buyerId,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
          buyerEmail: buyerEmail,
          requirement: property.title,
          budgetCr: property.askingPriceCr > 0 ? property.askingPriceCr : 1.5,
          preferredLocation: property.effectiveLocality,
          propertyId: property.id,
          propertyTitle: property.title,
          enquiryStatus: 'Site Visit',
          siteVisitStatus: 'Requested',
          leadScore: 92,
          scoreTier: LeadScoreTier.hot,
          notes: ['Site visit scheduled for $scheduledDate at $scheduledTime (Cab: ${cabRequired ? "Yes" : "No"})'],
          lastActivity: 'Booked site visit for $scheduledDate',
          lastActivityTime: DateTime.now(),
        ),
      );
    }

    // Send Dealer Notification
    sendNotification(
      dealerId: targetDealerId,
      type: DealerNotificationType.newSiteVisit,
      title: 'New Site Visit Request! 📅',
      message: '$buyerName requested a site visit for ${property.title} on $scheduledDate at $scheduledTime.',
      propertyId: property.id,
      propertyTitle: property.title,
      siteVisitId: visitId,
    );

    notifyListeners();
    return newVisit;
  }

  /// Dealer confirms, reschedules, or cancels site visit
  void updateSiteVisitStatus({
    required String visitId,
    required SiteVisitStatus newStatus,
    String? note,
  }) {
    final idx = _siteVisits.indexWhere((v) => v.id == visitId);
    if (idx != -1) {
      final current = _siteVisits[idx];
      _siteVisits[idx] = current.copyWith(
        status: newStatus,
        notes: note != null ? '${current.notes ?? ""}\n$note' : current.notes,
        updatedAt: DateTime.now(),
      );

      // Trigger notification
      if (newStatus == SiteVisitStatus.confirmed) {
        sendNotification(
          dealerId: current.dealerId,
          type: DealerNotificationType.siteVisitConfirmed,
          title: 'Site Visit Confirmed ✅',
          message: 'Site visit for ${current.buyerName} at ${current.propertyTitle} confirmed for ${current.scheduledDate}.',
          propertyId: current.propertyId,
          propertyTitle: current.propertyTitle,
          siteVisitId: visitId,
        );
      } else if (newStatus == SiteVisitStatus.cancelled) {
        sendNotification(
          dealerId: current.dealerId,
          type: DealerNotificationType.siteVisitCancelled,
          title: 'Site Visit Cancelled ❌',
          message: 'Site visit for ${current.buyerName} was cancelled.',
          propertyId: current.propertyId,
          propertyTitle: current.propertyTitle,
          siteVisitId: visitId,
        );
      }

      notifyListeners();
    }
  }

  // =========================================================================
  // NOTIFICATIONS SYSTEM
  // =========================================================================

  void sendNotification({
    required String dealerId,
    required DealerNotificationType type,
    required String title,
    required String message,
    String? propertyId,
    String? propertyTitle,
    String? leadId,
    String? siteVisitId,
    Map<String, dynamic>? metadata,
  }) {
    final notif = DealerNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      dealerId: dealerId,
      type: type,
      title: title,
      message: message,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      leadId: leadId,
      siteVisitId: siteVisitId,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notif);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].markAsRead();
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead(String dealerId) {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].dealerId == dealerId && !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].markAsRead();
      }
    }
    notifyListeners();
  }

  // =========================================================================
  // COMPUTED REAL ANALYTICS
  // =========================================================================

  DealerAnalyticsData computeAnalyticsForDealer(String dealerId) {
    final stateProps = PropertyStateService.instance.dealerProperties;
    final dealerProps = stateProps.where((p) => p['dealerId'] == dealerId || p['dealer_id'] == dealerId).toList();
    
    final activeProps = dealerProps.where((p) => (p['status'] == 'published' || p['status'] == 'approved')).length;
    final pendingProps = dealerProps.where((p) => (p['status'] == 'pending' || p['status'] == 'under_review')).length;

    final dealerLeadsList = getLeadsForDealer(dealerId);
    final dealerVisitsList = getSiteVisitsForDealer(dealerId);

    final totalLeads = dealerLeadsList.length;
    final qualifiedLeads = dealerLeadsList.where((l) => l.isQualified || l.isSiteVisit || l.isNegotiation || l.isConverted).length;
    final conversions = dealerLeadsList.where((l) => l.isConverted).length;
    final totalVisits = dealerVisitsList.length;
    final completedVisits = dealerVisitsList.where((v) => v.isCompleted).length;

    // Real computations
    final leadConvRate = totalLeads > 0 ? ((conversions / totalLeads) * 100.0) : 0.0;
    final visitConvRate = totalVisits > 0 ? ((conversions / totalVisits) * 100.0) : 0.0;

    // Calculate total real property views
    int totalViews = 0;
    for (final raw in dealerProps) {
      final v = (raw['viewsCount'] as num?)?.toInt() ?? (raw['views_count'] as num?)?.toInt() ?? (raw['views'] as num?)?.toInt() ?? 0;
      totalViews += v;
    }

    // Build real top property objects
    final topPropertyList = <Property>[];
    for (final raw in dealerProps) {
      topPropertyList.add(Property.fromMap(raw));
    }

    return DealerAnalyticsData(
      totalProperties: dealerProps.length,
      activeListings: activeProps,
      pendingProperties: pendingProps,
      totalViews: totalViews,
      totalEnquiries: totalLeads,
      totalLeads: totalLeads,
      qualifiedLeads: qualifiedLeads,
      siteVisitsCount: totalVisits,
      completedSiteVisits: completedVisits,
      conversionsCount: conversions,
      leadConversionRate: leadConvRate,
      siteVisitConversionRate: visitConvRate,
      topProperties: topPropertyList,
    );
  }

  // =========================================================================
  // SAMPLE DATA INITIALIZATION
  // =========================================================================

  void _initSampleData({bool enableSampleFallback = false}) {
    _leads.clear();
    _siteVisits.clear();
    _notifications.clear();

    if (!enableSampleFallback) {
      // Production mode: zero fake data
      return;
    }

    // Initial leads for default dealer
    _leads.addAll(List.from(DealerLead.initialSampleLeads));

    // Initial site visits
    _siteVisits.addAll([
      DealerSiteVisit(
        id: 'VISIT-001',
        propertyId: 'PROP-001',
        propertyTitle: 'ATS Knightsbridge Ultra Luxury 4 BHK',
        propertySector: 'Sector 124, Noida Expressway',
        buyerId: 'usr_rahul',
        buyerName: 'Rahul Mehra',
        buyerPhone: '+91 98103 45678',
        buyerEmail: 'rahul.mehra@gmail.com',
        dealerId: 'DLR-NOIDA-101',
        dealerName: 'Rajesh Varma',
        scheduledDate: 'Tomorrow, 30 Aug',
        scheduledTime: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
        pickupLocation: 'Botanical Garden Metro',
        status: SiteVisitStatus.requested,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      DealerSiteVisit(
        id: 'VISIT-002',
        propertyId: 'PROP-002',
        propertyTitle: 'Godrej Palm Retreat Resort Residences',
        propertySector: 'Sector 150, Noida',
        buyerId: 'usr_priya',
        buyerName: 'Dr. Priya Singhal',
        buyerPhone: '+91 99201 88344',
        buyerEmail: 'priya.singhal@apollo.org',
        dealerId: 'DLR-NOIDA-101',
        dealerName: 'Rajesh Varma',
        scheduledDate: 'Sunday, 31 Aug',
        scheduledTime: '03:30 PM',
        visitorCount: 3,
        cabRequired: false,
        status: SiteVisitStatus.confirmed,
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
      ),
    ]);

    // Initial notifications
    _notifications.addAll([
      DealerNotification(
        id: 'notif_init_1',
        dealerId: 'DLR-NOIDA-101',
        type: DealerNotificationType.newLead,
        title: '🔥 Hot Lead Assigned: Rahul Mehra',
        message: 'Rahul Mehra (Score 92%) submitted an inquiry for ATS Knightsbridge 4 BHK.',
        propertyId: 'PROP-001',
        propertyTitle: 'ATS Knightsbridge',
        leadId: 'LEAD-001',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      DealerNotification(
        id: 'notif_init_2',
        dealerId: 'DLR-NOIDA-101',
        type: DealerNotificationType.newSiteVisit,
        title: 'New Site Visit Request 📅',
        message: 'Dr. Priya Singhal requested a site visit for Godrej Palm Retreat on Sunday.',
        propertyId: 'PROP-002',
        propertyTitle: 'Godrej Palm Retreat',
        siteVisitId: 'VISIT-002',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      DealerNotification(
        id: 'notif_init_3',
        dealerId: 'DLR-NOIDA-101',
        type: DealerNotificationType.propertyApproved,
        title: 'Property Approved & Live! 🎉',
        message: 'Your listing "Eldeco Live Greens Resort Residences" has been verified and published by PropZen Admin.',
        propertyId: 'PROP-003',
        propertyTitle: 'Eldeco Live Greens',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);
  }
}
