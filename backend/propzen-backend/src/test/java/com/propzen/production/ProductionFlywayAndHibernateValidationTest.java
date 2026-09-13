package com.propzen.production;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class ProductionFlywayAndHibernateValidationTest {

    @DynamicPropertySource
    static void configureProductionValidationProperties(DynamicPropertyRegistry registry) {
        String dbUrl = "jdbc:h2:mem:propzen_prod_validation;DB_CLOSE_DELAY=-1;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE";

        // Pre-create the Supabase live baseline tables before Flyway starts
        try (Connection conn = java.sql.DriverManager.getConnection(dbUrl, "sa", "");
             Statement stmt = conn.createStatement()) {

            // Create schema public if needed
            stmt.execute("CREATE SCHEMA IF NOT EXISTS public");

            // Alias TIMESTAMPTZ to TIMESTAMP WITH TIME ZONE for PostgreSQL compatibility
            stmt.execute("CREATE DOMAIN IF NOT EXISTS TIMESTAMPTZ AS TIMESTAMP WITH TIME ZONE");
            stmt.execute("CREATE DOMAIN IF NOT EXISTS \"TIMESTAMPTZ\" AS TIMESTAMP WITH TIME ZONE");

            // Live Supabase baseline tables
            stmt.execute("CREATE TABLE IF NOT EXISTS public.users (" +
                    "id UUID PRIMARY KEY, " +
                    "full_name VARCHAR(255), " +
                    "email VARCHAR(255) UNIQUE, " +
                    "phone VARCHAR(50), " +
                    "role VARCHAR(50) DEFAULT 'BUYER', " +
                    "is_email_verified BOOLEAN DEFAULT FALSE, " +
                    "last_login_at TIMESTAMP WITH TIME ZONE, " +
                    "created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, " +
                    "metadata TEXT" +
                    ")");

            stmt.execute("CREATE TABLE IF NOT EXISTS public.profiles (" +
                    "id UUID PRIMARY KEY, " +
                    "user_id UUID, " +
                    "full_name VARCHAR(255)" +
                    ")");

            stmt.execute("CREATE TABLE IF NOT EXISTS public.posted_properties (" +
                    "id UUID PRIMARY KEY, " +
                    "title VARCHAR(255) NOT NULL, " +
                    "city VARCHAR(100), " +
                    "sector VARCHAR(100), " +
                    "property_type VARCHAR(100), " +
                    "bhk VARCHAR(50), " +
                    "price_cr NUMERIC(12, 4), " +
                    "sqft INT, " +
                    "owner_name VARCHAR(255), " +
                    "owner_phone VARCHAR(50), " +
                    "status VARCHAR(50) DEFAULT 'DRAFT', " +
                    "created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, " +
                    "metadata TEXT" +
                    ")");

            stmt.execute("CREATE TABLE IF NOT EXISTS public.enquiries (" +
                    "id UUID PRIMARY KEY, " +
                    "property_id VARCHAR(255), " +
                    "property_title VARCHAR(255), " +
                    "user_name VARCHAR(255), " +
                    "user_email VARCHAR(255), " +
                    "user_phone VARCHAR(50), " +
                    "enquiry_type VARCHAR(50), " +
                    "message TEXT, " +
                    "status VARCHAR(50) DEFAULT 'New', " +
                    "created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, " +
                    "metadata TEXT" +
                    ")");

            stmt.execute("CREATE TABLE IF NOT EXISTS public.site_visits (" +
                    "id UUID PRIMARY KEY, " +
                    "property_id VARCHAR(255), " +
                    "property_title VARCHAR(255), " +
                    "user_name VARCHAR(255) NOT NULL, " +
                    "user_email VARCHAR(255), " +
                    "user_phone VARCHAR(50) NOT NULL, " +
                    "visit_date VARCHAR(255), " +
                    "time_slot VARCHAR(50), " +
                    "visitor_count INT DEFAULT 1, " +
                    "cab_required BOOLEAN DEFAULT FALSE, " +
                    "status VARCHAR(50) DEFAULT 'SCHEDULED', " +
                    "created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP, " +
                    "metadata TEXT" +
                    ")");

        } catch (Exception e) {
            throw new RuntimeException("Failed to prepare baseline schema for test: " + e.getMessage(), e);
        }

        registry.add("spring.datasource.url", () -> dbUrl);
        registry.add("spring.datasource.username", () -> "sa");
        registry.add("spring.datasource.password", () -> "");
        registry.add("spring.datasource.driver-class-name", () -> "org.h2.Driver");

        // Exact production configuration
        registry.add("spring.flyway.enabled", () -> "true");
        registry.add("spring.flyway.baseline-on-migrate", () -> "true");
        registry.add("spring.flyway.baseline-version", () -> "0");
        registry.add("spring.flyway.baseline-description", () -> "Supabase Live Baseline");
        registry.add("spring.flyway.locations", () -> "classpath:db/migration");
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
    }

    @Autowired(required = false)
    private Flyway flyway;

    @Autowired
    private DataSource dataSource;

    @Test
    @DisplayName("Verify Flyway applied all migrations V1–V10 and Hibernate validated schema")
    void testProductionFlywayAndHibernateValidation() {
        assertNotNull(dataSource, "Production DataSource must be active");
        assertNotNull(flyway, "Flyway must be active and configured");

        var info = flyway.info();
        assertNotNull(info, "Flyway migration info must not be null");

        var appliedMigrations = info.applied();
        assertTrue(appliedMigrations.length >= 10, 
                "Flyway must have applied all migrations (V1 to V10). Count: " + appliedMigrations.length);

        for (var migration : appliedMigrations) {
            assertTrue(migration.getState().isApplied(), 
                    "Migration " + migration.getVersion() + " must be successfully applied");
        }

        // Verify latest schema version
        assertEquals("10", info.current().getVersion().getVersion(), 
                "Current database schema version must be 10");
    }
}
