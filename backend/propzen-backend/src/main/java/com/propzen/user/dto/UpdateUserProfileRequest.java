package com.propzen.user.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.io.Serializable;

/**
 * Request body for updating the current user's personal profile.
 * Ignores any client attempts to modify security-sensitive fields (id, role, email, etc.).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class UpdateUserProfileRequest implements Serializable {

    @Size(min = 2, max = 100, message = "Full name must be between 2 and 100 characters")
    private String fullName;

    @Pattern(regexp = "^[+0-9\\-\\s()]{7,20}$", message = "Invalid phone number format")
    private String phone;

    public UpdateUserProfileRequest() {
    }

    public UpdateUserProfileRequest(String fullName, String phone) {
        this.fullName = fullName;
        this.phone = phone;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }
}
