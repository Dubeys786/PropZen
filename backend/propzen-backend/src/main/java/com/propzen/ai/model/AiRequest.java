package com.propzen.ai.model;

import java.io.Serializable;
import java.util.UUID;

/**
 * Standard typed request envelope for AI operations.
 */
public class AiRequest<T> implements Serializable {

    private String requestId;
    private UUID userId;
    private AiOperationType operation;
    private T payload;
    private int maxTokens = 1000;
    private double temperature = 0.2;
    private boolean bypassCache = false;

    public AiRequest() {
    }

    public AiRequest(String requestId, UUID userId, AiOperationType operation, T payload) {
        this.requestId = requestId != null ? requestId : UUID.randomUUID().toString();
        this.userId = userId;
        this.operation = operation;
        this.payload = payload;
    }

    public static <T> AiRequest<T> of(AiOperationType operation, T payload, UUID userId) {
        return new AiRequest<>(UUID.randomUUID().toString(), userId, operation, payload);
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

    public AiOperationType getOperation() {
        return operation;
    }

    public void setOperation(AiOperationType operation) {
        this.operation = operation;
    }

    public T getPayload() {
        return payload;
    }

    public void setPayload(T payload) {
        this.payload = payload;
    }

    public int getMaxTokens() {
        return maxTokens;
    }

    public void setMaxTokens(int maxTokens) {
        this.maxTokens = maxTokens;
    }

    public double getTemperature() {
        return temperature;
    }

    public void setTemperature(double temperature) {
        this.temperature = temperature;
    }

    public boolean isBypassCache() {
        return bypassCache;
    }

    public void setBypassCache(boolean bypassCache) {
        this.bypassCache = bypassCache;
    }
}
