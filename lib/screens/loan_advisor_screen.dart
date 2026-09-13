import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';
import '../theme/app_theme.dart';
import 'loan_application_wizard_screen.dart';

class LoanAdvisorScreen extends StatefulWidget {
  const LoanAdvisorScreen({super.key});

  @override
  State<LoanAdvisorScreen> createState() => _LoanAdvisorScreenState();
}

class _LoanAdvisorScreenState extends State<LoanAdvisorScreen> {
  final LoanService _loanService = LoanService.instance;

  // EMI Calculator Inputs
  double _loanAmount = 5000000;
  double _interestRate = 8.5;
  int _tenureYears = 20;

  // Eligibility Inputs
  final TextEditingController _incomeController = TextEditingController(text: '120000');
  final TextEditingController _existingEmiController = TextEditingController(text: '15000');
  LoanEligibilityResult? _eligibilityResult;

  // Track Application Input
  final TextEditingController _trackingPhoneController = TextEditingController();
  List<LoanRequestModel> _matchedRequests = [];
  bool _hasSearchedTracking = false;

  @override
  void initState() {
    super.initState();
    _recalculateEligibility();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _existingEmiController.dispose();
    _trackingPhoneController.dispose();
    super.dispose();
  }

  void _recalculateEligibility() {
    final income = double.tryParse(_incomeController.text.trim()) ?? 120000;
    final emi = double.tryParse(_existingEmiController.text.trim()) ?? 0;
    _loanService.estimateEligibility(monthlyIncome: income, existingEmi: emi).then((res) {
      if (mounted) setState(() => _eligibilityResult = res);
    });
  }

  void _trackLoan() {
    final phone = _trackingPhoneController.text.trim();
    final all = _loanService.applications;
    setState(() {
      _hasSearchedTracking = true;
      _matchedRequests = all.where((a) => a.phone.contains(phone) || a.id.contains(phone)).toList();
    });
  }

  String _formatCurrency(double val) {
    if (val >= 10000000) {
      return '₹ ${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '₹ ${(val / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹ ${val.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    final emiMap = _loanService.calculateEmi(
      loanAmount: _loanAmount,
      interestRatePercent: _interestRate,
      tenureYears: _tenureYears,
    );

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'PropZen Loan Advisor',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Overview Banner
            _buildHeroBanner(),

            const SizedBox(height: 24),

            // 2. Interactive EMI Calculator
            _buildEmiCalculatorCard(emiMap),

            const SizedBox(height: 24),

            // 3. Indicative Eligibility Estimator
            _buildEligibilityEstimatorCard(),

            const SizedBox(height: 24),

            // 4. Compare Benchmark Loan Options
            _buildBenchmarkRatesCard(),

            const SizedBox(height: 24),

            // 5. Track Loan Request
            _buildTrackLoanSection(),

            const SizedBox(height: 32),

            // 6. Application CTA
            _buildApplicationCta(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'PROPZEN HOME & PROPERTY LOAN DESK',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Multi-Lender Loan Assistance & Indicative Advisory',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Compare competitive home loan interest rates, calculate precise EMIs, and submit seamless loan applications with dedicated partner bank support.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.landmark, size: 36, color: AppTheme.accentEmerald),
          ),
        ],
      ),
    );
  }

  Widget _buildEmiCalculatorCard(Map<String, double> emiMap) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calculator, color: AppTheme.primaryViolet, size: 20),
              const SizedBox(width: 8),
              Text(
                'Interactive EMI Calculator',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Loan Amount Slider
          Text('Loan Amount: ${_formatCurrency(_loanAmount)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          Slider(
            value: _loanAmount,
            min: 1000000,
            max: 50000000,
            divisions: 49,
            activeColor: AppTheme.primaryViolet,
            onChanged: (v) => setState(() => _loanAmount = v),
          ),

          // Interest Rate Slider
          Text('Interest Rate: ${_interestRate.toStringAsFixed(2)}% p.a.', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          Slider(
            value: _interestRate,
            min: 6.5,
            max: 14.0,
            divisions: 75,
            activeColor: AppTheme.primaryViolet,
            onChanged: (v) => setState(() => _interestRate = v),
          ),

          // Tenure Slider
          Text('Tenure: $_tenureYears Years (${_tenureYears * 12} Months)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          Slider(
            value: _tenureYears.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppTheme.primaryViolet,
            onChanged: (v) => setState(() => _tenureYears = v.round()),
          ),

          const Divider(height: 24),

          // EMI Results
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('Monthly EMI', '₹ ${emiMap['monthly_emi']?.toStringAsFixed(0)}', AppTheme.primaryViolet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile('Total Interest', _formatCurrency(emiMap['total_interest'] ?? 0), AppTheme.coralDanger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile('Total Repayment', _formatCurrency(emiMap['total_repayment'] ?? 0), AppTheme.emeraldSuccess),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityEstimatorCard() {
    final el = _eligibilityResult;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: AppTheme.emeraldSuccess, size: 20),
              const SizedBox(width: 8),
              Text(
                'Indicative Eligibility Estimator',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monthly In-Hand Income (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => _recalculateEligibility(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _existingEmiController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Existing EMIs (₹)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (_) => _recalculateEligibility(),
                ),
              ),
            ],
          ),

          if (el != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated Eligible Loan:', style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
                      Text(_formatCurrency(el.maxEligibleLoan), style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Max Affordable Monthly EMI:', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                      Text('₹ ${el.estimatedMonthlyEmi.toStringAsFixed(0)} / mo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Indicative estimate only. Final eligibility and approval are determined by the lender.',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkRatesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benchmark Lender Interest Rates (Indicative)',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          _buildBankRow('State Bank of India (SBI)', '8.50% – 9.15%', '0.35% (Max ₹10,000)'),
          const Divider(height: 16),
          _buildBankRow('HDFC Bank', '8.70% – 9.40%', '0.50% (Min ₹3,000)'),
          const Divider(height: 16),
          _buildBankRow('ICICI Bank', '8.75% – 9.45%', '0.50% (Min ₹3,000)'),
          const Divider(height: 16),
          _buildBankRow('Bank of Baroda', '8.40% – 9.05%', 'Nil Special Offer'),
        ],
      ),
    );
  }

  Widget _buildTrackLoanSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.search, color: AppTheme.primaryViolet, size: 20),
              const SizedBox(width: 8),
              Text(
                'Track Loan Application Status',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _trackingPhoneController,
                  decoration: InputDecoration(
                    hintText: 'Enter Mobile Number or Loan Request ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _trackLoan,
                child: const Text('Track', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          if (_hasSearchedTracking) ...[
            const SizedBox(height: 16),
            if (_matchedRequests.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text('No active loan application found for this input. Please apply below.', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
              )
            else
              ..._matchedRequests.map((req) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(req.id, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: req.status == LoanStatus.approved ? AppTheme.emeraldSuccess.withOpacity(0.15) : AppTheme.primaryViolet.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(req.status.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: req.status == LoanStatus.approved ? AppTheme.emeraldSuccess : AppTheme.primaryViolet)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(req.propertyTitle, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text('Loan Amount: ${_formatCurrency(req.loanAmount)} | Tenure: ${req.preferredTenureYears} yrs', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                        if (req.adminRemarks != null && req.adminRemarks!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Bank Desk Note: ${req.adminRemarks}', style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black87)),
                        ],
                      ],
                    ),
                  )),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationCta() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryViolet,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
          label: Text('Apply for Home Loan Assistance', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoanApplicationWizardScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBankRow(String bankName, String rate, String fee) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(bankName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
        Text(rate, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
        const SizedBox(width: 16),
        Text(fee, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}
