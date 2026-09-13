package com.propzen.ai.service;

import com.propzen.ai.dto.AiFollowUpDraftDto;
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
public class AiFollowUpService {

    private final LeadRepository leadRepository;
    private final AiOrchestrator orchestrator;
    private final com.propzen.crm.service.LeadService leadService;

    public AiFollowUpService(LeadRepository leadRepository,
                             AiOrchestrator orchestrator,
                             com.propzen.crm.service.LeadService leadService) {
        this.leadRepository = leadRepository;
        this.orchestrator = orchestrator;
        this.leadService = leadService;
    }

    @Transactional(readOnly = true)
    public AiFollowUpDraftDto generateFollowUpDraft(UUID leadId, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
        leadService.assertLeadAccess(lead, actor);

        Map<String, Object> payload = new HashMap<>();
        payload.put("leadId", lead.getId());
        payload.put("name", lead.getName());
        payload.put("propertyTitle", lead.getPropertyId() != null ? "Property #" + lead.getPropertyId() : "Selected Property");
        payload.put("stage", lead.getStage() != null ? lead.getStage().name() : "NEW_LEAD");

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.CRM_FOLLOW_UP_DRAFT,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<AiFollowUpDraftDto> resp = orchestrator.execute(req, AiFollowUpDraftDto.class);
        return resp.getData();
    }
}
