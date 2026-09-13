package com.propzen.crm.dto;

import com.propzen.crm.model.CampaignChannel;
import com.propzen.crm.model.CampaignType;
import com.propzen.crm.model.LeadStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public class CreateCampaignRequest {

    @NotBlank(message = "Campaign name is required")
    private String name;

    private CampaignType type = CampaignType.PROMOTIONAL;

    private CampaignChannel channel = CampaignChannel.WHATSAPP;

    @NotNull(message = "Template ID is required")
    private UUID templateId;

    private LeadStatus targetStatus;
    private String targetCity;
    private String targetSector;
    private List<UUID> specificLeadIds;
    private OffsetDateTime scheduledAt;

    public CreateCampaignRequest() {
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public CampaignType getType() {
        return type;
    }

    public void setType(CampaignType type) {
        this.type = type;
    }

    public CampaignChannel getChannel() {
        return channel;
    }

    public void setChannel(CampaignChannel channel) {
        this.channel = channel;
    }

    public UUID getTemplateId() {
        return templateId;
    }

    public void setTemplateId(UUID templateId) {
        this.templateId = templateId;
    }

    public LeadStatus getTargetStatus() {
        return targetStatus;
    }

    public void setTargetStatus(LeadStatus targetStatus) {
        this.targetStatus = targetStatus;
    }

    public String getTargetCity() {
        return targetCity;
    }

    public void setTargetCity(String targetCity) {
        this.targetCity = targetCity;
    }

    public String getTargetSector() {
        return targetSector;
    }

    public void setTargetSector(String targetSector) {
        this.targetSector = targetSector;
    }

    public List<UUID> getSpecificLeadIds() {
        return specificLeadIds;
    }

    public void setSpecificLeadIds(List<UUID> specificLeadIds) {
        this.specificLeadIds = specificLeadIds;
    }

    public OffsetDateTime getScheduledAt() {
        return scheduledAt;
    }

    public void setScheduledAt(OffsetDateTime scheduledAt) {
        this.scheduledAt = scheduledAt;
    }
}
