package com.propzen.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Enterprise database configuration for PropZen Spring Data JPA.
 *
 * Configures transaction management and repository scanning while guaranteeing
 * compatibility with Supabase PostgreSQL and connection pooling.
 */
@Configuration
@EnableTransactionManagement
@EnableJpaAuditing
@EnableJpaRepositories(basePackages = "com.propzen")
public class DatabaseConfig {

    private static final Logger log = LoggerFactory.getLogger(DatabaseConfig.class);

    public DatabaseConfig() {
        log.info("Initialized PropZen Database and Transaction Management configuration");
    }
}
