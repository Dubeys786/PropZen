import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/dealer_subscription_model.dart';
import '../services/dealer_subscription_service.dart';
import '../services/property_state_service.dart';
import '../screens/dealer_subscription_plans_screen.dart';
import '../widgets/dealer_payment_history_modal.dart';
import '../theme/app_theme.dart';

/// Institutional "Subscription & Plans" Status Card for Dealer Dashboard
class DealerSubscriptionStatusCard extends StatelessWidget {
  const DealerSubscriptionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DealerSubscriptionService.instance;
    final state = PropertyStateService.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([service, state]),
      builder: (context, _) {
        final sub = service.currentSubscription;
        final activeListings = state.dealerProperties.length;
        final listingLimit = sub.listingLimit;
        final listingRatio = listingLimit > 0 ? (activeListings / listingLimit).clamp(0.0, 1.0) : 0.0;
        final leadsUsed = state.leads.length;
        final leadLimit = sub.leadLimit;
        final leadRatio = leadLimit > 0 ? (leadsUsed / leadLimit).clamp(0.0, 1.0) : 0.0;

        final isNearLimit = listingRatio >= 0.8 && listingLimit > 0;
        final isAtLimit = listingLimit > 0 && activeListings >= listingLimit;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
              // Row 1: Plan Tier, Status, Billing action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(LucideIcons.crown, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sub.isNone ? 'NO ACTIVE SUBSCRIPTION' : sub.planName.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sub.statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: sub.statusColor.withOpacity(0.5)),
                                ),
                                child: Text(
                                  sub.statusDisplay,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: sub.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            sub.isNone
                                ? 'No active subscription • Select a plan to start'
                                : (sub.isActive
                                    ? 'Valid Until: ${sub.formattedExpiryDate} (${sub.remainingDays} days left)'
                                    : (sub.isExpired
                                        ? 'Subscription expired on ${sub.formattedExpiryDate}'
                                        : (sub.isGracePeriod
                                            ? 'Grace period active - Renew now'
                                            : 'Payment required to activate pass'))),
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => DealerPaymentHistoryModal.show(context),
                    icon: const Icon(LucideIcons.receipt, size: 14, color: Color(0xFFC4B5FD)),
                    label: Text(
                      'Invoices',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFC4B5FD)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 18),

              // Row 2: Listings & Leads Progress Bars
              Row(
                children: [
                  // Active Listings Limit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Listings',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
                            ),
                            Text(
                              '$activeListings / $listingLimit',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isAtLimit ? const Color(0xFFF87171) : (isNearLimit ? const Color(0xFFFBBF24) : Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: listingRatio,
                            minHeight: 7,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAtLimit ? const Color(0xFFEF4444) : (isNearLimit ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                            ),
                          ),
                        ),
                        if (isAtLimit)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Listing limit reached. Upgrade to add more properties.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF87171)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Leads Limit
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Buyer Leads',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
                            ),
                            Text(
                              '$leadsUsed / $leadLimit',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: leadRatio,
                            minHeight: 7,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (sub.isNone || !sub.isActive)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.crown, size: 14),
                      label: Text(
                        'View Plans',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else if (sub.tier == 'starter' || sub.isExpired || isNearLimit)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.zap, size: 14),
                      label: Text(
                        sub.isExpired ? 'Renew Subscription' : (sub.tier == 'starter' ? 'Upgrade to Pro' : 'Upgrade Plan'),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DealerSubscriptionPlansScreen()),
                        );
                      },
                      icon: const Icon(LucideIcons.settings, size: 14, color: Colors.white),
                      label: Text(
                        'Manage Subscription',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
