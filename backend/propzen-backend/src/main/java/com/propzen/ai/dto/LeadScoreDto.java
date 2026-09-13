package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class LeadScoreDto implements Serializable {

    private UUID leadId;
    private int score;
    private String classification; // HOT, WARM, COLD
    private List<String> reasons = new ArrayList<>();
    private String nextAction;
    private double confidence = 0.90;

    public LeadScoreDto() {
    }

    public LeadScoreDto(UUID leadId, int score, String classification, List<String> reasons, String nextAction, double confidence) {
        this.leadId = leadId;
        this.score = score;
        this.classification = classification;
        this.reasons = reasons != null ? reasons : new ArrayList<>();
        this.nextAction = nextAction;
        this.confidence = confidence;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public int getScore() {
        return score;
    }

    public void setScore(int score) {
        this.score = score;
    }

    public String getClassification() {
        return classification;
    }

    public void setClassification(String classification) {
        this.classification = classification;
    }

    public List<String> getReasons() {
        return reasons;
    }

    public void setReasons(List<String> reasons) {
        this.reasons = reasons;
    }

    public String getNextAction() {
        return nextAction;
    }

    public void setNextAction(String nextAction) {
        this.nextAction = nextAction;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }
}
