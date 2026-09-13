package com.propzen.ai.model;

/**
 * Supported AI providers in the PropZen platform.
 */
public enum AiProviderType {
    LOCAL,
    OPENAI,
    GEMINI,
    ANTHROPIC;

    public static AiProviderType fromString(String val) {
        if (val == null || val.isBlank()) {
            return LOCAL;
        }
        try {
            return AiProviderType.valueOf(val.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return LOCAL;
        }
    }
}
