package com.propzen.service.dto;

import java.math.BigDecimal;

public class PartnerDashboardDto {
    private long newRequests;
    private long pendingRequests;
    private long activeServices;
    private long completedServices;
    private long pendingPayments;
    private BigDecimal totalEarnings;
    private double averageRating;
    private long customerCount;
    private long unreadNotifications;

    public PartnerDashboardDto() {}

    public PartnerDashboardDto(long newRequests, long pendingRequests, long activeServices,
                               long completedServices, long pendingPayments, BigDecimal totalEarnings,
                               double averageRating, long customerCount, long unreadNotifications) {
        this.newRequests = newRequests;
        this.pendingRequests = pendingRequests;
        this.activeServices = activeServices;
        this.completedServices = completedServices;
        this.pendingPayments = pendingPayments;
        this.totalEarnings = totalEarnings != null ? totalEarnings : BigDecimal.ZERO;
        this.averageRating = averageRating;
        this.customerCount = customerCount;
        this.unreadNotifications = unreadNotifications;
    }

    public long getNewRequests() { return newRequests; }
    public void setNewRequests(long newRequests) { this.newRequests = newRequests; }

    public long getPendingRequests() { return pendingRequests; }
    public void setPendingRequests(long pendingRequests) { this.pendingRequests = pendingRequests; }

    public long getActiveServices() { return activeServices; }
    public void setActiveServices(long activeServices) { this.activeServices = activeServices; }

    public long getCompletedServices() { return completedServices; }
    public void setCompletedServices(long completedServices) { this.completedServices = completedServices; }

    public long getPendingPayments() { return pendingPayments; }
    public void setPendingPayments(long pendingPayments) { this.pendingPayments = pendingPayments; }

    public BigDecimal getTotalEarnings() { return totalEarnings; }
    public void setTotalEarnings(BigDecimal totalEarnings) { this.totalEarnings = totalEarnings; }

    public double getAverageRating() { return averageRating; }
    public void setAverageRating(double averageRating) { this.averageRating = averageRating; }

    public long getCustomerCount() { return customerCount; }
    public void setCustomerCount(long customerCount) { this.customerCount = customerCount; }

    public long getUnreadNotifications() { return unreadNotifications; }
    public void setUnreadNotifications(long unreadNotifications) { this.unreadNotifications = unreadNotifications; }
}
