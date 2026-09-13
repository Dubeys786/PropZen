package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class AdminAiInsightsDto implements Serializable {

    private long hotLeadsCount;
    private long unattendedLeadsCount;
    private long overdueFollowUpsCount;
    private long pendingVerificationsCount;
    private List<String> operationalRisks = new ArrayList<>();
    private List<String> strategicRecommendations = new ArrayList<>();
    private String platformHealthIndex; // EXCELLENT, HEALTHY, ATTENTION_REQUIRED

    public AdminAiInsightsDto() {
    }

    public long getHotLeadsCount() {
        return hotLeadsCount;
    }

    public void setHotLeadsCount(long hotLeadsCount) {
        this.hotLeadsCount = hotLeadsCount;
    }

    public long getUnattendedLeadsCount() {
        return unattendedLeadsCount;
    }

    public void setUnattendedLeadsCount(long unattendedLeadsCount) {
        this.unattendedLeadsCount = unattendedLeadsCount;
    }

    public long getOverdueFollowUpsCount() {
        return overdueFollowUpsCount;
    }

    public void setOverdueFollowUpsCount(long overdueFollowUpsCount) {
        this.overdueFollowUpsCount = overdueFollowUpsCount;
    }

    public long getPendingVerificationsCount() {
        return pendingVerificationsCount;
    }

    public void setPendingVerificationsCount(long pendingVerificationsCount) {
        this.pendingVerificationsCount = pendingVerificationsCount;
    }

    public List<String> getOperationalRisks() {
        return operationalRisks;
    }

    public void setOperationalRisks(List<String> operationalRisks) {
        this.operationalRisks = operationalRisks;
    }

    public List<String> getStrategicRecommendations() {
        return strategicRecommendations;
    }

    public void setStrategicRecommendations(List<String> strategicRecommendations) {
        this.strategicRecommendations = strategicRecommendations;
    }

    public String getPlatformHealthIndex() {
        return platformHealthIndex;
    }

    public void setPlatformHealthIndex(String platformHealthIndex) {
        this.platformHealthIndex = platformHealthIndex;
    }
}
