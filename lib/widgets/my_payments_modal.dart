import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/payment_record_model.dart';
import '../services/nri_subscription_service.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_theme.dart';

/// Modal for Viewing User's Payment History & Invoices
class MyPaymentsModal extends StatefulWidget {
  const MyPaymentsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MyPaymentsModal(),
    );
  }

  @override
  State<MyPaymentsModal> createState() => _MyPaymentsModalState();
}

class _MyPaymentsModalState extends State<MyPaymentsModal> {
  final NriSubscriptionService _service = NriSubscriptionService.instance;
  bool _isLoading = true;
  List<PaymentRecord> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final userId = UserSession.fullName.isNotEmpty ? UserSession.fullName : 'usr_nri_client';
    final list = await _service.getPaymentHistory(userId);
    setState(() {
      _payments = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: 700,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.receipt, color: AppTheme.primaryViolet, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Payments & Invoices',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          'Verified Razorpay transaction history',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
                : _payments.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) => _buildPaymentItem(_payments[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(LucideIcons.creditCard, size: 36, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Payment Records Found',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Any subscription pass payments or renewals made through Razorpay will appear here with downloadable invoices.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(PaymentRecord p) {
    Color statusBg;
    Color statusText;
    IconData statusIcon;

    if (p.isSuccess) {
      statusBg = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF16A34A);
      statusIcon = LucideIcons.checkCircle;
    } else if (p.isFailed) {
      statusBg = const Color(0xFFFEE2E2);
      statusText = const Color(0xFFDC2626);
      statusIcon = LucideIcons.xCircle;
    } else if (p.isRefunded) {
      statusBg = const Color(0xFFE0E7FF);
      statusText = const Color(0xFF4F46E5);
      statusIcon = LucideIcons.rotateCcw;
    } else {
      statusBg = const Color(0xFFFEF3C7);
      statusText = const Color(0xFFD97706);
      statusIcon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                p.planName,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusText),
                    const SizedBox(width: 4),
                    Text(
                      p.status.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: statusText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${p.formattedDate}',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
              ),
              Text(
                p.formattedAmount,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Payment ID: ${p.id}',
                    style: GoogleFonts.robotoMono(fontSize: 10, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.isSuccess)
                  InkWell(
                    onTap: () => _showReceiptDialog(p),
                    child: Text(
                      'View Receipt',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(PaymentRecord p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Color(0xFF16A34A), size: 24),
            const SizedBox(width: 8),
            Text('Payment Receipt', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _receiptRow('Item', p.planName),
            _receiptRow('Amount', p.formattedAmount),
            _receiptRow('Provider', 'Razorpay Secure'),
            _receiptRow('Status', 'VERIFIED SUCCESS ✓'),
            _receiptRow('Payment ID', p.id),
            _receiptRow('Order ID', p.orderId),
            _receiptRow('Transaction ID', p.transactionId ?? 'TXN-RZP-${DateTime.now().millisecondsSinceEpoch}'),
            _receiptRow('Date', p.formattedDate),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.poppins(color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
