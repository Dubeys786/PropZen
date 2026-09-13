import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/area_discovery_model.dart';
import '../models/property.dart';
import '../services/area_discovery_service.dart';
import '../services/property_state_service.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

class AreaDiscoveryScreen extends StatefulWidget {
  final Property? sourceProperty;
  final String? pincode;
  final String? locality;

  const AreaDiscoveryScreen({
    super.key,
    this.sourceProperty,
    this.pincode,
    this.locality,
  });

  @override
  State<AreaDiscoveryScreen> createState() => _AreaDiscoveryScreenState();
}

class _AreaDiscoveryScreenState extends State<AreaDiscoveryScreen> with SingleTickerProviderStateMixin {
  final AreaDiscoveryService _discoveryService = AreaDiscoveryService.instance;
  late TabController _tabController;
  AreaProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAreaProfile();
  }

  Future<void> _loadAreaProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      AreaProfileModel profile;
      if (widget.sourceProperty != null) {
        profile = await _discoveryService.resolveAreaForProperty(widget.sourceProperty!);
      } else {
        final mockProp = Property(
          id: 'prop_temp',
          title: 'Area Inquiry',
          sector: widget.locality ?? 'Sector 150',
          city: 'Noida',
          postalCode: widget.pincode ?? '201310',
          askingPriceCr: 1.5,
          sqft: 1600,
          imageUrl: '',
          propertyType: 'Apartment',
          bhk: '3 BHK',
        );
        profile = await _discoveryService.resolveAreaForProperty(mockProp);
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Area information is temporarily unavailable. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Preparing your area guide...', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryViolet),
              const SizedBox(height: 16),
              Text('Resolving verified PIN code & area intelligence...', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Area Discovery', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textPrimary)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle, size: 48, color: AppTheme.amberWarning),
                const SizedBox(height: 16),
                Text('Area information is temporarily unavailable.', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Information for this area is being prepared from official records.', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                  icon: const Icon(LucideIcons.refreshCw, size: 16, color: Colors.white),
                  label: const Text('Retry Resolution', style: TextStyle(color: Colors.white)),
                  onPressed: _loadAreaProfile,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _profile!;
    final matchingProperties = PropertyStateService.instance.allProperties
        .where((prop) =>
            prop.sector.toLowerCase().contains(p.locality.toLowerCase()) ||
            prop.postalCode.contains(p.pincode) ||
            prop.city.toLowerCase().contains(p.city.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.compass, size: 14, color: AppTheme.primaryViolet),
                  const SizedBox(width: 4),
                  Text('AUTOMATIC AREA DISCOVERY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20, color: AppTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Area Discovery link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Breadcrumbs
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.home),
                  child: Text('Home', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryViolet)),
                ),
                Text('  /  ', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                Text(p.city, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                Text('  /  ', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                Text(p.locality, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Hero Header Card with PIN Code and Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.cardWhite, AppTheme.surfaceSubtle],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Explore ${p.locality}',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 14, color: AppTheme.primaryViolet),
                            const SizedBox(width: 4),
                            Text('PIN: ${p.pincode}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${p.city}, ${p.state} • ${p.country}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldSuccess.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.emeraldSuccess),
                        const SizedBox(width: 6),
                        Text(
                          'This is the area around the property you selected.',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.emeraldSuccess),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Key Stats Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderStat('Avg Rate', '₹${p.marketSnapshot.avgPriceSqft.toStringAsFixed(0)}/sqft', LucideIcons.indianRupee),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeaderStat('6M Trend', '+${p.marketSnapshot.appreciation6mPercent}%', LucideIcons.trendingUp, isSuccess: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildHeaderStat('Active Listings', '${matchingProperties.length}', LucideIcons.building),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Tab Bar for Structured Exploration (5 Tabs)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryViolet,
                indicatorWeight: 3,
                isScrollable: true,
                labelColor: AppTheme.primaryViolet,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(icon: Icon(LucideIcons.landmark, size: 16), text: 'History'),
                  Tab(icon: Icon(LucideIcons.map, size: 16), text: 'Landmarks'),
                  Tab(icon: Icon(LucideIcons.star, size: 16), text: 'Representatives'),
                  Tab(icon: Icon(LucideIcons.school, size: 16), text: 'Amenities'),
                  Tab(icon: Icon(LucideIcons.lineChart, size: 16), text: 'Market'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar Views
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(p),
                  _buildLandmarksTab(p),
                  _buildPublicFiguresTab(p),
                  _buildAmenitiesTab(p),
                  _buildMarketTab(p),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Other PropZen Properties in this Area
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Properties in ${p.locality}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('${matchingProperties.length} verified listings available in PIN ${p.pincode}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(LucideIcons.search, size: 14),
                  label: const Text('View All', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.search, arguments: {'query': p.locality});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...matchingProperties.take(3).map((prop) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        prop.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppTheme.surfaceSubtle),
                      ),
                    ),
                    title: Text(prop.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    subtitle: Text('${prop.bhk} • ₹${prop.askingPriceCr} Cr • ${prop.sector}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.propertyDetails, arguments: prop);
                      },
                      child: const Text('View', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                )),

            const SizedBox(height: 20),

            // Back & Filter Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: const Text('Back to Property'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(LucideIcons.listFilter, size: 16),
                    label: const Text('View Properties in This Area'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.search, arguments: {'query': p.locality});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value, IconData icon, {bool isSuccess = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: isSuccess ? AppTheme.emeraldSuccess : AppTheme.primaryViolet),
              const SizedBox(width: 4),
              Text(title, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: isSuccess ? AppTheme.emeraldSuccess : AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 🏛️ History Tab
  Widget _buildHistoryTab(AreaProfileModel p) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text(p.historySummary, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
        const SizedBox(height: 16),
        Text('Development Timeline & Milestones', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        ...p.historyMilestones.map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(m.year, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(m.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Source: ${m.source}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // 🗺️ Landmarks Tab
  Widget _buildLandmarksTab(AreaProfileModel p) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Key Monuments, Parks & Public Facilities in ${p.locality}', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        ...p.landmarks.map((lm) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
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
                        child: Text(lm.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${lm.distanceKm} km', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(lm.category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Text(lm.description, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle, size: 12, color: AppTheme.emeraldSuccess),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('Significance: ${lm.significance} (${lm.source})', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                      ),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ⭐ Public Figures Tab (Strict Privacy Safeguards)
  Widget _buildPublicFiguresTab(AreaProfileModel p) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 16, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verified public representatives & notable figures with documented public constituency ties. No private residences or contact details are tracked.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...p.publicFigures.map((fig) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryViolet.withOpacity(0.1),
                    backgroundImage: fig.photoUrl != null ? NetworkImage(fig.photoUrl!) : null,
                    child: fig.photoUrl == null ? const Icon(LucideIcons.user, color: AppTheme.primaryViolet, size: 24) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fig.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(fig.category.displayName, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(fig.designation, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(fig.publicAssociation, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 6),
                        Text(fig.shortBio, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(LucideIcons.badgeCheck, size: 12, color: AppTheme.emeraldSuccess),
                            const SizedBox(width: 4),
                            Text('Source: ${fig.source}', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.emeraldSuccess)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // 🏫 Amenities Tab
  Widget _buildAmenitiesTab(AreaProfileModel p) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: p.amenities.map((item) {
        IconData icon;
        switch (item.category) {
          case AmenityCategory.education:
            icon = LucideIcons.graduationCap;
            break;
          case AmenityCategory.healthcare:
            icon = LucideIcons.heartPulse;
            break;
          case AmenityCategory.shopping:
            icon = LucideIcons.shoppingBag;
            break;
          case AmenityCategory.connectivity:
            icon = LucideIcons.navigation;
            break;
          case AmenityCategory.publicInfrastructure:
            icon = LucideIcons.building;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryViolet.withOpacity(0.08),
              child: Icon(icon, color: AppTheme.primaryViolet, size: 18),
            ),
            title: Text(item.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            subtitle: Text('${item.typeDescription} • ${item.category.displayName}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.distanceKm} km', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                if (item.rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, size: 10, color: Color(0xFFD97706)),
                      const SizedBox(width: 2),
                      Text('${item.rating}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    ],
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 📊 Market Tab
  Widget _buildMarketTab(AreaProfileModel p) {
    final m = p.marketSnapshot;
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Capital & Rental Benchmarks', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Average Capital Value', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('₹${m.avgPriceSqft.toStringAsFixed(0)} / sq.ft', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Price Range', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('₹${m.priceRangeMin.toStringAsFixed(0)} - ₹${m.priceRangeMax.toStringAsFixed(0)}/sqft', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Monthly Rental', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  Text('₹${(m.rentalRangeMinMonthly / 1000).toStringAsFixed(0)}k - ₹${(m.rentalRangeMaxMonthly / 1000).toStringAsFixed(0)}k', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryViolet.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.info, size: 16, color: AppTheme.primaryViolet),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimated market trend based on Apify market benchmarks and verified registrar transactions. Past appreciation is not a guarantee of future returns.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Market Dynamics & Infrastructure Growth', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(m.trendSummary, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.5)),
      ],
    );
  }
}
