import '../crm/services/crm_api_client.dart';

/// Centralized API Client export for PropZen frontend services.
/// Connects to the Java Spring Boot backend using configured environment base URL
/// and authenticated Supabase Bearer JWT tokens.
typedef ApiClient = CrmApiClient;
