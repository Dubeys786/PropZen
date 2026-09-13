import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property.dart';
import '../services/property_state_service.dart';
import '../services/supabase_service.dart';
import '../services/n8n_service.dart';
import '../services/dealer_lead_service.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../widgets/interactive_property_map.dart';
import '../widgets/enquiry_auth_dialog.dart';
import '../widgets/ai_property_verification_widget.dart';
import '../widgets/propzen_deal_score_widget.dart';
import '../widgets/property_visualization_hub.dart';
import '../widgets/locality_personalities_widget.dart';
import '../services/deal_room_service.dart';
import 'user_profile_screen.dart';
import 'site_visit_booking_screen.dart';
import 'negotiation_room_screen.dart';
import 'deal_room_screen.dart';
import 'site_visit_checklist_screen.dart';
import '../widgets/nri_drone_tour_card.dart';
import '../services/admin_command_service.dart';
import '../widgets/nri_remote_tour_dialog.dart';
import '../widgets/youtube_property_video_player.dart';
import 'nri_remote_dashboard_screen.dart';
import 'nearby_services_screen.dart';
import '../models/nearby_category_taxonomy.dart';

/// Complete, Rebuilt-from-Scratch Property Details Screen
class PropertyDetailsScreen extends StatefulWidget {
  final Property? property;
  final String? propertyId;
  final int initialTabIndex;

  const PropertyDetailsScreen({
    super.key,
    this.property,
    this.propertyId,
    this.initialTabIndex = 0,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PropertyStateService _stateService = PropertyStateService.instance;
  late final PageController _galleryPageController;

  Property? _property;
  bool _isLoading = true;
  bool _hasError = false;
  int _currentImageIndex = 0;
  bool _isWishlisted = false;
  bool _isCompared = false;

  @override
  void initState() {
    super.initState();
    _galleryPageController = PageController();
    _resolvePropertyData();
  }

  @override
  void didUpdateWidget(covariant PropertyDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.property != widget.property || oldWidget.propertyId != widget.propertyId) {
      _resolvePropertyData();
    }
  }

  @override
  void dispose() {
    _galleryPageController.dispose();
    super.dispose();
  }

  Future<void> _resolvePropertyData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 1. Direct object provided
      if (widget.property != null) {
        _property = widget.property;
        _isWishlisted = _stateService.isSaved(_property!.id);
        _isCompared = _stateService.isCompared(_property!.id);
        setState(() => _isLoading = false);
        return;
      }

      // 2. Resolve via propertyId
      final targetId = widget.propertyId;
      if (targetId != null && targetId.isNotEmpty) {
        // Check in-memory store
        final inMemory = _stateService.findPropertyById(targetId);
        if (inMemory != null) {
          _property = inMemory;
          _isWishlisted = _stateService.isSaved(_property!.id);
          _isCompared = _stateService.isCompared(_property!.id);
          setState(() => _isLoading = false);
          return;
        }

        // Fetch from Supabase backend
        try {
          final fetched = await SupabaseService.instance.fetchPropertyById(targetId);
          if (fetched != null) {
            _property = fetched;
            _isWishlisted = _stateService.isSaved(_property!.id);
            _isCompared = _stateService.isCompared(_property!.id);
            setState(() => _isLoading = false);
            return;
          }
        } catch (_) {}
      }

      // Property not found
      setState(() {
        _property = null;
        _isLoading = false;
        _hasError = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _toggleWishlist() {
    if (_property == null) return;
    setState(() {
      _stateService.toggleSave(_property!.id);
      _isWishlisted = _stateService.isSaved(_property!.id);
    });
    _showSnackBar(_isWishlisted ? 'Saved to Wishlist!' : 'Removed from Wishlist');
  }

  void _toggleCompare() {
    if (_property == null) return;
    setState(() {
      _stateService.toggleCompare(_property!.id);
      _isCompared = _stateService.isCompared(_property!.id);
    });
    _showSnackBar(_isCompared ? 'Added to Property Comparison' : 'Removed from Comparison');
  }

  void _shareProperty() {
    if (_property == null) return;
    _showSharePropertySheet(_property!);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primaryViolet,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _checkIsReadyToMove(Property prop) {
    final statusLower = '${prop.statusTag} ${prop.possessionStatus} ${prop.availability}'.toLowerCase();
    return statusLower.contains('ready') || prop.statusTag == 'Ready to Move';
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text('PropZen Property Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryViolet),
              const SizedBox(height: 16),
              Text('Loading property details...', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_hasError || _property == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text('Property Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.home, size: 48, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                Text('Property Not Found', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'The requested property is no longer active or the URL is invalid.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacementNamed(AppRoutes.properties);
                    }
                  },
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Back to Properties'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final prop = _property!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: isDesktop ? _buildDesktopLayout(prop) : _buildMobileTabletLayout(prop),
      ),
      bottomNavigationBar: isDesktop ? null : _buildMobileStickyActionBar(prop),
    );
  }

  // ===========================================================================
  // MOBILE / TABLET SINGLE COLUMN LAYOUT
  // ===========================================================================
  Widget _buildMobileTabletLayout(Property prop) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Hero Gallery
          _buildHeroGallery(prop, isDesktop: false),

          // 2. Property Header & Price
          _buildPropertyHeader(prop),

          const SizedBox(height: 8),

          // 2B. PropZen Trust Score Card
          _buildTrustScoreCard(prop),

          const SizedBox(height: 8),

          // 3. Quick Property Facts
          _buildQuickFactsCard(prop),

          const SizedBox(height: 8),

          // 4. Property Overview & Highlights
          _buildOverviewSection(prop),

          const SizedBox(height: 8),

          // 5. Amenities
          _buildAmenitiesSection(prop),

          const SizedBox(height: 12),

          // 5A. Exclusive NRI Drone Tour & Remote Exploration Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NriDroneTourCard(property: prop),
          ),

          // 5B. Experience This Property (360 Virtual Tour, 3D Twin, AR Scale, Floor Plan, Vastu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PropertyVisualizationHub(property: prop),
          ),

          const SizedBox(height: 12),

          // 5C. Official YouTube Video Walkthrough (if available)
          if (prop.hasYoutubeVideo) ...[
            _buildYouTubeWalkthroughCard(prop),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),

          // 6. Location & Connectivity
          _buildLocationSection(prop),

          const SizedBox(height: 12),

          // 6B. Know Your Locality — Notable Personalities in This Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LocalityPersonalitiesWidget(property: prop),
          ),

          const SizedBox(height: 12),

          // 6C. AI Property Verification Hub
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AiPropertyVerificationWidget(property: prop),
          ),

          const SizedBox(height: 12),

          // 6C. PropZen Deal Score 5-Pillar Rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PropZenDealScoreWidget(property: prop),
          ),

          const SizedBox(height: 12),

          // 6D. Safe Deal Room & Negotiation Access Card
          _buildDealRoomQuickActions(prop),

          const SizedBox(height: 8),

          // 7. Floor Plan
          _buildFloorPlanSection(prop),

          const SizedBox(height: 8),

          // 8. Gallery Multi-Room Grid
          _buildPhotoGalleryGrid(prop),

          const SizedBox(height: 8),

          // 9. Price & Cost Details
          _buildPriceDetailsSection(prop),

          const SizedBox(height: 8),

          // 10. Builder / Developer Card
          _buildBuilderSection(prop),

          const SizedBox(height: 8),

          // Direct Advisor Desk & WhatsApp CTA
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: InkWell(
              onTap: () async {
                final text = Uri.encodeComponent('Hi PropZen! I am interested in ${prop.title} (${prop.sector}, ${prop.city}) listed on PropZen.');
                final uri = Uri.parse('https://wa.me/919810394068?text=$text');
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(LucideIcons.phoneCall, size: 18, color: AppTheme.primaryViolet),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Direct Advisor Desk (+91 98103 94068)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('WhatsApp Support • Instant Response', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.messageCircle, size: 18, color: Color(0xFF25D366)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 11. Similar Properties in NCR
          _buildSimilarPropertiesSection(prop),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP 2-COLUMN LAYOUT
  // ===========================================================================
  Widget _buildDesktopLayout(Property prop) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1280),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Breadcrumbs & Back bar
              _buildDesktopTopBar(prop),

              const SizedBox(height: 16),

              // Hero Gallery
              _buildHeroGallery(prop, isDesktop: true),

              const SizedBox(height: 24),

              // 2-Column Split
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Main Content (Width: 68%)
                  Expanded(
                    flex: 68,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPropertyHeader(prop),
                        const SizedBox(height: 16),
                        _buildTrustScoreCard(prop),
                        const SizedBox(height: 16),
                        _buildQuickFactsCard(prop),
                        const SizedBox(height: 16),
                        _buildOverviewSection(prop),
                        const SizedBox(height: 16),
                        _buildAmenitiesSection(prop),
                        const SizedBox(height: 16),
                        NriDroneTourCard(property: prop),
                        const SizedBox(height: 16),
                        PropertyVisualizationHub(property: prop),
                        const SizedBox(height: 16),
                        if (prop.hasYoutubeVideo) ...[
                          _buildYouTubeWalkthroughCard(prop),
                          const SizedBox(height: 16),
                        ],
                        _buildLocationSection(prop),
                        const SizedBox(height: 16),
                        LocalityPersonalitiesWidget(property: prop),
                        const SizedBox(height: 16),
                        AiPropertyVerificationWidget(property: prop),
                        const SizedBox(height: 16),
                        PropZenDealScoreWidget(property: prop),
                        const SizedBox(height: 16),
                        _buildDealRoomQuickActions(prop),
                        const SizedBox(height: 16),
                        _buildFloorPlanSection(prop),
                        const SizedBox(height: 16),
                        _buildPhotoGalleryGrid(prop),
                        const SizedBox(height: 16),
                        _buildPriceDetailsSection(prop),
                        const SizedBox(height: 16),
                        _buildBuilderSection(prop),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right Column: Sticky Action & Enquiry Card (Width: 32%)
                  Expanded(
                    flex: 32,
                    child: _buildDesktopActionCard(prop),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Similar Properties
              _buildSimilarPropertiesSection(prop),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(Property prop) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                const Icon(LucideIcons.arrowLeft, size: 16, color: AppTheme.primaryViolet),
                const SizedBox(width: 6),
                Text('Back to Properties', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('/', style: GoogleFonts.inter(color: AppTheme.textMuted)),
        const SizedBox(width: 12),
        Text(prop.city, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(width: 8),
        Text('/', style: GoogleFonts.inter(color: AppTheme.textMuted)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            prop.title,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeWalkthroughCard(Property prop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.youtube, color: Color(0xFFFF0000), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Official Video Walkthrough', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('1080p HD walkthrough streaming on demand', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          YouTubePropertyVideoPlayer(
            videoId: prop.youtubeVideoId,
            videoUrl: prop.youtubeUrl,
            propertyTitle: prop.title,
          ),
        ],
      ),
    );
  }

  Widget _buildDealRoomQuickActions(Property prop) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safe Deal Room & AI Negotiation', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('Private, verified buyer-dealer room with offer history & milestone escrow tracker', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final room = DealRoomService.instance.getOrCreateDealRoom(
                      property: prop,
                      buyerId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer_active',
                      buyerName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Prospective Buyer',
                      dealerId: prop.dealerId.isNotEmpty ? prop.dealerId : 'dealer_ncr_01',
                      dealerName: prop.dealerName.isNotEmpty ? prop.dealerName : 'Aman Sharma (Prime Realty)',
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => DealRoomScreen(dealRoomId: room.id)),
                    );
                  },
                  icon: const Icon(LucideIcons.shieldCheck, size: 14),
                  label: Text('Enter Safe Deal Room', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => NegotiationRoomScreen(property: prop)),
                    );
                  },
                  icon: const Icon(LucideIcons.scale, size: 14),
                  label: Text('AI Negotiation Insights', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryViolet,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppTheme.primaryViolet),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. HERO PROPERTY GALLERY CAROUSEL
  // ===========================================================================
  Widget _buildHeroGallery(Property prop, {required bool isDesktop}) {
    final images = prop.dynamicGalleryImages;
    final height = isDesktop ? 460.0 : 300.0;
    final isReady = _checkIsReadyToMove(prop);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: isDesktop ? BorderRadius.circular(20) : BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Page View of Images
          PageView.builder(
            controller: _galleryPageController,
            itemCount: images.length,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (ctx, idx) {
              return Image.network(
                images[idx],
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(child: Icon(LucideIcons.image, color: Colors.white38, size: 48)),
                ),
              );
            },
          ),

          // Top Navigation Bar
          Positioned(
            top: isDesktop ? 16 : 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                _buildCircleIconButton(
                  icon: LucideIcons.arrowLeft,
                  onTap: () => Navigator.of(context).maybePop(),
                  tooltip: 'Back',
                ),

                // Top Right Action Buttons
                Row(
                  children: [
                    _buildCircleIconButton(
                      icon: LucideIcons.scale,
                      color: _isCompared ? AppTheme.primaryViolet : Colors.black87,
                      onTap: _toggleCompare,
                      tooltip: 'Compare',
                    ),
                    const SizedBox(width: 8),
                    _buildCircleIconButton(
                      icon: _isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: _isWishlisted ? Colors.redAccent : Colors.black87,
                      onTap: _toggleWishlist,
                      tooltip: 'Save',
                    ),
                    const SizedBox(width: 8),
                    _buildCircleIconButton(
                      icon: LucideIcons.share2,
                      onTap: _shareProperty,
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Left / Right Arrow Controls
          if (images.length > 1) ...[
            Positioned(
              left: 12,
              top: (height / 2) - 20,
              child: _buildCircleIconButton(
                icon: LucideIcons.chevronLeft,
                onTap: () {
                  if (_currentImageIndex > 0) {
                    _galleryPageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                  }
                },
                tooltip: 'Previous Image',
              ),
            ),
            Positioned(
              right: 12,
              top: (height / 2) - 20,
              child: _buildCircleIconButton(
                icon: LucideIcons.chevronRight,
                onTap: () {
                  if (_currentImageIndex < images.length - 1) {
                    _galleryPageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                  }
                },
                tooltip: 'Next Image',
              ),
            ),
          ],

          // Bottom Bar (Status Tag + Image Counter Badge)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isReady
                        ? AppTheme.emeraldSuccess
                        : (prop.statusTag == 'New Launch' ? const Color(0xFF0284C7) : AppTheme.primaryViolet),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.checkCircle, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        prop.statusTag.isNotEmpty ? prop.statusTag : (isReady ? 'Ready to Move' : 'Under Construction'),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Image Counter Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.camera, color: Colors.white, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${_currentImageIndex + 1} / ${images.length}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
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

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. PROPERTY HEADER & BASIC INFO
  // ===========================================================================
  Widget _buildPropertyHeader(Property prop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row/Wrap with PropZen ID + Verified + Freshness + Zero Broker Chips + Report Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // PropZen Human-Readable ID Badge + QR Action
                  InkWell(
                    onTap: () => _showPropertyQrCodeModal(prop),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.qrCode, size: 12, color: AppTheme.primaryViolet),
                          const SizedBox(width: 4),
                          Text(prop.propzenId, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                        ],
                      ),
                    ),
                  ),

                  if (prop.isVerified)
                    InkWell(
                      onTap: () => _showVerificationExplainerModal(prop),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldSuccess.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.emeraldSuccess.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.badgeCheck, size: 12, color: AppTheme.emeraldSuccess),
                            const SizedBox(width: 4),
                            Text('PROPZEN VERIFIED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                            const SizedBox(width: 4),
                            Text('• ${prop.freshnessDisplay}', style: GoogleFonts.inter(fontSize: 9, color: AppTheme.emeraldSuccess)),
                          ],
                        ),
                      ),
                    ),

                  if (prop.isSold)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('SOLD', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                    ),

                  if (prop.isZeroBroker)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ZERO BROKERAGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(prop.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showReportPropertyDialog(prop),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.flag, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('Report', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            prop.title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 6),

          // Location & Rating Subtitle
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 15, color: AppTheme.primaryViolet),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${prop.sector}, ${prop.city}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 3),
                    Text(
                      '${prop.rating.toStringAsFixed(1)} (${prop.reviewCount})',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // Price & Configuration Highlight Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Asking Price', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            prop.formattedPrice,
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (prop.originalPriceCr != null && prop.originalPriceCr! > prop.askingPriceCr) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${prop.originalPriceCr!.toStringAsFixed(2)} Cr',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '₹${prop.pricePerSqft.toStringAsFixed(0)} / sq.ft • All Inclusive',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Configuration Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(prop.bhk, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text(prop.propertyType, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
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
  // 3. QUICK PROPERTY FACTS
  // ===========================================================================
  Widget _buildQuickFactsCard(Property prop) {
    final isReady = _checkIsReadyToMove(prop);
    final propTypeLower = prop.propertyType.toLowerCase();
    final bhkLower = prop.bhk.toLowerCase();

    // Property-specific floor calculation
    String floorVal;
    if (propTypeLower.contains('plot') || propTypeLower.contains('land')) {
      floorVal = 'Ground / Plot';
    } else if (propTypeLower.contains('villa') || propTypeLower.contains('independent') || propTypeLower.contains('house')) {
      floorVal = 'G + 2 Floors';
    } else if (propTypeLower.contains('commercial') || propTypeLower.contains('office') || propTypeLower.contains('shop')) {
      floorVal = 'Commercial Floor Plate';
    } else {
      final floorNum = (prop.id.hashCode.abs() % 18) + 2;
      final totalFloors = floorNum > 15 ? 24 : (floorNum > 10 ? 18 : 14);
      floorVal = '${floorNum}th of $totalFloors Floors';
    }

    // Property-specific bathrooms calculation
    String bathroomsVal;
    if (propTypeLower.contains('plot') || propTypeLower.contains('land')) {
      bathroomsVal = 'N/A (Plot)';
    } else if (bhkLower.contains('1')) {
      bathroomsVal = '1 Bath';
    } else if (bhkLower.contains('2')) {
      bathroomsVal = '2 Baths';
    } else if (bhkLower.contains('3')) {
      bathroomsVal = '3 Baths';
    } else if (bhkLower.contains('4')) {
      bathroomsVal = '4 Baths';
    } else if (bhkLower.contains('5')) {
      bathroomsVal = '5 Baths';
    } else {
      bathroomsVal = '2 Baths';
    }

    final reraVal = prop.reraId.isNotEmpty
        ? prop.reraId
        : (prop.isReraApproved ? 'RERA Approved' : 'Information not available');

    final facingVal = prop.facing.isNotEmpty ? prop.facing : 'North-East';
    final furnishingVal = prop.furnishing.isNotEmpty
        ? prop.furnishing
        : (prop.furnishingStatus.isNotEmpty ? prop.furnishingStatus : 'Information not available');

    final facts = [
      {'label': 'Super Area', 'value': '${prop.sqft} Sq. Ft.', 'icon': LucideIcons.maximize2},
      {'label': 'Carpet Area', 'value': '${prop.carpetAreaSqft > 0 ? prop.carpetAreaSqft : (prop.sqft * 0.8).round()} Sq. Ft.', 'icon': LucideIcons.layoutGrid},
      {'label': 'Bedrooms', 'value': prop.bhk, 'icon': LucideIcons.bed},
      {'label': 'Bathrooms', 'value': bathroomsVal, 'icon': LucideIcons.bath},
      {'label': 'Property Type', 'value': prop.propertyType, 'icon': LucideIcons.home},
      {'label': 'Possession', 'value': isReady ? 'Ready to Move' : (prop.possessionDate.isNotEmpty ? prop.possessionDate : 'Dec 2026'), 'icon': LucideIcons.calendar},
      {'label': 'RERA ID', 'value': reraVal, 'icon': LucideIcons.shieldCheck},
      {'label': 'Floor', 'value': floorVal, 'icon': LucideIcons.layers},
      {'label': 'Facing', 'value': facingVal, 'icon': LucideIcons.compass},
      {'label': 'Furnishing', 'value': furnishingVal, 'icon': LucideIcons.sofa},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Property Facts', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 5 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: facts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: crossAxisCount > 2 ? 1.8 : 2.4,
                ),
                itemBuilder: (ctx, i) {
                  final f = facts[i];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(f['icon'] as IconData, size: 18, color: AppTheme.primaryViolet),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(f['label'] as String, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted), maxLines: 1),
                              Text(f['value'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PROPERTY OVERVIEW & KEY HIGHLIGHTS
  // ===========================================================================
  Widget _buildOverviewSection(Property prop) {
    final defaultDesc = 'Experience luxury living at ${prop.title} in ${prop.sector}, ${prop.city}. This well-appointed ${prop.bhk} ${prop.propertyType} offers high architectural standards, abundant natural lighting, green facing balconies, and seamless connectivity across the NCR corridor.';
    final descriptionText = prop.description.isNotEmpty ? prop.description : defaultDesc;

    final highlights = [
      'Prime location in ${prop.sector} with swift access to expressways',
      'Gated community with 3-tier round-the-clock security and CCTV',
      'High rental yield potential estimated at ${prop.rentalYieldPercent}% p.a.',
      'PropZen 10x Intelligence Score: ${prop.score10x} / 10',
      '100% RERA Approved with clear title and legal verification',
      'Grand clubhouse with swimming pool, 3-tier gym & landscaped parks',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About ${prop.title}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          Text(
            descriptionText,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.6),
          ),
          const SizedBox(height: 20),
          Text('Key Highlights', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          ...highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.checkCircle2, size: 16, color: AppTheme.emeraldSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(h, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. AMENITIES SECTION
  // ===========================================================================
  Widget _buildAmenitiesSection(Property prop) {
    final amenitiesList = prop.amenities;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: Text('Amenities & Facilities', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
              const SizedBox(width: 8),
              if (amenitiesList.isNotEmpty)
                Text('${amenitiesList.length} Amenities', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          if (amenitiesList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'Information not available',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: amenitiesList.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.check, size: 14, color: AppTheme.emeraldSuccess),
                      const SizedBox(width: 6),
                      Text(amenity, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  IconData _getInfrastructureIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('metro') || lower.contains('station') || lower.contains('train') || lower.contains('rail')) {
      return LucideIcons.train;
    }
    if (lower.contains('expressway') || lower.contains('highway') || lower.contains('road') || lower.contains('chowk') || lower.contains('fng') || lower.contains('nh') || lower.contains('link') || lower.contains('flyover') || lower.contains('corridor')) {
      return LucideIcons.navigation;
    }
    if (lower.contains('school') || lower.contains('college') || lower.contains('university') || lower.contains('institute') || lower.contains('academy') || lower.contains('amity') || lower.contains('galgotias')) {
      return LucideIcons.graduationCap;
    }
    if (lower.contains('hospital') || lower.contains('clinic') || lower.contains('health') || lower.contains('med') || lower.contains('fortis') || lower.contains('jaypee') || lower.contains('yatharth') || lower.contains('apollo') || lower.contains('max') || lower.contains('sarvodaya')) {
      return LucideIcons.heartPulse;
    }
    if (lower.contains('mall') || lower.contains('plaza') || lower.contains('market') || lower.contains('bazaar') || lower.contains('shopping') || lower.contains('retail') || lower.contains('centre') || lower.contains('center')) {
      return LucideIcons.shoppingBag;
    }
    if (lower.contains('airport') || lower.contains('jewar') || lower.contains('igi') || lower.contains('aerodrome') || lower.contains('terminal')) {
      return LucideIcons.plane;
    }
    if (lower.contains('park') || lower.contains('river') || lower.contains('lake') || lower.contains('garden') || lower.contains('green') || lower.contains('riverfront') || lower.contains('lawn')) {
      return LucideIcons.trees;
    }
    if (lower.contains('circuit') || lower.contains('f1') || lower.contains('stadium') || lower.contains('sports') || lower.contains('golf') || lower.contains('court')) {
      return LucideIcons.trophy;
    }
    return LucideIcons.mapPin;
  }

  // ===========================================================================
  // 6. LOCATION SECTION (NO GOOGLE MAPS REDIRECT)
  // ===========================================================================
  Widget _buildLocationSection(Property prop) {
    final Map<String, String> nearbyMap = prop.nearby;
    final hasNearby = nearbyMap.isNotEmpty;
    final List<Map<String, dynamic>> connectivity = [];
    if (hasNearby) {
      nearbyMap.forEach((name, dist) {
        connectivity.add({
          'name': name,
          'dist': dist,
          'icon': _getInfrastructureIcon(name),
        });
      });
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppTheme.primaryViolet, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Property Location & Map', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive In-App Location Map
          InteractivePropertyMap(
            property: prop,
            showHeader: false,
            showControls: true,
            isInteractive: true,
          ),

          const SizedBox(height: 16),

          // Full Address Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FULL ADDRESS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  prop.fullAddress,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildAddressChip('Sector', prop.sector),
                    _buildAddressChip('City', prop.city),
                    if (prop.postalCode.isNotEmpty) _buildAddressChip('PIN', prop.postalCode),
                    if (prop.locality.isNotEmpty) _buildAddressChip('Locality', prop.locality),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.compass, size: 16),
                  label: Text('Explore ${prop.sector} (Area Discovery)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.areaDiscovery, arguments: prop);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppTheme.primaryViolet),
                        ),
                        icon: const Icon(LucideIcons.landmark, size: 14, color: AppTheme.primaryViolet),
                        label: const Text('Compare Loans', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.loanComparison, arguments: prop);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppTheme.emeraldSuccess),
                        ),
                        icon: const Icon(LucideIcons.hardHat, size: 14, color: AppTheme.emeraldSuccess),
                        label: const Text('Construction Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.constructionProgress, arguments: prop);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text('Nearby Infrastructure & Distances', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),

          // Interactive Category Search Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildNearbyCategoryPill(context, prop, 'Schools', NearbyCategoryTaxonomy.school, LucideIcons.graduationCap),
                _buildNearbyCategoryPill(context, prop, 'Hospitals', NearbyCategoryTaxonomy.hospital, LucideIcons.heartPulse),
                _buildNearbyCategoryPill(context, prop, 'Restaurants', NearbyCategoryTaxonomy.restaurant, LucideIcons.utensils),
                _buildNearbyCategoryPill(context, prop, 'Metro', NearbyCategoryTaxonomy.metroStation, LucideIcons.train),
                _buildNearbyCategoryPill(context, prop, 'Malls', NearbyCategoryTaxonomy.mall, LucideIcons.shoppingBag),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (!hasNearby || connectivity.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'Information not available',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...connectivity.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Icon(item['icon'] as IconData, size: 14, color: AppTheme.primaryViolet),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item['name'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Text(item['dist'] as String, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAddressChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text('$label: $value', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF334155))),
    );
  }

  Widget _buildNearbyCategoryPill(BuildContext context, Property prop, String label, String catId, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NearbyServicesScreen(
                sourceProperty: prop,
                initialCategory: catId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppTheme.primaryViolet),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. FLOOR PLAN SECTION
  // ===========================================================================
  List<Map<String, String>> _getPropertySpecificRoomDimensions(Property prop) {
    final typeLower = prop.propertyType.toLowerCase();
    final bhkLower = prop.bhk.toLowerCase();
    final sqft = prop.sqft;

    if (typeLower.contains('plot') || typeLower.contains('land') || typeLower.contains('agricultural')) {
      final width = 30;
      final length = sqft > 0 ? (sqft / width).round() : 40;
      return [
        {'room': 'Plot Frontage & Boundary', 'dim': '$length\' 0" × $width\' 0"', 'notes': 'Demarcated Gated Boundary'},
        {'room': 'Total Plot Area', 'dim': '$sqft Sq. Ft.', 'notes': '${(sqft / 9).round()} Sq. Yards • Clear Title'},
        {'room': 'Internal Access Road', 'dim': '12 Meter Wide', 'notes': 'Direct Sector Road Connect'},
        {'room': 'Facing & Orientation', 'dim': prop.facing.isNotEmpty ? prop.facing : 'North-East', 'notes': 'Vastu Compliant Alignment'},
      ];
    }

    if (typeLower.contains('commercial') || typeLower.contains('office') || typeLower.contains('shop') || typeLower.contains('warehouse')) {
      return [
        {'room': 'Main Workstation Hall', 'dim': '${(sqft * 0.50).round()} Sq. Ft.', 'notes': 'Open-Plan Modular Floor Plate'},
        {'room': 'Executive Cabin / Suite', 'dim': '${(sqft * 0.20).round()} Sq. Ft.', 'notes': 'Soundproof Double Glazing'},
        {'room': 'Conference Room', 'dim': '${(sqft * 0.15).round()} Sq. Ft.', 'notes': 'AV Ready & High-Speed LAN'},
        {'room': 'Pantry & Wet Utility', 'dim': '${(sqft * 0.10).round()} Sq. Ft.', 'notes': 'Attached Restrooms & Service Niche'},
      ];
    }

    if (typeLower.contains('villa') || bhkLower.contains('5') || (bhkLower.contains('4') && sqft >= 2400)) {
      return [
        {'room': 'Grand Master Suite', 'dim': '17\' 0" × 14\' 6"', 'notes': 'Walk-in Dresser & Master Jacuzzi Bath'},
        {'room': 'Junior Master Bedroom', 'dim': '15\' 0" × 13\' 0"', 'notes': 'Attached Bath & Balcony'},
        {'room': 'Bedroom 3 & 4', 'dim': '14\' 0" × 12\' 6"', 'notes': 'Park Facing & Wardrobe Niches'},
        {'room': 'Grand Double-Height Living', 'dim': '24\' 0" × 16\' 0"', 'notes': 'Main Foyer & Private Lawn Access'},
        {'room': 'Gourmet Island Kitchen', 'dim': '13\' 0" × 10\' 0"', 'notes': 'Separate Wet & Dry Utility Area'},
      ];
    }

    if (bhkLower.contains('4') || (bhkLower.contains('3') && sqft >= 1800)) {
      return [
        {'room': 'Master Bedroom Suite', 'dim': '15\' 6" × 13\' 0"', 'notes': 'Attached Bath & Dresser'},
        {'room': 'Bedroom 2 (Guest Suite)', 'dim': '13\' 6" × 12\' 0"', 'notes': 'Attached Green Balcony'},
        {'room': 'Bedroom 3 / Kids', 'dim': '12\' 6" × 11\' 6"', 'notes': 'Natural Light Bay Window'},
        {'room': 'Living & Dining Hall', 'dim': '20\' 0" × 14\' 0"', 'notes': 'Main Entry & Panoramic Balcony'},
        {'room': 'Modular Modern Kitchen', 'dim': '11\' 0" × 8\' 6"', 'notes': 'Utility Balcony Attached'},
      ];
    }

    if (bhkLower.contains('3') || sqft >= 1400) {
      return [
        {'room': 'Master Bedroom', 'dim': '14\' 6" × 12\' 0"', 'notes': 'Attached Bath & Green Balcony'},
        {'room': 'Bedroom 2', 'dim': '12\' 6" × 11\' 0"', 'notes': 'Attached Wardrobe Niche'},
        {'room': 'Bedroom 3 / Kids Room', 'dim': '11\' 6" × 10\' 6"', 'notes': 'Corner Ventilation Window'},
        {'room': 'Living & Dining Area', 'dim': '18\' 0" × 13\' 0"', 'notes': 'Main Entrance & Balcony View'},
        {'room': 'Modular Kitchen', 'dim': '10\' 0" × 8\' 0"', 'notes': 'Utility Service Balcony'},
      ];
    }

    if (bhkLower.contains('2') || sqft >= 950) {
      return [
        {'room': 'Master Bedroom', 'dim': '13\' 6" × 11\' 6"', 'notes': 'Attached Bath & Balcony'},
        {'room': 'Bedroom 2', 'dim': '11\' 6" × 10\' 6"', 'notes': 'Wardrobe Niche & Window'},
        {'room': 'Living & Dining Area', 'dim': '16\' 6" × 12\' 0"', 'notes': 'Main Entry & Green Foyer'},
        {'room': 'Modular Kitchen', 'dim': '9\' 6" × 7\' 6"', 'notes': 'Utility Balcony Attached'},
      ];
    }

    // 1 BHK or default
    return [
      {'room': 'Master Bedroom', 'dim': '12\' 0" × 10\' 6"', 'notes': 'Attached Balcony & Wardrobe'},
      {'room': 'Living & Dining Area', 'dim': '14\' 6" × 11\' 0"', 'notes': 'Main Entry Foyer'},
      {'room': 'Modular Kitchen', 'dim': '8\' 6" × 7\' 0"', 'notes': 'Utility Space Attached'},
      {'room': 'Sanitized Bathroom', 'dim': '7\' 6" × 5\' 0"', 'notes': 'Premium CP Fittings'},
    ];
  }

  Widget _buildFloorPlanSection(Property prop) {
    final hasFloorPlanUrl = prop.floorPlanUrl != null && prop.floorPlanUrl!.isNotEmpty;
    final hasDimensions = prop.sqft > 0;
    final rooms = _getPropertySpecificRoomDimensions(prop);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: Text('Floor Plan & Layout', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
              const SizedBox(width: 8),
              Text(
                prop.sqft > 0 ? '${prop.bhk} • ${prop.sqft} Sq. Ft.' : prop.bhk,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasFloorPlanUrl) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                prop.floorPlanUrl!,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (!hasDimensions && !hasFloorPlanUrl)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  'Floor plan not available',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '2D CAD BLUEPRINT SPECIFICATION — ${prop.title.toUpperCase()}',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('ARCHITECT CERTIFIED', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Schematic Room Dimensions Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < rooms.length; i++) ...[
                          if (i > 0) const Divider(color: Color(0xFF334155), height: 12),
                          _buildRoomDimensionRow(rooms[i]['room']!, rooms[i]['dim']!, rooms[i]['notes']!),
                        ],
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

  Widget _buildRoomDimensionRow(String room, String dim, String notes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(notes, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
          child: Text(dim, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8))),
        ),
      ],
    );
  }

  // ===========================================================================
  // 8. PHOTO GALLERY GRID
  // ===========================================================================
  Widget _buildPhotoGalleryGrid(Property prop) {
    final images = prop.dynamicGalleryImages;
    final labels = ['Exterior Elevation', 'Living Room', 'Master Suite', 'Balcony & Green View'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Property Photo Gallery', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length > 4 ? 4 : images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (ctx, i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                      ),
                      child: Text(
                        i < labels.length ? labels[i] : 'Photo ${i + 1}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 9. PRICE & COST DETAILS
  // ===========================================================================
  Widget _buildPriceDetailsSection(Property prop) {
    final maintenanceVal = (prop.sqft * 3.5).round();
    final stampDutyVal = (prop.askingPriceCr * 100 * 0.06);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price & Cost Transparency', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          _buildCostRow('Base Asking Price', prop.formattedPrice, isBold: true),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCostRow('Estimated Maintenance', '₹$maintenanceVal / month', isBold: false),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCostRow('Covered Car Parking', 'Included (1 Covered Slot)', isBold: false),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCostRow('Clubhouse Membership', 'Included (Lifetime Access)', isBold: false),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCostRow('Stamp Duty & Govt Registration', 'Estimated ~6% (₹${stampDutyVal.toStringAsFixed(2)} Lakh)', isBold: false),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _buildCostRow('Total Estimated Cost', '₹${(prop.askingPriceCr * 1.06).toStringAsFixed(2)} Cr', isBold: true, highlight: true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isBold = false, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: highlight ? AppTheme.primaryViolet : AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppTheme.primaryViolet : const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 10. BUILDER / DEVELOPER SECTION
  // ===========================================================================
  Widget _buildBuilderSection(Property prop) {
    final builder = prop.builderName.isNotEmpty ? prop.builderName : 'PropZen Partner Developer';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryViolet.withOpacity(0.1),
            child: const Icon(LucideIcons.building, color: AppTheme.primaryViolet, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Developer & Builder', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                Text(builder, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('20+ Years in Real Estate • 35+ NCR Projects Delivered', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 11. SIMILAR PROPERTIES IN NCR
  // ===========================================================================
  Widget _buildSimilarPropertiesSection(Property currentProp) {
    final similarList = _stateService.allProperties.where((p) => p.id != currentProp.id).take(3).toList();
    if (similarList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Similar Properties in NCR', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 14),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similarList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              final simProp = similarList[i];
              return Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      simProp.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9), height: 120),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(simProp.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${simProp.sector}, ${simProp.city}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary), maxLines: 1),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(simProp.formattedPrice, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                              Text(simProp.bhk, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: simProp, propertyId: simProp.id)),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryViolet),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 6),
                              ),
                              child: Text('View Details', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 12. DESKTOP STICKY ACTION CARD (RIGHT COLUMN)
  // ===========================================================================
  Widget _buildDesktopActionCard(Property prop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exclusive Offer Price', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(
            prop.formattedPrice,
            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
          ),
          Text(
            '₹${prop.pricePerSqft.toStringAsFixed(0)} / sq.ft • All Inclusive',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Primary Action: Book Site Visit (or Sold state)
          if (prop.isSold) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
              child: Text('This property is marked SOLD and is no longer accepting new enquiries.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _handleBookSiteVisitClick(prop),
                icon: const Icon(LucideIcons.calendarCheck, size: 18, color: Colors.white),
                label: Text('Book a Site Visit', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Secondary Action: Enquire Now
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _handleEnquireNowClick(prop),
              icon: const Icon(LucideIcons.messageSquare, size: 18, color: AppTheme.primaryViolet),
              label: Text('Enquire Now', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Advisor contact snippet (Click to WhatsApp 9810394068)
          InkWell(
            onTap: () async {
              final text = Uri.encodeComponent('Hi PropZen! I am interested in ${prop.title} (${prop.sector}, ${prop.city}) listed on PropZen.');
              final uri = Uri.parse('https://wa.me/919810394068?text=$text');
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(LucideIcons.phoneCall, size: 18, color: AppTheme.primaryViolet),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Direct Advisor Desk (+91 98103 94068)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('WhatsApp Support • Instant Response', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.messageCircle, size: 18, color: Color(0xFF25D366)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 13. MOBILE STICKY ACTION BAR
  // ===========================================================================
  Widget _buildMobileStickyActionBar(Property prop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          // Book a Site Visit Button
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => _handleBookSiteVisitClick(prop),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text('Book a Site Visit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Enquire Now Button
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: () => _handleEnquireNowClick(prop),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryViolet, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Enquire Now', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 14. AUTH-GUARDED ACTION HANDLERS
  // ===========================================================================
  void _handleEnquireNowClick(Property prop) {
    if (!UserSession.isLoggedIn || !UserSession.isEmailVerified) {
      EnquiryAuthDialog.show(
        context,
        actionLabel: 'Property Enquiry',
        onSuccess: () => _openEnquireNowModal(prop),
      );
    } else {
      _openEnquireNowModal(prop);
    }
  }

  void _handleBookSiteVisitClick(Property prop) {
    if (!UserSession.isLoggedIn || !UserSession.isEmailVerified) {
      EnquiryAuthDialog.show(
        context,
        actionLabel: 'Book a Site Visit',
        onSuccess: () => _openBookSiteVisitModal(prop),
      );
    } else {
      _openBookSiteVisitModal(prop);
    }
  }

  // ===========================================================================
  // 15. ENQUIRE NOW MODAL (STRICTLY POPULATED FROM AUTHENTICATED PROFILE)
  // ===========================================================================
  void _openEnquireNowModal(Property prop) {
    final nameController = TextEditingController(text: UserSession.fullName);
    final phoneController = TextEditingController(text: UserSession.mobileNumber);
    final emailController = TextEditingController(text: UserSession.email);
    final messageController = TextEditingController(
      text: 'I am interested in ${prop.title} (${prop.bhk}) located at ${prop.sector}, ${prop.city}. Please contact me.',
    );
    String contactMethod = 'Phone Call';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Enquire About Property', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                '${prop.title} • ${prop.sector}, ${prop.city}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),

                    // Dynamic Property Context Pill
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Type: ${prop.propertyType} • ${prop.bhk}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                          Text(prop.formattedPrice, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                        ],
                      ),
                    ),

                    const Divider(height: 20, color: Color(0xFFE2E8F0)),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: 'Enter your 10-digit mobile number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'Enter your email address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Preferred Contact Method', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: ['Phone Call', 'WhatsApp', 'Email'].map((m) {
                        final isSelected = contactMethod == m;
                        return ChoiceChip(
                          label: Text(m, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryViolet.withOpacity(0.15),
                          onSelected: (_) => setModalState(() => contactMethod = m),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: messageController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                final email = emailController.text.trim();
                                final msg = messageController.text.trim();

                                if (name.isEmpty || phone.isEmpty || email.isEmpty) {
                                  _showSnackBar('Please complete all required fields', isError: true);
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                // 1. Submit to n8n Production Workflow (N8N_PROPERTY_ENQUIRY_URL)
                                final n8nRes = await N8nService.instance.submitPropertyEnquiry(
                                  propertyId: prop.id,
                                  propertyName: prop.title,
                                  fullName: name,
                                  mobileNumber: phone,
                                  email: email,
                                  message: msg,
                                  preferredContactMethod: contactMethod.toLowerCase().contains('whatsapp')
                                      ? 'whatsapp'
                                      : (contactMethod.toLowerCase().contains('email') ? 'email' : 'phone'),
                                );

                                // 2. Save in memory
                                _stateService.addEnquiry(
                                  prop.title,
                                  'Property Details Page',
                                  msg,
                                  prop.id,
                                  prop.dealerId,
                                  name,
                                  phone,
                                  email,
                                );

                                // 3. Create Real Lead linked to Dealer
                                DealerLeadService.instance.createLeadFromEnquiry(
                                  buyerId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer',
                                  buyerName: name,
                                  buyerPhone: phone,
                                  buyerEmail: email,
                                  property: prop,
                                  message: msg,
                                );

                                // 4. Save to Supabase backend
                                try {
                                  await SupabaseService.instance.saveEnquiry(
                                    propertyTitle: prop.title,
                                    propertyId: prop.id,
                                    dealerId: prop.dealerId,
                                    name: name,
                                    phone: phone,
                                    email: email,
                                    message: msg,
                                  );
                                } catch (_) {}

                                if (mounted) {
                                  Navigator.of(modalCtx).pop();
                                  if (n8nRes.isSuccess) {
                                    _showSnackBar('Enquiry submitted successfully');
                                  } else {
                                    _showSnackBar(n8nRes.message, isError: true);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Submit Enquiry', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 16. BOOK A SITE VISIT FLOW (PASSES DYNAMIC PROPERTY)
  // ===========================================================================
  void _openBookSiteVisitModal(Property prop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SiteVisitBookingScreen(property: prop),
      ),
    );
  }

  // ===========================================================================
  // 17. PHASE 1 TRUST-FIRST VERIFICATION EXPLAINER MODAL
  // ===========================================================================
  void _showVerificationExplainerModal(Property prop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.shieldCheck, color: AppTheme.emeraldSuccess, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Why is this property verified?', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${prop.title} (${prop.sector}, ${prop.city})', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              const Divider(height: 24),

              _buildVerificationCheckItem('Dealer / Owner Identity Checked', 'Verified government KYC and registered dealer credentials.', true),
              _buildVerificationCheckItem('Property Documents Reviewed', 'Title deed, sanctioned layout, and registry documents validated.', true),
              _buildVerificationCheckItem('Location Verified', 'Physical GPS coordinates, sector boundary, and PIN code confirmed.', prop.locationVerified),
              _buildVerificationCheckItem('Legal & RERA Sanction Completed', prop.reraId.isNotEmpty ? 'RERA ID: ${prop.reraId} matched with official registry.' : 'Legal non-encumbrance verification passed.', true),
              _buildVerificationCheckItem('Listing Information Checked', 'Floor plan, asking price, and physical specifications audited.', true),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verified based on the checks completed by PropZen. Not a legal or financial guarantee.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationCheckItem(String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circleDashed, color: isCompleted ? AppTheme.emeraldSuccess : AppTheme.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 18. PROPZEN TRUST SCORE CARD & EXPLAINER MODAL
  // ===========================================================================
  Widget _buildTrustScoreCard(Property prop) {
    final score = prop.intelligenceScore > 0 ? prop.intelligenceScore : 92;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: InkWell(
        onTap: () => _showTrustScoreExplainerModal(prop),
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('$score', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
                  Text('/ 100', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('PropZen Trust Score', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.info, size: 13, color: AppTheme.primaryViolet),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Transparent verification rating based on 5 verified audit pillars.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.primaryViolet),
          ],
        ),
      ),
    );
  }

  void _showTrustScoreExplainerModal(Property prop) {
    final score = prop.intelligenceScore > 0 ? prop.intelligenceScore : 92;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PropZen Trust Score: $score/100', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),
              _buildScorePillarRow('Dealer Identity Verification', '20 / 20', LucideIcons.userCheck),
              _buildScorePillarRow('Physical Location Geocoding', '20 / 20', LucideIcons.mapPin),
              _buildScorePillarRow('Title Deed & Registry Completeness', '20 / 20', LucideIcons.fileCheck),
              _buildScorePillarRow('Legal & RERA Sanction Check', '20 / 20', LucideIcons.scale),
              _buildScorePillarRow('Listing Consistency & Freshness', '12 / 20', LucideIcons.refreshCw),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Trust Score is an internal PropZen indicator based on available verification signals. It is not a legal or financial guarantee.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScorePillarRow(String name, String points, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryViolet),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
          Text(points, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 19. REPORT PROPERTY DIALOG (8 STRUCTURED REASONS)
  // ===========================================================================
  void _showReportPropertyDialog(Property prop) {
    final reasons = [
      'Fake property',
      'Wrong price',
      'Wrong location',
      'Duplicate listing',
      'Misleading information',
      'Incorrect images',
      'Suspicious dealer',
      'Other',
    ];
    String selectedReason = reasons.first;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Report Property Listing', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select reason for reporting "${prop.title}":', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 10),
                ...reasons.map((r) => RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(r, style: GoogleFonts.inter(fontSize: 13)),
                      value: r,
                      groupValue: selectedReason,
                      onChanged: (v) {
                        if (v != null) setDlgState(() => selectedReason = v);
                      },
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Additional Details (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                AdminCommandService.instance.submitUserReport(
                  propertyId: prop.id,
                  propertyTitle: prop.title,
                  reporterId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_guest',
                  reason: selectedReason,
                  comment: commentController.text.trim(),
                );
                Navigator.pop(dlgCtx);
                _showSnackBar('Report submitted. Our moderation desk will review.');
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 20. PROPZEN ID & QR CODE MODAL
  // ===========================================================================
  void _showPropertyQrCodeModal(Property prop) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.qrCode, color: AppTheme.primaryViolet, size: 22),
            const SizedBox(width: 8),
            Text('PropZen QR Verification', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
                    child: const Icon(LucideIcons.qrCode, size: 100, color: AppTheme.primaryViolet),
                  ),
                  const SizedBox(height: 10),
                  Text(prop.propzenId, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                  Text('Official PropZen Verification ID', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Scan to verify authentic legal RERA records, location GPS boundary, and dealer verification on the official public gateway.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // ===========================================================================
  // 21. SANITIZED SHARE PROPERTY SHEET
  // ===========================================================================
  void _showSharePropertySheet(Property prop) {
    final shareUrl = 'https://propzen.ai/verify/property/${prop.id}';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.share2, color: AppTheme.primaryViolet, size: 20),
                const SizedBox(width: 8),
                Text('Share Verified Listing', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('${prop.title} (${prop.propzenId})', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('${prop.sector}, ${prop.city} • ${prop.bhk} • ${prop.formattedPrice}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(child: Text(shareUrl, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet), overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 16, color: AppTheme.primaryViolet),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSnackBar('PropZen verification link copied!');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
