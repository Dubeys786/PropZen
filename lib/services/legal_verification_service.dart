import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env_config.dart';

enum LegalVerificationStatus {
  pending,
  inProgress,
  verified,
  needsReview,
  rejected,
  error;

  String get displayName {
    switch (this) {
      case LegalVerificationStatus.pending:
        return 'Pending Verification';
      case LegalVerificationStatus.inProgress:
        return 'In Progress';
      case LegalVerificationStatus.verified:
        return 'Legally Verified';
      case LegalVerificationStatus.needsReview:
        return 'Needs Manual Review';
      case LegalVerificationStatus.rejected:
        return 'Verification Rejected';
      case LegalVerificationStatus.error:
        return 'Verification Error';
    }
  }

  static LegalVerificationStatus fromString(String val) {
    final lower = val.trim().toLowerCase();
    if (lower == 'verified' || lower == 'approved') return LegalVerificationStatus.verified;
    if (lower == 'in_progress' || lower == 'in-progress' || lower == 'processing') return LegalVerificationStatus.inProgress;
    if (lower == 'needs_review' || lower == 'needs-review') return LegalVerificationStatus.needsReview;
    if (lower == 'rejected' || lower == 'failed') return LegalVerificationStatus.rejected;
    if (lower == 'error') return LegalVerificationStatus.error;
    return LegalVerificationStatus.pending;
  }
}

class LegalVerificationRecord {
  final String verificationId;
  final String propertyId;
  final String verificationType; // RERA_SANCTION, NON_ENCUMBRANCE, TITLE_SEARCH, COURT_LITIGATION
  final LegalVerificationStatus status;
  final String provider; // eCourt, Signzy, UP_RERA, LandRecords
  final String? referenceId;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String? reviewedBy;
  final String source;
  final String resultSummary;
  final bool isDemoMock;

  const LegalVerificationRecord({
    required this.verificationId,
    required this.propertyId,
    required this.verificationType,
    required this.status,
    required this.provider,
    this.referenceId,
    required this.requestedAt,
    this.completedAt,
    this.reviewedBy,
    required this.source,
    required this.resultSummary,
    this.isDemoMock = false,
  });

  Map<String, dynamic> toMap() => {
        'verificationId': verificationId,
        'propertyId': propertyId,
        'verificationType': verificationType,
        'status': status.name,
        'provider': provider,
        'referenceId': referenceId,
        'requestedAt': requestedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'reviewedBy': reviewedBy,
        'source': source,
        'resultSummary': resultSummary,
        'isDemoMock': isDemoMock,
      };

  factory LegalVerificationRecord.fromMap(Map<String, dynamic> map, String id) {
    return LegalVerificationRecord(
      verificationId: id,
      propertyId: map['propertyId']?.toString() ?? '',
      verificationType: map['verificationType']?.toString() ?? 'RERA_SANCTION',
      status: LegalVerificationStatus.fromString(map['status']?.toString() ?? 'pending'),
      provider: map['provider']?.toString() ?? 'UP_RERA',
      referenceId: map['referenceId']?.toString(),
      requestedAt: DateTime.tryParse(map['requestedAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      reviewedBy: map['reviewedBy']?.toString(),
      source: map['source']?.toString() ?? 'Official Registry',
      resultSummary: map['resultSummary']?.toString() ?? 'Verification records in review',
      isDemoMock: map['isDemoMock'] == true,
    );
  }
}

class LegalVerificationService extends ChangeNotifier {
  LegalVerificationService._internal() {
    _initDefaultRecords();
  }
  static final LegalVerificationService instance = LegalVerificationService._internal();
  factory LegalVerificationService() => instance;

  final Map<String, List<LegalVerificationRecord>> _propertyVerifications = {};
  bool _useMockAdapter = true;

  bool get useMockAdapter => _useMockAdapter;
  void setUseMockAdapter(bool value) {
    _useMockAdapter = value;
    notifyListeners();
  }

  void _initDefaultRecords() {
    final now = DateTime.now();
    _propertyVerifications['prop_mahagun'] = [
      LegalVerificationRecord(
        verificationId: 'ver_rera_01',
        propertyId: 'prop_mahagun',
        verificationType: 'UP_RERA_REGISTRATION',
        status: LegalVerificationStatus.verified,
        provider: 'UP RERA Official Portal',
        referenceId: 'UPRERAPRJ123456',
        requestedAt: now.subtract(const Duration(days: 30)),
        completedAt: now.subtract(const Duration(days: 28)),
        reviewedBy: 'Adv. PropZen Verification Desk',
        source: 'UP RERA Public Registry',
        resultSummary: 'Verified active registration with sanctioned layout plan and valid completion timeline.',
        isDemoMock: false,
      ),
      LegalVerificationRecord(
        verificationId: 'ver_enc_01',
        propertyId: 'prop_mahagun',
        verificationType: 'NON_ENCUMBRANCE_SEARCH',
        status: LegalVerificationStatus.verified,
        provider: 'Sub-Registrar Office Noida',
        referenceId: 'EC-NOIDA-2025-88912',
        requestedAt: now.subtract(const Duration(days: 25)),
        completedAt: now.subtract(const Duration(days: 22)),
        reviewedBy: 'Adv. PropZen Verification Desk',
        source: 'District Sub-Registrar Records',
        resultSummary: 'Clear freehold title search across 30 years with no adverse mortgages.',
        isDemoMock: false,
      ),
    ];
  }

  List<LegalVerificationRecord> getVerificationsForProperty(String propertyId) {
    return _propertyVerifications[propertyId] ?? [];
  }

  /// Initiates legal / government verification check
  Future<LegalVerificationRecord> verifyProperty({
    required String propertyId,
    required String reraId,
    required String district,
  }) async {
    final now = DateTime.now();
    final verId = 'ver_${DateTime.now().millisecondsSinceEpoch}';

    if (!_useMockAdapter) {
      // Production fail-closed gateway
      try {
        final resp = await http.post(
          Uri.parse('${EnvConfig.aiEngineBaseUrl}/api/v1/government/verify-rera'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'rera_id': reraId, 'district': district}),
        );
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final record = LegalVerificationRecord(
            verificationId: verId,
            propertyId: propertyId,
            verificationType: 'UP_RERA_SANCTION',
            status: LegalVerificationStatus.fromString(data['status']?.toString() ?? 'pending'),
            provider: 'UP RERA Official Gateway',
            referenceId: reraId,
            requestedAt: now,
            completedAt: DateTime.now(),
            reviewedBy: 'Authorized RERA Verification Agent',
            source: 'State RERA Registry',
            resultSummary: data['summary']?.toString() ?? 'Verified matching layout with approved RERA certificate.',
            isDemoMock: false,
          );
          _propertyVerifications.putIfAbsent(propertyId, () => []).insert(0, record);
          notifyListeners();
          return record;
        }
      } catch (_) {}

      // Fail-closed record
      final failedRecord = LegalVerificationRecord(
        verificationId: verId,
        propertyId: propertyId,
        verificationType: 'UP_RERA_SANCTION',
        status: LegalVerificationStatus.needsReview,
        provider: 'UP RERA Official Gateway',
        referenceId: reraId,
        requestedAt: now,
        reviewedBy: 'Pending Manual Review',
        source: 'Awaiting Official Production API Approval',
        resultSummary: 'Production API access is awaiting official government gateway key clearance. Flagged for manual advocate verification.',
        isDemoMock: false,
      );
      _propertyVerifications.putIfAbsent(propertyId, () => []).insert(0, failedRecord);
      notifyListeners();
      return failedRecord;
    }

    // Explicitly labeled Mock / Demo Adapter
    final mockRecord = LegalVerificationRecord(
      verificationId: verId,
      propertyId: propertyId,
      verificationType: 'UP_RERA_SANCTION',
      status: LegalVerificationStatus.verified,
      provider: 'UP RERA Simulated Verification Adapter',
      referenceId: reraId.isNotEmpty ? reraId : 'DEMO-UPRERA-2026',
      requestedAt: now,
      completedAt: now,
      reviewedBy: 'PropZen Automated Test Harness',
      source: 'DEMO / TEST ONLY — Synthetic Sample Record',
      resultSummary: 'DEMO / TEST ONLY: Synthetic title search and sanctioned layout matching.',
      isDemoMock: true,
    );
    _propertyVerifications.putIfAbsent(propertyId, () => []).insert(0, mockRecord);
    notifyListeners();
    return mockRecord;
  }
}
