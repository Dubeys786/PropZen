package com.propzen.property.dto;

import com.propzen.property.entity.Property;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Detailed property view DTO with role-sensitive field sanitization.
 */
public class PropertyDetailsDto {

    private UUID id;
    private String title;
    private String description;
    private String city;
    private String sector;
    private String locality;
    private String propertyType;
    private String bhk;
    private BigDecimal priceCr;
    private Integer sqft;
    private String status;
    private String verificationStatus;
    private String amenities;
    private String imageUrl;
    private String images;
    private UUID dealerId;
    private String ownerName;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public PropertyDetailsDto() {
    }

    public static PropertyDetailsDto fromEntity(Property p, boolean isPrivileged) {
        if (p == null) return null;
        PropertyDetailsDto dto = new PropertyDetailsDto();
        dto.setId(p.getId());
        dto.setTitle(p.getTitle());
        dto.setDescription(p.getDescription());
        dto.setCity(p.getCity());
        dto.setSector(p.getSector());
        dto.setLocality(p.getLocality());
        dto.setPropertyType(p.getPropertyType());
        dto.setBhk(p.getBhk());
        dto.setPriceCr(p.getPriceCr());
        dto.setSqft(p.getSqft());
        dto.setStatus(p.getStatus());
        dto.setVerificationStatus(p.getVerificationStatus());
        dto.setAmenities(p.getAmenities());
        dto.setImageUrl(p.getImageUrl());
        dto.setImages(p.getImages());
        dto.setDealerId(p.getDealerId());
        dto.setCreatedAt(p.getCreatedAt());
        dto.setUpdatedAt(p.getUpdatedAt());

        // Expose ownerName only to authorized dealer or admin
        if (isPrivileged) {
            dto.setOwnerName(p.getOwnerName());
        }
        return dto;
    }

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getSector() {
        return sector;
    }

    public void setSector(String sector) {
        this.sector = sector;
    }

    public String getLocality() {
        return locality;
    }

    public void setLocality(String locality) {
        this.locality = locality;
    }

    public String getPropertyType() {
        return propertyType;
    }

    public void setPropertyType(String propertyType) {
        this.propertyType = propertyType;
    }

    public String getBhk() {
        return bhk;
    }

    public void setBhk(String bhk) {
        this.bhk = bhk;
    }

    public BigDecimal getPriceCr() {
        return priceCr;
    }

    public void setPriceCr(BigDecimal priceCr) {
        this.priceCr = priceCr;
    }

    public Integer getSqft() {
        return sqft;
    }

    public void setSqft(Integer sqft) {
        this.sqft = sqft;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getVerificationStatus() {
        return verificationStatus;
    }

    public void setVerificationStatus(String verificationStatus) {
        this.verificationStatus = verificationStatus;
    }

    public String getAmenities() {
        return amenities;
    }

    public void setAmenities(String amenities) {
        this.amenities = amenities;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getImages() {
        return images;
    }

    public void setImages(String images) {
        this.images = images;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }

    public String getOwnerName() {
        return ownerName;
    }

    public void setOwnerName(String ownerName) {
        this.ownerName = ownerName;
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
