package com.propzen.service.dto;

import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServicePartnerProfileDto {
    private UUID id;
    private UUID userId;
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
    private PartnerVerificationStatus verificationStatus;
    private PartnerStatus partnerStatus;
    private BigDecimal rating;
    private Integer totalCompletedServices;
    private Integer totalActiveServices;
    private String adminNotes;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public static ServicePartnerProfileDto fromEntity(ServicePartnerProfile entity) {
        ServicePartnerProfileDto dto = new ServicePartnerProfileDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUserId());
        dto.setBusinessName(entity.getBusinessName());
        dto.setCompanyName(entity.getCompanyName());
        dto.setDisplayName(entity.getDisplayName());
        dto.setPhone(entity.getPhone());
        dto.setEmail(entity.getEmail());
        dto.setDescription(entity.getDescription());
        dto.setExperienceYears(entity.getExperienceYears());
        dto.setCity(entity.getCity());
        dto.setServiceArea(entity.getServiceArea());
        dto.setProfileImageUrl(entity.getProfileImageUrl());
        dto.setServiceCategoryId(entity.getServiceCategoryId());
        dto.setServiceCategories(entity.getServiceCategories());
        dto.setVerificationStatus(entity.getVerificationStatus());
        dto.setPartnerStatus(entity.getPartnerStatus());
        dto.setRating(entity.getRating());
        dto.setTotalCompletedServices(entity.getTotalCompletedServices());
        dto.setTotalActiveServices(entity.getTotalActiveServices());
        dto.setAdminNotes(entity.getAdminNotes());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

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

    public PartnerVerificationStatus getVerificationStatus() { return verificationStatus; }
    public void setVerificationStatus(PartnerVerificationStatus verificationStatus) { this.verificationStatus = verificationStatus; }

    public PartnerStatus getPartnerStatus() { return partnerStatus; }
    public void setPartnerStatus(PartnerStatus partnerStatus) { this.partnerStatus = partnerStatus; }

    public BigDecimal getRating() { return rating; }
    public void setRating(BigDecimal rating) { this.rating = rating; }

    public Integer getTotalCompletedServices() { return totalCompletedServices; }
    public void setTotalCompletedServices(Integer totalCompletedServices) { this.totalCompletedServices = totalCompletedServices; }

    public Integer getTotalActiveServices() { return totalActiveServices; }
    public void setTotalActiveServices(Integer totalActiveServices) { this.totalActiveServices = totalActiveServices; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
