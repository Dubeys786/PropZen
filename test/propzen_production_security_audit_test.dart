import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/models/admin_models.dart';
import 'package:dealghar_ncr_10x/models/property.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/admin_command_service.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/services/property_state_service.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';

class _SecurityTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _SecurityMockHttpClient();
  }
}

class _SecurityMockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _SecurityMockHttpRequest('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _SecurityMockHttpRequest('POST', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _SecurityMockHttpRequest('PATCH', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _SecurityMockHttpRequest('DELETE', url);
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _SecurityMockHttpRequest(method, url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SecurityMockHttpRequest implements HttpClientRequest {
  final String method;
  final Uri uri;
  final HttpHeaders headers = _SecurityMockHttpHeaders();
  int _contentLength = 0;
  bool followRedirects = true;
  int maxRedirects = 5;
  bool bufferOutput = true;
  bool persistentConnection = true;

  _SecurityMockHttpRequest(this.method, this.uri);

  @override
  int get contentLength => _contentLength;
  @override
  set contentLength(int length) {
    _contentLength = length;
  }

  @override
  void add(List<int> data) {}
  @override
  void write(Object? obj) {}
  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> close() async {
    final path = uri.path;
    final query = uri.query;

    if (path.contains('/admin_accounts')) {
      if (query.contains('dubeysakshi618@gmail.com')) {
        return _SecurityMockHttpResponse(200, '[{"id":"adm_001","name":"Sakshi Dubey","email":"dubeysakshi618@gmail.com","role":"super_admin","is_active":true}]');
      } else {
        return _SecurityMockHttpResponse(200, '[]');
      }
    }

    if (path.contains('/users')) {
      return _SecurityMockHttpResponse(200, '[{"id":"usr_001","full_name":"Sakshi Dubey","email":"dubeysakshi618@gmail.com","role":"Admin","status":"Active"},{"id":"usr_002","full_name":"Rahul Verma","email":"rahul@investors.in","role":"Buyer","status":"Active"}]');
    }

    if (path.contains('/dealers')) {
      return _SecurityMockHttpResponse(200, '[{"id":"dlr_001","name":"Rajesh Varma","firm_name":"NCR Prime Realty","email":"rajesh@ncrprime.com","verification_status":"Verified","account_status":"Active"}]');
    }

    if (path.contains('/admin_audit_logs')) {
      return _SecurityMockHttpResponse(200, '[{"id":"aud_001","actor_email":"dubeysakshi618@gmail.com","action":"ADMIN_LOGIN","entity_type":"auth","entity_id":"dubeysakshi618@gmail.com","created_at":"2026-09-01T10:00:00Z"}]');
    }

    return _SecurityMockHttpResponse(200, '[]');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SecurityMockHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  _SecurityMockHttpResponse(this.statusCode, this.body);

  @override
  HttpHeaders get headers => _SecurityMockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(body.codeUnits).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SecurityMockHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _SecurityTestHttpOverrides();

  group('PropZen 12-Point Security Audit & Hardening Regression Test Suite', () {
    setUp(() {
      UserSession.logout();
      AdminService.instance.logoutAdmin();
      PropertyStateService.instance.setProperties(List.from(Property.sampleDeals));
    });

    // TEST 1: Unauthenticated user -> /admin -> Authentication Required
    testWidgets('TEST 1: Unauthenticated user opening /admin cannot see admin workspaces and gets Authentication Required', (tester) async {
      UserSession.logout();
      AdminService.instance.logoutAdmin();

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Authentication Required'), findsOneWidget);
      expect(find.text('Sign In as Admin'), findsOneWidget);
      expect(find.text('Properties & Moderation'), findsNothing);
      expect(find.text('User Management'), findsNothing);
    });

    // TEST 2: Normal user (buyer) -> /admin -> Access Denied 403
    testWidgets('TEST 2: Normal user opening /admin gets Access Denied (403)', (tester) async {
      UserSession.login(
        name: 'Amit Sharma',
        phone: '9876543210',
        email: 'amit.buyer@gmail.com',
        role: 'Buyer',
      );

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Access Denied (403)'), findsOneWidget);
      expect(find.textContaining('dubeysakshi618@gmail.com'), findsOneWidget);
      expect(find.text('Return to Home Page'), findsOneWidget);
    });

    // TEST 3: Dealer user -> /admin -> Access Denied 403
    testWidgets('TEST 3: Dealer user opening /admin gets Access Denied (403)', (tester) async {
      UserSession.login(
        name: 'Rajesh Broker',
        phone: '9811122233',
        email: 'rajesh@ncrproperties.com',
        role: 'Dealer',
      );

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Access Denied (403)'), findsOneWidget);
      expect(find.text('Return to Home Page'), findsOneWidget);
    });

    // TEST 4: Authorized Admin -> /admin -> ALLOWED
    testWidgets('TEST 4: Authorized Admin (dubeysakshi618@gmail.com) is ALLOWED into Command Center', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'Admin',
      );
      AdminService.instance.setAdminLoggedIn(true, email: 'dubeysakshi618@gmail.com', name: 'Sakshi Dubey');

      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: AdminPanelScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PropZen Command Center'), findsWidgets);
      expect(find.text('Dashboard Overview'), findsWidgets);
      expect(find.text('Properties & Moderation'), findsWidgets);
    });

    // TEST 5: Backend Admin Verification
    test('TEST 5: Database admin verification function validates admin email securely', () async {
      final isAuthorized = await SupabaseService.instance.verifyAdminAccessInBackend('dubeysakshi618@gmail.com');
      expect(isAuthorized, isTrue);

      final isFakeAdmin = await SupabaseService.instance.verifyAdminAccessInBackend('hacker@attack.com');
      expect(isFakeAdmin, isFalse);
    });

    // TEST 6: Role Resolution from Database
    test('TEST 6: fetchUserProfileRole accurately classifies roles', () async {
      final adminRole = await SupabaseService.instance.fetchUserProfileRole('dubeysakshi618@gmail.com');
      expect(adminRole, equals('admin'));

      final buyerRole = await SupabaseService.instance.fetchUserProfileRole('normal.user@gmail.com');
      expect(buyerRole, equals('user'));
    });

    // TEST 7: Input Sanitization (XSS, SQLi, Path Traversal)
    test('TEST 7: Input sanitizers strip malicious payloads and path traversal', () {
      final dirtyText = '<script>alert("XSS")</script>Hello <b>World</b> ../../etc/passwd';
      final cleanText = SupabaseService.sanitizeText(dirtyText);
      expect(cleanText.contains('<script>'), isFalse);
      expect(cleanText.contains('../../'), isFalse);
      expect(cleanText.contains('Hello World'), isTrue);

      final dirtyEmail = '  DUBEYSAKSHI618@GMAIL.COM  ';
      expect(SupabaseService.sanitizeEmail(dirtyEmail), equals('dubeysakshi618@gmail.com'));

      final invalidEmail = 'fake_email<script>';
      expect(SupabaseService.sanitizeEmail(invalidEmail), isEmpty);

      final cleanPhone = SupabaseService.sanitizePhone('+91 (981) 039-4068<xss>');
      expect(cleanPhone, equals('+91 981 0394068'));
    });

    // TEST 8: File Upload Security Validator (MIME, Extension, Size)
    test('TEST 8: File upload validator strictly rejects dangerous scripts and oversized files', () {
      // 1. Executable file rejection
      final exeRes = SupabaseService.validateUploadFile(
        fileName: 'malicious_script.exe',
        bytes: [0x4D, 0x5A, 0x90, 0x00],
      );
      expect(exeRes['isValid'], isFalse);
      expect(exeRes['error'], contains('Forbidden file type'));

      // 2. Script file rejection (.sh, .php, .js)
      final phpRes = SupabaseService.validateUploadFile(
        fileName: 'webshell.php',
        bytes: [0x3C, 0x3F, 0x70, 0x68, 0x70],
      );
      expect(phpRes['isValid'], isFalse);

      // 3. Oversized file rejection (> 5MB)
      final oversizedBytes = List<int>.filled(6 * 1024 * 1024, 0x00);
      final sizeRes = SupabaseService.validateUploadFile(
        fileName: 'photo.jpg',
        bytes: oversizedBytes,
        maxSizeBytes: 5 * 1024 * 1024,
      );
      expect(sizeRes['isValid'], isFalse);
      expect(sizeRes['error'], contains('exceeds allowed limit'));

      // 4. Valid image acceptance
      final validBytes = List<int>.filled(1024 * 50, 0xFF);
      final validRes = SupabaseService.validateUploadFile(
        fileName: 'living_room_luxury.jpg',
        bytes: validBytes,
      );
      expect(validRes['isValid'], isTrue);
      expect(validRes['extension'], equals('jpg'));
      expect(validRes['sanitizedFileName'], isNotNull);
    });

    // TEST 9: Audit Logging System
    test('TEST 9: Administrative actions record structured audit logs in memory and database', () async {
      AdminCommandService.instance.recordAuditLog(
        targetType: 'Property',
        targetId: 'PROP-101',
        targetTitle: 'ATS Greens Pristine',
        action: 'Approved',
        reason: 'RERA documents verified by compliance officer.',
      );

      final logs = AdminCommandService.instance.auditLogs;
      expect(logs.isNotEmpty, isTrue);
      expect(logs.first.action, equals('Approved'));
      expect(logs.first.targetId, equals('PROP-101'));
      expect(logs.first.reason, contains('RERA documents verified'));
    });

    // TEST 10: Security Alert Monitoring System
    test('TEST 10: Security alerts record critical unauthorized access events', () async {
      final success = await SupabaseService.instance.recordSecurityAlert(
        alertType: 'unauthorized_admin_route_attempt',
        severity: 'high',
        targetIdentifier: 'hacker@attacker.com',
        details: {'route': '/admin', 'ip': '192.168.1.100'},
      );
      expect(success, isTrue);
    });

    // TEST 11: Rate Limiting Throttling
    test('TEST 11: AuthService rate limiter throttles repeated OTP / reset attempts', () async {
      for (int i = 0; i < 5; i++) {
        await AuthService.instance.sendOtp(phone: '+919999999999');
      }

      // 6th attempt should be blocked
      final blocked = await AuthService.instance.sendOtp(phone: '+919999999999');
      expect(blocked, isFalse);
    });

    // TEST 12: Safe Error Masking
    test('TEST 12: Internal database schema errors are masked safely for end-users', () {
      final rawError = 'PostgreSQL error: duplicate key value violates unique constraint "users_email_key" DETAIL: Key (email)=(test@a.com) already exists.';
      final safeMsg = SupabaseService.safeUserErrorMessage(rawError);
      expect(safeMsg.contains('PostgreSQL'), isFalse);
      expect(safeMsg.contains('violates unique constraint'), isFalse);
      expect(safeMsg, equals('A record with these details already exists.'));
    });
  });
}
