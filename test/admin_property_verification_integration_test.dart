import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dealghar_ncr_10x/routes/app_routes.dart';
import 'package:dealghar_ncr_10x/screens/admin_panel_screen.dart';
import 'package:dealghar_ncr_10x/screens/user_profile_screen.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/admin_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/widgets/admin_route_guard.dart';
import 'package:dealghar_ncr_10x/verification/models/trust_engine_models.dart';
import 'package:dealghar_ncr_10x/verification/screens/verification_workspace_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserSession.logout();
    AdminService.instance.resetForTesting(claimed: true);
    SupabaseService.instance.clearSession();
  });

  group('PropZen AI Property Verification Command Center Integration Suite', () {
    test('1. AppRoutes generates AdminRouteGuard with initialNavIndex: 2 for adminPropertyVerification', () {
      final route = AppRoutes.generateRoute(
        const RouteSettings(name: AppRoutes.adminPropertyVerification),
      );
      expect(route, isNotNull);
      expect(route, isA<MaterialPageRoute>());

      final pageRoute = route as MaterialPageRoute;
      final widget = pageRoute.builder(
        // ignore: invalid_use_of_protected_member
        _MockBuildContext(),
      );

      expect(widget, isA<AdminRouteGuard>());
      final guard = widget as AdminRouteGuard;
      expect(guard.allowCrmRoles, isFalse);
      expect(guard.child, isA<AdminPanelScreen>());
      final panel = guard.child as AdminPanelScreen;
      expect(panel.initialNavIndex, equals(2));
    });

    test('2. Unauthenticated user is barred from AI Property Verification Command Center', () {
      UserSession.logout();
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.unauthenticated));
    });

    test('3. Buyer role is strictly barred from AI Property Verification Command Center (403)', () {
      UserSession.login(
        name: 'Regular Buyer',
        phone: '9876543210',
        email: 'buyer@propzen.in',
        role: 'Buyer',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.forbidden403));
      expect(UserSession.isAdmin, isFalse);
    });

    test('4. Dealer role is strictly barred from AI Property Verification Command Center (allowCrmRoles: false)', () {
      UserSession.login(
        name: 'NCR Dealer',
        phone: '9812345678',
        email: 'dealer@propzen.in',
        role: 'Dealer',
        isEmailVerified: true,
      );
      final isPermittedForAdminVerification = UserSession.isAdmin && UserSession.email.trim().toLowerCase() == UserSession.designatedAdminEmail;
      expect(isPermittedForAdminVerification, isFalse);
      expect(UserSession.isAdmin, isFalse);
    });

    test('5. Service Partner role is strictly barred from AI Property Verification Command Center (403)', () {
      UserSession.login(
        name: 'Service Partner',
        phone: '9823456789',
        email: 'partner@propzen.in',
        role: 'SERVICE_PARTNER',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.forbidden403));
      expect(UserSession.isAdmin, isFalse);
    });

    test('6. Verified Admin is granted access to AI Property Verification Command Center', () {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: true,
      );
      expect(AuthService.instance.checkCommandCenterAccess(), equals(AdminAccessStatus.allowed));
      expect(UserSession.isAdmin, isTrue);
    });

    test('7. TrustEngine Models decode backend JSON correctly', () {
      final backendJson = {
        'id': 'V-998811',
        'propertyTitle': 'Sector 150 Luxury Apartment',
        'location': 'Expressway, Noida',
        'ownerName': 'Vikram Rathore',
        'status': 'VERIFIED',
        'riskScore': 94.5,
        'overallRiskLevel': 'LOW',
        'updatedAt': '2026-09-10T12:00:00.000Z',
        'propertyDetails': {
          'propertyType': 'Apartment',
          'city': 'Noida',
          'sectorLocality': 'Sector 150',
          'surveyKhasraNumber': 'K-1029',
          'plotNumber': 'A-44',
          'area': '2250',
          'unit': 'Sq.Ft',
          'ownerName': 'Vikram Rathore',
          'registrationNumber': 'REG-2024-8891',
        },
        'documents': [
          {
            'id': 'D-1',
            'fileName': 'Sale_Deed_Registered.pdf',
            'documentType': 'SALE_DEED',
            'fileSize': 1048576,
            'status': 'PROCESSED',
            'fileUrl': 'https://storage.propzen.in/docs/D-1.pdf',
            'createdAt': '2026-09-10T11:00:00.000Z',
          }
        ],
        'riskChecks': [
          {
            'categoryName': 'Title Authenticity',
            'explanation': 'Unbroken 30-year conveyance verified.',
            'status': 'PASS',
          }
        ],
        'consistencyChecks': [
          {
            'attributeName': 'Owner Name',
            'documentAValue': 'Vikram Rathore',
            'documentBValue': 'Vikram Rathore',
            'matchStatus': 'MATCH',
            'differenceNotes': 'Matches across deeds',
          }
        ],
      };

      final parsed = VerificationCase.fromJson(backendJson);
      expect(parsed.id, equals('V-998811'));
      expect(parsed.propertyTitle, equals('Sector 150 Luxury Apartment'));
      expect(parsed.status, equals(VerificationStatus.verified));
      expect(parsed.overallRiskLevel, equals(RiskLevel.low));
      expect(parsed.numericalRiskScore, equals(94.5));
      expect(parsed.documents.length, equals(1));
      expect(parsed.documents.first.name, equals('Sale_Deed_Registered.pdf'));
      expect(parsed.riskCategories.length, equals(1));
      expect(parsed.riskCategories.first.status, equals('PASS'));
      expect(parsed.consistencyRows.length, equals(1));
      expect(parsed.consistencyRows.first.matchStatus, equals(ConsistencyMatchStatus.match));
    });

    testWidgets('8. AdminPanelScreen mounts and renders AI Property Verification menu item and workspace', (tester) async {
      UserSession.login(
        name: 'Sakshi Dubey',
        phone: '9810394068',
        email: 'dubeysakshi618@gmail.com',
        role: 'ADMIN',
        isEmailVerified: true,
      );
      AdminService.instance.setAdminLoggedIn(true, email: 'dubeysakshi618@gmail.com', name: 'Sakshi Dubey');

      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminPanelScreen(initialNavIndex: 2),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check for navigation menu item
      expect(find.text('AI Property Verification'), findsAtLeastNWidgets(1));
      expect(find.text('AI-powered property & document verification'), findsAtLeastNWidgets(1));

      // Check that Verification Workspace view is mounted
      expect(find.byType(VerificationWorkspaceView), findsOneWidget);
    });
  });
}

class _MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
