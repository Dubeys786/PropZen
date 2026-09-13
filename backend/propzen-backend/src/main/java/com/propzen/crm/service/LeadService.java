package com.propzen.crm.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.crm.automation.AutomationEngine;
import com.propzen.crm.automation.AutomationEvent;
import com.propzen.crm.automation.AutomationEventType;
import com.propzen.crm.dto.AssignLeadRequest;
import com.propzen.crm.dto.CreateLeadRequest;
import com.propzen.crm.dto.LeadActivityDto;
import com.propzen.crm.dto.LeadDto;
import com.propzen.crm.dto.LeadSearchRequest;
import com.propzen.crm.dto.UpdateLeadPriorityRequest;
import com.propzen.crm.dto.UpdateLeadRequest;
import com.propzen.crm.dto.UpdateLeadStatusRequest;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.LeadActivity;
import com.propzen.crm.entity.CrmAssignmentHistory;
import com.propzen.crm.model.ActivityType;
import com.propzen.crm.model.CrmActivityType;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.LeadType;
import com.propzen.crm.repository.CrmAssignmentHistoryRepository;
import com.propzen.crm.repository.LeadActivityRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.LeadSpecifications;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.exception.BadRequestException;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Core CRM business service managing lead lifecycle, assignment, follow-ups, and isolation.
 */
@Service
public class LeadService {

    private static final Logger log = LoggerFactory.getLogger(LeadService.class);

    private final LeadRepository leadRepository;
    private final LeadActivityRepository leadActivityRepository;
    private final DealerProfileRepository dealerProfileRepository;
    private final ServicePartnerProfileRepository servicePartnerProfileRepository;
    private final ServicePartnerLeadRoutingService servicePartnerLeadRoutingService;
    private final LeadScoringService leadScoringService;
    private final AutoAssignmentService autoAssignmentService;
    private final AutomationEngine automationEngine;
    private final AuditLogService auditLogService;
    private final LeadDeduplicationService leadDeduplicationService;
    private final CrmAssignmentHistoryRepository assignmentHistoryRepository;
    private final CrmActivityService crmActivityService;

    public LeadService(LeadRepository leadRepository,
                       LeadActivityRepository leadActivityRepository,
                       DealerProfileRepository dealerProfileRepository,
                       ServicePartnerProfileRepository servicePartnerProfileRepository,
                       ServicePartnerLeadRoutingService servicePartnerLeadRoutingService,
                       LeadScoringService leadScoringService,
                       AutoAssignmentService autoAssignmentService,
                       AutomationEngine automationEngine,
                       AuditLogService auditLogService,
                       LeadDeduplicationService leadDeduplicationService,
                       CrmAssignmentHistoryRepository assignmentHistoryRepository,
                       CrmActivityService crmActivityService) {
        this.leadRepository = leadRepository;
        this.leadActivityRepository = leadActivityRepository;
        this.dealerProfileRepository = dealerProfileRepository;
        this.servicePartnerProfileRepository = servicePartnerProfileRepository;
        this.servicePartnerLeadRoutingService = servicePartnerLeadRoutingService;
        this.leadScoringService = leadScoringService;
        this.autoAssignmentService = autoAssignmentService;
        this.automationEngine = automationEngine;
        this.auditLogService = auditLogService;
        this.leadDeduplicationService = leadDeduplicationService;
        this.assignmentHistoryRepository = assignmentHistoryRepository;
        this.crmActivityService = crmActivityService;
    }

    @Transactional
    public LeadDto createLead(CreateLeadRequest request, AuthenticatedUser actor) {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-" + System.currentTimeMillis());
        lead.setName(request.getName().trim());
        lead.setEmail(request.getEmail() != null ? request.getEmail().trim().toLowerCase() : null);
        lead.setPhone(request.getPhone().trim());
        lead.setPropertyId(request.getPropertyId());
        lead.setMessage(request.getMessage());
        lead.setSource(request.getSource() != null ? request.getSource() : LeadSource.WEBSITE);
        lead.setStatus(LeadStatus.NEW);
        lead.setStage(request.getStage() != null ? request.getStage() : LeadStage.NEW_LEAD);
        lead.setLeadType(request.getLeadType() != null ? request.getLeadType() : LeadType.BUYER);
        lead.setNotes(request.getNotes());
        lead.setPriority(request.getPriority() != null ? request.getPriority() : LeadPriority.MEDIUM);
        lead.setBudgetMin(request.getBudgetMin());
        lead.setBudgetMax(request.getBudgetMax());
        lead.setPreferredCity(request.getPreferredCity());
        lead.setPreferredSector(request.getPreferredSector());
        lead.setPreferredPropertyType(request.getPreferredPropertyType());
        lead.setPreferredBhk(request.getPreferredBhk());
        lead.setAssignedTo(request.getAssignedTo());
        lead.setDealerId(request.getDealerId());
        lead.setServiceCategory(request.getServiceCategory());
        lead.setAssignedPartnerId(request.getAssignedPartnerId());
        lead.setAssignmentStatus(request.getAssignmentStatus() != null ? request.getAssignmentStatus() : "UNASSIGNED");

        if (actor != null && lead.getUserId() == null) {
            lead.setUserId(actor.getUserId());
        }

        // Auto assignment if unassigned for property leads
        if (lead.getAssignedTo() == null && (lead.getServiceCategory() == null || lead.getServiceCategory().isBlank())) {
            autoAssignmentService.autoAssign(lead);
        }

        // Calculate score
        lead.setLeadScore(leadScoringService.calculateScore(lead));

        Lead saved = leadDeduplicationService.deduplicateOrSave(lead);

        // Service partner lead routing if service category is present
        if (saved.getServiceCategory() != null && !saved.getServiceCategory().isBlank()) {
            saved = servicePartnerLeadRoutingService.routeAndAssignLead(saved, actor != null ? actor.getUserId() : null);
        }

        // Record creation activity
        LeadActivity activity = new LeadActivity();
        activity.setLeadId(saved.getId());
        activity.setActorUserId(actor != null ? actor.getUserId() : null);
        activity.setType(ActivityType.NOTE);
        activity.setNote("Lead created via " + saved.getSource());
        leadActivityRepository.save(activity);

        crmActivityService.recordSystemActivity(
                saved.getId(),
                saved.getUserId(),
                CrmActivityType.LEAD_CREATED,
                "Lead Created",
                "Lead #" + saved.getLeadNumber() + " created via " + saved.getSource()
        );

        // Trigger automation
        automationEngine.handleEvent(new AutomationEvent(
                AutomationEventType.LEAD_CREATED,
                saved.getId(),
                saved,
                Collections.emptyMap()
        ));

        auditLogService.logAction(
                actor != null ? actor.getUserId() : null,
                "CRM_LEAD_CREATED",
                "crm_leads/" + saved.getId(),
                "Lead #" + saved.getLeadNumber() + " created"
        );

        return toEnrichedDto(saved);
    }

    @Transactional(readOnly = true)
    public LeadDto getLead(UUID id, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));
        assertLeadAccess(lead, actor);
        return toEnrichedDto(lead);
    }

    @Transactional(readOnly = true)
    public Page<LeadDto> searchLeads(LeadSearchRequest request, AuthenticatedUser actor) {
        request.validate();

        UUID effectiveDealerId = request.getDealerId();
        UUID effectiveAssignedTo = request.getAssignedTo();
        UUID effectiveAssignedPartnerId = request.getAssignedPartnerId();

        // Enforce Dealer & Service Partner Isolation
        if (isAdmin(actor)) {
            // Admin has global visibility across all leads or can filter by requested dealerId / partnerId
        } else if (isDealer(actor)) {
            DealerProfile dealer = getDealerProfile(actor.getUserId());
            effectiveDealerId = dealer.getId();
        } else if (isServicePartner(actor)) {
            ServicePartnerProfile partner = getServicePartnerProfile(actor.getUserId());
            effectiveAssignedPartnerId = partner.getId();
        } else {
            throw new ForbiddenException("Only dealers, service partners, and administrators can access CRM leads");
        }

        Specification<Lead> spec = LeadSpecifications.withFilters(
                request.getQ(),
                request.getStatus(),
                request.getPriority(),
                request.getSource(),
                effectiveAssignedTo,
                effectiveDealerId,
                request.getCity(),
                request.getSector(),
                request.getPropertyId(),
                request.getCreatedAfter(),
                request.getCreatedBefore(),
                request.getServiceCategory(),
                effectiveAssignedPartnerId,
                request.getAssignmentStatus()
        );

        Pageable pageable = PageRequest.of(
                request.getPage(),
                request.getSize(),
                request.getSortOrder()
        );

        return leadRepository.findAll(spec, pageable).map(this::toEnrichedDto);
    }

    @Transactional
    public LeadDto updateLead(UUID id, UpdateLeadRequest request, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));
        assertLeadAccess(lead, actor);

        if (request.getName() != null) lead.setName(request.getName().trim());
        if (request.getEmail() != null) lead.setEmail(request.getEmail().trim().toLowerCase());
        if (request.getPhone() != null) lead.setPhone(request.getPhone().trim());
        if (request.getMessage() != null) lead.setMessage(request.getMessage());
        if (request.getPriority() != null) lead.setPriority(request.getPriority());
        if (request.getBudgetMin() != null) lead.setBudgetMin(request.getBudgetMin());
        if (request.getBudgetMax() != null) lead.setBudgetMax(request.getBudgetMax());
        if (request.getPreferredCity() != null) lead.setPreferredCity(request.getPreferredCity());
        if (request.getPreferredSector() != null) lead.setPreferredSector(request.getPreferredSector());
        if (request.getPreferredPropertyType() != null) lead.setPreferredPropertyType(request.getPreferredPropertyType());
        if (request.getPreferredBhk() != null) lead.setPreferredBhk(request.getPreferredBhk());
        if (request.getNextFollowUpAt() != null) lead.setNextFollowUpAt(request.getNextFollowUpAt());
        if (request.getMetadata() != null) lead.setMetadata(request.getMetadata());

        lead.setLeadScore(leadScoringService.calculateScore(lead));
        Lead saved = leadRepository.save(lead);

        auditLogService.logAction(
                actor.getUserId(),
                "CRM_LEAD_UPDATED",
                "crm_leads/" + saved.getId(),
                "Updated lead details"
        );

        return LeadDto.fromEntity(saved);
    }

    @Transactional
    public LeadDto updateStatus(UUID id, UpdateLeadStatusRequest request, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));
        assertLeadAccess(lead, actor);

        LeadStatus oldStatus = lead.getStatus();
        lead.setStatus(request.getStatus());

        if (request.getStatus() == LeadStatus.CONVERTED) {
            lead.setConvertedAt(OffsetDateTime.now());
        } else if (request.getStatus() == LeadStatus.LOST || request.getStatus() == LeadStatus.CLOSED) {
            lead.setLostAt(OffsetDateTime.now());
            if (request.getLostReason() != null) {
                lead.setLostReason(request.getLostReason());
            }
        }

        Lead saved = leadRepository.save(lead);

        // Record status change activity
        LeadActivity activity = new LeadActivity();
        activity.setLeadId(saved.getId());
        activity.setActorUserId(actor.getUserId());
        activity.setType(ActivityType.STATUS_CHANGE);
        activity.setNote(String.format("Status changed from %s to %s. Note: %s",
                oldStatus, request.getStatus(), request.getNote() != null ? request.getNote() : "None"));
        leadActivityRepository.save(activity);

        // Trigger automation
        automationEngine.handleEvent(new AutomationEvent(
                AutomationEventType.LEAD_STATUS_CHANGED,
                saved.getId(),
                saved,
                Collections.emptyMap()
        ));

        auditLogService.logAction(
                actor.getUserId(),
                "CRM_LEAD_STATUS_CHANGED",
                "crm_leads/" + saved.getId(),
                "Status: " + oldStatus + " -> " + request.getStatus()
        );

        return LeadDto.fromEntity(saved);
    }

    @Transactional
    public LeadDto updatePriority(UUID id, UpdateLeadPriorityRequest request, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));
        assertLeadAccess(lead, actor);

        LeadPriority oldPriority = lead.getPriority();
        lead.setPriority(request.getPriority());
        Lead saved = leadRepository.save(lead);

        LeadActivity activity = new LeadActivity();
        activity.setLeadId(saved.getId());
        activity.setActorUserId(actor.getUserId());
        activity.setType(ActivityType.NOTE);
        activity.setNote(String.format("Priority changed from %s to %s", oldPriority, request.getPriority()));
        leadActivityRepository.save(activity);

        return LeadDto.fromEntity(saved);
    }

    @Transactional
    public LeadDto assignLead(UUID id, AssignLeadRequest request, AuthenticatedUser actor) {
        if (!isAdmin(actor)) {
            throw new ForbiddenException("Only administrators can assign or reassign leads");
        }

        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));

        UUID previousUser = lead.getAssignedTo();
        lead.setAssignedTo(request.getAssignedTo());
        if (request.getDealerId() != null) {
            lead.setDealerId(request.getDealerId());
        }

        Lead saved = leadRepository.save(lead);

        assignmentHistoryRepository.save(new CrmAssignmentHistory(
                saved.getId(), previousUser, request.getAssignedTo(), actor.getUserId()
        ));

        LeadActivity activity = new LeadActivity();
        activity.setLeadId(saved.getId());
        activity.setActorUserId(actor.getUserId());
        activity.setType(ActivityType.ASSIGNMENT);
        activity.setNote("Assigned lead to user " + request.getAssignedTo());
        leadActivityRepository.save(activity);

        crmActivityService.recordSystemActivity(
                saved.getId(),
                saved.getUserId(),
                CrmActivityType.ASSIGNED,
                "Lead Assigned",
                "Assigned to user " + request.getAssignedTo()
        );

        automationEngine.handleEvent(new AutomationEvent(
                AutomationEventType.DEALER_ASSIGNED,
                saved.getId(),
                saved,
                Collections.emptyMap()
        ));

        auditLogService.logAction(
                actor.getUserId(),
                "CRM_LEAD_ASSIGNED",
                "crm_leads/" + saved.getId(),
                "Assigned to user " + request.getAssignedTo()
        );

        return LeadDto.fromEntity(saved);
    }

    @Transactional
    public void deleteLead(UUID id, AuthenticatedUser actor) {
        if (!isAdmin(actor)) {
            throw new ForbiddenException("Only administrators can delete leads");
        }
        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));
        leadRepository.delete(lead);

        auditLogService.logAction(
                actor.getUserId(),
                "CRM_LEAD_DELETED",
                "crm_leads/" + id,
                "Deleted lead #" + lead.getLeadNumber()
        );
    }

    @Transactional
    public LeadDto updateStage(UUID id, LeadStage newStage, String notes, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", id));
        assertLeadAccess(lead, actor);

        LeadStage oldStage = lead.getStage();
        lead.setStage(newStage);
        if (notes != null && !notes.isBlank()) {
            lead.setNotes(notes);
        }
        if (newStage == LeadStage.CONVERTED) {
            lead.setStatus(LeadStatus.CONVERTED);
            lead.setConvertedAt(OffsetDateTime.now());
        } else if (newStage == LeadStage.LOST) {
            lead.setStatus(LeadStatus.LOST);
            lead.setLostAt(OffsetDateTime.now());
        }

        Lead saved = leadRepository.save(lead);

        crmActivityService.recordSystemActivity(
                saved.getId(),
                saved.getUserId(),
                CrmActivityType.STAGE_CHANGED,
                "Lead Stage Changed",
                String.format("Stage changed from %s to %s. Notes: %s", oldStage, newStage, notes != null ? notes : "None")
        );

        auditLogService.logAction(
                actor.getUserId(),
                "CRM_LEAD_STAGE_CHANGED",
                "crm_leads/" + saved.getId(),
                "Stage: " + oldStage + " -> " + newStage
        );

        return LeadDto.fromEntity(saved);
    }

    @Transactional
    public LeadDto convertLead(UUID id, AuthenticatedUser actor) {
        return updateStage(id, LeadStage.CONVERTED, "Lead converted successfully", actor);
    }

    @Transactional(readOnly = true)
    public List<LeadActivityDto> getTimeline(UUID leadId, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
        assertLeadAccess(lead, actor);

        return leadActivityRepository.findByLeadIdOrderByCreatedAtDesc(leadId)
                .stream()
                .map(LeadActivityDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<LeadDto> getCustomerLeads(AuthenticatedUser actor) {
        if (actor == null || actor.getUserId() == null) {
            return Collections.emptyList();
        }
        return leadRepository.findByUserId(actor.getUserId())
                .stream()
                .map(this::toEnrichedDto)
                .collect(Collectors.toList());
    }

    public LeadDto toEnrichedDto(Lead lead) {
        LeadDto dto = LeadDto.fromEntity(lead);
        if (lead.getAssignedPartnerId() != null) {
            servicePartnerProfileRepository.findById(lead.getAssignedPartnerId())
                    .ifPresent(p -> dto.setAssignedPartnerName(p.getBusinessName()));
        }
        return dto;
    }

    // Security & Helper Methods

    public void assertLeadAccess(Lead lead, AuthenticatedUser actor) {
        if (actor == null) {
            throw new ForbiddenException("Authentication required");
        }
        if (isAdmin(actor)) {
            return;
        }
        if (isDealer(actor)) {
            DealerProfile dealer = getDealerProfile(actor.getUserId());
            boolean isAssigned = (lead.getDealerId() != null && lead.getDealerId().equals(dealer.getId())) ||
                                 (lead.getAssignedTo() != null && lead.getAssignedTo().equals(actor.getUserId()));
            if (!isAssigned) {
                throw new ForbiddenException("Access denied: You are not assigned to this lead");
            }
            return;
        }
        if (isServicePartner(actor)) {
            ServicePartnerProfile partner = getServicePartnerProfile(actor.getUserId());
            boolean isAssigned = (lead.getAssignedPartnerId() != null && lead.getAssignedPartnerId().equals(partner.getId()));
            if (!isAssigned) {
                throw new ForbiddenException("Access denied: You are not assigned to this service lead");
            }
            return;
        }
        if (lead.getUserId() != null && lead.getUserId().equals(actor.getUserId())) {
            return;
        }
        throw new ForbiddenException("Access denied to CRM resource");
    }

    private boolean isAdmin(AuthenticatedUser user) {
        return user != null && user.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }

    private boolean isDealer(AuthenticatedUser user) {
        return user != null && user.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_DEALER"));
    }

    private boolean isServicePartner(AuthenticatedUser user) {
        return user != null && user.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SERVICE_PARTNER") || a.getAuthority().equals("ROLE_PARTNER"));
    }

    private DealerProfile getDealerProfile(UUID userId) {
        return dealerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ForbiddenException("No dealer profile found for user"));
    }

    private ServicePartnerProfile getServicePartnerProfile(UUID userId) {
        return servicePartnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ForbiddenException("No service partner profile found for user"));
    }
}
