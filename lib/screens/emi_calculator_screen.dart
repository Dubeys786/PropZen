import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/enquiry_auth_dialog.dart';

class EmiCalculatorScreen extends StatefulWidget {
  const EmiCalculatorScreen({super.key});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  double _propertyPrice = 5000000;
  double _downPayment = 1000000;
  double _interestRate = 8.50;
  double _loanTenureYears = 20;

  double get _loanAmount => max(0, _propertyPrice - _downPayment);

  double get _monthlyEmi {
    if (_loanAmount <= 0) return 0;
    final r = (_interestRate / 12) / 100;
    final n = _loanTenureYears * 12;
    final emi = _loanAmount * r * (pow(1 + r, n) / (pow(1 + r, n) - 1));
    return emi.isNaN || emi.isInfinite ? 0 : emi;
  }

  double get _totalPayment => _monthlyEmi * _loanTenureYears * 12;
  double get _totalInterest => max(0, _totalPayment - _loanAmount);

  String _formatCurrency(double val) {
    if (val >= 10000000) {
      return '₹ ${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return '₹ ${(val / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹ ${val.toStringAsFixed(0)}';
    }
  }

  void _onCheckEligibility() {
    EnquiryAuthDialog.show(
      context,
      actionLabel: 'Check Home Loan Eligibility',
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Home Loan Eligibility Request Received! Our loan partner will assist you with zero processing fee.'),
            backgroundColor: AppTheme.emeraldSuccess,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          'Loan Calculator',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderLight),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.home, color: AppTheme.primaryViolet, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Home Loan EMI Assistant', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('Compare plans & calculate monthly EMI accurately.', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Property Price Slider
            _buildSliderSection(
              label: 'Property Price',
              valueDisplay: _formatCurrency(_propertyPrice),
              value: _propertyPrice,
              min: 1000000,
              max: 30000000,
              divisions: 58,
              onChanged: (val) => setState(() {
                _propertyPrice = val;
                if (_downPayment > _propertyPrice) _downPayment = _propertyPrice * 0.2;
              }),
            ),

            const SizedBox(height: 18),

            // Down Payment Slider
            _buildSliderSection(
              label: 'Down Payment',
              valueDisplay: _formatCurrency(_downPayment),
              value: _downPayment,
              min: 200000,
              max: _propertyPrice,
              divisions: 50,
              onChanged: (val) => setState(() => _downPayment = val),
            ),

            const SizedBox(height: 18),

            // Loan Amount Display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Loan Amount', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                  Text(_formatCurrency(_loanAmount), style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Interest Rate Slider
            _buildSliderSection(
              label: 'Interest Rate (p.a.)',
              valueDisplay: '${_interestRate.toStringAsFixed(2)} %',
              value: _interestRate,
              min: 7.0,
              max: 14.0,
              divisions: 70,
              onChanged: (val) => setState(() => _interestRate = val),
            ),

            const SizedBox(height: 18),

            // Loan Tenure Slider
            _buildSliderSection(
              label: 'Loan Tenure',
              valueDisplay: '${_loanTenureYears.toInt()} Years',
              value: _loanTenureYears,
              min: 5,
              max: 30,
              divisions: 25,
              onChanged: (val) => setState(() => _loanTenureYears = val),
            ),

            const SizedBox(height: 24),

            // Calculated EMI Result Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.4), width: 1.5),
                boxShadow: AppTheme.softCardShadow,
              ),
              child: Column(
                children: [
                  Text('Calculated Monthly EMI', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Text(
                    '₹ ${_monthlyEmi.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / month',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryViolet),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Total Interest', _formatCurrency(_totalInterest)),
                      Container(width: 1, height: 30, color: AppTheme.borderLight),
                      _buildSummaryItem('Total Payable', _formatCurrency(_totalPayment)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Check Eligibility Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onCheckEligibility,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Text(
                  'Check Eligibility',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Top Bank Offers Table
            Text(
              'Partner Bank Rates',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildBankRow('State Bank of India (SBI)', '8.40%', 'Zero Processing Fee'),
            _buildBankRow('HDFC Bank', '8.50%', 'Instant Pre-approval'),
            _buildBankRow('ICICI Bank', '8.60%', 'Special Women Buyer Rate'),
            _buildBankRow('Axis Bank', '8.75%', 'Up to 90% Financing'),

            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required String valueDisplay,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            Text(valueDisplay, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.primaryViolet,
          inactiveColor: AppTheme.borderLight,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildBankRow(String bankName, String rate, String perk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bankName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              Text(perk, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.emeraldSuccess)),
            ],
          ),
          Text(rate, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
        ],
      ),
    );
  }
}
