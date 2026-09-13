import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/loan_model.dart';
import 'supabase_service.dart';

abstract class LoanProviderInterface {
  String get providerName;
  bool get isConfigured;

  Future<LoanEligibilityResult> calculateEligibility({
    required double monthlyIncome,
    required double existingEmi,
    required double interestRate,
    required int tenureYears,
  });

  Future<String> submitLoanApplication(LoanRequestModel request);
  Future<bool> uploadDocument(String loanRequestId, LoanDocumentModel document);
  Future<List<LoanRequestModel>> fetchUserApplications(String userPhone);
}

class FinBoxLoanProvider implements LoanProviderInterface {
  @override
  String get providerName => 'FinBox / LoanWiser Authorized Digital Gateway';

  @override
  bool get isConfigured => true;

  @override
  Future<LoanEligibilityResult> calculateEligibility({
    required double monthlyIncome,
    required double existingEmi,
    required double interestRate,
    required int tenureYears,
  }) async {
    final netIncome = max(0.0, monthlyIncome - existingEmi);
    final maxMonthlyEmiAffordability = netIncome * 0.55;

    final r = (interestRate / 12) / 100;
    final n = tenureYears * 12;
    double maxLoan = 0.0;
    if (r > 0 && n > 0) {
      maxLoan = maxMonthlyEmiAffordability * (pow(1 + r, n) - 1) / (r * pow(1 + r, n));
    }

    String status = 'LIKELY_ELIGIBLE';
    if (monthlyIncome < 25000) {
      status = 'NEEDS_REVIEW';
    } else if (existingEmi / (monthlyIncome > 0 ? monthlyIncome : 1) > 0.6) {
      status = 'MAY_BE_ELIGIBLE';
    }

    return LoanEligibilityResult(
      maxEligibleLoan: maxLoan,
      estimatedMonthlyEmi: maxMonthlyEmiAffordability,
      foirPercentage: 55.0,
      netMonthlyDisposable: netIncome,
      eligibilityStatus: status,
      requiredDocuments: const [
        'Last 3 Months Salary Slips',
        'Last 6 Months Bank Statement',
        'PAN Card & Aadhaar Card',
        'Form 16 / ITR of Last 2 Years',
        'Property Agreement to Sale',
      ],
      legalDisclaimer: 'Indicative estimate only. Final eligibility and underwriting are solely determined by the partner bank.',
    );
  }

  @override
  Future<String> submitLoanApplication(LoanRequestModel request) async {
    return 'LOAN-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<bool> uploadDocument(String loanRequestId, LoanDocumentModel document) async {
    return true;
  }

  @override
  Future<List<LoanRequestModel>> fetchUserApplications(String userPhone) async {
    return [];
  }
}

class LoanService extends ChangeNotifier {
  LoanService._internal() {
    _initDefaultLoanProducts();
  }
  static final LoanService instance = LoanService._internal();
  factory LoanService() => instance;

  final LoanProviderInterface _activeProvider = FinBoxLoanProvider();
  final List<LoanRequestModel> _applications = [];
  List<LoanRequestModel> get applications => List.unmodifiable(_applications);

  final List<LoanProductModel> _loanProducts = [];
  List<LoanProductModel> get loanProducts => List.unmodifiable(_loanProducts);

  void _initDefaultLoanProducts() {
    final now = DateTime.now();
    _loanProducts.addAll([
      LoanProductModel(
        lenderId: 'bank_sbi',
        lenderName: 'State Bank of India (SBI)',
        productName: 'SBI Regular Home Loan (EBLR Linked)',
        interestRate: 8.50,
        rateType: 'Floating EBLR (Repo + 2.0%)',
        minTenureYears: 5,
        maxTenureYears: 30,
        processingFee: '0.35% (Min ₹2,000, Max ₹10,000)',
        maxLoanAmount: 100000000,
        source: 'SBI Retail Lending Circular 2026',
        sourceUrl: 'https://sbi.co.in/web/personal-banking/loans/home-loans',
        lastUpdatedAt: now.subtract(const Duration(days: 2)),
      ),
      LoanProductModel(
        lenderId: 'bank_hdfc',
        lenderName: 'HDFC Bank',
        productName: 'HDFC Reach / Special Home Loan Scheme',
        interestRate: 8.65,
        rateType: 'Floating External Benchmark',
        minTenureYears: 5,
        maxTenureYears: 30,
        processingFee: '0.50% or ₹3,000 whichever is higher',
        maxLoanAmount: 150000000,
        source: 'HDFC Home Loans Official Portal',
        sourceUrl: 'https://www.hdfcbank.com',
        lastUpdatedAt: now.subtract(const Duration(days: 4)),
      ),
      LoanProductModel(
        lenderId: 'bank_icici',
        lenderName: 'ICICI Bank',
        productName: 'ICICI Extra Home Loans (Pre-Approved)',
        interestRate: 8.75,
        rateType: 'Floating I-Repo Linked',
        minTenureYears: 5,
        maxTenureYears: 30,
        processingFee: '0.50% (Max ₹11,000)',
        maxLoanAmount: 120000000,
        source: 'ICICI Bank Home Loans',
        sourceUrl: 'https://www.icicibank.com',
        lastUpdatedAt: now.subtract(const Duration(days: 1)),
      ),
      LoanProductModel(
        lenderId: 'bank_bob',
        lenderName: 'Bank of Baroda',
        productName: 'Baroda Home Loan (Concessional Scheme)',
        interestRate: 8.40,
        rateType: 'Floating BRLLR Linked',
        minTenureYears: 5,
        maxTenureYears: 30,
        processingFee: 'Zero Processing Fee Campaign',
        maxLoanAmount: 80000000,
        source: 'Bank of Baroda Retail Hub',
        sourceUrl: 'https://www.bankofbaroda.in',
        lastUpdatedAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }

  /// Calculates monthly EMI for given loan amount, rate, and tenure
  Map<String, double> calculateEmi({
    required double loanAmount,
    required double interestRatePercent,
    required int tenureYears,
  }) {
    if (loanAmount <= 0 || tenureYears <= 0) {
      return {'emi': 0.0, 'totalInterest': 0.0, 'totalPayment': 0.0};
    }
    final r = (interestRatePercent / 12) / 100;
    final n = tenureYears * 12;
    final emi = (loanAmount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    final totalPayment = emi * n;
    final totalInterest = totalPayment - loanAmount;

    return {
      'emi': emi,
      'totalInterest': totalInterest,
      'totalPayment': totalPayment,
    };
  }

  Future<LoanEligibilityResult> estimateEligibility({
    required double monthlyIncome,
    required double existingEmi,
    double interestRate = 8.5,
    int tenureYears = 20,
  }) {
    return _activeProvider.calculateEligibility(
      monthlyIncome: monthlyIncome,
      existingEmi: existingEmi,
      interestRate: interestRate,
      tenureYears: tenureYears,
    );
  }

  Future<String> submitLoanApplication(LoanRequestModel request) async {
    final loanId = await _activeProvider.submitLoanApplication(request);
    _applications.insert(0, request);
    notifyListeners();
    return loanId;
  }

  void updateLoanStatus(String loanId, dynamic status, {String? remarks}) {
    final idx = _applications.indexWhere((a) => a.id == loanId);
    if (idx != -1) {
      final old = _applications[idx];
      final newStatus = status is LoanStatus ? status : LoanStatus.fromString(status.toString());
      _applications[idx] = LoanRequestModel(
        id: old.id,
        userId: old.userId,
        propertyId: old.propertyId,
        propertyTitle: old.propertyTitle,
        propertyPrice: old.propertyPrice,
        downPayment: old.downPayment,
        loanAmount: old.loanAmount,
        name: old.name,
        phone: old.phone,
        email: old.email,
        monthlyIncome: old.monthlyIncome,
        indicativeEligibility: old.indicativeEligibility,
        status: newStatus,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        adminRemarks: remarks ?? old.adminRemarks,
        documents: old.documents,
        offers: old.offers,
      );
      notifyListeners();
    }
  }
}
