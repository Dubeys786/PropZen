package com.propzen.ai.dto;

import java.io.Serializable;
import java.util.UUID;

public class NextActionDto implements Serializable {

    private UUID leadId;
    private String action;
    private String channel; // CALL, WHATSAPP, EMAIL, SITE_VISIT
    private String priority;
    private String dueWithin;
    private String reason;

    public NextActionDto() {
    }

    public NextActionDto(UUID leadId, String action, String channel, String priority, String dueWithin, String reason) {
        this.leadId = leadId;
        this.action = action;
        this.channel = channel;
        this.priority = priority;
        this.dueWithin = dueWithin;
        this.reason = reason;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public String getChannel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
    }

    public String getDueWithin() {
        return dueWithin;
    }

    public void setDueWithin(String dueWithin) {
        this.dueWithin = dueWithin;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }
}
