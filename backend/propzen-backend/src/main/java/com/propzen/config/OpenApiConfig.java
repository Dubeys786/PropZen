package com.propzen.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI 3 / Swagger documentation configuration for PropZen API suite.
 */
@Configuration
public class OpenApiConfig {

    @Value("${propzen.app.version:1.0.0}")
    private String appVersion;

    @Bean
    public OpenAPI propzenOpenAPI() {
        final String securitySchemeName = "bearerAuth";

        return new OpenAPI()
                .info(new Info()
                        .title("PropZen Real-Estate Platform API")
                        .description("High-performance, secure REST API suite for property discovery, dealer portal, " +
                                "enquiry management, site visit scheduling, and AI-assisted document verification.")
                        .version(appVersion)
                        .contact(new Contact()
                                .name("PropZen Engineering")
                                .email("engineering@propzen.ai")
                                .url("https://propzen.ai"))
                        .license(new License()
                                .name("Proprietary - All Rights Reserved")
                                .url("https://propzen.ai/terms")))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Local Development Server"),
                        new Server().url("https://api.propzen.ai").description("Production Gateway")))
                .addSecurityItem(new SecurityRequirement().addList(securitySchemeName))
                .components(new Components()
                        .addSecuritySchemes(securitySchemeName, new SecurityScheme()
                                .name(securitySchemeName)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Provide the Supabase-issued Bearer JWT token to authenticate.")));
    }
}
