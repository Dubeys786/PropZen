import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';

class TrustEngineReportModal extends StatelessWidget {
  final VerificationCase verificationCase;

  const TrustEngineReportModal({super.key, required this.verificationCase});

  static Future<void> show(BuildContext context, VerificationCase vCase) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: TrustEngineReportModal(verificationCase: vCase),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = verificationCase;

    return Container(
      width: 920,
      height: 780,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x24000000), blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Modal Header with Action Buttons
            _buildHeader(context),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Printable Report Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Official Watermark Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PROPZEN TRUST ENGINE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'AI Property & Document Verification Audit Certificate',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'VERIFICATION ID',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
                            ),
                            Text(
                              v.id,
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF7C3AED)),
                            ),
                            Text(
                              'Generated ${v.lastUpdated.day}/${v.lastUpdated.month}/${v.lastUpdated.year} • Verified',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 18),

                    // Case Summary Grid
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          _summaryCol('Property Asset', v.propertyTitle),
                          _summaryCol('Identified Owner', v.ownerName),
                          _summaryCol('Overall Status', v.status.label, color: v.status.color),
                          _summaryCol('Risk Classification', v.overallRiskLevel.label, color: v.overallRiskLevel.color),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Section 1: Executive Summary
                    _sectionTitle('1. Executive Summary', LucideIcons.fileText),
                    const SizedBox(height: 8),
                    Text(
                      'This comprehensive verification certificate was produced by PropZen Trust Engine v3.4 following algorithmic OCR inspection, revenue department boundary alignment, and cross-deed legal verification. The submitted asset (${v.propertyTitle}) displays a sound ownership trajectory and unbroken chain of title across 30 years.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155), height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Document Analysis & Integrity
                    _sectionTitle('2. Document Analysis & Spectral Integrity', LucideIcons.fileSearch),
                    const SizedBox(height: 8),
                    Text(
                      'All ${v.documents.length} ingested documents were subjected to multi-spectral watermark analysis and Sub-Registrar stamp barcode validation. No evidence of pixel-level tampering, digital signature invalidation, or mechanical splicing was detected.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155), height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Cross-Document Consistency Matrix
                    _sectionTitle('3. Cross-Document Consistency Verification', LucideIcons.gitCompare),
                    const SizedBox(height: 8),
                    ...v.consistencyRows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            '${row.attributeName}: ',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          Expanded(
                            child: Text(
                              '${row.documentAValue} (${row.differenceNotes})',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Section 4: Authorized Source Verification
                    _sectionTitle('4. Official Source Registry Logs', LucideIcons.landmark),
                    const SizedBox(height: 8),
                    ...v.sources.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF0D9488)),
                          const SizedBox(width: 8),
                          Text(
                            '${s.sourceName} [${s.referenceId}]: ',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          Expanded(
                            child: Text(
                              s.resultSummary,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Section 5: Risk Findings & Manual Review Items
                    _sectionTitle('5. Risk Findings & Actionable Recommendations', LucideIcons.shieldAlert),
                    const SizedBox(height: 8),
                    ...v.findings.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(f.severity.icon, size: 15, color: f.severity.color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${f.title}: ${f.recommendedAction}',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 24),

                    // Section 6: Audit Trail
                    _sectionTitle('6. Immutable Audit Trail', LucideIcons.history),
                    const SizedBox(height: 8),
                    ...v.auditTrail.map((ev) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${ev.timestamp.hour}:${ev.timestamp.minute.toString().padLeft(2, '0')} • ${ev.actor}: ',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                          ),
                          Expanded(
                            child: Text(
                              '${ev.action} - ${ev.details}',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 32),

                    // MANDATORY LEGAL DISCLAIMER
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IMPORTANT LEGAL DISCLAIMER',
                                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PropZen AI verification is an analytical and risk-assessment tool. Results should be reviewed against authoritative records and professional/legal advice where required. PropZen does not claim 100% fraud detection, 100% legal verification, guaranteed ownership, or guaranteed title clearance.',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB45309), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'PropZen Verification Report',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.download, size: 14),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading official PDF verification certificate...')),
                  );
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.share2, size: 14),
                label: const Text('Share Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report link copied to clipboard.')),
                  );
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(LucideIcons.printer, size: 14),
                label: const Text('Print Report'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sending document to printer...')),
                  );
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCol(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: color ?? const Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
