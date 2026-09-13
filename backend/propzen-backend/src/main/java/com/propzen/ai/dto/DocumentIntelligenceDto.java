package com.propzen.ai.dto;

import com.propzen.ai.model.VerificationStatus;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DocumentIntelligenceDto implements Serializable {

    private String documentType; // REGISTRY, SALE_DEED, AGREEMENT, KHATAUNI, IDENTITY, APPROVAL, UNKNOWN
    private VerificationStatus verificationStatus;
    private double confidenceScore;
    private Map<String, String> extractedAttributes = new HashMap<>();
    private List<String> flaggedDiscrepancies = new ArrayList<>();
    private String humanReviewRecommendation;

    public DocumentIntelligenceDto() {
    }

    public DocumentIntelligenceDto(String documentType, VerificationStatus verificationStatus,
                                   double confidenceScore, Map<String, String> extractedAttributes,
                                   List<String> flaggedDiscrepancies, String humanReviewRecommendation) {
        this.documentType = documentType;
        this.verificationStatus = verificationStatus;
        this.confidenceScore = confidenceScore;
        this.extractedAttributes = extractedAttributes != null ? extractedAttributes : new HashMap<>();
        this.flaggedDiscrepancies = flaggedDiscrepancies != null ? flaggedDiscrepancies : new ArrayList<>();
        this.humanReviewRecommendation = humanReviewRecommendation;
    }

    public String getDocumentType() {
        return documentType;
    }

    public void setDocumentType(String documentType) {
        this.documentType = documentType;
    }

    public VerificationStatus getVerificationStatus() {
        return verificationStatus;
    }

    public void setVerificationStatus(VerificationStatus verificationStatus) {
        this.verificationStatus = verificationStatus;
    }

    public double getConfidenceScore() {
        return confidenceScore;
    }

    public void setConfidenceScore(double confidenceScore) {
        this.confidenceScore = confidenceScore;
    }

    public Map<String, String> getExtractedAttributes() {
        return extractedAttributes;
    }

    public void setExtractedAttributes(Map<String, String> extractedAttributes) {
        this.extractedAttributes = extractedAttributes;
    }

    public List<String> getFlaggedDiscrepancies() {
        return flaggedDiscrepancies;
    }

    public void setFlaggedDiscrepancies(List<String> flaggedDiscrepancies) {
        this.flaggedDiscrepancies = flaggedDiscrepancies;
    }

    public String getHumanReviewRecommendation() {
        return humanReviewRecommendation;
    }

    public void setHumanReviewRecommendation(String humanReviewRecommendation) {
        this.humanReviewRecommendation = humanReviewRecommendation;
    }
}
