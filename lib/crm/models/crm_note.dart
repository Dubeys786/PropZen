/// Internal CRM note associated with a lead
class CrmNote {
  final String id;
  final String leadId;
  final String? createdById;
  final String? createdByName;
  final String content;
  final bool isPinned;
  final DateTime createdAt;

  const CrmNote({
    required this.id,
    required this.leadId,
    this.createdById,
    this.createdByName,
    required this.content,
    this.isPinned = false,
    required this.createdAt,
  });

  factory CrmNote.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return CrmNote(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      createdById: json['createdById']?.toString(),
      createdByName: json['createdByName']?.toString(),
      content: json['content']?.toString() ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadId': leadId,
        'createdById': createdById,
        'createdByName': createdByName,
        'content': content,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
      };
}
