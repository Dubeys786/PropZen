import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/dealer_subscription_model.dart';
import '../services/dealer_subscription_service.dart';
import '../services/razorpay_checkout_service.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/dealer_payment_history_modal.dart';
import '../services/apple_storekit_service.dart';
import '../theme/app_theme.dart';

/// Premium Dealer & Broker Subscription Plans & Razorpay Checkout Screen
class DealerSubscriptionPlansScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionActivated;

  const DealerSubscriptionPlansScreen({
    super.key,
    this.onSubscriptionActivated,
  });

  @override
  State<DealerSubscriptionPlansScreen> createState() => _DealerSubscriptionPlansScreenState();
}

class _DealerSubscriptionPlansScreenState extends State<DealerSubscriptionPlansScreen> {
  final DealerSubscriptionService _service = DealerSubscriptionService.instance;
  final RazorpayCheckoutService _razorpayService = RazorpayCheckoutService.instance;

  String _selectedPlanId = 'dealer_premium'; // Default Selection (Recommended)
  bool _isProcessingPayment = false;
  String? _paymentStatusMessage;

  @override
  void initState() {
    super.initState();
    final currentSub = _service.currentSubscription;
    if (currentSub.planId.isNotEmpty) {
      _selectedPlanId = currentSub.planId;
    }
  }

  void _onSelectPlan(DealerSubscriptionPlan plan) {
    setState(() {
      _selectedPlanId = plan.id;
    });

    final dealerEmail = UserSession.email.isNotEmpty ? UserSession.email : 'dealer@propzen.ai';
    final dealerId = UserSession.dealerId;

    // Strictly marks plan selected (status = 'plan_selected').
    // This DOES NOT activate subscription or elevate limits.
    _service.selectPlan(
      plan: plan,
      dealerId: dealerId,
      dealerEmail: dealerEmail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _service.plans;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 700 && screenWidth < 1100;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        title: Text(
          'Dealer Subscription & Plans',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => DealerPaymentHistoryModal.show(context),
            icon: const Icon(LucideIcons.receipt, size: 15, color: AppTheme.primaryViolet),
            label: Text(
              'Billing & Invoices',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : (isTablet ? 30 : 16),
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _buildHeroBanner(isDesktop),

                const SizedBox(height: 28),

                // Section Title
                Text(
                  'Choose Your Growth Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Select a plan that matches your listing volume and AI requirements. Continue to verified Razorpay checkout.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),

                const SizedBox(height: 20),

                // Plan Cards Grid
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: plans
                        .map((p) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: _buildPlanCard(p),
                              ),
                            ))
                        .toList(),
                  )
                else
                  Column(
                    children: plans
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPlanCard(p),
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 28),

                // Feature Comparison Summary Card
                _buildComparisonTableCard(),

                const SizedBox(height: 28),

                // Checkout & Payment CTA Box
                _buildPaymentCheckoutBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 30 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x1F7C3AED), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.briefcase, color: Colors.white, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'PROPNZEN DEALER & BROKER SUITE',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: Color(0xFF34D399), size: 12),
                    const SizedBox(width: 5),
                    Text(
                      'RERA Verified Partner',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF34D399)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Grow Your Business with PropZen',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 24 : 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powerful tools to manage high-volume listings, automate AI copywriting, score buyer intent, and close real estate transactions faster.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(DealerSubscriptionPlan plan) {
    final isSelected = _selectedPlanId == plan.id;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? const [BoxShadow(color: Color(0x1A7C3AED), blurRadius: 16, offset: Offset(0, 4))]
            : AppTheme.subtleCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (plan.isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              else if (plan.discountTag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.discountTag!,
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
                  ),
                )
              else
                const SizedBox(height: 20),
              Icon(
                isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                color: isSelected ? AppTheme.primaryViolet : AppTheme.borderLight,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            plan.description,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedPrice,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
              ),
              if (plan.originalPriceInr != null) ...[
                const SizedBox(width: 6),
                Text(
                  plan.formattedOriginalPrice,
                  style: GoogleFonts.inter(fontSize: 13, decoration: TextDecoration.lineThrough, color: AppTheme.textHint),
                ),
              ],
            ],
          ),
          Text(
            plan.formattedDuration,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          // Key Quota Badges
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${plan.listingLimit}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text('Listings', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
                Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                Column(
                  children: [
                    Text(
                      '${plan.leadLimit}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text('Leads/mo', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
                Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                Column(
                  children: [
                    Text(
                      '${plan.photosPerProperty}',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text('Photos/prop', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 20, color: AppTheme.borderLight),
          Column(
            children: plan.benefits.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.check, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Explicit Plan Selection Button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: isSelected
                ? ElevatedButton.icon(
                    onPressed: () => _onSelectPlan(plan),
                    icon: const Icon(LucideIcons.check, size: 14, color: Colors.white),
                    label: Text('Selected ✓', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryViolet,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                : OutlinedButton(
                    onPressed: () => _onSelectPlan(plan),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryViolet,
                      side: const BorderSide(color: AppTheme.primaryViolet),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Select Plan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTableCard() {
    final features = [
      {'name': 'Active Listings Limit', 'free': '3', 'premium': '15', 'super': 'Unlimited'},
      {'name': 'Buyer Leads / Month', 'free': '10', 'premium': '75', 'super': 'VIP Unlimited'},
      {'name': 'Plan Duration', 'free': '60-Day Trial', 'premium': 'Monthly', 'super': 'Monthly'},
      {'name': 'Cost', 'free': '₹0 (Free Trial)', 'premium': '₹4,999 / mo', 'super': '₹9,999 / mo'},
      {'name': 'Photos per Property', 'free': '10', 'premium': '25', 'super': '50'},
      {'name': 'AI Listing & Copywriting', 'free': 'Basic', 'premium': '✓ Included', 'super': '✓ Advanced'},
      {'name': 'AI Lead Scoring', 'free': '—', 'premium': '✓ Included', 'super': '✓ Heatmaps & VIP'},
      {'name': '360° Virtual Tour Embeds', 'free': '—', 'premium': '✓ Included', 'super': '✓ 4K Ultra'},
      {'name': 'Featured & Priority Ranking', 'free': '—', 'premium': '✓ Included', 'super': '✓ Homepage Featured'},
      {'name': 'Account Management', 'free': 'Self-serve', 'premium': 'Priority CRM', 'super': 'Dedicated VIP Manager'},
      {'name': 'API & Webhook Access', 'free': '—', 'premium': '—', 'super': '✓ Full Access'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strict 3-Plan Entitlement Comparison',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 28,
              horizontalMargin: 8,
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              columns: [
                DataColumn(label: Text('Plan Capability', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('FREE (60-DAY TRIAL)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PREMIUM (₹4,999)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet))),
                DataColumn(label: Text('SUPER PREMIUM (₹9,999)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF047857)))),
              ],
              rows: features.map((f) {
                return DataRow(
                  cells: [
                    DataCell(Text(f['name']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                    DataCell(Text(f['free']!, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary))),
                    DataCell(Text(f['premium']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet))),
                    DataCell(Text(f['super']!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF047857)))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCheckoutBox() {
    final selectedPlan = _service.getPlanById(_selectedPlanId) ?? _service.plans.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Color(0x0A7C3AED), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Selected Plan: ${selectedPlan.name}',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: selectedPlan.isFree ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            selectedPlan.isFree ? 'Free Forever' : 'Payment Required',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: selectedPlan.isFree ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Capacity: ${selectedPlan.listingLimit} Listings • ${selectedPlan.leadLimit} Leads • Razorpay Gateway Verified',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                selectedPlan.formattedPrice,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_paymentStatusMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _paymentStatusMessage!,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isProcessingPayment ? null : () => _executeDealerPayment(selectedPlan),
              icon: _isProcessingPayment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(LucideIcons.shieldCheck, size: 16, color: Colors.white),
              label: Text(
                _isProcessingPayment
                    ? 'Processing Payment...'
                    : (selectedPlan.isFree ? 'Activate Free Starter Plan' : 'Continue to Payment • ${selectedPlan.formattedPrice}'),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryViolet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '🔒 ${AppleStoreKitService.instance.paymentPlatformDisclaimer}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _restoreDealerPurchases,
              icon: const Icon(LucideIcons.refreshCw, size: 12, color: AppTheme.primaryViolet),
              label: Text(
                'Restore Purchases (Apple ID / Store)',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _executeDealerPayment(DealerSubscriptionPlan plan) async {
    final dealerEmail = UserSession.email.isNotEmpty ? UserSession.email : 'dealer@propzen.ai';
    final dealerId = UserSession.dealerId;
    final dealerName = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'Verified Dealer';
    final dealerPhone = UserSession.phone.isNotEmpty ? UserSession.phone : '';

    setState(() {
      _isProcessingPayment = true;
      _paymentStatusMessage = 'Creating backend order on PropZen server...';
    });

    try {
      // iOS Apple App Store StoreKit Route
      if (AppleStoreKitService.instance.isIos && !plan.isFree) {
        setState(() {
          _paymentStatusMessage = 'Connecting to Apple App Store In-App Purchase...';
        });

        final result = await AppleStoreKitService.instance.purchaseDealerSubscription(
          plan: plan,
          dealerId: dealerId,
          dealerEmail: dealerEmail,
        );

        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });

        if (result['status'] == 'success') {
          final sub = result['subscription'] as DealerSubscription;
          final txId = result['transactionId'] as String;
          _showSuccessReceiptDialog(plan, sub, txId);
          widget.onSubscriptionActivated?.call();
        } else {
          _showErrorToast(result['message'] as String? ?? 'Apple purchase could not be completed.');
        }
        return;
      }

      // 1. Create Backend Order (Android / Web)
      final orderData = await _service.initiatePaymentOrder(
        plan: plan,
        dealerId: dealerId,
        dealerEmail: dealerEmail,
      );

      // Handle Free plan immediately
      if (plan.isFree || (orderData['isFree'] == true)) {
        final orderId = orderData['orderId'] as String? ?? 'order_dealer_free';
        final sub = await _service.verifyAndActivateSubscription(
          plan: plan,
          paymentId: 'free_trial_activation',
          orderId: orderId,
          signature: orderData['signature'] as String? ?? 'sig_free',
          dealerId: dealerId,
          dealerEmail: dealerEmail,
        );

        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });

        _showSuccessReceiptDialog(plan, sub, 'free_trial_activation');
        return;
      }

      // If Payment Gateway is pending integration, show real status notice and DO NOT fake payment
      if (orderData['status'] == 'payment_pending') {
        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(LucideIcons.clock, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 8),
                  Text('Payment Pending', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Online payment gateway integration is currently in progress for ${plan.name} (${plan.formattedPrice}).',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      'Invoice #${orderData['orderId']} has been recorded. Your subscription status is set to PAYMENT PENDING. The PropZen desk will confirm activation upon payment receipt.',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Understood', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ),
              ],
            ),
          );
        }
        return;
      }

      setState(() {
        _paymentStatusMessage = 'Opening Razorpay checkout...';
      });

      // 2. Open Razorpay Checkout Dialog
      final checkoutResult = await _razorpayService.openCheckout(
        orderData: orderData,
        userName: dealerName,
        userEmail: dealerEmail,
        userPhone: dealerPhone,
      );

      final status = checkoutResult['status'] as String? ?? 'error';

      if (status == 'cancelled') {
        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });
        _service.setPaymentPending(
          plan: plan,
          dealerId: dealerId,
          dealerEmail: dealerEmail,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment cancelled. Subscription remains on current plan.'),
              backgroundColor: const Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Try Again',
                textColor: Colors.amber,
                onPressed: () => _executeDealerPayment(plan),
              ),
            ),
          );
        }
        return;
      }

      if (status == 'failed' || status == 'error') {
        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${checkoutResult['error'] ?? 'Transaction was not completed.'}'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Try Again',
                textColor: Colors.white,
                onPressed: () => _executeDealerPayment(plan),
              ),
            ),
          );
        }
        return;
      }

      // 3. Payment Received from Razorpay -> Server-Side Verification Required
      setState(() {
        _paymentStatusMessage = 'Verifying payment securely on PropZen server...';
      });

      final paymentId = checkoutResult['paymentId'] as String;
      final orderId = checkoutResult['orderId'] as String;
      final signature = checkoutResult['signature'] as String;

      final sub = await _service.verifyAndActivateSubscription(
        plan: plan,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        dealerId: dealerId,
        dealerEmail: dealerEmail,
      );

      setState(() {
        _isProcessingPayment = false;
        _paymentStatusMessage = null;
      });

      if (!mounted) return;
      _showSuccessReceiptDialog(plan, sub, paymentId);
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
        _paymentStatusMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dealer payment verification error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _executeDealerPayment(plan),
            ),
          ),
        );
      }
    }
  }

  void _showSuccessReceiptDialog(DealerSubscriptionPlan plan, DealerSubscription sub, String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.checkCircle2, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Subscription Active ✓',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${plan.name} Activated',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Plan', plan.name),
                  _buildReceiptRow('Listing Capacity', '${plan.listingLimit} Active Listings'),
                  _buildReceiptRow('Lead Quota', '${plan.leadLimit} Leads / month'),
                  _buildReceiptRow('Amount Paid', plan.formattedPrice),
                  _buildReceiptRow('Valid Until', sub.formattedExpiryDate),
                  _buildReceiptRow('Payment ID', paymentId),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                  widget.onSubscriptionActivated?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Open Dealer Portal', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _restoreDealerPurchases() async {
    final dealerEmail = UserSession.email.isNotEmpty ? UserSession.email : 'dealer@propzen.ai';
    final dealerId = UserSession.dealerId;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking Apple App Store for active subscriptions...'), duration: Duration(seconds: 2)),
    );

    final result = await AppleStoreKitService.instance.restorePurchases(
      userType: 'Dealer',
      userId: dealerId,
      userEmail: dealerEmail,
    );

    if (!mounted) return;

    if (result['restored'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: AppTheme.emeraldSuccess,
        ),
      );
      setState(() {});
      widget.onSubscriptionActivated?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: AppTheme.primaryViolet,
        ),
      );
    }
  }
}
