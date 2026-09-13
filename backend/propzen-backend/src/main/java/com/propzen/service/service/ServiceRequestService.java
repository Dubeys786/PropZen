package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.common.response.PageResponse;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.*;
import com.propzen.service.entity.ServiceCategory;
import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.ServiceJourneyEventType;
import com.propzen.service.model.ServicePriority;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.notification.ServiceNotificationEvent;
import com.propzen.service.notification.ServiceNotificationService;
import com.propzen.service.repository.*;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ServiceRequestService {

    private static final Logger log = LoggerFactory.getLogger(ServiceRequestService.class);

    private final ServiceRequestRepository requestRepository;
    private final ServiceCategoryRepository categoryRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final ServiceJourneyEventRepository journeyEventRepository;
    private final ServiceDocumentRepository documentRepository;
    private final ServiceMilestoneRepository milestoneRepository;
    private final ServiceFeedbackRepository feedbackRepository;
    private final ServiceMilestoneService milestoneService;
    private final UserRepository userRepository;
    private final ServiceNotificationService notificationService;
    private final AuditLogService auditLogService;

    public ServiceRequestService(ServiceRequestRepository requestRepository,
                                 ServiceCategoryRepository categoryRepository,
                                 ServicePartnerProfileRepository partnerProfileRepository,
                                 ServiceJourneyEventRepository journeyEventRepository,
                                 ServiceDocumentRepository documentRepository,
                                 ServiceMilestoneRepository milestoneRepository,
                                 ServiceFeedbackRepository feedbackRepository,
                                 ServiceMilestoneService milestoneService,
                                 UserRepository userRepository,
                                 ServiceNotificationService notificationService,
                                 AuditLogService auditLogService) {
        this.requestRepository = requestRepository;
        this.categoryRepository = categoryRepository;
        this.partnerProfileRepository = partnerProfileRepository;
        this.journeyEventRepository = journeyEventRepository;
        this.documentRepository = documentRepository;
        this.milestoneRepository = milestoneRepository;
        this.feedbackRepository = feedbackRepository;
        this.milestoneService = milestoneService;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public ServiceRequestDto createRequest(CreateServiceRequestDto requestDto, AuthenticatedUser customer) {
        if (customer == null) {
            throw new ForbiddenException("Authentication required to submit service request");
        }

        ServiceCategory category = categoryRepository.findById(requestDto.getServiceCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("ServiceCategory", requestDto.getServiceCategoryId()));

        String serviceNumber = "SR-" + System.currentTimeMillis();

        ServiceRequest sr = new ServiceRequest();
        sr.setServiceNumber(serviceNumber);
        sr.setCustomerId(customer.getUserId());
        sr.setServiceCategoryId(category.getId());
        sr.setPropertyId(requestDto.getPropertyId());
        sr.setTitle(requestDto.getTitle().trim());
        sr.setDescription(requestDto.getDescription());
        sr.setLocation(requestDto.getLocation());
        sr.setBudget(requestDto.getBudget());
        sr.setPreferredDate(requestDto.getPreferredDate());
        sr.setPreferredTime(requestDto.getPreferredTime());
        sr.setPriority(requestDto.getPriority() != null ? requestDto.getPriority() : ServicePriority.MEDIUM);
        sr.setStatus(ServiceRequestStatus.NEW);

        ServiceRequest saved = requestRepository.save(sr);

        // Record Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getId());
        event.setEventType(ServiceJourneyEventType.REQUEST_CREATED);
        event.setTitle("Service Request Created");
        event.setDescription("Service request #" + saved.getServiceNumber() + " created for " + category.getName());
        event.setCreatedBy(customer.getUserId());
        journeyEventRepository.save(event);

        // Dispatch notification
        notificationService.handleNotification(new ServiceNotificationEvent(
                ServiceJourneyEventType.REQUEST_CREATED,
                saved.getId(),
                saved.getServiceNumber(),
                category.getName(),
                customer.getEmail() != null ? customer.getEmail() : "Customer",
                customer.getPhone(),
                "",
                "",
                Map.of()
        ));

        auditLogService.logAction(
                customer.getUserId(),
                "SERVICE_REQUEST_CREATED",
                "public.service_requests/" + saved.getId(),
                "Request #" + saved.getServiceNumber() + " submitted"
        );

        ServiceRequestDto dto = ServiceRequestDto.fromEntity(saved);
        dto.setCategoryName(category.getName());
        return dto;
    }

    @Transactional(readOnly = true)
    public PageResponse<ServiceRequestDto> getMyRequests(AuthenticatedUser customer, Pageable pageable) {
        if (customer == null) throw new ForbiddenException("Authentication required");

        Page<ServiceRequestDto> page = requestRepository.findByCustomerIdOrderByCreatedAtDesc(customer.getUserId(), pageable)
                .map(sr -> {
                    ServiceRequestDto dto = ServiceRequestDto.fromEntity(sr);
                    categoryRepository.findById(sr.getServiceCategoryId()).ifPresent(c -> dto.setCategoryName(c.getName()));
                    return dto;
                });

        return PageResponse.from(page);
    }

    @Transactional(readOnly = true)
    public ServiceRequestDetailDto getRequestDetails(UUID id, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        assertRequestAccess(sr, actor);

        ServiceRequestDetailDto detail = new ServiceRequestDetailDto();
        ServiceRequestDto dto = ServiceRequestDto.fromEntity(sr);
        categoryRepository.findById(sr.getServiceCategoryId()).ifPresent(c -> dto.setCategoryName(c.getName()));
        detail.setRequest(dto);

        // Customer details
        userRepository.findById(sr.getCustomerId()).ifPresent(u -> {
            detail.setCustomerName(u.getFullName());
            detail.setCustomerEmail(u.getEmail());
            detail.setCustomerPhone(u.getPhone());
        });

        // Partner details
        if (sr.getPartnerId() != null) {
            partnerProfileRepository.findById(sr.getPartnerId()).ifPresent(p -> {
                detail.setPartnerBusinessName(p.getBusinessName());
                detail.setPartnerDisplayName(p.getDisplayName());
                detail.setPartnerPhone(p.getPhone());
            });
        }

        // Milestones and dynamic progress
        List<ServiceMilestoneDto> milestones = milestoneRepository.findByServiceRequestIdOrderBySequenceNumberAsc(sr.getId())
                .stream().map(ServiceMilestoneDto::fromEntity).toList();
        detail.setMilestones(milestones);
        detail.setProgressPercentage(milestoneService.calculateProgressPercentage(sr.getId()));

        // Documents
        List<ServiceDocumentDto> docs = documentRepository.findByServiceRequestIdOrderByUploadedAtDesc(sr.getId())
                .stream().map(ServiceDocumentDto::fromEntity).toList();
        detail.setDocuments(docs);

        // Feedback
        feedbackRepository.findByServiceRequestId(sr.getId()).ifPresent(f -> detail.setFeedback(ServiceFeedbackDto.fromEntity(f)));

        return detail;
    }

    @Transactional
    public ServiceRequestDto cancelRequest(UUID id, String reason, AuthenticatedUser customer) {
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        boolean isAdmin = customer != null && customer.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin && (customer == null || !sr.getCustomerId().equals(customer.getUserId()))) {
            throw new ForbiddenException("Only the customer or administrator can cancel a service request");
        }

        if (sr.getStatus() == ServiceRequestStatus.COMPLETED || sr.getStatus() == ServiceRequestStatus.CANCELLED) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "Cannot cancel service request in status " + sr.getStatus());
        }

        sr.setStatus(ServiceRequestStatus.CANCELLED);
        sr.setCancelledAt(OffsetDateTime.now());
        sr.setCancellationReason(reason);

        ServiceRequest saved = requestRepository.save(sr);

        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getId());
        event.setEventType(ServiceJourneyEventType.SERVICE_CANCELLED);
        event.setTitle("Service Request Cancelled");
        event.setDescription(reason != null ? reason : "Cancelled by user");
        event.setCreatedBy(customer.getUserId());
        journeyEventRepository.save(event);

        auditLogService.logAction(
                customer.getUserId(),
                "SERVICE_REQUEST_CANCELLED",
                "public.service_requests/" + saved.getId(),
                "Reason: " + reason
        );

        return ServiceRequestDto.fromEntity(saved);
    }

    // =========================================================================
    // PARTNER WORKFLOWS
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResponse<ServiceRequestDto> getPartnerRequests(AuthenticatedUser partnerUser, Pageable pageable) {
        ServicePartnerProfile partner = getPartnerProfile(partnerUser.getUserId());

        Page<ServiceRequestDto> page = requestRepository.findByPartnerIdOrderByCreatedAtDesc(partner.getId(), pageable)
                .map(sr -> {
                    ServiceRequestDto dto = ServiceRequestDto.fromEntity(sr);
                    categoryRepository.findById(sr.getServiceCategoryId()).ifPresent(c -> dto.setCategoryName(c.getName()));
                    return dto;
                });

        return PageResponse.from(page);
    }

    @Transactional
    public ServiceRequestDto acceptRequest(UUID id, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getPartnerProfile(partnerUser.getUserId());
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        if (!partner.getId().equals(sr.getPartnerId())) {
            throw new ForbiddenException("Access denied: This request is not assigned to you");
        }

        sr.setStatus(ServiceRequestStatus.ACCEPTED);
        ServiceRequest saved = requestRepository.save(sr);

        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getId());
        event.setEventType(ServiceJourneyEventType.PARTNER_ACCEPTED);
        event.setTitle("Request Accepted");
        event.setDescription("Accepted by " + partner.getBusinessName());
        event.setCreatedBy(partnerUser.getUserId());
        journeyEventRepository.save(event);

        notificationService.handleNotification(new ServiceNotificationEvent(
                ServiceJourneyEventType.PARTNER_ACCEPTED,
                saved.getId(),
                saved.getServiceNumber(),
                saved.getTitle(),
                "",
                "",
                partner.getBusinessName(),
                partner.getPhone(),
                Map.of()
        ));

        return ServiceRequestDto.fromEntity(saved);
    }

    @Transactional
    public ServiceRequestDto rejectRequest(UUID id, String reason, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getPartnerProfile(partnerUser.getUserId());
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        if (!partner.getId().equals(sr.getPartnerId())) {
            throw new ForbiddenException("Access denied: This request is not assigned to you");
        }

        sr.setStatus(ServiceRequestStatus.PENDING_ASSIGNMENT);
        sr.setPartnerId(null);
        sr.setRejectionReason(reason);
        ServiceRequest saved = requestRepository.save(sr);

        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getId());
        event.setEventType(ServiceJourneyEventType.PARTNER_REJECTED);
        event.setTitle("Partner Declined Request");
        event.setDescription("Declined by " + partner.getBusinessName() + (reason != null ? ": " + reason : ""));
        event.setCreatedBy(partnerUser.getUserId());
        journeyEventRepository.save(event);

        return ServiceRequestDto.fromEntity(saved);
    }

    @Transactional
    public ServiceRequestDto startService(UUID id, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getPartnerProfile(partnerUser.getUserId());
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        if (!partner.getId().equals(sr.getPartnerId())) {
            throw new ForbiddenException("Access denied: This request is not assigned to you");
        }

        sr.setStatus(ServiceRequestStatus.IN_PROGRESS);
        sr.setStartedAt(OffsetDateTime.now());
        ServiceRequest saved = requestRepository.save(sr);

        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getId());
        event.setEventType(ServiceJourneyEventType.WORK_STARTED);
        event.setTitle("Service Work Started");
        event.setDescription("Work officially started by partner");
        event.setCreatedBy(partnerUser.getUserId());
        journeyEventRepository.save(event);

        return ServiceRequestDto.fromEntity(saved);
    }

    @Transactional
    public ServiceRequestDto completeService(UUID id, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getPartnerProfile(partnerUser.getUserId());
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        if (!partner.getId().equals(sr.getPartnerId())) {
            throw new ForbiddenException("Access denied: This request is not assigned to you");
        }

        sr.setStatus(ServiceRequestStatus.COMPLETED);
        sr.setCompletedAt(OffsetDateTime.now());
        ServiceRequest saved = requestRepository.save(sr);

        // Update partner stats
        partner.setTotalCompletedServices(partner.getTotalCompletedServices() + 1);
        if (partner.getTotalActiveServices() > 0) {
            partner.setTotalActiveServices(partner.getTotalActiveServices() - 1);
        }
        partnerProfileRepository.save(partner);

        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getId());
        event.setEventType(ServiceJourneyEventType.SERVICE_COMPLETED);
        event.setTitle("Service Completed");
        event.setDescription("Service successfully delivered and completed by partner");
        event.setCreatedBy(partnerUser.getUserId());
        journeyEventRepository.save(event);

        return ServiceRequestDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ServiceRequestDetailDto> getActiveServicesForPartner(AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getPartnerProfile(partnerUser.getUserId());

        List<ServiceRequest> activeRequests = requestRepository.findByPartnerId(partner.getId())
                .stream()
                .filter(r -> r.getStatus() == ServiceRequestStatus.ACCEPTED ||
                             r.getStatus() == ServiceRequestStatus.IN_PROGRESS ||
                             r.getStatus() == ServiceRequestStatus.ON_HOLD ||
                             r.getStatus() == ServiceRequestStatus.ASSIGNED)
                .toList();

        return activeRequests.stream().map(sr -> {
            ServiceRequestDetailDto detail = new ServiceRequestDetailDto();
            detail.setRequest(ServiceRequestDto.fromEntity(sr));
            detail.setProgressPercentage(milestoneService.calculateProgressPercentage(sr.getId()));
            userRepository.findById(sr.getCustomerId()).ifPresent(u -> {
                detail.setCustomerName(u.getFullName());
                detail.setCustomerEmail(u.getEmail());
                detail.setCustomerPhone(u.getPhone());
            });
            return detail;
        }).collect(Collectors.toList());
    }

    // =========================================================================
    // ADMIN SERVICE REQUEST WORKFLOWS
    // =========================================================================

    @Transactional(readOnly = true)
    public PageResponse<ServiceRequestDto> searchRequestsAdmin(
            UUID categoryId,
            ServiceRequestStatus status,
            ServicePriority priority,
            UUID partnerId,
            UUID customerId,
            String location,
            String search,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore,
            Pageable pageable
    ) {
        Specification<ServiceRequest> spec = ServiceRequestSpecifications.withFilters(
                categoryId, status, priority, partnerId, customerId, location, search, createdAfter, createdBefore
        );

        Page<ServiceRequestDto> page = requestRepository.findAll(spec, pageable)
                .map(sr -> {
                    ServiceRequestDto dto = ServiceRequestDto.fromEntity(sr);
                    categoryRepository.findById(sr.getServiceCategoryId()).ifPresent(c -> dto.setCategoryName(c.getName()));
                    return dto;
                });

        return PageResponse.from(page);
    }

    @Transactional
    public ServiceRequestDto updateStatusAdmin(UUID id, UpdateServiceRequestStatusRequest request, AuthenticatedUser adminUser) {
        ServiceRequest sr = requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", id));

        sr.setStatus(request.getStatus());
        if (request.getStatus() == ServiceRequestStatus.COMPLETED) {
            sr.setCompletedAt(OffsetDateTime.now());
        } else if (request.getStatus() == ServiceRequestStatus.CANCELLED) {
            sr.setCancelledAt(OffsetDateTime.now());
            sr.setCancellationReason(request.getReason());
        }

        ServiceRequest saved = requestRepository.save(sr);

        auditLogService.logAction(
                adminUser.getUserId(),
                "SERVICE_REQUEST_STATUS_UPDATED",
                "public.service_requests/" + saved.getId(),
                "Status set to " + request.getStatus()
        );

        return ServiceRequestDto.fromEntity(saved);
    }

    // Helper Security methods
    private void assertRequestAccess(ServiceRequest sr, AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");
        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (isAdmin) return;

        if (sr.getCustomerId().equals(actor.getUserId())) return;

        if (sr.getPartnerId() != null) {
            ServicePartnerProfile partner = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (partner != null && partner.getId().equals(sr.getPartnerId())) {
                return;
            }
        }

        throw new ForbiddenException("Access denied to this service request");
    }

    private ServicePartnerProfile getPartnerProfile(UUID userId) {
        return partnerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ForbiddenException("No service partner profile found for user"));
    }
}
