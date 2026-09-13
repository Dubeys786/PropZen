package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class DealerAiInsightsDto implements Serializable {

    private UUID dealerId;
    private long totalAssignedLeads;
    private long hotLeads;
    private double conversionRate;
    private List<String> listingRecommendations = new ArrayList<>();
    private List<String> leadFollowUpAlerts = new ArrayList<>();
    private String dealerPerformanceGrade; // A+, A, B, NEEDS_IMPROVEMENT

    public DealerAiInsightsDto() {
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }

    public long getTotalAssignedLeads() {
        return totalAssignedLeads;
    }

    public void setTotalAssignedLeads(long totalAssignedLeads) {
        this.totalAssignedLeads = totalAssignedLeads;
    }

    public long getHotLeads() {
        return hotLeads;
    }

    public void setHotLeads(long hotLeads) {
        this.hotLeads = hotLeads;
    }

    public double getConversionRate() {
        return conversionRate;
    }

    public void setConversionRate(double conversionRate) {
        this.conversionRate = conversionRate;
    }

    public List<String> getListingRecommendations() {
        return listingRecommendations;
    }

    public void setListingRecommendations(List<String> listingRecommendations) {
        this.listingRecommendations = listingRecommendations;
    }

    public List<String> getLeadFollowUpAlerts() {
        return leadFollowUpAlerts;
    }

    public void setLeadFollowUpAlerts(List<String> leadFollowUpAlerts) {
        this.leadFollowUpAlerts = leadFollowUpAlerts;
    }

    public String getDealerPerformanceGrade() {
        return dealerPerformanceGrade;
    }

    public void setDealerPerformanceGrade(String dealerPerformanceGrade) {
        this.dealerPerformanceGrade = dealerPerformanceGrade;
    }
}
