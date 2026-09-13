package com.propzen.verification.dto;

public class VerificationDashboardMetricsDto {

    private long totalCases;
    private long verified;
    private long underReview;
    private long highRisk;
    private long documentsProcessed;

    public VerificationDashboardMetricsDto() {
    }

    public VerificationDashboardMetricsDto(long totalCases, long verified, long underReview, long highRisk, long documentsProcessed) {
        this.totalCases = totalCases;
        this.verified = verified;
        this.underReview = underReview;
        this.highRisk = highRisk;
        this.documentsProcessed = documentsProcessed;
    }

    public long getTotalCases() { return totalCases; }
    public void setTotalCases(long totalCases) { this.totalCases = totalCases; }

    public long getVerified() { return verified; }
    public void setVerified(long verified) { this.verified = verified; }

    public long getUnderReview() { return underReview; }
    public void setUnderReview(long underReview) { this.underReview = underReview; }

    public long getHighRisk() { return highRisk; }
    public void setHighRisk(long highRisk) { this.highRisk = highRisk; }

    public long getDocumentsProcessed() { return documentsProcessed; }
    public void setDocumentsProcessed(long documentsProcessed) { this.documentsProcessed = documentsProcessed; }
}
