import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/vendor_monetization_models.dart';
import '../services/vendor_wallet_lead_service.dart';
import '../theme/app_theme.dart';

class VendorWalletDashboardScreen extends StatefulWidget {
  const VendorWalletDashboardScreen({super.key});

  @override
  State<VendorWalletDashboardScreen> createState() => _VendorWalletDashboardScreenState();
}

class _VendorWalletDashboardScreenState extends State<VendorWalletDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VendorWalletLeadService _service = VendorWalletLeadService.instance;
  bool _isRecharging = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRecharge(double amount) async {
    setState(() => _isRecharging = true);
    await Future.delayed(const Duration(milliseconds: 900));
    await _service.topUpWallet(
      amountInr: amount,
      providerPaymentId: 'RZP-${DateTime.now().millisecondsSinceEpoch}',
      signature: 'sig_verified_hash',
    );
    if (mounted) {
      setState(() => _isRecharging = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('₹ ${amount.toStringAsFixed(0)} credited to Vendor Wallet!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final wallet = _service.wallet;
        final assignments = _service.assignments;
        final transactions = _service.transactions;

        return Scaffold(
          backgroundColor: AppTheme.pageBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Text(
              'Vendor Wallet & Lead CRM',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryViolet,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryViolet,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(LucideIcons.target, size: 18), text: 'Assigned Leads'),
                Tab(icon: Icon(LucideIcons.receipt, size: 18), text: 'Wallet Statement'),
              ],
            ),
          ),
          body: Column(
            children: [
              // 1. Wallet Header Banner
              _buildWalletHeader(wallet),

              // 2. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeadsTab(assignments),
                    _buildTransactionsTab(transactions),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletHeader(VendorWalletModel wallet) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVAILABLE LEAD BALANCE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('₹ ${wallet.balanceInr.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.emeraldSuccess.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('PRO DEALER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentEmerald)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isRecharging ? null : () => _handleRecharge(2000),
                  child: const Text('+ ₹2,000', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isRecharging ? null : () => _handleRecharge(5000),
                  child: const Text('+ ₹5,000', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldSuccess,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isRecharging ? null : () => _handleRecharge(10000),
                  child: _isRecharging
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('+ ₹10,000', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeadsTab(List<LeadAssignmentModel> assignments) {
    if (assignments.isEmpty) {
      return Center(child: Text('No assigned leads yet.', style: GoogleFonts.inter(color: AppTheme.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: assignments.length,
      itemBuilder: (context, idx) {
        final a = assignments[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: AppTheme.softCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(a.customerName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: a.status == LeadAssignmentStatus.accepted ? AppTheme.emeraldSuccess.withOpacity(0.15) : AppTheme.primaryViolet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(a.status.dbValue, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: a.status == LeadAssignmentStatus.accepted ? AppTheme.emeraldSuccess : AppTheme.primaryViolet)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(a.propertyTitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
              Text('Locality: ${a.locality} | Lead Cost: ₹${a.leadCostInr.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(a.effectivePhone, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: a.isCustomerContactUnlocked ? AppTheme.emeraldSuccess : AppTheme.textPrimary)),
                    ],
                  ),
                  if (!a.isCustomerContactUnlocked)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.unlock, size: 14, color: Colors.white),
                      label: const Text('Unlock Contact', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => _service.acceptLead(a.id),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldSuccess,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.phoneCall, size: 14, color: Colors.white),
                      label: const Text('Call Customer', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {},
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(List<WalletTransactionModel> transactions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: transactions.length,
      itemBuilder: (context, idx) {
        final tx = transactions[idx];
        final isCredit = tx.type == WalletTransactionType.credit;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCredit ? AppTheme.emeraldSuccess.withOpacity(0.12) : AppTheme.coralDanger.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight, size: 18, color: isCredit ? AppTheme.emeraldSuccess : AppTheme.coralDanger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.description, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('${tx.id} • Balance after: ₹${tx.balanceAfter.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              Text(
                '${isCredit ? "+" : "-"} ₹${tx.amount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: isCredit ? AppTheme.emeraldSuccess : AppTheme.coralDanger),
              ),
            ],
          ),
        );
      },
    );
  }
}
