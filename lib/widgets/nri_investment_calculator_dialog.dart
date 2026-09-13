import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/property.dart';
import '../models/nri_subscription_model.dart';
import '../theme/app_theme.dart';

/// NRI Property Investment, Yield & Cash Flow Calculator
class NriInvestmentCalculatorDialog extends StatefulWidget {
  final Property property;

  const NriInvestmentCalculatorDialog({
    super.key,
    required this.property,
  });

  static Future<void> show(BuildContext context, {required Property property}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => NriInvestmentCalculatorDialog(property: property),
    );
  }

  @override
  State<NriInvestmentCalculatorDialog> createState() => _NriInvestmentCalculatorDialogState();
}

class _NriInvestmentCalculatorDialogState extends State<NriInvestmentCalculatorDialog> {
  late double _propertyPrice;
  double _downPaymentPercent = 20.0;
  double _interestRatePercent = 8.5;
  int _loanTenureYears = 20;
  double _expectedMonthlyRent = 35000.0;
  int _holdingPeriodYears = 5;

  @override
  void initState() {
    super.initState();
    _propertyPrice = widget.property.askingPriceCr > 0
        ? widget.property.askingPriceCr * 10000000
        : 8500000.0;

    // Estimate realistic rent based on property value
    _expectedMonthlyRent = (_propertyPrice * 0.045) / 12;
  }

  String _formatInr(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} Lakh';
    } else {
      return '₹${amount.round()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = NriInvestmentCalculation(
      propertyPrice: _propertyPrice,
      downPaymentPercent: _downPaymentPercent,
      interestRatePercent: _interestRatePercent,
      loanTenureYears: _loanTenureYears,
      expectedMonthlyRent: _expectedMonthlyRent,
      holdingPeriodYears: _holdingPeriodYears,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.calculator, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NRI Property Investment Calculator',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          widget.property.title,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFCBD5E1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white70, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Output Cards Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildMetricItem('Estimated EMI', '₹${calc.monthlyEmi.round()}/mo', Colors.cyanAccent),
                              _buildMetricItem('Gross Rental Yield', '${calc.grossRentalYield.toStringAsFixed(2)}%', Colors.greenAccent),
                            ],
                          ),
                          const Divider(height: 20, color: Colors.white24),
                          Row(
                            children: [
                              _buildMetricItem('Down Payment (20%)', _formatInr(calc.downPaymentAmount), Colors.white),
                              _buildMetricItem('Net Cash Flow / yr', '₹${calc.annualCashFlow.round()}', calc.annualCashFlow >= 0 ? Colors.greenAccent : Colors.orangeAccent),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sliders
                    _buildSlider(
                      label: 'Down Payment Percentage',
                      valueStr: '${_downPaymentPercent.toInt()}% (${_formatInr(calc.downPaymentAmount)})',
                      value: _downPaymentPercent,
                      min: 10,
                      max: 60,
                      divisions: 10,
                      onChanged: (v) => setState(() => _downPaymentPercent = v),
                    ),
                    const SizedBox(height: 12),

                    _buildSlider(
                      label: 'NRI Home Loan Interest Rate',
                      valueStr: '${_interestRatePercent.toStringAsFixed(1)}% p.a.',
                      value: _interestRatePercent,
                      min: 7.0,
                      max: 12.0,
                      divisions: 50,
                      onChanged: (v) => setState(() => _interestRatePercent = v),
                    ),
                    const SizedBox(height: 12),

                    _buildSlider(
                      label: 'Loan Tenure',
                      valueStr: '$_loanTenureYears Years',
                      value: _loanTenureYears.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      onChanged: (v) => setState(() => _loanTenureYears = v.toInt()),
                    ),
                    const SizedBox(height: 12),

                    _buildSlider(
                      label: 'Expected Monthly Rental Income',
                      valueStr: '₹${_expectedMonthlyRent.round()}/mo',
                      value: _expectedMonthlyRent,
                      min: 10000,
                      max: 200000,
                      divisions: 38,
                      onChanged: (v) => setState(() => _expectedMonthlyRent = v),
                    ),

                    const SizedBox(height: 20),

                    // Disclaimer Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.info, size: 15, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These are estimates based on the assumptions entered and are not financial advice. Rental yield and market appreciation vary by micro-location.',
                              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Done Exploring Yield', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String val, Color valColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueStr,
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
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text(valueStr, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryViolet,
            inactiveTrackColor: const Color(0xFFE2E8F0),
            thumbColor: AppTheme.primaryViolet,
            trackHeight: 3.0,
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
