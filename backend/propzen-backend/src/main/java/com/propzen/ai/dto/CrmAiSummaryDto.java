package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class CrmAiSummaryDto implements Serializable {

    private UUID leadId;
    private String summary;
    private String priority; // LOW, MEDIUM, HIGH, URGENT
    private String sentiment; // POSITIVE, NEUTRAL, HESITANT, CRITICAL
    private String recommendedAction;
    private String suggestedFollowUp;
    private List<String> keyMilestones = new ArrayList<>();
    private String reason;

    public CrmAiSummaryDto() {
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public String getSummary() {
        return summary;
    }

    public void setSummary(String summary) {
        this.summary = summary;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public String getSentiment() {
        return sentiment;
    }

    public void setSentiment(String sentiment) {
        this.sentiment = sentiment;
    }

    public String getRecommendedAction() {
        return recommendedAction;
    }

    public void setRecommendedAction(String recommendedAction) {
        this.recommendedAction = recommendedAction;
    }

    public String getSuggestedFollowUp() {
        return suggestedFollowUp;
    }

    public void setSuggestedFollowUp(String suggestedFollowUp) {
        this.suggestedFollowUp = suggestedFollowUp;
    }

    public List<String> getKeyMilestones() {
        return keyMilestones;
    }

    public void setKeyMilestones(List<String> keyMilestones) {
        this.keyMilestones = keyMilestones;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }
}
