package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.common.response.PageResponse;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.CreateFeedbackRequest;
import com.propzen.service.dto.ServiceFeedbackDto;
import com.propzen.service.entity.ServiceFeedback;
import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.ServiceJourneyEventType;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.repository.ServiceFeedbackRepository;
import com.propzen.service.repository.ServiceJourneyEventRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.UUID;

@Service
public class ServiceFeedbackService {

    private final ServiceFeedbackRepository feedbackRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final ServiceJourneyEventRepository journeyEventRepository;
    private final AuditLogService auditLogService;

    public ServiceFeedbackService(ServiceFeedbackRepository feedbackRepository,
                                  ServiceRequestRepository requestRepository,
                                  ServicePartnerProfileRepository partnerProfileRepository,
                                  ServiceJourneyEventRepository journeyEventRepository,
                                  AuditLogService auditLogService) {
        this.feedbackRepository = feedbackRepository;
        this.requestRepository = requestRepository;
        this.partnerProfileRepository = partnerProfileRepository;
        this.journeyEventRepository = journeyEventRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public ServiceFeedbackDto submitFeedback(UUID serviceRequestId, CreateFeedbackRequest request, AuthenticatedUser customerUser) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        if (!sr.getCustomerId().equals(customerUser.getUserId())) {
            throw new ForbiddenException("Only the customer of this service request can submit feedback");
        }

        if (sr.getStatus() != ServiceRequestStatus.COMPLETED) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "Feedback can only be submitted for completed services");
        }

        if (sr.getPartnerId() == null) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "No partner assigned to this service request");
        }

        if (feedbackRepository.existsByServiceRequestId(sr.getId())) {
            throw new BusinessException(ErrorCode.DUPLICATE_RESOURCE, "Feedback already submitted for this service request");
        }

        ServiceFeedback feedback = new ServiceFeedback();
        feedback.setServiceRequestId(sr.getId());
        feedback.setCustomerId(customerUser.getUserId());
        feedback.setPartnerId(sr.getPartnerId());
        feedback.setRating(request.getRating());
        feedback.setComment(request.getComment() != null ? request.getComment().trim() : null);

        ServiceFeedback saved = feedbackRepository.save(feedback);

        // Recalculate partner rating
        Double avg = feedbackRepository.calculateAverageRatingByPartnerId(sr.getPartnerId());
        if (avg != null) {
            partnerProfileRepository.findById(sr.getPartnerId()).ifPresent(partner -> {
                partner.setRating(BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP));
                partnerProfileRepository.save(partner);
            });
        }

        // Record Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(sr.getId());
        event.setEventType(ServiceJourneyEventType.FEEDBACK_SUBMITTED);
        event.setTitle("Feedback Submitted");
        event.setDescription("Rating: " + saved.getRating() + "/5 stars.");
        event.setCreatedBy(customerUser.getUserId());
        journeyEventRepository.save(event);

        auditLogService.logAction(
                customerUser.getUserId(),
                "SERVICE_FEEDBACK_SUBMITTED",
                "public.service_feedback/" + saved.getId(),
                "Rating: " + saved.getRating()
        );

        return ServiceFeedbackDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public ServiceFeedbackDto getFeedbackForRequest(UUID serviceRequestId) {
        return feedbackRepository.findByServiceRequestId(serviceRequestId)
                .map(ServiceFeedbackDto::fromEntity)
                .orElse(null);
    }

    @Transactional(readOnly = true)
    public PageResponse<ServiceFeedbackDto> getFeedbackForPartner(AuthenticatedUser partnerUser, Pageable pageable) {
        ServicePartnerProfile partner = partnerProfileRepository.findByUserId(partnerUser.getUserId())
                .orElseThrow(() -> new ForbiddenException("No partner profile found"));

        Page<ServiceFeedbackDto> page = feedbackRepository.findByPartnerIdOrderByCreatedAtDesc(partner.getId(), pageable)
                .map(ServiceFeedbackDto::fromEntity);

        return PageResponse.from(page);
    }

    @Transactional(readOnly = true)
    public PageResponse<ServiceFeedbackDto> getAllFeedback(Pageable pageable) {
        Page<ServiceFeedbackDto> page = feedbackRepository.findAll(pageable)
                .map(ServiceFeedbackDto::fromEntity);
        return PageResponse.from(page);
    }
}
