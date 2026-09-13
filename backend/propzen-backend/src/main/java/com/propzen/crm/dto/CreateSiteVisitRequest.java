package com.propzen.crm.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public class CreateSiteVisitRequest {

    private String propertyId;

    private String propertyTitle;

    @NotBlank(message = "User name is required")
    @Size(max = 255, message = "Name must not exceed 255 characters")
    private String userName;

    private String userEmail;

    @NotBlank(message = "User phone is required")
    @Size(max = 50, message = "Phone must not exceed 50 characters")
    private String userPhone;

    private UUID dealerId;

    @NotBlank(message = "Visit date is required")
    private String visitDate;

    @NotBlank(message = "Time slot is required")
    private String timeSlot;

    @Min(value = 1, message = "Visitor count must be at least 1")
    private Integer visitorCount = 1;

    private Boolean cabRequired = false;

    private String metadata;

    public CreateSiteVisitRequest() {
    }

    public String getPropertyId() {
        return propertyId;
    }

    public void setPropertyId(String propertyId) {
        this.propertyId = propertyId;
    }

    public String getPropertyTitle() {
        return propertyTitle;
    }

    public void setPropertyTitle(String propertyTitle) {
        this.propertyTitle = propertyTitle;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getUserPhone() {
        return userPhone;
    }

    public void setUserPhone(String userPhone) {
        this.userPhone = userPhone;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }

    public String getVisitDate() {
        return visitDate;
    }

    public void setVisitDate(String visitDate) {
        this.visitDate = visitDate;
    }

    public String getTimeSlot() {
        return timeSlot;
    }

    public void setTimeSlot(String timeSlot) {
        this.timeSlot = timeSlot;
    }

    public Integer getVisitorCount() {
        return visitorCount;
    }

    public void setVisitorCount(Integer visitorCount) {
        this.visitorCount = visitorCount;
    }

    public Boolean getCabRequired() {
        return cabRequired;
    }

    public void setCabRequired(Boolean cabRequired) {
        this.cabRequired = cabRequired;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
}
