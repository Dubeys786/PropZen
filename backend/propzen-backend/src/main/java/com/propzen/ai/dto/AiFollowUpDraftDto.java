package com.propzen.ai.dto;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

public class AiFollowUpDraftDto implements Serializable {

    private UUID leadId;
    private OffsetDateTime suggestedDate;
    private String suggestedChannel; // CALL, WHATSAPP, EMAIL, SMS
    private String intent;
    private String suggestedMessage;
    private String rationale;

    public AiFollowUpDraftDto() {
    }

    public AiFollowUpDraftDto(UUID leadId, OffsetDateTime suggestedDate, String suggestedChannel,
                              String intent, String suggestedMessage, String rationale) {
        this.leadId = leadId;
        this.suggestedDate = suggestedDate;
        this.suggestedChannel = suggestedChannel;
        this.intent = intent;
        this.suggestedMessage = suggestedMessage;
        this.rationale = rationale;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public OffsetDateTime getSuggestedDate() {
        return suggestedDate;
    }

    public void setSuggestedDate(OffsetDateTime suggestedDate) {
        this.suggestedDate = suggestedDate;
    }

    public String getSuggestedChannel() {
        return suggestedChannel;
    }

    public void setSuggestedChannel(String suggestedChannel) {
        this.suggestedChannel = suggestedChannel;
    }

    public String getIntent() {
        return intent;
    }

    public void setIntent(String intent) {
        this.intent = intent;
    }

    public String getSuggestedMessage() {
        return suggestedMessage;
    }

    public void setSuggestedMessage(String suggestedMessage) {
        this.suggestedMessage = suggestedMessage;
    }

    public String getRationale() {
        return rationale;
    }

    public void setRationale(String rationale) {
        this.rationale = rationale;
    }
}
