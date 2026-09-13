package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.common.response.PageResponse;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.ServicePartnerProfileDto;
import com.propzen.service.dto.UpdatePartnerStatusRequest;
import com.propzen.service.dto.UpdatePartnerVerificationRequest;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServicePartnerSpecifications;
import com.propzen.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class AdminServicePartnerService {

    private static final Logger log = LoggerFactory.getLogger(AdminServicePartnerService.class);

    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final UserRepository userRepository;
    private final AuditLogService auditLogService;

    public AdminServicePartnerService(ServicePartnerProfileRepository partnerProfileRepository,
                                     UserRepository userRepository,
                                     AuditLogService auditLogService) {
        this.partnerProfileRepository = partnerProfileRepository;
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public PageResponse<ServicePartnerProfileDto> listPartners(
            PartnerStatus status,
            PartnerVerificationStatus verificationStatus,
            String city,
            String search,
            OffsetDateTime createdAfter,
            OffsetDateTime createdBefore,
            Pageable pageable
    ) {
        Specification<ServicePartnerProfile> spec = ServicePartnerSpecifications.withFilters(
                status, verificationStatus, city, search, createdAfter, createdBefore
        );

        Page<ServicePartnerProfileDto> page = partnerProfileRepository.findAll(spec, pageable)
                .map(ServicePartnerProfileDto::fromEntity);

        return PageResponse.from(page);
    }

    @Transactional(readOnly = true)
    public ServicePartnerProfileDto getPartnerById(UUID id) {
        ServicePartnerProfile profile = partnerProfileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", id));
        return ServicePartnerProfileDto.fromEntity(profile);
    }

    @Transactional
    public ServicePartnerProfileDto updatePartnerStatus(UUID id, UpdatePartnerStatusRequest request, AuthenticatedUser adminUser) {
        ServicePartnerProfile profile = partnerProfileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", id));

        PartnerStatus current = profile.getPartnerStatus();
        PartnerStatus target = request.getStatus();

        if (!current.canTransitionTo(target)) {
            throw new BusinessException(ErrorCode.BAD_REQUEST, "Invalid partner status transition from " + current + " to " + target);
        }

        profile.setPartnerStatus(target);
        if (request.getAdminNotes() != null) {
            profile.setAdminNotes(request.getAdminNotes().trim());
        }
        profile.setReviewedBy(adminUser.getUserId());
        profile.setReviewedAt(OffsetDateTime.now());

        // Role synchronization
        if (target == PartnerStatus.APPROVED) {
            profile.setVerificationStatus(PartnerVerificationStatus.VERIFIED);
            userRepository.findById(profile.getUserId()).ifPresentOrElse(
                    u -> {
                        u.setRole("SERVICE_PARTNER");
                        userRepository.save(u);
                        log.info("Server-side role upgraded to SERVICE_PARTNER for user: {}", u.getId());
                    },
                    () -> {
                        com.propzen.user.entity.User newUser = new com.propzen.user.entity.User(
                                profile.getUserId(),
                                profile.getBusinessName(),
                                profile.getEmail(),
                                profile.getPhone(),
                                "SERVICE_PARTNER"
                        );
                        userRepository.save(newUser);
                        log.info("Created user record and activated SERVICE_PARTNER role for user: {}", profile.getUserId());
                    }
            );

            auditLogService.logAction(
                    adminUser.getUserId(),
                    "SERVICE_PARTNER_APPLICATION_APPROVED",
                    "public.service_partner_profiles/" + profile.getId(),
                    "Service partner application approved for user " + profile.getUserId() + " (" + profile.getBusinessName() + ")"
            );
        } else if (target == PartnerStatus.SUSPENDED) {
            userRepository.findById(profile.getUserId()).ifPresent(u -> {
                if ("SERVICE_PARTNER".equalsIgnoreCase(u.getRole())) {
                    u.setRole("Buyer");
                    userRepository.save(u);
                    log.info("Server-side role revoked from SERVICE_PARTNER for suspended user: {}", u.getId());
                }
            });

            auditLogService.logAction(
                    adminUser.getUserId(),
                    "SERVICE_PARTNER_APPLICATION_SUSPENDED",
                    "public.service_partner_profiles/" + profile.getId(),
                    "Service partner application suspended"
            );
        } else if (target == PartnerStatus.REJECTED) {
            profile.setVerificationStatus(PartnerVerificationStatus.REJECTED);
            auditLogService.logAction(
                    adminUser.getUserId(),
                    "SERVICE_PARTNER_APPLICATION_REJECTED",
                    "public.service_partner_profiles/" + profile.getId(),
                    "Service partner application rejected. Notes: " + profile.getAdminNotes()
            );
        }

        ServicePartnerProfile saved = partnerProfileRepository.save(profile);

        auditLogService.logAction(
                adminUser.getUserId(),
                "SERVICE_PARTNER_STATUS_CHANGED",
                "public.service_partner_profiles/" + saved.getId(),
                "Partner status updated to " + target
        );

        return ServicePartnerProfileDto.fromEntity(saved);
    }

    @Transactional
    public ServicePartnerProfileDto updatePartnerVerification(UUID id, UpdatePartnerVerificationRequest request, AuthenticatedUser adminUser) {
        ServicePartnerProfile profile = partnerProfileRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", id));

        profile.setVerificationStatus(request.getVerificationStatus());
        if (request.getAdminNotes() != null) {
            profile.setAdminNotes(request.getAdminNotes().trim());
        }
        profile.setReviewedBy(adminUser.getUserId());
        profile.setReviewedAt(OffsetDateTime.now());

        ServicePartnerProfile saved = partnerProfileRepository.save(profile);

        auditLogService.logAction(
                adminUser.getUserId(),
                "SERVICE_PARTNER_VERIFICATION_CHANGED",
                "public.service_partner_profiles/" + saved.getId(),
                "Verification status updated to " + request.getVerificationStatus()
        );

        return ServicePartnerProfileDto.fromEntity(saved);
    }
}
