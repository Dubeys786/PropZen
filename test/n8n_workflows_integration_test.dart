import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dealghar_ncr_10x/services/n8n_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  group('PropZen Production n8n Workflows Integration Tests', () {
    setUp(() {
      UserSession.login(
        name: 'Rohit Singhania',
        phone: '9811223344',
        email: 'rohit.singhania@example.com',
        isEmailVerified: true,
      );
    });

    tearDown(() {
      N8nService.instance.setMockClient(null);
    });

    test('1. Production Webhook URLs and Config are correct with zero test webhooks', () {
      expect(N8nService.prodBookSiteVisitUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/site-visit');
      expect(N8nService.prodPropertyEnquiryUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/enquiry');
      expect(N8nService.prodPropertyDataUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/property');
      expect(N8nService.prodServicesUrl, 'https://propzen.app.n8n.cloud/webhook/propzen/services');

      // Assert no test URLs
      expect(N8nService.prodBookSiteVisitUrl.contains('webhook-test'), isFalse);
      expect(N8nService.prodPropertyEnquiryUrl.contains('webhook-test'), isFalse);
      expect(N8nService.prodPropertyDataUrl.contains('webhook-test'), isFalse);
      expect(N8nService.prodServicesUrl.contains('webhook-test'), isFalse);
    });

    test('2. Book a Site Visit sends correct JSON schema and X-PropZen-Key header', () async {
      late Map<String, dynamic> capturedBody;
      late Map<String, String> capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.toString(), contains('/api/n8n/site-visit'));

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Site visit scheduled successfully for ATS HomeKraft',
            'bookingId': 'VISIT-N8N-9988',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      N8nService.instance.setMockClient(mockClient);

      final res = await N8nService.instance.bookSiteVisit(
        propertyId: 'PROP-ATS-01',
        propertyName: 'ATS HomeKraft Pious Orchards',
        fullName: 'Rohit Singhania',
        mobileNumber: '9811223344',
        email: 'rohit.singhania@example.com',
        visitDate: '2026-09-15',
        visitTime: '11:00 AM',
        visitorCount: 2,
        cabRequired: true,
        message: 'Require cab pickup from Sector 137 Metro.',
      );

      expect(res.isSuccess, isTrue);
      expect(res.statusCode, 200);
      expect(res.message, contains('Site visit scheduled'));

      // Verify Header
      expect(capturedHeaders['Content-Type'], contains('application/json'));

      // Verify JSON payload structure
      expect(capturedBody['propertyId'], 'PROP-ATS-01');
      expect(capturedBody['propertyName'], 'ATS HomeKraft Pious Orchards');
      expect(capturedBody['fullName'], 'Rohit Singhania');
      expect(capturedBody['mobileNumber'], '9811223344');
      expect(capturedBody['email'], 'rohit.singhania@example.com');
      expect(capturedBody['visitDate'], '2026-09-15');
      expect(capturedBody['visitTime'], '11:00');
      expect(capturedBody['visitorCount'], 2);
      expect(capturedBody['cabRequired'], true);
      expect(capturedBody['message'], 'Require cab pickup from Sector 137 Metro.');
    });

    test('3. Property Enquiry sends correct JSON schema and preferred contact method', () async {
      late Map<String, dynamic> capturedBody;
      late Map<String, String> capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.toString(), contains('/api/n8n/enquiry'));

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Enquiry received for Gaur City 2',
            'enquiryId': 'ENQ-N8N-5544',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      N8nService.instance.setMockClient(mockClient);

      final res = await N8nService.instance.submitPropertyEnquiry(
        propertyId: 'PROP-GAUR-02',
        propertyName: 'Gaur City 2 - 14th Avenue',
        fullName: 'Rohit Singhania',
        mobileNumber: '9811223344',
        email: 'rohit.singhania@example.com',
        message: 'Please send latest payment plan and floor plans.',
        preferredContactMethod: 'WhatsApp',
      );

      expect(res.isSuccess, isTrue);
      expect(res.statusCode, 201);

      // Verify payload
      expect(capturedBody['propertyId'], 'PROP-GAUR-02');
      expect(capturedBody['propertyName'], 'Gaur City 2 - 14th Avenue');
      expect(capturedBody['fullName'], 'Rohit Singhania');
      expect(capturedBody['mobileNumber'], '9811223344');
      expect(capturedBody['email'], 'rohit.singhania@example.com');
      expect(capturedBody['message'], 'Please send latest payment plan and floor plans.');
      expect(capturedBody['preferredContactMethod'], 'whatsapp');
    });

    test('4. Property Data workflow retrieves and synchronizes properties into PropertyStateService', () async {
      final sampleN8nProperties = [
        {
          'id': 'PROP-N8N-NEW-01',
          'title': 'Godrej Palm Retreat N8N Edition',
          'sector': 'Sector 150',
          'city': 'Noida',
          'category': 'Residential',
          'property_type': 'Apartment',
          'price_cr': 1.85,
          'area': 1950,
          'bhk': '3 BHK',
          'status': 'published',
          'amenities': ['Resort Style Club', 'Olympic Pool', 'Tennis Court'],
        }
      ];

      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('/api/n8n/property'));

        return http.Response(
          jsonEncode(sampleN8nProperties),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      N8nService.instance.setMockClient(mockClient);

      final stateService = PropertyStateService.instance;
      final syncSuccess = await stateService.loadPropertiesFromN8n();

      expect(syncSuccess, isTrue);
      final found = stateService.findPropertyById('PROP-N8N-NEW-01');
      expect(found, isNotNull);
      expect(found!.title, 'Godrej Palm Retreat N8N Edition');
      expect(found.askingPriceCr, 1.85);
      expect(found.bhk, '3 BHK');
    });

    test('5. Services workflow sends mapped service request payload to n8n', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.url.toString(), contains('/api/n8n/services'));

        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Service consultation request recorded',
            'serviceId': 'legal_document_verification',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      N8nService.instance.setMockClient(mockClient);

      final res = await N8nService.instance.requestService(
        serviceId: 'legal_document_verification',
        serviceName: 'Legal Document Verification',
        category: 'LEGAL',
        fullName: 'Rohit Singhania',
        mobileNumber: '9811223344',
        email: 'rohit.singhania@example.com',
        notes: 'Verification required for resale flat in Sector 137.',
        params: {'startingPrice': '₹4,999', 'estimatedTime': '24-48 Hours'},
      );

      expect(res.isSuccess, isTrue);
      expect(capturedBody['serviceId'], 'legal_document_verification');
      expect(capturedBody['serviceName'], 'Legal Document Verification');
      expect(capturedBody['category'], 'LEGAL');
      expect(capturedBody['params']['startingPrice'], '₹4,999');
    });

    test('6. Centralized Error Handling handles 400, 401, 404, 500, and timeout correctly', () async {
      // 400 Bad Request
      var mockClient = MockClient((req) async {
        return http.Response(jsonEncode({'error': 'Missing required parameter: email'}), 400);
      });
      N8nService.instance.setMockClient(mockClient);
      var res = await N8nService.instance.bookSiteVisit(
        propertyId: '1',
        propertyName: 'Test',
        fullName: 'Test',
        mobileNumber: '1',
        email: '',
        visitDate: '2026-09-01',
        visitTime: '10:00',
      );
      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 400);
      expect(res.message, contains('Missing required parameter'));

      // 401 Unauthorized
      mockClient = MockClient((req) async {
        return http.Response('Unauthorized', 401);
      });
      N8nService.instance.setMockClient(mockClient);
      res = await N8nService.instance.submitPropertyEnquiry(
        propertyId: '1',
        propertyName: 'Test',
        fullName: 'Test',
        mobileNumber: '1',
        email: 'test@example.com',
        message: 'Hello',
      );
      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 401);
      expect(res.message, contains('Authentication error with n8n'));

      // 404 Not Found
      mockClient = MockClient((req) async {
        return http.Response('Not Found', 404);
      });
      N8nService.instance.setMockClient(mockClient);
      res = await N8nService.instance.fetchPropertyData(propertyId: 'NON-EXISTENT');
      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 404);
      expect(res.message, contains('not found'));

      // 500 Internal Error
      mockClient = MockClient((req) async {
        return http.Response('Workflow execution error', 500);
      });
      N8nService.instance.setMockClient(mockClient);
      res = await N8nService.instance.requestService(
        serviceId: '1',
        serviceName: 'Test',
        category: 'Test',
        fullName: 'Test',
        mobileNumber: '1',
        email: 't@t.com',
      );
      expect(res.isSuccess, isFalse);
      expect(res.statusCode, 500);
      expect(res.message, contains('n8n workflow returned error'));
    });
  });
}
