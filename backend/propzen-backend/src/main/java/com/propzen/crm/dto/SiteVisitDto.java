package com.propzen.crm.dto;

import com.propzen.crm.entity.SiteVisit;

import java.time.OffsetDateTime;
import java.util.UUID;

public class SiteVisitDto {

    private UUID id;
    private String propertyId;
    private String propertyTitle;
    private String userName;
    private String userEmail;
    private String userPhone;
    private UUID userId;
    private UUID dealerId;
    private String visitDate;
    private String timeSlot;
    private Integer visitorCount;
    private Boolean cabRequired;
    private String status;
    private String metadata;
    private OffsetDateTime createdAt;

    public SiteVisitDto() {
    }

    public static SiteVisitDto fromEntity(SiteVisit entity) {
        if (entity == null) {
            return null;
        }
        SiteVisitDto dto = new SiteVisitDto();
        dto.setId(entity.getId());
        dto.setPropertyId(entity.getPropertyId());
        dto.setPropertyTitle(entity.getPropertyTitle());
        dto.setUserName(entity.getUserName());
        dto.setUserEmail(entity.getUserEmail());
        dto.setUserPhone(entity.getUserPhone());
        dto.setUserId(entity.getUserId());
        dto.setDealerId(entity.getDealerId());
        dto.setVisitDate(entity.getVisitDate());
        dto.setTimeSlot(entity.getTimeSlot());
        dto.setVisitorCount(entity.getVisitorCount());
        dto.setCabRequired(entity.getCabRequired());
        dto.setStatus(entity.getStatus());
        dto.setMetadata(entity.getMetadata());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }

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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
