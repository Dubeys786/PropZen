package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class ServicePartnerAiInsightsDto implements Serializable {

    private UUID partnerId;
    private long totalAssignedRequests;
    private long completedRequests;
    private double completionRate;
    private double averageRating;
    private String feedbackSentiment; // EXCELLENT, POSITIVE, MIXED, POOR
    private List<String> operationalTips = new ArrayList<>();
    private String capacityStatus; // AVAILABLE, OPTIMAL, OVERLOADED

    public ServicePartnerAiInsightsDto() {
    }

    public UUID getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(UUID partnerId) {
        this.partnerId = partnerId;
    }

    public long getTotalAssignedRequests() {
        return totalAssignedRequests;
    }

    public void setTotalAssignedRequests(long totalAssignedRequests) {
        this.totalAssignedRequests = totalAssignedRequests;
    }

    public long getCompletedRequests() {
        return completedRequests;
    }

    public void setCompletedRequests(long completedRequests) {
        this.completedRequests = completedRequests;
    }

    public double getCompletionRate() {
        return completionRate;
    }

    public void setCompletionRate(double completionRate) {
        this.completionRate = completionRate;
    }

    public double getAverageRating() {
        return averageRating;
    }

    public void setAverageRating(double averageRating) {
        this.averageRating = averageRating;
    }

    public String getFeedbackSentiment() {
        return feedbackSentiment;
    }

    public void setFeedbackSentiment(String feedbackSentiment) {
        this.feedbackSentiment = feedbackSentiment;
    }

    public List<String> getOperationalTips() {
        return operationalTips;
    }

    public void setOperationalTips(List<String> operationalTips) {
        this.operationalTips = operationalTips;
    }

    public String getCapacityStatus() {
        return capacityStatus;
    }

    public void setCapacityStatus(String capacityStatus) {
        this.capacityStatus = capacityStatus;
    }
}
