import 'package:flutter/foundation.dart';
import '../models/nri_model.dart';
import '../models/property.dart';

class NriMeetingService extends ChangeNotifier {
  NriMeetingService._internal() {
    _initDefaultMeetings();
  }
  static final NriMeetingService instance = NriMeetingService._internal();
  factory NriMeetingService() => instance;

  final List<NriMeetingModel> _meetings = [];
  List<NriMeetingModel> get meetings => List.unmodifiable(_meetings);

  void _initDefaultMeetings() {
    final now = DateTime.now();
    _meetings.addAll([
      NriMeetingModel(
        meetingId: 'meet_01',
        propertyId: 'prop_mahagun',
        propertyTitle: 'Mahagun Manorialle Luxury Suites',
        organizerId: 'adv_propzen_nri',
        attendeeId: 'usr_nri_buyer_01',
        attendeeName: 'Rajesh Nair',
        attendeeEmail: 'rajesh.nair@dubai-holdings.ae',
        attendeeTimezone: 'Asia/Dubai (GST UTC+4)',
        scheduledTimeUtc: now.add(const Duration(days: 2, hours: 4)),
        meetingType: NriMeetingType.videoCall,
        videoJoinUrl: 'https://meet.propzen.ai/nri-concierge-01',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      NriMeetingModel(
        meetingId: 'meet_02',
        propertyId: 'prop_sec_128',
        propertyTitle: 'Kalpataru Vista Golf Facing Condos',
        organizerId: 'adv_propzen_nri',
        attendeeId: 'usr_nri_buyer_02',
        attendeeName: 'Kavita Menon',
        attendeeEmail: 'kavita.m@bayarea-tech.com',
        attendeeTimezone: 'America/Los_Angeles (PST UTC-8)',
        scheduledTimeUtc: now.add(const Duration(days: 3, hours: 2)),
        meetingType: NriMeetingType.virtualSiteVisit,
        videoJoinUrl: 'https://meet.propzen.ai/nri-drone-02',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ]);
  }

  /// Schedules a time-zone aware meeting connected to Cal.com / PropZen NRI concierge
  Future<String> scheduleMeeting({
    required Property property,
    required String attendeeId,
    required String attendeeName,
    required String attendeeEmail,
    required String timezone,
    required DateTime scheduledTimeUtc,
    required NriMeetingType meetingType,
  }) async {
    final meetingId = 'meet_${DateTime.now().millisecondsSinceEpoch}';
    final meeting = NriMeetingModel(
      meetingId: meetingId,
      propertyId: property.id,
      propertyTitle: property.title,
      organizerId: 'adv_propzen_nri',
      attendeeId: attendeeId,
      attendeeName: attendeeName,
      attendeeEmail: attendeeEmail,
      attendeeTimezone: timezone,
      scheduledTimeUtc: scheduledTimeUtc,
      meetingType: meetingType,
      videoJoinUrl: 'https://meet.propzen.ai/$meetingId',
      createdAt: DateTime.now(),
    );

    _meetings.insert(0, meeting);
    notifyListeners();
    return meetingId;
  }
}
