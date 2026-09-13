import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/everyday_utility_service.dart';
import 'public_property_verification_screen.dart';

class PropertyToolsScreen extends StatefulWidget {
  final int initialTabIndex;

  const PropertyToolsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PropertyToolsScreen> createState() => _PropertyToolsScreenState();
}

class _PropertyToolsScreenState extends State<PropertyToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EverydayUtilityService _service = EverydayUtilityService.instance;

  // 1. Interior State
  double _interiorSize = 1450;
  String _interiorFinish = 'Standard';

  // 2. Renovation State
  double _renoArea = 900;
  String _renoScope = 'Partial Upgrade';

  // 3. Vastu State
  String _vastuFacing = 'East';

  // 4. Checklist State
  String _selectedRole = 'Buyer';
  final Set<String> _checkedDocs = {};

  final List<String> _interiorFinishes = ['Basic', 'Standard', 'Premium', 'Luxury'];
  final List<String> _renovationScopes = ['Touch-up & Cosmetic', 'Partial Upgrade', 'Full Overhaul'];
  final List<String> _vastuDirections = ['East', 'North', 'North-East', 'West', 'South', 'North-West', 'South-East', 'South-West'];

  final Map<String, List<Map<String, String>>> _documentChecklists = {
    'Buyer': [
      {'title': 'Title Deed / Sale Deed', 'desc': 'Original registered conveyance establishing seller ownership chain.'},
      {'title': 'Mother Deed (30-Year Chain)', 'desc': 'Traces uninterrupted ownership history through previous transfers.'},
      {'title': 'Encumbrance Certificate (EC Form 15)', 'desc': 'Issued by Sub-Registrar confirming property has zero legal dues or mortgages.'},
      {'title': 'Sanctioned Building Plan & OC/CC', 'desc': 'Municipal-approved structural blueprint and Occupancy Certificate.'},
      {'title': 'RERA Registration Certificate', 'desc': 'Mandatory verification number for projects launched after 2016.'},
      {'title': 'Property Tax Paid Receipts', 'desc': 'Latest 3 years municipal tax receipts with nil outstanding.'},
      {'title': 'Society / Builder NOC', 'desc': 'No Objection Certificate from RWA or builder declaring nil dues.'},
    ],
    'Seller': [
      {'title': 'Original Allotment Letter', 'desc': 'Issued by authority or builder during primary booking.'},
      {'title': 'Possession Letter & Handover Proof', 'desc': 'Physical possession documentation from builder.'},
      {'title': 'Up-to-Date Utility Bills', 'desc': 'Electricity, water, gas bills with clearance certificates.'},
      {'title': 'Bank Loan Closure / NOC', 'desc': 'If previously mortgaged, loan closure letter and original deeds release.'},
    ],
    'Dealer': [
      {'title': 'RERA Agent Registration', 'desc': 'State RERA certificate allowing authorized real estate broking.'},
      {'title': 'Standardized Mandate Agreement', 'desc': 'Written seller/buyer representation contract with agreed terms.'},
      {'title': 'KYC of All Parties', 'desc': 'Aadhaar, PAN, and identity verification prior to formal agreement.'},
    ],
    'Builder': [
      {'title': 'Land Title & Non-Encumbrance Certificate', 'desc': 'Clean freehold land ownership documents.'},
      {'title': 'Environmental Clearance (MoEF)', 'desc': 'Environmental impact assessment approval for large layouts.'},
      {'title': 'Fire & Aviation NOC', 'desc': 'Height and safety clearances from respective statutory authorities.'},
      {'title': 'Quarterly RERA Financial Escrow Updates', 'desc': 'Mandatory 70% project escrow bank account audit reports.'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double val) {
    return '₹ ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'PropZen Property & Living Tools',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF7C3AED),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Interior Cost'),
                Tab(text: 'Renovation Cost'),
                Tab(text: 'Vastu Tool'),
                Tab(text: 'Document Checklist'),
                Tab(text: 'Verification Guide'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInteriorTab(),
          _buildRenovationTab(),
          _buildVastuTab(),
          _buildChecklistTab(),
          _buildVerificationGuideTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: INTERIOR COST CALCULATOR
  // ===========================================================================
  Widget _buildInteriorTab() {
    final result = _service.calculateInteriorCost(
      propertySizeSqft: _interiorSize,
      finishLevel: _interiorFinish,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interior Cost Estimator', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Calculate estimated budget for turnkey modular kitchens, woodwork, false ceiling, and lighting.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    // Size Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Super Built-Up Area', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                        Text('${_interiorSize.toStringAsFixed(0)} sq.ft.', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xFF7C3AED), thumbColor: const Color(0xFF7C3AED)),
                      child: Slider(
                        value: _interiorSize,
                        min: 500,
                        max: 5000,
                        divisions: 90,
                        onChanged: (v) => setState(() => _interiorSize = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Finish Level Choice
                    Text('Finish & Material Specification', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _interiorFinishes.map((f) {
                        final isSelected = _interiorFinish == f;
                        return ChoiceChip(
                          label: Text(f, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF475569))),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1))),
                          onSelected: (s) {
                            if (s) setState(() => _interiorFinish = f);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Estimated Output
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Interior Budget', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Text(_formatCurrency(result.estimatedTotalCost), style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                    Text('Estimated rate: ₹${result.ratePerSqft.toStringAsFixed(0)} / sq.ft.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),
                    Text('Room & Category Breakdown', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    ...result.categoryBreakdown.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                              Text(_formatCurrency(e.value), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 14),
                    Text('Estimated cost — actual cost depends on custom materials, city, vendor and detailed design.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: RENOVATION CALCULATOR
  // ===========================================================================
  Widget _buildRenovationTab() {
    final result = _service.calculateRenovationCost(
      areaSqft: _renoArea,
      renovationScope: _renoScope,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home Renovation Cost Estimator', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Estimate tiling, civil work, bathroom overhauls, repainting and electrical upgrades.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Area to Renovate', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                        Text('${_renoArea.toStringAsFixed(0)} sq.ft.', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(activeTrackColor: const Color(0xFF7C3AED), thumbColor: const Color(0xFF7C3AED)),
                      child: Slider(
                        value: _renoArea,
                        min: 200,
                        max: 4000,
                        divisions: 76,
                        onChanged: (v) => setState(() => _renoArea = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('Renovation Scope', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _renovationScopes.map((scope) {
                        final isSelected = _renoScope == scope;
                        return ChoiceChip(
                          label: Text(scope, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF475569))),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1))),
                          onSelected: (s) {
                            if (s) setState(() => _renoScope = scope);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Renovation Budget', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Text(_formatCurrency(result.estimatedTotalBudget), style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Text('Scope Breakdown', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    ...result.roomBreakdown.entries.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                              Text(_formatCurrency(e.value), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: TRADITIONAL VASTU EDUCATIONAL TOOL
  // ===========================================================================
  Widget _buildVastuTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.compass, size: 22, color: Color(0xFF7C3AED)),
                        const SizedBox(width: 10),
                        Text('Traditional Vastu Educational Guide', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Educational guidance based on traditional architectural principles. Not presented as scientific or binding fact.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    Text('Select Property Facing Direction', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vastuDirections.map((dir) {
                        final isSelected = _vastuFacing == dir;
                        return ChoiceChip(
                          label: Text(dir, style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF475569))),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1))),
                          onSelected: (s) {
                            if (s) setState(() => _vastuFacing = dir);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Vastu Principles Grid
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Traditional Room Placement Principles for $_vastuFacing Facing Home', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    _buildVastuRuleRow('Main Entrance', 'North-East (Ishan) or East is traditionally considered most auspicious for positive daylight energy.'),
                    _buildVastuRuleRow('Master Bedroom', 'South-West (Nairutya) corner is associated with stability, longevity and grounding.'),
                    _buildVastuRuleRow('Kitchen (Fire Element)', 'South-East (Agneya) corner is ideal for the cooking hearth.'),
                    _buildVastuRuleRow('Pooja Room / Meditation', 'North-East or North direction ensures tranquil morning solar energy.'),
                    _buildVastuRuleRow('Living Room', 'North, East, or North-East ensures welcoming openness for guests and natural light.'),
                    const SizedBox(height: 14),
                    Text('Note: Traditional Vastu guidance is cultural architectural folklore. Personal comfort, natural ventilation, and functional design should always take precedence.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVastuRuleRow(String room, String guidance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(room, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(guidance, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155)))),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: PROPERTY DOCUMENT CHECKLIST
  // ===========================================================================
  Widget _buildChecklistTab() {
    final docs = _documentChecklists[_selectedRole] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property Document Checklist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Interactive verification checklist tailored by transaction role. Does not substitute for title verification by a licensed advocate.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 18),

                    // Role selector
                    Wrap(
                      spacing: 8,
                      children: ['Buyer', 'Seller', 'Dealer', 'Builder'].map((role) {
                        final isSelected = _selectedRole == role;
                        return ChoiceChip(
                          label: Text(role, style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF475569))),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFCBD5E1))),
                          onSelected: (s) {
                            if (s) setState(() => _selectedRole = role);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Checklist Items
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_selectedRole Required Documents (${_checkedDocs.length}/${docs.length} Verified)', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 14),

                    ...docs.map((d) {
                      final title = d['title']!;
                      final desc = d['desc']!;
                      final isChecked = _checkedDocs.contains(title);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isChecked ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isChecked ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _checkedDocs.remove(title);
                              } else {
                                _checkedDocs.add(title);
                              }
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(isChecked ? LucideIcons.checkSquare : LucideIcons.square, color: isChecked ? const Color(0xFF16A34A) : const Color(0xFF94A3B8), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: isChecked ? const Color(0xFF166534) : const Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 5: PROPERTY VERIFICATION GUIDE (9 STEPS)
  // ===========================================================================
  Widget _buildVerificationGuideTab() {
    final steps = [
      {'step': '1', 'title': 'Ownership & Title Verification', 'desc': 'Check chain of title for at least 30 years to guarantee clear, marketable ownership without undisclosed coparceners.'},
      {'step': '2', 'title': 'Encumbrance Certificate (EC)', 'desc': 'Obtain Form 15 from Sub-Registrar to verify absence of recorded bank liens, attachment orders, or lis pendens.'},
      {'step': '3', 'title': 'Sanctioned Building Plan & OC', 'desc': 'Confirm construction exactly matches municipality-sanctioned architectural blueprints with valid Occupancy Certificate.'},
      {'step': '4', 'title': 'RERA Registration & Compliance', 'desc': 'Verify project registration on state RERA portal, developer quarterly updates, and escrow bank details.'},
      {'step': '5', 'title': 'Property Tax & Utility Dues', 'desc': 'Ensure municipality tax receipts and electricity/water bills have zero outstanding arrears.'},
      {'step': '6', 'title': 'Physical Site Inspection', 'desc': 'Inspect boundary demarcation, carpet area vs super area, access roads, and verify no physical encroachment.'},
      {'step': '7', 'title': 'Society / Builder NOC', 'desc': 'Acquire formal clearance certifying all maintenance, transfer charges, and club fees are settled.'},
      {'step': '8', 'title': 'Agreement to Sell Review', 'desc': 'Vet cancellation clauses, penalty terms, possession timelines, and indemnity protections before signing.'},
      {'step': '9', 'title': 'Final Legal Consultation', 'desc': 'Engage an independent real estate lawyer for formal Title Search Report (TSR) prior to paying token advance.'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 24),
                        const SizedBox(width: 10),
                        Text('9-Step Property Legal Verification Guide', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Essential legal checkpoints every property buyer in India should execute before transferring advance tokens.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PublicPropertyVerificationScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.search, size: 16, color: Colors.white),
                      label: Text('Open PropZen Online Verification Tool', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ...steps.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.12), shape: BoxShape.circle),
                          child: Center(child: Text(s['step']!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['title']!, style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              Text(s['desc']!, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
