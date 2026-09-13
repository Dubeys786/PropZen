package com.propzen.service.service;

import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.ServiceJourneyEventDto;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.repository.ServiceJourneyEventRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ServiceJourneyService {

    private final ServiceJourneyEventRepository journeyEventRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;

    public ServiceJourneyService(ServiceJourneyEventRepository journeyEventRepository,
                                 ServiceRequestRepository requestRepository,
                                 ServicePartnerProfileRepository partnerProfileRepository) {
        this.journeyEventRepository = journeyEventRepository;
        this.requestRepository = requestRepository;
        this.partnerProfileRepository = partnerProfileRepository;
    }

    @Transactional(readOnly = true)
    public List<ServiceJourneyEventDto> getJourneyTimeline(UUID serviceRequestId, AuthenticatedUser actor) {
        ServiceRequest request = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertJourneyAccess(request, actor);

        return journeyEventRepository.findByServiceRequestIdOrderByCreatedAtAsc(serviceRequestId)
                .stream()
                .map(ServiceJourneyEventDto::fromEntity)
                .collect(Collectors.toList());
    }

    private void assertJourneyAccess(ServiceRequest request, AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");

        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) return;

        // Customer check
        if (request.getCustomerId().equals(actor.getUserId())) return;

        // Partner check
        if (request.getPartnerId() != null) {
            ServicePartnerProfile partner = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (partner != null && partner.getId().equals(request.getPartnerId())) {
                return;
            }
        }

        throw new ForbiddenException("Access denied to service journey timeline");
    }
}
