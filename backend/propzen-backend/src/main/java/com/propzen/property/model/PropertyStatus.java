package com.propzen.property.model;

import java.util.Locale;

/**
 * Controlled lifecycle states for properties.
 */
public enum PropertyStatus {
    DRAFT,
    SUBMITTED,
    UNDER_REVIEW,
    APPROVED,
    PUBLISHED,
    REJECTED,
    SOLD,
    RENTED,
    ARCHIVED;

    /**
     * Safely maps legacy or external status values to PropertyStatus.
     */
    public static PropertyStatus fromStringSafe(String val) {
        if (val == null || val.isBlank()) {
            return PUBLISHED;
        }
        String normalized = val.trim().toUpperCase(Locale.ROOT);
        switch (normalized) {
            case "ACTIVE":
            case "LIVE":
                return PUBLISHED;
            case "PENDING":
                return UNDER_REVIEW;
            case "INACTIVE":
                return ARCHIVED;
            default:
                try {
                    return PropertyStatus.valueOf(normalized);
                } catch (IllegalArgumentException e) {
                    return PUBLISHED;
                }
        }
    }
}
