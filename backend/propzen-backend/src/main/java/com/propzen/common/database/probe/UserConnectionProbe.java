package com.propzen.common.database.probe;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.Subselect;
import org.hibernate.annotations.Synchronize;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Read-only probe entity mapped directly to the authoritative Supabase 'users' table.
 * Marked as @Immutable and @Subselect to guarantee JPA will never issue DDL or UPDATE statements.
 */
@Entity
@Immutable
@Subselect("SELECT id, full_name, email, phone, role, is_email_verified, last_login_at, created_at FROM users")
@Synchronize("users")
public class UserConnectionProbe implements Serializable {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "email")
    private String email;

    @Column(name = "phone")
    private String phone;

    @Column(name = "role")
    private String role;

    @Column(name = "is_email_verified")
    private Boolean emailVerified;

    @Column(name = "last_login_at")
    private OffsetDateTime lastLoginAt;

    @Column(name = "created_at")
    private OffsetDateTime createdAt;

    public UserConnectionProbe() {
    }

    public UUID getId() {
        return id;
    }

    public String getFullName() {
        return fullName;
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

    public Boolean getEmailVerified() {
        return emailVerified;
    }

    public OffsetDateTime getLastLoginAt() {
        return lastLoginAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
