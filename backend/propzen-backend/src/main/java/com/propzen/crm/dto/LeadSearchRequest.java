package com.propzen.crm.dto;

import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStatus;
import com.propzen.exception.BadRequestException;
import org.springframework.data.domain.Sort;

import java.time.OffsetDateTime;
import java.util.UUID;

public class LeadSearchRequest {

    private String q;
    private LeadStatus status;
    private LeadPriority priority;
    private LeadSource source;
    private UUID assignedTo;
    private UUID dealerId;
    private String city;
    private String sector;
    private String propertyId;
    private String serviceCategory;
    private UUID assignedPartnerId;
    private String assignmentStatus;
    private OffsetDateTime createdAfter;
    private OffsetDateTime createdBefore;
    private String sort = "newest";
    private Integer page = 0;
    private Integer size = 20;

    public LeadSearchRequest() {
    }

    public void validate() {
        if (page != null && page < 0) {
            throw new BadRequestException("Page index cannot be negative");
        }
        if (size != null && (size < 1 || size > 100)) {
            throw new BadRequestException("Page size must be between 1 and 100");
        }
    }

    public Sort getSortOrder() {
        if (sort == null || sort.isBlank() || "newest".equalsIgnoreCase(sort)) {
            return Sort.by(Sort.Direction.DESC, "createdAt");
        }
        if ("oldest".equalsIgnoreCase(sort)) {
            return Sort.by(Sort.Direction.ASC, "createdAt");
        }
        if ("score_high".equalsIgnoreCase(sort) || "score".equalsIgnoreCase(sort)) {
            return Sort.by(Sort.Direction.DESC, "leadScore");
        }
        if ("follow_up".equalsIgnoreCase(sort)) {
            return Sort.by(Sort.Direction.ASC, "nextFollowUpAt");
        }
        return Sort.by(Sort.Direction.DESC, "createdAt");
    }

    // Getters and Setters

    public String getQ() {
        return q;
    }

    public void setQ(String q) {
        this.q = q;
    }

    public LeadStatus getStatus() {
        return status;
    }

    public void setStatus(LeadStatus status) {
        this.status = status;
    }

    public LeadPriority getPriority() {
        return priority;
    }

    public void setPriority(LeadPriority priority) {
        this.priority = priority;
    }

    public LeadSource getSource() {
        return source;
    }

    public void setSource(LeadSource source) {
        this.source = source;
    }

    public UUID getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(UUID assignedTo) {
        this.assignedTo = assignedTo;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getSector() {
        return sector;
    }

    public void setSector(String sector) {
        this.sector = sector;
    }

    public String getPropertyId() {
        return propertyId;
    }

    public void setPropertyId(String propertyId) {
        this.propertyId = propertyId;
    }

    public OffsetDateTime getCreatedAfter() {
        return createdAfter;
    }

    public void setCreatedAfter(OffsetDateTime createdAfter) {
        this.createdAfter = createdAfter;
    }

    public OffsetDateTime getCreatedBefore() {
        return createdBefore;
    }

    public void setCreatedBefore(OffsetDateTime createdBefore) {
        this.createdBefore = createdBefore;
    }

    public String getSort() {
        return sort;
    }

    public void setSort(String sort) {
        this.sort = sort;
    }

    public Integer getPage() {
        return page != null ? page : 0;
    }

    public void setPage(Integer page) {
        this.page = page;
    }

    public Integer getSize() {
        return size != null ? size : 20;
    }

    public void setSize(Integer size) {
        this.size = size;
    }

    public String getServiceCategory() {
        return serviceCategory;
    }

    public void setServiceCategory(String serviceCategory) {
        this.serviceCategory = serviceCategory;
    }

    public UUID getAssignedPartnerId() {
        return assignedPartnerId;
    }

    public void setAssignedPartnerId(UUID assignedPartnerId) {
        this.assignedPartnerId = assignedPartnerId;
    }

    public String getAssignmentStatus() {
        return assignmentStatus;
    }

    public void setAssignmentStatus(String assignmentStatus) {
        this.assignmentStatus = assignmentStatus;
    }
}
