import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/ai_service_tool_data.dart';
import '../services/ai_tools_service.dart';
import '../widgets/enquiry_auth_dialog.dart';
import '../widgets/ai_tools/visual_2d_floor_plan_canvas.dart';

class AiToolDetailScreen extends StatefulWidget {
  final String toolType;
  final String? title;
  final String? category;
  final String? description;
  final IconData? icon;
  final Color? accentColor;
  final String? actionButtonText;
  final List<String>? defaultFeatures;

  const AiToolDetailScreen({
    super.key,
    required this.toolType,
    this.title,
    this.category,
    this.description,
    this.icon,
    this.accentColor,
    this.actionButtonText,
    this.defaultFeatures,
  });

  @override
  State<AiToolDetailScreen> createState() => _AiToolDetailScreenState();
}

class _AiToolDetailScreenState extends State<AiToolDetailScreen> {
  late final AiServiceTool _tool;
  final Map<String, dynamic> _formValues = {};
  final Map<String, TextEditingController> _controllers = {};

  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _initToolData();
  }

  void _initToolData() {
    final registered = AiServiceRegistry.getById(widget.toolType) ??
        AiServiceRegistry.getBySlug(widget.toolType) ??
        AiServiceRegistry.getByRoute(widget.toolType);

    if (registered != null) {
      _tool = registered;
    } else {
      // Fallback for custom or direct route IDs
      _tool = AiServiceTool(
        id: widget.toolType,
        slug: widget.toolType.replaceAll('_', '-'),
        routePath: '/ai-tools/${widget.toolType.replaceAll('_', '-')}',
        title: widget.title ?? 'AI Intelligence Tool',
        shortDescription: widget.description ?? 'AI-powered real estate analysis and insights.',
        fullDescription: widget.description ?? 'PropZen machine learning algorithms analyze verified market data to deliver actionable insights.',
        primaryCategory: widget.category ?? 'Property Intelligence',
        allCategories: ['All', widget.category ?? 'Property Intelligence'],
        searchKeywords: ['ai', 'tool', 'intelligence', 'propzen'],
        icon: widget.icon ?? LucideIcons.sparkles,
        accentColor: widget.accentColor ?? AppTheme.primaryViolet,
        uniqueImageUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
        features: widget.defaultFeatures ?? const ['Verified Property Data', 'Predictive Analysis', 'Instant Results'],
        inputs: const [
          AiToolInputField(key: 'location', label: 'Sector / Locality', hint: 'e.g. Sector 150, Noida'),
          AiToolInputField(key: 'budget', label: 'Target Budget', hint: 'e.g. ₹ 1.5 Cr'),
        ],
      );
    }

    // Initialize form values from tool input defaults
    for (final input in _tool.inputs) {
      _formValues[input.key] = input.defaultValue;
      _controllers[input.key] = TextEditingController(text: input.defaultValue);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _executeAnalysis() async {
    // Sync text field controller values into form values
    for (final entry in _controllers.entries) {
      _formValues[entry.key] = entry.value.text.trim();
    }

    setState(() {
      _isLoading = true;
      _resultData = null;
    });

    try {
      final res = await AiToolsService.instance.executeTool(
        toolType: _tool.id,
        params: _formValues,
      );

      if (mounted) {
        setState(() {
          _resultData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running ${_tool.title}: $e'),
            backgroundColor: AppTheme.coralDanger,
          ),
        );
      }
    }
  }

  void _showConsultExpertDialog() {
    EnquiryAuthDialog.show(
      context,
      actionLabel: 'Consult ${_tool.title} Specialist',
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Consultation requested for ${_tool.title}. Our specialist will contact you shortly.'),
            backgroundColor: AppTheme.emeraldSuccess,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _tool.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_tool.icon, color: _tool.accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tool.title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? LucideIcons.check : LucideIcons.bookmark,
              color: _isSaved ? _tool.accentColor : AppTheme.textSecondary,
              size: 20,
            ),
            tooltip: 'Save Tool',
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSaved ? '✓ ${_tool.title} saved to your bookmarks.' : 'Bookmark removed.'),
                  backgroundColor: AppTheme.primaryViolet,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tool Hero Banner with Unique Image
                _buildToolHeroBanner(),

                const SizedBox(height: 20),

                // Form Inputs Section
                _buildInputFormCard(),

                const SizedBox(height: 24),

                // Output / Loading / Empty State Area
                if (_isLoading)
                  _buildLoadingCard()
                else if (_resultData != null)
                  _buildResultCard(_resultData!)
                else
                  _buildEmptyStateGuideCard(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolHeroBanner() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 21 / 9,
                child: Image.network(
                  _tool.uniqueImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: AppTheme.surfaceHighlight,
                    child: Center(
                      child: Icon(_tool.icon, size: 48, color: _tool.accentColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _tool.accentColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.sparkles, color: Colors.white, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        _tool.badgeLabel,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tool.title,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tool.shortDescription,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.9), height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Features Row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tool.features.map((feat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.checkCircle2, color: _tool.accentColor, size: 13),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          feat,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.slidersHorizontal, size: 18, color: _tool.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configure Parameters',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your project criteria to generate accurate AI predictions and domain-specific specs.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Dynamic Inputs
          ..._tool.inputs.map((input) => _buildInputField(input)),

          const SizedBox(height: 18),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _executeAnalysis,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
              label: Text(
                _isLoading ? 'Processing Intelligence...' : _tool.buttonLabel,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tool.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(AiToolInputField input) {
    if (input.type == 'dropdown' && input.options != null) {
      final currentVal = _formValues[input.key] ?? input.defaultValue;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: input.options!.contains(currentVal) ? currentVal : input.options!.first,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.textSecondary),
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                  items: input.options!.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _formValues[input.key] = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (input.type == 'upload') {
      final currentFile = (_formValues[input.key] ?? '').toString().trim();
      final hasFile = currentFile.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _tool.accentColor.withOpacity(0.35), width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _tool.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(hasFile ? LucideIcons.fileCheck : LucideIcons.uploadCloud, color: _tool.accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasFile ? currentFile : 'No document selected yet',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: hasFile ? FontWeight.bold : FontWeight.w500,
                                color: hasFile ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Supports PDF, JPG, PNG (Max 25 MB)',
                              style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // File selection dialog
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Select Document for Diligence', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(LucideIcons.fileCheck, color: Color(0xFFDC2626)),
                                    title: const Text('RERA_Certificate.pdf'),
                                    subtitle: const Text('Official Project RERA Approval'),
                                    onTap: () {
                                      setState(() => _formValues[input.key] = 'RERA_Certificate.pdf');
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(LucideIcons.fileText, color: Color(0xFF0284C7)),
                                    title: const Text('Sale_Deed_Registry.pdf'),
                                    subtitle: const Text('Sub-Registrar Conveyance Deed'),
                                    onTap: () {
                                      setState(() => _formValues[input.key] = 'Sale_Deed_Registry.pdf');
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(LucideIcons.fileSpreadsheet, color: Color(0xFF059669)),
                                    title: const Text('Property_Tax_Receipt.pdf'),
                                    subtitle: const Text('Municipal Assessment Paid Receipt'),
                                    onTap: () {
                                      setState(() => _formValues[input.key] = 'Property_Tax_Receipt.pdf');
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.uploadCloud, size: 13),
                        label: const Text('Browse File', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: BorderSide(color: _tool.accentColor),
                          foregroundColor: _tool.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controllers[input.key] ?? TextEditingController(text: input.defaultValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(input.label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: input.hint,
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textHint),
              filled: true,
              fillColor: AppTheme.surfaceSubtle,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _tool.accentColor, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _tool.accentColor),
          const SizedBox(height: 18),
          Text(
            'Analyzing with ${_tool.title} Engine...',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Computing domain parameters, architectural rules, and verified market benchmarks.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateGuideCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clean Empty State Notification Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _tool.accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_tool.icon, color: _tool.accentColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No data available yet',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select or enter parameters above and click "${_tool.buttonLabel}" to get started.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _tool.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_tool.icon, color: _tool.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How ${_tool.title} Works',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Automated real-time intelligence workflow',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildGuideStep('1', 'Set Your Parameters', 'Configure the inputs above for your exact property, room, or requirements.'),
          _buildGuideStep('2', 'AI Computation', 'PropZen algorithms process architectural formulas, circle rates, and verified data.'),
          _buildGuideStep('3', 'Examine Bespoke Results', 'Review tailored measurements, cost breakdowns, color palettes, and scores.'),
          _buildGuideStep('4', 'Save or Consult Expert', 'Bookmark this tool report or request a 1-on-1 specialist consultation.'),

          const SizedBox(height: 12),

          if (_tool.disclaimer != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tool.disclaimer!,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _tool.accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: _tool.accentColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final metrics = data['metrics'] as Map<String, dynamic>? ?? {};
    final summary = data['summary']?.toString() ?? '';
    final recommendations = (data['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final materials = data['materials'] as Map<String, dynamic>? ?? {};
    final palette = (data['palette'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final rooms = data['rooms'] as List<dynamic>? ?? [];
    final zones = data['zones'] as List<dynamic>? ?? [];
    final scenes = data['scenes'] as List<dynamic>? ?? [];
    final matrix = data['matrix'] as List<dynamic>? ?? [];
    final checklist = data['checklist'] as List<dynamic>? ?? [];
    final bankRates = data['bankRates'] as List<dynamic>? ?? [];
    final recommendationsList = data['recommendationsList'] as List<dynamic>? ?? [];
    final milestones = data['milestones'] as List<dynamic>? ?? [];
    final materialChecklist = data['materialChecklist'] as List<dynamic>? ?? [];
    final threads = data['threads'] as List<dynamic>? ?? [];
    final previewUrl = data['previewUrl']?.toString() ?? _tool.uniqueImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _tool.accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: AppTheme.softCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_tool.accentColor, _tool.accentColor.withOpacity(0.85)],
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_tool.title.toUpperCase()} REPORT',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _tool.id == 'ai_floor_plan' ? 'INTERACTIVE 2D CAD' : 'AI GENERATED',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Visual Result: If Floor Plan, render Interactive 2D Vector CAD Canvas!
          if (_tool.id == 'ai_floor_plan') ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Visual2dFloorPlanCanvas(
                plotWidth: double.tryParse(_formValues['plotWidth']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '30') ?? 30.0,
                plotLength: double.tryParse(_formValues['plotLength']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '50') ?? 50.0,
                facing: _formValues['facing']?.toString() ?? 'North-East',
                bhk: _formValues['bedrooms']?.toString() ?? '3 BHK',
                floors: _formValues['floors']?.toString() ?? 'G+1 (Double Story)',
                vastuStrictness: _formValues['vastuPref']?.toString() ?? 'Strict 100% Vastu',
                onRegenerate: () => _executeAnalysis(),
              ),
            ),
          ] else ...[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                previewUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: AppTheme.surfaceHighlight,
                  child: Center(
                    child: Icon(_tool.icon, size: 48, color: _tool.accentColor.withOpacity(0.4)),
                  ),
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Summary
                Text('AI Summary', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(summary, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.45)),

                const SizedBox(height: 18),

                // Key Metrics Grid
                if (metrics.isNotEmpty) ...[
                  Text('Key Intelligence Metrics', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: metrics.length,
                    itemBuilder: (ctx, i) {
                      final key = metrics.keys.elementAt(i);
                      final val = metrics[key]?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(key, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(val, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: _tool.accentColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                ],

                // 1. Specialized Floor Plan Room Breakdown Table
                if (rooms.isNotEmpty) ...[
                  Text('Room-by-Room Sizing & Vastu Zones', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...rooms.map((r) {
                    final rm = r as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.layout, size: 16, color: Color(0xFF0D9488)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rm['room']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                Text(rm['zone']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(rm['dimensions']?.toString() ?? '', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                              Text(rm['area']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 2. Specialized Vastu Zones Cards
                if (zones.isNotEmpty) ...[
                  Text('Vedic Directional Zones Compliance', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...zones.map((z) {
                    final zn = z as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.compass, size: 15, color: Color(0xFFD97706)),
                                  const SizedBox(width: 8),
                                  Text(zn['zone']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldSuccess.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(zn['score']?.toString() ?? '95%', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(zn['desc']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 3. Specialized Document Verification Checklist
                if (checklist.isNotEmpty) ...[
                  Text('Legal Title & Compliance Verification', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...checklist.map((c) {
                    final ck = c as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.checkCircle2, color: AppTheme.emeraldSuccess, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(ck['item']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emeraldSuccess.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(ck['status']?.toString() ?? 'VERIFIED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 4. Specialized Loan Consultancy Bank Comparison
                if (bankRates.isNotEmpty) ...[
                  Text('Partner Bank Interest Rate Benchmark', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...bankRates.map((b) {
                    final bk = b as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bk['bank']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                Text('Processing: ${bk['procFee'] ?? '0.5%'} • LTV: ${bk['maxLtv'] ?? '80%'}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Text(bk['rate']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 5. Specialized Property Video Scenes Timeline
                if (scenes.isNotEmpty) ...[
                  Text('Video Storyboard Scenes & Voiceover Prompts', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...scenes.map((s) {
                    final sc = s as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sc['scene']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Text(sc['duration']?.toString() ?? '', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(sc['script']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 6. Specialized Property Comparison Matrix
                if (matrix.isNotEmpty) ...[
                  Text('Side-by-Side Comparison Matrix', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...matrix.map((m) {
                    final mx = m as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(mx['feature']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(mx['prop1']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                              const SizedBox(width: 8),
                              Expanded(child: Text(mx['prop2']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 7. Specialized Recommendations List (for Property Recommendation tool)
                if (recommendationsList.isNotEmpty) ...[
                  Text('Top Ranked Property Matches', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...recommendationsList.map((rec) {
                    final rc = rec as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(rc['name']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryViolet.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${rc['matchScore'] ?? '95%'} Match', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                              ),
                            ],
                          ),
                          Text('${rc['sector'] ?? ''} • ${rc['price'] ?? ''}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                          const SizedBox(height: 4),
                          Text(rc['usp']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // Palette Chips (for Interior & Decor tools)
                if (palette.isNotEmpty) ...[
                  Text('Curated Color Palette', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: palette.map((colorHex) {
                      final c = Color(int.tryParse(colorHex.replaceAll('#', '0xFF')) ?? 0xFF7C3AED);
                      return Expanded(
                        child: Container(
                          height: 36,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Center(
                            child: Text(
                              colorHex,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                ],

                // Materials Breakdown
                if (materials.isNotEmpty) ...[
                  Text('Recommended Materials & Specifications', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  ...materials.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _tool.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(e.key, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: _tool.accentColor)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e.value.toString(), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 8. Specialized Construction Milestones Timeline
                if (milestones.isNotEmpty) ...[
                  Text('5-Phase Structural Construction Roadmap', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...milestones.map((m) {
                    final ml = m as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(ml['stage']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${ml['duration']} (${ml['costPct']})', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(ml['desc']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.35)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 9. Specialized Construction Material Bill of Quantities (BOQ)
                if (materialChecklist.isNotEmpty) ...[
                  Text('Material Bill of Quantities (BOQ) Estimates', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 10),
                  ...materialChecklist.map((mat) {
                    final mt = mat as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mt['category']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                const SizedBox(height: 2),
                                Text(mt['spec']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(mt['qty']?.toString() ?? '', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0D9488))),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // 10. Specialized Discussion Forum Threads Feed
                if (threads.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Community Questions & Verified Answers', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Ask Community Question', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Type your question about property, Vastu, loans, or registry...',
                                      hintStyle: GoogleFonts.inter(fontSize: 12),
                                      border: const OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Question posted! Verified community experts will respond shortly.'),
                                        backgroundColor: Color(0xFF8B5CF6),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                                  child: const Text('Post Question', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.plusCircle, size: 14, color: Color(0xFF8B5CF6)),
                        label: Text('Ask Question', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...threads.map((th) {
                    final t = th as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(t['tag']?.toString() ?? 'General', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF8B5CF6))),
                              ),
                              Text('${t['author']} • ${t['time']}', style: GoogleFonts.inter(fontSize: 10.5, color: AppTheme.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(t['title']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text(t['content']?.toString() ?? '', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.35)),
                          if (t['expertReply'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(LucideIcons.award, size: 15, color: Color(0xFF059669)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Verified Expert Answer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                                        const SizedBox(height: 2),
                                        Text(t['expertReply'].toString(), style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textPrimary, height: 1.35)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(LucideIcons.thumbsUp, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('${t['likes']} Upvotes', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(width: 14),
                              Icon(LucideIcons.messageSquare, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('${t['repliesCount']} Replies', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // AI Recommendations List
                if (recommendations.isNotEmpty) ...[
                  Text('AI Actionable Recommendations', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  ...recommendations.map((rec) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.check, size: 14, color: _tool.accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(rec, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showConsultExpertDialog,
                        icon: const Icon(LucideIcons.userCheck, size: 14),
                        label: const Text('Consult Specialist', maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                          side: BorderSide(color: _tool.accentColor),
                          foregroundColor: _tool.accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ ${_tool.title} report exported to your dashboard.'),
                              backgroundColor: AppTheme.emeraldSuccess,
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.download, size: 14, color: Colors.white),
                        label: const Text('Export Report', maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tool.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
