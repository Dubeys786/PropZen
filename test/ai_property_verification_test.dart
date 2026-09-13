import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property_verification_model.dart';
import 'package:dealghar_ncr_10x/services/n8n_service.dart';

void main() {
  group('AI Property Verification System Unit Tests', () {
    test('1. VerificationStatus Enum and Extensions Map Correctly', () {
      expect(VerificationStatus.consistent.label, 'Information appears consistent');
      expect(VerificationStatus.needsReview.label, 'Manual review recommended');
      expect(VerificationStatus.mismatch.label, 'Important mismatch detected');
      expect(VerificationStatus.sourceUnavailable.label, 'Official verification source unavailable');
      expect(VerificationStatus.pending.label, 'Verification Pending');

      expect(VerificationStatusExt.fromString('consistent'), VerificationStatus.consistent);
      expect(VerificationStatusExt.fromString('green'), VerificationStatus.consistent);
      expect(VerificationStatusExt.fromString('needs_review'), VerificationStatus.needsReview);
      expect(VerificationStatusExt.fromString('yellow'), VerificationStatus.needsReview);
      expect(VerificationStatusExt.fromString('mismatch'), VerificationStatus.mismatch);
      expect(VerificationStatusExt.fromString('red'), VerificationStatus.mismatch);
      expect(VerificationStatusExt.fromString('source_unavailable'), VerificationStatus.sourceUnavailable);
      expect(VerificationStatusExt.fromString('unavailable'), VerificationStatus.sourceUnavailable);
    });

    test('2. PropertyDocumentModel Serialization and Deserialization', () {
      final doc = PropertyDocumentModel(
        id: 'DOC-137-SD-01',
        propertyId: 'NCR-FLAT-3BHK-103',
        documentType: 'Sale Deed',
        fileName: 'Sale_Deed_ATS_HappyTrails.pdf',
        fileSizeBytes: 4404019,
        pageCount: 18,
        isCompleteUpload: true,
        verificationStatus: VerificationStatus.consistent,
        statusReason: 'Information appears consistent: Owner name and super area match registered deed.',
        uploadedAt: '2026-08-20T14:30:00Z',
      );

      final map = doc.toMap();
      expect(map['id'], 'DOC-137-SD-01');
      expect(map['document_type'], 'Sale Deed');
      expect(map['page_count'], 18);
      expect(map['verification_status'], 'consistent');

      final fromMap = PropertyDocumentModel.fromMap(map);
      expect(fromMap.id, doc.id);
      expect(fromMap.documentType, 'Sale Deed');
      expect(fromMap.verificationStatus, VerificationStatus.consistent);
      expect(fromMap.isCompleteUpload, true);
    });

    test('3. DocumentAnalysisModel Entity Extraction & Missing Pages Detection', () {
      final analysis = DocumentAnalysisModel(
        id: 'ANALYSIS-01',
        documentId: 'DOC-137-SD-01',
        propertyId: 'NCR-FLAT-3BHK-103',
        documentType: 'Sale Deed',
        extractedData: {
          'ownerName': 'Sunil Kumar Agrawal & Meena Agrawal',
          'propertyAddress': 'Unit 802, Tower 4, ATS Happy Trails, Sector 10, Greater Noida West',
          'areaSqft': '1,750 Sq.Ft',
          'carpetAreaSqft': '1,250 Sq.Ft',
          'docNumber': 'UP/GN/2024/0981'
        },
        detectedIssues: [],
        missingPagesDetected: false,
        consistencyStatus: VerificationStatus.consistent,
        analysisSummary: 'All extracted entities match sanctioned project blueprints with 100% confidence.',
        createdAt: '2026-08-20T14:35:00Z',
      );

      final map = analysis.toMap();
      expect(map['missing_pages_detected'], false);
      expect(map['consistency_status'], 'consistent');
      expect(map['extracted_data']['ownerName'], 'Sunil Kumar Agrawal & Meena Agrawal');

      final deserialized = DocumentAnalysisModel.fromMap(map);
      expect(deserialized.missingPagesDetected, false);
      expect(deserialized.extractedData['areaSqft'], '1,750 Sq.Ft');
      expect(deserialized.consistencyStatus, VerificationStatus.consistent);
    });

    test('4. Cross-Document Area Discrepancy Flagged as Mismatch (Red)', () {
      final mismatchAnalysis = DocumentAnalysisModel(
        id: 'ANALYSIS-02',
        documentId: 'DOC-137-MOD-02',
        propertyId: 'NCR-FLAT-3BHK-103',
        documentType: 'Sale Agreement',
        extractedData: {
          'ownerName': 'Sunil Kumar Agrawal',
          'areaSqft': '1,550 Sq.Ft', // Mismatch from 1,750 Sq.Ft
        },
        detectedIssues: ['Super area in Agreement (1,550 sq.ft) deviates from Registry (1,750 sq.ft)'],
        missingPagesDetected: false,
        consistencyStatus: VerificationStatus.mismatch,
        analysisSummary: 'Important mismatch detected: Registered super built-up area variance.',
        createdAt: '2026-08-27T10:00:00Z',
      );

      expect(mismatchAnalysis.consistencyStatus, VerificationStatus.mismatch);
      expect(mismatchAnalysis.consistencyStatus.label, 'Important mismatch detected');
      expect(mismatchAnalysis.detectedIssues.isNotEmpty, true);
    });

    test('5. Official Record VerificationCheckModel handles Source Unavailable Fallback', () {
      final unavailableCheck = VerificationCheckModel(
        id: 'CHK-04',
        propertyId: 'NCR-FLAT-3BHK-103',
        checkType: 'Environmental NOC',
        fieldName: 'Ground Water NOC',
        sourceType: 'Central Ground Water Authority',
        claimValue: 'NOC Approved',
        sourceValue: 'Official verification source unavailable',
        status: 'SOURCE_UNAVAILABLE',
        statusReason: 'Official verification source unavailable: Public CGWA digital lookup API is offline.',
        isOfficialSource: false,
        verifiedAt: '2026-08-27T10:30:00Z',
      );

      final map = unavailableCheck.toMap();
      expect(map['status'], 'SOURCE_UNAVAILABLE');
      expect(map['source_value'], 'Official verification source unavailable');
      expect(map['is_official_source'], false);

      final parsed = VerificationCheckModel.fromMap(map);
      expect(parsed.sourceValue, 'Official verification source unavailable');
    });

    test('6. Official Record VerificationCheckModel handles Matched RERA Record', () {
      final reraCheck = VerificationCheckModel(
        id: 'CHK-01',
        propertyId: 'NCR-FLAT-3BHK-103',
        checkType: 'RERA Registration',
        fieldName: 'Project Sanction ID',
        sourceType: 'State Regulatory Authority',
        claimValue: 'UPRERAPRJ15574',
        sourceValue: 'Active & Approved (Valid until Dec 2026)',
        status: 'MATCH',
        statusReason: 'Project registration active on State RERA portal with valid promoter compliance.',
        isOfficialSource: true,
        verifiedAt: '2026-08-27T10:30:00Z',
      );

      expect(reraCheck.status, 'MATCH');
      expect(reraCheck.isOfficialSource, true);
      expect(reraCheck.claimValue, 'UPRERAPRJ15574');
    });

    test('7. PropertyHistoryEventModel Chronological Timeline Serialization', () {
      final events = [
        PropertyHistoryEventModel(
          id: 'HIST-01',
          propertyId: 'NCR-FLAT-3BHK-103',
          eventDate: '2019-03-15',
          eventType: 'Land Allotment Recorded',
          description: 'GNIDA allotted Plot GH-02.',
          sourceName: 'GNIDA Official Gazette Allotment GH-02',
          createdAt: '2026-08-20T00:00:00Z',
        ),
        PropertyHistoryEventModel(
          id: 'HIST-02',
          propertyId: 'NCR-FLAT-3BHK-103',
          eventDate: '2020-08-20',
          eventType: 'UP RERA Registration Approved',
          description: 'Project received state regulatory registration.',
          sourceName: 'UP RERA Portal Registration Order',
          createdAt: '2026-08-20T00:00:00Z',
        ),
      ];

      expect(events[0].eventDate, '2019-03-15');
      expect(events[1].eventDate, '2020-08-20');
      expect(events[0].eventType, 'Land Allotment Recorded');
    });

    test('8. VerificationQuestionModel Resolution Workflow', () {
      final question = VerificationQuestionModel(
        id: 'Q-103-01',
        propertyId: 'NCR-FLAT-3BHK-103',
        issueDetected: 'Minor Typo in Co-Owner Middle Name',
        affectedField: 'Owner Name',
        questionText: 'Property Tax Receipt abbreviates co-owner name. Please confirm matching identity.',
        evidenceReference: 'GNIDA Tax Receipt #GNIDA-PTAX-2025-88391',
        status: 'Pending',
        createdAt: '2026-08-25T10:00:00Z',
        updatedAt: '2026-08-25T10:00:00Z',
      );

      expect(question.status, 'Pending');

      // Dealer resolves question
      final resolved = VerificationQuestionModel(
        id: question.id,
        propertyId: question.propertyId,
        issueDetected: question.issueDetected,
        affectedField: question.affectedField,
        questionText: question.questionText,
        evidenceReference: question.evidenceReference,
        status: 'Resolved',
        createdAt: question.createdAt,
        updatedAt: '2026-08-26T18:20:00Z',
      );

      expect(resolved.status, 'Resolved');
    });

    test('9. True Property Cost Calculator Male Buyer in UP (7% Stamp Duty)', () {
      final estimate = PropertyCostEstimateModel(
        id: 'EST-103-MALE',
        propertyId: 'NCR-FLAT-3BHK-103',
        basePrice: 14500000.0, // ₹ 1.45 Cr
        stampDutyPercent: 7.0,
        stampDutyCharges: 1015000.0, // 7% of 1.45 Cr
        registrationPercent: 1.0,
        registrationCharges: 145000.0, // 1% of 1.45 Cr
        brokeragePercent: 1.0,
        brokerageCharges: 145000.0, // 1%
        maintenanceDeposit: 150000.0,
        renovationEstimate: 350000.0,
        legalDueDiligence: 25000.0,
        otherCharges: 0.0,
        estimatedTotalCost: 16330000.0, // ₹ 1.633 Cr
        buyerCategory: 'Male',
        locationJurisdiction: 'Noida (Uttar Pradesh)',
      );

      expect(estimate.basePrice, 14500000.0);
      expect(estimate.stampDutyCharges, 1015000.0);
      expect(estimate.registrationCharges, 145000.0);
      expect(estimate.estimatedTotalCost, 16330000.0);
      expect(estimate.disclaimer, contains('Estimated cost'));
    });

    test('10. True Property Cost Calculator Female Buyer Concession in UP (6% Stamp Duty)', () {
      final basePrice = 14500000.0;
      final stampPct = 6.0; // 1% concession for female buyer in UP
      final stampCharges = basePrice * (stampPct / 100.0); // ₹ 8,70,000
      final regCharges = basePrice * 0.01; // ₹ 1,45,000
      final brokerage = basePrice * 0.01; // ₹ 1,45,000
      final maint = 150000.0;
      final reno = 350000.0;
      final legal = 25000.0;
      final total = basePrice + stampCharges + regCharges + brokerage + maint + reno + legal;

      final femaleEstimate = PropertyCostEstimateModel(
        id: 'EST-103-FEMALE',
        propertyId: 'NCR-FLAT-3BHK-103',
        basePrice: basePrice,
        stampDutyPercent: stampPct,
        stampDutyCharges: stampCharges,
        registrationCharges: regCharges,
        brokerageCharges: brokerage,
        maintenanceDeposit: maint,
        renovationEstimate: reno,
        legalDueDiligence: legal,
        estimatedTotalCost: total,
        buyerCategory: 'Female',
        locationJurisdiction: 'Noida (Uttar Pradesh)',
      );

      expect(femaleEstimate.stampDutyPercent, 6.0);
      expect(femaleEstimate.stampDutyCharges, 870000.0);
      expect(femaleEstimate.estimatedTotalCost, 16185000.0); // ₹ 1.6185 Cr
      expect(femaleEstimate.buyerCategory, 'Female');
    });

    test('11. N8nService Verification Endpoint Constants Defined', () {
      expect(N8nService.prodVerifyDocumentUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/verify-document');
      expect(N8nService.prodOfficialSourceCheckUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/verify-source');
      expect(N8nService.prodQuestionGeneratorUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/verification-question');
      expect(N8nService.prodPropertyMonitorUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/property-monitor');
    });
  });
}
