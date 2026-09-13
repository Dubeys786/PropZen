package com.propzen.crm.dto;

import java.io.Serializable;
import java.math.BigDecimal;

public class AdminDashboardSummaryDto implements Serializable {

    private long totalUsers;
    private long totalBuyers;
    private long totalDealers;
    private long totalServicePartners;
    private long totalProperties;
    private long activeProperties;
    private long totalEnquiries;
    private long newLeads;
    private long siteVisits;
    private long serviceRequests;
    private long pendingVerifications;
    private long pendingDealerApprovals;
    private long pendingPartnerApprovals;
    private BigDecimal revenue;
    private long pendingPayments;
    private long completedServices;

    public AdminDashboardSummaryDto() {
    }

    public long getTotalUsers() {
        return totalUsers;
    }

    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }

    public long getTotalBuyers() {
        return totalBuyers;
    }

    public void setTotalBuyers(long totalBuyers) {
        this.totalBuyers = totalBuyers;
    }

    public long getTotalDealers() {
        return totalDealers;
    }

    public void setTotalDealers(long totalDealers) {
        this.totalDealers = totalDealers;
    }

    public long getTotalServicePartners() {
        return totalServicePartners;
    }

    public void setTotalServicePartners(long totalServicePartners) {
        this.totalServicePartners = totalServicePartners;
    }

    public long getTotalProperties() {
        return totalProperties;
    }

    public void setTotalProperties(long totalProperties) {
        this.totalProperties = totalProperties;
    }

    public long getActiveProperties() {
        return activeProperties;
    }

    public void setActiveProperties(long activeProperties) {
        this.activeProperties = activeProperties;
    }

    public long getTotalEnquiries() {
        return totalEnquiries;
    }

    public void setTotalEnquiries(long totalEnquiries) {
        this.totalEnquiries = totalEnquiries;
    }

    public long getNewLeads() {
        return newLeads;
    }

    public void setNewLeads(long newLeads) {
        this.newLeads = newLeads;
    }

    public long getSiteVisits() {
        return siteVisits;
    }

    public void setSiteVisits(long siteVisits) {
        this.siteVisits = siteVisits;
    }

    public long getServiceRequests() {
        return serviceRequests;
    }

    public void setServiceRequests(long serviceRequests) {
        this.serviceRequests = serviceRequests;
    }

    public long getPendingVerifications() {
        return pendingVerifications;
    }

    public void setPendingVerifications(long pendingVerifications) {
        this.pendingVerifications = pendingVerifications;
    }

    public long getPendingDealerApprovals() {
        return pendingDealerApprovals;
    }

    public void setPendingDealerApprovals(long pendingDealerApprovals) {
        this.pendingDealerApprovals = pendingDealerApprovals;
    }

    public long getPendingPartnerApprovals() {
        return pendingPartnerApprovals;
    }

    public void setPendingPartnerApprovals(long pendingPartnerApprovals) {
        this.pendingPartnerApprovals = pendingPartnerApprovals;
    }

    public BigDecimal getRevenue() {
        return revenue;
    }

    public void setRevenue(BigDecimal revenue) {
        this.revenue = revenue;
    }

    public long getPendingPayments() {
        return pendingPayments;
    }

    public void setPendingPayments(long pendingPayments) {
        this.pendingPayments = pendingPayments;
    }

    public long getCompletedServices() {
        return completedServices;
    }

    public void setCompletedServices(long completedServices) {
        this.completedServices = completedServices;
    }
}
