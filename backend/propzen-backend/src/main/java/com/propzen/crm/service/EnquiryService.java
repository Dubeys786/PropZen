package com.propzen.crm.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.crm.automation.AutomationEngine;
import com.propzen.crm.automation.AutomationEvent;
import com.propzen.crm.automation.AutomationEventType;
import com.propzen.crm.dto.CreateEnquiryRequest;
import com.propzen.crm.dto.EnquiryDto;
import com.propzen.crm.entity.Enquiry;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.LeadActivity;
import com.propzen.crm.model.ActivityType;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.crm.repository.LeadActivityRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service managing property enquiries and automatic synchronized CRM lead creation.
 */
@Service
public class EnquiryService {

    private static final Logger log = LoggerFactory.getLogger(EnquiryService.class);

    private static final Set<LeadStatus> INACTIVE_STATUSES = Set.of(
            LeadStatus.CONVERTED, LeadStatus.LOST, LeadStatus.CLOSED
    );

    private final EnquiryRepository enquiryRepository;
    private final LeadRepository leadRepository;
    private final LeadActivityRepository leadActivityRepository;
    private final AutoAssignmentService autoAssignmentService;
    private final LeadScoringService leadScoringService;
    private final AutomationEngine automationEngine;
    private final AuditLogService auditLogService;

    public EnquiryService(EnquiryRepository enquiryRepository,
                          LeadRepository leadRepository,
                          LeadActivityRepository leadActivityRepository,
                          AutoAssignmentService autoAssignmentService,
                          LeadScoringService leadScoringService,
                          AutomationEngine automationEngine,
                          AuditLogService auditLogService) {
        this.enquiryRepository = enquiryRepository;
        this.leadRepository = leadRepository;
        this.leadActivityRepository = leadActivityRepository;
        this.autoAssignmentService = autoAssignmentService;
        this.leadScoringService = leadScoringService;
        this.automationEngine = automationEngine;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public EnquiryDto submitEnquiry(CreateEnquiryRequest request, AuthenticatedUser principal) {
        String cleanPhone = request.getPhone().replaceAll("[^0-9+]", "").trim();
        String cleanEmail = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : null;

        // 1. Persist in authoritative enquiries table
        Enquiry enquiry = new Enquiry();
        enquiry.setPropertyId(request.getPropertyId());
        enquiry.setPropertyTitle(request.getPropertyTitle());
        enquiry.setUserName(request.getName().trim());
        enquiry.setUserEmail(cleanEmail);
        enquiry.setUserPhone(cleanPhone);
        enquiry.setMessage(request.getMessage());
        enquiry.setEnquiryType(request.getEnquiryType());
        enquiry.setStatus("New");
        enquiry.setDealerId(request.getDealerId());
        enquiry.setMetadata(request.getMetadata());

        if (principal != null) {
            enquiry.setUserId(principal.getUserId());
        }

        Enquiry savedEnquiry = enquiryRepository.save(enquiry);

        // 2. Automatic CRM Lead Creation with Deduplication
        Optional<Lead> existingLead = Optional.empty();
        if (principal != null && request.getPropertyId() != null) {
            existingLead = leadRepository.findFirstByUserIdAndPropertyIdAndStatusNotIn(
                    principal.getUserId(), request.getPropertyId(), INACTIVE_STATUSES);
        }
        if (existingLead.isEmpty() && request.getPropertyId() != null) {
            existingLead = leadRepository.findFirstByPhoneAndPropertyIdAndStatusNotIn(
                    cleanPhone, request.getPropertyId(), INACTIVE_STATUSES);
        }

        Lead targetLead;
        if (existingLead.isPresent()) {
            // Deduplication: Associate with existing active lead
            targetLead = existingLead.get();
            targetLead.setLastContactedAt(OffsetDateTime.now());
            targetLead = leadRepository.save(targetLead);

            LeadActivity activity = new LeadActivity();
            activity.setLeadId(targetLead.getId());
            activity.setActorUserId(principal != null ? principal.getUserId() : null);
            activity.setType(ActivityType.NOTE);
            activity.setNote("Received repeated enquiry for property: " +
                    (request.getPropertyTitle() != null ? request.getPropertyTitle() : request.getPropertyId()));
            leadActivityRepository.save(activity);

            log.info("Linked enquiry to existing CRM lead #{}", targetLead.getLeadNumber());
        } else {
            // Create brand new CRM lead
            Lead newLead = new Lead();
            newLead.setLeadNumber("LEAD-" + System.currentTimeMillis());
            newLead.setName(request.getName().trim());
            newLead.setEmail(cleanEmail);
            newLead.setPhone(cleanPhone);
            newLead.setPropertyId(request.getPropertyId());
            newLead.setMessage(request.getMessage());
            newLead.setSource(LeadSource.PROPERTY_ENQUIRY);
            newLead.setStatus(LeadStatus.NEW);
            newLead.setPriority(LeadPriority.MEDIUM);
            newLead.setDealerId(request.getDealerId());

            if (principal != null) {
                newLead.setUserId(principal.getUserId());
            }

            // Auto-assign to property dealer if known
            autoAssignmentService.autoAssign(newLead);

            // Calculate initial score
            newLead.setLeadScore(leadScoringService.calculateScore(newLead));

            targetLead = leadRepository.save(newLead);

            LeadActivity activity = new LeadActivity();
            activity.setLeadId(targetLead.getId());
            activity.setActorUserId(principal != null ? principal.getUserId() : null);
            activity.setType(ActivityType.NOTE);
            activity.setNote("Lead auto-created from property enquiry: " +
                    (request.getPropertyTitle() != null ? request.getPropertyTitle() : request.getPropertyId()));
            leadActivityRepository.save(activity);

            log.info("Auto-created new CRM lead #{}", targetLead.getLeadNumber());
        }

        // 3. Trigger Automation Events
        automationEngine.handleEvent(new AutomationEvent(
                AutomationEventType.ENQUIRY_CREATED,
                targetLead.getId(),
                targetLead,
                Collections.emptyMap()
        ));

        auditLogService.logAction(
                principal != null ? principal.getUserId() : null,
                "ENQUIRY_SUBMITTED",
                "enquiries/" + savedEnquiry.getId(),
                "Submitted enquiry for property " + request.getPropertyId() + ", lead #" + targetLead.getLeadNumber()
        );

        return EnquiryDto.fromEntity(savedEnquiry);
    }

    @Transactional(readOnly = true)
    public List<EnquiryDto> getMyEnquiries(AuthenticatedUser principal) {
        if (principal == null) {
            return Collections.emptyList();
        }
        return enquiryRepository.findByUserId(principal.getUserId())
                .stream()
                .map(EnquiryDto::fromEntity)
                .collect(Collectors.toList());
    }
}
