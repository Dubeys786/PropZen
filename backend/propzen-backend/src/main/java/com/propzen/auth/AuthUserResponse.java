package com.propzen.auth;

import java.io.Serializable;
import java.util.List;
import java.util.UUID;

/**
 * Safe client DTO for authenticated user identity.
 * Strictly excludes JWTs, refresh tokens, and internal credentials.
 */
public class AuthUserResponse implements Serializable {

    private boolean authenticated;
    private UUID userId;
    private String email;
    private String phone;
    private List<String> roles;

    public AuthUserResponse() {
    }

    public AuthUserResponse(boolean authenticated, UUID userId, String email, String phone, List<String> roles) {
        this.authenticated = authenticated;
        this.userId = userId;
        this.email = email;
        this.phone = phone;
        this.roles = roles;
    }

    public boolean isAuthenticated() {
        return authenticated;
    }

    public void setAuthenticated(boolean authenticated) {
        this.authenticated = authenticated;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public List<String> getRoles() {
        return roles;
    }

    public void setRoles(List<String> roles) {
        this.roles = roles;
    }
}
