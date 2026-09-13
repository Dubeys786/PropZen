import 'package:flutter/material.dart';

// =============================================================================
// 1. FINANCE & CALCULATOR MODELS
// =============================================================================

class EmiCalculationResult {
  final double loanAmount;
  final double annualInterestRate;
  final int tenureYears;
  final double monthlyEmi;
  final double totalInterest;
  final double totalPayment;
  final double principalPercentage;
  final double interestPercentage;

  const EmiCalculationResult({
    required this.loanAmount,
    required this.annualInterestRate,
    required this.tenureYears,
    required this.monthlyEmi,
    required this.totalInterest,
    required this.totalPayment,
    required this.principalPercentage,
    required this.interestPercentage,
  });
}

class AffordabilityResult {
  final double monthlyIncome;
  final double existingEmis;
  final double downPayment;
  final double estimatedAffordablePropertyValue;
  final double estimatedLoanAmount;
  final double estimatedMaxEmi;
  final double foirPercentage;
  final String note;

  const AffordabilityResult({
    required this.monthlyIncome,
    required this.existingEmis,
    required this.downPayment,
    required this.estimatedAffordablePropertyValue,
    required this.estimatedLoanAmount,
    required this.estimatedMaxEmi,
    required this.foirPercentage,
    this.note = 'Educational estimate based on standard 50% FOIR banking benchmarks.',
  });
}

class RentVsBuyResult {
  final double monthlyRent;
  final double propertyPrice;
  final double estimatedTenYearRentCost;
  final double estimatedTenYearBuyCost;
  final double estimatedTenYearPropertyValue;
  final double estimatedNetWealthDifference;
  final int breakEvenYears;
  final String summary;

  const RentVsBuyResult({
    required this.monthlyRent,
    required this.propertyPrice,
    required this.estimatedTenYearRentCost,
    required this.estimatedTenYearBuyCost,
    required this.estimatedTenYearPropertyValue,
    required this.estimatedNetWealthDifference,
    required this.breakEvenYears,
    required this.summary,
  });
}

class StampDutyResult {
  final String state;
  final String propertyType;
  final double propertyValue;
  final double stampDutyPercent;
  final double stampDutyAmount;
  final double registrationPercent;
  final double registrationAmount;
  final double totalGovernmentCharges;
  final String source;
  final String lastVerifiedAt;
  final bool isVerified;

  const StampDutyResult({
    required this.state,
    required this.propertyType,
    required this.propertyValue,
    required this.stampDutyPercent,
    required this.stampDutyAmount,
    required this.registrationPercent,
    required this.registrationAmount,
    required this.totalGovernmentCharges,
    required this.source,
    required this.lastVerifiedAt,
    required this.isVerified,
  });
}

class PropertyRoiResult {
  final double purchasePrice;
  final double grossAnnualRent;
  final double grossRentalYieldPercent;
  final double netOperatingIncome;
  final double netRentalYieldPercent;
  final double estimatedFutureValue;
  final double estimatedCapitalGain;
  final double estimatedTotalReturn;
  final double annualizedRoiPercent;

  const PropertyRoiResult({
    required this.purchasePrice,
    required this.grossAnnualRent,
    required this.grossRentalYieldPercent,
    required this.netOperatingIncome,
    required this.netRentalYieldPercent,
    required this.estimatedFutureValue,
    required this.estimatedCapitalGain,
    required this.estimatedTotalReturn,
    required this.annualizedRoiPercent,
  });
}

// =============================================================================
// 2. CREDIT & LOAN READINESS MODELS
// =============================================================================

enum LoanReadinessTier { strong, moderate, needsImprovement }

class HomeLoanReadinessResult {
  final LoanReadinessTier tier;
  final String title;
  final String description;
  final double estimatedMaxEmi;
  final double estimatedMaxLoan;
  final List<String> positiveFactors;
  final List<String> improvementRecommendations;
  final Color color;

  const HomeLoanReadinessResult({
    required this.tier,
    required this.title,
    required this.description,
    required this.estimatedMaxEmi,
    required this.estimatedMaxLoan,
    required this.positiveFactors,
    required this.improvementRecommendations,
    required this.color,
  });
}

// =============================================================================
// 3. CITY & AREA INTELLIGENCE MODELS
// =============================================================================

class CityIntelligenceModel {
  final String id;
  final String name;
  final String state;
  final String avgPricePerSqft;
  final String rentalYieldRange;
  final String metroStatus;
  final String airportConnectivity;
  final String overview;
  final List<String> topAreas;
  final List<String> majorEmploymentHubs;
  final String imageUrl;

  const CityIntelligenceModel({
    required this.id,
    required this.name,
    required this.state,
    required this.avgPricePerSqft,
    required this.rentalYieldRange,
    required this.metroStatus,
    required this.airportConnectivity,
    required this.overview,
    required this.topAreas,
    required this.majorEmploymentHubs,
    required this.imageUrl,
  });
}

class PropZenAreaScore {
  final double connectivity;
  final double lifestyle;
  final double healthcare;
  final double education;
  final double greenSpaces;
  final double infrastructure;
  final double investmentSignal;

  const PropZenAreaScore({
    required this.connectivity,
    required this.lifestyle,
    required this.healthcare,
    required this.education,
    required this.greenSpaces,
    required this.infrastructure,
    required this.investmentSignal,
  });

  double get overallScore =>
      ((connectivity * 0.20) +
          (lifestyle * 0.15) +
          (healthcare * 0.10) +
          (education * 0.15) +
          (greenSpaces * 0.15) +
          (infrastructure * 0.15) +
          (investmentSignal * 0.10));
}

class AreaIntelligenceModel {
  final String id;
  final String name;
  final String city;
  final String priceRange;
  final String rentalTrend;
  final PropZenAreaScore score;
  final String nearestMetro;
  final String nearestAirport;
  final String nearestExpressway;
  final List<String> topSchools;
  final List<String> topHospitals;
  final List<String> shoppingLifestyle;
  final String upcomingInfraHighlight;

  const AreaIntelligenceModel({
    required this.id,
    required this.name,
    required this.city,
    required this.priceRange,
    required this.rentalTrend,
    required this.score,
    required this.nearestMetro,
    required this.nearestAirport,
    required this.nearestExpressway,
    required this.topSchools,
    required this.topHospitals,
    required this.shoppingLifestyle,
    required this.upcomingInfraHighlight,
  });
}

class InfrastructureProjectModel {
  final String id;
  final String name;
  final String location;
  final String city;
  final String category; // 'Airport', 'Expressway', 'Metro', 'Rail / RRTS', 'Commercial'
  final String status; // 'Under Construction', 'Operational Phase 1', 'Sanctioned', 'Land Acquisition'
  final String expectedTimeline;
  final String source;
  final String? sourceUrl;
  final String lastVerifiedAt;
  final String summary;

  const InfrastructureProjectModel({
    required this.id,
    required this.name,
    required this.location,
    required this.city,
    required this.category,
    required this.status,
    required this.expectedTimeline,
    required this.source,
    this.sourceUrl,
    required this.lastVerifiedAt,
    required this.summary,
  });
}

// =============================================================================
// 4. TRAVEL & LIFESTYLE MODELS
// =============================================================================

class TravelDestinationModel {
  final String id;
  final String name;
  final String state;
  final String category; // 'Beach', 'Mountains', 'Heritage', 'Luxury', 'Wildlife', 'Spiritual'
  final String bestTime;
  final String startingBudget;
  final String overview;
  final String nearestAirport;
  final String nearestRailway;
  final String roadConnectivity;
  final List<String> topAttractions;
  final List<String> twoDayItinerary;
  final List<String> threeDayItinerary;
  final String imageUrl;

  const TravelDestinationModel({
    required this.id,
    required this.name,
    required this.state,
    required this.category,
    required this.bestTime,
    required this.startingBudget,
    required this.overview,
    required this.nearestAirport,
    required this.nearestRailway,
    required this.roadConnectivity,
    required this.topAttractions,
    required this.twoDayItinerary,
    required this.threeDayItinerary,
    required this.imageUrl,
  });
}

class WeekendGetawayModel {
  final String destination;
  final String fromCity;
  final int distanceKm;
  final double driveTimeHours;
  final String bestTransport;
  final String idealDuration;
  final String highlights;
  final String imageUrl;

  const WeekendGetawayModel({
    required this.destination,
    required this.fromCity,
    required this.distanceKm,
    required this.driveTimeHours,
    required this.bestTransport,
    required this.idealDuration,
    required this.highlights,
    required this.imageUrl,
  });
}

// =============================================================================
// 5. PROPERTY TOOLS MODELS
// =============================================================================

class InteriorCostResult {
  final double propertySizeSqft;
  final String finishLevel;
  final double estimatedTotalCost;
  final double ratePerSqft;
  final Map<String, double> categoryBreakdown;

  const InteriorCostResult({
    required this.propertySizeSqft,
    required this.finishLevel,
    required this.estimatedTotalCost,
    required this.ratePerSqft,
    required this.categoryBreakdown,
  });
}

class RenovationCostResult {
  final double areaSqft;
  final String renovationScope;
  final double estimatedTotalBudget;
  final Map<String, double> roomBreakdown;

  const RenovationCostResult({
    required this.areaSqft,
    required this.renovationScope,
    required this.estimatedTotalBudget,
    required this.roomBreakdown,
  });
}
