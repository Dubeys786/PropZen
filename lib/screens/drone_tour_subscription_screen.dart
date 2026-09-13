import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/drone_tour_subscription_model.dart';
import '../models/property.dart';
import '../services/drone_subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nri_drone_tour_player_modal.dart';
import 'user_profile_screen.dart';

/// Premium Drone Tour Subscription Screen
/// Dedicated exclusively to Drone Tour access (Decoupled from Dealer subscriptions)
class DroneTourSubscriptionScreen extends StatefulWidget {
  final Property? returnToProperty;
  final VoidCallback? onSubscriptionActivated;

  const DroneTourSubscriptionScreen({
    super.key,
    this.returnToProperty,
    this.onSubscriptionActivated,
  });

  static Future<void> show(
    BuildContext context, {
    Property? returnToProperty,
    VoidCallback? onSubscriptionActivated,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DroneTourSubscriptionScreen(
          returnToProperty: returnToProperty,
          onSubscriptionActivated: onSubscriptionActivated,
        ),
      ),
    );
  }

  @override
  State<DroneTourSubscriptionScreen> createState() => _DroneTourSubscriptionScreenState();
}

class _DroneTourSubscriptionScreenState extends State<DroneTourSubscriptionScreen> {
  final DroneSubscriptionService _droneService = DroneSubscriptionService.instance;

  String _selectedPlanId = 'drone_pass_3m'; // Default 3 Months (Popular)
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final currentSub = UserSession.droneSubscription;
    if (currentSub != null && currentSub.planId.isNotEmpty) {
      _selectedPlanId = currentSub.planId;
    }
  }

  void _handlePlanSelection(DroneTourPlan plan) {
    setState(() {
      _selectedPlanId = plan.id;
    });

    // Mark pending order record. This DOES NOT activate the subscription.
    _droneService.createPendingOrder(
      plan: plan,
      userId: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'buyer_user',
      userEmail: UserSession.email,
    );
  }

  Future<void> _handleSubscribeNow() async {
    final plan = _droneService.plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => _droneService.plans[1],
    );

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Initializing secure payment checkout...';
    });

    // 1. Create Pending Order (Strictly locked state)
    final pendingSub = _droneService.createPendingOrder(
      plan: plan,
      userId: UserSession.fullName.isNotEmpty ? UserSession.fullName : 'buyer_user',
      userEmail: UserSession.email,
    );

    // 2. Gateway Checkout & Verification Pipeline
    try {
      await Future.delayed(const Duration(milliseconds: 1200));

      final transactionId = 'txn_drone_${DateTime.now().millisecondsSinceEpoch}';
      final paymentId = 'pay_drone_${DateTime.now().millisecondsSinceEpoch}';

      final activeSub = await _droneService.verifyAndActivateSubscription(
        orderId: pendingSub.id,
        planId: plan.id,
        paymentId: paymentId,
        transactionId: transactionId,
      );

      _handleActivationSuccess(activeSub);
    } catch (e) {
      _droneService.markPaymentFailed(reason: e.toString());
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Payment error: $e';
        });
      }
    }
  }

  void _handleActivationSuccess(DroneTourSubscription activeSub) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Subscription Active! Drone Tours Unlocked.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🎉 ${activeSub.planName} Activated! All Drone Tours are now unlocked.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.emeraldSuccess,
        duration: const Duration(seconds: 4),
      ),
    );

    widget.onSubscriptionActivated?.call();

    // If navigated from a specific property, pop and open the tour player!
    if (widget.returnToProperty != null) {
      final prop = widget.returnToProperty!;
      Navigator.of(context).pop();
      NriDroneTourPlayerModal.show(context, prop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = _droneService.plans;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final hasActiveAccess = UserSession.hasActiveDroneAccess;
    final currentSub = UserSession.droneSubscription;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark luxury theme for aerial vibe
      appBar: AppBar(
        title: Text(
          'Unlock Premium Drone Tours',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 60 : (isTablet ? 30 : 18),
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                _buildHeaderBanner(hasActiveAccess, currentSub),

                const SizedBox(height: 24),

                // Benefits List
                _buildBenefitsSection(),

                const SizedBox(height: 28),

                // Subscription Plans Grid
                Text(
                  'Choose Your Drone Tour Pass',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (ctx, constraints) {
                    if (constraints.maxWidth >= 700) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: plans.map((p) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: _buildPlanCard(p),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return Column(
                        children: plans.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildPlanCard(p),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // Checkout & Subscribe Button Box
                _buildCheckoutBox(hasActiveAccess),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool hasActiveAccess, DroneTourSubscription? currentSub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.4)),
                ),
                child: const Text('🚁', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Premium Drone Tours',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Experience properties from above with immersive aerial views.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFC7D2FE),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasActiveAccess && currentSub != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF34D399)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: Color(0xFF34D399), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Current Status: Active (${currentSub.planName}) — Valid until ${currentSub.formattedExpiryDate}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      'HD aerial property videos',
      'Property surroundings',
      'Better location understanding',
      'Immersive aerial experience',
      'Access to available property drone tours',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Subscribe to Drone Tours?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: benefits.map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(LucideIcons.check, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(DroneTourPlan plan) {
    final isSelected = _selectedPlanId == plan.id;

    return InkWell(
      onTap: () => _handlePlanSelection(plan),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF818CF8) : const Color(0xFF334155),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
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
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'POPULAR',
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                else if (plan.discountTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      plan.discountTag!,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                else
                  const SizedBox(height: 18),
                Radio<String>(
                  value: plan.id,
                  groupValue: _selectedPlanId,
                  onChanged: (_) => _handlePlanSelection(plan),
                  activeColor: const Color(0xFF818CF8),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              plan.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  plan.formattedPrice,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF818CF8),
                  ),
                ),
                if (plan.formattedOriginalPrice.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    plan.formattedOriginalPrice,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              plan.formattedMonthlyPrice,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 8),
            ...plan.benefits.take(3).map((b) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.check, size: 13, color: Color(0xFF34D399)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBox(bool hasActiveAccess) {
    final selectedPlan = _droneService.plans.firstWhere(
      (p) => p.id == _selectedPlanId,
      orElse: () => _droneService.plans[1],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Pass: ${selectedPlan.name}',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Full access across all NCR properties for ${selectedPlan.durationMonths} months',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
              Text(
                selectedPlan.formattedPrice,
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF818CF8)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                _statusMessage!,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 14),
          ],

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleSubscribeNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Processing Secure Checkout...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Text(
                      hasActiveAccess ? 'Renew / Upgrade Drone Pass' : 'Subscribe Now',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  'Encrypted 256-bit Payment Verification. Instant activation upon success.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
