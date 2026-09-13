package com.propzen.crm.dto;

public class CrmDashboardDto {

    private long totalLeads;
    private long newLeads;
    private long contactedLeads;
    private long qualifiedLeads;
    private long followUpsDue;
    private long siteVisits;
    private long convertedLeads;
    private long lostLeads;
    private double conversionRate;

    public CrmDashboardDto() {
    }

    public CrmDashboardDto(long totalLeads, long newLeads, long contactedLeads, long qualifiedLeads,
                           long followUpsDue, long siteVisits, long convertedLeads, long lostLeads,
                           double conversionRate) {
        this.totalLeads = totalLeads;
        this.newLeads = newLeads;
        this.contactedLeads = contactedLeads;
        this.qualifiedLeads = qualifiedLeads;
        this.followUpsDue = followUpsDue;
        this.siteVisits = siteVisits;
        this.convertedLeads = convertedLeads;
        this.lostLeads = lostLeads;
        this.conversionRate = conversionRate;
    }

    // Getters and Setters

    public long getTotalLeads() {
        return totalLeads;
    }

    public void setTotalLeads(long totalLeads) {
        this.totalLeads = totalLeads;
    }

    public long getNewLeads() {
        return newLeads;
    }

    public void setNewLeads(long newLeads) {
        this.newLeads = newLeads;
    }

    public long getContactedLeads() {
        return contactedLeads;
    }

    public void setContactedLeads(long contactedLeads) {
        this.contactedLeads = contactedLeads;
    }

    public long getQualifiedLeads() {
        return qualifiedLeads;
    }

    public void setQualifiedLeads(long qualifiedLeads) {
        this.qualifiedLeads = qualifiedLeads;
    }

    public long getFollowUpsDue() {
        return followUpsDue;
    }

    public void setFollowUpsDue(long followUpsDue) {
        this.followUpsDue = followUpsDue;
    }

    public long getSiteVisits() {
        return siteVisits;
    }

    public void setSiteVisits(long siteVisits) {
        this.siteVisits = siteVisits;
    }

    public long getConvertedLeads() {
        return convertedLeads;
    }

    public void setConvertedLeads(long convertedLeads) {
        this.convertedLeads = convertedLeads;
    }

    public long getLostLeads() {
        return lostLeads;
    }

    public void setLostLeads(long lostLeads) {
        this.lostLeads = lostLeads;
    }

    public double getConversionRate() {
        return conversionRate;
    }

    public void setConversionRate(double conversionRate) {
        this.conversionRate = conversionRate;
    }
}
