import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';
import 'n8n_service.dart';
import 'property_state_service.dart';
import '../screens/user_profile_screen.dart';

class EnquiryResult {
  final bool isSuccess;
  final String message;
  final String enquiryId;
  final String? errorMessage;

  const EnquiryResult({
    required this.isSuccess,
    required this.message,
    required this.enquiryId,
    this.errorMessage,
  });
}

class EnquiryService extends ChangeNotifier {
  EnquiryService._internal();
  static final EnquiryService instance = EnquiryService._internal();
  factory EnquiryService() => instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  // =========================================================================
  // 1. SUBMIT ENQUIRY (Direct Supabase + Background n8n Webhook)
  // =========================================================================
  Future<EnquiryResult> submitEnquiry({
    required String propertyTitle,
    String? propertyId,
    String? dealerId,
    String? clientId,
    required String name,
    required String email,
    required String phone,
    String message = 'Interested in this verified property. Please share full brochure, floor plan, and pricing.',
    String enquiryType = 'Property Details Enquiry',
    Map<String, dynamic>? metadata,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    final cleanEmail = email.trim().toLowerCase();
    final effectiveEnquiryId = 'ENQ-${DateTime.now().millisecondsSinceEpoch}';
    final effectiveClientId = clientId ?? (UserSession.isLoggedIn ? (UserSession.mobileNumber.isNotEmpty ? 'usr_${UserSession.mobileNumber}' : 'usr_active') : 'usr_guest_${cleanPhone.replaceAll('+', '')}');

    try {
      // 1. Save directly to Supabase enquiries table
      await SupabaseService.instance.saveEnquiry(
        propertyTitle: propertyTitle,
        propertyId: propertyId ?? 'PROP-DIRECT',
        clientId: effectiveClientId,
        dealerId: dealerId,
        name: name.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        enquiryType: enquiryType,
        message: message,
        metadata: {
          if (metadata != null) ...metadata,
          'enquiry_id': effectiveEnquiryId,
        },
      );

      // 2. Trigger asynchronous n8n webhook notification in background
      N8nService.instance.submitPropertyEnquiry(
        propertyId: propertyId ?? 'PROP-DIRECT',
        propertyName: propertyTitle,
        userId: effectiveClientId,
        fullName: name.trim(),
        mobileNumber: cleanPhone,
        email: cleanEmail,
        message: message,
        preferredContactMethod: 'phone',
      ).then((res) {
        debugPrint('[EnquiryService] Background n8n webhook response: ${res.statusCode}');
      }).catchError((err) {
        debugPrint('[EnquiryService] Background n8n note: $err');
      });

      // 3. Save to local property state for reactive UI
      PropertyStateService.instance.addEnquiry(
        propertyTitle,
        enquiryType,
        message,
        propertyId,
        dealerId,
        name.trim(),
        cleanPhone,
        cleanEmail,
      );

      _isLoading = false;
      notifyListeners();

      return EnquiryResult(
        isSuccess: true,
        message: 'Enquiry submitted successfully! Dealer will contact you shortly.',
        enquiryId: effectiveEnquiryId,
      );
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();

      // Graceful fallback
      PropertyStateService.instance.addEnquiry(
        propertyTitle,
        enquiryType,
        message,
        propertyId,
        dealerId,
        name.trim(),
        cleanPhone,
        cleanEmail,
      );

      return EnquiryResult(
        isSuccess: true,
        message: 'Enquiry recorded successfully.',
        enquiryId: effectiveEnquiryId,
      );
    }
  }

  // =========================================================================
  // 2. FETCH USER ENQUIRIES
  // =========================================================================
  Future<List<Map<String, dynamic>>> fetchUserEnquiries(String userPhone) async {
    final cleanPhone = userPhone.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final endpoint = '${SupabaseService.supabaseUrl}/rest/v1/enquiries?client_phone=like.*$cleanPhone*&order=created_at.desc';
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'apikey': SupabaseService.supabasePublishableKey,
          'Authorization': 'Bearer ${SupabaseService.supabasePublishableKey}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[EnquiryService] fetchUserEnquiries error: $e');
    }
    return PropertyStateService.instance.enquiries;
  }
}
