import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/loan_model.dart';
import '../models/service_request_model.dart';
import '../services/loan_service.dart';
import '../services/service_partner_service.dart';
import 'user_profile_screen.dart';
import '../theme/app_theme.dart';

class LoanApplicationWizardScreen extends StatefulWidget {
  final String? prefillPropertyTitle;
  final double? prefillPropertyPrice;

  const LoanApplicationWizardScreen({
    super.key,
    this.prefillPropertyTitle,
    this.prefillPropertyPrice,
  });

  @override
  State<LoanApplicationWizardScreen> createState() => _LoanApplicationWizardScreenState();
}

class _LoanApplicationWizardScreenState extends State<LoanApplicationWizardScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String _generatedLoanId = '';

  // Form Controllers - Personal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Noida');

  // Form Controllers - Employment
  String _employmentType = 'Salaried';
  final TextEditingController _incomeController = TextEditingController(text: '120000');
  final TextEditingController _existingEmiController = TextEditingController(text: '0');

  // Form Controllers - Property & Loan
  late TextEditingController _propertyTitleController;
  late TextEditingController _propertyPriceController;
  late TextEditingController _downPaymentController;
  late TextEditingController _loanAmountController;
  int _tenureYears = 20;
  String _preferredLender = 'State Bank of India (SBI)';

  // Documents checklist
  final List<String> _uploadedDocs = [];

  @override
  void initState() {
    super.initState();
    final price = widget.prefillPropertyPrice ?? 8500000;
    final down = price * 0.20;
    final loan = price - down;

    _propertyTitleController = TextEditingController(text: widget.prefillPropertyTitle ?? 'ATS Kingston Heath 3 BHK');
    _propertyPriceController = TextEditingController(text: price.toStringAsFixed(0));
    _downPaymentController = TextEditingController(text: down.toStringAsFixed(0));
    _loanAmountController = TextEditingController(text: loan.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _incomeController.dispose();
    _existingEmiController.dispose();
    _propertyTitleController.dispose();
    _propertyPriceController.dispose();
    _downPaymentController.dispose();
    _loanAmountController.dispose();
    super.dispose();
  }

  void _recalculateLoan() {
    final price = double.tryParse(_propertyPriceController.text.trim()) ?? 0;
    final down = double.tryParse(_downPaymentController.text.trim()) ?? 0;
    final loan = price - down;
    _loanAmountController.text = loan.toStringAsFixed(0);
  }

  Future<void> _submitApplication() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Name and Contact Phone.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final loanAmt = double.tryParse(_loanAmountController.text.trim()) ?? 5000000;
    final income = double.tryParse(_incomeController.text.trim()) ?? 120000;
    final price = double.tryParse(_propertyPriceController.text.trim()) ?? 8500000;
    final down = double.tryParse(_downPaymentController.text.trim()) ?? 1700000;

    final request = LoanRequestModel(
      id: 'LOAN-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_active',
      propertyTitle: _propertyTitleController.text.trim(),
      propertyPrice: price,
      downPayment: down,
      loanAmount: loanAmt,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      city: _cityController.text.trim(),
      employmentType: _employmentType,
      monthlyIncome: income,
      preferredTenureYears: _tenureYears,
      preferredLender: _preferredLender,
      indicativeEligibility: income * 50,
      status: LoanStatus.newRequest,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final loanId = await LoanService.instance.submitLoanApplication(request);

    try {
      await ServicePartnerService.instance.createServiceRequest(
        category: ServiceCategoryType.loan,
        subCategory: 'Home Loan Consultation',
        title: 'Home Loan Request - ${_propertyTitleController.text}',
        description: 'Preferred Lender: $_preferredLender, Loan Amount: ₹${_loanAmountController.text}, Tenure: $_tenureYears years',
        propertyTitle: _propertyTitleController.text,
        propertyPriceCr: (double.tryParse(_propertyPriceController.text) ?? 0.0) / 10000000,
        customerId: UserSession.userId.isNotEmpty ? UserSession.userId : UserSession.phone,
        customerName: _nameController.text.isNotEmpty ? _nameController.text : UserSession.fullName,
        customerPhone: _phoneController.text.isNotEmpty ? _phoneController.text : UserSession.phone,
        customerEmail: _emailController.text.isNotEmpty ? _emailController.text : UserSession.email,
        estimatedPrice: double.tryParse(_loanAmountController.text) ?? 0.0,
      );
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
        _generatedLoanId = loanId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Home Loan Application Wizard',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Step Progress Header
            _buildStepIndicator(),

            const SizedBox(height: 24),

            // Step Content
            if (_currentStep == 0) _buildPersonalStep(),
            if (_currentStep == 1) _buildEmploymentStep(),
            if (_currentStep == 2) _buildPropertyLoanStep(),
            if (_currentStep == 3) _buildDocumentsReviewStep(),

            const SizedBox(height: 32),

            // Navigation Buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal', 'Income', 'Loan Details', 'Review'];
    return Row(
      children: List.generate(steps.length, (idx) {
        final isActive = idx == _currentStep;
        final isPassed = idx < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPassed ? AppTheme.emeraldSuccess : (isActive ? AppTheme.primaryViolet : Colors.grey.shade300),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                      : Text('${idx + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  steps[idx],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? AppTheme.primaryViolet : AppTheme.textMuted),
                ),
              ),
              if (idx < steps.length - 1) Container(width: 12, height: 2, color: isPassed ? AppTheme.emeraldSuccess : Colors.grey.shade300),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPersonalStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1: Personal Contact Details', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name (as per PAN)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Current City', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2: Employment & Income Profile', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Salaried'),
                  selected: _employmentType == 'Salaried',
                  selectedColor: AppTheme.primaryViolet.withOpacity(0.15),
                  onSelected: (v) => setState(() => _employmentType = 'Salaried'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Self-Employed / Business'),
                  selected: _employmentType == 'Self-Employed',
                  selectedColor: AppTheme.primaryViolet.withOpacity(0.15),
                  onSelected: (v) => setState(() => _employmentType = 'Self-Employed'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Net Monthly In-Hand Income (₹)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _existingEmiController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Existing Monthly EMIs (₹) if any', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyLoanStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3: Property & Requested Loan Amount', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _propertyTitleController,
            decoration: const InputDecoration(labelText: 'Property Name / Project', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _propertyPriceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Total Property Cost (₹)', border: OutlineInputBorder()),
            onChanged: (_) => _recalculateLoan(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _downPaymentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Down Payment Contribution (₹)', border: OutlineInputBorder()),
            onChanged: (_) => _recalculateLoan(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _loanAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Requested Loan Amount (₹)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Preferred Tenure: $_tenureYears Years', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          Slider(
            value: _tenureYears.toDouble(),
            min: 5,
            max: 30,
            divisions: 25,
            activeColor: AppTheme.primaryViolet,
            onChanged: (v) => setState(() => _tenureYears = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsReviewStep() {
    final docs = ['PAN Card Copy', 'Aadhaar Card', 'Last 3 Months Salary Slips', 'Bank Statement (6 Months)'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4: Checklist & Review', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Upload or check the documents you have ready for fast-track processing:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          ...docs.map((d) {
            final isChecked = _uploadedDocs.contains(d);
            return CheckboxListTile(
              title: Text(d, style: GoogleFonts.inter(fontSize: 13)),
              value: isChecked,
              activeColor: AppTheme.primaryViolet,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _uploadedDocs.add(d);
                  } else {
                    _uploadedDocs.remove(d);
                  }
                });
              },
            );
          }),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 18, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your documents are encrypted and only shared with authorized partner banks for loan sanction.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryViolet,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                    } else {
                      _submitApplication();
                    }
                  },
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _currentStep == 3 ? 'Submit Loan Application' : 'Continue',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: const Icon(LucideIcons.checkCheck, size: 48, color: AppTheme.emeraldSuccess),
              ),
              const SizedBox(height: 20),
              Text('Loan Application Submitted!', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your Application ID is $_generatedLoanId', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
              const SizedBox(height: 12),
              Text(
                'Our partner bank desk will review your details and connect with you within 4 business hours with customized sanction options.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
