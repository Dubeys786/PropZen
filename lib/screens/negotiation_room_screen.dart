import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/deal_room_model.dart';
import '../models/property.dart';
import '../services/ai_negotiation_service.dart';
import '../services/deal_room_service.dart';
import '../theme/app_theme.dart';
import 'deal_room_screen.dart';
import 'user_profile_screen.dart';

class NegotiationRoomScreen extends StatefulWidget {
  final Property property;
  final String? dealRoomId;

  const NegotiationRoomScreen({
    super.key,
    required this.property,
    this.dealRoomId,
  });

  @override
  State<NegotiationRoomScreen> createState() => _NegotiationRoomScreenState();
}

class _NegotiationRoomScreenState extends State<NegotiationRoomScreen> {
  late final TextEditingController _buyerBudgetController;
  late final TextEditingController _dealerOfferController;
  final TextEditingController _offerNoteController = TextEditingController();

  NegotiationInsight? _insight;
  late DealRoom _dealRoom;

  @override
  void initState() {
    super.initState();
    final listedCr = widget.property.askingPriceCr > 0 ? widget.property.askingPriceCr : (widget.property.price / 10000000);

    _buyerBudgetController = TextEditingController(text: (listedCr * 0.95).toStringAsFixed(2));
    _dealerOfferController = TextEditingController(text: listedCr.toStringAsFixed(2));

    _dealRoom = DealRoomService.instance.getOrCreateDealRoom(
      property: widget.property,
      buyerId: UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_buyer_active',
      buyerName: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Rahul Singhania',
      dealerId: widget.property.dealerId.isNotEmpty ? widget.property.dealerId : 'dealer_ncr_01',
      dealerName: widget.property.dealerName.isNotEmpty ? widget.property.dealerName : 'Aman Sharma (Prime Realty)',
    );

    _recalculateInsight();
  }

  @override
  void dispose() {
    _buyerBudgetController.dispose();
    _dealerOfferController.dispose();
    _offerNoteController.dispose();
    super.dispose();
  }

  void _recalculateInsight() {
    final listedCr = widget.property.askingPriceCr > 0 ? widget.property.askingPriceCr : (widget.property.price / 10000000);
    final buyerCr = double.tryParse(_buyerBudgetController.text) ?? (listedCr * 0.95);
    final dealerCr = double.tryParse(_dealerOfferController.text) ?? listedCr;

    setState(() {
      _insight = AiNegotiationService.instance.analyzeNegotiation(
        listedPriceCr: listedCr,
        buyerBudgetCr: buyerCr,
        dealerOfferCr: dealerCr,
        property: widget.property,
      );
    });
  }

  void _submitNewOffer(bool isBuyer) {
    final amountCr = double.tryParse(isBuyer ? _buyerBudgetController.text : _dealerOfferController.text) ?? 1.5;
    final role = isBuyer ? 'Buyer' : 'Dealer';
    final name = isBuyer
        ? (UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Buyer')
        : (widget.property.dealerName.isNotEmpty ? widget.property.dealerName : 'Dealer Desk');

    DealRoomService.instance.submitOffer(
      dealRoomId: _dealRoom.id,
      senderId: isBuyer ? 'usr_buyer_active' : 'dealer_ncr_01',
      senderName: name,
      senderRole: role,
      amountCr: amountCr,
      note: _offerNoteController.text.trim().isNotEmpty ? _offerNoteController.text.trim() : null,
    );

    setState(() {
      _dealRoom = DealRoomService.instance.getRoomById(_dealRoom.id) ?? _dealRoom;
      _offerNoteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ $role offer of ₹${amountCr.toStringAsFixed(2)} Cr recorded in Safe Deal Room!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = UserSession.roleTierNotifier.value == 'Buyer';

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Negotiation Room & AI Insights',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            Text(
              widget.property.title,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => DealRoomScreen(dealRoomId: _dealRoom.id),
                ),
              );
            },
            icon: const Icon(LucideIcons.shieldCheck, size: 16, color: Color(0xFF10B981)),
            label: Text('Open Safe Deal Room', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
          ),
          const SizedBox(width: 8),
        ],
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
                // 1. Negotiation Parameters Comparison Card
                _buildParametersCard(),
                const SizedBox(height: 20),

                // 2. AI Estimated Negotiation Range & Insights
                if (_insight != null) _buildAiInsightCard(_insight!),
                const SizedBox(height: 20),

                // 3. Submit New Offer Section
                _buildOfferSubmissionBox(isBuyer),
                const SizedBox(height: 24),

                // 4. Chronological Offer Ledger
                _buildOfferHistorySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Proposal Parameters', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text('Base Listed: ₹ ${widget.property.askingPriceCr.toStringAsFixed(2)} Cr',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buyer Maximum Budget (₹ Cr)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _buyerBudgetController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculateInsight(),
                      decoration: InputDecoration(
                        hintText: 'e.g. 1.75',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dealer Offer / Counter (₹ Cr)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dealerOfferController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalculateInsight(),
                      decoration: InputDecoration(
                        hintText: 'e.g. 1.82',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(NegotiationInsight insight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.35), width: 1.5),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.scale, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Estimated Negotiation Band', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      Text('Dynamic Fair-Value Settlement Range', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Close Probability: ${insight.dealProbability}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Highlighted Range Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                Text('Potential Realistic Negotiation Range:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Text(
                  insight.formattedRange,
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                ),
                const SizedBox(height: 6),
                Text('Difference between buyer budget and counter-offer: ₹${insight.priceDifferenceCr.toStringAsFixed(2)} Cr (${insight.spreadPercentage.toStringAsFixed(1)}% spread)',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Key Negotiation Factors
          Text('Key Negotiation Dynamics:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          ...insight.negotiationFactors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.35))),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          // Suggested Next Step
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.lightbulb, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Suggested Strategy: ${insight.suggestedNextStep}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF065F46))),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Disclaimer
          Text(
            '⚠️ ${insight.disclaimer}',
            style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferSubmissionBox(bool isBuyer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Submit Official Proposal in Safe Deal Room', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          TextField(
            controller: _offerNoteController,
            decoration: InputDecoration(
              hintText: 'Add note / inclusions (e.g. Immediate token ready if 2 covered parking slots included)',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _submitNewOffer(true),
                  icon: const Icon(LucideIcons.send, size: 14),
                  label: const Text('Submit Buyer Offer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _submitNewOffer(false),
                  icon: const Icon(LucideIcons.cornerUpRight, size: 14),
                  label: const Text('Submit Dealer Counter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferHistorySection() {
    final offers = _dealRoom.offers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Chronological Offer History (${offers.length})', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text('Immutable Audit Trail', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
        const SizedBox(height: 12),
        ...offers.map((offer) => _buildOfferTile(offer)),
      ],
    );
  }

  Widget _buildOfferTile(DealOffer offer) {
    final isPending = offer.status == OfferStatus.pending;
    final isAccepted = offer.status == OfferStatus.accepted;

    Color statusColor = AppTheme.textMuted;
    if (isPending) statusColor = const Color(0xFFF59E0B);
    if (isAccepted) statusColor = const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isAccepted ? const Color(0xFF10B981).withOpacity(0.5) : AppTheme.borderLight),
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
                child: Icon(offer.senderRole == 'Buyer' ? LucideIcons.user : LucideIcons.building,
                    size: 16, color: offer.senderRole == 'Buyer' ? AppTheme.primaryViolet : const Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${offer.senderName} (${offer.senderRole})',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  if (offer.note != null && offer.note!.isNotEmpty)
                    Text(
                      offer.note!,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                offer.formattedAmount,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  offer.status.name.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
