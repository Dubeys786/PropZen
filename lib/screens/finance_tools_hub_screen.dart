import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/everyday_utility_models.dart';
import '../services/everyday_utility_service.dart';
import 'property_search_screen.dart';

class FinanceToolsHubScreen extends StatefulWidget {
  final int initialTabIndex;

  const FinanceToolsHubScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FinanceToolsHubScreen> createState() => _FinanceToolsHubScreenState();
}

class _FinanceToolsHubScreenState extends State<FinanceToolsHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EverydayUtilityService _service = EverydayUtilityService.instance;

  // 1. EMI State
  double _emiLoanAmount = 5000000; // 50 Lakhs
  double _emiInterestRate = 8.50;
  int _emiTenureYears = 20;

  // 2. Affordability State
  double _affordIncome = 150000; // 1.5 Lakhs/mo
  double _affordExistingEmis = 20000;
  double _affordDownPayment = 1500000; // 15 Lakhs
  final double _affordInterestRate = 8.50;
  final int _affordTenureYears = 20;

  // 3. Rent vs Buy State
  double _rvbRent = 30000;
  double _rvbPrice = 7500000;
  final double _rvbDownPayment = 1500000;
  final double _rvbInterestRate = 8.50;
  final int _rvbTenureYears = 20;
  final double _rvbAppreciation = 6.0;
  final double _rvbRentIncrease = 5.0;

  // 4. Stamp Duty State
  String _selectedState = 'Uttar Pradesh (Noida)';
  final String _stampPropertyType = 'Residential Apartment';
  double _stampPropertyValue = 6500000;

  // 5. Property ROI State
  double _roiPrice = 8000000;
  final double _roiDownPayment = 1600000;
  final double _roiLoanAmount = 6400000;
  double _roiRent = 32000;
  final double _roiAnnualExpenses = 35000;
  final double _roiAppreciation = 6.5;
  int _roiHoldingYears = 5;

  final List<String> _states = [
    'Uttar Pradesh (Noida)',
    'Delhi NCT',
    'Haryana (Gurgaon)',
    'Maharashtra (Mumbai)',
    'Karnataka (Bangalore)',
    'Rajasthan (Jaipur)',
    'Other State (Verify)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹ ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹ ${(amount / 100000).toStringAsFixed(2)} L';
    } else {
      return '₹ ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
  }

  void _navigateToPropertiesForEmi(double emiAmount, double loanAmount) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PropertySearchScreen(
          title: 'Properties around ${_formatCurrency(loanAmount * 1.25)}',
          initialQuery: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
          'PropZen Finance Calculators',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF7C3AED),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Home Loan EMI'),
                Tab(text: 'Affordability'),
                Tab(text: 'Rent vs Buy'),
                Tab(text: 'Stamp Duty'),
                Tab(text: 'Property ROI'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmiCalculatorTab(isDesktop),
          _buildAffordabilityTab(isDesktop),
          _buildRentVsBuyTab(isDesktop),
          _buildStampDutyTab(isDesktop),
          _buildPropertyRoiTab(isDesktop),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: HOME LOAN EMI
  // ===========================================================================
  Widget _buildEmiCalculatorTab(bool isDesktop) {
    final emiResult = _service.calculateHomeLoanEmi(
      loanAmount: _emiLoanAmount,
      interestRate: _emiInterestRate,
      tenureYears: _emiTenureYears,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _buildEmiControlsCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _buildEmiResultsCard(emiResult)),
                  ],
                )
              : Column(
                  children: [
                    _buildEmiControlsCard(),
                    const SizedBox(height: 20),
                    _buildEmiResultsCard(emiResult),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmiControlsCard() {
    return Container(
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
          Text(
            'Loan Parameters',
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust the loan amount, interest rate and duration to estimate your monthly commitment.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 22),

          // 1. Loan Amount
          _buildSliderRow(
            label: 'Loan Amount',
            valueFormatted: _formatCurrency(_emiLoanAmount),
            value: _emiLoanAmount,
            min: 500000,
            max: 50000000,
            divisions: 99,
            onChanged: (v) => setState(() => _emiLoanAmount = v),
          ),
          const SizedBox(height: 20),

          // 2. Interest Rate
          _buildSliderRow(
            label: 'Interest Rate (% p.a.)',
            valueFormatted: '${_emiInterestRate.toStringAsFixed(2)}%',
            value: _emiInterestRate,
            min: 6.5,
            max: 15.0,
            divisions: 85,
            onChanged: (v) => setState(() => _emiInterestRate = v),
          ),
          const SizedBox(height: 20),

          // 3. Tenure
          _buildSliderRow(
            label: 'Loan Tenure',
            valueFormatted: '$_emiTenureYears Years',
            value: _emiTenureYears.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => setState(() => _emiTenureYears = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmiResultsCard(EmiCalculationResult result) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Loan Repayment',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(result.monthlyEmi),
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          _buildBreakdownRow('Principal Loan Amount', _formatCurrency(result.loanAmount), const Color(0xFF0F172A)),
          const SizedBox(height: 10),
          _buildBreakdownRow('Total Interest Payable', _formatCurrency(result.totalInterest), const Color(0xFFEF4444)),
          const SizedBox(height: 10),
          _buildBreakdownRow('Total Amount Payable', _formatCurrency(result.totalPayment), const Color(0xFF0F172A), isBold: true),

          const SizedBox(height: 20),

          // Principal vs Interest Visual Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: result.principalPercentage.round().clamp(1, 99),
                  child: Container(height: 10, color: const Color(0xFF7C3AED)),
                ),
                Expanded(
                  flex: result.interestPercentage.round().clamp(1, 99),
                  child: Container(height: 10, color: const Color(0xFFF97316)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Principal: ${result.principalPercentage.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              Text('Interest: ${result.interestPercentage.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _emiLoanAmount = 5000000;
                    _emiInterestRate = 8.50;
                    _emiTenureYears = 20;
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Reset', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToPropertiesForEmi(result.monthlyEmi, result.loanAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.home, size: 16, color: Colors.white),
                  label: Text('View Properties in Budget', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: AFFORDABILITY
  // ===========================================================================
  Widget _buildAffordabilityTab(bool isDesktop) {
    final result = _service.calculateAffordability(
      monthlyIncome: _affordIncome,
      existingEmis: _affordExistingEmis,
      downPayment: _affordDownPayment,
      interestRate: _affordInterestRate,
      tenureYears: _affordTenureYears,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home Affordability Calculator',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find out how much property you can comfortably afford based on your monthly income and savings.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 22),

                    _buildSliderRow(
                      label: 'Net Monthly Income',
                      valueFormatted: _formatCurrency(_affordIncome),
                      value: _affordIncome,
                      min: 30000,
                      max: 1000000,
                      divisions: 97,
                      onChanged: (v) => setState(() => _affordIncome = v),
                    ),
                    const SizedBox(height: 18),

                    _buildSliderRow(
                      label: 'Existing Monthly EMIs',
                      valueFormatted: _formatCurrency(_affordExistingEmis),
                      value: _affordExistingEmis,
                      min: 0,
                      max: 300000,
                      divisions: 60,
                      onChanged: (v) => setState(() => _affordExistingEmis = v),
                    ),
                    const SizedBox(height: 18),

                    _buildSliderRow(
                      label: 'Available Down Payment',
                      valueFormatted: _formatCurrency(_affordDownPayment),
                      value: _affordDownPayment,
                      min: 200000,
                      max: 20000000,
                      divisions: 99,
                      onChanged: (v) => setState(() => _affordDownPayment = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Results
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.checkCircle2, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 8),
                        Text('Estimated Affordable Property Budget', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(result.estimatedAffordablePropertyValue),
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF15803D)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Max Affordable Loan: ${_formatCurrency(result.estimatedLoanAmount)} • Max Monthly EMI: ${_formatCurrency(result.estimatedMaxEmi)}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF166534), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Note: ${result.note}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 3: RENT VS BUY
  // ===========================================================================
  Widget _buildRentVsBuyTab(bool isDesktop) {
    final result = _service.calculateRentVsBuy(
      monthlyRent: _rvbRent,
      propertyPrice: _rvbPrice,
      downPayment: _rvbDownPayment,
      loanInterestRate: _rvbInterestRate,
      loanTenureYears: _rvbTenureYears,
      expectedPropertyAppreciationPercent: _rvbAppreciation,
      expectedRentIncreasePercent: _rvbRentIncrease,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rent vs Buy 10-Year Comparison', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Compare 10-year financial outcomes between renting and building long-term equity through ownership.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 22),

                    _buildSliderRow(
                      label: 'Current Monthly Rent',
                      valueFormatted: _formatCurrency(_rvbRent),
                      value: _rvbRent,
                      min: 10000,
                      max: 200000,
                      divisions: 95,
                      onChanged: (v) => setState(() => _rvbRent = v),
                    ),
                    const SizedBox(height: 18),

                    _buildSliderRow(
                      label: 'Target Property Price',
                      valueFormatted: _formatCurrency(_rvbPrice),
                      value: _rvbPrice,
                      min: 2500000,
                      max: 50000000,
                      divisions: 95,
                      onChanged: (v) => setState(() => _rvbPrice = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('10-Year Outlook Summary', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    _buildBreakdownRow('10-Year Total Rent Paid', _formatCurrency(result.estimatedTenYearRentCost), const Color(0xFFEF4444)),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Estimated Future Property Value', _formatCurrency(result.estimatedTenYearPropertyValue), const Color(0xFF10B981)),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Net Equity Advantage of Buying', _formatCurrency(result.estimatedNetWealthDifference), const Color(0xFF7C3AED), isBold: true),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                      child: Text(result.summary, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 4: STAMP DUTY
  // ===========================================================================
  Widget _buildStampDutyTab(bool isDesktop) {
    final result = _service.calculateStampDuty(
      state: _selectedState,
      propertyType: _stampPropertyType,
      propertyValue: _stampPropertyValue,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stamp Duty & Registration Calculator', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Check government registry charges and stamp duties verified by state revenue departments.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    // State Dropdown
                    Text('Select State / Territory', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedState,
                          isExpanded: true,
                          items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.inter(fontSize: 13.5)))).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedState = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildSliderRow(
                      label: 'Property Agreement Value',
                      valueFormatted: _formatCurrency(_stampPropertyValue),
                      value: _stampPropertyValue,
                      min: 1000000,
                      max: 50000000,
                      divisions: 98,
                      onChanged: (v) => setState(() => _stampPropertyValue = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Results
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Government Charges', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    _buildBreakdownRow('Stamp Duty (${result.stampDutyPercent.toStringAsFixed(1)}%)', _formatCurrency(result.stampDutyAmount), const Color(0xFF0F172A)),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Registration Fees (${result.registrationPercent.toStringAsFixed(1)}%)', _formatCurrency(result.registrationAmount), const Color(0xFF0F172A)),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Total Registry Charges', _formatCurrency(result.totalGovernmentCharges), const Color(0xFF7C3AED), isBold: true),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: result.isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: result.isVerified ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Icon(result.isVerified ? LucideIcons.shieldCheck : LucideIcons.alertCircle, size: 16, color: result.isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${result.source} (Verified: ${result.lastVerifiedAt})',
                              style: GoogleFonts.inter(fontSize: 11.5, color: result.isVerified ? const Color(0xFF166534) : const Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 5: PROPERTY ROI
  // ===========================================================================
  Widget _buildPropertyRoiTab(bool isDesktop) {
    final result = _service.calculatePropertyRoi(
      purchasePrice: _roiPrice,
      downPayment: _roiDownPayment,
      loanAmount: _roiLoanAmount,
      monthlyRent: _roiRent,
      annualExpenses: _roiAnnualExpenses,
      expectedAppreciationRate: _roiAppreciation,
      holdingPeriodYears: _roiHoldingYears,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property ROI & Rental Yield Calculator', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('Estimate rental yields, capital appreciation, and overall investment returns over your target holding period.', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                    const SizedBox(height: 20),

                    _buildSliderRow(
                      label: 'Purchase Price',
                      valueFormatted: _formatCurrency(_roiPrice),
                      value: _roiPrice,
                      min: 2000000,
                      max: 50000000,
                      divisions: 96,
                      onChanged: (v) => setState(() => _roiPrice = v),
                    ),
                    const SizedBox(height: 18),

                    _buildSliderRow(
                      label: 'Expected Monthly Rental Income',
                      valueFormatted: _formatCurrency(_roiRent),
                      value: _roiRent,
                      min: 5000,
                      max: 250000,
                      divisions: 98,
                      onChanged: (v) => setState(() => _roiRent = v),
                    ),
                    const SizedBox(height: 18),

                    _buildSliderRow(
                      label: 'Holding Period (Years)',
                      valueFormatted: '$_roiHoldingYears Years',
                      value: _roiHoldingYears.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (v) => setState(() => _roiHoldingYears = v.round()),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Results
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Investment Yields', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    _buildBreakdownRow('Gross Rental Yield', '${result.grossRentalYieldPercent.toStringAsFixed(2)}% p.a.', const Color(0xFF10B981), isBold: true),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Net Rental Yield (after maintenance)', '${result.netRentalYieldPercent.toStringAsFixed(2)}% p.a.', const Color(0xFF0F172A)),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Future Estimated Property Value', _formatCurrency(result.estimatedFutureValue), const Color(0xFF7C3AED), isBold: true),
                    const SizedBox(height: 10),
                    _buildBreakdownRow('Estimated Total Returns (Capital + Rent)', _formatCurrency(result.estimatedTotalReturn), const Color(0xFF0F172A)),

                    const SizedBox(height: 16),
                    Text('Disclaimer: Estimates for analytical purposes only. Not financial or investment advice.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // COMMON HELPER WIDGETS
  // ===========================================================================
  Widget _buildSliderRow({
    required String label,
    required String valueFormatted,
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

  Widget _buildBreakdownRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color)),
      ],
    );
  }
}
