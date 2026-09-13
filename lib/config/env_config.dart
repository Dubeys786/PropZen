import 'package:flutter/foundation.dart';

/// Centralized Environment Configuration for PropZen
/// Reads client-safe variables via compile-time environment definitions or falls back to production defaults.
///
/// Under NO circumstances are private server secrets (such as Supabase service_role,
/// DB passwords, JWT secrets) to be stored or referenced here.
class EnvConfig {
  EnvConfig._();

  /// Environment name: 'development', 'staging', 'production'
  static const String environment = String.fromEnvironment(
    'PROPZEN_ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );

  /// Check if running in production mode
  static bool get isProduction => environment.toLowerCase() == 'production' || kReleaseMode;

  /// Check if running in development mode
  static bool get isDevelopment => !isProduction;

  /// Check if running in staging mode
  static bool get isStaging => environment.toLowerCase() == 'staging';

  /// Client-accessible Supabase URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eemxylswyvhsyzllcsnp.supabase.co',
  );

  /// Client-accessible Supabase Anon / Publishable Key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_VfKv6fXe243_FfAHo8t1DA_uBwIP0YS',
  );

  /// Canonical Host
  static const String canonicalHost = String.fromEnvironment(
    'CANONICAL_HOST',
    defaultValue: 'https://propzen.ai',
  );

  /// Project Identifier
  static const String supabaseProjectId = 'eemxylswyvhsyzllcsnp';

  /// Raw compile-time injected Java / Spring Boot Backend API Base URL
  static const String _rawBackendApiBaseUrl = String.fromEnvironment(
    'PROPZEN_API_BASE_URL',
    defaultValue: '',
  );

  /// Resolved Java / Spring Boot Backend API Base URL.
  ///
  /// - In PRODUCTION: Returns the injected `--dart-define=PROPZEN_API_BASE_URL=https://...`
  ///   If omitted in production Web, returns empty string `''` to safely support reverse-proxy / same-origin routes,
  ///   NEVER silently falling back to a broken `http://localhost:8080`.
  /// - In DEVELOPMENT: Returns `http://localhost:8080` if not overridden.
  static String get backendApiBaseUrl {
    if (_rawBackendApiBaseUrl.trim().isNotEmpty) {
      final url = _rawBackendApiBaseUrl.trim();
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }

    if (isProduction) {
      // In production, never silently depend on localhost!
      // On Web, relative paths '' allow same-origin hosting / reverse proxies.
      return kIsWeb ? '' : '';
    }

    // Development fallback
    return 'http://localhost:8080';
  }

  /// Whether a custom production backend URL was explicitly supplied via --dart-define
  static bool get hasConfiguredBackendUrl => _rawBackendApiBaseUrl.trim().isNotEmpty;

  /// Raw compile-time injected Python / AI Engine Base URL
  static const String _rawAiEngineBaseUrl = String.fromEnvironment(
    'AI_ENGINE_BASE_URL',
    defaultValue: '',
  );

  /// Resolved Python / AI Engine Base URL.
  static String get aiEngineBaseUrl {
    if (_rawAiEngineBaseUrl.trim().isNotEmpty) {
      final url = _rawAiEngineBaseUrl.trim();
      return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    }

    if (isProduction) {
      return kIsWeb ? '' : '';
    }

    return 'http://127.0.0.1:8000';
  }
}

