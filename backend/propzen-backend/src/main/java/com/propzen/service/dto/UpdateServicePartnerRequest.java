package com.propzen.service.dto;

import java.util.UUID;

public class UpdateServicePartnerRequest {
    private String businessName;
    private String companyName;
    private String displayName;
    private String phone;
    private String email;
    private String description;
    private Integer experienceYears;
    private String city;
    private String serviceArea;
    private String profileImageUrl;
    private UUID serviceCategoryId;
    private String serviceCategories;

    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) { this.businessName = businessName; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Integer getExperienceYears() { return experienceYears; }
    public void setExperienceYears(Integer experienceYears) { this.experienceYears = experienceYears; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getServiceArea() { return serviceArea; }
    public void setServiceArea(String serviceArea) { this.serviceArea = serviceArea; }

    public String getProfileImageUrl() { return profileImageUrl; }
    public void setProfileImageUrl(String profileImageUrl) { this.profileImageUrl = profileImageUrl; }

    public UUID getServiceCategoryId() { return serviceCategoryId; }
    public void setServiceCategoryId(UUID serviceCategoryId) { this.serviceCategoryId = serviceCategoryId; }

    public String getServiceCategories() { return serviceCategories; }
    public void setServiceCategories(String serviceCategories) { this.serviceCategories = serviceCategories; }
}
