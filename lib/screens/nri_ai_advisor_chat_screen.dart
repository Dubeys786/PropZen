import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/ai_advisor_models.dart';
import '../services/nri_ai_advisor_engine_service.dart';
import '../theme/app_theme.dart';
import 'property_details_screen.dart';

class NriAiAdvisorChatScreen extends StatefulWidget {
  const NriAiAdvisorChatScreen({super.key});

  @override
  State<NriAiAdvisorChatScreen> createState() => _NriAiAdvisorChatScreenState();
}

class _NriAiAdvisorChatScreenState extends State<NriAiAdvisorChatScreen> {
  final NriAiAdvisorEngineService _advisorService = NriAiAdvisorEngineService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    '₹2 Cr commercial on Noida Expressway with high rental yield',
    '3 BHK luxury ready-to-move in Sector 150 under ₹2.5 Cr',
    'High capital appreciation plots near Jewar Airport',
    'Ready-to-move golf villas in Greater Noida',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuery([String? text]) {
    final query = text ?? _textController.text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    _advisorService.processUserQuery(query).then((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _advisorService,
      builder: (context, _) {
        final messages = _advisorService.messages;
        final isSearching = _advisorService.isSearching;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.sparkles, size: 18, color: AppTheme.primaryViolet),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NRI AI Investment Advisor', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    Text('Strictly queries verified Supabase assets', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.textMuted),
                onPressed: () => _advisorService.clearChat(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Message List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final msg = messages[idx];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              if (isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryViolet)),
                      const SizedBox(width: 10),
                      Text('Scanning verified database & matching criteria...', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),

              // Quick Suggested Chips
              Container(
                height: 42,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickPrompts.length,
                  itemBuilder: (context, idx) {
                    final prompt = _quickPrompts[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(prompt, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet)),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppTheme.primaryViolet.withOpacity(0.3)),
                        onPressed: isSearching ? null : () => _sendQuery(prompt),
                      ),
                    );
                  },
                ),
              ),

              // Input Bar
              _buildInputBar(isSearching),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(AiAdvisorMessageModel msg) {
    final isUser = msg.sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primaryViolet : Colors.white,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
              ),
              border: isUser ? null : Border.all(color: AppTheme.borderLight),
              boxShadow: isUser ? null : AppTheme.softCardShadow,
            ),
            child: Text(
              msg.content,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isUser ? Colors.white : AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),

          // Embedded Matched Properties
          if (msg.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...msg.recommendations.map((rec) => _buildMatchedPropertyCard(rec)),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchedPropertyCard(AiAdvisorMatchResult rec) {
    final p = rec.property;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rec.isExactMatch ? AppTheme.accentEmerald.withOpacity(0.4) : AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.isExactMatch ? AppTheme.emeraldSuccess.withOpacity(0.15) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.matchHeadline,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: rec.isExactMatch ? AppTheme.emeraldSuccess : AppTheme.textMuted,
                  ),
                ),
              ),
              Text('${rec.matchScore}% Match', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          Text('${p.sector}, ${p.city} • ${p.bhk} • ${p.sqft} sq.ft', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('₹ ${p.askingPriceCr.toStringAsFixed(2)} Cr', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('${p.rentalYieldPercent}% Rental Yield', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
              ),
            ],
          ),
          const Divider(height: 16),
          ...rec.whyItMatches.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle, size: 13, color: AppTheme.emeraldSuccess),
                    const SizedBox(width: 6),
                    Expanded(child: Text(reason, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary))),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryViolet),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Full Property Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: p)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isSearching) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Type your investment budget & goals...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendQuery(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.send, color: AppTheme.primaryViolet),
              onPressed: isSearching ? null : () => _sendQuery(),
            ),
          ],
        ),
      ),
    );
  }
}
