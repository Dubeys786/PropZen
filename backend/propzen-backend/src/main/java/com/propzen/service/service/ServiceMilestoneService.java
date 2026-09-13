package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.CreateMilestoneRequest;
import com.propzen.service.dto.ServiceMilestoneDto;
import com.propzen.service.dto.UpdateMilestoneRequest;
import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.entity.ServiceMilestone;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.MilestoneStatus;
import com.propzen.service.model.ServiceJourneyEventType;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.repository.ServiceJourneyEventRepository;
import com.propzen.service.repository.ServiceMilestoneRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ServiceMilestoneService {

    private final ServiceMilestoneRepository milestoneRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final ServiceJourneyEventRepository journeyEventRepository;
    private final AuditLogService auditLogService;

    public ServiceMilestoneService(ServiceMilestoneRepository milestoneRepository,
                                   ServiceRequestRepository requestRepository,
                                   ServicePartnerProfileRepository partnerProfileRepository,
                                   ServiceJourneyEventRepository journeyEventRepository,
                                   AuditLogService auditLogService) {
        this.milestoneRepository = milestoneRepository;
        this.requestRepository = requestRepository;
        this.partnerProfileRepository = partnerProfileRepository;
        this.journeyEventRepository = journeyEventRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public List<ServiceMilestoneDto> getMilestones(UUID serviceRequestId, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertMilestoneAccess(sr, actor);

        return milestoneRepository.findByServiceRequestIdOrderBySequenceNumberAsc(serviceRequestId)
                .stream()
                .map(ServiceMilestoneDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ServiceMilestoneDto createMilestone(UUID serviceRequestId, CreateMilestoneRequest request, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertPartnerOrAdminAccess(sr, actor);

        ServiceMilestone milestone = new ServiceMilestone();
        milestone.setServiceRequestId(sr.getId());
        milestone.setTitle(request.getTitle().trim());
        milestone.setDescription(request.getDescription());
        milestone.setSequenceNumber(request.getSequenceNumber() != null ? request.getSequenceNumber() : 0);
        milestone.setAmount(request.getAmount() != null ? request.getAmount() : java.math.BigDecimal.ZERO);
        milestone.setStatus(MilestoneStatus.PENDING);
        milestone.setDueDate(request.getDueDate());

        ServiceMilestone saved = milestoneRepository.save(milestone);

        // Record Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(sr.getId());
        event.setEventType(ServiceJourneyEventType.MILESTONE_CREATED);
        event.setTitle("Milestone Created: " + saved.getTitle());
        event.setDescription("Amount: " + saved.getAmount() + ". Sequence: " + saved.getSequenceNumber());
        event.setCreatedBy(actor.getUserId());
        journeyEventRepository.save(event);

        auditLogService.logAction(
                actor.getUserId(),
                "SERVICE_MILESTONE_CREATED",
                "public.service_milestones/" + saved.getId(),
                "Created milestone " + saved.getTitle()
        );

        return ServiceMilestoneDto.fromEntity(saved);
    }

    @Transactional
    public ServiceMilestoneDto updateMilestone(UUID milestoneId, UpdateMilestoneRequest request, AuthenticatedUser actor) {
        ServiceMilestone milestone = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceMilestone", milestoneId));

        ServiceRequest sr = requestRepository.findById(milestone.getServiceRequestId())
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", milestone.getServiceRequestId()));

        assertPartnerOrAdminAccess(sr, actor);

        if (request.getTitle() != null) milestone.setTitle(request.getTitle().trim());
        if (request.getDescription() != null) milestone.setDescription(request.getDescription());
        if (request.getSequenceNumber() != null) milestone.setSequenceNumber(request.getSequenceNumber());
        if (request.getAmount() != null) milestone.setAmount(request.getAmount());
        if (request.getDueDate() != null) milestone.setDueDate(request.getDueDate());
        if (request.getStatus() != null) {
            // Partners cannot mark milestone as APPROVED directly (only customer/admin can approve)
            boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
            if (request.getStatus() == MilestoneStatus.APPROVED && !isAdmin) {
                throw new ForbiddenException("Partners cannot self-approve milestones as customer approval");
            }
            milestone.setStatus(request.getStatus());
            if (request.getStatus() == MilestoneStatus.COMPLETED || request.getStatus() == MilestoneStatus.APPROVED) {
                milestone.setCompletedAt(OffsetDateTime.now());
            }
        }

        ServiceMilestone saved = milestoneRepository.save(milestone);
        return ServiceMilestoneDto.fromEntity(saved);
    }

    @Transactional
    public ServiceMilestoneDto approveMilestone(UUID milestoneId, AuthenticatedUser actor) {
        ServiceMilestone milestone = milestoneRepository.findById(milestoneId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceMilestone", milestoneId));

        ServiceRequest sr = requestRepository.findById(milestone.getServiceRequestId())
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", milestone.getServiceRequestId()));

        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        boolean isCustomer = sr.getCustomerId().equals(actor.getUserId());

        if (!isAdmin && !isCustomer) {
            throw new ForbiddenException("Only the customer or administrator can approve a milestone");
        }

        milestone.setStatus(MilestoneStatus.APPROVED);
        milestone.setCompletedAt(OffsetDateTime.now());
        ServiceMilestone saved = milestoneRepository.save(milestone);

        // Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(sr.getId());
        event.setEventType(ServiceJourneyEventType.MILESTONE_COMPLETED);
        event.setTitle("Milestone Approved: " + saved.getTitle());
        event.setDescription("Milestone approved by " + (isCustomer ? "Customer" : "Administrator"));
        event.setCreatedBy(actor.getUserId());
        journeyEventRepository.save(event);

        auditLogService.logAction(
                actor.getUserId(),
                "SERVICE_MILESTONE_APPROVED",
                "public.service_milestones/" + saved.getId(),
                "Milestone " + saved.getTitle() + " approved"
        );

        return ServiceMilestoneDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public double calculateProgressPercentage(UUID serviceRequestId) {
        List<ServiceMilestone> milestones = milestoneRepository.findByServiceRequestIdOrderBySequenceNumberAsc(serviceRequestId);
        if (milestones.isEmpty()) {
            ServiceRequest sr = requestRepository.findById(serviceRequestId).orElse(null);
            if (sr == null) return 0.0;
            if (sr.getStatus() == ServiceRequestStatus.COMPLETED) return 100.0;
            if (sr.getStatus() == ServiceRequestStatus.IN_PROGRESS) return 50.0;
            if (sr.getStatus() == ServiceRequestStatus.ACCEPTED) return 10.0;
            return 0.0;
        }

        long completed = milestones.stream()
                .filter(m -> m.getStatus() == MilestoneStatus.COMPLETED || m.getStatus() == MilestoneStatus.APPROVED)
                .count();

        double pct = ((double) completed / milestones.size()) * 100.0;
        return Math.round(pct * 10.0) / 10.0;
    }

    private void assertMilestoneAccess(ServiceRequest request, AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");
        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) return;

        if (request.getCustomerId().equals(actor.getUserId())) return;

        if (request.getPartnerId() != null) {
            ServicePartnerProfile partner = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (partner != null && partner.getId().equals(request.getPartnerId())) {
                return;
            }
        }

        throw new ForbiddenException("Access denied to service milestones");
    }

    private void assertPartnerOrAdminAccess(ServiceRequest request, AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");
        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) return;

        if (request.getPartnerId() != null) {
            ServicePartnerProfile partner = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (partner != null && partner.getId().equals(request.getPartnerId())) {
                return;
            }
        }

        throw new ForbiddenException("Only the assigned service partner or administrator can modify milestones");
    }
}
