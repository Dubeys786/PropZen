package com.propzen.crm.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.common.notification.NotificationService;
import com.propzen.common.notification.NotificationType;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.ServicePartnerProfileDto;
import com.propzen.service.entity.ServiceCategory;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.repository.ServiceCategoryRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Production-grade Service Partner Lead Routing & Assignment Engine.
 * 
 * When a customer creates a service enquiry:
 * 1. Identifies the normalized service category.
 * 2. Matches eligible approved and verified service partners.
 * 3. Applies multi-criteria deterministic ranking:
 *    - City / Service area proximity match
 *    - Lowest active lead workload (balanced dispatch)
 *    - Highest partner rating
 *    - Deterministic ID tie-breaker
 * 4. Automatically assigns lead or falls back to the Admin Unassigned Queue.
 * 5. Records comprehensive audit log and dispatches in-app notifications.
 */
@Service
public class ServicePartnerLeadRoutingService {

    private static final Logger log = LoggerFactory.getLogger(ServicePartnerLeadRoutingService.class);

    private final ServicePartnerProfileRepository partnerRepository;
    private final ServiceCategoryRepository categoryRepository;
    private final LeadRepository leadRepository;
    private final AuditLogService auditLogService;
    private final NotificationService notificationService;

    public ServicePartnerLeadRoutingService(
            ServicePartnerProfileRepository partnerRepository,
            ServiceCategoryRepository categoryRepository,
            LeadRepository leadRepository,
            AuditLogService auditLogService,
            NotificationService notificationService
    ) {
        this.partnerRepository = partnerRepository;
        this.categoryRepository = categoryRepository;
        this.leadRepository = leadRepository;
        this.auditLogService = auditLogService;
        this.notificationService = notificationService;
    }

    /**
     * Automatically routes and assigns a lead to an eligible service partner.
     * If no eligible partner is available, assigns to UNASSIGNED fallback queue.
     */
    @Transactional
    public Lead routeAndAssignLead(Lead lead, UUID actorUserId) {
        if (lead.getServiceCategory() == null || lead.getServiceCategory().isBlank()) {
            lead.setAssignmentStatus("UNASSIGNED");
            return leadRepository.save(lead);
        }

        String rawCategory = lead.getServiceCategory().trim();
        List<ServicePartnerProfile> eligiblePartners = findEligiblePartnersForCategory(rawCategory);

        if (eligiblePartners.isEmpty()) {
            lead.setAssignedPartnerId(null);
            lead.setAssignmentStatus("UNASSIGNED");
            Lead saved = leadRepository.save(lead);

            auditLogService.logAction(
                    actorUserId != null ? actorUserId : lead.getUserId(),
                    "LEAD_UNASSIGNED",
                    "crm_leads/" + saved.getId(),
                    "No eligible service partner found for category '" + rawCategory + "'. Placed in Admin unassigned queue."
            );
            log.warn("Lead {} with category '{}' could not be matched. Moved to UNASSIGNED queue.", saved.getLeadNumber(), rawCategory);
            return saved;
        }

        // Rank candidates:
        // 1. Proximity score (1 if city matches lead.getPreferredCity(), 0 otherwise)
        // 2. Active lead workload (fewer active leads first)
        // 3. Rating (higher rating first)
        // 4. Stable UUID string tie-breaker
        String targetCity = lead.getPreferredCity() != null ? lead.getPreferredCity().trim() : "";

        ServicePartnerProfile selectedPartner = eligiblePartners.stream()
                .min((p1, p2) -> {
                    // 1. City match
                    boolean p1CityMatch = isCityMatch(p1, targetCity);
                    boolean p2CityMatch = isCityMatch(p2, targetCity);
                    if (p1CityMatch != p2CityMatch) {
                        return p1CityMatch ? -1 : 1;
                    }

                    // 2. Active lead workload
                    long p1Active = getActiveLeadCount(p1.getId());
                    long p2Active = getActiveLeadCount(p2.getId());
                    if (p1Active != p2Active) {
                        return Long.compare(p1Active, p2Active);
                    }

                    // 3. Rating
                    BigDecimal r1 = p1.getRating() != null ? p1.getRating() : BigDecimal.ZERO;
                    BigDecimal r2 = p2.getRating() != null ? p2.getRating() : BigDecimal.ZERO;
                    int ratingComp = r2.compareTo(r1); // descending
                    if (ratingComp != 0) {
                        return ratingComp;
                    }

                    // 4. Deterministic tie breaker
                    return p1.getId().compareTo(p2.getId());
                })
                .orElse(eligiblePartners.get(0));

        lead.setAssignedPartnerId(selectedPartner.getId());
        lead.setAssignmentStatus("ASSIGNED");
        Lead saved = leadRepository.save(lead);

        auditLogService.logAction(
                actorUserId != null ? actorUserId : lead.getUserId(),
                "LEAD_ASSIGNED",
                "crm_leads/" + saved.getId(),
                "Lead assigned to partner " + selectedPartner.getBusinessName() + " (" + selectedPartner.getId() + ") for category " + rawCategory
        );

        // Notify partner via in-app notification
        try {
            notificationService.createNotification(
                    selectedPartner.getUserId(),
                    NotificationType.LEAD_UPDATE,
                    "New Service Lead Assigned",
                    "New service lead #" + saved.getLeadNumber() + " for " + rawCategory + " has been assigned to you.",
                    "{\"leadId\":\"" + saved.getId() + "\",\"serviceCategory\":\"" + rawCategory + "\"}"
            );
        } catch (Exception e) {
            log.warn("Failed to dispatch in-app notification for lead assignment: {}", e.getMessage());
        }

        log.info("Lead {} successfully assigned to partner {} ({})", saved.getLeadNumber(), selectedPartner.getBusinessName(), selectedPartner.getId());
        return saved;
    }

    /**
     * Lists all eligible, approved, and verified service partners for a lead's category.
     */
    @Transactional(readOnly = true)
    public List<ServicePartnerProfileDto> getEligiblePartnersForLead(UUID leadId) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));

        if (lead.getServiceCategory() == null || lead.getServiceCategory().isBlank()) {
            return Collections.emptyList();
        }

        return findEligiblePartnersForCategory(lead.getServiceCategory())
                .stream()
                .map(ServicePartnerProfileDto::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * Allows Admin to manually assign a lead to a specific verified partner.
     */
    @Transactional
    public Lead assignPartnerManually(UUID leadId, UUID partnerId, AuthenticatedUser adminUser) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));

        ServicePartnerProfile partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", partnerId));

        if (partner.getPartnerStatus() != PartnerStatus.APPROVED || partner.getVerificationStatus() != PartnerVerificationStatus.VERIFIED) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "Cannot assign lead to unverified or unapproved partner");
        }

        lead.setAssignedPartnerId(partner.getId());
        lead.setAssignmentStatus("ASSIGNED");
        Lead saved = leadRepository.save(lead);

        auditLogService.logAction(
                adminUser.getUserId(),
                "LEAD_ASSIGNED",
                "crm_leads/" + saved.getId(),
                "Admin manually assigned lead to partner " + partner.getBusinessName() + " (" + partner.getId() + ")"
        );

        try {
            notificationService.createNotification(
                    partner.getUserId(),
                    NotificationType.LEAD_UPDATE,
                    "New Service Lead Assigned (Manual)",
                    "Service lead #" + saved.getLeadNumber() + " has been assigned to you by Admin.",
                    "{\"leadId\":\"" + saved.getId() + "\"}"
            );
        } catch (Exception e) {
            log.warn("Failed to dispatch in-app notification: {}", e.getMessage());
        }

        return saved;
    }

    /**
     * Allows Admin to unassign a lead back to the unassigned queue.
     */
    @Transactional
    public Lead unassignPartner(UUID leadId, AuthenticatedUser adminUser) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));

        UUID prevPartner = lead.getAssignedPartnerId();
        lead.setAssignedPartnerId(null);
        lead.setAssignmentStatus("UNASSIGNED");
        Lead saved = leadRepository.save(lead);

        auditLogService.logAction(
                adminUser.getUserId(),
                "LEAD_UNASSIGNED",
                "crm_leads/" + saved.getId(),
                "Admin unassigned lead from partner " + prevPartner
        );

        return saved;
    }

    /**
     * Finds all active, approved, and verified partners matching the requested category.
     */
    public List<ServicePartnerProfile> findEligiblePartnersForCategory(String category) {
        if (category == null || category.isBlank()) {
            return Collections.emptyList();
        }

        List<ServicePartnerProfile> approvedPartners = partnerRepository.findByPartnerStatusAndVerificationStatus(
                PartnerStatus.APPROVED, PartnerVerificationStatus.VERIFIED
        );

        String normalizedTarget = cleanCategoryToken(category);

        // Preload categories map for quick category ID lookup
        Map<UUID, ServiceCategory> categoryMap = categoryRepository.findAll().stream()
                .collect(Collectors.toMap(ServiceCategory::getId, c -> c, (c1, c2) -> c1));

        return approvedPartners.stream()
                .filter(p -> matchesCategory(p, normalizedTarget, categoryMap))
                .collect(Collectors.toList());
    }

    private boolean matchesCategory(ServicePartnerProfile partner, String normalizedTarget, Map<UUID, ServiceCategory> categoryMap) {
        // 1. Direct match on partner.getServiceCategories()
        if (partner.getServiceCategories() != null && !partner.getServiceCategories().isBlank()) {
            String[] tokens = partner.getServiceCategories().split("[,;|]");
            for (String t : tokens) {
                String cleanT = cleanCategoryToken(t);
                if (cleanT.contains(normalizedTarget) || normalizedTarget.contains(cleanT)) {
                    return true;
                }
            }
        }

        // 2. Match via partner.getServiceCategoryId()
        if (partner.getServiceCategoryId() != null) {
            ServiceCategory sc = categoryMap.get(partner.getServiceCategoryId());
            if (sc != null) {
                String cleanSlug = cleanCategoryToken(sc.getSlug());
                String cleanName = cleanCategoryToken(sc.getName());
                if (cleanSlug.contains(normalizedTarget) || normalizedTarget.contains(cleanSlug)
                        || cleanName.contains(normalizedTarget) || normalizedTarget.contains(cleanName)) {
                    return true;
                }
            }
        }

        // 3. Fallback check on businessName/description for keywords
        return false;
    }

    private boolean isCityMatch(ServicePartnerProfile p, String targetCity) {
        if (targetCity == null || targetCity.isBlank()) return false;
        String tc = targetCity.toLowerCase(Locale.ROOT);

        if (p.getCity() != null && p.getCity().toLowerCase(Locale.ROOT).contains(tc)) {
            return true;
        }
        if (p.getServiceArea() != null && p.getServiceArea().toLowerCase(Locale.ROOT).contains(tc)) {
            return true;
        }
        return false;
    }

    private long getActiveLeadCount(UUID partnerId) {
        try {
            return leadRepository.countByAssignedPartnerIdAndStatus(partnerId, LeadStatus.IN_PROGRESS)
                    + leadRepository.countByAssignedPartnerIdAndStatus(partnerId, LeadStatus.NEW);
        } catch (Exception e) {
            return 0L;
        }
    }

    private String cleanCategoryToken(String raw) {
        if (raw == null) return "";
        return raw.toLowerCase(Locale.ROOT)
                .replace("_", "")
                .replace("-", "")
                .replace(" ", "")
                .replace("consultancy", "")
                .replace("support", "")
                .replace("service", "");
    }
}
