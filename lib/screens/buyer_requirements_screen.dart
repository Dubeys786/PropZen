import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/buyer_requirement.dart';
import '../models/property.dart';
import '../services/ai_matching_service.dart';
import '../services/deal_room_service.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';
import 'site_visit_booking_screen.dart';
import 'deal_room_screen.dart';
import 'user_profile_screen.dart';

class BuyerRequirementsScreen extends StatefulWidget {
  const BuyerRequirementsScreen({super.key});

  @override
  State<BuyerRequirementsScreen> createState() => _BuyerRequirementsScreenState();
}

class _BuyerRequirementsScreenState extends State<BuyerRequirementsScreen> {
  final _aiMatchingService = AiMatchingService.instance;

  late TextEditingController _locationController;
  late TextEditingController _minBudgetController;
  late TextEditingController _maxBudgetController;
  late TextEditingController _minAreaController;

  String _selectedPropertyType = 'Apartment';
  String _selectedBhk = '3 BHK';
  String _selectedPurpose = 'Self-Use';
  String _selectedPossession = 'Ready to Move';
  final Set<String> _selectedAmenities = {'Club House', 'Swimming Pool', 'Gym', 'Security', 'Power Backup'};

  final List<String> _availableAmenities = [
    'Club House',
    'Swimming Pool',
    'Gym',
    'Security',
    'Power Backup',
    'Covered Parking',
    'Children Play Area',
    'Park Facing',
    'Jogging Track',
  ];

  List<PropertyMatchResult> _topMatches = [];
  bool _isEditingRequirement = false;

  @override
  void initState() {
    super.initState();
    final req = _aiMatchingService.currentRequirement ??
        BuyerRequirement.defaultRequirement(UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active', UserSession.fullName);

    _locationController = TextEditingController(text: req.preferredLocations.join(', '));
    _minBudgetController = TextEditingController(text: req.minBudgetCr.toString());
    _maxBudgetController = TextEditingController(text: req.maxBudgetCr.toString());
    _minAreaController = TextEditingController(text: req.minAreaSqft.round().toString());
    _selectedPropertyType = req.propertyType;
    _selectedBhk = req.bhk;
    _selectedPurpose = req.purchasePurpose;
    _selectedPossession = req.possessionPreference;
    _selectedAmenities.clear();
    _selectedAmenities.addAll(req.requiredAmenities);

    _calculateMatches();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _minAreaController.dispose();
    super.dispose();
  }

  void _calculateMatches() {
    final locs = _locationController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final minB = double.tryParse(_minBudgetController.text) ?? 1.0;
    final maxB = double.tryParse(_maxBudgetController.text) ?? 3.0;
    final minA = double.tryParse(_minAreaController.text) ?? 1200;

    final updatedReq = BuyerRequirement(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      userId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active',
      userName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Buyer',
      userPhone: UserSession.mobileNumber,
      userEmail: UserSession.email,
      preferredLocations: locs.isNotEmpty ? locs : ['Sector 150', 'Noida Expressway'],
      minBudgetCr: minB,
      maxBudgetCr: maxB,
      propertyType: _selectedPropertyType,
      bhk: _selectedBhk,
      minAreaSqft: minA,
      requiredAmenities: _selectedAmenities.toList(),
      purchasePurpose: _selectedPurpose,
      possessionPreference: _selectedPossession,
    );

    _aiMatchingService.saveRequirement(updatedReq);

    setState(() {
      _topMatches = _aiMatchingService.getTopMatches(requirement: updatedReq);
      _isEditingRequirement = false;
    });
  }

  void _openDealRoomForProperty(Property prop) {
    final room = DealRoomService.instance.getOrCreateDealRoom(
      property: prop,
      buyerId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer_active',
      buyerName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Prospective Buyer',
      buyerPhone: UserSession.mobileNumber,
      buyerEmail: UserSession.email,
      dealerId: prop.dealerId.isNotEmpty ? prop.dealerId : 'dealer_ncr_01',
      dealerName: prop.dealerName.isNotEmpty ? prop.dealerName : 'Aman Sharma (Prime Realty)',
      dealerPhone: prop.dealerPhone.isNotEmpty ? prop.dealerPhone : '+91 98103 94068',
      dealerEmail: prop.dealerEmail,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DealRoomScreen(dealRoomId: room.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Property Auto-Match',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  'Institutional Multi-Factor Fit Engine',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isEditingRequirement = !_isEditingRequirement),
            icon: Icon(_isEditingRequirement ? LucideIcons.check : LucideIcons.slidersHorizontal, color: AppTheme.primaryViolet),
            tooltip: _isEditingRequirement ? 'Save & Match' : 'Edit Requirements',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Requirement Summary / Edit Card
                _buildRequirementHeaderCard(),
                const SizedBox(height: 20),

                // Matching Results Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.target, size: 18, color: AppTheme.primaryViolet),
                        const SizedBox(width: 8),
                        Text(
                          'Top Matches For You (${_topMatches.length})',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      'Ranked by Multi-Attribute Fit',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Match Cards List
                if (_topMatches.isEmpty)
                  _buildNoMatchesView()
                else
                  ..._topMatches.asMap().entries.map((entry) {
                    final index = entry.key;
                    final match = entry.value;
                    return _buildPropertyMatchCard(index + 1, match);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.userCheck, color: AppTheme.primaryViolet, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Active Property Criteria',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Tailored to your budget, location, and BHK preferences',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (_isEditingRequirement) {
                    _calculateMatches();
                  } else {
                    setState(() => _isEditingRequirement = true);
                  }
                },
                icon: Icon(_isEditingRequirement ? LucideIcons.sparkles : LucideIcons.edit2, size: 14),
                label: Text(_isEditingRequirement ? 'Apply & Re-Match' : 'Edit Criteria', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditingRequirement ? AppTheme.primaryViolet : AppTheme.surfaceSubtle,
                  foregroundColor: _isEditingRequirement ? Colors.white : AppTheme.primaryViolet,
                  elevation: _isEditingRequirement ? 2 : 0,
                  side: BorderSide(color: _isEditingRequirement ? Colors.transparent : AppTheme.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          if (_isEditingRequirement) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 16),

            // Edit Form Fields
            _buildEditForm(),
          ] else ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCriterionChip(LucideIcons.mapPin, _locationController.text.isNotEmpty ? _locationController.text : 'Sector 150, Noida'),
                _buildCriterionChip(LucideIcons.indianRupee, '₹${_minBudgetController.text} Cr – ₹${_maxBudgetController.text} Cr'),
                _buildCriterionChip(LucideIcons.home, '$_selectedBhk $_selectedPropertyType'),
                _buildCriterionChip(LucideIcons.calendar, _selectedPossession),
                _buildCriterionChip(LucideIcons.briefcase, _selectedPurpose),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location
        Text('Preferred Locations / Sectors (comma separated)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: 'e.g. Sector 150, Noida Expressway, Greater Noida',
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
          ),
        ),
        const SizedBox(height: 14),

        // Budget Range
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Min Budget (₹ Cr)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _minBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '1.2',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  Text('Max Budget (₹ Cr)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _maxBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '2.8',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // BHK & Property Type
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bedrooms (BHK)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedBhk,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['1 BHK', '2 BHK', '3 BHK', '4 BHK', '5+ BHK']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b, style: GoogleFonts.inter(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedBhk = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Property Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPropertyType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Apartment', 'Villa', 'Plot', 'Office Space']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPropertyType = val!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Possession & Purpose
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Possession Timeline', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPossession,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Ready to Move', 'Within 6 Months', 'Under Construction']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPossession = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchase Purpose', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedPurpose,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Self-Use', 'Investment', 'Rental Income']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.inter(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPurpose = val!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Amenities Checklist
        Text('Preferred Amenities', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableAmenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity, style: GoogleFonts.inter(fontSize: 11, color: isSelected ? Colors.white : AppTheme.textPrimary)),
              selected: isSelected,
              selectedColor: AppTheme.primaryViolet,
              checkmarkColor: Colors.white,
              backgroundColor: AppTheme.surfaceSubtle,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCriterionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryViolet),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPropertyMatchCard(int rank, PropertyMatchResult match) {
    final prop = match.property;
    final isTop3 = rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isTop3 ? AppTheme.primaryViolet.withOpacity(0.3) : AppTheme.borderLight, width: isTop3 ? 1.5 : 1.0),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isTop3 ? AppTheme.primaryViolet.withOpacity(0.06) : AppTheme.surfaceSubtle,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTop3 ? AppTheme.primaryViolet : AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$rank Match',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      match.matchGrade,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                    ),
                  ],
                ),
                // Percentage badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Text(
                        '${match.matchPercentage}% Match',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        prop.dynamicImageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 90,
                          height: 90,
                          color: AppTheme.surfaceSubtle,
                          child: const Icon(LucideIcons.building, color: AppTheme.textHint),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  prop.title,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (prop.isVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('✓ Verified', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${prop.effectiveLocality}, ${prop.city}',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₹ ${prop.askingPriceCr > 0 ? prop.askingPriceCr.toStringAsFixed(2) : (prop.price / 10000000).toStringAsFixed(2)} Cr',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${prop.bhk} • ${prop.sqft.round()} sq.ft.',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 12),

                // Match Reasons Chips
                Text('Why this is a top match:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: match.matchReasons.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: r.isMatched ? const Color(0xFF10B981).withOpacity(0.08) : AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: r.isMatched ? const Color(0xFF10B981).withOpacity(0.25) : AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(r.isMatched ? LucideIcons.check : LucideIcons.circle, size: 10, color: r.isMatched ? const Color(0xFF10B981) : AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(
                            r.text,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: r.isMatched ? FontWeight.w600 : FontWeight.normal,
                              color: r.isMatched ? const Color(0xFF065F46) : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => PropertyDetailsScreen(property: prop, propertyId: prop.id),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.externalLink, size: 14),
                        label: Text('View Details', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => SiteVisitBookingScreen(property: prop),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.calendar, size: 14),
                        label: Text('Book Visit', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _openDealRoomForProperty(prop),
                      icon: const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981)),
                      tooltip: 'Enter Safe Deal Room',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildNoMatchesView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.searchX, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No Exact Matches Found', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Try expanding your budget range or adding nearby NCR sectors.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _isEditingRequirement = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Adjust Criteria'),
            ),
          ],
        ),
      ),
    );
  }
}
