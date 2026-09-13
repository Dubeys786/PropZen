package com.propzen.crm.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.Map;
import java.util.UUID;

public class OneClickWhatsAppRequest {

    private UUID leadId;
    private UUID customerId;

    @NotBlank(message = "Recipient phone number is required")
    private String toPhone;

    @NotBlank(message = "Template name is required")
    private String templateName;

    private Map<String, String> variables;

    public OneClickWhatsAppRequest() {
    }

    public OneClickWhatsAppRequest(String toPhone, String templateName, Map<String, String> variables) {
        this.toPhone = toPhone;
        this.templateName = templateName;
        this.variables = variables;
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

    public String getToPhone() {
        return toPhone;
    }

    public void setToPhone(String toPhone) {
        this.toPhone = toPhone;
    }

    public String getTemplateName() {
        return templateName;
    }

    public void setTemplateName(String templateName) {
        this.templateName = templateName;
    }

    public Map<String, String> getVariables() {
        return variables;
    }

    public void setVariables(Map<String, String> variables) {
        this.variables = variables;
    }
}
