package com.propzen;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

/**
 * PropZen Enterprise Backend Application Entry Point.
 *
 * Provides RESTful APIs, multi-criteria property discovery, secure authentication,
 * and AI-assisted verification services.
 */
@SpringBootApplication
public class PropzenApplication {

    public static void main(String[] args) {
        SpringApplication.run(PropzenApplication.class, args);
    }
}
