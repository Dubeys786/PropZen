import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/trust_engine_models.dart';
import '../services/trust_engine_service.dart';
import '../widgets/trust_engine_upload_area.dart';
import '../widgets/trust_engine_workflow_card.dart';
import '../widgets/trust_engine_extraction_table.dart';
import '../widgets/trust_engine_consistency_matrix.dart';
import '../widgets/trust_engine_risk_dashboard.dart';
import '../widgets/trust_engine_findings_card.dart';
import '../widgets/trust_engine_sources_card.dart';
import '../widgets/trust_engine_report_modal.dart';
import '../widgets/trust_engine_history_dialog.dart';

class TrustEngineScreen extends StatefulWidget {
  final PropertyDetailsInput? initialDetails;

  const TrustEngineScreen({super.key, this.initialDetails});

  @override
  State<TrustEngineScreen> createState() => _TrustEngineScreenState();
}

class _TrustEngineScreenState extends State<TrustEngineScreen> {
  final TrustEngineService _service = TrustEngineService.instance;

  late VerificationCase _currentCase;
  late PropertyDetailsInput _formInput;

  // Verification pipeline runtime state
  bool _isRunning = false;
  int _activeStep = 0;
  double _pipelineProgress = 0.0;
  StreamSubscription? _pipelineSub;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _formInput = widget.initialDetails?.copy() ?? PropertyDetailsInput();
    _currentCase = _service.createNewCase(_formInput);
  }

  @override
  void dispose() {
    _pipelineSub?.cancel();
    super.dispose();
  }

  void _startVerification() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _activeStep = 1;
      _pipelineProgress = 0.05;
      _errorMessage = null;
      _currentCase = _currentCase.copyWith(
        status: VerificationStatus.processing,
        propertyDetails: _formInput.copy(),
        lastUpdated: DateTime.now(),
      );
    });

    _pipelineSub?.cancel();
    _pipelineSub = _service.runVerificationPipeline(_currentCase).listen(
      (event) {
        if (mounted) {
          setState(() {
            _activeStep = event['step'] as int;
            _pipelineProgress = (event['progress'] as num).toDouble();
          });
        }
      },
      onDone: () {
        if (mounted) {
          final completed = _service.compileCompletedResults(_currentCase);
          setState(() {
            _isRunning = false;
            _activeStep = 8;
            _pipelineProgress = 1.0;
            _currentCase = completed;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isRunning = false;
            _errorMessage = 'Unable to complete verification. Please try again.';
          });
        }
      },
    );
  }

  void _resetNewCase() {
    _pipelineSub?.cancel();
    setState(() {
      _isRunning = false;
      _activeStep = 0;
      _pipelineProgress = 0.0;
      _errorMessage = null;
      _formInput = PropertyDetailsInput();
      _currentCase = _service.createNewCase(_formInput);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Module Top Header
                _buildHeader(),
                const SizedBox(height: 20),

                // Error State Banner (Sanitized)
                if (_errorMessage != null) ...[
                  _buildErrorBanner(),
                  const SizedBox(height: 20),
                ],

                // 2. Verification Overview Card
                _buildOverviewCard(),
                const SizedBox(height: 24),

                // 3. Document Upload Area
                TrustEngineUploadArea(
                  documents: _currentCase.documents,
                  onDocumentAdded: (doc) {
                    setState(() {
                      _currentCase = _service.addDocumentToCase(_currentCase, doc);
                    });
                  },
                  onDocumentRemoved: (id) {
                    setState(() {
                      _currentCase = _service.removeDocumentFromCase(_currentCase, id);
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 4. Property Information Form
                _buildPropertyDetailsForm(),
                const SizedBox(height: 24),

                // 5. Verification Workflow Timeline
                if (_isRunning || _activeStep > 0) ...[
                  TrustEngineWorkflowCard(
                    activeStep: _activeStep,
                    overallProgress: _pipelineProgress,
                    isRunning: _isRunning,
                  ),
                  const SizedBox(height: 24),
                ],

                // 6. AI Extracted Information Table
                TrustEngineExtractionTable(fields: _currentCase.extractedFields),
                const SizedBox(height: 24),

                // 7. Cross-Document Consistency Matrix
                TrustEngineConsistencyMatrix(consistencyRows: _currentCase.consistencyRows),
                const SizedBox(height: 24),

                // 8. Multi-Vector Risk Analysis Dashboard
                TrustEngineRiskDashboard(
                  overallRisk: _currentCase.overallRiskLevel,
                  numericalScore: _currentCase.numericalRiskScore,
                  categories: _currentCase.riskCategories,
                ),
                const SizedBox(height: 24),

                // 9. AI Verification Findings
                TrustEngineFindingsCard(findings: _currentCase.findings),
                const SizedBox(height: 24),

                // 10. Authorized Source Verification
                TrustEngineSourcesCard(sources: _currentCase.sources),
                const SizedBox(height: 24),

                // 11. Verification Report Preview & Legal Disclaimer
                _buildReportSummaryCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. TOP MODULE HEADER
  // =========================================================================
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'PROPZEN TRUST ENGINE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Secure Verification',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.lock, size: 10, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        'Secure Processing',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'AI Property Verification',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Verify property documents, ownership information and risk indicators with one intelligent workflow.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.history, size: 14, color: Color(0xFF475569)),
              label: const Text('Verification History'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                TrustEngineHistoryDialog.show(
                  context,
                  history: _service.history,
                  onSelectCase: (selected) {
                    setState(() {
                      _currentCase = selected;
                      _formInput = selected.propertyDetails.copy();
                    });
                  },
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.download, size: 14, color: Color(0xFF475569)),
              label: const Text('Download Report'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                TrustEngineReportModal.show(context, _currentCase);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('New Verification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              onPressed: _resetNewCase,
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            actionButtons,
          ],
        );
      },
    );
  }

  // =========================================================================
  // ERROR BANNER (Sanitized)
  // =========================================================================
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to complete verification',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                ),
                Text(
                  'Please check your connection and try again.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            onPressed: _startVerification,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. VERIFICATION OVERVIEW CARD
  // =========================================================================
  Widget _buildOverviewCard() {
    final v = _currentCase;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Overview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: v.status.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: v.status.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: v.status.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      v.status.label,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: v.status.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 750;

              if (isWide) {
                return Row(
                  children: [
                    _overviewTile('Verification ID', v.id, isAccent: true),
                    _overviewTile('Property', v.propertyTitle),
                    _overviewTile('Location', v.location),
                    _overviewTile('Owner', v.ownerName),
                    _overviewTile('Last Updated', '${v.lastUpdated.day}/${v.lastUpdated.month}/${v.lastUpdated.year}'),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      _overviewTile('Verification ID', v.id, isAccent: true),
                      _overviewTile('Property', v.propertyTitle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _overviewTile('Location', v.location),
                      _overviewTile('Owner', v.ownerName),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _overviewTile(String label, String value, {bool isAccent = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isAccent ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. PROPERTY DETAILS FORM
  // =========================================================================
  Widget _buildPropertyDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.home, size: 16, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Property Details & Legal Identifiers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                'Editable before initiating analysis',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Confirm the physical and municipal coordinates against the deeds you have uploaded.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          // Fields Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final colCount = isWide ? 3 : 1;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _fieldWrapper('Property Type', _formInput.propertyType, (val) => _formInput.propertyType = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Address', _formInput.address, (val) => _formInput.address = val, colCount, constraints.maxWidth),
                  _fieldWrapper('City', _formInput.city, (val) => _formInput.city = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Sector / Locality', _formInput.sectorLocality, (val) => _formInput.sectorLocality = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Plot Number', _formInput.plotNumber, (val) => _formInput.plotNumber = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Survey / Khasra No.', _formInput.surveyKhasraNumber, (val) => _formInput.surveyKhasraNumber = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Area (${_formInput.unit})', _formInput.area, (val) => _formInput.area = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Owner Name', _formInput.ownerName, (val) => _formInput.ownerName = val, colCount, constraints.maxWidth),
                  _fieldWrapper('Registration Number', _formInput.registrationNumber, (val) => _formInput.registrationNumber = val, colCount, constraints.maxWidth),
                ],
              );
            },
          ),
          const SizedBox(height: 22),

          // Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: _isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.playCircle, size: 16),
                label: Text(_isRunning ? 'Processing Verification...' : 'Start AI Verification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                onPressed: _isRunning ? null : _startVerification,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldWrapper(String label, String initialValue, ValueChanged<String> onChanged, int colCount, double maxWidth) {
    final itemWidth = colCount > 1 ? (maxWidth - (colCount - 1) * 14) / colCount : maxWidth;

    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 11. VERIFICATION REPORT SUMMARY CARD & LEGAL DISCLAIMER
  // =========================================================================
  Widget _buildReportSummaryCard() {
    final v = _currentCase;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.award, size: 16, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PropZen Verification Certificate & Report',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(LucideIcons.fileCheck, size: 14),
                label: const Text('Open Full Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => TrustEngineReportModal.show(context, v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'The complete audit certificate aggregates document OCR provenance, encumbrance clearances, e-court checks, and authority registrations in a unified verifiable package.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 20),

          // Legal Disclaimer
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
                const Icon(LucideIcons.info, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEGAL NOTICE & REGULATORY DISCLAIMER',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 3),
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
    );
  }
}
