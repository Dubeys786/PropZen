package com.propzen.health;

import com.propzen.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;
import java.util.Arrays;
import java.util.Map;

/**
 * Health and diagnostics controller providing standard health, liveness, and readiness probes.
 * Never exposes database credentials, secrets, or internal stack traces.
 */
@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health & Diagnostics", description = "Endpoints for verifying service health, Kubernetes liveness and readiness probes")
public class HealthController {

    private static final Logger log = LoggerFactory.getLogger(HealthController.class);

    private final DataSource dataSource;
    private final Environment environment;

    @Value("${propzen.app.version:1.0.0}")
    private String appVersion;

    @Autowired
    public HealthController(DataSource dataSource, Environment environment) {
        this.dataSource = dataSource;
        this.environment = environment;
    }

    @GetMapping
    @Operation(summary = "Health check", description = "Returns system uptime status, database connectivity, and active profile")
    public ResponseEntity<ApiResponse<HealthResponse>> checkHealth() {
        String dbStatus = checkDatabaseConnectivity();
        String activeEnv = getActiveEnvironment();

        HealthResponse health = new HealthResponse(
                "UP",
                "UP",
                dbStatus,
                appVersion,
                activeEnv
        );

        ApiResponse<HealthResponse> response = ApiResponse.success(health, "PropZen Backend is healthy and operational");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/liveness")
    @Operation(summary = "Kubernetes / Container Liveness Probe", description = "Returns 200 OK to indicate JVM process is alive and responsive")
    public ResponseEntity<ApiResponse<Map<String, String>>> livenessProbe() {
        return ResponseEntity.ok(ApiResponse.ok(Map.of("status", "ALIVE"), "Process is alive"));
    }

    @GetMapping("/readiness")
    @Operation(summary = "Kubernetes / Container Readiness Probe", description = "Returns 200 OK when database and dependencies are ready to accept traffic")
    public ResponseEntity<ApiResponse<Map<String, String>>> readinessProbe() {
        String dbStatus = checkDatabaseConnectivity();
        if ("UP".equalsIgnoreCase(dbStatus)) {
            return ResponseEntity.ok(ApiResponse.ok(Map.of("status", "READY", "database", dbStatus), "Service is ready to accept traffic"));
        } else {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(ApiResponse.error("SERVICE_UNAVAILABLE", "Database not ready", Map.of("database", dbStatus)));
        }
    }

    private String checkDatabaseConnectivity() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(2)) {
                try (Statement stmt = connection.createStatement()) {
                    stmt.execute("SELECT 1");
                }
                return "UP";
            }
            return "DEGRADED";
        } catch (Exception ex) {
            log.warn("Database health check probe failed: {}", ex.getMessage());
            return "DOWN";
        }
    }

    private String getActiveEnvironment() {
        String[] profiles = environment.getActiveProfiles();
        if (profiles.length == 0) {
            return "default";
        }
        return Arrays.toString(profiles);
    }
}
