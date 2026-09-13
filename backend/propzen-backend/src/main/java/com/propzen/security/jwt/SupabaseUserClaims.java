package com.propzen.security.jwt;

import java.io.Serializable;
import java.time.Instant;
import java.util.Collections;
import java.util.Map;
import java.util.UUID;

/**
 * Encapsulates validated claims extracted from a Supabase-issued JWT.
 */
public class SupabaseUserClaims implements Serializable {

    private final UUID userId;
    private final String email;
    private final String phone;
    private final String role;
    private final Map<String, Object> appMetadata;
    private final Map<String, Object> userMetadata;
    private final Instant issuedAt;
    private final Instant expiresAt;

    public SupabaseUserClaims(UUID userId,
                              String email,
                              String phone,
                              String role,
                              Map<String, Object> appMetadata,
                              Map<String, Object> userMetadata,
                              Instant issuedAt,
                              Instant expiresAt) {
        this.userId = userId;
        this.email = email;
        this.phone = phone;
        this.role = role;
        this.appMetadata = appMetadata != null ? appMetadata : Collections.emptyMap();
        this.userMetadata = userMetadata != null ? userMetadata : Collections.emptyMap();
        this.issuedAt = issuedAt;
        this.expiresAt = expiresAt;
    }

    public UUID getUserId() {
        return userId;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public String getRole() {
        return role;
    }

    public Map<String, Object> getAppMetadata() {
        return appMetadata;
    }

    public Map<String, Object> getUserMetadata() {
        return userMetadata;
    }

    public Instant getIssuedAt() {
        return issuedAt;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }
}
