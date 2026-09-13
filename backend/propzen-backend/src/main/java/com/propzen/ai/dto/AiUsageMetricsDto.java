package com.propzen.ai.dto;

import java.io.Serializable;

public class AiUsageMetricsDto implements Serializable {

    private long totalRequests;
    private long successfulRequests;
    private long failedRequests;
    private long fallbackRequests;
    private double averageLatencyMs;
    private long totalTokensUsed;
    private String activeProvider;

    public AiUsageMetricsDto() {
    }

    public long getTotalRequests() {
        return totalRequests;
    }

    public void setTotalRequests(long totalRequests) {
        this.totalRequests = totalRequests;
    }

    public long getSuccessfulRequests() {
        return successfulRequests;
    }

    public void setSuccessfulRequests(long successfulRequests) {
        this.successfulRequests = successfulRequests;
    }

    public long getFailedRequests() {
        return failedRequests;
    }

    public void setFailedRequests(long failedRequests) {
        this.failedRequests = failedRequests;
    }

    public long getFallbackRequests() {
        return fallbackRequests;
    }

    public void setFallbackRequests(long fallbackRequests) {
        this.fallbackRequests = fallbackRequests;
    }

    public double getAverageLatencyMs() {
        return averageLatencyMs;
    }

    public void setAverageLatencyMs(double averageLatencyMs) {
        this.averageLatencyMs = averageLatencyMs;
    }

    public long getTotalTokensUsed() {
        return totalTokensUsed;
    }

    public void setTotalTokensUsed(long totalTokensUsed) {
        this.totalTokensUsed = totalTokensUsed;
    }

    public String getActiveProvider() {
        return activeProvider;
    }

    public void setActiveProvider(String activeProvider) {
        this.activeProvider = activeProvider;
    }
}
