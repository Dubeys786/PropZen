import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/perfect_property_model.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../screens/property_details_screen.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/property_map_view.dart';
import '../widgets/enquiry_auth_dialog.dart';
import '../theme/app_theme.dart';

class FindMyPerfectPropertyScreen extends StatefulWidget {
  final PropertyPreferenceModel? initialPreferences;

  const FindMyPerfectPropertyScreen({
    super.key,
    this.initialPreferences,
  });

  @override
  State<FindMyPerfectPropertyScreen> createState() => _FindMyPerfectPropertyScreenState();
}

class _FindMyPerfectPropertyScreenState extends State<FindMyPerfectPropertyScreen> {
  late PropertyPreferenceModel _preferences;

  // Step 0: Intro, 1: Purpose, 2: Location, 3: Budget, 4: Type, 5: BHK, 6: Priorities, 7: Lifestyle, 8: Loading, 9: Results
  int _currentStep = 0;
  final int _totalSteps = 6;

  // Search in Step 2
  final TextEditingController _locationSearchController = TextEditingController();
  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();

  // Results state
  List<PropertyMatchResult> _allResults = [];
  List<PropertyMatchResult> _filteredResults = [];
  bool _isSavingPreferences = false;
  bool _isMapMode = false;
  String _selectedSort = 'Best Match';
  String _selectedBhkFilter = 'All';
  String _selectedTypeFilter = 'All';

  final List<String> _availableCities = [
    'Noida',
    'Gurugram',
    'Delhi',
    'Greater Noida',
    'Faridabad',
    'Ghaziabad',
  ];

  final List<String> _popularLocalities = [
    'Sector 150',
    'Sector 137',
    'Sector 62',
    'Golf Course Road',
    'Cyber City',
    'Dwarka Expressway',
    'Sector 63',
    'Vasant Kunj',
    'Knowledge Park',
    'Sector 142',
  ];

  final List<Map<String, dynamic>> _propertyTypeOptions = [
    {'title': 'Apartment', 'icon': LucideIcons.building2, 'desc': 'Multi-storey luxury flats'},
    {'title': 'Villa', 'icon': LucideIcons.home, 'desc': 'Independent luxury villas'},
    {'title': 'Independent House', 'icon': LucideIcons.layoutGrid, 'desc': 'Standalone residential homes'},
    {'title': 'Plot', 'icon': LucideIcons.map, 'desc': 'Gated residential land parcels'},
    {'title': 'Penthouse', 'icon': LucideIcons.sparkles, 'desc': 'Top-floor sky residences'},
    {'title': 'Studio', 'icon': LucideIcons.sofa, 'desc': 'Compact 1RK/studio units'},
    {'title': 'Commercial', 'icon': LucideIcons.briefcase, 'desc': 'Offices & highstreet retail'},
  ];

  final List<String> _bhkOptionsList = [
    '1 BHK',
    '2 BHK',
    '3 BHK',
    '4 BHK',
    '5+ BHK',
  ];

  final List<Map<String, dynamic>> _prioritiesList = [
    {'name': 'Near Metro', 'icon': LucideIcons.mapPin},
    {'name': 'Near Schools', 'icon': LucideIcons.graduationCap},
    {'name': 'Near Hospitals', 'icon': LucideIcons.crosshair},
    {'name': 'Near Shopping', 'icon': LucideIcons.shoppingBag},
    {'name': 'Green/Open Spaces', 'icon': LucideIcons.trees},
    {'name': 'Gym', 'icon': LucideIcons.dumbbell},
    {'name': 'Swimming Pool', 'icon': LucideIcons.waves},
    {'name': 'Parking', 'icon': LucideIcons.car},
    {'name': 'Security', 'icon': LucideIcons.shieldCheck},
    {'name': 'Power Backup', 'icon': LucideIcons.zap},
    {'name': 'Ready to Move', 'icon': LucideIcons.checkCircle2},
    {'name': 'Under Construction', 'icon': LucideIcons.hammer},
    {'name': 'High Rental Potential', 'icon': LucideIcons.indianRupee},
    {'name': 'Investment Growth', 'icon': LucideIcons.trendingUp},
    {'name': 'Vastu Friendly', 'icon': LucideIcons.compass},
  ];

  final List<String> _lifestyleOptions = [
    'Quiet Area',
    'Family Friendly',
    'Luxury',
    'Budget Friendly',
    'Modern Amenities',
    'Low Maintenance',
    'Good Connectivity',
  ];

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences != null
        ? widget.initialPreferences!.copyWith()
        : PropertyPreferenceModel();

    _updateBudgetControllers();
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _updateBudgetControllers() {
    if (_preferences.purpose == 'Rent') {
      _minBudgetController.text = '₹${_preferences.minBudget.round()}';
      _maxBudgetController.text = '₹${_preferences.maxBudget.round()}';
    } else {
      _minBudgetController.text = '₹${(_preferences.minBudget * 100).round()} Lakh';
      _maxBudgetController.text = _preferences.maxBudget >= 1.0
          ? '₹${_preferences.maxBudget.toStringAsFixed(2)} Cr'
          : '₹${(_preferences.maxBudget * 100).round()} Lakh';
    }
  }

  void _goToNextStep() {
    if (_currentStep < 7) {
      setState(() {
        _currentStep++;
      });
    } else if (_currentStep == 7) {
      _generateResults();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        if (_currentStep == 9) {
          _currentStep = 7; // Go back from Results to Lifestyle
        } else {
          _currentStep--;
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _resetAllPreferences() {
    setState(() {
      _preferences = PropertyPreferenceModel();
      _currentStep = 0;
      _allResults = [];
      _filteredResults = [];
      _isMapMode = false;
      _updateBudgetControllers();
    });
  }

  Future<void> _generateResults() async {
    setState(() {
      _currentStep = 8; // Loading animation
    });

    // Sleek short delay for premium UX computation animation
    await Future.delayed(const Duration(milliseconds: 900));

    // STRICT: Only use published properties
    final sourceProperties = PropertyStateService.instance.publishedProperties;

    // Run matching engine
    final matches = PerfectPropertyMatchingEngine.evaluateMatches(
      properties: sourceProperties,
      preferences: _preferences,
    );

    if (mounted) {
      setState(() {
        _allResults = matches;
        _applySortAndFilters();
        _currentStep = 9; // Results View
      });
    }
  }

  void _applySortAndFilters() {
    List<PropertyMatchResult> list = List.from(_allResults);

    // Filter by BHK
    if (_selectedBhkFilter != 'All') {
      list = list.where((m) => m.property.bhk.contains(_selectedBhkFilter)).toList();
    }

    // Filter by Type
    if (_selectedTypeFilter != 'All') {
      list = list.where((m) => m.property.propertyType == _selectedTypeFilter).toList();
    }

    // Sort
    switch (_selectedSort) {
      case 'Lowest Price':
        list.sort((a, b) => a.property.askingPriceCr.compareTo(b.property.askingPriceCr));
        break;
      case 'Highest Price':
        list.sort((a, b) => b.property.askingPriceCr.compareTo(a.property.askingPriceCr));
        break;
      case 'Newest':
        list.sort((a, b) => (b.property.createdAt ?? '').compareTo(a.property.createdAt ?? ''));
        break;
      case 'Most Popular':
        list.sort((a, b) => b.property.score10x.compareTo(a.property.score10x));
        break;
      case 'Best Match':
      default:
        list.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
    }

    setState(() {
      _filteredResults = list;
    });
  }

  Future<void> _handleSaveSearch() async {
    if (!UserSession.isLoggedIn) {
      EnquiryAuthDialog.show(
        context,
        actionLabel: 'Save Search Preferences',
        onSuccess: () {
          _savePreferencesToSupabase();
        },
      );
      return;
    }

    await _savePreferencesToSupabase();
  }

  Future<void> _savePreferencesToSupabase() async {
    setState(() => _isSavingPreferences = true);
    final userEmail = UserSession.email.isNotEmpty ? UserSession.email : 'user@propzen.ai';
    final success = await SupabaseService.instance.savePropertyPreferences(
      userId: userEmail,
      preferences: _preferences,
    );
    setState(() => _isSavingPreferences = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? 'Preferences saved successfully! You will receive notifications for new matches.'
                      : 'Preferences saved locally.',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && !isDesktop;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _currentStep == 9 ? _buildResultsAppBar() : _buildWizardAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 960 : 720),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentView(isDesktop, isTablet),
            ),
          ),
        ),
      ),
      bottomNavigationBar: (_currentStep > 0 && _currentStep < 8)
          ? _buildWizardBottomBar()
          : (_currentStep == 9 ? _buildResultsBottomBar() : null),
    );
  }

  PreferredSizeWidget _buildWizardAppBar() {
    final stepProgress = _currentStep == 0 ? 0.0 : (_currentStep / _totalSteps).clamp(0.0, 1.0);

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B), size: 20),
        onPressed: _goToPreviousStep,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Perfect Property',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          if (_currentStep > 0 && _currentStep <= _totalSteps)
            Text(
              'Step $_currentStep of $_totalSteps',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
            )
          else if (_currentStep == 7)
            Text(
              'Optional Preferences',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
        ],
      ),
      actions: [
        if (_currentStep > 0 && _currentStep < 8)
          TextButton(
            onPressed: _resetAllPreferences,
            child: Text(
              'Reset',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
        IconButton(
          icon: const Icon(LucideIcons.x, color: Color(0xFF64748B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: (_currentStep > 0 && _currentStep <= _totalSteps)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: stepProgress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                minHeight: 4,
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildResultsAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B), size: 20),
        onPressed: () => setState(() => _currentStep = 7),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Perfect Matches',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          Text(
            '${_filteredResults.length} properties match your lifestyle',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
          ),
        ],
      ),
      actions: [
        // Map / List Toggle
        IconButton(
          tooltip: _isMapMode ? 'Switch to Card View' : 'View on Interactive Map',
          icon: Icon(_isMapMode ? LucideIcons.layoutGrid : LucideIcons.map, color: AppTheme.primaryViolet, size: 20),
          onPressed: () => setState(() => _isMapMode = !_isMapMode),
        ),
        IconButton(
          tooltip: 'Edit Preferences',
          icon: const Icon(LucideIcons.slidersHorizontal, color: Color(0xFF1E293B), size: 20),
          onPressed: () => setState(() => _currentStep = 1),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCurrentView(bool isDesktop, bool isTablet) {
    switch (_currentStep) {
      case 0:
        return _buildIntroView(isDesktop);
      case 1:
        return _buildPurposeStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildBudgetStep();
      case 4:
        return _buildPropertyTypeStep();
      case 5:
        return _buildBhkStep();
      case 6:
        return _buildPrioritiesStep();
      case 7:
        return _buildLifestyleStep();
      case 8:
        return _buildLoadingView();
      case 9:
        return _buildResultsView(isDesktop, isTablet);
      default:
        return _buildIntroView(isDesktop);
    }
  }

  // ===========================================================================
  // STEP 0: INTRO SCREEN
  // ===========================================================================
  Widget _buildIntroView(bool isDesktop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.primaryViolet),
                const SizedBox(width: 6),
                Text(
                  'SMART PROPERTY MATCH',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet, letterSpacing: 0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Find Your Perfect Property',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 32 : 26,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Answer a few simple questions and we\'ll help you discover properties that match your lifestyle, budget, and priorities.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 36),

          // Feature Grid Highlights
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildIntroFeatureRow(
                  icon: LucideIcons.target,
                  color: const Color(0xFF6366F1),
                  title: '100% Data-Backed Match Score',
                  subtitle: 'Calculated with real weights: Budget (25%), Location (20%), BHK & Amenities.',
                ),
                const Divider(height: 28, color: Color(0xFFF1F5F9)),
                _buildIntroFeatureRow(
                  icon: LucideIcons.shieldCheck,
                  color: const Color(0xFF10B981),
                  title: 'Only Verified Published Listings',
                  subtitle: 'Strictly live properties verified and approved by PropZen administrators.',
                ),
                const Divider(height: 28, color: Color(0xFFF1F5F9)),
                _buildIntroFeatureRow(
                  icon: LucideIcons.mapPin,
                  color: const Color(0xFFF59E0B),
                  title: 'Exact NCR Geo-Location & Maps',
                  subtitle: 'Explore matches with verified coordinates across Noida, Gurugram, and Delhi.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: AppTheme.primaryViolet.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get Started',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 1: PURPOSE
  // ===========================================================================
  Widget _buildPurposeStep() {
    final purposes = [
      {'title': 'Buy a Property', 'icon': LucideIcons.home, 'val': 'Buy', 'desc': 'Find your dream home or commercial property to own'},
      {'title': 'Rent a Property', 'icon': LucideIcons.building2, 'val': 'Rent', 'desc': 'Discover rental apartments with flexible leases'},
      {'title': 'Investment', 'icon': LucideIcons.trendingUp, 'val': 'Investment', 'desc': 'High rental yield & capital appreciation deals'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'What are you looking for?',
            subtitle: 'Choose your primary goal to help us tailor financial calculations and filters.',
          ),
          const SizedBox(height: 24),
          ...purposes.map((p) {
            final isSelected = _preferences.purpose == p['val'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _preferences.purpose = p['val'] as String;
                    if (_preferences.purpose == 'Rent') {
                      _preferences.minBudget = 20000;
                      _preferences.maxBudget = 80000;
                    } else {
                      _preferences.minBudget = 0.40;
                      _preferences.maxBudget = 2.50;
                    }
                    _updateBudgetControllers();
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryViolet : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          p['icon'] as IconData,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['title'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primaryViolet : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['desc'] as String,
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(LucideIcons.checkCircle2, color: AppTheme.primaryViolet, size: 22)
                      else
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 2: LOCATION
  // ===========================================================================
  Widget _buildLocationStep() {
    final query = _locationSearchController.text.toLowerCase();
    final matchingLocalities = _popularLocalities.where((loc) => loc.toLowerCase().contains(query)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'Where do you want to live?',
            subtitle: 'Select your preferred city and specific localities or sectors in NCR.',
          ),
          const SizedBox(height: 20),

          // City selector
          Text('Select City', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCities.map((city) {
              final isSelected = _preferences.city == city;
              return ChoiceChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _preferences.city = city;
                    });
                  }
                },
                selectedColor: AppTheme.primaryViolet,
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Search Field + GPS Button
          Text('Preferred Localities / Sectors', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationSearchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search city or locality (e.g. Sector 150)',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(LucideIcons.search, size: 16, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (!_preferences.localities.contains('Sector 150')) {
                      _preferences.localities.add('Sector 150');
                    }
                    _preferences.city = 'Noida';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auto-detected location: Sector 150, Noida'), duration: Duration(seconds: 2)),
                  );
                },
                icon: const Icon(LucideIcons.crosshair, size: 14, color: AppTheme.primaryViolet),
                label: Text('Use My Location', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.primaryViolet),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Locality Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matchingLocalities.map((loc) {
              final isSelected = _preferences.localities.contains(loc);
              return FilterChip(
                label: Text(loc),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _preferences.localities.add(loc);
                    } else {
                      _preferences.localities.remove(loc);
                    }
                  });
                },
                selectedColor: const Color(0xFFEDE9FE),
                checkmarkColor: AppTheme.primaryViolet,
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primaryViolet : const Color(0xFF475569),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 3: BUDGET
  // ===========================================================================
  Widget _buildBudgetStep() {
    final isRent = _preferences.purpose == 'Rent';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'What is your budget?',
            subtitle: isRent
                ? 'Specify your preferred monthly rental range.'
                : 'Adjust the slider or enter your purchase budget range.',
          ),
          const SizedBox(height: 28),

          // Range Display Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Selected Budget Range',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                Text(
                  isRent
                      ? '₹${(_preferences.minBudget / 1000).round()}k – ₹${(_preferences.maxBudget / 1000).round()}k / month'
                      : '₹${(_preferences.minBudget * 100).round()} Lakh – ${_preferences.maxBudget >= 1.0 ? '₹${_preferences.maxBudget.toStringAsFixed(2)} Cr' : '₹${(_preferences.maxBudget * 100).round()} Lakh'}',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Range Slider
          if (isRent)
            RangeSlider(
              values: RangeValues(_preferences.minBudget, _preferences.maxBudget),
              min: 10000,
              max: 200000,
              divisions: 38,
              activeColor: AppTheme.primaryViolet,
              inactiveColor: const Color(0xFFE2E8F0),
              onChanged: (values) {
                setState(() {
                  _preferences.minBudget = values.start;
                  _preferences.maxBudget = values.end;
                  _updateBudgetControllers();
                });
              },
            )
          else
            RangeSlider(
              values: RangeValues(_preferences.minBudget, _preferences.maxBudget),
              min: 0.20, // 20 Lakh
              max: 5.00, // 5 Crore
              divisions: 48,
              activeColor: AppTheme.primaryViolet,
              inactiveColor: const Color(0xFFE2E8F0),
              onChanged: (values) {
                setState(() {
                  _preferences.minBudget = values.start;
                  _preferences.maxBudget = values.end;
                  _updateBudgetControllers();
                });
              },
            ),

          const SizedBox(height: 20),

          // Editable min/max fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Minimum Budget', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _minBudgetController,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maximum Budget', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _maxBudgetController,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 4: PROPERTY TYPE
  // ===========================================================================
  Widget _buildPropertyTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'What type of property are you looking for?',
            subtitle: 'You can select multiple property types that interest you.',
          ),
          const SizedBox(height: 20),
          ..._propertyTypeOptions.map((t) {
            final title = t['title'] as String;
            final isSelected = _preferences.propertyTypes.contains(title);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _preferences.propertyTypes.add(title);
                    } else {
                      _preferences.propertyTypes.remove(title);
                    }
                  });
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryViolet.withOpacity(0.12) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(t['icon'] as IconData, color: isSelected ? AppTheme.primaryViolet : const Color(0xFF64748B), size: 20),
                ),
                title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primaryViolet : const Color(0xFF0F172A))),
                subtitle: Text(t['desc'] as String, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                activeColor: AppTheme.primaryViolet,
                tileColor: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 5: BEDROOMS (BHK)
  // ===========================================================================
  Widget _buildBhkStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'How many bedrooms do you need?',
            subtitle: 'Select one or more BHK configurations to expand your search options.',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _bhkOptionsList.map((bhk) {
              final isSelected = _preferences.bhkOptions.contains(bhk);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _preferences.bhkOptions.remove(bhk);
                    } else {
                      _preferences.bhkOptions.add(bhk);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.bedDouble,
                        color: isSelected ? AppTheme.primaryViolet : const Color(0xFF64748B),
                        size: 26,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        bhk,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryViolet : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSelected)
                        const Icon(LucideIcons.checkCircle2, color: AppTheme.primaryViolet, size: 16)
                      else
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 6: PRIORITIES
  // ===========================================================================
  Widget _buildPrioritiesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'What matters most to you?',
            subtitle: 'Select amenities and locality highlights that are essential for your daily life.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _prioritiesList.map((prio) {
              final name = prio['name'] as String;
              final isSelected = _preferences.priorities.contains(name);
              return FilterChip(
                avatar: Icon(
                  prio['icon'] as IconData,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  size: 14,
                ),
                label: Text(name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _preferences.priorities.add(name);
                    } else {
                      _preferences.priorities.remove(name);
                    }
                  });
                },
                selectedColor: AppTheme.primaryViolet,
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 7: OPTIONAL LIFESTYLE PREFERENCES
  // ===========================================================================
  Widget _buildLifestyleStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(
            question: 'Anything else you prefer?',
            subtitle: 'Optional lifestyle tags to fine-tune your matching algorithm. You can skip this step.',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _lifestyleOptions.map((style) {
              final isSelected = _preferences.lifestylePreferences.contains(style);
              return FilterChip(
                label: Text(style),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _preferences.lifestylePreferences.add(style);
                    } else {
                      _preferences.lifestylePreferences.remove(style);
                    }
                  });
                },
                selectedColor: const Color(0xFFEDE9FE),
                checkmarkColor: AppTheme.primaryViolet,
                backgroundColor: Colors.white,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppTheme.primaryViolet : const Color(0xFF475569),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? AppTheme.primaryViolet : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP 8: LOADING ANIMATION
  // ===========================================================================
  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Finding your perfect properties...',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Analyzing live Supabase listings across your budget & location preferences.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 9: RESULTS VIEW
  // ===========================================================================
  Widget _buildResultsView(bool isDesktop, bool isTablet) {
    if (_filteredResults.isEmpty) {
      return _buildNoResultsView();
    }

    if (_isMapMode) {
      final propertiesOnMap = _filteredResults.map((r) => r.property).toList();
      return PropertyMapView(
        properties: propertiesOnMap,
      );
    }

    final bestMatch = _filteredResults.first;
    final otherMatches = _filteredResults.skip(1).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Sort Bar
          _buildFilterSortBar(),
          const SizedBox(height: 20),

          // 1. BEST MATCH SECTION
          Text(
            '★ Best Match For You',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _buildMatchCard(bestMatch, isFeatured: true),

          const SizedBox(height: 28),

          // 2. RECOMMENDED & OTHER MATCHES
          if (otherMatches.isNotEmpty) ...[
            Text(
              'Recommended Matches',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            ...otherMatches.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMatchCard(m),
                )),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.arrowUpDown, size: 14, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text('Sort:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              items: ['Best Match', 'Lowest Price', 'Highest Price', 'Newest', 'Most Popular']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSort = val;
                    _applySortAndFilters();
                  });
                }
              },
            ),
          ),
          const Spacer(),
          // Filter button
          InkWell(
            onTap: () => setState(() => _currentStep = 1),
            child: Row(
              children: [
                const Icon(LucideIcons.slidersHorizontal, size: 14, color: AppTheme.primaryViolet),
                const SizedBox(width: 4),
                Text('Adjust', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(PropertyMatchResult match, {bool isFeatured = false}) {
    final p = match.property;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFeatured ? AppTheme.primaryViolet : const Color(0xFFE2E8F0),
          width: isFeatured ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Banner with Match Score Badge
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  p.dynamicImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9)),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: isFeatured
                        ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)])
                        : const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${match.matchScore}% Match',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              if (match.alternativeReason != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      match.alternativeReason!,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFCD34D)),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.title,
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.propertyType,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${p.effectiveLocality}, ${p.city}',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Price and Specs
                Row(
                  children: [
                    Text(
                      p.formattedPrice,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.bhk} • ${p.sqft} sq.ft',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // WHY THIS PROPERTY MATCHES (Bullet points)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this matches your preferences:',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      ...match.matchReasons.map((reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('✓ ', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                                Expanded(
                                  child: Text(
                                    reason.replaceAll('✓ ', ''),
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // View Details Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => PropertyDetailsScreen(property: p),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFeatured ? AppTheme.primaryViolet : const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Details',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.chevronRight, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NO RESULTS VIEW
  // ===========================================================================
  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.searchX, color: Color(0xFFEF4444), size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'We couldn\'t find an exact match.',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Try expanding your budget range or selecting additional localities to discover more verified properties.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _preferences.maxBudget = _preferences.maxBudget * 1.5;
                      _updateBudgetControllers();
                      _currentStep = 3;
                    });
                  },
                  icon: const Icon(LucideIcons.indianRupee, size: 14),
                  label: const Text('Increase Budget'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _preferences.localities = List.from(_popularLocalities);
                      _currentStep = 2;
                    });
                  },
                  icon: const Icon(LucideIcons.mapPin, size: 14),
                  label: const Text('Expand Location'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _currentStep = 1),
                  icon: const Icon(LucideIcons.slidersHorizontal, size: 14),
                  label: const Text('Edit Preferences'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BARS
  // ===========================================================================
  Widget _buildWizardBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 1)
              OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Text('Back', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              ),
            if (_currentStep > 1) const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _goToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 7 ? 'Find My Matches' : 'Continue',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.arrowRight, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(LucideIcons.slidersHorizontal, size: 14, color: Color(0xFF475569)),
                label: Text('Edit Search', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSavingPreferences ? null : _handleSaveSearch,
                icon: _isSavingPreferences
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.bookmark, size: 15, color: Colors.white),
                label: Text(
                  _isSavingPreferences ? 'Saving...' : 'Save My Search',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader({required String question, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
        ),
      ],
    );
  }
}
