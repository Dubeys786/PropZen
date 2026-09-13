import 'crm_lead.dart';
import 'crm_follow_up.dart';
import 'crm_task.dart';
import 'crm_note.dart';

class Customer360Profile {
  final String customerId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? city;
  final DateTime? registeredAt;

  final List<CrmLead> leads;
  final List<CrmFollowUp> followups;
  final List<CrmTask> tasks;
  final List<CrmNote> notes;

  final int totalLeads;
  final int totalEnquiries;
  final int totalSiteVisits;
  final int totalServiceRequests;
  final double totalSpent;

  const Customer360Profile({
    required this.customerId,
    required this.fullName,
    this.email,
    this.phone,
    this.role,
    this.city,
    this.registeredAt,
    this.leads = const [],
    this.followups = const [],
    this.tasks = const [],
    this.notes = const [],
    this.totalLeads = 0,
    this.totalEnquiries = 0,
    this.totalSiteVisits = 0,
    this.totalServiceRequests = 0,
    this.totalSpent = 0.0,
  });

  factory Customer360Profile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    final rawLeads = json['leads'] as List? ?? [];
    final rawFollowups = json['followups'] as List? ?? [];
    final rawTasks = json['tasks'] as List? ?? [];
    final rawNotes = json['notes'] as List? ?? [];

    return Customer360Profile(
      customerId: json['customerId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Customer',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      city: json['city']?.toString(),
      registeredAt: parseDate(json['registeredAt']),
      leads: rawLeads.map((e) => CrmLead.fromJson(e as Map<String, dynamic>)).toList(),
      followups: rawFollowups.map((e) => CrmFollowUp.fromJson(e as Map<String, dynamic>)).toList(),
      tasks: rawTasks.map((e) => CrmTask.fromJson(e as Map<String, dynamic>)).toList(),
      notes: rawNotes.map((e) => CrmNote.fromJson(e as Map<String, dynamic>)).toList(),
      totalLeads: parseInt(json['totalLeads']),
      totalEnquiries: parseInt(json['totalEnquiries']),
      totalSiteVisits: parseInt(json['totalSiteVisits']),
      totalServiceRequests: parseInt(json['totalServiceRequests']),
      totalSpent: parseDouble(json['totalSpent']),
    );
  }
}
