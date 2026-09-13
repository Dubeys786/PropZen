package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.CreateDeliverableRequest;
import com.propzen.service.dto.ServiceDeliverableDto;
import com.propzen.service.entity.ServiceDeliverable;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.repository.ServiceDeliverableRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ServiceDeliverableService {

    private final ServiceDeliverableRepository deliverableRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final AuditLogService auditLogService;

    public ServiceDeliverableService(
            ServiceDeliverableRepository deliverableRepository,
            ServiceRequestRepository requestRepository,
            ServicePartnerProfileRepository partnerProfileRepository,
            AuditLogService auditLogService
    ) {
        this.deliverableRepository = deliverableRepository;
        this.requestRepository = requestRepository;
        this.partnerProfileRepository = partnerProfileRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public ServiceDeliverableDto addDeliverable(UUID serviceRequestId, CreateDeliverableRequest request, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertPartnerOrAdminAccess(sr, actor);

        ServiceDeliverable deliverable = new ServiceDeliverable(
                sr.getId(),
                request.getTitle().trim(),
                request.getDescription(),
                request.getFileUrl(),
                actor.getUserId()
        );

        ServiceDeliverable saved = deliverableRepository.save(deliverable);

        auditLogService.logAction(
                actor.getUserId(),
                "SERVICE_DELIVERABLE_SUBMITTED",
                "service_deliverables/" + saved.getId(),
                "Submitted deliverable: " + saved.getTitle()
        );

        return ServiceDeliverableDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ServiceDeliverableDto> getDeliverables(UUID serviceRequestId, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertAccess(sr, actor);

        return deliverableRepository.findByServiceRequestIdOrderByCreatedAtDesc(serviceRequestId).stream()
                .map(ServiceDeliverableDto::fromEntity)
                .collect(Collectors.toList());
    }

    private void assertAccess(ServiceRequest sr, AuthenticatedUser actor) {
        if (actor.isAdmin()) return;
        if (actor.getUserId().equals(sr.getCustomerId())) return;
        if (sr.getPartnerId() != null) {
            ServicePartnerProfile profile = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (profile != null && profile.getId().equals(sr.getPartnerId())) return;
        }
        throw new ForbiddenException("Access denied to this service request deliverables");
    }

    private void assertPartnerOrAdminAccess(ServiceRequest sr, AuthenticatedUser actor) {
        if (actor.isAdmin()) return;
        if (sr.getPartnerId() != null) {
            ServicePartnerProfile profile = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (profile != null && profile.getId().equals(sr.getPartnerId())) return;
        }
        throw new ForbiddenException("Only the assigned service partner or administrator can submit deliverables");
    }
}
