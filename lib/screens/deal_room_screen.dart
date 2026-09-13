import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/deal_room_model.dart';
import '../services/deal_room_service.dart';
import '../theme/app_theme.dart';
import '../widgets/propzen_deal_score_widget.dart';
import 'user_profile_screen.dart';
import 'main_shell.dart';

class DealRoomScreen extends StatefulWidget {
  final String dealRoomId;

  const DealRoomScreen({super.key, required this.dealRoomId});

  @override
  State<DealRoomScreen> createState() => _DealRoomScreenState();
}

class _DealRoomScreenState extends State<DealRoomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatInputController = TextEditingController();
  final TextEditingController _counterAmountController = TextEditingController();
  final TextEditingController _counterNoteController = TextEditingController();

  final _dealRoomService = DealRoomService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    _counterAmountController.dispose();
    _counterNoteController.dispose();
    super.dispose();
  }

  void _sendChatMessage(DealRoom room) {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    final isBuyer = UserSession.roleTierNotifier.value == 'Buyer';
    final role = isBuyer ? 'Buyer' : 'Dealer';
    final name = isBuyer ? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Buyer') : room.dealerName;

    _dealRoomService.sendMessage(
      dealRoomId: room.id,
      senderId: isBuyer ? room.buyerId : room.dealerId,
      senderName: name,
      senderRole: role,
      content: text,
    );

    _chatInputController.clear();
  }

  void _acceptOffer(DealRoom room, DealOffer offer) {
    final isBuyer = UserSession.roleTierNotifier.value == 'Buyer';
    final name = isBuyer ? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Buyer') : room.dealerName;
    final role = isBuyer ? 'Buyer' : 'Dealer';

    _dealRoomService.acceptOffer(
      dealRoomId: room.id,
      offerId: offer.id,
      actorName: name,
      actorRole: role,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Offer of ${offer.formattedAmount} Accepted! Safe Deal Room advanced to Agreement & Payment stages.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showCounterOfferDialog(DealRoom room) {
    _counterAmountController.text = (room.latestOffer?.amountCr ?? room.listedPriceCr).toStringAsFixed(2);
    _counterNoteController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Submit Formal Counter-Offer', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter proposed price amount in ₹ Cr:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _counterAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 1.78',
                prefixText: '₹ ',
                suffixText: 'Cr',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Optional Note / Condition:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: _counterNoteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Inclusive of covered car parking & club membership',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_counterAmountController.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid offer amount')),
                );
                return;
              }

              final isBuyer = UserSession.roleTierNotifier.value == 'Buyer';
              final name = isBuyer ? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Buyer') : room.dealerName;
              final role = isBuyer ? 'Buyer' : 'Dealer';

              _dealRoomService.submitOffer(
                dealRoomId: room.id,
                senderId: isBuyer ? room.buyerId : room.dealerId,
                senderName: name,
                senderRole: role,
                amountCr: amount,
                note: _counterNoteController.text.trim(),
              );

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✨ Formal Counter-Offer of ₹${amount.toStringAsFixed(2)} Cr Submitted!'),
                  backgroundColor: AppTheme.primaryViolet,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Counter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dealRoomService,
      builder: (context, _) {
        final room = _dealRoomService.getRoomById(widget.dealRoomId);

        if (room == null) {
          return Scaffold(
            backgroundColor: AppTheme.pageBackground,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppTheme.textPrimary),
              title: Text('Safe Deal Room', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppTheme.borderLight),
              ),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.shieldCheck, size: 48, color: AppTheme.primaryViolet),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No active deals yet',
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore properties and start your property journey.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
                          (route) => false,
                        );
                      },
                      icon: const Icon(LucideIcons.compass, size: 18),
                      label: const Text('Explore Properties'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
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
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Safe Deal Room', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryViolet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(room.stage.displayName, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                        ),
                      ],
                    ),
                    Text(
                      '${room.buyerName} ↔ ${room.dealerName} • ${room.propertyTitle}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppTheme.borderLight),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppTheme.primaryViolet,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.primaryViolet,
                    labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: '🏛️ Overview & Stepper'),
                      Tab(text: '💰 Offers & Negotiation'),
                      Tab(text: '💳 Payment Milestones'),
                      Tab(text: '💬 Secure Chat'),
                      Tab(text: '📑 Documents (KYC/Deeds)'),
                      Tab(text: '📜 Activity Timeline'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Overview
              _buildOverviewTab(room),

              // Tab 2: Offers
              _buildOffersTab(room),

              // Tab 3: Milestones
              _buildPaymentMilestonesTab(room),

              // Tab 4: Chat
              _buildSecureChatTab(room),

              // Tab 5: Documents
              _buildDocumentsTab(room),

              // Tab 6: Activity Timeline
              _buildTimelineTab(room),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(DealRoom room) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deal Lifecycle Stage Stepper
              _buildLifecycleStepper(room),
              const SizedBox(height: 20),

              // Participants Card
              _buildParticipantsCard(room),
              const SizedBox(height: 20),

              // PropZen 5-Pillar Deal Score Widget
              const PropZenDealScoreWidget(),
              const SizedBox(height: 20),

              // Current Agreement Status Box
              _buildCurrentDealStatusBox(room),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifecycleStepper(DealRoom room) {
    final stages = DealStage.values;
    final currentIdx = room.stage.index;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deal Lifecycle Stage', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Step ${room.stage.stepIndex} of 7', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: stages.map((st) {
                final idx = st.index;
                final isDone = idx < currentIdx;
                final isCurrent = idx == currentIdx;

                Color circleColor = AppTheme.borderLight;
                Color textColor = AppTheme.textMuted;
                if (isDone) {
                  circleColor = const Color(0xFF10B981);
                  textColor = const Color(0xFF10B981);
                } else if (isCurrent) {
                  circleColor = AppTheme.primaryViolet;
                  textColor = AppTheme.primaryViolet;
                }

                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone ? const Color(0xFF10B981) : (isCurrent ? AppTheme.primaryViolet : AppTheme.surfaceSubtle),
                            shape: BoxShape.circle,
                            border: Border.all(color: circleColor, width: 2),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                                : Text('${idx + 1}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : AppTheme.textMuted)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          st.displayName,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: textColor),
                        ),
                      ],
                    ),
                    if (idx < stages.length - 1)
                      Container(
                        width: 36,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: isDone ? const Color(0xFF10B981) : AppTheme.borderLight,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsCard(DealRoom room) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verified Authorized Deal Participants', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          Row(
            children: [
              // Buyer
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primaryViolet.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.user, size: 16, color: AppTheme.primaryViolet),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(room.buyerName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('Buyer • KYC Verified ✓', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Dealer
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.building, size: 16, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(room.dealerName, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Institutional Partner ✓', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDealStatusBox(DealRoom room) {
    final agreedPrice = room.agreedPriceCr;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (agreedPrice != null ? const Color(0xFF10B981) : AppTheme.primaryViolet).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (agreedPrice != null ? const Color(0xFF10B981) : AppTheme.primaryViolet).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agreedPrice != null ? 'Agreed Price: ₹${agreedPrice.toStringAsFixed(2)} Cr' : 'Current Active Proposal: ${room.latestOffer?.formattedAmount ?? "₹${room.listedPriceCr} Cr"}',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: agreedPrice != null ? const Color(0xFF065F46) : AppTheme.primaryViolet),
              ),
              const SizedBox(height: 4),
              Text(
                agreedPrice != null
                    ? 'Price finalized. Both parties are bound by the draft agreement milestones.'
                    : 'Awaiting formal confirmation or counter proposal in the Offers tab.',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(1), // Switch to Offers Tab
            style: ElevatedButton.styleFrom(
              backgroundColor: agreedPrice != null ? const Color(0xFF10B981) : AppTheme.primaryViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View Offers'),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersTab(DealRoom room) {
    final offers = room.offers;
    final latestOffer = room.latestOffer;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Latest Active Offer Banner
              if (latestOffer != null && latestOffer.status == OfferStatus.pending)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1.5),
                    boxShadow: AppTheme.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Active Offer on Table', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                            child: Text('PENDING APPROVAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        latestOffer.formattedAmount,
                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                      ),
                      Text('Proposed by: ${latestOffer.senderName} (${latestOffer.senderRole})', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                      if (latestOffer.note != null && latestOffer.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Note: ${latestOffer.note}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptOffer(room, latestOffer),
                              icon: const Icon(LucideIcons.checkCheck, size: 16),
                              label: const Text('Accept & Finalize Price'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCounterOfferDialog(room),
                              icon: const Icon(LucideIcons.cornerUpRight, size: 16),
                              label: const Text('Counter Offer'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppTheme.primaryViolet),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Offer History Ledger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Complete Negotiation History (${offers.length})', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ElevatedButton.icon(
                    onPressed: () => _showCounterOfferDialog(room),
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Submit Offer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...offers.map((o) => _buildOfferTile(o)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferTile(DealOffer offer) {
    Color badgeColor = const Color(0xFFF59E0B);
    if (offer.status == OfferStatus.accepted) badgeColor = const Color(0xFF10B981);
    if (offer.status == OfferStatus.rejected) badgeColor = const Color(0xFFEF4444);
    if (offer.status == OfferStatus.countered) badgeColor = AppTheme.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: offer.status == OfferStatus.accepted ? const Color(0xFF10B981).withOpacity(0.5) : AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (offer.senderRole == 'Buyer' ? AppTheme.primaryViolet : const Color(0xFF10B981)).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(offer.senderRole == 'Buyer' ? LucideIcons.user : LucideIcons.building, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${offer.senderName} (${offer.senderRole})', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  if (offer.note != null && offer.note!.isNotEmpty)
                    Text(offer.note!, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(offer.formattedAmount, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                child: Text(offer.status.name.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMilestonesTab(DealRoom room) {
    final milestones = room.paymentMilestones;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Milestones Tracker', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Milestone-based disbursement schedule linked to construction & registry', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 16),

              ...milestones.map((m) => _buildMilestoneCard(room, m)),

              const SizedBox(height: 16),
              Text(
                '⚠️ PropZen tracks milestone statuses for transparent buyer-dealer coordination. Direct transactions occur via authorized escrow / banking channels.',
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(DealRoom room, PaymentMilestone m) {
    final isPaid = m.status == MilestoneStatus.paid;

    Color badgeColor = const Color(0xFFF59E0B);
    if (isPaid) badgeColor = const Color(0xFF10B981);
    if (m.status == MilestoneStatus.upcoming) badgeColor = AppTheme.primaryViolet;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPaid ? const Color(0xFF10B981).withOpacity(0.4) : AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFF10B981).withOpacity(0.1) : AppTheme.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(isPaid ? LucideIcons.checkCheck : LucideIcons.creditCard, color: isPaid ? const Color(0xFF10B981) : AppTheme.textMuted, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Due Date: ${m.dueDate}${m.paymentReference != null ? " • ${m.paymentReference}" : ""}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  if (m.notes != null) ...[
                    const SizedBox(height: 2),
                    Text(m.notes!, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(m.formattedAmount, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet)),
              const SizedBox(height: 4),
              if (!isPaid)
                OutlinedButton(
                  onPressed: () {
                    _dealRoomService.updateMilestoneStatus(
                      dealRoomId: room.id,
                      milestoneId: m.id,
                      status: MilestoneStatus.paid,
                      paymentRef: 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      actorName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Buyer',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text('Mark Paid', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('PAID ✓', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecureChatTab(DealRoom room) {
    final messages = room.messages;

    return Column(
      children: [
        // Chat Header Notice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surfaceSubtle,
          child: Row(
            children: [
              const Icon(LucideIcons.lock, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Text('End-to-End Encrypted Communication between ${room.buyerName} and ${room.dealerName}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: messages.length,
            separatorBuilder: (c, i) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final msg = messages[i];
              final isBuyer = msg.senderRole == 'Buyer';
              final isSystem = msg.senderRole == 'System';

              if (isSystem) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.surfaceSubtle, borderRadius: BorderRadius.circular(8)),
                    child: Text(msg.content, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted), textAlign: TextAlign.center),
                  ),
                );
              }

              return Align(
                alignment: isBuyer ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBuyer ? AppTheme.primaryViolet : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isBuyer ? null : Border.all(color: AppTheme.borderLight),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${msg.senderName} (${msg.senderRole})',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isBuyer ? Colors.white70 : AppTheme.primaryViolet)),
                        const SizedBox(height: 4),
                        Text(msg.content, style: GoogleFonts.inter(fontSize: 12, color: isBuyer ? Colors.white : AppTheme.textPrimary, height: 1.35)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Chat Input Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInputController,
                  decoration: InputDecoration(
                    hintText: 'Type secure message to deal participants...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: AppTheme.surfaceSubtle,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendChatMessage(room),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _sendChatMessage(room),
                icon: const Icon(LucideIcons.send, color: AppTheme.primaryViolet),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab(DealRoom room) {
    final docs = room.documents;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Secure Deal Documents (${docs.length})', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('Authorized participants repository with verification checks', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _dealRoomService.uploadDocument(
                        dealRoomId: room.id,
                        documentName: 'Payment_Receipt_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf',
                        documentType: 'Payment Receipt',
                        uploadedBy: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Buyer',
                        uploaderRole: UserSession.roleTierNotifier.value,
                        fileUrl: 'https://propzen.ai/docs/receipt.pdf',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Document uploaded to Safe Deal Room!'), backgroundColor: Color(0xFF10B981)),
                      );
                    },
                    icon: const Icon(LucideIcons.upload, size: 14),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...docs.map((d) => _buildDocumentTile(d)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(DealDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.surfaceSubtle, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.fileText, color: AppTheme.primaryViolet, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.documentName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${doc.documentType} • ${doc.fileSize} • Uploaded by ${doc.uploadedBy}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(doc.verificationStatus, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(DealRoom room) {
    final timeline = room.activityTimeline;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Immutable Deal Audit Log', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Chronological recording of all offer, document, and milestone events', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              ...timeline.map((event) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.history, size: 16, color: AppTheme.primaryViolet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(event.description, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text('${event.actorName} (${event.actorRole})', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
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
