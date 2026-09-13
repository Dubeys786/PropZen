package com.propzen.property.dto;

import com.propzen.property.entity.Property;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Public consumer-safe summary DTO for property search and listings.
 * Never exposes owner phone, internal notes, or private metadata.
 */
public class PropertyListDto {

    private UUID id;
    private String title;
    private String city;
    private String sector;
    private String locality;
    private String propertyType;
    private String bhk;
    private BigDecimal priceCr;
    private Integer sqft;
    private String status;
    private String imageUrl;
    private OffsetDateTime createdAt;

    public PropertyListDto() {
    }

    public static PropertyListDto fromEntity(Property p) {
        if (p == null) return null;
        PropertyListDto dto = new PropertyListDto();
        dto.setId(p.getId());
        dto.setTitle(p.getTitle());
        dto.setCity(p.getCity());
        dto.setSector(p.getSector());
        dto.setLocality(p.getLocality());
        dto.setPropertyType(p.getPropertyType());
        dto.setBhk(p.getBhk());
        dto.setPriceCr(p.getPriceCr());
        dto.setSqft(p.getSqft());
        dto.setStatus(p.getStatus());
        dto.setImageUrl(p.getImageUrl());
        dto.setCreatedAt(p.getCreatedAt());
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

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
