package com.propzen.service.dto;

import java.math.BigDecimal;
import java.util.UUID;

public class PartnerRecommendationDto {
    private UUID partnerId;
    private String businessName;
    private String displayName;
    private String city;
    private BigDecimal rating;
    private Integer experienceYears;
    private Integer activeServices;
    private BigDecimal score;
    private String matchReason;

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) { this.businessName = businessName; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public BigDecimal getRating() { return rating; }
    public void setRating(BigDecimal rating) { this.rating = rating; }

    public Integer getExperienceYears() { return experienceYears; }
    public void setExperienceYears(Integer experienceYears) { this.experienceYears = experienceYears; }

    public Integer getActiveServices() { return activeServices; }
    public void setActiveServices(Integer activeServices) { this.activeServices = activeServices; }

    public BigDecimal getScore() { return score; }
    public void setScore(BigDecimal score) { this.score = score; }

    public String getMatchReason() { return matchReason; }
    public void setMatchReason(String matchReason) { this.matchReason = matchReason; }
}
