import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/reporter_models.dart';
import '../theme/app_theme.dart';
import 'reporter_studio_screen.dart';

class ReporterFeedScreen extends StatefulWidget {
  const ReporterFeedScreen({super.key});

  @override
  State<ReporterFeedScreen> createState() => _ReporterFeedScreenState();
}

class _ReporterFeedScreenState extends State<ReporterFeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _isPlaying = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Noida Updates',
    'Greater Noida',
    'Real-Estate News',
    'Infrastructure',
    'Government Announcements',
  ];

  final List<ReporterVideoModel> _videos = [
    ReporterVideoModel(
      id: 'VID-001',
      title: 'Noida International Airport Jewar — Runway Final Testing',
      description: 'DGCA conducts final calibration flights ahead of commercial operations. Noida Expressway corridor property demand surges 14%.',
      category: 'Infrastructure',
      videoUrl: 'https://propzen.ai/videos/jewar_testing.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      script: const ReporterScriptModel(
        headline: 'Jewar Airport Operational Countdown Begins',
        shortScript30s: 'Final runway calibration flights underway at Jewar Airport. Sector 150 & Yamuna Expressway witness record investor inquiries.',
        fullScript60s: 'Final calibration flights conducted by DGCA at Noida International Airport Jewar. Connectivity with Aqua Line metro will reduce travel times by 40 minutes.',
        caption: 'Jewar Airport Runway Testing #NoidaRealEstate #JewarAirport',
        description: 'Infrastructure update on Noida International Airport.',
      ),
      sourceInformation: 'Ministry of Civil Aviation & YEIDA Press Release',
      viewCount: 14200,
      shareCount: 890,
      saveCount: 430,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now(),
    ),
    ReporterVideoModel(
      id: 'VID-002',
      title: 'UP RERA Issues New Fast-Track Delivery Directives',
      description: 'Strict escrow monitoring enforced across Greater Noida West projects ensuring on-time possession for 22,000 homebuyers.',
      category: 'Government Announcements',
      videoUrl: 'https://propzen.ai/videos/rera_update.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=800&q=80',
      script: const ReporterScriptModel(
        headline: 'UP RERA Fast-Track Delivery Mandate',
        shortScript30s: 'UP RERA strengthens escrow audits to guarantee builder deliveries in Greater Noida West.',
        fullScript60s: 'Regulatory authority mandates 70% escrow compliance with quarterly milestone verifications.',
        caption: 'UP RERA Buyer Protection #HomeBuyerRights #UPRERA',
        description: 'Regulatory milestone report.',
      ),
      sourceInformation: 'UP RERA Official Bulletin 2026',
      viewCount: 9800,
      shareCount: 512,
      saveCount: 310,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      updatedAt: DateTime.now(),
    ),
    ReporterVideoModel(
      id: 'VID-003',
      title: 'Sector 150 Low-Density Green Corridor Market Analysis',
      description: 'Why Sector 150 is retaining its status as NCR’s premier sports-centric luxury residential hub.',
      category: 'Real-Estate News',
      videoUrl: 'https://propzen.ai/videos/sec150_trends.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
      script: const ReporterScriptModel(
        headline: 'Sector 150 Luxury Living Report',
        shortScript30s: '80% green cover and direct expressway access drive 12% YoY appreciation in Sector 150.',
        fullScript60s: 'Analysis of luxury residential demand in Sector 150 sports city.',
        caption: 'Sector 150 Noida Luxury Real Estate #PropZenReporter',
        description: 'Locality intelligence overview.',
      ),
      sourceInformation: 'PropZen Market Research Division',
      viewCount: 11400,
      shareCount: 640,
      saveCount: 520,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<ReporterVideoModel> get _filteredVideos {
    if (_selectedCategory == 'All') return _videos;
    return _videos.where((v) => v.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredVideos;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Reels View
          if (filtered.isEmpty)
            Center(
              child: Text(
                'No videos in this category yet.',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: filtered.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentIndex = idx;
                  _isPlaying = true;
                });
              },
              itemBuilder: (context, idx) {
                final video = filtered[idx];
                return _buildReelItem(video);
              },
            ),

          // Top Overlay: Header & Category Pills
          Positioned(
            top: 44,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Icon(LucideIcons.video, color: AppTheme.coralDanger, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'PropZen Reporter',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(LucideIcons.mic, size: 14, color: Colors.white),
                      label: const Text('Admin Studio', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReporterStudioScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final isSel = _selectedCategory == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.white70)),
                          selected: isSel,
                          selectedColor: AppTheme.primaryViolet,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          onSelected: (_) => setState(() => _selectedCategory = c),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelItem(ReporterVideoModel video) {
    return GestureDetector(
      onTap: () => setState(() => _isPlaying = !_isPlaying),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Media
          Image.network(
            video.thumbnailUrl,
            fit: BoxFit.cover,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.85],
              ),
            ),
          ),

          // Play/Pause Center Indicator if paused
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(LucideIcons.play, color: Colors.white, size: 40),
              ),
            ),

          // Right Side Action Bar
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                _buildActionIcon(
                  _isMuted ? LucideIcons.volumeX : LucideIcons.volume2,
                  _isMuted ? 'Muted' : 'Audio',
                  () => setState(() => _isMuted = !_isMuted),
                ),
                const SizedBox(height: 20),
                _buildActionIcon(LucideIcons.eye, '${video.viewCount}', () {}),
                const SizedBox(height: 20),
                _buildActionIcon(LucideIcons.share2, '${video.shareCount}', () {}),
                const SizedBox(height: 20),
                _buildActionIcon(LucideIcons.bookmark, '${video.saveCount}', () {}),
              ],
            ),
          ),

          // Bottom Left Content Details
          Positioned(
            left: 20,
            bottom: 40,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.coralDanger,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    video.category.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.title,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  video.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 14, color: AppTheme.emeraldSuccess),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Verified Source: ${video.sourceInformation}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white60),
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

  Widget _buildActionIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
