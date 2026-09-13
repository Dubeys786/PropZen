package com.propzen.crm.dto;

import com.propzen.crm.entity.Enquiry;

import java.time.OffsetDateTime;
import java.util.UUID;

public class EnquiryDto {

    private UUID id;
    private String propertyId;
    private String propertyTitle;
    private String userName;
    private String userEmail;
    private String userPhone;
    private UUID userId;
    private UUID dealerId;
    private String message;
    private String status;
    private String enquiryType;
    private OffsetDateTime createdAt;

    public EnquiryDto() {
    }

    public static EnquiryDto fromEntity(Enquiry e) {
        if (e == null) return null;
        EnquiryDto dto = new EnquiryDto();
        dto.setId(e.getId());
        dto.setPropertyId(e.getPropertyId());
        dto.setPropertyTitle(e.getPropertyTitle());
        dto.setUserName(e.getUserName());
        dto.setUserEmail(e.getUserEmail());
        dto.setUserPhone(e.getUserPhone());
        dto.setUserId(e.getUserId());
        dto.setDealerId(e.getDealerId());
        dto.setMessage(e.getMessage());
        dto.setStatus(e.getStatus());
        dto.setEnquiryType(e.getEnquiryType());
        dto.setCreatedAt(e.getCreatedAt());
        return dto;
    }

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getEnquiryType() {
        return enquiryType;
    }

    public void setEnquiryType(String enquiryType) {
        this.enquiryType = enquiryType;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
