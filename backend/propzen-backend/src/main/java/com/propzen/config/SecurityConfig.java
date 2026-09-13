package com.propzen.config;

import com.propzen.security.filter.SupabaseJwtAuthenticationFilter;
import com.propzen.security.handler.PropzenAccessDeniedHandler;
import com.propzen.security.handler.PropzenAuthenticationEntryPoint;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.configurers.HeadersConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfigurationSource;

/**
 * Spring Security 6 configuration establishing stateless Supabase JWT authentication,
 * RBAC authorization, custom error translators, and secure response headers.
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final SupabaseJwtAuthenticationFilter jwtFilter;
    private final PropzenAuthenticationEntryPoint authEntryPoint;
    private final PropzenAccessDeniedHandler accessDeniedHandler;

    @Autowired
    public SecurityConfig(SupabaseJwtAuthenticationFilter jwtFilter,
                          PropzenAuthenticationEntryPoint authEntryPoint,
                          PropzenAccessDeniedHandler accessDeniedHandler) {
        this.jwtFilter = jwtFilter;
        this.authEntryPoint = authEntryPoint;
        this.accessDeniedHandler = accessDeniedHandler;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, CorsConfigurationSource corsConfigurationSource) throws Exception {
        http
                // Enable CORS integration with Spring Security
                .cors(cors -> cors.configurationSource(corsConfigurationSource))

                // Disable CSRF for stateless REST architecture
                .csrf(AbstractHttpConfigurer::disable)

                // Custom exception translators for 401 & 403
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(authEntryPoint)
                        .accessDeniedHandler(accessDeniedHandler)
                )

                // Stateless session management (JWT-oriented)
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // Frame options and secure enterprise headers
                .headers(headers -> {
                    headers.frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin);
                    headers.referrerPolicy(ref -> ref.policy(org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter.ReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN));
                    headers.permissionsPolicy(perm -> perm.policy("camera=(), microphone=(), geolocation=()"));
                    headers.contentSecurityPolicy(csp -> csp
                            .policyDirectives("default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https:; frame-ancestors 'self';"));
                })

                // Endpoint authorization rules
                .authorizeHttpRequests(auth -> auth
                        // Permit all OPTIONS requests for CORS preflight
                        .requestMatchers(org.springframework.http.HttpMethod.OPTIONS, "/**").permitAll()

                        // Public Health & Diagnostics
                        .requestMatchers("/api/v1/health", "/api/v1/health/**", "/actuator/health", "/actuator/health/**", "/actuator/info", "/error").permitAll()

                        // Swagger / OpenAPI documentation
                        .requestMatchers(
                                "/swagger-ui.html",
                                "/swagger-ui/**",
                                "/v3/api-docs/**",
                                "/v3/api-docs.yaml"
                        ).permitAll()

                        // Public Property Browsing
                        .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/v1/properties", "/api/v1/properties/**").permitAll()

                        // Public Enquiry Submission, Site Visit Booking & Provider Webhooks
                        .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/v1/enquiries", "/api/v1/site-visits").permitAll()
                        .requestMatchers("/api/v1/webhooks/**").permitAll()
                        .requestMatchers("/api/v1/whatsapp/webhook").permitAll()
                        .requestMatchers("/api/v1/communication/**").permitAll()
                        .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/v1/services/payments/webhook").permitAll()

                        // Notifications & Storage (authenticated users)
                        .requestMatchers("/api/v1/notifications", "/api/v1/notifications/**").authenticated()
                        .requestMatchers("/api/v1/storage/**").authenticated()

                        // WhatsApp Business Messaging (Dealers and Admins only)
                        .requestMatchers("/api/v1/whatsapp/**").hasAnyRole("DEALER", "ADMIN")

                        // Public/Authenticated Service Category Browsing
                        .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/v1/services/categories", "/api/v1/services/categories/**").permitAll()

                        // Property Creation and Modifications (Dealers and Admins only)
                        .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/v1/properties").hasAnyRole("DEALER", "ADMIN")
                        .requestMatchers(org.springframework.http.HttpMethod.PATCH, "/api/v1/properties/**").hasAnyRole("DEALER", "ADMIN")

                        // Admin Operations (strictly protected to ROLE_ADMIN)
                        .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                        .requestMatchers("/actuator/**").hasRole("ADMIN")
                        // Public Service Enquiry Intake
                        .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/v1/crm/leads/service-enquiry").permitAll()

                        // Authenticated Customer's Own Service Requests
                        .requestMatchers("/api/v1/crm/leads/my").authenticated()

                        // Admin Lead Assignment Endpoints
                        .requestMatchers("/api/v1/crm/leads/*/assign",
                                         "/api/v1/crm/leads/*/assign-partner",
                                         "/api/v1/crm/leads/*/unassign-partner",
                                         "/api/v1/crm/leads/*/eligible-partners").hasRole("ADMIN")
                        .requestMatchers("/api/v1/crm/campaigns/**").hasRole("ADMIN")

                        // AI Intelligence Endpoints
                        .requestMatchers("/api/v1/ai/crm/**").hasAnyRole("DEALER", "ADMIN")
                        .requestMatchers("/api/v1/ai/**").authenticated()

                        // CRM Operations (Dealers, Service Partners and Admins with strict domain isolation)
                        .requestMatchers("/api/v1/crm/**").hasAnyRole("DEALER", "SERVICE_PARTNER", "ADMIN")

                        // Service Partner Portal Operations (requires ROLE_SERVICE_PARTNER or ROLE_ADMIN)
                        .requestMatchers("/api/v1/partner/**").hasAnyRole("SERVICE_PARTNER", "ADMIN")

                        // Dealer Portal Operations
                        .requestMatchers("/api/v1/dealer/**").hasAnyRole("DEALER", "ADMIN")

                        // Service Partner Application and Own Profile (accessible by authenticated user)
                        .requestMatchers("/api/v1/service-partners/**").authenticated()

                        // Service Requests, Deliverables, Milestones, Payments, Feedback (accessible by authenticated user)
                        .requestMatchers("/api/v1/services/**").authenticated()
                        .requestMatchers("/api/v1/service-requests/**").authenticated()
                        .requestMatchers("/api/v1/service-milestones/**").authenticated()

                        // Dealer Application and Own Profile (accessible by authenticated user)
                        .requestMatchers("/api/v1/dealers/apply", "/api/v1/dealers/me").authenticated()

                        // Protected Dealer Operations (requires ROLE_DEALER or ROLE_ADMIN)
                        .requestMatchers("/api/v1/dealers/**").hasAnyRole("DEALER", "ADMIN")

                        // User Profile Management & Preferences (authenticated user)
                        .requestMatchers("/api/v1/users/**").authenticated()
                        .requestMatchers("/api/v1/enquiries/me").authenticated()

                        // Authenticated User Context
                        .requestMatchers("/api/v1/auth/me").authenticated()
                        .requestMatchers("/api/v1/my/**").authenticated()

                        // All other endpoints require authentication
                        .anyRequest().authenticated()
                )

                // Insert Supabase JWT Filter before standard authentication filter
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
