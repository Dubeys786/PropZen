package com.propzen.health;

import java.io.Serializable;

/**
 * Health check status payload DTO reporting application status and database availability.
 */
public class HealthResponse implements Serializable {

    private String application;
    private String status;
    private String database;
    private String version;
    private String environment;

    public HealthResponse() {
    }

    public HealthResponse(String application, String status, String database, String version, String environment) {
        this.application = application;
        this.status = status;
        this.database = database;
        this.version = version;
        this.environment = environment;
    }

    public String getApplication() {
        return application;
    }

    public void setApplication(String application) {
        this.application = application;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getDatabase() {
        return database;
    }

    public void setDatabase(String database) {
        this.database = database;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getEnvironment() {
        return environment;
    }

    public void setEnvironment(String environment) {
        this.environment = environment;
    }
}
