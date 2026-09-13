package com.propzen.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Enterprise CORS configuration supporting development Flutter Web origins and production environments.
 */
@Configuration
public class CorsConfig {

    private static final Logger log = LoggerFactory.getLogger(CorsConfig.class);

    @Value("${propzen.cors.allowed-origins:http://localhost:3000,http://localhost:8080,http://localhost:5000,https://propzen.ai,https://app.propzen.ai,https://admin.propzen.ai}")
    private String allowedOriginsConfig;

    @Value("${propzen.environment:production}")
    private String environment;

    private boolean isProduction() {
        return "production".equalsIgnoreCase(environment) || "prod".equalsIgnoreCase(environment);
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();

        List<String> origins = Arrays.stream(allowedOriginsConfig.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();

        log.info("Configuring CORS allowed origins: {} (env: {})", origins, environment);

        config.setAllowedOrigins(origins);
        if (isProduction()) {
            config.setAllowedOriginPatterns(List.of(
                    "https://*.propzen.ai",
                    "https://propzen.ai"
            ));
        } else {
            config.setAllowedOriginPatterns(List.of(
                    "http://localhost:[*]",
                    "http://127.0.0.1:[*]",
                    "https://*.propzen.ai",
                    "https://propzen.ai"
            ));
        }
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"));
        config.setAllowedHeaders(List.of(
                "Authorization",
                "Content-Type",
                "Accept",
                "X-Request-Id",
                "apikey",
                "Origin",
                "X-Requested-With",
                "Access-Control-Request-Method",
                "Access-Control-Request-Headers"
        ));
        config.setExposedHeaders(List.of("X-Request-Id", "Content-Disposition", "Authorization"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public CorsFilter corsFilter(CorsConfigurationSource corsConfigurationSource) {
        return new CorsFilter(corsConfigurationSource);
    }
}
