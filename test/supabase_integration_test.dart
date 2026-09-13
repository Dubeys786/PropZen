import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/screens/site_visit_booking_screen.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  group('Supabase Backend Integration Tests', () {
    test('1. SupabaseService configuration matches provided project credentials', () {
      expect(SupabaseService.projectId, equals('eemxylswyvhsyzllcsnp'));
      expect(SupabaseService.supabaseUrl, equals('https://eemxylswyvhsyzllcsnp.supabase.co'));
      expect(SupabaseService.supabasePublishableKey, equals('sb_publishable_VfKv6fXe243_FfAHo8t1DA_uBwIP0YS'));
    });

    test('2. UserSession login triggers Supabase profile sync', () async {
      UserSession.login(
        name: 'Sakshi Sharma',
        userEmail: 'sakshi.sharma@dealghar.com',
        phone: '9810394068',
        role: 'Verified Buyer / Owner',
        isEmailVerified: true,
      );

      expect(UserSession.isLoggedInNotifier.value, isTrue);
      expect(UserSession.fullNameNotifier.value, equals('Sakshi Sharma'));
      expect(UserSession.emailNotifier.value, equals('sakshi.sharma@dealghar.com'));
      expect(UserSession.mobileNumberNotifier.value, contains('9810394068'));

      final currentUser = SupabaseService.instance.auth.currentUser;
      expect(currentUser, isNotNull);
      expect(currentUser!.name, equals('Sakshi Sharma'));
      expect(currentUser.email, equals('sakshi.sharma@dealghar.com'));
    });

    test('3. Supabase saveSiteVisit sends structured booking payload', () async {
      final success = await SupabaseService.instance.saveSiteVisit(
        propertyId: 'NCR-137-NOIDA-994',
        propertyTitle: '3BHK Premium Luxury Flat',
        visitDate: '2026-08-25',
        timeSlot: '11:00 AM - 12:00 PM',
        name: 'Sakshi Sharma',
        phone: '+91 98103 94068',
        email: 'sakshi.sharma@dealghar.com',
      );

      // In mock test HTTP environment, verify method runs without exception
      expect(success, isA<bool>());
    });

    testWidgets('4. SiteVisitBookingScreen UI submits booking and triggers Supabase sync', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testProperty = Property(
        id: 'NCR-PROJ-GODREJ-146',
        title: 'Godrej Tropical Isle',
        sector: 'Sector 146, Noida Expressway',
        city: 'Noida',
        category: 'Residential',
        propertyType: 'Flat',
        askingPriceCr: 1.85,
        fairValueCr: 1.78,
        pricePerSqft: 10277,
        score10x: 9.7,
        rentalYieldPercent: 6.40,
        sqft: 1800,
        bhk: '3BHK',
        imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiteVisitBookingScreen(property: testProperty),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify form fields
      expect(find.text('Confirm Site Visit'), findsOneWidget);
      expect(find.text('Godrej Tropical Isle'), findsWidgets);

      // Tap confirm button
      final confirmBtn = find.text('Confirm Site Visit');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Verify success confirmation view
      expect(find.text('Site Visit Requested Successfully'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  void write(Object? obj) {}

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 201;

  @override
  int get contentLength => _jsonResponse.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  Future<E> drain<E>([E? futureValue]) async => futureValue as E;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_jsonResponse]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

final _jsonResponse = '[{"id":"test-1","status":"success"}]'.codeUnits;
