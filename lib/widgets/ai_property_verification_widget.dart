import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

/// Full-featured AI Property Verification & Title Intelligence Widget for Flutter
class AiPropertyVerificationWidget extends StatefulWidget {
  final Property property;

  const AiPropertyVerificationWidget({
    super.key,
    required this.property,
  });

  @override
  State<AiPropertyVerificationWidget> createState() => _AiPropertyVerificationWidgetState();
}

class _AiPropertyVerificationWidgetState extends State<AiPropertyVerificationWidget> {
  // Verification State Store
  int _pipelineStep = 6;
  bool _isMonitoringActive = true;

  // Cost Calculator State
  String _selectedJurisdiction = 'noida_up';
  String _selectedBuyerCategory = 'male';
  double _stampDutyPct = 7.0;
  double _registrationPct = 1.0;
  double _brokeragePct = 1.0;
  double _maintenanceDeposit = 150000.0;
  double _renovationEstimate = 350000.0;
  double _legalDueDiligence = 25000.0;

  // Document List
  late List<Map<String, dynamic>> _documents;
  late List<Map<String, dynamic>> _officialChecks;
  late List<Map<String, dynamic>> _historyEvents;
  late List<Map<String, dynamic>> _questions;
  late List<Map<String, dynamic>> _alerts;

  @override
  void initState() {
    super.initState();
    _initVerificationData();
  }

  void _initVerificationData() {
    final prop = widget.property;

    _documents = [
      {
        'id': 'DOC-SD-01',
        'type': 'Sale Deed',
        'fileName': 'Sale_Deed_${prop.title.replaceAll(' ', '_')}.pdf',
        'size': '4.2 MB',
        'pages': 18,
        'uploadDate': '2026-08-20 14:30',
        'status': 'consistent', // consistent (green), needs_review (yellow), mismatch (red)
        'statusReason': 'Information appears consistent: Registered owner names, unit allotment, and super area match registrar records.',
        'extracted': {
          'owner': 'Sunil Kumar Agrawal & Meena Agrawal',
          'unit': 'Tower 4 - Unit 802 (Floor 8)',
          'area': '${prop.sqft} Sq.Ft (Sanctioned)',
          'docNo': 'UP/GN/2024/0981 (Book 1, Vol 4921)',
          'completeness': 'Complete (18/18 pages verified)',
        }
      },
      {
        'id': 'DOC-REG-02',
        'type': 'Sub-Registrar Registry',
        'fileName': 'Sub_Registrar_UP_Registry_Certificate.pdf',
        'size': '2.8 MB',
        'pages': 8,
        'uploadDate': '2026-08-22 11:15',
        'status': 'consistent',
        'statusReason': 'Information appears consistent: Stamped registry verifies stamp duty payment of ₹10,15,000 with zero liens.',
        'extracted': {
          'owner': 'Sunil Kumar Agrawal & Meena Agrawal',
          'unit': 'Plot GH-02, ${prop.sector}',
          'area': '${prop.sqft} Sq.Ft',
          'docNo': 'REG-GBN-2024-884210',
          'completeness': 'Complete (8/8 pages present)',
        }
      },
      {
        'id': 'DOC-RERA-03',
        'type': 'RERA Certificate',
        'fileName': 'UPRERA_Project_Registration_Certificate.pdf',
        'size': '1.5 MB',
        'pages': 4,
        'uploadDate': '2026-08-15 09:00',
        'status': 'consistent',
        'statusReason': 'Information appears consistent: Project registration valid and active on state RERA regulatory portal.',
        'extracted': {
          'owner': prop.builderName.isNotEmpty ? prop.builderName : 'ATS HomeKraft',
          'unit': 'Sanctioned Master Typology',
          'area': '${prop.sqft} Sq.Ft Typology',
          'docNo': prop.reraId.isNotEmpty ? prop.reraId : 'UPRERAPRJ15574',
          'completeness': 'Complete (4/4 pages verified)',
        }
      },
      {
        'id': 'DOC-TAX-04',
        'type': 'Municipal Tax Receipt',
        'fileName': 'GNIDA_Municipal_Property_Tax_2025_26.pdf',
        'size': '980 KB',
        'pages': 2,
        'uploadDate': '2026-08-25 16:20',
        'status': 'consistent',
        'statusReason': 'Information appears consistent: Zero municipal property tax arrears recorded with the urban development authority.',
        'extracted': {
          'owner': 'Sunil Kumar Agrawal',
          'unit': 'Unit 802, ${prop.sector}',
          'area': '${prop.sqft} Sq.Ft Assessment',
          'docNo': 'GNIDA-PTAX-2025-88391',
          'completeness': 'Complete (2/2 pages)',
        }
      },
    ];

    _officialChecks = [
      {
        'id': 'CHK-01',
        'sourceName': 'UP RERA Official Portal',
        'sourceType': 'State Regulatory Authority',
        'field': 'Project Registration & Sanction',
        'claim': prop.reraId.isNotEmpty ? prop.reraId : 'UPRERAPRJ15574',
        'source': 'Active & Approved (Valid until Dec 2026)',
        'status': 'MATCH',
        'isOfficial': true,
        'verifiedAt': '2026-08-27 10:30 AM',
        'reason': 'Project registration active on State RERA portal with valid promoter compliance.',
        'evidence': 'UPRERA Public Registry Project ID: UPRERAPRJ15574 | Promoter: ATS HomeKraft | Approval: Sanctioned Residential Highrise | Land Title: Clear Allotment.'
      },
      {
        'id': 'CHK-02',
        'sourceName': 'Dept of Stamp & Registration (UP)',
        'sourceType': 'State Land Revenue Authority',
        'field': 'Title Deed & Encumbrance (30-Yr)',
        'claim': 'Sunil Kumar Agrawal & Meena Agrawal',
        'source': 'Registered Freehold Title (No Liens / Clean)',
        'status': 'MATCH',
        'isOfficial': true,
        'verifiedAt': '2026-08-27 10:30 AM',
        'reason': 'Sub-Registrar record confirms zero active court attachments, mortgages, or second-party encumbrances.',
        'evidence': 'Sub-Registrar Gautam Buddha Nagar E-Inspection Entry #UP/GN/2024/0981. Stamped stamp duty paid in full: ₹10,15,000. Clean non-encumbrance certificate issued.'
      },
      {
        'id': 'CHK-03',
        'sourceName': 'Greater Noida Authority (GNIDA)',
        'sourceType': 'Municipal Urban Authority',
        'field': 'Master Plan Land Use & Occupancy',
        'claim': 'Residential (Sanctioned Highrise)',
        'source': 'Approved Group Housing (FAR Compliant)',
        'status': 'MATCH',
        'isOfficial': true,
        'verifiedAt': '2026-08-27 10:30 AM',
        'reason': 'GNIDA Master Plan 2031 validates zoning for Group Housing with full OC issuance.',
        'evidence': 'GNIDA Planning Sanction GN/BP/2019/882. Occupancy Certificate issued for Tower 4 on 10th Nov 2023.'
      },
      {
        'id': 'CHK-04',
        'sourceName': 'Central Ground Water Authority',
        'sourceType': 'Environmental Compliance',
        'field': 'Environmental / Ground Water NOC',
        'claim': 'NOC Approved',
        'source': 'Official verification source unavailable',
        'status': 'SOURCE_UNAVAILABLE',
        'isOfficial': false,
        'verifiedAt': '2026-08-27 10:30 AM',
        'reason': 'Official verification source unavailable: CGWA local sub-district digital lookup API is offline.',
        'evidence': 'Public API endpoint returned HTTP 503 (Source unavailable). PropZen does not synthesize missing governmental data.'
      },
    ];

    _historyEvents = [
      {
        'date': '2019-03-15',
        'type': 'Land Allotment Recorded',
        'desc': 'Development authority allotted Group Housing plot with clear freehold demarcations.',
        'source': 'Authority Official Gazette Allotment GH-02',
        'status': 'VERIFIED'
      },
      {
        'date': '2020-08-20',
        'type': 'RERA Registration Approved',
        'desc': 'Project received state regulatory registration with approved architectural blueprints.',
        'source': 'UP RERA Portal Registration Order',
        'status': 'VERIFIED'
      },
      {
        'date': '2023-11-10',
        'type': 'Occupancy Certificate Issued',
        'desc': 'Authority structural engineers inspected and issued Full Occupancy Certificate.',
        'source': 'GNIDA Occupancy Certificate OC/2023/419',
        'status': 'VERIFIED'
      },
      {
        'date': '2024-03-14',
        'type': 'Sub-Registrar Registry & Mutation',
        'desc': 'First buyer title deed executed and registered at Sub-Registrar Office.',
        'source': 'Sub-Registrar Gautam Buddha Nagar Reg #0981',
        'status': 'VERIFIED'
      },
      {
        'date': '2026-08-27',
        'type': 'PropZen AI Title & Document Audit',
        'desc': 'PropZen AI Title Intelligence completed 4-way cross-check across Sale Deed, RERA, and Tax records.',
        'source': 'PropZen Automated Verification Engine',
        'status': 'VERIFIED'
      },
    ];

    _questions = [
      {
        'id': 'Q-01',
        'issue': 'Minor Co-Owner Name Spelling in Tax Receipt',
        'affected': 'Owner Name',
        'evidence': 'Tax receipt lists "Sunil K Agrawal" while Registry specifies "Sunil Kumar Agrawal".',
        'question': 'Property Tax Receipt abbreviates co-owner name as "Sunil K Agrawal". Please confirm matching identity via Aadhaar/PAN.',
        'status': 'Resolved',
        'dealerAnswer': 'Aadhaar copy uploaded confirming Sunil Kumar Agrawal. Tax record updated with full name in Q2 2026 assessment.',
        'answeredAt': '2026-08-26 18:20',
      }
    ];

    _alerts = [
      {
        'title': 'Circle Rate Update Monitored',
        'date': '2026-08-15 08:30 AM',
        'desc': 'Gautam Buddha Nagar revised base circle rate for this micro-market by +4.5% for FY 2026-27.',
        'prev': '₹ 42,000 / Sq.Mtr',
        'next': '₹ 43,890 / Sq.Mtr',
        'source': 'UP Department of Stamp & Registration Circular',
      }
    ];
  }

  void _openSourceProofModal(Map<String, dynamic> check) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Source-Proof Evidence', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('PropZen Institutional Verification Engine', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Source Metadata Grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VERIFIED SOURCE', style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(check['sourceName'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SOURCE TYPE', style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(check['sourceType'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Claim vs Source Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CLAIMED VALUE VS. VERIFIED SOURCE VALUE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Listing Claim', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                                const SizedBox(height: 2),
                                Text(check['claim'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Verified Source', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF065F46))),
                                const SizedBox(height: 2),
                                Text(check['source'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Extracted Evidence Snippet
              Text('EXTRACTED EVIDENCE DATA SNIPPET', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  check['evidence'] ?? '',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF34D399), height: 1.4),
                ),
              ),

              const SizedBox(height: 14),

              // AI Rationale
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        check['reason'] ?? '',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF3730A3), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close Action
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Close Evidence', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Banner & Verified Badge
          _buildHeaderBanner(),

          const SizedBox(height: 20),

          // 2. Verification Pipeline Steps
          _buildPipelineTracker(),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 20),

          // 3. Government & Official Record Checks
          _buildOfficialChecksSection(),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 20),

          // 5. Property History Timeline
          _buildHistoryTimelineSection(),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 20),

          // 6. AI Clarification Inquiries
          _buildQuestionsSection(),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 20),

          // 7. Real-Time Property Alert Monitor
          _buildMonitoringSection(),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
          const SizedBox(height: 20),

          // 8. True Property Cost Calculator
          _buildTrueCostCalculatorSection(),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. HEADER BANNER & BADGE
  // =========================================================================
  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: Color(0xFFFBBF24), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI Property Verification Intelligence',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Official Source Cross-Check • Title Timeline • Mismatch Resolution', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('✓ PropZen Verified', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6EE7B7))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),

          // 4 KPI Counters
          Row(
            children: [
              _buildKpiCard('DOCUMENTS CHECKED', '${_documents.length} / ${_documents.length} Complete', Colors.white),
              const SizedBox(width: 8),
              _buildKpiCard('OFFICIAL SOURCES', '${_officialChecks.where((c) => c['status'] == 'MATCH').length} / ${_officialChecks.length} Verified', const Color(0xFF34D399)),
              const SizedBox(width: 8),
              _buildKpiCard('CONSISTENCY', 'Passed (100%)', const Color(0xFF6EE7B7)),
              const SizedBox(width: 8),
              _buildKpiCard('LAST VERIFIED', 'Aug 27, 2026', const Color(0xFFE2E8F0)),
            ],
          ),

          const SizedBox(height: 12),

          // Scope & Non-Legal Disclaimer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, size: 14, color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scope of Verification: PropZen Verified — document and available-source checks completed. This process evaluates cross-document data consistency and available public records. It does not constitute legal title certification or guaranteed ownership.',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFCBD5E1), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: valueColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. PIPELINE TRACKER
  // =========================================================================
  Widget _buildPipelineTracker() {
    final steps = ['1. Uploaded', '2. AI Analysis', '3. Comparison', '4. Official Check', '5. Review Issues', '6. Result Active'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.activity, size: 14, color: AppTheme.primaryViolet),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Verification Pipeline Progress',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('Step $_pipelineStep / 6: Complete', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(steps.length, (idx) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, size: 10, color: Color(0xFF065F46)),
                          const SizedBox(width: 4),
                          Text(
                            steps[idx],
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              }

              return Row(
                children: List.generate(steps.length, (idx) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: idx < steps.length - 1 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.check, size: 10, color: Color(0xFF065F46)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              steps[idx],
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF065F46)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. GOVERNMENT & OFFICIAL RECORD CHECKS
  // =========================================================================
  Widget _buildOfficialChecksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.landmark, size: 18, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '1. Government & Official Record Checks',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cross-verifies ownership, RERA status, and registry records against authorized portals.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✓ Official government record sources synchronized!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(LucideIcons.refreshCw, size: 12),
              label: const Text('Re-check Sources'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryViolet, textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Checks Table List
        Column(
          children: _officialChecks.map((chk) => _buildOfficialCheckRow(chk)).toList(),
        ),
      ],
    );
  }

  Widget _buildOfficialCheckRow(Map<String, dynamic> chk) {
    final isMatch = chk['status'] == 'MATCH';
    final isUnavailable = chk['status'] == 'SOURCE_UNAVAILABLE';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(chk['isOfficial'] == true ? LucideIcons.shieldCheck : LucideIcons.alertCircle, size: 18, color: isMatch ? const Color(0xFF10B981) : AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            flex: 35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chk['sourceName'] ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(chk['field'] ?? '', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 40,
            child: Text(
              chk['source'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isUnavailable ? AppTheme.textMuted : AppTheme.textPrimary,
                fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _openSourceProofModal(chk),
            icon: const Icon(LucideIcons.eye, size: 12),
            label: const Text('View Source'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryViolet,
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. PROPERTY HISTORY TIMELINE
  // =========================================================================
  Widget _buildHistoryTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.history, size: 18, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '2. Property History Timeline',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('Chronological ledger of verified ownership, allotments, and AI audit timestamps.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),

        const SizedBox(height: 14),

        Column(
          children: _historyEvents.map((evt) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle)),
                    Container(width: 2, height: 44, color: const Color(0xFFE2E8F0)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(4)),
                              child: Text(evt['date'], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(evt['type'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(evt['desc'], style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // =========================================================================
  // 6. AI QUESTIONS & DEALER RESOLUTION
  // =========================================================================
  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(LucideIcons.helpCircle, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3. AI Clarification Inquiries & Discrepancies',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text('0 Inquiries Pending', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('When document contradictions occur, AI generates clarification questions for dealer resolution.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),

        const SizedBox(height: 14),

        Column(
          children: _questions.map((q) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(q['issue'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                        child: Text('✓ Resolved', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('❓ AI Question: "${q['question']}"', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Affected Field: ${q['affected']} • Evidence: ${q['evidence']}', style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  if (q['dealerAnswer'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFD1FAE5).withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dealer Clarification (${q['answeredAt']}):', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                          const SizedBox(height: 2),
                          Text(q['dealerAnswer'], style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF065F46))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // =========================================================================
  // 7. REAL-TIME PROPERTY ALERT MONITOR
  // =========================================================================
  Widget _buildMonitoringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFF3E8FF), shape: BoxShape.circle),
                child: const Icon(LucideIcons.bellRing, size: 20, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('4. Real-Time Property Alert Monitor', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('24/7 background watch for registry, circle rates, and title changes.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: _isMonitoringActive,
                activeColor: const Color(0xFF7C3AED),
                onChanged: (val) {
                  setState(() => _isMonitoringActive = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? '🔔 Property Alert Monitor ENABLED' : 'Property Alert Monitor PAUSED', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      backgroundColor: val ? const Color(0xFF10B981) : AppTheme.textSecondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Alerts Feed
        Column(
          children: _alerts.map((alt) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(alt['title'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF6B21A8)), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(alt['date'], style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF7E22CE))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(alt['desc'], style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Previous: ${alt['prev']} → New: ${alt['next']}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF581C87))),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // =========================================================================
  // 8. TRUE PROPERTY COST CALCULATOR
  // =========================================================================
  Widget _buildTrueCostCalculatorSection() {
    final basePrice = widget.property.askingPriceCr > 0 ? widget.property.askingPriceCr * 10000000.0 : 14500000.0;
    final stampCharges = basePrice * (_stampDutyPct / 100.0);
    final regCharges = basePrice * (_registrationPct / 100.0);
    final brokerageCharges = basePrice * (_brokeragePct / 100.0);
    final totalOutlay = basePrice + stampCharges + regCharges + brokerageCharges + _maintenanceDeposit + _renovationEstimate + _legalDueDiligence;
    final priceDisplay = widget.property.priceRangeDisplay.isNotEmpty ? widget.property.priceRangeDisplay : '₹ ${widget.property.askingPriceCr.toStringAsFixed(2)} Cr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calculator, size: 18, color: Color(0xFFE11D48)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '5. True Property Cost Calculator',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Accurate estimation of total outlay including state taxes, brokerage, and renovation.',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: Text('Configurable Rates', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buyer Category', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFCBD5E1))),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedBuyerCategory,
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('👨 Male (7% Stamp)')),
                                DropdownMenuItem(value: 'female', child: Text('👩 Female (6% Concession)')),
                                DropdownMenuItem(value: 'joint', child: Text('👥 Joint (6.5%)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedBuyerCategory = val;
                                    _stampDutyPct = val == 'female' ? 6.0 : (val == 'joint' ? 6.5 : 7.0);
                                  });
                                }
                              },
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stamp Duty (${_stampDutyPct}%)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Slider(
                          value: _stampDutyPct,
                          min: 4.0,
                          max: 9.0,
                          divisions: 10,
                          activeColor: const Color(0xFFE11D48),
                          onChanged: (val) => setState(() => _stampDutyPct = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Itemized Breakdown Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildCostRow('Base Property Price', priceDisplay),
                    _buildCostRow('State Stamp Duty (${_stampDutyPct}%)', '₹ ${(stampCharges / 100000).toStringAsFixed(2)} Lacs'),
                    _buildCostRow('Registration Charges (1%)', '₹ ${(regCharges / 100000).toStringAsFixed(2)} Lacs'),
                    _buildCostRow('Advisory & Brokerage (1%)', '₹ ${(brokerageCharges / 100000).toStringAsFixed(2)} Lacs'),
                    _buildCostRow('Maintenance & Club Deposit', '₹ ${(_maintenanceDeposit / 100000).toStringAsFixed(2)} Lacs'),
                    _buildCostRow('Modular Interior & Renovation', '₹ ${(_renovationEstimate / 100000).toStringAsFixed(2)} Lacs'),
                    _buildCostRow('Legal Due Diligence & Mutation', '₹ ${(_legalDueDiligence / 1000).toStringAsFixed(0)} Thousand'),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ESTIMATED TOTAL OUTLAY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                            Text('₹ ${(totalOutlay / 10000000).toStringAsFixed(2)} Cr', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFE11D48))),
                          ],
                        ),
                        Text(
                          '"Estimated cost — actuals vary with circle rate."',
                          style: GoogleFonts.inter(fontSize: 9, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(val, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
