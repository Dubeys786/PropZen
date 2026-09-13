package com.propzen.ai.service;

import com.propzen.ai.dto.CrmAiSummaryDto;
import com.propzen.ai.dto.NextActionDto;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class CrmAiAssistantService {

    private final LeadRepository leadRepository;
    private final AiOrchestrator orchestrator;
    private final com.propzen.crm.service.LeadService leadService;

    public CrmAiAssistantService(LeadRepository leadRepository,
                                 AiOrchestrator orchestrator,
                                 com.propzen.crm.service.LeadService leadService) {
        this.leadRepository = leadRepository;
        this.orchestrator = orchestrator;
        this.leadService = leadService;
    }

    @Transactional(readOnly = true)
    public CrmAiSummaryDto generateLeadSummary(UUID leadId, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
        leadService.assertLeadAccess(lead, actor);

        Map<String, Object> payload = new HashMap<>();
        payload.put("leadId", lead.getId());
        payload.put("name", lead.getName());
        payload.put("stage", lead.getStage() != null ? lead.getStage().name() : "NEW_LEAD");
        payload.put("status", lead.getStatus() != null ? lead.getStatus().name() : "NEW");
        payload.put("notes", lead.getNotes());

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.CRM_LEAD_SUMMARY,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<CrmAiSummaryDto> resp = orchestrator.execute(req, CrmAiSummaryDto.class);
        return resp.getData();
    }

    @Transactional(readOnly = true)
    public NextActionDto recommendNextAction(UUID leadId, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
        leadService.assertLeadAccess(lead, actor);

        Map<String, Object> payload = new HashMap<>();
        payload.put("leadId", lead.getId());
        payload.put("stage", lead.getStage() != null ? lead.getStage().name() : "NEW");
        payload.put("status", lead.getStatus() != null ? lead.getStatus().name() : "NEW");

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.CRM_NEXT_ACTION,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<NextActionDto> resp = orchestrator.execute(req, NextActionDto.class);
        return resp.getData();
    }

    @Transactional(readOnly = true)
    public CrmAiSummaryDto summarizeConversation(UUID leadId, String conversationText, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
        leadService.assertLeadAccess(lead, actor);

        Map<String, Object> payload = new HashMap<>();
        payload.put("leadId", lead.getId());
        payload.put("conversationText", conversationText);

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.CRM_CONVERSATION_SUMMARY,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<CrmAiSummaryDto> resp = orchestrator.execute(req, CrmAiSummaryDto.class);
        return resp.getData();
    }
}
