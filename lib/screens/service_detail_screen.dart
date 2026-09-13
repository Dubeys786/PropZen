import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/enquiry_auth_dialog.dart';
import '../services/n8n_service.dart';
import 'user_profile_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> features;
  final String startingPrice;
  final String estimatedTime;
  final String imageUrl;

  const ServiceDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.features,
    required this.startingPrice,
    required this.estimatedTime,
    required this.imageUrl,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final List<Map<String, String>> _forumPosts = [
    {
      'author': 'Amit Verma (Sector 150 Buyer)',
      'time': '2 hours ago',
      'title': 'Best interior designer for 3BHK flat in Sector 150 Noida?',
      'content': 'We recently bought a 3BHK in Godrej Tropical Isle. Looking for recommendations on turnkey modular kitchen and ceiling work. Any feedback on PropZen interior team?',
      'likes': '24',
      'replies': '8 replies',
    },
    {
      'author': 'Priya Sundaram (Gurgaon)',
      'time': '1 day ago',
      'title': 'Document Verification turnaround time for Sohna Road plot?',
      'content': 'Is 30-year title check sufficient for RERA plots near Golf Course Extension? Thanks PropZen legal team for clearing encumbrance certificate status.',
      'likes': '42',
      'replies': '15 replies',
    },
    {
      'author': 'Vikramaditya S. (Greater Noida)',
      'time': '3 days ago',
      'title': 'Vastu orientation feedback for North-East facing plot',
      'content': 'Consulted PropZen Vastu expert before laying foundation in Sector 62. The non-demolition remedies for kitchen placement were super helpful.',
      'likes': '56',
      'replies': '19 replies',
    },
  ];

  final TextEditingController _newPostController = TextEditingController();

  void _onBookService() {
    EnquiryAuthDialog.show(
      context,
      actionLabel: 'Book ${widget.title} Consultation',
      onSuccess: () async {
        final name = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'PropZen Member';
        final phone = UserSession.mobileNumber.isNotEmpty ? UserSession.mobileNumber : '9810394068';
        final email = UserSession.email.isNotEmpty ? UserSession.email : 'member@propzen.ai';

        final n8nRes = await N8nService.instance.requestService(
          serviceId: widget.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_'),
          serviceName: widget.title,
          category: widget.category,
          fullName: name,
          mobileNumber: phone,
          email: email,
          notes: 'Consultation requested for ${widget.title} (${widget.startingPrice}).',
          params: {
            'startingPrice': widget.startingPrice,
            'estimatedTime': widget.estimatedTime,
            'features': widget.features,
          },
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(n8nRes.isSuccess
                ? '🎉 Consultation Request Submitted for ${widget.title}! Our specialist will call you shortly.'
                : n8nRes.message),
            backgroundColor: n8nRes.isSuccess ? AppTheme.emeraldSuccess : AppTheme.coralDanger,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isForum = widget.title.contains('Forum') || widget.category == 'COMMUNITY';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.icon, size: 20, color: widget.accentColor),
            const SizedBox(width: 8),
            Text(widget.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Tagline Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.accentColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.accentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.category.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 14, color: widget.accentColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.estimatedTime,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.description,
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.lightOnSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (isForum) ...[
              // COMMUNITY DISCUSSION FORUM VIEW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💬 Active Community Discussions',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showNewPostModal(context),
                    icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                    label: Text('New Topic', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _forumPosts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final post = _forumPosts[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(post['author']![0], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                ),
                                const SizedBox(width: 8),
                                Text(post['author']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(post['time']!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(post['title']!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface)),
                        const SizedBox(height: 4),
                        Text(post['content']!, style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppTheme.darkOnSurfaceVariant : AppTheme.lightOnSurfaceVariant, height: 1.4)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(LucideIcons.thumbsUp, size: 14, color: Colors.indigo),
                            const SizedBox(width: 4),
                            Text('${post['likes']} Helpful', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo)),
                            const SizedBox(width: 16),
                            Icon(LucideIcons.messageCircle, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(post['replies']!, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              // REGULAR SERVICE DETAILS VIEW
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                '✨ Key Service Deliverables & Features',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                children: widget.features.map((feat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: widget.accentColor.withOpacity(0.12), shape: BoxShape.circle),
                          child: Icon(LucideIcons.check, size: 14, color: widget.accentColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feat,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkOnSurface : AppTheme.lightOnSurface),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Pricing & Booking Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ESTIMATED SERVICE FEE', style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          widget.startingPrice,
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: widget.accentColor),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _onBookService,
                      icon: const Icon(LucideIcons.calendarCheck, size: 16, color: Colors.white),
                      label: Text('Request This Service', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNewPostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start a Community Discussion', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _newPostController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ask a question or share a property/builder review in NCR...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_newPostController.text.trim().isNotEmpty) {
                    setState(() {
                      _forumPosts.insert(0, {
                        'author': 'You (Guest User)',
                        'time': 'Just now',
                        'title': 'New Community Topic',
                        'content': _newPostController.text.trim(),
                        'likes': '1',
                        'replies': '0 replies',
                      });
                    });
                    _newPostController.clear();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Topic posted to PropZen Forum!'), backgroundColor: Colors.indigo),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: Text('Post Topic', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
