package com.propzen.service.dto;

import java.util.ArrayList;
import java.util.List;

public class ServiceRequestDetailDto {
    private ServiceRequestDto request;
    private String customerName;
    private String customerEmail;
    private String customerPhone;
    private String partnerBusinessName;
    private String partnerDisplayName;
    private String partnerPhone;
    private double progressPercentage;
    private List<ServiceMilestoneDto> milestones = new ArrayList<>();
    private List<ServiceDocumentDto> documents = new ArrayList<>();
    private ServiceFeedbackDto feedback;

    public ServiceRequestDto getRequest() { return request; }
    public void setRequest(ServiceRequestDto request) { this.request = request; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String customerEmail) { this.customerEmail = customerEmail; }

    public String getCustomerPhone() { return customerPhone; }
    public void setCustomerPhone(String customerPhone) { this.customerPhone = customerPhone; }

    public String getPartnerBusinessName() { return partnerBusinessName; }
    public void setPartnerBusinessName(String partnerBusinessName) { this.partnerBusinessName = partnerBusinessName; }

    public String getPartnerDisplayName() { return partnerDisplayName; }
    public void setPartnerDisplayName(String partnerDisplayName) { this.partnerDisplayName = partnerDisplayName; }

    public String getPartnerPhone() { return partnerPhone; }
    public void setPartnerPhone(String partnerPhone) { this.partnerPhone = partnerPhone; }

    public double getProgressPercentage() { return progressPercentage; }
    public void setProgressPercentage(double progressPercentage) { this.progressPercentage = progressPercentage; }

    public List<ServiceMilestoneDto> getMilestones() { return milestones; }
    public void setMilestones(List<ServiceMilestoneDto> milestones) { this.milestones = milestones; }

    public List<ServiceDocumentDto> getDocuments() { return documents; }
    public void setDocuments(List<ServiceDocumentDto> documents) { this.documents = documents; }

    public ServiceFeedbackDto getFeedback() { return feedback; }
    public void setFeedback(ServiceFeedbackDto feedback) { this.feedback = feedback; }
}
