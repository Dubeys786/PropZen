import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dealghar_ncr_10x/services/n8n_service.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

void main() {
  group('PropZen n8n Property Enquiry Integration Test Suite', () {
    final n8n = N8nService.instance;

    setUp(() {
      UserSession.login(
        fullName: 'Sakshi Sharma',
        mobile: '9810394068',
        email: 'sakshi@propzen.ai',
        isEmailVerified: true,
      );
    });

    test('1. Verified Webhook URLs and Endpoints', () {
      expect(N8nService.prodPropertyEnquiryUrl, equals('https://propzen.app.n8n.cloud/webhook/propzen/enquiry'));
      expect(N8nService.testPropertyEnquiryUrl, equals('https://propzen.app.n8n.cloud/webhook-test/propzen/enquiry'));
    });

    test('2. Submits Exact Required Payload Fields to n8n Webhook', () async {
      late Map<String, dynamic> receivedPayload;
      late Map<String, String> receivedHeaders;
      late Uri targetUri;

      final mockClient = MockClient((request) async {
        targetUri = request.url;
        receivedHeaders = request.headers;
        receivedPayload = jsonDecode(request.body);

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Enquiry submitted successfully',
            'data': {'enquiryId': 'enq_test_123'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      n8n.setMockClient(mockClient);

      final response = await n8n.submitPropertyEnquiry(
        propertyId: 'prop_dlf_camellias_001',
        propertyName: 'The Camellias, Golf Course Road',
        fullName: 'Sakshi Sharma',
        mobileNumber: '9810394068',
        email: 'sakshi@propzen.ai',
        message: 'I would like more information on 4 BHK layout and payment schedule.',
        preferredContactMethod: 'phone',
      );

      // Verify Response
      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      expect(response.message, contains('Enquiry submitted successfully'));

      // Verify Required Payload Keys (Snake Case & Camel Case)
      expect(receivedPayload['property_id'], equals('prop_dlf_camellias_001'));
      expect(receivedPayload['user_id'], equals('sakshi@propzen.ai'));
      expect(receivedPayload['full_name'], equals('Sakshi Sharma'));
      expect(receivedPayload['mobile_number'], equals('9810394068'));
      expect(receivedPayload['email'], equals('sakshi@propzen.ai'));
      expect(receivedPayload['message'], contains('4 BHK layout'));
      expect(receivedPayload['preferred_contact_method'], equals('phone'));

      // Verify Header Authentication is attached
      expect(receivedHeaders['X-PropZen-Key'], isNotEmpty);
      expect(receivedHeaders['Content-Type'], contains('application/json'));
    });

    test('3. Response Handling for 400 Validation Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': 'Validation error: mobile_number must be 10 digits',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      n8n.setMockClient(mockClient);

      final response = await n8n.submitPropertyEnquiry(
        propertyId: 'prop_001',
        propertyName: 'Test Property',
        fullName: 'Test User',
        mobileNumber: '123',
        email: 'invalid@email.com',
        message: 'Hello',
      );

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(400));
      expect(response.message, contains('Validation error'));
    });

    test('4. Response Handling for 500 Server Error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'Internal Workflow Execution Error',
          500,
        );
      });

      n8n.setMockClient(mockClient);

      final response = await n8n.submitPropertyEnquiry(
        propertyId: 'prop_001',
        propertyName: 'Test Property',
        fullName: 'Test User',
        mobileNumber: '9810394068',
        email: 'test@propzen.ai',
        message: 'Hello',
      );

      expect(response.isSuccess, isFalse);
      expect(response.statusCode, equals(500));
      expect(response.message, contains('500'));
    });

    test('5. Supports Toggling to Test Webhook for Staging / Verification', () async {
      Uri? calledUri;
      final mockClient = MockClient((request) async {
        calledUri = request.url;
        return http.Response(jsonEncode({'success': true, 'message': 'Enquiry submitted successfully'}), 200);
      });

      n8n.setMockClient(mockClient);

      await n8n.submitPropertyEnquiry(
        propertyId: 'prop_test',
        propertyName: 'Test Villa',
        fullName: 'Tester',
        mobileNumber: '9810394068',
        email: 'tester@propzen.ai',
        message: 'Test',
        useTestWebhook: true,
      );

      expect(calledUri.toString(), equals(N8nService.testPropertyEnquiryUrl));
    });

    tearDown(() {
      n8n.setMockClient(null);
    });
  });
}
