package com.propzen.ai.service;

import com.propzen.ai.dto.DealerAiInsightsDto;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class DealerAiInsightsService {

    private final DealerProfileRepository dealerRepository;
    private final LeadRepository leadRepository;
    private final AiOrchestrator orchestrator;

    public DealerAiInsightsService(DealerProfileRepository dealerRepository,
                                   LeadRepository leadRepository,
                                   AiOrchestrator orchestrator) {
        this.dealerRepository = dealerRepository;
        this.leadRepository = leadRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional(readOnly = true)
    public DealerAiInsightsDto getDealerInsights(UUID requestedDealerId, AuthenticatedUser actor) {
        UUID effectiveDealerId = resolveDealerId(requestedDealerId, actor);

        DealerProfile dealer = dealerRepository.findById(effectiveDealerId)
                .orElseThrow(() -> new ResourceNotFoundException("DealerProfile", effectiveDealerId));

        long assigned = leadRepository.countByAssignedTo(dealer.getUserId());
        long converted = leadRepository.countByAssignedToAndStatus(dealer.getUserId(), LeadStatus.CONVERTED);

        Map<String, Object> payload = new HashMap<>();
        payload.put("dealerId", dealer.getId());
        payload.put("assignedLeadsCount", assigned);
        payload.put("convertedLeadsCount", converted);

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.DEALER_INSIGHTS,
                payload,
                actor.getUserId()
        );

        AiResponse<DealerAiInsightsDto> resp = orchestrator.execute(req, DealerAiInsightsDto.class);
        return resp.getData();
    }

    private UUID resolveDealerId(UUID requestedDealerId, AuthenticatedUser actor) {
        if (actor.isAdmin()) {
            if (requestedDealerId != null) return requestedDealerId;
            return dealerRepository.findAll().stream().findFirst()
                    .map(DealerProfile::getId)
                    .orElseThrow(() -> new ResourceNotFoundException("DealerProfile", "none"));
        }

        DealerProfile profile = dealerRepository.findByUserId(actor.getUserId())
                .orElseThrow(() -> new ForbiddenException("Only registered dealers or administrators can access dealer AI insights"));

        if (requestedDealerId != null && !requestedDealerId.equals(profile.getId())) {
            throw new ForbiddenException("Cross-tenant access prohibited. Dealers can only access their own AI insights.");
        }

        return profile.getId();
    }
}
