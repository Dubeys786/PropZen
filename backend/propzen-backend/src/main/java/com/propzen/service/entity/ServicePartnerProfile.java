package com.propzen.service.entity;

import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "service_partner_profiles", schema = "public")
public class ServicePartnerProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false, unique = true)
    private UUID userId;

    @Column(name = "business_name", nullable = false)
    private String businessName;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "display_name")
    private String displayName;

    private String phone;
    private String email;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "experience_years")
    private Integer experienceYears = 0;

    private String city;

    @Column(name = "service_area")
    private String serviceArea;

    @Column(name = "profile_image_url")
    private String profileImageUrl;

    @Column(name = "service_category_id")
    private UUID serviceCategoryId;

    @Column(name = "service_categories")
    private String serviceCategories; // Comma-separated category slugs or primary category

    @Enumerated(EnumType.STRING)
    @Column(name = "verification_status", nullable = false)
    private PartnerVerificationStatus verificationStatus = PartnerVerificationStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "partner_status", nullable = false)
    private PartnerStatus partnerStatus = PartnerStatus.PENDING;

    @Column(precision = 3, scale = 2)
    private BigDecimal rating = new BigDecimal("5.00");

    @Column(name = "total_completed_services", nullable = false)
    private Integer totalCompletedServices = 0;

    @Column(name = "total_active_services", nullable = false)
    private Integer totalActiveServices = 0;

    @Column(name = "admin_notes", columnDefinition = "TEXT")
    private String adminNotes;

    @Column(name = "reviewed_by")
    private UUID reviewedBy;

    @Column(name = "reviewed_at")
    private OffsetDateTime reviewedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        OffsetDateTime now = OffsetDateTime.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
        if (verificationStatus == null) verificationStatus = PartnerVerificationStatus.PENDING;
        if (partnerStatus == null) partnerStatus = PartnerStatus.PENDING;
        if (rating == null) rating = new BigDecimal("5.00");
        if (totalCompletedServices == null) totalCompletedServices = 0;
        if (totalActiveServices == null) totalActiveServices = 0;
        if (experienceYears == null) experienceYears = 0;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
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

    public UUID getReviewedBy() { return reviewedBy; }
    public void setReviewedBy(UUID reviewedBy) { this.reviewedBy = reviewedBy; }

    public OffsetDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(OffsetDateTime reviewedAt) { this.reviewedAt = reviewedAt; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
