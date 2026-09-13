import 'package:flutter/foundation.dart';

enum NriMeetingType {
  videoCall,
  dealerCall,
  legalConsultation,
  propertyConsultation,
  virtualSiteVisit;

  String get displayName {
    switch (this) {
      case NriMeetingType.videoCall:
        return 'NRI Video Conference';
      case NriMeetingType.dealerCall:
        return 'Direct Dealer Phone Call';
      case NriMeetingType.legalConsultation:
        return 'Legal & Title Consultation';
      case NriMeetingType.propertyConsultation:
        return 'Property Advisory Session';
      case NriMeetingType.virtualSiteVisit:
        return 'Live 360 Drone / Virtual Tour';
    }
  }
}

class NriMeetingModel {
  final String meetingId;
  final String propertyId;
  final String propertyTitle;
  final String organizerId;
  final String attendeeId;
  final String attendeeName;
  final String attendeeEmail;
  final String attendeeTimezone; // e.g. 'America/New_York', 'Asia/Dubai', 'Europe/London'
  final DateTime scheduledTimeUtc;
  final NriMeetingType meetingType;
  final String status; // SCHEDULED, CONFIRMED, COMPLETED, CANCELLED
  final String? calComBookingId;
  final String? videoJoinUrl;
  final DateTime createdAt;

  const NriMeetingModel({
    required this.meetingId,
    required this.propertyId,
    required this.propertyTitle,
    required this.organizerId,
    required this.attendeeId,
    required this.attendeeName,
    required this.attendeeEmail,
    required this.attendeeTimezone,
    required this.scheduledTimeUtc,
    required this.meetingType,
    this.status = 'CONFIRMED',
    this.calComBookingId,
    this.videoJoinUrl,
    required this.createdAt,
  });

  factory NriMeetingModel.fromMap(Map<String, dynamic> map, String id) {
    return NriMeetingModel(
      meetingId: id,
      propertyId: map['propertyId']?.toString() ?? '',
      propertyTitle: map['propertyTitle']?.toString() ?? 'Property Consultation',
      organizerId: map['organizerId']?.toString() ?? 'adv_propzen_nri',
      attendeeId: map['attendeeId']?.toString() ?? '',
      attendeeName: map['attendeeName']?.toString() ?? 'NRI Buyer',
      attendeeEmail: map['attendeeEmail']?.toString() ?? '',
      attendeeTimezone: map['attendeeTimezone']?.toString() ?? 'Asia/Dubai',
      scheduledTimeUtc: DateTime.tryParse(map['scheduledTimeUtc']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 2)),
      meetingType: NriMeetingType.values.firstWhere(
        (t) => t.name == map['meetingType'],
        orElse: () => NriMeetingType.videoCall,
      ),
      status: map['status']?.toString() ?? 'CONFIRMED',
      calComBookingId: map['calComBookingId']?.toString(),
      videoJoinUrl: map['videoJoinUrl']?.toString() ?? 'https://meet.propzen.ai/nri-concierge-01',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'meetingId': meetingId,
        'propertyId': propertyId,
        'propertyTitle': propertyTitle,
        'organizerId': organizerId,
        'attendeeId': attendeeId,
        'attendeeName': attendeeName,
        'attendeeEmail': attendeeEmail,
        'attendeeTimezone': attendeeTimezone,
        'scheduledTimeUtc': scheduledTimeUtc.toIso8601String(),
        'meetingType': meetingType.name,
        'status': status,
        'calComBookingId': calComBookingId,
        'videoJoinUrl': videoJoinUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}

class CurrencyRateModel {
  final String code; // USD, GBP, EUR, AED, CAD, AUD, SGD, INR
  final String name;
  final String symbol;
  final double inrRate; // 1 Code = X INR
  final DateTime lastUpdatedAt;

  const CurrencyRateModel({
    required this.code,
    required this.name,
    required this.symbol,
    required this.inrRate,
    required this.lastUpdatedAt,
  });
}
