package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.UUID;

public class EnquiryClassificationDto implements Serializable {

    private UUID enquiryId;
    private String category; // PROPERTY_INQUIRY, PRICE_INQUIRY, SITE_VISIT, LOAN, LEGAL, DOCUMENT, SERVICE, DEALER, OTHER
    private String priority; // LOW, MEDIUM, HIGH, URGENT
    private String sentiment; // POSITIVE, NEUTRAL, CRITICAL
    private String suggestedDepartment;
    private String suggestedAction;
    private double confidence = 0.92;

    public EnquiryClassificationDto() {
    }

    public EnquiryClassificationDto(UUID enquiryId, String category, String priority, String sentiment,
                                    String suggestedDepartment, String suggestedAction, double confidence) {
        this.enquiryId = enquiryId;
        this.category = category;
        this.priority = priority;
        this.sentiment = sentiment;
        this.suggestedDepartment = suggestedDepartment;
        this.suggestedAction = suggestedAction;
        this.confidence = confidence;
    }

    public UUID getEnquiryId() {
        return enquiryId;
    }

    public void setEnquiryId(UUID enquiryId) {
        this.enquiryId = enquiryId;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
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

    public String getSuggestedDepartment() {
        return suggestedDepartment;
    }

    public void setSuggestedDepartment(String suggestedDepartment) {
        this.suggestedDepartment = suggestedDepartment;
    }

    public String getSuggestedAction() {
        return suggestedAction;
    }

    public void setSuggestedAction(String suggestedAction) {
        this.suggestedAction = suggestedAction;
    }

    public double getConfidence() {
        return confidence;
    }

    public void setConfidence(double confidence) {
        this.confidence = confidence;
    }
}
