import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/loan_model.dart';
import '../services/loan_service.dart';
import '../theme/app_theme.dart';
import 'loan_application_wizard_screen.dart';

class LoanComparisonScreen extends StatefulWidget {
  final double initialPrice;

  const LoanComparisonScreen({super.key, this.initialPrice = 10000000});

  @override
  State<LoanComparisonScreen> createState() => _LoanComparisonScreenState();
}

class _LoanComparisonScreenState extends State<LoanComparisonScreen> {
  final LoanService _loanService = LoanService.instance;

  late double _propertyPrice;
  double _downPaymentPercent = 20.0;
  int _tenureYears = 20;
  double _monthlyIncome = 150000;
  double _existingEmi = 15000;

  @override
  void initState() {
    super.initState();
    _propertyPrice = widget.initialPrice > 0 ? widget.initialPrice : 10000000;
  }

  double get _loanAmount => _propertyPrice * (1 - _downPaymentPercent / 100);

  @override
  Widget build(BuildContext context) {
    final products = _loanService.loanProducts;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Home Loan Comparison & Sanctions',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Calculator Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Interactive Loan Amount & Tenure Configurator', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Property Price: ₹${(_propertyPrice / 10000000).toStringAsFixed(2)} Cr', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Down Payment: ${_downPaymentPercent.toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                    ],
                  ),
                  Slider(
                    value: _downPaymentPercent,
                    min: 10,
                    max: 50,
                    divisions: 8,
                    activeColor: AppTheme.primaryViolet,
                    onChanged: (v) => setState(() => _downPaymentPercent = v),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Calculated Loan Required:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                      Text('₹${(_loanAmount / 100000).toStringAsFixed(1)} Lakh', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tenure: $_tenureYears Years', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${_tenureYears * 12} Months', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                  Slider(
                    value: _tenureYears.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 25,
                    activeColor: AppTheme.primaryViolet,
                    onChanged: (v) => setState(() => _tenureYears = v.toInt()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Indicative Disclaimers
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, size: 16, color: AppTheme.primaryViolet),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Indicative partner bank interest rates. Final sanction, rate type, and processing fees are determined by individual lending institutions.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryViolet),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text('Verified Partner Bank Loan Schemes', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),

            // 3. Bank Loan Cards
            ...products.map((prod) {
              final emiCalc = _loanService.calculateEmi(
                loanAmount: _loanAmount,
                interestRatePercent: prod.interestRate,
                tenureYears: _tenureYears,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(prod.lenderName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.emeraldSuccess.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${prod.interestRate}% p.a.',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldSuccess),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(prod.productName, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryViolet)),
                    Text(prod.rateType, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated Monthly EMI', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                            Text('₹${emiCalc['emi']!.toStringAsFixed(0)} / mo', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Processing Fee', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                            Text(prod.processingFee, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                            onPressed: () {
                              _loanService.estimateEligibility(monthlyIncome: _monthlyIncome, existingEmi: _existingEmi).then((res) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Eligibility Status: ${res.eligibilityStatus}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                    content: Text('Max estimated loan affordability: ₹${(res.maxEligibleLoan / 100000).toStringAsFixed(1)} Lakh with ₹${res.estimatedMonthlyEmi.toStringAsFixed(0)}/mo net disposable.'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                                  ),
                                );
                              });
                            },
                            child: const Text('Check Eligibility', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, padding: const EdgeInsets.symmetric(vertical: 8)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LoanApplicationWizardScreen(
                                    prefillPropertyPrice: _propertyPrice,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Apply Now', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
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
}
