import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/everyday_utility_models.dart';
import '../services/everyday_utility_service.dart';

class ExploreIndiaScreen extends StatefulWidget {
  final String? initialCategory;

  const ExploreIndiaScreen({super.key, this.initialCategory});

  @override
  State<ExploreIndiaScreen> createState() => _ExploreIndiaScreenState();
}

class _ExploreIndiaScreenState extends State<ExploreIndiaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EverydayUtilityService _service = EverydayUtilityService.instance;

  String _selectedCategory = 'All';
  String _originCity = 'Delhi NCR';

  final List<String> _categories = [
    'All',
    'Beach',
    'Mountains',
    'Heritage',
    'Luxury & Heritage',
    'Wellness & Backwaters',
    'Spiritual & Adventure',
    'Wildlife',
  ];

  final List<String> _originCities = [
    'Delhi NCR',
    'Mumbai / Pune',
    'Bangalore',
    'Jaipur',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TravelDestinationModel> get _filteredDestinations {
    if (_selectedCategory == 'All') return _service.verifiedDestinations;
    return _service.verifiedDestinations.where((d) => d.category.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
  }

  void _showDestinationDetailModal(TravelDestinationModel d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image & Title
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          d.imageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(height: 220, color: const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              Text('${d.state} • ${d.category}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(d.startingBudget, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF059669))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(d.overview, style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF334155), height: 1.5)),
                      const SizedBox(height: 20),

                      // Connectivity
                      _buildSectionTitle('How to Reach'),
                      const SizedBox(height: 8),
                      _buildInfoRow(LucideIcons.plane, 'Nearest Airport', d.nearestAirport),
                      _buildInfoRow(LucideIcons.train, 'Nearest Railway', d.nearestRailway),
                      _buildInfoRow(LucideIcons.navigation, 'Road Connectivity', d.roadConnectivity),
                      const SizedBox(height: 20),

                      // Top Attractions
                      _buildSectionTitle('Top Attractions'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: d.topAttractions.map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                              child: Text(a, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                            )).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Itineraries
                      _buildSectionTitle('Curated Itineraries'),
                      const SizedBox(height: 8),
                      Text('2-Day Weekend Escape:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                      const SizedBox(height: 4),
                      ...d.twoDayItinerary.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                                Expanded(child: Text(step, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569)))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                      Text('3-Day Leisure Tour:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                      const SizedBox(height: 4),
                      ...d.threeDayItinerary.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                                Expanded(child: Text(step, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569)))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),

                      // Best Time
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 10),
                            Text('Best Time to Visit: ${d.bestTime}', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF1E40AF))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)));
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          Text('$label: ', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF0F172A)))),
        ],
      ),
    );
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
          'Explore India — Travel & Lifestyle',
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
                Tab(text: 'Premium Destinations'),
                Tab(text: 'Weekend Getaways'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDestinationsTab(),
          _buildWeekendGetawaysTab(),
        ],
      ),
    );
  }

  Widget _buildDestinationsTab() {
    final destinations = _filteredDestinations;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF475569))),
                        selected: isSelected,
                        selectedColor: const Color(0xFF7C3AED),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0))),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Handpicked Premium Destinations (${destinations.length})',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore India’s most iconic beaches, mountain retreats, royal palaces, and tranquil backwaters.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              // Destination Cards Grid
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: destinations.map((d) => _buildDestinationCard(d)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(TravelDestinationModel d) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Stack(
              children: [
                Image.network(
                  d.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(height: 160, color: const Color(0xFF0F172A)),
                ),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6)),
                    child: Text(d.category, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(d.name, style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(d.startingBudget, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF6EE7B7))),
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
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 6),
                    Text(d.state, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(LucideIcons.calendar, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(d.bestTime, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(d.overview, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showDestinationDetailModal(d),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Explore Itinerary & Guide', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendGetawaysTab() {
    final getaways = _service.getWeekendGetawaysForCity(_originCity);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origin Selector
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    const Icon(LucideIcons.compass, color: Color(0xFF7C3AED), size: 22),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Travelling From:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _originCity,
                            items: _originCities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _originCity = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('Weekend Trips from $_originCity', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Top destinations within a comfortable 2 to 6 hour scenic drive or express rail ride.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 18),

              ...getaways.map((g) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            g.imageUrl,
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(width: 120, height: 90, color: const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(g.destination, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text('${g.driveTimeHours} hrs drive', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('${g.distanceKm} km via ${g.bestTransport}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                              const SizedBox(height: 6),
                              Text(g.highlights, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155))),
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
