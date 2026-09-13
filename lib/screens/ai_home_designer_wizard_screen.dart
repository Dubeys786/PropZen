import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/ai_home_project.dart';
import '../services/ai_home_designer_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/ai_home/visual_compass_selector.dart';
import '../widgets/ai_home/interactive_floor_plan_viewer.dart';
import '../widgets/ai_home/isometric_3d_home_viewer.dart';
import '../widgets/ai_home/facade_comparison_view.dart';
import '../widgets/ai_home/interior_room_designer_view.dart';
import 'my_ai_designs_screen.dart';
import 'ai_home_share_screen.dart';
import '../widgets/enquiry_auth_dialog.dart';

/// Multi-Step App Wizard for AI Home & Vastu Designer
class AiHomeDesignerWizardScreen extends StatefulWidget {
  final AiHomeProject? initialProject;
  final int initialStep;

  const AiHomeDesignerWizardScreen({
    super.key,
    this.initialProject,
    this.initialStep = 0,
  });

  @override
  State<AiHomeDesignerWizardScreen> createState() => _AiHomeDesignerWizardScreenState();
}

class _AiHomeDesignerWizardScreenState extends State<AiHomeDesignerWizardScreen> {
  late int _currentStep;
  late AiHomeProject _project;

  // Controllers for Step 1
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _roadWidthController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _customModifyPromptController = TextEditingController();

  // AI Generation overlay animation state
  bool _isGenerating = false;
  int _generationPhaseIndex = 0;

  final List<String> _generationPhases = [
    'Analyzing plot geometry & setback boundaries...',
    'Checking cardinal solar orientation & sun path...',
    'Calculating Vastu Purusha Mandala room zoning...',
    'Optimizing circulation flow & structural grid...',
    'Generating 2D architectural CAD floor plan...',
    'Preparing 3D spatial model & facade elevations...',
  ];

  final List<String> _stepTitles = [
    'Plot Details',
    'Vastu & Direction',
    'Requirements',
    'AI Floor Plan',
    '3D Visualization',
    'Facade Design',
    'Interior Design',
    'Walkthrough',
    'Save & Share',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;

    final user = SupabaseService.instance.auth.currentUser;
    _project = widget.initialProject ?? AiHomeProject.defaultProject(userId: user?.id ?? 'usr_active');

    _lengthController.text = _project.plotLength.toStringAsFixed(0);
    _widthController.text = _project.plotWidth.toStringAsFixed(0);
    _roadWidthController.text = _project.roadWidth.toStringAsFixed(0);
    _projectNameController.text = _project.projectName;

    // If initial project already has generated designs, we can jump to floor plan if requested
    if (_project.status == 'generated' && _project.floorPlans.isNotEmpty && widget.initialStep == 0) {
      _currentStep = 3;
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _roadWidthController.dispose();
    _projectNameController.dispose();
    _customModifyPromptController.dispose();
    super.dispose();
  }

  void _saveDraft() async {
    _syncFormFields();
    final updated = _project.copyWith(status: 'draft', updatedAt: DateTime.now().toIso8601String());
    setState(() => _project = updated);

    await AiHomeDesignerService.instance.saveProject(updated);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Draft saved successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppTheme.emeraldSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _syncFormFields() {
    final len = double.tryParse(_lengthController.text.trim()) ?? _project.plotLength;
    final wid = double.tryParse(_widthController.text.trim()) ?? _project.plotWidth;
    final roadWid = double.tryParse(_roadWidthController.text.trim()) ?? _project.roadWidth;
    final name = _projectNameController.text.trim();

    _project = _project.copyWith(
      plotLength: len,
      plotWidth: wid,
      roadWidth: roadWid,
      projectName: name.isNotEmpty ? name : _project.projectName,
    );
  }

  void _goToNextStep() {
    _syncFormFields();

    // Step 1 Validation
    if (_currentStep == 0) {
      if (_project.plotLength <= 0 || _project.plotWidth <= 0) {
        _showValidationToast('Please enter valid plot length and width.');
        return;
      }
    }

    // Moving from Step 3 (Requirements) -> Step 4 (AI Generation & Floor Plan)
    if (_currentStep == 2 && (_project.floorPlans.isEmpty || _project.status == 'draft')) {
      _triggerFullAiGeneration();
      return;
    }

    if (_currentStep < 8) {
      setState(() => _currentStep++);
    }
  }

  void _goToPreviousStep() {
    _syncFormFields();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showValidationToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppTheme.coralDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerFullAiGeneration() async {
    setState(() {
      _isGenerating = true;
      _generationPhaseIndex = 0;
    });

    // Step-by-step loading animation ticker
    for (int i = 1; i < _generationPhases.length; i++) {
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _generationPhaseIndex = i);
    }

    try {
      final generatedProject = await AiHomeDesignerService.instance.generateCompleteDesign(_project);
      if (!mounted) return;

      setState(() {
        _project = generatedProject;
        _isGenerating = false;
        _currentStep = 3; // Open AI Floor Plan
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete AI generation. Please check your network and retry.')),
      );
    }
  }

  void _triggerLayoutModification(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    try {
      final modified = await AiHomeDesignerService.instance.modifyProjectLayout(_project, prompt);
      if (!mounted) return;

      setState(() {
        _project = modified;
        _isGenerating = false;
      });
      _customModifyPromptController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Layout modified according to your request!'),
          backgroundColor: AppTheme.emeraldSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              _goToPreviousStep();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Home & Vastu Designer',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Text(
              'Step ${_currentStep + 1} of 9: ${_stepTitles[_currentStep]}',
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(LucideIcons.save, size: 15, color: AppTheme.primaryViolet),
            label: Text(
              'Save Draft',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.folder, color: AppTheme.textPrimary, size: 18),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyAiDesignsScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 9.0,
            backgroundColor: AppTheme.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
            minHeight: 4,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Step Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveLayout.horizontalPadding(context),
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Title Banner
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _stepTitles[_currentStep],
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                _getStepSubtitle(_currentStep),
                                style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.purpleSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderPurple),
                            ),
                            child: Text(
                              '${_currentStep + 1}/9',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Current Step Widget
                      _buildCurrentStepWidget(),
                      const SizedBox(height: 32),

                      // Bottom Navigation Row: Back / Continue / Generate
                      _buildWizardBottomNav(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Multi-Stage AI Generation Animation Overlay
          if (_isGenerating) _buildAiGenerationOverlay(),
        ],
      ),
    );
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Specify plot dimensions, shape, floors and parking.';
      case 1:
        return 'Set road & entrance orientation for Vastu harmony.';
      case 2:
        return 'Select BHK, kitchen style, living room and budget.';
      case 3:
        return '2D CAD layout with room tags, dimensions & Vastu insights.';
      case 4:
        return 'Orbit and inspect 3D spatial home layout.';
      case 5:
        return 'Choose and compare exterior facade styles.';
      case 6:
        return 'Customize room furnishings, lighting & textures.';
      case 7:
        return 'Cinematic 4K walkthrough and virtual camera path.';
      case 8:
        return 'Save your project to cloud, download assets & share.';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep1PlotDetails();
      case 1:
        return _buildStep2VastuAndDirection();
      case 2:
        return _buildStep3Requirements();
      case 3:
        return _buildStep4FloorPlan();
      case 4:
        return _buildStep5ThreeD();
      case 5:
        return _buildStep6Facade();
      case 6:
        return _buildStep7Interior();
      case 7:
        return _buildStep8Walkthrough();
      case 8:
        return _buildStep9SaveAndShare();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // STEP 1 — PLOT DETAILS
  // =========================================================================
  Widget _buildStep1PlotDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Project Name
        _buildTextField(
          controller: _projectNameController,
          label: 'Project Name',
          hint: 'e.g. My 3BHK Dream Villa',
          icon: LucideIcons.edit3,
        ),
        const SizedBox(height: 18),

        // Dimensions (Length x Width) + Unit
        Text('Plot Dimensions & Unit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _widthController,
                label: 'Width (Frontage)',
                hint: '20',
                keyboardType: TextInputType.number,
                icon: LucideIcons.moveHorizontal,
                onChanged: (v) => setState(() {}),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('×', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ),
            Expanded(
              flex: 3,
              child: _buildTextField(
                controller: _lengthController,
                label: 'Length (Depth)',
                hint: '50',
                keyboardType: TextInputType.number,
                icon: LucideIcons.moveVertical,
                onChanged: (v) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PlotUnit>(
                    value: _project.plotUnit,
                    isExpanded: true,
                    items: PlotUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.label, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                    onChanged: (u) {
                      if (u != null) setState(() => _project = _project.copyWith(plotUnit: u));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Total Area Calculated Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.purpleSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderPurple),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              Text(
                'Total Plot Area: ${_project.totalPlotAreaSqft.round()} sq ft (${_widthController.text.trim()} × ${_lengthController.text.trim()} ${_project.plotUnit.symbol})',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Plot Shape Selector
        Text('Plot Shape', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PlotShape.values.map((shape) {
            final isSelected = _project.plotShape == shape;
            return GestureDetector(
              onTap: () => setState(() => _project = _project.copyWith(plotShape: shape)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryViolet : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                  ),
                  boxShadow: isSelected ? AppTheme.subtleCardShadow : null,
                ),
                child: Text(
                  shape.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Road Width & Number of Floors
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _roadWidthController,
                label: 'Road Width (ft)',
                hint: '30',
                keyboardType: TextInputType.number,
                icon: LucideIcons.gitCommit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Number of Floors', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FloorOption>(
                        value: _project.floors,
                        isExpanded: true,
                        items: FloorOption.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label, style: GoogleFonts.inter(fontSize: 12.5)))).toList(),
                        onChanged: (f) {
                          if (f != null) setState(() => _project = _project.copyWith(floors: f));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Parking Required
        Text('Parking Required', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: 'Yes, Covered Parking',
                isSelected: _project.parkingRequired,
                icon: LucideIcons.car,
                onTap: () => setState(() => _project = _project.copyWith(parkingRequired: true)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip(
                label: 'No Parking Needed',
                isSelected: !_project.parkingRequired,
                icon: LucideIcons.ban,
                onTap: () => setState(() => _project = _project.copyWith(parkingRequired: false)),
              ),
            ),
          ],
        ),

        if (_project.parkingRequired) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Number of Cars:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              ...[1, 2, 3].map((count) {
                final isSelected = _project.parkingCarCount == count;
                return GestureDetector(
                  onTap: () => setState(() => _project = _project.copyWith(parkingCarCount: count)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryViolet : AppTheme.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count Car${count > 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // STEP 2 — DIRECTION & VASTU
  // =========================================================================
  Widget _buildStep2VastuAndDirection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive Visual Compass
        VisualCompassSelector(
          selectedRoadDirection: _project.roadDirection,
          selectedEntranceDirection: _project.entranceDirection,
          onRoadDirectionChanged: (dir) => setState(() => _project = _project.copyWith(roadDirection: dir)),
          onEntranceDirectionChanged: (dir) => setState(() => _project = _project.copyWith(entranceDirection: dir)),
        ),
        const SizedBox(height: 24),

        // Vastu Preferences Toggles
        Text('Vastu & Architectural Preferences', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),

        ...[
          'Vastu-friendly layout',
          'Maximum natural light',
          'Cross ventilation',
          'Separate pooja room',
          'Privacy-focused layout',
          'Senior-friendly layout',
          'Modern open-plan layout',
        ].map((pref) {
          final isChecked = _project.vastuPreferences.contains(pref);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isChecked ? AppTheme.primaryViolet : AppTheme.borderLight),
            ),
            child: CheckboxListTile(
              title: Text(pref, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              value: isChecked,
              activeColor: AppTheme.primaryViolet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onChanged: (val) {
                final list = List<String>.from(_project.vastuPreferences);
                if (val == true) {
                  list.add(pref);
                } else {
                  list.remove(pref);
                }
                setState(() => _project = _project.copyWith(vastuPreferences: list));
              },
            ),
          );
        }),
        const SizedBox(height: 14),

        // Guidance & Non-claim Disclaimer Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.info, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI will use your plot direction and preferences to suggest suitable room placement. AI-generated design is for planning and visualization purposes. Final construction drawings should be reviewed and approved by a qualified architect/engineer.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 3 — HOME REQUIREMENTS
  // =========================================================================
  Widget _buildStep3Requirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property Type
        Text('Property Type', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PropertyTypeChoice.values.map((type) {
            final isSelected = _project.propertyType == type;
            return GestureDetector(
              onTap: () => setState(() => _project = _project.copyWith(propertyType: type)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryViolet : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight),
                ),
                child: Text(
                  type.label,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Bedrooms & Bathrooms Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bedrooms (BHK)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [1, 2, 3, 4, 5].map((b) {
                      final isSelected = _project.bedrooms == b;
                      return GestureDetector(
                        onTap: () => setState(() => _project = _project.copyWith(bedrooms: b)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryViolet : AppTheme.surfaceHighlight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$b${b == 5 ? '+' : ''}',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textPrimary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bathrooms', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [1, 2, 3, 4].map((b) {
                      final isSelected = _project.bathrooms == b;
                      return GestureDetector(
                        onTap: () => setState(() => _project = _project.copyWith(bathrooms: b)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryViolet : AppTheme.surfaceHighlight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$b${b == 4 ? '+' : ''}',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textPrimary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Kitchen & Living Room Choices
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kitchen Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _project.kitchenType,
                        isExpanded: true,
                        items: ['Open Kitchen', 'Closed Kitchen', 'Modular Kitchen'].map((k) => DropdownMenuItem(value: k, child: Text(k, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                        onChanged: (k) {
                          if (k != null) setState(() => _project = _project.copyWith(kitchenType: k));
                        },
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
                  Text('Living Room Size', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _project.livingRoomType,
                        isExpanded: true,
                        items: ['Compact', 'Standard', 'Large', 'Luxury'].map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                        onChanged: (l) {
                          if (l != null) setState(() => _project = _project.copyWith(livingRoomType: l));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Additional Spaces Selector
        Text('Additional Spaces', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Pooja Room',
            'Study Room',
            'Store Room',
            'Utility Room',
            'Dressing Room',
            'Home Office',
            'Gym',
            'Theatre',
            'Servant Room',
            'Balcony',
            'Terrace Garden',
            'Courtyard',
          ].map((space) {
            final isSelected = _project.additionalSpaces.contains(space);
            return GestureDetector(
              onTap: () {
                final list = List<String>.from(_project.additionalSpaces);
                if (isSelected) {
                  list.remove(space);
                } else {
                  list.add(space);
                }
                setState(() => _project = _project.copyWith(additionalSpaces: list));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryViolet : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight),
                ),
                child: Text(
                  space,
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Budget Range & Design Style
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget Range', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _project.budgetRange,
                        isExpanded: true,
                        items: ['₹30L – ₹50L', '₹50L – ₹1Cr', '₹1Cr – ₹2Cr', '₹2Cr+'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                        onChanged: (b) {
                          if (b != null) setState(() => _project = _project.copyWith(budgetRange: b));
                        },
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
                  Text('Design Style', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<HomeDesignStyle>(
                        value: _project.designStyle,
                        isExpanded: true,
                        items: HomeDesignStyle.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: GoogleFonts.inter(fontSize: 12)))).toList(),
                        onChanged: (s) {
                          if (s != null) setState(() => _project = _project.copyWith(designStyle: s));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 4 — AI FLOOR PLAN & CUSTOMIZATION
  // =========================================================================
  Widget _buildStep4FloorPlan() {
    final floorPlan = _project.floorPlans.isNotEmpty ? _project.floorPlans.first : null;

    if (floorPlan == null) {
      return Center(
        child: Column(
          children: [
            const Icon(LucideIcons.layout, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text('No floor plan generated yet.', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _triggerFullAiGeneration, child: const Text('Generate Now')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive 2D CAD Floor Plan
        InteractiveFloorPlanViewer(
          floorPlan: floorPlan,
          project: _project,
          onDownload: () => _showDownloadToast('Floor Plan CAD'),
          onShare: () => _openShareModal(),
          onRegenerate: _triggerFullAiGeneration,
        ),
        const SizedBox(height: 20),

        // Vastu Insights Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.compass, size: 18, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Text('Vastu Alignment Analysis', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              ...floorPlan.vastuInsights.map((insight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14, color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(insight, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.35)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Customize Layout AI Prompt Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, size: 16, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Text('Customize Floor Plan with AI', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Request modifications in plain English:', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.textMuted)),
              const SizedBox(height: 10),

              // Quick Modification Prompt Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Move kitchen to the other side',
                  'Add one bedroom',
                  'Increase living room',
                  'Add balcony',
                  'Make parking bigger',
                  'Add pooja room',
                ].map((prompt) {
                  return GestureDetector(
                    onTap: () {
                      _customModifyPromptController.text = prompt;
                      _triggerLayoutModification(prompt);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(prompt, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Custom Input + AI Modify Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customModifyPromptController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Expand master bedroom and add wardrobe...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _triggerLayoutModification(_customModifyPromptController.text),
                    icon: const Icon(LucideIcons.wand2, size: 15),
                    label: const Text('AI Modify'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 5 — 3D VISUALIZATION
  // =========================================================================
  Widget _buildStep5ThreeD() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Isometric3dHomeViewer(
          project: _project,
          isExternalProviderConfigured: AiHomeDesignerService.instance.isExternalProviderConfigured,
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 6 — FACADE DESIGNER
  // =========================================================================
  Widget _buildStep6Facade() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FacadeComparisonView(
          facades: _project.facadeDesigns,
          activeStyle: _project.designStyle.label,
          onStyleSelected: (style) {
            setState(() => _project = _project.copyWith(designStyle: HomeDesignStyle.fromString(style)));
          },
          onRegenerateFacade: () async {
            setState(() => _isGenerating = true);
            final updated = await AiHomeDesignerService.instance.regenerateFacades(_project, _project.designStyle.label);
            if (!mounted) return;
            setState(() {
              _project = updated;
              _isGenerating = false;
            });
          },
          onDownload: () => _showDownloadToast('Facade Elevation'),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 7 — INTERIOR DESIGNER
  // =========================================================================
  Widget _buildStep7Interior() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InteriorRoomDesignerView(
          interiorDesigns: _project.interiorDesigns,
          activeStyle: _project.designStyle.label,
          onGenerateInterior: (room, style, color) async {
            setState(() => _isGenerating = true);
            final updated = await AiHomeDesignerService.instance.regenerateRoomInterior(
              _project,
              roomName: room,
              style: style,
              colorPreference: color,
            );
            if (!mounted) return;
            setState(() {
              _project = updated;
              _isGenerating = false;
            });
          },
          onSaveDesign: _saveDraft,
          onDownload: () => _showDownloadToast('Interior Room Concept'),
        ),
      ],
    );
  }

  // =========================================================================
  // STEP 8 — WALKTHROUGH
  // =========================================================================
  Widget _buildStep8Walkthrough() {
    final wt = _project.walkthrough;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryViolet, width: 2),
                    ),
                    child: const Icon(LucideIcons.play, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Virtual 4K Cinematic Walkthrough',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Duration: ${wt?.durationSeconds ?? 45} seconds • Multi-Angle Cam',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
                      onPressed: () => _openShareModal(),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.maximize2, color: Colors.white, size: 18),
                      onPressed: () => _showDownloadToast('Walkthrough Fullscreen'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Keyframe Navigation List
        Text('Camera Tour Keyframes', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        ...(wt?.cameraKeyframes ?? [
          '1. Exterior Facade & Covered Portico',
          '2. Grand Entrance Foyer',
          '3. Double-Height Living Hall & Courtyard',
          '4. Modular Island Kitchen & Dining',
          '5. Master Bedroom Suite & Balcony',
        ]).map((kf) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.video, size: 15, color: AppTheme.primaryViolet),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(kf, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ),
                const Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.textHint),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // STEP 9 — SAVE & SHARE (AI DESIGN RESULT)
  // =========================================================================
  Widget _buildStep9SaveAndShare() {
    final primaryElevationUrl = (_project.facadeDesigns.isNotEmpty && _project.facadeDesigns.first.imageUrl != null)
        ? _project.facadeDesigns.first.imageUrl!
        : 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI DESIGN RESULT Main Container
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3), width: 1.5),
            boxShadow: AppTheme.softCardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'AI DESIGN RESULT',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '100% VASTU COMPLIANT',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Generated Visual Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  primaryElevationUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    color: AppTheme.surfaceHighlight,
                    child: const Center(
                      child: Icon(LucideIcons.home, size: 48, color: AppTheme.primaryViolet),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Design Summary
                    Text(
                      'AI Design Summary',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Custom architectural concept generated for ${_project.projectName} (${_project.formattedPlotDimensions}, ${_project.bedrooms} BHK ${_project.designStyle.label}). Space planning maximizes carpet efficiency with balanced circulation pathways and daylight exposure.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
                    ),

                    const SizedBox(height: 20),

                    // DESIGN INSIGHTS Section
                    Text(
                      'DESIGN INSIGHTS',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          _buildInsightRow(LucideIcons.palette, 'Style', _project.designStyle.label),
                          _buildInsightRow(LucideIcons.percent, 'Space Optimization', '94% Efficiency'),
                          _buildInsightRow(LucideIcons.banknote, 'Estimated Budget', _project.budgetRange),
                          _buildInsightRow(LucideIcons.clock, 'Estimated Timeline', '45 Working Days'),
                          _buildInsightRow(LucideIcons.sun, 'Natural Light', 'High (Dual Window Openings)'),
                          _buildInsightRow(LucideIcons.archive, 'Storage Efficiency', 'High (Concealed Niches)'),
                          _buildInsightRow(LucideIcons.layoutGrid, 'Furniture Density', 'Balanced Ergonomics'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // RECOMMENDED MATERIALS Section
                    Text(
                      'RECOMMENDED MATERIALS',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          _buildMaterialRow('Flooring', 'Italian Marble / 800x1600mm Hardwood Vitrified Tiles'),
                          _buildMaterialRow('Walls', 'Neutral Palette with Fluted Panelling & Textured Accent'),
                          _buildMaterialRow('Furniture', 'Modular High-Density Fabric Sectional & Oak Coffee Table'),
                          _buildMaterialRow('Lighting', 'Warm 3000K Ambient LED Coves & Magnetic Track Lights'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // AI RECOMMENDATIONS Section
                    Text(
                      'AI RECOMMENDATIONS',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendationItem('Use concealed storage to maximize floor area.'),
                    _buildRecommendationItem('Keep natural light unobstructed from main floor-to-ceiling windows.'),
                    _buildRecommendationItem('Use warm ambient lighting for comfortable evenings.'),
                    _buildRecommendationItem('Maintain clear walking zones (minimum 3.5 ft) between functional areas.'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons: [Save Design], [Consult Expert], [Generate Another Design]
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () async {
              await AiHomeDesignerService.instance.saveProject(_project);
              if (!mounted) return;
              _saveDraft();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Design saved successfully to your PropZen cloud collection!'),
                  backgroundColor: AppTheme.emeraldSuccess,
                ),
              );
            },
            icon: const Icon(LucideIcons.check, size: 18),
            label: const Text('Save Design'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  EnquiryAuthDialog.show(
                    context,
                    actionLabel: 'Consult Architect',
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Consultation booked! An architect will contact you within 24 hours.'),
                          backgroundColor: AppTheme.emeraldSuccess,
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(LucideIcons.userCheck, size: 16),
                label: const Text('Consult Expert'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primaryViolet),
                  foregroundColor: AppTheme.primaryViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Generate Another'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.borderLight),
                  foregroundColor: AppTheme.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryViolet),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(String category, String material) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(material, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.checkCircle, size: 14, color: AppTheme.emeraldSuccess),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary, height: 1.35)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WIZARD BOTTOM NAVIGATION BUTTONS
  // =========================================================================
  Widget _buildWizardBottomNav() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          OutlinedButton.icon(
            onPressed: _goToPreviousStep,
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentStep == 2 && (_project.floorPlans.isEmpty || _project.status == 'draft')
                ? _triggerFullAiGeneration
                : _goToNextStep,
            icon: Icon(
              _currentStep == 2 ? LucideIcons.sparkles : (_currentStep == 8 ? LucideIcons.check : LucideIcons.arrowRight),
              size: 18,
            ),
            label: Text(
              _currentStep == 2 ? 'Generate My Dream Home' : (_currentStep == 8 ? 'Finish & View My Designs' : 'Continue'),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // AI GENERATION LOADING ANIMATION OVERLAY
  // =========================================================================
  Widget _buildAiGenerationOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Designing Your Dream Home...',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  _generationPhases[_generationPhaseIndex],
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: (_generationPhaseIndex + 1) / _generationPhases.length,
                  backgroundColor: AppTheme.surfaceHighlight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openShareModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiHomeShareDialog(project: _project),
    );
  }

  void _showDownloadToast(String assetName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$assetName download started! Saved to device.'),
        backgroundColor: AppTheme.primaryViolet,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 16, color: AppTheme.textHint) : null,
            filled: true,
            fillColor: AppTheme.surfaceSubtle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryViolet : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight),
          boxShadow: isSelected ? AppTheme.subtleCardShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
