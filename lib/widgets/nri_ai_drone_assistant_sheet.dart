import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

/// Interactive AI Assistant Sheet during Drone Tour Playback
class NriAiDroneAssistantSheet extends StatefulWidget {
  final Property property;

  const NriAiDroneAssistantSheet({
    super.key,
    required this.property,
  });

  static void show(BuildContext context, {required Property property}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NriAiDroneAssistantSheet(property: property),
    );
  }

  @override
  State<NriAiDroneAssistantSheet> createState() => _NriAiDroneAssistantSheetState();
}

class _NriAiDroneAssistantSheetState extends State<NriAiDroneAssistantSheet> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestedPrompts = const [
    'What am I looking at right now?',
    'Where is the nearest expressway?',
    'How far is the international airport?',
    'Is there green buffer around the towers?',
    'What are the commercial hubs nearby?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'text':
          'Namaste! I am your PropZen AI Aerial Guide for **${widget.property.title}** (${widget.property.sector}, ${widget.property.city}). Ask me anything about this aerial view, nearby roads, transit corridors, or green coverage!',
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _handleUserQuery(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': query.trim()});
      _isTyping = true;
    });
    _queryController.clear();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final q = query.toLowerCase();
      String response = '';

      if (q.contains('what am i looking at') || q.contains('aerial view') || q.contains('overview')) {
        response =
            'You are viewing the 4K aerial perspective of **${widget.property.title}** at approximately ${widget.property.droneFlightAltitudeMeters}m altitude. Visible features include Tower A & B residential quads, the central landscaped clubhouse with swimming pool, and the adjoining 45-meter sector arterial road.';
      } else if (q.contains('road') || q.contains('expressway') || q.contains('highway') || q.contains('connectivity')) {
        final nearbyInfo = widget.property.nearby.entries.map((e) => '• **${e.key}**: ${e.value}').join('\n');
        response =
            '**Connectivity & Highway Corridors:**\n$nearbyInfo\n\nThe site enjoys direct signal-free access to major NCR arteries, with a wide 4-lane sector access corridor.';
      } else if (q.contains('airport') || q.contains('jewar') || q.contains('igi')) {
        response =
            '**Airport Proximity:**\n• **Upcoming Noida International Airport (Jewar)**: ~38 km via Yamuna Expressway.\n• **Indira Gandhi International Airport (IGI, T3)**: ~42 km via DND Flyway & NH-48.';
      } else if (q.contains('green') || q.contains('park') || q.contains('buffer') || q.contains('environment')) {
        response =
            '**Green Buffer & Environment:**\n• 70%+ open green spaces within the gated project.\n• Bordered by a dedicated 50m green belt corridor shielding from dust and traffic noise.\n• East-facing sunrise exposure overlooking lush open landscape.';
      } else if (q.contains('metro') || q.contains('station') || q.contains('transit')) {
        response =
            '**Metro & Public Transit:**\n• **Sector 52 / 76 Metro Stations**: ~8.0 km (connecting Aqua & Blue Lines).\n• Proposed Greater Noida West Metro extension planned within 1.5 km of this sector.';
      } else {
        response =
            'Based on verified PropZen geographical data for **${widget.property.title}** (${widget.property.sector}), this property features **${widget.property.bhk}** configurations, starting asking price of **${widget.property.priceRangeDisplay}**, RERA Approval (${widget.property.reraId}), and high NRI investor sentiment.';
      }

      setState(() {
        _isTyping = false;
        _messages.add({'role': 'assistant', 'text': response});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.72,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.bot, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Drone Tour Aerial Guide',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Real-time intelligence on locality, roads & surroundings',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: mq.size.width * 0.82),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.primaryViolet : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isUser ? Colors.transparent : Colors.white10),
                    ),
                    child: Text(
                      m['text']!,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white, height: 1.45),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryViolet)),
                  const SizedBox(width: 8),
                  Text('PropZen AI is analyzing aerial telemetry...', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                ],
              ),
            ),

          // Suggested Prompts
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: _suggestedPrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF1E293B),
                    label: Text(p, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1))),
                    onPressed: () => _handleUserQuery(p),
                    side: const BorderSide(color: Colors.white12),
                  ),
                );
              }).toList(),
            ),
          ),

          // Input Field
          Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 8,
              bottom: mq.viewInsets.bottom + 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _queryController,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                      onSubmitted: _handleUserQuery,
                      decoration: InputDecoration(
                        hintText: 'Ask about this drone view or locality...',
                        hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handleUserQuery(_queryController.text),
                  icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
