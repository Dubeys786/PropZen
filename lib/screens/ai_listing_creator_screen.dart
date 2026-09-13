import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../services/ai_copywriter_service.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/dealer_subscription_service.dart';
import '../theme/app_theme.dart';
import 'user_profile_screen.dart';
import 'dealer_subscription_plans_screen.dart';

class AiListingCreatorScreen extends StatefulWidget {
  final VoidCallback? onPublished;

  const AiListingCreatorScreen({super.key, this.onPublished});

  @override
  State<AiListingCreatorScreen> createState() => _AiListingCreatorScreenState();
}

class _AiListingCreatorScreenState extends State<AiListingCreatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Controllers
  final _titleController = TextEditingController(text: 'Eldeco Live Greens Resort Residences');
  final _locationController = TextEditingController(text: 'Sector 150');
  final _cityController = TextEditingController(text: 'Noida');
  final _priceController = TextEditingController(text: '1.95');
  final _sqftController = TextEditingController(text: '1850');
  final _bedroomsController = TextEditingController(text: '3 BHK');
  final _bathroomsController = TextEditingController(text: '3');
  final _landmarksController = TextEditingController(text: 'Near Sector 148 Metro & Shaheed Bhagat Singh Park');
  final _descController = TextEditingController();

  String _selectedType = 'Apartment';
  String _selectedFurnishing = 'Semi-Furnished';
  String _selectedStatus = 'Ready to Move';
  String _imageUrl = 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800';

  final Set<String> _selectedAmenities = {
    'Club House',
    'Swimming Pool',
    'Gymnasium',
    '24/7 Security',
    'Power Backup',
    'Covered Parking',
  };

  final List<String> _allAmenities = [
    'Club House',
    'Swimming Pool',
    'Gymnasium',
    '24/7 Security',
    'Power Backup',
    'Covered Parking',
    'Landscaped Gardens',
    'Kids Play Area',
    'Tennis Court',
    'Jogging Track',
  ];

  bool _isGenerating = false;
  GeneratedListingCopy? _generatedCopy;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _sqftController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _landmarksController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _generateAiCopy() async {
    final subService = DealerSubscriptionService.instance;
    if (!subService.canUseAiListingCreator()) {
      _showAiUpgradeDialog();
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a property title'), backgroundColor: AppTheme.coralDanger),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final copy = await AiCopywriterService.instance.generateListingCopy(
        title: title,
        propertyType: _selectedType,
        location: _locationController.text.trim(),
        city: _cityController.text.trim(),
        priceCr: double.tryParse(_priceController.text) ?? 1.5,
        sqft: double.tryParse(_sqftController.text) ?? 1500,
        bhk: _bedroomsController.text.trim(),
        furnishing: _selectedFurnishing,
        possession: _selectedStatus,
        amenities: _selectedAmenities.toList(),
        landmarks: _landmarksController.text.trim(),
        dealerName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Aman Sharma (Prime Realty)',
        dealerPhone: UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '+91 98103 94068',
      );

      setState(() {
        _generatedCopy = copy;
        _descController.text = copy.professionalDescription;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI Listing Copy & Social Marketing Assets Generated!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating copy: $e'), backgroundColor: AppTheme.coralDanger),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $label to clipboard!'), backgroundColor: AppTheme.primaryViolet),
    );
  }

  void _showPreviewDialog() {
    final title = _titleController.text.trim();
    final priceCr = double.tryParse(_priceController.text) ?? 1.5;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Listing Preview', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(LucideIcons.x)),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(_imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 14),
                        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${_locationController.text}, ${_cityController.text}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 10),
                        Text('₹ ${priceCr.toStringAsFixed(2)} Cr • ${_bedroomsController.text} • ${_sqftController.text} sq.ft.',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
                        const SizedBox(height: 16),
                        Text('Description:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(_descController.text.isNotEmpty ? _descController.text : 'No description provided.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
                        const SizedBox(height: 16),
                        if (_generatedCopy != null) ...[
                          Text('Key Highlights:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ..._generatedCopy!.highlights.map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.check, size: 12, color: Color(0xFF10B981)),
                                    const SizedBox(width: 6),
                                    Expanded(child: Text(h, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary))),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Back to Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _publishListing();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Confirm & Publish'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAiUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE9FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles, color: AppTheme.primaryViolet, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Creator Requires Pro Plan',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automated AI listing descriptions, amenities summaries, and WhatsApp marketing copy require an active Pro or Premium Dealer Subscription.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade now to unlock 50+ listings, AI lead scoring, and instant social captions.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
              );
            },
            icon: const Icon(LucideIcons.zap, size: 14),
            label: Text('Upgrade to Pro', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showListingLimitDialog() {
    final sub = DealerSubscriptionService.instance.currentSubscription;
    final activeCount = PropertyStateService.instance.dealerProperties.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Listing Limit Reached',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your current ${sub.planName} allows a maximum of ${sub.listingLimit} active listings.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Listings Used:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  Text('$activeCount / ${sub.listingLimit}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Upgrade to Pro or Premium to list more properties on PropZen.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
              );
            },
            icon: const Icon(LucideIcons.zap, size: 14),
            label: Text('Upgrade Plan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishListing() async {
    final subService = DealerSubscriptionService.instance;
    if (!subService.canCreateListing()) {
      _showListingLimitDialog();
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isPublishing = true);

    final priceCr = double.tryParse(_priceController.text) ?? 1.5;
    final sqft = double.tryParse(_sqftController.text) ?? 1500;
    final newId = 'PROP-${DateTime.now().millisecondsSinceEpoch}';

    final prop = Property(
      id: newId,
      dealerId: UserSession.mobileNumber.isNotEmpty ? 'dealer_${UserSession.mobileNumber}' : 'dealer_ncr_01',
      dealerName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Aman Sharma (Prime Realty)',
      dealerPhone: UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '+91 98103 94068',
      dealerEmail: UserSession.email,
      title: title,
      description: _descController.text,
      propertyType: _selectedType,
      bhk: _bedroomsController.text.trim(),
      askingPriceCr: priceCr,
      sqft: sqft.round(),
      city: _cityController.text.trim(),
      sector: _locationController.text.trim(),
      address: '${_locationController.text.trim()}, ${_cityController.text.trim()}',
      imageUrl: _imageUrl,
      amenities: _selectedAmenities.toList(),
      category: 'Residential',
      possessionStatus: _selectedStatus,
      furnishingStatus: _selectedFurnishing,
      isVerified: true,
      intelligenceScore: 92,
      investmentScore: 90,
      status: 'published',
    );

    PropertyStateService.instance.addProperty(prop);

    // Persist to Supabase
    try {
      await SupabaseService.instance.submitDealerProperty(
        prop,
        dealerId: prop.dealerId,
        dealerName: prop.dealerName,
        dealerPhone: prop.dealerPhone,
        dealerEmail: prop.dealerEmail,
      );
    } catch (_) {}

    setState(() => _isPublishing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Property successfully published and active in catalog!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    widget.onPublished?.call();
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
              child: const Icon(LucideIcons.wand2, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Listing Creator',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Text(
                  'Auto-Generate Multichannel High-Conversion Copy',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _showPreviewDialog,
              icon: const Icon(LucideIcons.eye, size: 14),
              label: Text(_isPublishing ? 'Publishing...' : 'Preview & Publish', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Basic Metadata Entry Form
                _buildFormSection(),
                const SizedBox(height: 20),

                // 2. Generate with AI Button
                _buildGenerateButton(),
                const SizedBox(height: 24),

                // 3. AI Generated Copy Showcase Tabs
                if (_generatedCopy != null) _buildGeneratedOutputSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.building, size: 18, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Text('Property Details & Media', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),

              // Title & Type
              if (isNarrow) ...[
                _buildInput('Property Title', _titleController, 'e.g. ATS Pious Orchards'),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['Apartment', 'Villa', 'Plot', 'Office Space', 'Penthouse']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      flex: 65,
                      child: _buildInput('Property Title', _titleController, 'e.g. ATS Pious Orchards'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: ['Apartment', 'Villa', 'Plot', 'Office Space', 'Penthouse']
                                .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.inter(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedType = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // Location & City
              if (isNarrow) ...[
                _buildInput('Location / Sector', _locationController, 'e.g. Sector 150'),
                const SizedBox(height: 12),
                _buildInput('City', _cityController, 'e.g. Noida'),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildInput('Location / Sector', _locationController, 'e.g. Sector 150'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput('City', _cityController, 'e.g. Noida'),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // Price & Area & BHK
              if (isNarrow) ...[
                _buildInput('Asking Price (₹ Cr)', _priceController, '1.95', TextInputType.number),
                const SizedBox(height: 12),
                _buildInput('Super Area (Sq. Ft.)', _sqftController, '1850', TextInputType.number),
                const SizedBox(height: 12),
                _buildInput('BHK Configuration', _bedroomsController, '3 BHK'),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildInput('Asking Price (₹ Cr)', _priceController, '1.95', TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput('Super Area (Sq. Ft.)', _sqftController, '1850', TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput('BHK Configuration', _bedroomsController, '3 BHK'),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // Status & Landmarks
              if (isNarrow) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Possession Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['Ready to Move', 'Under Construction', 'Immediate']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInput('Nearby Landmarks', _landmarksController, 'e.g. Metro station, school'),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Possession Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: ['Ready to Move', 'Under Construction', 'Immediate']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedStatus = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput('Nearby Landmarks', _landmarksController, 'e.g. Metro station, school'),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

          // Amenities Selector
          Text('Key Amenities Available:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allAmenities.map((a) {
              final isSel = _selectedAmenities.contains(a);
              return FilterChip(
                label: Text(a, style: GoogleFonts.inter(fontSize: 11, color: isSel ? Colors.white : AppTheme.textPrimary)),
                selected: isSel,
                selectedColor: AppTheme.primaryViolet,
                checkmarkColor: Colors.white,
                backgroundColor: AppTheme.surfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onSelected: (sel) {
                  setState(() {
                    if (sel) {
                      _selectedAmenities.add(a);
                    } else {
                      _selectedAmenities.remove(a);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      );
    },
  ),
);
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateAiCopy,
        icon: _isGenerating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
        label: Text(
          _isGenerating ? 'AI is Crafting Multichannel Copy...' : 'Generate with AI',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildGeneratedOutputSection() {
    final copy = _generatedCopy!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
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
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.checkCheck, color: Color(0xFF10B981), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('AI Generated Listing Copy & Marketing Assets',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              IconButton(
                onPressed: _generateAiCopy,
                icon: const Icon(LucideIcons.refreshCw, size: 16, color: AppTheme.primaryViolet),
                tooltip: 'Regenerate All Copy',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Short Headline Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(copy.headline, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(copy.headline, 'Headline'),
                  icon: const Icon(LucideIcons.copy, size: 14, color: AppTheme.textMuted),
                  tooltip: 'Copy Headline',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryViolet,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.primaryViolet,
            labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: '📄 Professional Description'),
              Tab(text: '✨ Highlights & Selling Points'),
              Tab(text: '💬 WhatsApp Listing Text'),
              Tab(text: '📸 Instagram / Reel Caption'),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Views
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Description
                _buildEditableDescriptionTab(copy),

                // Tab 2: Highlights
                _buildHighlightsTab(copy),

                // Tab 3: WhatsApp
                _buildFormattedCopyTab(copy.whatsAppText, 'WhatsApp Listing Text'),

                // Tab 4: Instagram
                _buildFormattedCopyTab(copy.instagramCaption, 'Instagram Caption'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDescriptionTab(GeneratedListingCopy copy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Editable Professional Description:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            TextButton.icon(
              onPressed: () => _copyToClipboard(_descController.text, 'Description'),
              icon: const Icon(LucideIcons.copy, size: 12),
              label: const Text('Copy Text', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: TextField(
            controller: _descController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceSubtle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightsTab(GeneratedListingCopy copy) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Selling Points:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          ...copy.keySellingPoints.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary))),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Text('Location & Amenities Summary:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(copy.locationSummary, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, height: 1.4)),
          const SizedBox(height: 6),
          Text(copy.amenitiesSummary, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFormattedCopyTab(String text, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ready to Share & Publish:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ElevatedButton.icon(
              onPressed: () => _copyToClipboard(text, label),
              icon: const Icon(LucideIcons.copy, size: 12),
              label: Text('Copy $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SelectableText(
                text,
                style: GoogleFonts.inter(fontSize: 11, height: 1.45, color: AppTheme.textPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, String hint, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
          ),
        ),
      ],
    );
  }
}
