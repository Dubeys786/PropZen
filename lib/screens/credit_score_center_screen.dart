import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/everyday_utility_models.dart';
import '../services/everyday_utility_service.dart';

class CreditScoreCenterScreen extends StatefulWidget {
  const CreditScoreCenterScreen({super.key});

  @override
  State<CreditScoreCenterScreen> createState() => _CreditScoreCenterScreenState();
}

class _CreditScoreCenterScreenState extends State<CreditScoreCenterScreen> {
  // Readiness assessment state
  double _income = 120000;
  double _existingEmis = 15000;
  final String _employmentType = 'Salaried Professional';
  double _downPayment = 1500000;
  double _desiredPrice = 7500000;
  int? _selfScore;

  final EverydayUtilityService _service = EverydayUtilityService.instance;

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹ ${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹ ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final readiness = _service.assessHomeLoanReadiness(
      monthlyIncome: _income,
      existingEmis: _existingEmis,
      employmentType: _employmentType,
      downPayment: _downPayment,
      desiredPrice: _desiredPrice,
      creditScore: _selfScore,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'PropZen Credit Score Center',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notice Banner: No Fake Scores
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.info, size: 20, color: Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Official credit-score integration coming soon. PropZen does not generate simulated or fabricated credit scores. All assessments are transparent educational estimates.',
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Interactive Readiness Tool
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(LucideIcons.shieldCheck, color: Color(0xFF7C3AED), size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Are You Ready for a Home Loan?', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                Text('Educational readiness analysis based on your debt-to-income ratio and down payment.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      _buildSliderRow('Monthly Income', _formatCurrency(_income), _income, 30000, 1000000, 97, (v) => setState(() => _income = v)),
                      const SizedBox(height: 16),
                      _buildSliderRow('Existing Monthly EMIs', _formatCurrency(_existingEmis), _existingEmis, 0, 300000, 60, (v) => setState(() => _existingEmis = v)),
                      const SizedBox(height: 16),
                      _buildSliderRow('Target Property Price', _formatCurrency(_desiredPrice), _desiredPrice, 2000000, 50000000, 96, (v) => setState(() => _desiredPrice = v)),
                      const SizedBox(height: 16),
                      _buildSliderRow('Available Down Payment', _formatCurrency(_downPayment), _downPayment, 200000, 20000000, 99, (v) => setState(() => _downPayment = v)),

                      const SizedBox(height: 20),

                      // Readiness Result Box
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: readiness.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: readiness.color.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  readiness.tier == LoanReadinessTier.strong ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                                  color: readiness.color,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  readiness.title,
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: readiness.color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(readiness.description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155))),
                            const SizedBox(height: 14),

                            if (readiness.positiveFactors.isNotEmpty) ...[
                              Text('Strengths:', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              ...readiness.positiveFactors.map((f) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.check, size: 14, color: Color(0xFF10B981)),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(f, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)))),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 8),
                            ],

                            if (readiness.improvementRecommendations.isNotEmpty) ...[
                              Text('Next Steps:', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                              const SizedBox(height: 4),
                              ...readiness.improvementRecommendations.map((r) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.arrowRight, size: 14, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(r, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)))),
                                      ],
                                    ),
                                  )),
                            ],

                            const SizedBox(height: 12),
                            Text(
                              'Educational estimate only. Does not constitute guaranteed loan sanction or bank approval.',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Credit Education Section
                Text(
                  'Credit Score Knowledge Center',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Understanding credit health before applying for a home loan.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),

                // 4 Score Ranges Cards
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _buildScoreRangeCard('750 - 900', 'Excellent', 'Lowest home loan interest rates and expedited approval.', const Color(0xFF10B981)),
                    _buildScoreRangeCard('700 - 749', 'Good', 'Eligible for competitive bank mortgage products.', const Color(0xFF0284C7)),
                    _buildScoreRangeCard('650 - 699', 'Fair', 'Standard loan terms, may require higher down payment.', const Color(0xFFF59E0B)),
                    _buildScoreRangeCard('300 - 649', 'Needs Work', 'High risk of rejection; credit repair recommended.', const Color(0xFFEF4444)),
                  ],
                ),

                const SizedBox(height: 24),

                // 5 Core Factors
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('5 Key Factors Influencing Your Credit Score', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 14),
                      _buildFactorItem('Repayment History (35%)', 'Consistent on-time EMI and card payments carry the largest weight.'),
                      _buildFactorItem('Credit Utilization (30%)', 'Keep credit card balances below 30% of your sanctioned credit limit.'),
                      _buildFactorItem('Credit History Length (15%)', 'Older, seasoned credit accounts showcase long-term reliability.'),
                      _buildFactorItem('Credit Mix (10%)', 'Healthy balance between secured (home loan) and unsecured credit.'),
                      _buildFactorItem('New Credit Inquiries (10%)', 'Avoid applying for multiple loans/cards in short succession.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRangeCard(String range, String tier, String desc, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(tier, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 8),
          Text(range, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text(desc, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildFactorItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, String valueFormatted, double value, double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155))),
            Text(valueFormatted, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7C3AED),
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: const Color(0xFF7C3AED),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
            trackHeight: 3.5,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
