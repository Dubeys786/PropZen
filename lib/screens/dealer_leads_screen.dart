import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import '../models/property.dart';
import '../services/ai_follow_up_service.dart';
import '../services/property_state_service.dart';
import '../services/deal_room_service.dart';
import '../services/dealer_subscription_service.dart';
import '../services/dealer_lead_service.dart';
import '../services/supabase_service.dart';
import '../widgets/dealer_buyer_matching_modal.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import 'deal_room_screen.dart';
import 'dealer_subscription_plans_screen.dart';
import 'user_profile_screen.dart';

class DealerLeadsScreen extends StatefulWidget {
  const DealerLeadsScreen({super.key});

  @override
  State<DealerLeadsScreen> createState() => _DealerLeadsScreenState();
}

class _DealerLeadsScreenState extends State<DealerLeadsScreen> {
  final DealerLeadService _leadService = DealerLeadService.instance;
  String _selectedFilter = 'ALL';

  String get _currentDealerId => UserSession.dealerId;

  final TextEditingController _customFollowUpController = TextEditingController();

  void _openFollowUpModal(DealerLead lead) async {
    final subService = DealerSubscriptionService.instance;
    if (!subService.canAccessFollowUpTools()) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle),
                child: const Icon(LucideIcons.bot, color: AppTheme.primaryViolet, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('AI Assistant Requires Pro Plan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Text(
            'Personalized AI WhatsApp follow-up generation is available for Pro and Premium subscribers. Upgrade now to automate client outreach.',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Upgrade Plan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<GeneratedFollowUp>(
            future: AiFollowUpService.instance.generateFollowUpForLead(lead),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  content: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.primaryViolet),
                        const SizedBox(height: 16),
                        Text('AI is crafting a personalized follow-up for ${lead.buyerName}...',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              final followUp = snapshot.data;
              if (followUp == null) return const SizedBox.shrink();

              if (_customFollowUpController.text.isEmpty) {
                _customFollowUpController.text = followUp.messageBody;
              }

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.bot, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Follow-up Assistant', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('Personalized for ${lead.buyerName}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet)),
                        ],
                      ),
                    ),
                  ],
                ),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('AI Rationale: ${followUp.rationale}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF065F46))),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Editable Message Body (Dealer Approval Required):',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _customFollowUpController,
                          maxLines: 5,
                          style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderLight)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ Explicit Dealer Action Required: Message will only be dispatched upon tapping "Approve & Send".',
                          style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _customFollowUpController.clear();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _customFollowUpController.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message copied to clipboard!'), backgroundColor: AppTheme.primaryViolet),
                      );
                    },
                    icon: const Icon(LucideIcons.copy, size: 12),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final sentMsg = _customFollowUpController.text.trim();
                      _customFollowUpController.clear();
                      Navigator.of(ctx).pop();

                      // Open WhatsApp with approved text
                      final phone = lead.buyerPhone.replaceAll(RegExp(r'[^\d]'), '');
                      if (phone.isNotEmpty) {
                        final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(sentMsg)}');
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Follow-up approved and initiated via WhatsApp!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.send, size: 14),
                    label: const Text('Approve & Send'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _leadService,
      builder: (context, _) {
        final allLeads = _leadService.getLeadsForDealer(_currentDealerId);

        List<DealerLead> filteredLeads;
        if (_selectedFilter == 'NEW') {
          filteredLeads = allLeads.where((l) => l.isNew).toList();
        } else if (_selectedFilter == 'CONTACTED') {
          filteredLeads = allLeads.where((l) => l.isContacted).toList();
        } else if (_selectedFilter == 'QUALIFIED') {
          filteredLeads = allLeads.where((l) => l.isQualified).toList();
        } else if (_selectedFilter == 'SITE_VISIT') {
          filteredLeads = allLeads.where((l) => l.isSiteVisit).toList();
        } else if (_selectedFilter == 'NEGOTIATION') {
          filteredLeads = allLeads.where((l) => l.isNegotiation).toList();
        } else if (_selectedFilter == 'CONVERTED') {
          filteredLeads = allLeads.where((l) => l.isConverted).toList();
        } else if (_selectedFilter == 'LOST') {
          filteredLeads = allLeads.where((l) => l.isLost).toList();
        } else {
          filteredLeads = allLeads;
        }

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
                  child: const Icon(LucideIcons.users, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Lead Management',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      'Predictive Lead Scoring & 7-Stage Pipeline Assistant',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => DealerBuyerMatchingModal.show(context),
                icon: const Icon(LucideIcons.sparkles, size: 14, color: AppTheme.primaryViolet),
                label: Text(
                  'AI Matchmaker',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.borderLight),
            ),
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filter Chips Bar
                    _buildFilterChipsBar(allLeads),
                    const SizedBox(height: 16),

                    // Lead Count Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pipeline Leads (${filteredLeads.length})', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('Sorted by Intent Score', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Leads List
                    if (filteredLeads.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: EmptyStateView(
                            title: 'No $_selectedFilter Leads',
                            message: 'No leads found in this pipeline stage.',
                            icon: LucideIcons.userX,
                          ),
                        ),
                      )
                    else
                      ...filteredLeads.map((lead) => _buildLeadCard(lead)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChipsBar(List<DealerLead> allLeads) {
    final filters = [
      {'id': 'ALL', 'label': 'All (${allLeads.length})'},
      {'id': 'NEW', 'label': '🌱 New (${allLeads.where((l) => l.isNew).length})'},
      {'id': 'CONTACTED', 'label': '📞 Contacted (${allLeads.where((l) => l.isContacted).length})'},
      {'id': 'QUALIFIED', 'label': '⚡ Qualified (${allLeads.where((l) => l.isQualified).length})'},
      {'id': 'SITE_VISIT', 'label': '📅 Site Visit (${allLeads.where((l) => l.isSiteVisit).length})'},
      {'id': 'NEGOTIATION', 'label': '🤝 Negotiation (${allLeads.where((l) => l.isNegotiation).length})'},
      {'id': 'CONVERTED', 'label': '🏆 Converted (${allLeads.where((l) => l.isConverted).length})'},
      {'id': 'LOST', 'label': '❌ Lost (${allLeads.where((l) => l.isLost).length})'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSel = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                f['label']!,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              selected: isSel,
              selectedColor: AppTheme.primaryViolet,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSel ? AppTheme.primaryViolet : AppTheme.borderLight)),
              onSelected: (_) => setState(() => _selectedFilter = f['id']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeadCard(DealerLead lead) {
    Color tierColor = const Color(0xFFF59E0B);
    if (lead.scoreTier == LeadScoreTier.hot) tierColor = const Color(0xFFEF4444);
    if (lead.scoreTier == LeadScoreTier.earlyInquiry) tierColor = const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lead.scoreTier == LeadScoreTier.hot ? tierColor.withOpacity(0.35) : AppTheme.borderLight, width: lead.scoreTier == LeadScoreTier.hot ? 1.5 : 1.0),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name + Score Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.user, color: tierColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.buyerName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('${lead.buyerPhone} • ${lead.buyerEmail}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              // AI Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tierColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      lead.scoreTier.badgeLabel,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: tierColor),
                    ),
                    const SizedBox(width: 4),
                    Text('(${lead.leadScore}%)', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: tierColor)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),

          // Requirement & Property Context
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interested Property:', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                    Text(lead.propertyTitle, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stated Budget:', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                    Text('₹ ${lead.budgetCr.toStringAsFixed(2)} Cr', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text('Last Activity: ${lead.lastActivity}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),

          const SizedBox(height: 10),

          // AI Factors Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: lead.scoreFactors.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: f.isPositive ? const Color(0xFF10B981).withOpacity(0.08) : const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (f.isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.2)),
                ),
                child: Text(
                  '${f.title} (${f.impactPercentage > 0 ? "+${f.impactPercentage}" : f.impactPercentage}%)',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: f.isPositive ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
                ),
              );
            }).toList(),
          ),

          // Pipeline Stage Status Selector Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.gitFork, size: 13, color: AppTheme.primaryViolet),
                    const SizedBox(width: 6),
                    Text('Pipeline Stage:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: 'Change Pipeline Stage',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lead.enquiryStatus,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.primaryViolet),
                      ],
                    ),
                  ),
                  onSelected: (newStatus) {
                    _leadService.updateLeadStatus(
                      leadId: lead.id,
                      newStatus: newStatus,
                      note: 'Moved from ${lead.enquiryStatus} to $newStatus',
                    );
                  },
                  itemBuilder: (ctx) => [
                    'New',
                    'Contacted',
                    'Qualified',
                    'Site Visit',
                    'Negotiation',
                    'Converted',
                    'Lost',
                  ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action Buttons: AI Follow-Up & Safe Deal Room
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openFollowUpModal(lead),
                  icon: const Icon(LucideIcons.bot, size: 14),
                  label: const Text('AI Follow-up Assistant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final room = DealRoomService.instance.getOrCreateDealRoom(
                    property: PropertyStateService.instance.findPropertyById(lead.propertyId) ?? Property.sampleDeals.first,
                    buyerId: lead.buyerId,
                    buyerName: lead.buyerName,
                    buyerPhone: lead.buyerPhone,
                    buyerEmail: lead.buyerEmail,
                    dealerId: _currentDealerId,
                    dealerName: 'Prime Realty',
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => DealRoomScreen(dealRoomId: room.id),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF10B981)),
                label: Text('Deal Room', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
