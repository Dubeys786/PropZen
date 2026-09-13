package com.propzen.property.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/**
 * Payload for creating a new property.
 * Privileged fields (dealer_id, owner_id, status, verification_status) are assigned server-side.
 */
public class CreatePropertyRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;

    private String description;

    @NotBlank(message = "City is required")
    @Size(max = 100, message = "City must not exceed 100 characters")
    private String city;

    @NotBlank(message = "Sector is required")
    @Size(max = 100, message = "Sector must not exceed 100 characters")
    private String sector;

    private String locality;

    @NotBlank(message = "Property type is required")
    @Size(max = 100, message = "Property type must not exceed 100 characters")
    private String propertyType;

    private String bhk;

    @NotNull(message = "Price in Crores is required")
    @DecimalMin(value = "0.0001", message = "Price must be greater than 0")
    private BigDecimal priceCr;

    @NotNull(message = "Area in sqft is required")
    @Min(value = 1, message = "Area in sqft must be greater than 0")
    private Integer sqft;

    private String amenities;
    private String imageUrl;
    private String images;
    private String metadata;
    private Boolean submitForReview = false;

    public CreatePropertyRequest() {
    }

    // Getters and Setters

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

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public Boolean getSubmitForReview() {
        return submitForReview != null ? submitForReview : false;
    }

    public void setSubmitForReview(Boolean submitForReview) {
        this.submitForReview = submitForReview;
    }
}
