package com.propzen.crm.entity;

import com.propzen.crm.model.WhatsAppTemplateCategory;
import com.propzen.crm.model.WhatsAppTemplateStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Entity representing official Meta WhatsApp Business templates.
 */
@Entity
@Table(name = "whatsapp_templates")
public class WhatsAppTemplateEntity implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "name", nullable = false, unique = true, length = 100)
    private String name;

    @Column(name = "template_name", nullable = false, length = 100)
    private String templateName;

    @Column(name = "language", nullable = false, length = 10)
    private String language = "en";

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 30)
    private WhatsAppTemplateCategory category = WhatsAppTemplateCategory.UTILITY;

    @Column(name = "content", nullable = false, columnDefinition = "text")
    private String content;

    @Column(name = "provider_template_id", length = 100)
    private String providerTemplateId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    private WhatsAppTemplateStatus status = WhatsAppTemplateStatus.APPROVED;

    @Column(name = "variables", columnDefinition = "text")
    private String variables;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public WhatsAppTemplateEntity() {
    }

    public WhatsAppTemplateEntity(String name, String templateName, String language, WhatsAppTemplateCategory category, String content, String variables) {
        this.name = name;
        this.templateName = templateName;
        this.language = language != null ? language : "en";
        this.category = category != null ? category : WhatsAppTemplateCategory.UTILITY;
        this.content = content;
        this.variables = variables;
        this.status = WhatsAppTemplateStatus.APPROVED;
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = OffsetDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
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
