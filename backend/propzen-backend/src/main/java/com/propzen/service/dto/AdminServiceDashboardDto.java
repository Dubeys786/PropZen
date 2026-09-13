package com.propzen.service.dto;

import java.math.BigDecimal;

public class AdminServiceDashboardDto {
    private long totalPartners;
    private long pendingPartners;
    private long verifiedPartners;
    private long activePartners;
    private long totalRequests;
    private long newRequests;
    private long activeRequests;
    private long completedRequests;
    private long cancelledRequests;
    private BigDecimal totalRevenue;
    private long pendingPayments;
    private double averageRating;

    public AdminServiceDashboardDto() {}

    public AdminServiceDashboardDto(long totalPartners, long pendingPartners, long verifiedPartners, long activePartners,
                                    long totalRequests, long newRequests, long activeRequests, long completedRequests,
                                    long cancelledRequests, BigDecimal totalRevenue, long pendingPayments, double averageRating) {
        this.totalPartners = totalPartners;
        this.pendingPartners = pendingPartners;
        this.verifiedPartners = verifiedPartners;
        this.activePartners = activePartners;
        this.totalRequests = totalRequests;
        this.newRequests = newRequests;
        this.activeRequests = activeRequests;
        this.completedRequests = completedRequests;
        this.cancelledRequests = cancelledRequests;
        this.totalRevenue = totalRevenue != null ? totalRevenue : BigDecimal.ZERO;
        this.pendingPayments = pendingPayments;
        this.averageRating = averageRating;
    }

    public long getTotalPartners() { return totalPartners; }
    public void setTotalPartners(long totalPartners) { this.totalPartners = totalPartners; }

    public long getPendingPartners() { return pendingPartners; }
    public void setPendingPartners(long pendingPartners) { this.pendingPartners = pendingPartners; }

    public long getVerifiedPartners() { return verifiedPartners; }
    public void setVerifiedPartners(long verifiedPartners) { this.verifiedPartners = verifiedPartners; }

    public long getActivePartners() { return activePartners; }
    public void setActivePartners(long activePartners) { this.activePartners = activePartners; }

    public long getTotalRequests() { return totalRequests; }
    public void setTotalRequests(long totalRequests) { this.totalRequests = totalRequests; }

    public long getNewRequests() { return newRequests; }
    public void setNewRequests(long newRequests) { this.newRequests = newRequests; }

    public long getActiveRequests() { return activeRequests; }
    public void setActiveRequests(long activeRequests) { this.activeRequests = activeRequests; }

    public long getCompletedRequests() { return completedRequests; }
    public void setCompletedRequests(long completedRequests) { this.completedRequests = completedRequests; }

    public long getCancelledRequests() { return cancelledRequests; }
    public void setCancelledRequests(long cancelledRequests) { this.cancelledRequests = cancelledRequests; }

    public BigDecimal getTotalRevenue() { return totalRevenue; }
    public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }

    public long getPendingPayments() { return pendingPayments; }
    public void setPendingPayments(long pendingPayments) { this.pendingPayments = pendingPayments; }

    public double getAverageRating() { return averageRating; }
    public void setAverageRating(double averageRating) { this.averageRating = averageRating; }
}
