package com.propzen.dealer.dto;

import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Standard DTO representation for a Dealer Profile.
 */
public class DealerProfileDto implements Serializable {

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
    private DealerVerificationStatus verificationStatus;
    private DealerStatus status;
    private String adminNotes;
    private UUID reviewedBy;
    private OffsetDateTime reviewedAt;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public DealerProfileDto() {
    }

    public static DealerProfileDto fromEntity(DealerProfile entity) {
        if (entity == null) return null;
        DealerProfileDto dto = new DealerProfileDto();
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
        dto.setVerificationStatus(entity.getVerificationStatus());
        dto.setStatus(entity.getStatus());
        dto.setAdminNotes(entity.getAdminNotes());
        dto.setReviewedBy(entity.getReviewedBy());
        dto.setReviewedAt(entity.getReviewedAt());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
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

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
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

    public DealerVerificationStatus getVerificationStatus() {
        return verificationStatus;
    }

    public void setVerificationStatus(DealerVerificationStatus verificationStatus) {
        this.verificationStatus = verificationStatus;
    }

    public DealerStatus getStatus() {
        return status;
    }

    public void setStatus(DealerStatus status) {
        this.status = status;
    }

    public String getAdminNotes() {
        return adminNotes;
    }

    public void setAdminNotes(String adminNotes) {
        this.adminNotes = adminNotes;
    }

    public UUID getReviewedBy() {
        return reviewedBy;
    }

    public void setReviewedBy(UUID reviewedBy) {
        this.reviewedBy = reviewedBy;
    }

    public OffsetDateTime getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(OffsetDateTime reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
