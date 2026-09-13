package com.propzen.ai.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Persisted record of an AI enquiry classification, stored separately from the original customer enquiry.
 */
@Entity
@Table(name = "ai_enquiry_classifications")
public class AiEnquiryClassification implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "enquiry_id", nullable = false)
    private UUID enquiryId;

    @Column(name = "category", nullable = false)
    private String category;

    @Column(name = "priority", nullable = false)
    private String priority;

    @Column(name = "sentiment")
    private String sentiment;

    @Column(name = "suggested_department")
    private String suggestedDepartment;

    @Column(name = "suggested_action", columnDefinition = "TEXT")
    private String suggestedAction;

    @Column(name = "confidence")
    private Double confidence;

    @Column(name = "classified_at", nullable = false, updatable = false)
    private OffsetDateTime classifiedAt;

    public AiEnquiryClassification() {
    }

    public AiEnquiryClassification(UUID enquiryId, String category, String priority, String sentiment,
                                   String suggestedDepartment, String suggestedAction, Double confidence) {
        this.enquiryId = enquiryId;
        this.category = category;
        this.priority = priority;
        this.sentiment = sentiment;
        this.suggestedDepartment = suggestedDepartment;
        this.suggestedAction = suggestedAction;
        this.confidence = confidence;
    }

    @PrePersist
    protected void onCreate() {
        if (classifiedAt == null) {
            classifiedAt = OffsetDateTime.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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

    public Double getConfidence() {
        return confidence;
    }

    public void setConfidence(Double confidence) {
        this.confidence = confidence;
    }

    public OffsetDateTime getClassifiedAt() {
        return classifiedAt;
    }

    public void setClassifiedAt(OffsetDateTime classifiedAt) {
        this.classifiedAt = classifiedAt;
    }
}
