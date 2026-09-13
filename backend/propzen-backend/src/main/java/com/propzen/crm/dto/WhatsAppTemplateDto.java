package com.propzen.crm.dto;

import com.propzen.crm.entity.WhatsAppTemplateEntity;
import com.propzen.crm.model.WhatsAppTemplateCategory;
import com.propzen.crm.model.WhatsAppTemplateStatus;

import java.time.OffsetDateTime;
import java.util.UUID;

public class WhatsAppTemplateDto {

    private UUID id;
    private String name;
    private String templateName;
    private String language;
    private WhatsAppTemplateCategory category;
    private String content;
    private String providerTemplateId;
    private WhatsAppTemplateStatus status;
    private String variables;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public WhatsAppTemplateDto() {
    }

    public static WhatsAppTemplateDto fromEntity(WhatsAppTemplateEntity entity) {
        if (entity == null) return null;
        WhatsAppTemplateDto dto = new WhatsAppTemplateDto();
        dto.setId(entity.getId());
        dto.setName(entity.getName());
        dto.setTemplateName(entity.getTemplateName());
        dto.setLanguage(entity.getLanguage());
        dto.setCategory(entity.getCategory());
        dto.setContent(entity.getContent());
        dto.setProviderTemplateId(entity.getProviderTemplateId());
        dto.setStatus(entity.getStatus());
        dto.setVariables(entity.getVariables());
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getTemplateName() {
        return templateName;
    }

    public void setTemplateName(String templateName) {
        this.templateName = templateName;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public WhatsAppTemplateCategory getCategory() {
        return category;
    }

    public void setCategory(WhatsAppTemplateCategory category) {
        this.category = category;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getProviderTemplateId() {
        return providerTemplateId;
    }

    public void setProviderTemplateId(String providerTemplateId) {
        this.providerTemplateId = providerTemplateId;
    }

    public WhatsAppTemplateStatus getStatus() {
        return status;
    }

    public void setStatus(WhatsAppTemplateStatus status) {
        this.status = status;
    }

    public String getVariables() {
        return variables;
    }

    public void setVariables(String variables) {
        this.variables = variables;
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
