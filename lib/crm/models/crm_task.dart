import 'package:flutter/material.dart';

enum TaskStatus {
  todo('TODO', 'To Do', Color(0xFF64748B)),
  inProgress('IN_PROGRESS', 'In Progress', Color(0xFF3B82F6)),
  completed('COMPLETED', 'Completed', Color(0xFF10B981)),
  cancelled('CANCELLED', 'Cancelled', Color(0xFF94A3B8)),
  overdue('OVERDUE', 'Overdue', Color(0xFFEF4444));

  final String code;
  final String label;
  final Color color;

  const TaskStatus(this.code, this.label, this.color);

  static TaskStatus fromString(String? val) {
    if (val == null) return TaskStatus.todo;
    final clean = val.toUpperCase().trim();
    for (final s in TaskStatus.values) {
      if (s.code == clean || s.name.toUpperCase() == clean) return s;
    }
    return TaskStatus.todo;
  }
}

class CrmTask {
  final String id;
  final String? leadId;
  final String? assignedTo;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const CrmTask({
    required this.id,
    this.leadId,
    this.assignedTo,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'MEDIUM',
    this.status = TaskStatus.todo,
    this.completedAt,
    this.createdAt,
  });

  bool get isCompleted => status == TaskStatus.completed;

  factory CrmTask.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return null;
      }
    }

    return CrmTask(
      id: json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString(),
      assignedTo: json['assignedTo']?.toString(),
      title: json['title']?.toString() ?? 'Task',
      description: json['description']?.toString(),
      dueDate: parseDate(json['dueDate']),
      priority: json['priority']?.toString() ?? 'MEDIUM',
      status: TaskStatus.fromString(json['status']?.toString()),
      completedAt: parseDate(json['completedAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadId': leadId,
        'assignedTo': assignedTo,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'status': status.code,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
