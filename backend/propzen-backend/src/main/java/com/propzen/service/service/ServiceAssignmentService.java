package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.PartnerRecommendationDto;
import com.propzen.service.dto.ServiceAssignmentDto;
import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.entity.ServiceRequestAssignment;
import com.propzen.service.model.AssignmentStatus;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.model.ServiceJourneyEventType;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.notification.ServiceNotificationEvent;
import com.propzen.service.notification.ServiceNotificationService;
import com.propzen.service.repository.ServiceJourneyEventRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestAssignmentRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ServiceAssignmentService {

    private static final Logger log = LoggerFactory.getLogger(ServiceAssignmentService.class);

    private final ServicePartnerProfileRepository partnerRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServiceRequestAssignmentRepository assignmentRepository;
    private final ServiceJourneyEventRepository journeyEventRepository;
    private final ServiceNotificationService notificationService;
    private final AuditLogService auditLogService;

    public ServiceAssignmentService(ServicePartnerProfileRepository partnerRepository,
                                    ServiceRequestRepository requestRepository,
                                    ServiceRequestAssignmentRepository assignmentRepository,
                                    ServiceJourneyEventRepository journeyEventRepository,
                                    ServiceNotificationService notificationService,
                                    AuditLogService auditLogService) {
        this.partnerRepository = partnerRepository;
        this.requestRepository = requestRepository;
        this.assignmentRepository = assignmentRepository;
        this.journeyEventRepository = journeyEventRepository;
        this.notificationService = notificationService;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public List<PartnerRecommendationDto> getRecommendations(UUID serviceRequestId) {
        ServiceRequest request = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        // 1. Find APPROVED and VERIFIED partners
        List<ServicePartnerProfile> candidates = partnerRepository.findByPartnerStatusAndVerificationStatus(
                PartnerStatus.APPROVED, PartnerVerificationStatus.VERIFIED
        );

        List<PartnerRecommendationDto> recommendations = new ArrayList<>();

        for (ServicePartnerProfile p : candidates) {
            // Category check
            boolean matchesCategory = (p.getServiceCategoryId() != null && p.getServiceCategoryId().equals(request.getServiceCategoryId()))
                    || (p.getServiceCategories() != null && p.getServiceCategories().contains(request.getServiceCategoryId().toString()));
            if (!matchesCategory) continue;

            // City/Location match check
            boolean cityMatch = false;
            if (request.getLocation() != null && p.getCity() != null) {
                cityMatch = request.getLocation().toLowerCase().contains(p.getCity().toLowerCase()) ||
                            p.getCity().toLowerCase().contains(request.getLocation().toLowerCase());
            }

            // Calculate multi-criteria assignment score:
            // 1. Rating (max 5.0) -> scaled to 35 points
            double ratingPoints = (p.getRating() != null ? p.getRating().doubleValue() / 5.0 : 0.8) * 35.0;

            // 2. Workload balance (fewer active services = higher points, max 40 points)
            int active = p.getTotalActiveServices() != null ? p.getTotalActiveServices() : 0;
            double workloadPoints = Math.max(0, 40.0 - (active * 4.0));

            // 3. Experience years (max 10 years considered for 25 points)
            int exp = p.getExperienceYears() != null ? Math.min(10, p.getExperienceYears()) : 0;
            double expPoints = (exp / 10.0) * 25.0;

            double totalScore = ratingPoints + workloadPoints + expPoints;
            if (cityMatch) {
                totalScore += 10.0; // Bonus for explicit city match
            }

            BigDecimal score = BigDecimal.valueOf(Math.min(100.0, totalScore)).setScale(2, RoundingMode.HALF_UP);

            PartnerRecommendationDto rec = new PartnerRecommendationDto();
            rec.setPartnerId(p.getId());
            rec.setBusinessName(p.getBusinessName());
            rec.setDisplayName(p.getDisplayName());
            rec.setCity(p.getCity());
            rec.setRating(p.getRating());
            rec.setExperienceYears(p.getExperienceYears());
            rec.setActiveServices(active);
            rec.setScore(score);
            rec.setMatchReason(cityMatch ? "Category & Location Match" : "Category Specialist");

            recommendations.add(rec);
        }

        // Sort descending by score
        recommendations.sort((a, b) -> b.getScore().compareTo(a.getScore()));
        return recommendations;
    }

    @Transactional
    public ServiceAssignmentDto assignPartner(UUID serviceRequestId, UUID partnerId, String notes, AuthenticatedUser adminUser) {
        ServiceRequest request = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        ServicePartnerProfile partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", partnerId));

        if (partner.getPartnerStatus() != PartnerStatus.APPROVED) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "Cannot assign to unapproved partner");
        }

        // Calculate score for this assignment
        List<PartnerRecommendationDto> recs = getRecommendations(serviceRequestId);
        BigDecimal score = recs.stream()
                .filter(r -> r.getPartnerId().equals(partnerId))
                .map(PartnerRecommendationDto::getScore)
                .findFirst()
                .orElse(BigDecimal.valueOf(50.00));

        // Create assignment record
        ServiceRequestAssignment assignment = new ServiceRequestAssignment();
        assignment.setServiceRequestId(request.getId());
        assignment.setPartnerId(partner.getId());
        assignment.setAssignedBy(adminUser != null ? adminUser.getUserId() : null);
        assignment.setAssignmentStatus(AssignmentStatus.ASSIGNED);
        assignment.setAssignmentScore(score);
        assignment.setNotes(notes);
        ServiceRequestAssignment savedAssignment = assignmentRepository.save(assignment);

        // Update service request
        request.setPartnerId(partner.getId());
        request.setStatus(ServiceRequestStatus.ASSIGNED);
        request.setAssignedAt(OffsetDateTime.now());
        requestRepository.save(request);

        // Update partner active services count
        partner.setTotalActiveServices(partner.getTotalActiveServices() + 1);
        partnerRepository.save(partner);

        // Record Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(request.getId());
        event.setEventType(ServiceJourneyEventType.PARTNER_ASSIGNED);
        event.setTitle("Partner Assigned");
        event.setDescription("Assigned to " + partner.getBusinessName());
        event.setCreatedBy(adminUser != null ? adminUser.getUserId() : null);
        journeyEventRepository.save(event);

        // Send notification to partner
        notificationService.handleNotification(new ServiceNotificationEvent(
                ServiceJourneyEventType.PARTNER_ASSIGNED,
                request.getId(),
                request.getServiceNumber(),
                request.getTitle(),
                "", // Customer name
                "", // Customer phone
                partner.getDisplayName() != null ? partner.getDisplayName() : partner.getBusinessName(),
                partner.getPhone(),
                Map.of("score", score)
        ));

        auditLogService.logAction(
                adminUser != null ? adminUser.getUserId() : null,
                "SERVICE_PARTNER_ASSIGNED",
                "public.service_requests/" + request.getId(),
                "Assigned to partner " + partner.getBusinessName()
        );

        return ServiceAssignmentDto.fromEntity(savedAssignment);
    }
}
