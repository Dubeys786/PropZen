package com.propzen.ai.dto;

import jakarta.validation.constraints.NotBlank;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class PropertyDescriptionRequest implements Serializable {

    private UUID propertyId;

    @NotBlank(message = "Property title is required")
    private String title;

    @NotBlank(message = "City is required")
    private String city;

    private String sector;
    private String propertyType;
    private String bhk;
    private Integer sqft;
    private BigDecimal priceCr;
    private List<String> amenities;
    private String possessionStatus;
    private String developerName;

    public PropertyDescriptionRequest() {
    }

    public UUID getPropertyId() {
        return propertyId;
    }

    public void setPropertyId(UUID propertyId) {
        this.propertyId = propertyId;
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

    public Integer getSqft() {
        return sqft;
    }

    public void setSqft(Integer sqft) {
        this.sqft = sqft;
    }

    public BigDecimal getPriceCr() {
        return priceCr;
    }

    public void setPriceCr(BigDecimal priceCr) {
        this.priceCr = priceCr;
    }

    public List<String> getAmenities() {
        return amenities;
    }

    public void setAmenities(List<String> amenities) {
        this.amenities = amenities;
    }

    public String getPossessionStatus() {
        return possessionStatus;
    }

    public void setPossessionStatus(String possessionStatus) {
        this.possessionStatus = possessionStatus;
    }

    public String getDeveloperName() {
        return developerName;
    }

    public void setDeveloperName(String developerName) {
        this.developerName = developerName;
    }
}
