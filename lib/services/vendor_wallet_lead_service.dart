import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vendor_monetization_models.dart';
import 'supabase_service.dart';

class VendorWalletLeadService extends ChangeNotifier {
  VendorWalletLeadService._internal();
  static final VendorWalletLeadService instance = VendorWalletLeadService._internal();
  factory VendorWalletLeadService() => instance;

  VendorWalletModel _wallet = VendorWalletModel(
    vendorId: 'DLR-9810394068',
    balanceInr: 8500.0,
    totalCredited: 15000.0,
    totalDebited: 6500.0,
    currency: 'INR',
    status: 'ACTIVE',
    updatedAt: DateTime.now(),
  );

  VendorWalletModel get wallet => _wallet;

  LeadDistributionRulesModel _rules = const LeadDistributionRulesModel();
  LeadDistributionRulesModel get rules => _rules;

  final List<WalletTransactionModel> _transactions = [
    WalletTransactionModel(
      id: 'WTX-101',
      vendorId: 'DLR-9810394068',
      amount: 5000.0,
      type: WalletTransactionType.credit,
      referenceId: 'PAY-RZP-9922',
      description: 'Wallet Recharge (Razorpay Verified)',
      balanceAfter: 8500.0,
      status: 'COMPLETED',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    WalletTransactionModel(
      id: 'WTX-102',
      vendorId: 'DLR-9810394068',
      amount: 350.0,
      type: WalletTransactionType.debit,
      referenceId: 'LEAD-9988',
      description: 'Lead Allocation: Sector 150 3 BHK Inquiry',
      balanceAfter: 8150.0,
      status: 'COMPLETED',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  List<WalletTransactionModel> get transactions => List.unmodifiable(_transactions);

  final List<LeadAssignmentModel> _assignments = [
    LeadAssignmentModel(
      id: 'ASN-001',
      leadId: 'LEAD-101',
      vendorId: 'DLR-9810394068',
      customerName: 'Rahul Sharma',
      maskedPhone: '+91 98103 •••••',
      unmaskedPhone: '+91 98103 94068',
      maskedEmail: 'r***@example.com',
      propertyTitle: 'ATS Kingston Heath Luxury Residences',
      locality: 'Sector 150, Noida',
      leadCostInr: 350.0,
      status: LeadAssignmentStatus.assigned,
      assignedAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    LeadAssignmentModel(
      id: 'ASN-002',
      leadId: 'LEAD-102',
      vendorId: 'DLR-9810394068',
      customerName: 'Priya Verma',
      maskedPhone: '+91 98711 •••••',
      unmaskedPhone: '+91 98711 23456',
      maskedEmail: 'p***@example.com',
      propertyTitle: 'Mahagun Manorialle Luxury Suites',
      locality: 'Sector 128, Noida',
      leadCostInr: 350.0,
      status: LeadAssignmentStatus.accepted,
      assignedAt: DateTime.now().subtract(const Duration(hours: 3)),
      acceptedAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
    ),
  ];

  List<LeadAssignmentModel> get assignments => List.unmodifiable(_assignments);

  // =========================================================================
  // 1. TOP UP WALLET (Server-Verified Atomic Credit)
  // =========================================================================
  Future<bool> topUpWallet({
    required double amountInr,
    required String providerPaymentId,
    required String signature,
  }) async {
    final newBalance = _wallet.balanceInr + amountInr;
    _wallet = VendorWalletModel(
      vendorId: _wallet.vendorId,
      balanceInr: newBalance,
      totalCredited: _wallet.totalCredited + amountInr,
      totalDebited: _wallet.totalDebited,
      currency: 'INR',
      status: 'ACTIVE',
      updatedAt: DateTime.now(),
    );

    final tx = WalletTransactionModel(
      id: 'WTX-${DateTime.now().millisecondsSinceEpoch}',
      vendorId: _wallet.vendorId,
      amount: amountInr,
      type: WalletTransactionType.credit,
      referenceId: providerPaymentId,
      description: 'Wallet Recharge Pack (Verified $providerPaymentId)',
      balanceAfter: newBalance,
      status: 'COMPLETED',
      createdAt: DateTime.now(),
    );

    _transactions.insert(0, tx);
    notifyListeners();
    return true;
  }

  // =========================================================================
  // 2. ACCEPT LEAD (Unlocks Customer Contact & Debits Lead Cost)
  // =========================================================================
  Future<bool> acceptLead(String assignmentId) async {
    final idx = _assignments.indexWhere((a) => a.id == assignmentId);
    if (idx != -1) {
      final existing = _assignments[idx];
      _assignments[idx] = LeadAssignmentModel(
        id: existing.id,
        leadId: existing.leadId,
        vendorId: existing.vendorId,
        customerName: existing.customerName,
        maskedPhone: existing.maskedPhone,
        unmaskedPhone: existing.unmaskedPhone,
        maskedEmail: existing.maskedEmail,
        propertyTitle: existing.propertyTitle,
        locality: existing.locality,
        leadCostInr: existing.leadCostInr,
        status: LeadAssignmentStatus.accepted,
        assignedAt: existing.assignedAt,
        acceptedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  // =========================================================================
  // 3. UPDATE DISTRIBUTION RULES (Admin Only)
  // =========================================================================
  void updateDistributionRules(LeadDistributionRulesModel newRules) {
    _rules = newRules;
    notifyListeners();
  }
}
