import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/everyday_utility_service.dart';
import 'package:dealghar_ncr_10x/services/global_search_service.dart';
import 'package:dealghar_ncr_10x/models/everyday_utility_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Everyday Utility Finance Calculations Tests', () {
    final service = EverydayUtilityService.instance;

    test('calculateHomeLoanEmi calculates mathematically correct EMI and interest', () {
      // Test case: 50 Lakhs loan at 8.5% for 20 years
      final result = service.calculateHomeLoanEmi(
        loanAmount: 5000000,
        interestRate: 8.50,
        tenureYears: 20,
      );

      // Standard EMI for ₹50L at 8.5% for 20 yrs is ~₹43,391
      expect(result.monthlyEmi, greaterThan(43000));
      expect(result.monthlyEmi, lessThan(44000));
      expect(result.totalPayment, greaterThan(5000000));
      expect(result.totalInterest, equals(result.totalPayment - 5000000));
      expect(result.principalPercentage + result.interestPercentage, closeTo(100.0, 0.01));
    });

    test('calculateAffordability applies 50% FOIR ceiling and computes budget', () {
      final result = service.calculateAffordability(
        monthlyIncome: 100000,
        existingEmis: 10000,
        downPayment: 1000000,
        interestRate: 8.50,
        tenureYears: 20,
      );

      // Max allowable EMI = 50,000 - 10,000 = 40,000
      expect(result.estimatedMaxEmi, equals(40000));
      expect(result.estimatedLoanAmount, greaterThan(4000000));
      expect(result.estimatedAffordablePropertyValue, equals(result.estimatedLoanAmount + 1000000));
    });

    test('calculateRentVsBuy evaluates 10-year wealth difference and break-even', () {
      final result = service.calculateRentVsBuy(
        monthlyRent: 25000,
        propertyPrice: 6000000,
        downPayment: 1200000,
        loanInterestRate: 8.50,
        loanTenureYears: 20,
        expectedPropertyAppreciationPercent: 6.0,
        expectedRentIncreasePercent: 5.0,
      );

      expect(result.estimatedTenYearRentCost, greaterThan(0));
      expect(result.estimatedTenYearPropertyValue, greaterThan(6000000));
      expect(result.breakEvenYears, inInclusiveRange(1, 10));
      expect(result.summary, isNotEmpty);
    });

    test('calculateStampDuty verifies UP, Delhi and provides fallback for unverified state', () {
      // UP (7%)
      final upResult = service.calculateStampDuty(
        state: 'Uttar Pradesh (Noida)',
        propertyType: 'Residential',
        propertyValue: 5000000,
      );
      expect(upResult.isVerified, isTrue);
      expect(upResult.stampDutyPercent, equals(7.0));
      expect(upResult.stampDutyAmount, equals(350000));

      // Delhi (6%)
      final delhiResult = service.calculateStampDuty(
        state: 'Delhi NCT',
        propertyType: 'Residential',
        propertyValue: 5000000,
      );
      expect(delhiResult.isVerified, isTrue);
      expect(delhiResult.stampDutyPercent, equals(6.0));
      expect(delhiResult.stampDutyAmount, equals(300000));

      // Unverified State
      final unverified = service.calculateStampDuty(
        state: 'Unknown State',
        propertyType: 'Residential',
        propertyValue: 5000000,
      );
      expect(unverified.isVerified, isFalse);
      expect(unverified.source, contains('Rate requires verification'));
    });

    test('calculatePropertyRoi evaluates rental yields and capital gains', () {
      final result = service.calculatePropertyRoi(
        purchasePrice: 10000000, // 1 Cr
        downPayment: 2000000,
        loanAmount: 8000000,
        monthlyRent: 40000,
        annualExpenses: 40000,
        expectedAppreciationRate: 6.0,
        holdingPeriodYears: 5,
      );

      // Gross rent = 4.8L, gross yield = 4.8%
      expect(result.grossRentalYieldPercent, closeTo(4.8, 0.01));
      expect(result.netOperatingIncome, equals(480000 - 40000));
      expect(result.estimatedFutureValue, greaterThan(10000000));
      expect(result.annualizedRoiPercent, greaterThan(0));
    });

    test('assessHomeLoanReadiness produces valid tiers without claiming bank approval', () {
      final strongProfile = service.assessHomeLoanReadiness(
        monthlyIncome: 200000,
        existingEmis: 10000,
        employmentType: 'Salaried Professional',
        downPayment: 2000000,
        desiredPrice: 8000000,
        creditScore: 780,
      );

      expect(strongProfile.tier, equals(LoanReadinessTier.strong));
      expect(strongProfile.title, equals('Strong Readiness'));
      expect(strongProfile.positiveFactors, isNotEmpty);
    });

    test('calculateInteriorCost and calculateRenovationCost return category breakdowns', () {
      final interior = service.calculateInteriorCost(propertySizeSqft: 1500, finishLevel: 'Standard');
      expect(interior.estimatedTotalCost, equals(1500 * 1500));
      expect(interior.categoryBreakdown.containsKey('Modular Kitchen'), isTrue);

      final reno = service.calculateRenovationCost(areaSqft: 1000, renovationScope: 'Partial Upgrade');
      expect(reno.estimatedTotalBudget, equals(1000 * 1100));
      expect(reno.roomBreakdown.containsKey('Tiling & Flooring'), isTrue);
    });
  });

  group('Global Search Everyday Utility Coverage Tests', () {
    final searchService = GlobalSearchService.instance;

    test('Query "EMI" returns Home Loan EMI Calculator', () {
      final results = searchService.search('EMI');
      expect(results.any((item) => item.id == 'emi_calculator'), isTrue);
    });

    test('Query "loan" returns Home Loan, Property Loan, EMI Calculator, Readiness', () {
      final results = searchService.search('loan');
      expect(results.any((item) => item.id == 'emi_calculator'), isTrue);
      expect(results.any((item) => item.id == 'home_loan_readiness'), isTrue);
    });

    test('Query "credit" returns Credit Score Center', () {
      final results = searchService.search('credit');
      expect(results.any((item) => item.id == 'credit_score_center'), isTrue);
    });

    test('Query "budget" returns Home Affordability Calculator', () {
      final results = searchService.search('budget');
      expect(results.any((item) => item.id == 'home_affordability'), isTrue);
    });

    test('Query "rent" returns Rent vs Buy Calculator', () {
      final results = searchService.search('rent');
      expect(results.any((item) => item.id == 'rent_vs_buy'), isTrue);
    });

    test('Query "ROI" returns Property ROI Calculator', () {
      final results = searchService.search('ROI');
      expect(results.any((item) => item.id == 'property_roi'), isTrue);
    });

    test('Query "Noida" returns Noida City Intelligence', () {
      final results = searchService.search('Noida');
      expect(results.any((item) => item.id == 'city_intelligence'), isTrue);
    });

    test('Query "metro" returns Connectivity Explorer', () {
      final results = searchService.search('metro');
      expect(results.any((item) => item.id == 'connectivity_explorer'), isTrue);
    });

    test('Query "Goa" returns Goa Destination Guide', () {
      final results = searchService.search('Goa');
      expect(results.any((item) => item.id == 'explore_india_goa'), isTrue);
    });

    test('Query "weekend" returns Weekend Getaways', () {
      final results = searchService.search('weekend');
      expect(results.any((item) => item.id == 'weekend_getaways'), isTrue);
    });

    test('Query "interior" returns Interior Cost Calculator', () {
      final results = searchService.search('interior');
      expect(results.any((item) => item.id == 'interior_cost_calculator'), isTrue);
    });

    test('Query "vastu" returns Vastu Tool', () {
      final results = searchService.search('vastu');
      expect(results.any((item) => item.id == 'vastu_tool'), isTrue);
    });

    test('Query "checklist" returns Property Document Checklist', () {
      final results = searchService.search('checklist');
      expect(results.any((item) => item.id == 'document_checklist'), isTrue);
    });
  });
}
