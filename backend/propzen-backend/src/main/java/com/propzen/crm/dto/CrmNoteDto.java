package com.propzen.crm.dto;

import com.propzen.crm.entity.CrmNote;

import java.time.OffsetDateTime;
import java.util.UUID;

public class CrmNoteDto {

    private UUID id;
    private UUID leadId;
    private UUID customerId;
    private UUID createdBy;
    private String note;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public CrmNoteDto() {
    }

    public static CrmNoteDto fromEntity(CrmNote entity) {
        if (entity == null) return null;
        CrmNoteDto dto = new CrmNoteDto();
        dto.setId(entity.getId());
        dto.setLeadId(entity.getLeadId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setCreatedBy(entity.getCreatedBy());
        dto.setNote(entity.getNote());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public void setCustomerId(UUID customerId) {
        this.customerId = customerId;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(UUID createdBy) {
        this.createdBy = createdBy;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
