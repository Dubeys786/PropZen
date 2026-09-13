import 'package:flutter/foundation.dart';

/// Component Health Status
enum HealthStatus {
  healthy,
  degraded,
  down,
  notConfigured,
}

extension HealthStatusExt on HealthStatus {
  String get displayName {
    switch (this) {
      case HealthStatus.healthy:
        return 'HEALTHY';
      case HealthStatus.degraded:
        return 'DEGRADED';
      case HealthStatus.down:
        return 'DOWN';
      case HealthStatus.notConfigured:
        return 'NOT CONFIGURED';
    }
  }

  String get badgeLabel {
    switch (this) {
      case HealthStatus.healthy:
        return '🟢 Healthy';
      case HealthStatus.degraded:
        return '🟡 Degraded';
      case HealthStatus.down:
        return '🔴 Down';
      case HealthStatus.notConfigured:
        return '⚪ Not Configured';
    }
  }
}

/// Latency Performance Tier
enum LatencyTier {
  fast,     // < 300ms
  normal,   // 300 - 800ms
  slow,     // 800 - 2000ms
  critical, // > 2000ms
}

extension LatencyTierExt on LatencyTier {
  String get displayName {
    switch (this) {
      case LatencyTier.fast:
        return 'FAST (< 300ms)';
      case LatencyTier.normal:
        return 'NORMAL (300-800ms)';
      case LatencyTier.slow:
        return 'SLOW (800-2000ms)';
      case LatencyTier.critical:
        return 'CRITICAL (> 2000ms)';
    }
  }
}

/// Individual Component Health Check
class ComponentHealthCheck {
  final String id;
  final String name;
  final String category; // Database, Auth, Storage, API, Media, YouTube, Notification, BackgroundJobs, Security
  final HealthStatus status;
  final int latencyMs;
  final DateTime lastCheckedAt;
  final int failureCount;
  final String? message;
  final bool isConfigured;
  final LatencyTier latencyTier;

  const ComponentHealthCheck({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.latencyMs,
    required this.lastCheckedAt,
    this.failureCount = 0,
    this.message,
    this.isConfigured = true,
    required this.latencyTier,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'status': status.name,
        'latency_ms': latencyMs,
        'last_checked_at': lastCheckedAt.toIso8601String(),
        'failure_count': failureCount,
        'message': message,
        'is_configured': isConfigured,
        'latency_tier': latencyTier.name,
      };

  factory ComponentHealthCheck.fromMap(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'healthy';
    final status = HealthStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => HealthStatus.healthy,
    );

    final tierStr = map['latency_tier'] as String? ?? 'fast';
    final tier = LatencyTier.values.firstWhere(
      (e) => e.name == tierStr,
      orElse: () => LatencyTier.fast,
    );

    return ComponentHealthCheck(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      status: status,
      latencyMs: (map['latency_ms'] as num?)?.toInt() ?? 0,
      lastCheckedAt: map['last_checked_at'] != null ? DateTime.parse(map['last_checked_at']) : DateTime.now(),
      failureCount: (map['failure_count'] as num?)?.toInt() ?? 0,
      message: map['message'] as String?,
      isConfigured: map['is_configured'] as bool? ?? true,
      latencyTier: tier,
    );
  }
}

/// Point Deduction for Transparent Health Scoring
class HealthScoreDeduction {
  final String category;
  final int pointsDeducted;
  final String reason;
  final String recommendedAction;

  const HealthScoreDeduction({
    required this.category,
    required this.pointsDeducted,
    required this.reason,
    required this.recommendedAction,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'points_deducted': pointsDeducted,
        'reason': reason,
        'recommended_action': recommendedAction,
      };
}

/// Transparent System Health Score
class SystemHealthScore {
  final int overallScore; // 0 - 100
  final String healthGrade; // 'Optimal', 'Good', 'Degraded', 'Critical'
  final Map<String, int> categoryScores;
  final List<HealthScoreDeduction> deductions;
  final DateTime calculatedAt;

  const SystemHealthScore({
    required this.overallScore,
    required this.healthGrade,
    required this.categoryScores,
    required this.deductions,
    required this.calculatedAt,
  });

  Map<String, dynamic> toMap() => {
        'overall_score': overallScore,
        'health_grade': healthGrade,
        'category_scores': categoryScores,
        'deductions': deductions.map((d) => d.toMap()).toList(),
        'calculated_at': calculatedAt.toIso8601String(),
      };
}

/// Grouped Production Error Model
class TrackedErrorGroup {
  final String errorFingerprint; // Hash of error type + normalized message
  final String errorType;
  final String severity; // 'info', 'low', 'medium', 'high', 'critical'
  final String message;
  final String pageOrService;
  final int occurrences;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String status; // 'active', 'investigating', 'resolved'
  final String? stackSnippet;

  const TrackedErrorGroup({
    required this.errorFingerprint,
    required this.errorType,
    required this.severity,
    required this.message,
    required this.pageOrService,
    required this.occurrences,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.status = 'active',
    this.stackSnippet,
  });

  TrackedErrorGroup copyWith({
    int? occurrences,
    DateTime? lastSeenAt,
    String? status,
  }) {
    return TrackedErrorGroup(
      errorFingerprint: errorFingerprint,
      errorType: errorType,
      severity: severity,
      message: message,
      pageOrService: pageOrService,
      occurrences: occurrences ?? this.occurrences,
      firstSeenAt: firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      status: status ?? this.status,
      stackSnippet: stackSnippet,
    );
  }

  Map<String, dynamic> toMap() => {
        'error_fingerprint': errorFingerprint,
        'error_type': errorType,
        'severity': severity,
        'message': message,
        'page_or_service': pageOrService,
        'occurrences': occurrences,
        'first_seen_at': firstSeenAt.toIso8601String(),
        'last_seen_at': lastSeenAt.toIso8601String(),
        'status': status,
        'stack_snippet': stackSnippet,
      };

  factory TrackedErrorGroup.fromMap(Map<String, dynamic> map) => TrackedErrorGroup(
        errorFingerprint: map['error_fingerprint'] as String? ?? '',
        errorType: map['error_type'] as String? ?? 'GeneralError',
        severity: map['severity'] as String? ?? 'medium',
        message: map['message'] as String? ?? '',
        pageOrService: map['page_or_service'] as String? ?? 'app',
        occurrences: (map['occurrences'] as num?)?.toInt() ?? 1,
        firstSeenAt: map['first_seen_at'] != null ? DateTime.parse(map['first_seen_at']) : DateTime.now(),
        lastSeenAt: map['last_seen_at'] != null ? DateTime.parse(map['last_seen_at']) : DateTime.now(),
        status: map['status'] as String? ?? 'active',
        stackSnippet: map['stack_snippet'] as String?,
      );
}

/// Synthetic Health Check Result
class SyntheticCheckResult {
  final String checkId;
  final String name;
  final String targetEndpoint;
  final bool passed;
  final int latencyMs;
  final DateTime executedAt;
  final String details;

  const SyntheticCheckResult({
    required this.checkId,
    required this.name,
    required this.targetEndpoint,
    required this.passed,
    required this.latencyMs,
    required this.executedAt,
    required this.details,
  });

  Map<String, dynamic> toMap() => {
        'check_id': checkId,
        'name': name,
        'target_endpoint': targetEndpoint,
        'passed': passed,
        'latency_ms': latencyMs,
        'executed_at': executedAt.toIso8601String(),
        'details': details,
      };
}

/// Background Job Item
class BackgroundJobItem {
  final String jobId;
  final String jobType; // 'media_optimization', 'ai_scoring', 'orphan_cleanup', 'backup_sync', 'notification_dispatch'
  final String status; // 'queued', 'running', 'completed', 'failed'
  final int progressPercent;
  final int retryCount;
  final int maxRetries;
  final String? targetEntityId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const BackgroundJobItem({
    required this.jobId,
    required this.jobType,
    required this.status,
    this.progressPercent = 0,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.targetEntityId,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  BackgroundJobItem copyWith({
    String? status,
    int? progressPercent,
    int? retryCount,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return BackgroundJobItem(
      jobId: jobId,
      jobType: jobType,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
      targetEntityId: targetEntityId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() => {
        'job_id': jobId,
        'job_type': jobType,
        'status': status,
        'progress_percent': progressPercent,
        'retry_count': retryCount,
        'max_retries': maxRetries,
        'target_entity_id': targetEntityId,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'error_message': errorMessage,
      };
}

/// Controlled Maintenance Mode State
enum MaintenanceModeType {
  off,
  readOnly,
  limited,
  full,
}

class MaintenanceModeConfig {
  final MaintenanceModeType mode;
  final bool isEnabled;
  final String? enabledBy;
  final DateTime? enabledAt;
  final String reason;
  final bool allowAdminBypass;
  final bool allowPublicBrowsing;
  final bool allowNewSubmissions;

  const MaintenanceModeConfig({
    this.mode = MaintenanceModeType.off,
    this.isEnabled = false,
    this.enabledBy,
    this.enabledAt,
    this.reason = 'System running in standard operational mode.',
    this.allowAdminBypass = true,
    this.allowPublicBrowsing = true,
    this.allowNewSubmissions = true,
  });

  Map<String, dynamic> toMap() => {
        'mode': mode.name,
        'is_enabled': isEnabled,
        'enabled_by': enabledBy,
        'enabled_at': enabledAt?.toIso8601String(),
        'reason': reason,
        'allow_admin_bypass': allowAdminBypass,
        'allow_public_browsing': allowPublicBrowsing,
        'allow_new_submissions': allowNewSubmissions,
      };
}

/// Application Version & Deployment Metadata
class AppVersionInfo {
  final String currentVersion;
  final String previousStableVersion;
  final String buildNumber;
  final DateTime releaseDate;
  final String deploymentStatus; // 'Live / Healthy', 'Rollback Ready', 'Building'
  final String environment; // 'Production', 'Staging', 'Local'
  final bool rollbackAvailable;

  const AppVersionInfo({
    this.currentVersion = 'v2.4.0-prod',
    this.previousStableVersion = 'v2.3.9-prod',
    this.buildNumber = '20260901.1',
    required this.releaseDate,
    this.deploymentStatus = 'Live / Healthy',
    this.environment = 'Production',
    this.rollbackAvailable = true,
  });

  Map<String, dynamic> toMap() => {
        'current_version': currentVersion,
        'previous_stable_version': previousStableVersion,
        'build_number': buildNumber,
        'release_date': releaseDate.toIso8601String(),
        'deployment_status': deploymentStatus,
        'environment': environment,
        'rollback_available': rollbackAvailable,
      };
}

/// Data Integrity Audit Report
class DataIntegrityReport {
  final int totalChecks;
  final int passedChecks;
  final int brokenReferencesCount;
  final List<String> detectedAnomalies;
  final DateTime generatedAt;

  const DataIntegrityReport({
    required this.totalChecks,
    required this.passedChecks,
    required this.brokenReferencesCount,
    required this.detectedAnomalies,
    required this.generatedAt,
  });

  bool get isHealthy => brokenReferencesCount == 0 && detectedAnomalies.isEmpty;
}
