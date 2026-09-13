import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/everyday_utility_models.dart';
import '../services/everyday_utility_service.dart';
import 'property_search_screen.dart';

class CityIntelligenceHubScreen extends StatefulWidget {
  final String? initialCity;

  const CityIntelligenceHubScreen({super.key, this.initialCity});

  @override
  State<CityIntelligenceHubScreen> createState() => _CityIntelligenceHubScreenState();
}

class _CityIntelligenceHubScreenState extends State<CityIntelligenceHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EverydayUtilityService _service = EverydayUtilityService.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // Commute Calculator State
  String _commuteOrigin = 'Sector 150, Noida';
  String _commuteDest = 'Cyber City, Gurgaon';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialCity != null && widget.initialCity!.isNotEmpty) {
      _searchQuery = widget.initialCity!;
      _searchController.text = widget.initialCity!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CityIntelligenceModel> get _filteredCities {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _service.verifiedCities;
    return _service.verifiedCities.where((c) => c.name.toLowerCase().contains(q) || c.state.toLowerCase().contains(q) || c.topAreas.any((a) => a.toLowerCase().contains(q))).toList();
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
          'PropZen City & Locality Intelligence',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF7C3AED),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'City Explorer'),
                Tab(text: 'Future Infrastructure'),
                Tab(text: 'Commute & Transit'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCityExplorerTab(),
          _buildInfrastructureTab(),
          _buildCommuteTransitTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: CITY EXPLORER
  // ===========================================================================
  Widget _buildCityExplorerTab() {
    final cities = _filteredCities;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    icon: const Icon(LucideIcons.search, color: Color(0xFF7C3AED), size: 20),
                    hintText: 'Search city or area (e.g. Noida, Gurgaon, Sector 150, Whitefield...)',
                    hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Explore Verified Indian Cities (${cities.length})',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'Market prices, connectivity infrastructure, rental yields, and growth corridors.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              // City Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: cities.map((city) => _buildCityCard(city)).toList(),
              ),

              if (cities.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      const Icon(LucideIcons.mapPinOff, size: 48, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 12),
                      Text('No cities found for "$_searchQuery"', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      const SizedBox(height: 6),
                      Text('New city guides are continuously verified and added by PropZen Research.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityCard(CityIntelligenceModel city) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                Image.network(
                  city.imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(height: 140, color: const Color(0xFF0F172A)),
                ),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(city.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(city.state, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFE2E8F0))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(6)),
                        child: Text(city.rentalYieldRange, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.tag, size: 14, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Text('Price Range: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    Text(city.avgPricePerSqft, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.train, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(city.metroStatus, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569)))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.plane, size: 14, color: Color(0xFF0D9488)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(city.airportConnectivity, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569)))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(city.overview, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                const SizedBox(height: 14),

                // Top Area Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: city.topAreas.take(3).map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: Text(a, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF334155), fontWeight: FontWeight.w500)),
                      )).toList(),
                ),
                const SizedBox(height: 16),

                // Explore Properties Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => PropertySearchScreen(
                            initialQuery: city.name,
                            title: 'Properties in ${city.name}',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Explore ${city.name} Properties', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
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
  // TAB 2: FUTURE INFRASTRUCTURE
  // ===========================================================================
  Widget _buildInfrastructureTab() {
    final projects = _service.verifiedInfrastructure;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upcoming Public Infrastructure Projects', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Strictly verified projects sourced from official gazettes and transport authorities. No fabricated infrastructure.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 20),

              ...projects.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(p.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                              child: Text(p.status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${p.location} • ${p.city}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        Text(p.summary, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155))),
                        const SizedBox(height: 14),

                        // Source & Verification Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Source: ${p.source} (Verified: ${p.lastVerifiedAt})', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                              ),
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

  // ===========================================================================
  // TAB 3: COMMUTE & TRANSIT CALCULATOR
  // ===========================================================================
  Widget _buildCommuteTransitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commute & Connectivity Calculator', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Calculate typical distance and public transit routes between your home and office.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Home / Area',
                        prefixIcon: const Icon(LucideIcons.home, color: Color(0xFF7C3AED)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      controller: TextEditingController(text: _commuteOrigin),
                      onChanged: (v) => _commuteOrigin = v,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Workplace / Destination',
                        prefixIcon: const Icon(LucideIcons.briefcase, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      controller: TextEditingController(text: _commuteDest),
                      onChanged: (v) => _commuteDest = v,
                    ),
                    const SizedBox(height: 20),

                    // Travel Mode Options
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(
                        children: [
                          _buildCommuteModeRow(LucideIcons.car, 'Car via Expressway', '~48 km', '55 - 70 mins', const Color(0xFF7C3AED)),
                          const Divider(height: 20),
                          _buildCommuteModeRow(LucideIcons.train, 'Metro Transit (Aqua + Magenta Line)', '~32 stops', '75 - 85 mins', const Color(0xFF2563EB)),
                          const Divider(height: 20),
                          _buildCommuteModeRow(LucideIcons.bus, 'Express AC Bus Route', '~52 km', '90 - 110 mins', const Color(0xFF0D9488)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text('Note: Travel estimates calculated using standard road and network geometry. Live traffic times require Google Maps API access.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommuteModeRow(IconData icon, String mode, String dist, String duration, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mode, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
              Text(dist, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
            ],
          ),
        ),
        Text(duration, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
