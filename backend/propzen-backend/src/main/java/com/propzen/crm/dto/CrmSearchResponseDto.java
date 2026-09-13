package com.propzen.crm.dto;

import java.util.ArrayList;
import java.util.List;

public class CrmSearchResponseDto {

    private String query;
    private List<LeadDto> leads = new ArrayList<>();
    private List<EnquiryDto> enquiries = new ArrayList<>();
    private List<Object> customers = new ArrayList<>();
    private List<Object> properties = new ArrayList<>();
    private List<Object> siteVisits = new ArrayList<>();
    private List<Object> serviceRequests = new ArrayList<>();

    public CrmSearchResponseDto() {
    }

    public CrmSearchResponseDto(String query) {
        this.query = query;
    }

    public String getQuery() {
        return query;
    }

    public void setQuery(String query) {
        this.query = query;
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

    public List<Object> getCustomers() {
        return customers;
    }

    public void setCustomers(List<Object> customers) {
        this.customers = customers;
    }

    public List<Object> getProperties() {
        return properties;
    }

    public void setProperties(List<Object> properties) {
        this.properties = properties;
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
}
