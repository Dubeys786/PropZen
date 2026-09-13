package com.propzen.ai.model;

import java.io.Serializable;

/**
 * Standard typed response envelope for AI operations.
 */
public class AiResponse<T> implements Serializable {

    private boolean success;
    private T data;
    private AiProviderType provider;
    private String model;
    private long latencyMs;
    private int tokensUsed;
    private boolean fallbackUsed;
    private String errorMessage;

    public AiResponse() {
    }

    public static <T> AiResponse<T> success(T data, AiProviderType provider, String model, long latencyMs, int tokensUsed) {
        AiResponse<T> resp = new AiResponse<>();
        resp.success = true;
        resp.data = data;
        resp.provider = provider;
        resp.model = model;
        resp.latencyMs = latencyMs;
        resp.tokensUsed = tokensUsed;
        resp.fallbackUsed = false;
        return resp;
    }

    public static <T> AiResponse<T> fallback(T data, String reason, long latencyMs) {
        AiResponse<T> resp = new AiResponse<>();
        resp.success = true;
        resp.data = data;
        resp.provider = AiProviderType.LOCAL;
        resp.model = "rule-engine-v1";
        resp.latencyMs = latencyMs;
        resp.tokensUsed = 0;
        resp.fallbackUsed = true;
        resp.errorMessage = reason;
        return resp;
    }

    public static <T> AiResponse<T> failure(String errorMessage, AiProviderType provider, long latencyMs) {
        AiResponse<T> resp = new AiResponse<>();
        resp.success = false;
        resp.provider = provider;
        resp.latencyMs = latencyMs;
        resp.errorMessage = errorMessage;
        return resp;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public AiProviderType getProvider() {
        return provider;
    }

    public void setProvider(AiProviderType provider) {
        this.provider = provider;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public long getLatencyMs() {
        return latencyMs;
    }

    public void setLatencyMs(long latencyMs) {
        this.latencyMs = latencyMs;
    }

    public int getTokensUsed() {
        return tokensUsed;
    }

    public void setTokensUsed(int tokensUsed) {
        this.tokensUsed = tokensUsed;
    }

    public boolean isFallbackUsed() {
        return fallbackUsed;
    }

    public void setFallbackUsed(boolean fallbackUsed) {
        this.fallbackUsed = fallbackUsed;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }
}
