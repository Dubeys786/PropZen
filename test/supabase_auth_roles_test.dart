import 'package:flutter_test/flutter_test.dart';
import 'package:dealghar_ncr_10x/services/auth_service.dart';
import 'package:dealghar_ncr_10x/services/supabase_service.dart';
import 'package:dealghar_ncr_10x/config/env_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropZen Supabase Role-Based Access Control & Environment Tests', () {
    test('1. EnvConfig provides required Supabase client configuration', () {
      expect(EnvConfig.supabaseUrl, isNotEmpty);
      expect(EnvConfig.supabaseUrl, contains('eemxylswyvhsyzllcsnp.supabase.co'));
      expect(EnvConfig.supabaseAnonKey, isNotEmpty);
      expect(EnvConfig.supabaseAnonKey, startsWith('sb_publishable_'));
      expect(EnvConfig.supabaseProjectId, equals('eemxylswyvhsyzllcsnp'));
    });

    test('2. UserRole enum correctly parses and serializes database roles', () {
      expect(UserRole.fromString('USER'), equals(UserRole.customer));
      expect(UserRole.fromString('customer'), equals(UserRole.customer));
      expect(UserRole.fromString('DEALER'), equals(UserRole.dealer));
      expect(UserRole.fromString('broker'), equals(UserRole.dealer));
      expect(UserRole.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserRole.fromString('super_admin'), equals(UserRole.admin));
      expect(UserRole.fromString('VERIFICATION_AGENT'), equals(UserRole.verificationAgent));

      expect(UserRole.customer.dbValue, equals('USER'));
      expect(UserRole.dealer.dbValue, equals('DEALER'));
      expect(UserRole.admin.dbValue, equals('ADMIN'));
      expect(UserRole.verificationAgent.dbValue, equals('VERIFICATION_AGENT'));
    });

    test('3. SupabaseAuthUser instantiates with role and email verification status', () {
      const user = SupabaseAuthUser(
        id: 'usr_test_uuid',
        name: 'Sakshi Dubey',
        email: 'dubeysakshi618@gmail.com',
        phone: '9810394068',
        role: 'ADMIN',
        isEmailVerified: true,
      );

      expect(user.id, equals('usr_test_uuid'));
      expect(user.name, equals('Sakshi Dubey'));
      expect(user.email, equals('dubeysakshi618@gmail.com'));
      expect(user.role, equals('ADMIN'));
      expect(user.isEmailVerified, isTrue);
    });

    test('4. SupabaseService delegates to EnvConfig credentials', () {
      expect(SupabaseService.supabaseUrl, equals(EnvConfig.supabaseUrl));
      expect(SupabaseService.publishableKey, equals(EnvConfig.supabaseAnonKey));
      expect(SupabaseService.projectId, equals(EnvConfig.supabaseProjectId));
    });
  });
}
