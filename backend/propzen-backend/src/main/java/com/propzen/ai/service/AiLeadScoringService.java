package com.propzen.ai.service;

import com.propzen.ai.dto.LeadScoreDto;
import com.propzen.ai.entity.AiLeadScore;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.ai.repository.AiLeadScoreRepository;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.repository.CrmFollowUpRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.SiteVisitRepository;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service("aiLeadScoringService")
public class AiLeadScoringService {

    private final LeadRepository leadRepository;
    private final SiteVisitRepository siteVisitRepository;
    private final CrmFollowUpRepository followUpRepository;
    private final AiLeadScoreRepository leadScoreRepository;
    private final AiOrchestrator orchestrator;
    private final com.propzen.crm.service.LeadService leadService;

    public AiLeadScoringService(LeadRepository leadRepository,
                                SiteVisitRepository siteVisitRepository,
                                CrmFollowUpRepository followUpRepository,
                                AiLeadScoreRepository leadScoreRepository,
                                AiOrchestrator orchestrator,
                                com.propzen.crm.service.LeadService leadService) {
        this.leadRepository = leadRepository;
        this.siteVisitRepository = siteVisitRepository;
        this.followUpRepository = followUpRepository;
        this.leadScoreRepository = leadScoreRepository;
        this.orchestrator = orchestrator;
        this.leadService = leadService;
    }

    @Transactional
    public LeadScoreDto calculateLeadScore(UUID leadId, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
        leadService.assertLeadAccess(lead, actor);

        boolean hasSiteVisit = (lead.getPhone() != null && !siteVisitRepository.findByUserPhone(lead.getPhone()).isEmpty())
                || (lead.getUserId() != null && !siteVisitRepository.findByUserId(lead.getUserId()).isEmpty());
        long followUpCount = followUpRepository.findByLeadIdOrderByFollowupAtAsc(leadId).size();

        Map<String, Object> payload = new HashMap<>();
        payload.put("leadId", lead.getId());
        payload.put("name", lead.getName());
        payload.put("stage", lead.getStage() != null ? lead.getStage().name() : "NEW_LEAD");
        payload.put("status", lead.getStatus() != null ? lead.getStatus().name() : "NEW");
        payload.put("hasSiteVisit", hasSiteVisit);
        payload.put("followUpCount", followUpCount);
        payload.put("budgetMatches", true);

        AiRequest<Map<String, Object>> request = AiRequest.of(
                AiOperationType.LEAD_SCORING,
                payload,
                actor != null ? actor.getUserId() : null
        );

        AiResponse<LeadScoreDto> response = orchestrator.execute(request, LeadScoreDto.class);
        LeadScoreDto scoreDto = response.getData();

        // Persist to ai_lead_scores
        AiLeadScore record = new AiLeadScore(
                lead.getId(),
                scoreDto.getScore(),
                scoreDto.getClassification(),
                String.join("; ", scoreDto.getReasons()),
                scoreDto.getNextAction(),
                scoreDto.getConfidence()
        );
        leadScoreRepository.save(record);

        return scoreDto;
    }

    @Transactional
    public LeadScoreDto calculateAndSaveLeadScore(UUID leadId, AuthenticatedUser actor) {
        return calculateLeadScore(leadId, actor);
    }

    @Transactional(readOnly = true)
    public LeadScoreDto getLatestScore(UUID leadId) {
        return leadScoreRepository.findTopByLeadIdOrderByScoredAtDesc(leadId)
                .map(s -> new LeadScoreDto(
                        s.getLeadId(),
                        s.getScore(),
                        s.getClassification(),
                        s.getReasons() != null ? java.util.Arrays.asList(s.getReasons().split(";\\s*")) : java.util.List.of(),
                        s.getNextAction(),
                        s.getConfidence() != null ? s.getConfidence() : 0.90
                ))
                .orElse(null);
    }
}
