import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_theme.dart';
import '../models/trust_engine_models.dart';
import '../services/trust_engine_service.dart';

/// Master Verification Workspace View embedded in the PropZen Command Center.
/// Features a dedicated 7-tab sub-navigation connecting to live backend APIs.
class VerificationWorkspaceView extends StatefulWidget {
  final bool isDesktop;

  const VerificationWorkspaceView({super.key, this.isDesktop = true});

  @override
  State<VerificationWorkspaceView> createState() => _VerificationWorkspaceViewState();
}

class _VerificationWorkspaceViewState extends State<VerificationWorkspaceView> {
  final TrustEngineService _service = TrustEngineService.instance;

  int _selectedTab = 0; // 0..6
  bool _isLoading = true;
  String? _errorMessage;

  // Live Backend Data
  VerificationMetrics _metrics = VerificationMetrics.zero;
  List<VerificationCase> _cases = [];
  List<VerificationDocument> _documents = [];
  VerificationCase? _activeCase;

  // Search & Filter state for Cases Tab
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'ALL';
  String _riskFilter = 'ALL';
  int _currentPage = 0;

  // New Verification Wizard Form State
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _sectorController = TextEditingController();
  final _khasraController = TextEditingController();
  final _plotController = TextEditingController();
  final _areaController = TextEditingController();
  final _ownerController = TextEditingController();
  final _regNumController = TextEditingController();
  final _regDateController = TextEditingController();
  String _selectedPropertyType = 'Apartment';
  final List<VerificationDocument> _wizardDocuments = [];
  bool _isProcessingAi = false;
  bool _isActionInProgress = false;
  int _verificationStage = 0; // 0 to 8

  final List<String> _tabLabels = [
    'AI Property Verification',
    'New Verification',
    'Verification Cases',
    'Documents',
    'Risk Analysis',
    'Verification Reports',
    'Verification History',
  ];

  final List<IconData> _tabIcons = [
    LucideIcons.shieldCheck,
    LucideIcons.plusCircle,
    LucideIcons.fileText,
    LucideIcons.folder,
    LucideIcons.alertTriangle,
    LucideIcons.fileSpreadsheet,
    LucideIcons.history,
  ];

  @override
  void initState() {
    super.initState();
    _loadLiveBackendData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _sectorController.dispose();
    _khasraController.dispose();
    _plotController.dispose();
    _areaController.dispose();
    _ownerController.dispose();
    _regNumController.dispose();
    _regDateController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveBackendData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final metricsFuture = _service.getDashboardMetrics();
      final casesFuture = _service.searchCases(
        query: _searchController.text.trim(),
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        riskLevel: _riskFilter == 'ALL' ? null : _riskFilter,
        page: _currentPage,
        size: 15,
      );
      final docsFuture = _service.fetchDocuments(page: 0, size: 30);

      final results = await Future.wait([metricsFuture, casesFuture, docsFuture]);

      if (mounted) {
        setState(() {
          _metrics = results[0] as VerificationMetrics;
          _cases = results[1] as List<VerificationCase>;
          _documents = results[2] as List<VerificationDocument>;
          if (_cases.isNotEmpty && _activeCase == null) {
            _activeCase = _cases.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to connect to PropZen verification service.';
        });
      }
    }
  }

  void _switchTab(int index) {
    setState(() {
      _selectedTab = index;
    });
    if (index == 2 || index == 3 || index == 6) {
      _loadLiveBackendData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.pageBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-Navigation Tab Bar
          _buildSubNavigationTabBar(),

          // Main Tab Body
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildCurrentTabView(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-NAVIGATION TAB BAR
  // ===========================================================================
  Widget _buildSubNavigationTabBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabLabels.length, (i) {
            final isSelected = _selectedTab == i;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _switchTab(i),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tabIcons[i],
                        size: 15,
                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tabLabels[i],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                        ),
                      ),
                      if (i == 2 && _metrics.underReview > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_metrics.underReview}',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentTabView() {
    switch (_selectedTab) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildNewVerificationWizardTab();
      case 2:
        return _buildVerificationCasesTab();
      case 3:
        return _buildDocumentsTab();
      case 4:
        return _buildRiskAnalysisTab();
      case 5:
        return _buildVerificationReportTab();
      case 6:
        return _buildVerificationHistoryTab();
      default:
        return _buildDashboardTab();
    }
  }

  // ===========================================================================
  // TAB 0: AI PROPERTY VERIFICATION DASHBOARD
  // ===========================================================================
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 22, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 8),
                      Text(
                        'AI Property Verification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI-powered property document analysis, consistency checking and risk assessment.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onPressed: _loadLiveBackendData,
                    icon: const Icon(LucideIcons.refreshCw, size: 14, color: Color(0xFF475569)),
                    label: Text('Refresh', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    onPressed: () => _switchTab(6),
                    icon: const Icon(LucideIcons.history, size: 14, color: Color(0xFF475569)),
                    label: Text('Verification History', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => _switchTab(1),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: Text('+ New Verification', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 5 Live KPI Cards
          GridView.count(
            crossAxisCount: widget.isDesktop ? 5 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: widget.isDesktop ? 2.1 : 1.7,
            children: [
              _buildKpiCard('Total Verification Cases', '${_metrics.totalCases}', 'All time submissions', LucideIcons.shield, const Color(0xFF4F46E5)),
              _buildKpiCard('Verified', '${_metrics.verified}', 'Passed trust criteria', LucideIcons.checkCircle2, const Color(0xFF10B981)),
              _buildKpiCard('Under Review', '${_metrics.underReview}', 'Pending administrative audit', LucideIcons.clock, const Color(0xFFF59E0B)),
              _buildKpiCard('High Risk', '${_metrics.highRisk}', 'Discrepancies flagged', LucideIcons.alertTriangle, const Color(0xFFEF4444)),
              _buildKpiCard('Documents Processed', '${_metrics.documentsProcessed}', 'OCR & extracted deeds', LucideIcons.fileCheck, const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Cases Section / Empty State
          Text(
            'Recent Verification Cases',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          if (_cases.isEmpty)
            _buildEmptyState(
              title: 'No properties are currently awaiting AI verification.',
              message: 'New property submissions and verification cases will appear here for 8-step AI analysis and administrative review.',
              buttonLabel: '+ New Verification',
              onAction: () => _switchTab(1),
            )
          else
            _buildCasesDataTable(_cases.take(5).toList()),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: NEW VERIFICATION WIZARD
  // ===========================================================================
  Widget _buildNewVerificationWizardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Property Verification', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('Provide property information and upload legal title deeds for AI analysis.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                      IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => _switchTab(0)),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xFFE2E8F0)),

                  // Step 1 Header
                  _buildStepHeader('Step 1', 'Property Information'),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Property Title *', border: OutlineInputBorder(), hintText: 'e.g. Greenfield 4BHK Villa'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Property title is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPropertyType,
                          decoration: const InputDecoration(labelText: 'Property Type *', border: OutlineInputBorder()),
                          items: ['Apartment', 'Villa', 'Plot', 'Commercial', 'Penthouse', 'Independent Floor']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _selectedPropertyType = v ?? 'Apartment'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'City is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sectorController,
                          decoration: const InputDecoration(labelText: 'Sector / Locality', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _khasraController,
                          decoration: const InputDecoration(labelText: 'Khasra / Survey Number', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _plotController,
                          decoration: const InputDecoration(labelText: 'Plot / Unit Number', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(labelText: 'Area (e.g. 2400 Sq.Ft)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ownerController,
                          decoration: const InputDecoration(labelText: 'Owner Name *', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Owner name is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _regNumController,
                          decoration: const InputDecoration(labelText: 'Registration Number', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _regDateController,
                          decoration: const InputDecoration(labelText: 'Registration Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Step 2 Header
                  _buildStepHeader('Step 2', 'Document Upload'),
                  const SizedBox(height: 12),

                  // Upload Drag / Click Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.uploadCloud, size: 36, color: Color(0xFF4F46E5)),
                        const SizedBox(height: 8),
                        Text('Upload legal title documents (PDF, JPG, JPEG, PNG)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Supported: Sale Deed, Registry, Khatauni, Mutation, Property Tax Receipt, Identity Document', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildQuickUploadBtn('Sale Deed', 'Sale_Deed.pdf'),
                            _buildQuickUploadBtn('Registry', 'Registry_Certificate.pdf'),
                            _buildQuickUploadBtn('Khatauni', 'Khatauni_Revenue_Extract.pdf'),
                            _buildQuickUploadBtn('Identity', 'Aadhaar_KYC_Owner.pdf'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Uploaded Document List
                  if (_wizardDocuments.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _wizardDocuments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final d = _wizardDocuments[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.fileText, size: 16, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text('${d.documentType} • ${d.formattedSize}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                child: Text('Ready for AI', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                                onPressed: () => setState(() => _wizardDocuments.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Step 3 / Start Verification Section
                  if (_isProcessingAi) ...[
                    _buildVerificationProgressCard(),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _switchTab(0),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isProcessingAi ? null : _handleStartAiVerification,
                        icon: const Icon(LucideIcons.sparkles, size: 16),
                        label: Text('START AI VERIFICATION', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String stepBadge, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(stepBadge, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5))),
        ),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildQuickUploadBtn(String docType, String defaultFilename) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      onPressed: () {
        setState(() {
          _wizardDocuments.add(VerificationDocument(
            id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
            name: defaultFilename,
            documentType: docType,
            fileSizeBytes: 2048000,
            status: DocumentProcessingStatus.uploaded,
            uploadedAt: DateTime.now(),
          ));
        });
      },
      icon: const Icon(LucideIcons.plus, size: 12),
      label: Text('+ Add $docType', style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildVerificationProgressCard() {
    final stages = [
      'Document Ingestion & Integrity Analysis',
      'OCR & Extracted Information Assembly',
      'Cross-Document Consistency Reconciliation',
      'Title & Conveyance Deed Verification',
      'Revenue & Sub-Registrar Reconciliation',
      'Encumbrance & Duplicate Detection',
      'AI Risk Scoring & Classification',
      'Audit Trail Assembly & Report Finalization',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4F46E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AI Verification Pipeline in Progress...', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5))),
              Text('${((_verificationStage / 8) * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF4F46E5))),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _verificationStage / 8, color: const Color(0xFF4F46E5), backgroundColor: const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: List.generate(stages.length, (idx) {
              final isDone = _verificationStage > idx;
              final isCurrent = _verificationStage == idx;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFECFDF5) : (isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? LucideIcons.checkCircle : (isCurrent ? LucideIcons.loader2 : LucideIcons.circle),
                      size: 10,
                      color: isDone ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 4),
                    Text(stages[idx], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: isDone ? const Color(0xFF059669) : const Color(0xFF475569))),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartAiVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessingAi = true;
      _verificationStage = 1;
    });

    final details = PropertyDetailsInput(
      propertyType: _selectedPropertyType,
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      sectorLocality: _sectorController.text.trim(),
      surveyKhasraNumber: _khasraController.text.trim(),
      plotNumber: _plotController.text.trim(),
      area: _areaController.text.trim(),
      ownerName: _ownerController.text.trim(),
      registrationNumber: _regNumController.text.trim(),
      registrationDate: _regDateController.text.trim(),
    );

    try {
      // 1. Submit Case to Java Spring Boot Backend
      final createdCase = await _service.submitCaseToBackend(details, _wizardDocuments);
      setState(() => _verificationStage = 4);

      // 2. Execute 8-step AI Verification Pipeline on Backend
      final verifiedCase = await _service.triggerAiVerification(createdCase.id);
      setState(() {
        _verificationStage = 8;
        _activeCase = verifiedCase;
        _isProcessingAi = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Property Verification completed successfully!')),
      );

      // Refresh data & switch to Report View
      await _loadLiveBackendData();
      if (!mounted) return;
      _switchTab(4); // Switch to Risk Analysis / Report
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification Pipeline Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===========================================================================
  // TAB 2: VERIFICATION CASES
  // ===========================================================================
  Widget _buildVerificationCasesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Verification Cases', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
                onPressed: () => _switchTab(1),
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('+ New Verification'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search & Filters Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadLiveBackendData(),
                    decoration: InputDecoration(
                      hintText: 'Search by case ID, title, owner, city...',
                      prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: ['ALL', 'PENDING', 'PROCESSING', 'VERIFIED', 'UNDER_REVIEW', 'NEEDS_CORRECTION', 'REJECTED']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    setState(() => _statusFilter = val ?? 'ALL');
                    _loadLiveBackendData();
                  },
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _riskFilter,
                  items: ['ALL', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'UNKNOWN']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (val) {
                    setState(() => _riskFilter = val ?? 'ALL');
                    _loadLiveBackendData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_cases.isEmpty)
            _buildEmptyState(
              title: 'No properties are currently awaiting AI verification.',
              message: 'Try adjusting your search criteria or register a new property for 8-step verification.',
              buttonLabel: '+ New Verification',
              onAction: () => _switchTab(1),
            )
          else
            _buildCasesDataTable(_cases),
        ],
      ),
    );
  }

  Widget _buildCasesDataTable(List<VerificationCase> casesList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(2.0),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(0.8),
          4: FlexColumnWidth(1.0),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(1.0),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            children: [
              _th('Case ID'),
              _th('Property'),
              _th('Owner'),
              _th('Docs'),
              _th('Risk'),
              _th('Status'),
              _th('Action'),
            ],
          ),
          ...casesList.map((c) {
            return TableRow(
              children: [
                _tdText(c.id, isBold: true),
                _tdText(c.propertyTitle),
                _tdText(c.ownerName),
                _tdText('${c.documents.length}'),
                _tdRiskBadge(c.overallRiskLevel),
                _tdStatusBadge(c.status),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => _activeCase = c);
                          _switchTab(4); // View Details / Risk Analysis
                        },
                        child: const Text('View Details', style: TextStyle(fontSize: 12)),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreVertical, size: 14),
                        tooltip: 'Actions',
                        onSelected: (val) {
                          if (val == 'VERIFY') {
                            _handleReverifyCase(c);
                          } else {
                            _handleUpdateStatus(c, val);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'VERIFY',
                            child: Row(
                              children: [
                                Icon(LucideIcons.refreshCw, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 8),
                                Text('Re-run AI Verification', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'VERIFIED',
                            child: Row(
                              children: [
                                Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text('Approve (VERIFIED)', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'UNDER_REVIEW',
                            child: Row(
                              children: [
                                Icon(LucideIcons.clock, size: 14, color: Color(0xFFF59E0B)),
                                SizedBox(width: 8),
                                Text('Mark for Review', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'NEEDS_CORRECTION',
                            child: Row(
                              children: [
                                Icon(LucideIcons.edit3, size: 14, color: Color(0xFFD97706)),
                                SizedBox(width: 8),
                                Text('Request Correction', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'REJECTED',
                            child: Row(
                              children: [
                                Icon(LucideIcons.xCircle, size: 14, color: Color(0xFFEF4444)),
                                SizedBox(width: 8),
                                Text('Reject Case', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _th(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
    );
  }

  Widget _tdText(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, color: AppTheme.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tdStatusBadge(VerificationStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: status.backgroundColor, borderRadius: BorderRadius.circular(6)),
        child: Text(status.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: status.color)),
      ),
    );
  }

  Widget _tdRiskBadge(RiskLevel risk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: risk.backgroundColor, borderRadius: BorderRadius.circular(6)),
        child: Text(risk.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: risk.color)),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: DOCUMENTS
  // ===========================================================================
  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Document Repository', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('${_documents.length} Total Documents in Archive', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 16),

          if (_documents.isEmpty)
            _buildEmptyState(
              title: 'No documents processed',
              message: 'Documents uploaded during property verification will appear here.',
              buttonLabel: '+ New Verification',
              onAction: () => _switchTab(1),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.isDesktop ? 3 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _documents.length,
              itemBuilder: (ctx, i) {
                final d = _documents[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(LucideIcons.fileText, color: Color(0xFF4F46E5), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(d.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${d.documentType} • ${d.formattedSize}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text('Uploaded: ${d.formattedUploadDate}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.download, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _handleReverifyCase(VerificationCase activeCase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.refreshCw, color: Color(0xFF4F46E5), size: 20),
            SizedBox(width: 8),
            Text('Re-run AI Verification?'),
          ],
        ),
        content: Text(
          'Re-executing the 8-step AI verification pipeline for "${activeCase.propertyTitle}" will re-analyze deed documents and update cadastral telemetry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Execute Verification'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionInProgress = true);
    try {
      final updated = await _service.triggerAiVerification(activeCase.id);
      if (mounted) {
        setState(() {
          _activeCase = updated;
          _isActionInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI verification re-run completed for Case ${activeCase.id}!'), backgroundColor: const Color(0xFF10B981)),
        );
        _loadLiveBackendData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to re-run AI verification: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleUpdateStatus(VerificationCase activeCase, String newStatus, {String? defaultNotes}) async {
    final notesController = TextEditingController(text: defaultNotes ?? '');
    final actionLabel = switch (newStatus) {
      'VERIFIED' => 'Approve as Verified',
      'UNDER_REVIEW' => 'Mark for Review',
      'NEEDS_CORRECTION' => 'Request Correction',
      'REJECTED' => 'Reject Case',
      _ => newStatus,
    };

    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update case "${activeCase.propertyTitle}" status to $newStatus.'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Administrative Notes / Reason (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter notes for audit trail...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'VERIFIED'
                  ? const Color(0xFF10B981)
                  : (newStatus == 'REJECTED' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (isConfirmed != true) return;

    setState(() => _isActionInProgress = true);
    try {
      final updated = await _service.updateCaseStatus(
        activeCase.id,
        newStatus,
        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _activeCase = updated;
          _isActionInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Case ${activeCase.id} updated to $newStatus successfully!'), backgroundColor: const Color(0xFF10B981)),
        );
        _loadLiveBackendData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildAdminActionToolbar(VerificationCase active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF4F46E5)),
              const SizedBox(width: 8),
              Text('Administrative Actions:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              _tdStatusBadge(active.status),
            ],
          ),
          if (_isActionInProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _handleReverifyCase(active),
                  icon: const Icon(LucideIcons.refreshCw, size: 13),
                  label: const Text('Re-run Verification', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: active.status == VerificationStatus.verified ? null : () => _handleUpdateStatus(active, 'VERIFIED'),
                  icon: const Icon(LucideIcons.checkCircle2, size: 13),
                  label: const Text('Approve (VERIFIED)', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: active.status == VerificationStatus.underReview ? null : () => _handleUpdateStatus(active, 'UNDER_REVIEW'),
                  icon: const Icon(LucideIcons.clock, size: 13),
                  label: const Text('Mark for Review', style: TextStyle(fontSize: 11)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD97706),
                    side: const BorderSide(color: Color(0xFFD97706)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => _handleUpdateStatus(active, 'NEEDS_CORRECTION'),
                  icon: const Icon(LucideIcons.edit3, size: 13),
                  label: const Text('Request Correction', style: TextStyle(fontSize: 11)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: active.status == VerificationStatus.highRisk ? null : () => _handleUpdateStatus(active, 'REJECTED'),
                  icon: const Icon(LucideIcons.xCircle, size: 13),
                  label: const Text('Reject', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEightStepPipelineCard(VerificationCase active) {
    final stages = [
      {'num': '1', 'name': 'Document Ingestion & Integrity Analysis', 'desc': 'Digital signature verification, tampering detection, resolution audit'},
      {'num': '2', 'name': 'OCR & Extracted Information Assembly', 'desc': 'Khasra numbers, plot telemetry, owner names, deed dates'},
      {'num': '3', 'name': 'Cross-Document Consistency Reconciliation', 'desc': 'Multi-deed cross-check: Sale deed vs Registry vs Khatauni'},
      {'num': '4', 'name': 'Title & Conveyance Deed Verification', 'desc': '30-year conveyance chain continuity, chain-of-title integrity'},
      {'num': '5', 'name': 'Revenue & Sub-Registrar Authority Reconciliation', 'desc': 'Jurisdictional cadastral record hash check against land archives'},
      {'num': '6', 'name': 'Encumbrance & Duplicate Detection', 'desc': 'Bank mortgage records, non-encumbrance certificate checks, duplicate listings'},
      {'num': '7', 'name': 'AI Risk Scoring & Classification', 'desc': 'Deterministic rule evaluation with neural risk scoring and confidence rating'},
      {'num': '8', 'name': 'Audit Trail Assembly & Report Finalization', 'desc': 'Immutable timestamped audit log, cryptographic hash, formal report certificate'},
    ];

    final isDone = active.status == VerificationStatus.verified;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
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
                  const Icon(LucideIcons.layers, color: Color(0xFF4F46E5), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '8-Step AI Property Verification Pipeline',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDone ? '8 of 8 Steps Complete' : 'Pipeline Executed',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDone ? const Color(0xFF059669) : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            separatorBuilder: (_, __) => const Divider(height: 14, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, idx) {
              final step = stages[idx];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Center(
                      child: Text(
                        step['num']!,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['name']!,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['desc']!,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 16),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: RISK ANALYSIS
  // ===========================================================================
  Widget _buildRiskAnalysisTab() {
    final active = _activeCase ?? (_cases.isNotEmpty ? _cases.first : null);

    if (active == null) {
      return _buildEmptyState(
        title: 'No case selected for risk analysis',
        message: 'Create or select a property verification case to view the risk breakdown.',
        buttonLabel: '+ New Verification',
        onAction: () => _switchTab(1),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risk Analysis: ${active.propertyTitle}', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('Case ID: ${active.id} • Owner: ${active.ownerName}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _switchTab(5),
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 14),
                    label: const Text('View Full Report'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Administrative Action Toolbar
          _buildAdminActionToolbar(active),
          const SizedBox(height: 16),

          // 8-Step Pipeline Status Card
          _buildEightStepPipelineCard(active),
          const SizedBox(height: 16),

          // Overall Risk Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: active.overallRiskLevel.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active.overallRiskLevel.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.shieldAlert, color: active.overallRiskLevel.color, size: 32),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Property Risk Level', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                        Text(active.overallRiskLevel.label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: active.overallRiskLevel.color)),
                      ],
                    ),
                  ],
                ),
                if (active.numericalRiskScore != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Trust Index Score', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      Text('${active.numericalRiskScore!.toInt()}/100', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: active.overallRiskLevel.color)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 7 Individual Checks
          Text('7-Pillar Verification Checks', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: active.riskCategories.isNotEmpty ? active.riskCategories.length : 3,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              if (active.riskCategories.isEmpty) {
                return const SizedBox();
              }
              final r = active.riskCategories[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle2, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.categoryName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(r.explanation, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                      child: Text(r.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 5: VERIFICATION REPORTS
  // ===========================================================================
  Widget _buildVerificationReportTab() {
    final active = _activeCase ?? (_cases.isNotEmpty ? _cases.first : null);

    if (active == null) {
      return _buildEmptyState(
        title: 'No report available',
        message: 'Select or execute a property verification case to generate an official report.',
        buttonLabel: '+ New Verification',
        onAction: () => _switchTab(1),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAdminActionToolbar(active),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PROPZEN AI PROPERTY VERIFICATION REPORT', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF4F46E5), letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text('Official Cadastral, Title & Encumbrance Telemetry Audit', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Downloading official PDF report...')),
                            );
                          },
                          icon: const Icon(LucideIcons.download, size: 14),
                          label: const Text('Download PDF'),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Color(0xFFE2E8F0)),

                    // Case Information
                    _buildReportSectionTitle('1. Case Information'),
                    const SizedBox(height: 8),
                    _buildReportDataGrid([
                      {'Case ID': active.id, 'Created Date': active.formattedUpdatedDate},
                      {'Property Title': active.propertyTitle, 'Status': active.status.label},
                      {'Owner Name': active.ownerName, 'Risk Level': active.overallRiskLevel.label},
                    ]),
                    const SizedBox(height: 24),

                    // Property Information
                    _buildReportSectionTitle('2. Property Information'),
                    const SizedBox(height: 8),
                    _buildReportDataGrid([
                      {'Address': active.location, 'City': active.propertyDetails.city},
                      {'Property Type': active.propertyDetails.propertyType, 'Area': '${active.propertyDetails.area} ${active.propertyDetails.unit}'},
                      {'Survey / Khasra': active.propertyDetails.surveyKhasraNumber, 'Registration Number': active.propertyDetails.registrationNumber},
                    ]),
                    const SizedBox(height: 24),

                    // 8-Step Verification Pipeline Telemetry
                    _buildReportSectionTitle('3. 8-Step AI Verification Pipeline Telemetry'),
                    const SizedBox(height: 8),
                    _buildEightStepPipelineCard(active),
                    const SizedBox(height: 24),

                    // Documents Analysed
                    _buildReportSectionTitle('4. Documents Analysed'),
                    const SizedBox(height: 8),
                    Text('${active.documents.length} legal deeds verified against public records.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                    const SizedBox(height: 24),

                    // Extracted Information
                    _buildReportSectionTitle('5. Extracted Information & Cross-Document Consistency'),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        _th('Attribute'),
                        _th('Extracted Value'),
                        _th('Match Status'),
                        _th('Notes'),
                      ],
                    ),
                    ...active.consistencyRows.map((r) => TableRow(
                          children: [
                            _tdText(r.attributeName, isBold: true),
                            _tdText(r.documentAValue),
                            _tdText(r.matchStatus.label),
                            _tdText(r.differenceNotes),
                          ],
                        )),
                  ],
                ),
                const SizedBox(height: 24),

                // Risk Assessment & AI Findings
                _buildReportSectionTitle('5. Risk Assessment & AI Findings'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Verification Result:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Ownership title confirmed with uninterrupted 30-year conveyance records. Digital registry hashes verified.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
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
);
  }

  Widget _buildReportSectionTitle(String title) {
    return Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimary));
  }

  Widget _buildReportDataGrid(List<Map<String, String>> data) {
    return Column(
      children: data.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: row.entries.map((entry) {
              return Expanded(
                child: Row(
                  children: [
                    Text('${entry.key}: ', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    Expanded(child: Text(entry.value, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // TAB 6: VERIFICATION HISTORY
  // ===========================================================================
  Widget _buildVerificationHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Verification History & Audit Milestones', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
              OutlinedButton.icon(
                onPressed: _loadLiveBackendData,
                icon: const Icon(LucideIcons.refreshCw, size: 14),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_cases.isEmpty)
            _buildEmptyState(
              title: 'No verification history',
              message: 'Past cases and audits will be logged chronologically here.',
              buttonLabel: '+ New Verification',
              onAction: () => _switchTab(1),
            )
          else
            _buildCasesDataTable(_cases),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY & ERROR STATES
  // ===========================================================================
  Widget _buildEmptyState({
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF4F46E5).withOpacity(0.08),
              child: const Icon(LucideIcons.shieldCheck, size: 28, color: Color(0xFF4F46E5)),
            ),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
              onPressed: onAction,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 36, color: Colors.amber),
            const SizedBox(height: 12),
            Text(_errorMessage ?? 'Unable to connect to PropZen verification service.', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadLiveBackendData,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
    );
  }
}
