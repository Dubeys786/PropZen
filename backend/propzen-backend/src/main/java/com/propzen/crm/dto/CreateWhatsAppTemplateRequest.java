package com.propzen.crm.dto;

import com.propzen.crm.model.WhatsAppTemplateCategory;
import jakarta.validation.constraints.NotBlank;

public class CreateWhatsAppTemplateRequest {

    @NotBlank(message = "Identifier name is required")
    private String name;

    @NotBlank(message = "Template name is required")
    private String templateName;

    private String language = "en";

    private WhatsAppTemplateCategory category = WhatsAppTemplateCategory.UTILITY;

    @NotBlank(message = "Content is required")
    private String content;

    private String providerTemplateId;

    private String variables;

    public CreateWhatsAppTemplateRequest() {
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

    public String getVariables() {
        return variables;
    }

    public void setVariables(String variables) {
        this.variables = variables;
    }
}
