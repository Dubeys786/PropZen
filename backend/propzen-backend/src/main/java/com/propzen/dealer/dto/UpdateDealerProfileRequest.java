package com.propzen.dealer.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.io.Serializable;

/**
 * Payload for a dealer updating their own editable profile fields.
 * Cannot modify status, verificationStatus, admin notes, or identity fields.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class UpdateDealerProfileRequest implements Serializable {

    @Size(min = 2, max = 255, message = "Business name must be between 2 and 255 characters")
    private String businessName;

    @Size(max = 255, message = "Company name must not exceed 255 characters")
    private String companyName;

    @Size(max = 255, message = "Display name must not exceed 255 characters")
    private String displayName;

    @Pattern(regexp = "^[+0-9\\-\\s()]{7,20}$", message = "Invalid phone number format")
    private String phone;

    @Size(max = 2000, message = "Description must not exceed 2000 characters")
    private String description;

    @Min(value = 0, message = "Experience years cannot be negative")
    @Max(value = 100, message = "Experience years must be reasonable")
    private Integer experienceYears;

    @Size(max = 100, message = "City must not exceed 100 characters")
    private String city;

    public UpdateDealerProfileRequest() {
    }

    public UpdateDealerProfileRequest(String businessName, String companyName, String displayName, String phone, String description, Integer experienceYears, String city) {
        this.businessName = businessName;
        this.companyName = companyName;
        this.displayName = displayName;
        this.phone = phone;
        this.description = description;
        this.experienceYears = experienceYears;
        this.city = city;
    }

    public String getBusinessName() {
        return businessName;
    }

    public void setBusinessName(String businessName) {
        this.businessName = businessName;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getExperienceYears() {
        return experienceYears;
    }

    public void setExperienceYears(Integer experienceYears) {
        this.experienceYears = experienceYears;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }
}
