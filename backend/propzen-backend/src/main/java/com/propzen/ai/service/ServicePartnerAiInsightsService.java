package com.propzen.ai.service;

import com.propzen.ai.dto.ServicePartnerAiInsightsDto;
import com.propzen.ai.model.AiOperationType;
import com.propzen.ai.model.AiRequest;
import com.propzen.ai.model.AiResponse;
import com.propzen.ai.orchestrator.AiOrchestrator;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class ServicePartnerAiInsightsService {

    private final ServicePartnerProfileRepository partnerRepository;
    private final ServiceRequestRepository serviceRequestRepository;
    private final AiOrchestrator orchestrator;

    public ServicePartnerAiInsightsService(ServicePartnerProfileRepository partnerRepository,
                                           ServiceRequestRepository serviceRequestRepository,
                                           AiOrchestrator orchestrator) {
        this.partnerRepository = partnerRepository;
        this.serviceRequestRepository = serviceRequestRepository;
        this.orchestrator = orchestrator;
    }

    @Transactional(readOnly = true)
    public ServicePartnerAiInsightsDto getPartnerInsights(UUID requestedPartnerId, AuthenticatedUser actor) {
        UUID effectivePartnerId = resolvePartnerId(requestedPartnerId, actor);

        ServicePartnerProfile partner = partnerRepository.findById(effectivePartnerId)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", effectivePartnerId));

        long total = serviceRequestRepository.countByPartnerId(partner.getId());
        long completed = serviceRequestRepository.countByPartnerIdAndStatus(partner.getId(), ServiceRequestStatus.COMPLETED);

        Map<String, Object> payload = new HashMap<>();
        payload.put("partnerId", partner.getId());
        payload.put("totalRequests", total);
        payload.put("completedRequests", completed);

        AiRequest<Map<String, Object>> req = AiRequest.of(
                AiOperationType.PARTNER_INSIGHTS,
                payload,
                actor.getUserId()
        );

        AiResponse<ServicePartnerAiInsightsDto> resp = orchestrator.execute(req, ServicePartnerAiInsightsDto.class);
        return resp.getData();
    }

    private UUID resolvePartnerId(UUID requestedPartnerId, AuthenticatedUser actor) {
        if (actor.isAdmin()) {
            if (requestedPartnerId != null) return requestedPartnerId;
            return partnerRepository.findAll().stream().findFirst()
                    .map(ServicePartnerProfile::getId)
                    .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", "none"));
        }

        ServicePartnerProfile profile = partnerRepository.findByUserId(actor.getUserId())
                .orElseThrow(() -> new ForbiddenException("Only registered service partners or administrators can access partner AI insights"));

        if (requestedPartnerId != null && !requestedPartnerId.equals(profile.getId())) {
            throw new ForbiddenException("Cross-tenant access prohibited. Partners can only access their own AI insights.");
        }

        return profile.getId();
    }
}
