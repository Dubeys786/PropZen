import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/dealer.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'dealer_profile_screen.dart';
import 'dealer_dashboard_screen.dart';

class DealersDirectoryScreen extends StatefulWidget {
  const DealersDirectoryScreen({super.key});

  @override
  State<DealersDirectoryScreen> createState() => _DealersDirectoryScreenState();
}

class _DealersDirectoryScreenState extends State<DealersDirectoryScreen> {
  String searchQuery = '';
  String selectedCity = 'All';
  String selectedSpecialty = 'All';
  bool onlyVerified = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredDealers = Dealer.sampleDealers.where((d) {
      final qLower = searchQuery.toLowerCase();
      final matchesQuery = searchQuery.isEmpty ||
          '${d.name} ${d.agency} ${d.location} ${d.city} ${d.specialization}'.toLowerCase().contains(qLower);

      if (!matchesQuery) return false;
      if (selectedCity != 'All' && !d.city.toLowerCase().contains(selectedCity.toLowerCase())) return false;
      if (onlyVerified && !d.isVerified) return false;

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Authorized Dealers Directory', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Dealer Dashboard',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const DealerDashboardScreen()));
            },
            icon: const Icon(LucideIcons.layoutDashboard, color: Color(0xFFD32F2F)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card
            GlassCard(
              borderColor: AppTheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.badgeCheck, color: Color(0xFFD32F2F), size: 24),
                          const SizedBox(width: 8),
                          Text('RERA Authorized Dealers', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const DealerDashboardScreen()));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFFD32F2F), borderRadius: BorderRadius.circular(12)),
                          child: Text('Dealer Portal 📊', style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Verified real estate advisors with audited deal registries across Noida, Gurgaon & Delhi NCR.', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar & Filters (Req #14)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, size: 16, color: Color(0xFFD32F2F)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search Dealer by Name, City, Sector...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // City Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Noida', 'Gurgaon', 'Greater Noida'].map((city) {
                  final isSel = selectedCity == city;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(city),
                      selected: isSel,
                      selectedColor: const Color(0xFFD32F2F),
                      labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                      onSelected: (val) {
                        if (val) setState(() => selectedCity = city);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Dealer Cards List (Req #13)
            ...filteredDealers.map((dealer) {
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: Image.network(
                              dealer.photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800, child: const Icon(LucideIcons.user, color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(dealer.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.checkCircle2, color: Colors.blue, size: 14),
                                ],
                              ),
                              Text(dealer.agency, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                              const SizedBox(height: 2),
                              Text('${dealer.experienceYears} Yrs Experience • ${dealer.location}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                                  const SizedBox(width: 3),
                                  Text('${dealer.rating} (${dealer.reviewCount} Reviews)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Text('${dealer.activeListingsCount} Active Deals', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dealer.reraNumber, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => DealerProfileScreen(dealer: dealer)));
                          },
                          icon: const Icon(LucideIcons.user, size: 12, color: Colors.white),
                          label: Text('View Profile', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
