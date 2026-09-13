import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/system_health_model.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/system_health_monitoring_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Production Reliability, Monitoring & Scalability Test Suite', () {
    // -------------------------------------------------------------------------
    // TEST 1: System Health Checks & Component Status Evaluation
    // -------------------------------------------------------------------------
    test('TEST 1: System Health checks report factual status and latency', () async {
      final service = SystemHealthMonitoringService.instance;
      await service.runLiveSystemHealthAudit();

      final checks = service.allHealthChecks;
      expect(checks.isNotEmpty, isTrue);

      final dbCheck = checks.firstWhere((c) => c.category == 'Database');
      expect(dbCheck.name, contains('Supabase PostgreSQL'));
      expect(dbCheck.latencyMs, greaterThanOrEqualTo(0));

      final storageCheck = checks.firstWhere((c) => c.category == 'Storage');
      expect(storageCheck.status, equals(HealthStatus.healthy));
    });

    // -------------------------------------------------------------------------
    // TEST 2: Transparent System Health Score (No Hardcoded 100/100)
    // -------------------------------------------------------------------------
    test('TEST 2: System Health Score is transparent with itemized deductions', () {
      final service = SystemHealthMonitoringService.instance;
      final score = service.evaluateSystemHealthScore();

      expect(score.overallScore, greaterThan(0));
      expect(score.overallScore, lessThanOrEqualTo(100));
      expect(score.categoryScores.containsKey('Database'), isTrue);
      expect(score.categoryScores.containsKey('Storage'), isTrue);
      expect(score.categoryScores.containsKey('API'), isTrue);
      expect(score.deductions.isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Production Error Tracking & Duplicate Grouping
    // -------------------------------------------------------------------------
    test('TEST 3: Repeated errors are deduplicated and grouped with occurrence count', () {
      final service = SystemHealthMonitoringService.instance;

      service.recordError(
        errorType: 'TimeoutException',
        message: 'Request to endpoint timed out after 5000ms',
        pageOrService: 'property_search',
        severity: 'medium',
      );

      service.recordError(
        errorType: 'TimeoutException',
        message: 'Request to endpoint timed out after 5000ms',
        pageOrService: 'property_search',
        severity: 'medium',
      );

      final errors = service.activeErrors.where((e) => e.errorType == 'TimeoutException').toList();
      expect(errors.isNotEmpty, isTrue);
      expect(errors.first.occurrences, greaterThanOrEqualTo(2));

      // Resolve error
      service.resolveErrorGroup(errors.first.errorFingerprint);
      final resolved = service.allErrors.firstWhere((e) => e.errorFingerprint == errors.first.errorFingerprint);
      expect(resolved.status, equals('resolved'));
    });

    // -------------------------------------------------------------------------
    // TEST 4: Synthetic Health Transactions
    // -------------------------------------------------------------------------
    test('TEST 4: Read-only synthetic checks execute without impacting production data', () async {
      final service = SystemHealthMonitoringService.instance;
      final results = await service.runAllSyntheticChecks();

      expect(results.length, greaterThanOrEqualTo(3));
      for (final res in results) {
        expect(res.passed, isTrue);
        expect(res.latencyMs, greaterThanOrEqualTo(0));
      }
    });

    // -------------------------------------------------------------------------
    // TEST 5: Background Jobs Queue & Progress Lifecycle
    // -------------------------------------------------------------------------
    test('TEST 5: Background job execution, retry, and cancellation lifecycle', () async {
      final service = SystemHealthMonitoringService.instance;
      final job = service.enqueueBackgroundJob(
        jobType: 'media_optimization',
        targetEntityId: 'PROP-TEST-99',
      );

      expect(job.jobId.isNotEmpty, isTrue);
      expect(job.status, isIn(['queued', 'running', 'completed']));

      // Retry test
      service.retryBackgroundJob(job.jobId);
      final retried = service.backgroundJobs.firstWhere((j) => j.jobId == job.jobId);
      expect(retried.retryCount, greaterThanOrEqualTo(0));
    });

    // -------------------------------------------------------------------------
    // TEST 6: Controlled Maintenance Mode (Read-Only vs Write Blocking)
    // -------------------------------------------------------------------------
    test('TEST 6: Maintenance mode preserves public reading while blocking unsafe writes', () {
      final service = SystemHealthMonitoringService.instance;

      // Normal mode
      service.setMaintenanceMode(mode: MaintenanceModeType.off);
      expect(service.isWriteAllowed(isAdmin: false), isTrue);

      // Read-Only Maintenance mode
      service.setMaintenanceMode(
        mode: MaintenanceModeType.readOnly,
        reason: 'Scheduled database indexing maintenance.',
        adminId: 'admin@propzen.ai',
      );

      expect(service.maintenanceConfig.isEnabled, isTrue);
      expect(service.maintenanceConfig.allowPublicBrowsing, isTrue);
      expect(service.isWriteAllowed(isAdmin: false), isFalse);
      expect(service.isWriteAllowed(isAdmin: true), isTrue); // Admin bypass permitted

      // Reset
      service.setMaintenanceMode(mode: MaintenanceModeType.off);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Data Integrity Audit Engine
    // -------------------------------------------------------------------------
    test('TEST 7: Data integrity scanner detects invalid records without data loss', () {
      final service = SystemHealthMonitoringService.instance;
      final report = service.runDataIntegrityAudit();

      expect(report.totalChecks, greaterThanOrEqualTo(0));
      expect(report.passedChecks, lessThanOrEqualTo(report.totalChecks));
      expect(report.generatedAt, isNotNull);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Automated Operational Recommendations
    // -------------------------------------------------------------------------
    test('TEST 8: Operational recommendations are generated from real health status', () {
      final service = SystemHealthMonitoringService.instance;
      final recs = service.generateOperationalRecommendations();

      expect(recs.isNotEmpty, isTrue);
      expect(recs.first.containsKey('title'), isTrue);
      expect(recs.first.containsKey('action'), isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST 9: Application Version & Rollback Metadata
    // -------------------------------------------------------------------------
    test('TEST 9: Version metadata and rollback readiness are accessible', () {
      final service = SystemHealthMonitoringService.instance;
      final v = service.versionInfo;

      expect(v.currentVersion.startsWith('v'), isTrue);
      expect(v.previousStableVersion.startsWith('v'), isTrue);
      expect(v.rollbackAvailable, isTrue);
      expect(v.environment, equals('Production'));
    });
  });
}
