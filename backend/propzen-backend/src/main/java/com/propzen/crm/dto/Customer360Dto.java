package com.propzen.crm.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Aggregated Customer 360 Data Transfer Object containing unified lifecycle data.
 */
public class Customer360Dto {

    private UUID customerId;
    private String fullName;
    private String email;
    private String phone;
    private String role;
    private String city;
    private OffsetDateTime registeredAt;

    private ContactPreferenceDto contactPreferences;

    private List<LeadDto> leads = new ArrayList<>();
    private List<EnquiryDto> enquiries = new ArrayList<>();
    private List<Object> siteVisits = new ArrayList<>();
    private List<Object> serviceRequests = new ArrayList<>();
    private List<CrmCommunicationDto> communications = new ArrayList<>();
    private List<ActivityDto> activities = new ArrayList<>();
    private List<CrmNoteDto> notes = new ArrayList<>();
    private List<FollowUpDto> followups = new ArrayList<>();
    private List<CrmTaskDto> tasks = new ArrayList<>();

    // High-level summary metrics
    private int totalLeads;
    private int totalEnquiries;
    private int totalSiteVisits;
    private int totalServiceRequests;
    private BigDecimal totalSpent = BigDecimal.ZERO;

    public Customer360Dto() {
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public void setCustomerId(UUID customerId) {
        this.customerId = customerId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public OffsetDateTime getRegisteredAt() {
        return registeredAt;
    }

    public void setRegisteredAt(OffsetDateTime registeredAt) {
        this.registeredAt = registeredAt;
    }

    public ContactPreferenceDto getContactPreferences() {
        return contactPreferences;
    }

    public void setContactPreferences(ContactPreferenceDto contactPreferences) {
        this.contactPreferences = contactPreferences;
    }

    public List<LeadDto> getLeads() {
        return leads;
    }

    public void setLeads(List<LeadDto> leads) {
        this.leads = leads;
    }

    public List<EnquiryDto> getEnquiries() {
        return enquiries;
    }

    public void setEnquiries(List<EnquiryDto> enquiries) {
        this.enquiries = enquiries;
    }

    public List<Object> getSiteVisits() {
        return siteVisits;
    }

    public void setSiteVisits(List<Object> siteVisits) {
        this.siteVisits = siteVisits;
    }

    public List<Object> getServiceRequests() {
        return serviceRequests;
    }

    public void setServiceRequests(List<Object> serviceRequests) {
        this.serviceRequests = serviceRequests;
    }

    public List<CrmCommunicationDto> getCommunications() {
        return communications;
    }

    public void setCommunications(List<CrmCommunicationDto> communications) {
        this.communications = communications;
    }

    public List<ActivityDto> getActivities() {
        return activities;
    }

    public void setActivities(List<ActivityDto> activities) {
        this.activities = activities;
    }

    public List<CrmNoteDto> getNotes() {
        return notes;
    }

    public void setNotes(List<CrmNoteDto> notes) {
        this.notes = notes;
    }

    public List<FollowUpDto> getFollowups() {
        return followups;
    }

    public void setFollowups(List<FollowUpDto> followups) {
        this.followups = followups;
    }

    public List<CrmTaskDto> getTasks() {
        return tasks;
    }

    public void setTasks(List<CrmTaskDto> tasks) {
        this.tasks = tasks;
    }

    public int getTotalLeads() {
        return totalLeads;
    }

    public void setTotalLeads(int totalLeads) {
        this.totalLeads = totalLeads;
    }

    public int getTotalEnquiries() {
        return totalEnquiries;
    }

    public void setTotalEnquiries(int totalEnquiries) {
        this.totalEnquiries = totalEnquiries;
    }

    public int getTotalSiteVisits() {
        return totalSiteVisits;
    }

    public void setTotalSiteVisits(int totalSiteVisits) {
        this.totalSiteVisits = totalSiteVisits;
    }

    public int getTotalServiceRequests() {
        return totalServiceRequests;
    }

    public void setTotalServiceRequests(int totalServiceRequests) {
        this.totalServiceRequests = totalServiceRequests;
    }

    public BigDecimal getTotalSpent() {
        return totalSpent;
    }

    public void setTotalSpent(BigDecimal totalSpent) {
        this.totalSpent = totalSpent;
    }
}
