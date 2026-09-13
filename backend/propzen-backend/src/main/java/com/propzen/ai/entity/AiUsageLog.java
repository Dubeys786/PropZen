package com.propzen.ai.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Entity logging all AI operations, performance metrics, token usage, and fallbacks.
 */
@Entity
@Table(name = "ai_usage_logs")
public class AiUsageLog implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "request_id", nullable = false)
    private String requestId;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "operation", nullable = false)
    private String operation;

    @Column(name = "provider", nullable = false)
    private String provider;

    @Column(name = "model")
    private String model;

    @Column(name = "tokens_used")
    private Integer tokensUsed = 0;

    @Column(name = "latency_ms", nullable = false)
    private Long latencyMs;

    @Column(name = "status", nullable = false)
    private String status;

    @Column(name = "fallback_used", nullable = false)
    private Boolean fallbackUsed = false;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public AiUsageLog() {
    }

    public AiUsageLog(String requestId, UUID userId, String operation, String provider, String model,
                      Integer tokensUsed, Long latencyMs, String status, Boolean fallbackUsed, String errorMessage) {
        this.requestId = requestId;
        this.userId = userId;
        this.operation = operation;
        this.provider = provider;
        this.model = model;
        this.tokensUsed = tokensUsed != null ? tokensUsed : 0;
        this.latencyMs = latencyMs;
        this.status = status;
        this.fallbackUsed = fallbackUsed != null ? fallbackUsed : false;
        this.errorMessage = errorMessage;
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getOperation() {
        return operation;
    }

    public void setOperation(String operation) {
        this.operation = operation;
    }

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public Integer getTokensUsed() {
        return tokensUsed;
    }

    public void setTokensUsed(Integer tokensUsed) {
        this.tokensUsed = tokensUsed;
    }

    public Long getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(Long latencyMs) {
        this.latencyMs = latencyMs;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Boolean getFallbackUsed() {
        return fallbackUsed;
    }

    public void setFallbackUsed(Boolean fallbackUsed) {
        this.fallbackUsed = fallbackUsed;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
