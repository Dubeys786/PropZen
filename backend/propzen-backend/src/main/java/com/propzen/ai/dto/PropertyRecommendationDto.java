package com.propzen.ai.dto;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class PropertyRecommendationDto implements Serializable {

    private UUID propertyId;
    private String title;
    private String city;
    private String sector;
    private String bhk;
    private String propertyType;
    private BigDecimal priceCr;
    private Integer sqft;
    private double matchPercentage;
    private List<String> matchHighlights = new ArrayList<>();

    public PropertyRecommendationDto() {
    }

    public PropertyRecommendationDto(UUID propertyId, String title, String city, String sector,
                                     String bhk, String propertyType, BigDecimal priceCr,
                                     Integer sqft, double matchPercentage, List<String> matchHighlights) {
        this.propertyId = propertyId;
        this.title = title;
        this.city = city;
        this.sector = sector;
        this.bhk = bhk;
        this.propertyType = propertyType;
        this.priceCr = priceCr;
        this.sqft = sqft;
        this.matchPercentage = matchPercentage;
        this.matchHighlights = matchHighlights != null ? matchHighlights : new ArrayList<>();
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

    public String getBhk() {
        return bhk;
    }

    public void setBhk(String bhk) {
        this.bhk = bhk;
    }

    public String getPropertyType() {
        return propertyType;
    }

    public void setPropertyType(String propertyType) {
        this.propertyType = propertyType;
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

    public double getMatchPercentage() {
        return matchPercentage;
    }

    public void setMatchPercentage(double matchPercentage) {
        this.matchPercentage = matchPercentage;
    }

    public List<String> getMatchHighlights() {
        return matchHighlights;
    }

    public void setMatchHighlights(List<String> matchHighlights) {
        this.matchHighlights = matchHighlights;
    }
}
