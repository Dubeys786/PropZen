package com.propzen.ai.dto;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class PropertyRecommendationRequest implements Serializable {

    private UUID userId;
    private String city;
    private String sector;
    private String propertyType;
    private String bhk;
    private BigDecimal minBudgetCr;
    private BigDecimal maxBudgetCr;
    private Integer minSqft;
    private List<String> preferredAmenities;
    private int limit = 5;

    public PropertyRecommendationRequest() {
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
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

    public BigDecimal getMinBudgetCr() {
        return minBudgetCr;
    }

    public void setMinBudgetCr(BigDecimal minBudgetCr) {
        this.minBudgetCr = minBudgetCr;
    }

    public BigDecimal getMaxBudgetCr() {
        return maxBudgetCr;
    }

    public void setMaxBudgetCr(BigDecimal maxBudgetCr) {
        this.maxBudgetCr = maxBudgetCr;
    }

    public Integer getMinSqft() {
        return minSqft;
    }

    public void setMinSqft(Integer minSqft) {
        this.minSqft = minSqft;
    }

    public List<String> getPreferredAmenities() {
        return preferredAmenities;
    }

    public void setPreferredAmenities(List<String> preferredAmenities) {
        this.preferredAmenities = preferredAmenities;
    }

    public int getLimit() {
        return limit;
    }

    public void setLimit(int limit) {
        this.limit = limit;
    }
}
