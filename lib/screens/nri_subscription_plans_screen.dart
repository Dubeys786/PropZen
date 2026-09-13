import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/nri_subscription_model.dart';
import '../services/nri_subscription_service.dart';
import '../services/razorpay_checkout_service.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/my_payments_modal.dart';
import '../services/apple_storekit_service.dart';
import '../theme/app_theme.dart';

/// Premium NRI Drone Tour Subscription Plans & Real Razorpay Checkout Screen
class NriSubscriptionPlansScreen extends StatefulWidget {
  final VoidCallback? onSubscriptionActivated;

  const NriSubscriptionPlansScreen({
    super.key,
    this.onSubscriptionActivated,
  });

  @override
  State<NriSubscriptionPlansScreen> createState() => _NriSubscriptionPlansScreenState();
}

class _NriSubscriptionPlansScreenState extends State<NriSubscriptionPlansScreen> {
  final NriSubscriptionService _subscriptionService = NriSubscriptionService.instance;
  final RazorpayCheckoutService _razorpayService = RazorpayCheckoutService.instance;

  String _selectedPlanId = 'nri_pass_premium'; // Default Selection (Recommended)
  bool _isProcessingPayment = false;
  String? _paymentStatusMessage;

  @override
  void initState() {
    super.initState();
    final userSub = UserSession.nriSubscription;
    if (userSub != null && userSub.planId.isNotEmpty) {
      _selectedPlanId = userSub.planId;
    }
  }

  void _onSelectPlan(NriSubscriptionPlan plan) {
    setState(() {
      _selectedPlanId = plan.id;
    });

    final userEmail = UserSession.email.isNotEmpty ? UserSession.email : 'nri.client@propzen.ai';
    final userId = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'usr_nri_client';

    // Strictly marks the plan as selected (status = 'plan_selected').
    // This DOES NOT activate subscription or grant drone access.
    _subscriptionService.selectPlan(
      plan: plan,
      userId: userId,
      userEmail: userEmail,
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _subscriptionService.plans;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        title: Text(
          'NRI Remote Property Pass',
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
            onPressed: () => MyPaymentsModal.show(context),
            icon: const Icon(LucideIcons.receipt, size: 15, color: AppTheme.primaryViolet),
            label: Text(
              'My Payments',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : (isTablet ? 30 : 18),
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _buildHeroBanner(isDesktop),

                const SizedBox(height: 28),

                // Section Title
                Text(
                  'Select Your Access Plan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Select a plan to review details, then continue to verified Razorpay payment checkout.',
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
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildPlanCard(p),
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 28),

                // Universal Benefits Checklist
                _buildBenefitsCard(),

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
                    const Icon(LucideIcons.globe, color: Colors.white, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      'NRI REMOTE PROPERTY SUITE',
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
                      'Razorpay Production Ready',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF34D399)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Buy Indian Real Estate from Anywhere in the World.',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'High-definition 4K aerial drone tours, RERA title checks, live video walkthroughs, and legal concierge engineered for global NRI investors.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(NriSubscriptionPlan plan) {
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
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
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
            plan.formattedMonthlyPrice,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const Divider(height: 22, color: AppTheme.borderLight),
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

  Widget _buildBenefitsCard() {
    final list = [
      'Property 4K Drone Aerial Tours',
      'Locality & Corridor aerial views where available',
      'Remote property exploration & 3D walkthroughs',
      'Access to new eligible drone tours during pass validity',
      'Optimized mobile, tablet, and desktop streaming',
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
            'Included in All NRI Passes',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: list.map((item) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCheck, size: 15, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Text(item, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimary)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCheckoutBox() {
    final selectedPlan = _subscriptionService.getPlanById(_selectedPlanId) ?? _subscriptionService.plans.first;

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
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Payment Required',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Duration: ${selectedPlan.durationMonths} Month(s) • Razorpay Server-Verified Checkout',
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
              onPressed: _isProcessingPayment ? null : () => _executeRazorpayPayment(selectedPlan),
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
                    : 'Continue to Payment • ${selectedPlan.formattedPrice}',
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
              onPressed: _restoreNriPurchases,
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

  void _executeRazorpayPayment(NriSubscriptionPlan plan) async {
    final userEmail = UserSession.email.isNotEmpty ? UserSession.email : 'nri.client@propzen.ai';
    final userId = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'usr_nri_client';
    final userName = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'NRI Investor';
    final userPhone = UserSession.phone.isNotEmpty ? UserSession.phone : '+919876543210';

    setState(() {
      _isProcessingPayment = true;
      _paymentStatusMessage = 'Initializing payment...';
    });

    try {
      // iOS Apple App Store StoreKit Route
      if (AppleStoreKitService.instance.isIos) {
        setState(() {
          _paymentStatusMessage = 'Connecting to Apple App Store In-App Purchase...';
        });

        final result = await AppleStoreKitService.instance.purchaseNriSubscription(
          plan: plan,
          userId: userId,
          userEmail: userEmail,
        );

        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });

        if (result['status'] == 'success') {
          final sub = result['subscription'] as NriSubscription;
          final txId = result['transactionId'] as String;
          _showSuccessReceiptDialog(plan, sub, txId);
          widget.onSubscriptionActivated?.call();
        } else {
          _showErrorToast(result['message'] as String? ?? 'Apple purchase could not be completed.');
        }
        return;
      }

      // 1. Create Backend Order (Android / Web)
      final orderData = await _subscriptionService.initiatePaymentOrder(
        plan: plan,
        userId: userId,
        userEmail: userEmail,
      );

      setState(() {
        _paymentStatusMessage = 'Opening Razorpay checkout...';
      });

      // 2. Open Razorpay Checkout Dialog
      final checkoutResult = await _razorpayService.openCheckout(
        orderData: orderData,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
      );

      final status = checkoutResult['status'] as String? ?? 'error';

      if (status == 'cancelled') {
        setState(() {
          _isProcessingPayment = false;
          _paymentStatusMessage = null;
        });
        _subscriptionService.setPaymentPending(
          plan: plan,
          userId: userId,
          userEmail: userEmail,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment cancelled. Subscription remains inactive.'),
              backgroundColor: const Color(0xFF64748B),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Try Again',
                textColor: Colors.amber,
                onPressed: () => _executeRazorpayPayment(plan),
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
                onPressed: () => _executeRazorpayPayment(plan),
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

      final sub = await _subscriptionService.verifyAndActivateSubscription(
        plan: plan,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        userId: userId,
        userEmail: userEmail,
      );

      setState(() {
        _isProcessingPayment = false;
        _paymentStatusMessage = null;
      });

      if (!mounted) return;

      // 4. Show Verified Payment Success & Active Subscription Receipt
      _showSuccessReceiptDialog(plan, sub, paymentId);
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
        _paymentStatusMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _executeRazorpayPayment(plan),
            ),
          ),
        );
      }
    }
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

  void _restoreNriPurchases() async {
    final userEmail = UserSession.email.isNotEmpty ? UserSession.email : 'nri.client@propzen.ai';
    final userId = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'usr_nri_client';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking Apple App Store for active subscriptions...'), duration: Duration(seconds: 2)),
    );

    final result = await AppleStoreKitService.instance.restorePurchases(
      userType: 'NRI',
      userId: userId,
      userEmail: userEmail,
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

  void _showSuccessReceiptDialog(NriSubscriptionPlan plan, NriSubscription sub, String paymentId) {
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
              'Payment Successful ✓',
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
                'Subscription Active',
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
                  _buildReceiptRow('Amount Paid', plan.formattedPrice),
                  _buildReceiptRow('Valid Until', sub.formattedExpiryDate),
                  _buildReceiptRow('Payment ID', paymentId),
                  _buildReceiptRow('Transaction ID', sub.transactionId),
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
                child: Text('Explore Drone Tours', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
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
}
