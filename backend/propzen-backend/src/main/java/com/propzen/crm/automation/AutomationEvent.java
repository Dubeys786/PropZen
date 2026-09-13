package com.propzen.crm.automation;

import com.propzen.crm.entity.Lead;

import java.util.Map;
import java.util.UUID;

public class AutomationEvent {

    private final AutomationEventType eventType;
    private final UUID leadId;
    private final Lead lead;
    private final Map<String, Object> metadata;

    public AutomationEvent(AutomationEventType eventType, UUID leadId, Lead lead, Map<String, Object> metadata) {
        this.eventType = eventType;
        this.leadId = leadId;
        this.lead = lead;
        this.metadata = metadata;
    }

    public AutomationEventType getEventType() {
        return eventType;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public Lead getLead() {
        return lead;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }
}
