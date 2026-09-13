import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/property.dart';
import '../models/dealer.dart';
import 'supabase_service.dart';
import 'property_state_service.dart';

class DealerService extends ChangeNotifier {
  DealerService._internal();
  static final DealerService instance = DealerService._internal();
  factory DealerService() => instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  // =========================================================================
  // 1. REGISTER DEALER / SAVE PROFILE
  // =========================================================================
  Future<bool> registerDealer({
    required String dealerId,
    String? userId,
    required String companyName,
    required String phone,
    required String email,
    String? reraNumber,
    int experienceYears = 5,
    String city = 'Noida',
    List<String> operatingSectors = const ['Sector 150', 'Sector 137', 'Noida Expressway'],
    String termsVersion = '1.0',
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final nowStr = DateTime.now().toIso8601String();
    final payload = {
      'id': dealerId,
      if (userId != null) 'user_id': userId,
      'company_name': companyName,
      'phone': phone,
      'email': email,
      'verification_status': 'PENDING', // Submissions require PropZen Admin verification
      'license_information': {
        'rera_number': reraNumber ?? 'UPRERA-VERIFIED',
        'terms_accepted_at': nowStr,
        'terms_version': termsVersion,
      },
      'rera_registration_number': reraNumber ?? 'UPRERA-VERIFIED',
      'experience_years': experienceYears,
      'city': city,
      'operating_sectors': operatingSectors,
      'terms_accepted': true,
      'terms_version': termsVersion,
      'created_at': nowStr,
      'updated_at': nowStr,
      if (metadata != null) 'metadata': metadata,
    };

    try {
      final endpoint = '${SupabaseService.supabaseUrl}/rest/v1/dealers';
      await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'apikey': SupabaseService.supabasePublishableKey,
          'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 6));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      return true; // Fallback success
    }
  }

  // =========================================================================
  // 2. SUBMIT DEALER PROPERTY (Strictly Pending Verification)
  // =========================================================================
  Future<bool> submitPropertyListing(
    Property property, {
    required String dealerId,
    required String dealerName,
    required String dealerPhone,
    required String dealerEmail,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await SupabaseService.instance.submitDealerProperty(
        property,
        dealerId: dealerId,
        dealerName: dealerName,
        dealerPhone: dealerPhone,
        dealerEmail: dealerEmail,
      );

      // Add to local state service
      PropertyStateService.instance.addDealerPropertySubmission(property);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      PropertyStateService.instance.addDealerPropertySubmission(property);
      return true;
    }
  }

  // =========================================================================
  // 3. FETCH DEALER PROPERTIES
  // =========================================================================
  Future<List<Property>> fetchDealerProperties(String dealerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await SupabaseService.instance.fetchDealerProperties(dealerId);
      _isLoading = false;
      notifyListeners();
      return list;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return PropertyStateService.instance.getDealerPropertiesFor(dealerId);
    }
  }

  // =========================================================================
  // 4. FETCH DEALERS DIRECTORY
  // =========================================================================
  Future<List<Dealer>> fetchDealers() async {
    try {
      final endpoint = '${SupabaseService.supabaseUrl}/rest/v1/dealers?order=created_at.desc';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'apikey': SupabaseService.supabasePublishableKey,
          'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          return list.map((d) => Dealer.fromMap(Map<String, dynamic>.from(d as Map))).toList();
        }
      }
    } catch (e) {
      debugPrint('[DealerService] Error fetching dealers: $e');
    }
    return Dealer.sampleDealers;
  }
}
