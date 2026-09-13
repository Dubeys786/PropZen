import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/design_studio_models.dart';
import '../models/visualization_models.dart';
import '../services/design_studio_service.dart';
import '../services/visualization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_tools/visual_2d_floor_plan_canvas.dart';
import 'three_d_property_viewer_screen.dart';

class DesignStudioScreen extends StatefulWidget {
  const DesignStudioScreen({super.key});

  @override
  State<DesignStudioScreen> createState() => _DesignStudioScreenState();
}

class _DesignStudioScreenState extends State<DesignStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DesignStudioService _designService = DesignStudioService.instance;
  final VisualizationService _vizService = VisualizationService.instance;

  // Vastu Form Controllers
  final TextEditingController _plotWidthController = TextEditingController(text: '30');
  final TextEditingController _plotLengthController = TextEditingController(text: '50');
  String _facingDirection = 'North-East';
  String _entranceDirection = 'North-East';
  String _propertyType = 'Independent Villa';
  VastuAnalysisResult? _vastuResult;

  // AI Room Designer State
  String _selectedRoomType = 'Living Room';
  String _selectedStyle = 'Modern Luxury';
  bool _isGeneratingAiDesign = false;
  String? _generatedAiImageUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _runVastuAnalysis();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _plotWidthController.dispose();
    _plotLengthController.dispose();
    super.dispose();
  }

  void _runVastuAnalysis() {
    final width = double.tryParse(_plotWidthController.text.trim()) ?? 30.0;
    final length = double.tryParse(_plotLengthController.text.trim()) ?? 50.0;

    final input = VastuInputModel(
      plotWidth: width,
      plotLength: length,
      facingDirection: _facingDirection,
      entranceDirection: _entranceDirection,
      propertyType: _propertyType,
    );

    setState(() {
      _vastuResult = _designService.analyzeVastu(input);
    });
  }

  Future<void> _generateAiDesign() async {
    setState(() => _isGeneratingAiDesign = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isGeneratingAiDesign = false;
        _generatedAiImageUrl = 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1000&q=80';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'PropZen Design Studio',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryViolet,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryViolet,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(LucideIcons.compass, size: 18), text: 'Vastu AI'),
            Tab(icon: Icon(LucideIcons.layoutGrid, size: 18), text: '2D CAD'),
            Tab(icon: Icon(LucideIcons.wand2, size: 18), text: 'AI Designer'),
            Tab(icon: Icon(LucideIcons.box, size: 18), text: '3D Studio'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVastuTab(),
          _build2dPlannerTab(),
          _buildAiDesignerTab(),
          _build3dStudioTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: VASTU CONSULTATION & ANALYSIS
  // =========================================================================
  Widget _buildVastuTab() {
    final res = _vastuResult;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plot & Facing Parameters', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _plotWidthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Plot Width (ft)', border: OutlineInputBorder()),
                        onChanged: (_) => _runVastuAnalysis(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _plotLengthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Plot Length (ft)', border: OutlineInputBorder()),
                        onChanged: (_) => _runVastuAnalysis(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _facingDirection,
                  decoration: const InputDecoration(labelText: 'Plot Facing Direction', border: OutlineInputBorder()),
                  items: ['North-East', 'East', 'North', 'North-West', 'West', 'South-East', 'South', 'South-West']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _facingDirection = v);
                      _runVastuAnalysis();
                    }
                  },
                ),
              ],
            ),
          ),

          if (res != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vastu Compliance Score', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldSuccess.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${res.overallScore} / 100', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(res.ratingGrade, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                  const Divider(height: 24),
                  _buildVastuRow(LucideIcons.compass, 'Direction Analysis', res.directionSummary),
                  const SizedBox(height: 12),
                  _buildVastuRow(LucideIcons.doorOpen, 'Entrance Guidance', res.entranceAnalysis),
                  const SizedBox(height: 12),
                  _buildVastuRow(LucideIcons.flame, 'Kitchen Placement (Agneya)', res.kitchenPlacement),
                  const SizedBox(height: 12),
                  _buildVastuRow(LucideIcons.bed, 'Master Bedroom (Nairutya)', res.masterBedroomPlacement),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.info, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(res.disclaimer, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E))),
                        ),
                      ],
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

  Widget _buildVastuRow(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryViolet),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(body, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: 2D CAD FLOOR PLANNER
  // =========================================================================
  Widget _build2dPlannerTab() {
    final width = double.tryParse(_plotWidthController.text.trim()) ?? 30.0;
    final length = double.tryParse(_plotLengthController.text.trim()) ?? 50.0;
    return Visual2dFloorPlanCanvas(
      plotWidth: width,
      plotLength: length,
      facing: _facingDirection,
    );
  }

  // =========================================================================
  // TAB 3: AI ROOM DESIGNER
  // =========================================================================
  Widget _buildAiDesignerTab() {
    final rooms = ['Living Room', 'Master Bedroom', 'Modular Kitchen', 'Modern Bathroom', 'Executive Office', 'Villa Exterior'];
    final styles = ['Modern Luxury', 'Minimalist Zen', 'Contemporary Chic', 'Traditional Indian', 'Scandinavian'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PropZen AI Home Designer', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Generate photorealistic interior & exterior architectural transformations in seconds.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                Text('Select Space:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rooms.map((r) {
                    final isSel = _selectedRoomType == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: isSel,
                      selectedColor: AppTheme.primaryViolet.withOpacity(0.15),
                      onSelected: (v) => setState(() => _selectedRoomType = r),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Select Aesthetic Style:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: styles.map((s) {
                    final isSel = _selectedStyle == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: isSel,
                      selectedColor: AppTheme.primaryViolet.withOpacity(0.15),
                      onSelected: (v) => setState(() => _selectedStyle = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isGeneratingAiDesign
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.sparkles, color: Colors.white),
                    label: Text(_isGeneratingAiDesign ? 'Generating AI Rendering...' : 'Generate Architectural Render', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _isGeneratingAiDesign ? null : _generateAiDesign,
                  ),
                ),
              ],
            ),
          ),

          if (_generatedAiImageUrl != null) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      _generatedAiImageUrl!,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_selectedStyle $_selectedRoomType', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('Generated via PropZen AI Vision Engine', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.share2, color: AppTheme.primaryViolet),
                          onPressed: () {},
                        ),
                      ],
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

  // =========================================================================
  // TAB 4: 3D VISUALIZATION STUDIO
  // =========================================================================
  Widget _build3dStudioTab() {
    final activeProvider = _vizService.activeProvider;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.box, color: AppTheme.primaryViolet, size: 22),
                    const SizedBox(width: 8),
                    Text('3D Property Architectural Walkthrough', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Active 3D Engine: ${activeProvider.providerName}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 16),

                if (!activeProvider.isConfigured) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 32, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          '3D visualization provider is not configured yet.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please configure your 3D cloud credentials or switch back to the built-in isometric provider in settings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(LucideIcons.maximize2, color: Colors.white),
                      label: const Text('Open Interactive 3D Viewer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ThreeDPropertyViewerScreen(propertyTitle: 'PropZen Signature 3D Twin'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
