package com.propzen.dealer.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.common.response.PageResponse;
import com.propzen.dealer.dto.DealerProfileDto;
import com.propzen.dealer.dto.UpdateDealerStatusRequest;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.dealer.repository.DealerSpecifications;
import com.propzen.exception.DealerNotFoundException;
import com.propzen.exception.InvalidDealerStatusTransitionException;
import com.propzen.security.user.AuthenticatedUser;
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
public class AdminDealerService {

    private static final Logger log = LoggerFactory.getLogger(AdminDealerService.class);

    private final DealerProfileRepository dealerProfileRepository;
    private final UserRepository userRepository;
    private final AuditLogService auditLogService;

    public AdminDealerService(DealerProfileRepository dealerProfileRepository,
                              UserRepository userRepository,
                              AuditLogService auditLogService) {
        this.dealerProfileRepository = dealerProfileRepository;
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public PageResponse<DealerProfileDto> listDealers(DealerStatus status,
                                                      DealerVerificationStatus verificationStatus,
                                                      String search,
                                                      Pageable pageable) {
        Specification<DealerProfile> spec = DealerSpecifications.withFilters(status, verificationStatus, search);
        Page<DealerProfileDto> page = dealerProfileRepository.findAll(spec, pageable)
                .map(DealerProfileDto::fromEntity);

        return PageResponse.from(page);
    }

    @Transactional(readOnly = true)
    public DealerProfileDto getDealerById(UUID id) {
        DealerProfile profile = dealerProfileRepository.findById(id)
                .orElseThrow(() -> new DealerNotFoundException(id));
        return DealerProfileDto.fromEntity(profile);
    }

    @Transactional
    public DealerProfileDto updateDealerStatus(UUID id,
                                               UpdateDealerStatusRequest request,
                                               AuthenticatedUser adminUser) {
        DealerProfile profile = dealerProfileRepository.findById(id)
                .orElseThrow(() -> new DealerNotFoundException(id));

        DealerStatus currentStatus = profile.getStatus();
        DealerStatus targetStatus = request.getStatus();

        // 1. Validate state transition
        if (!currentStatus.canTransitionTo(targetStatus)) {
            throw new InvalidDealerStatusTransitionException(currentStatus, targetStatus);
        }

        // 2. Apply status update
        profile.setStatus(targetStatus);
        if (request.getAdminNotes() != null) {
            profile.setAdminNotes(request.getAdminNotes().trim());
        }
        profile.setReviewedBy(adminUser.getUserId());
        profile.setReviewedAt(OffsetDateTime.now());

        // 3. Handle status-specific logic and role activation
        if (targetStatus == DealerStatus.APPROVED) {
            profile.setVerificationStatus(DealerVerificationStatus.VERIFIED);

            // Server-side authoritative role activation: Update or insert user's DB role to DEALER
            userRepository.findById(profile.getUserId()).ifPresentOrElse(
                    u -> {
                        u.setRole("DEALER");
                        userRepository.save(u);
                        log.info("Server-side role activated to DEALER for user: {}", u.getId());
                    },
                    () -> {
                        com.propzen.user.entity.User newUser = new com.propzen.user.entity.User(
                                profile.getUserId(),
                                profile.getBusinessName(),
                                profile.getEmail(),
                                profile.getPhone(),
                                "DEALER"
                        );
                        userRepository.save(newUser);
                        log.info("Created user record and activated DEALER role for user: {}", profile.getUserId());
                    }
            );

            auditLogService.logAction(
                    adminUser.getUserId(),
                    "DEALER_APPLICATION_APPROVED",
                    "public.dealer_profiles/" + profile.getId(),
                    "Dealer application approved for user " + profile.getUserId() + " (" + profile.getBusinessName() + ")"
            );
        } else if (targetStatus == DealerStatus.REJECTED) {
            profile.setVerificationStatus(DealerVerificationStatus.REJECTED);
            auditLogService.logAction(
                    adminUser.getUserId(),
                    "DEALER_APPLICATION_REJECTED",
                    "public.dealer_profiles/" + profile.getId(),
                    "Dealer application rejected. Notes: " + profile.getAdminNotes()
            );
        } else if (targetStatus == DealerStatus.SUSPENDED) {
            profile.setVerificationStatus(DealerVerificationStatus.SUSPENDED);

            // Revoke active dealer role on suspension
            userRepository.findById(profile.getUserId()).ifPresent(u -> {
                if ("DEALER".equalsIgnoreCase(u.getRole())) {
                    u.setRole("Buyer");
                    userRepository.save(u);
                    log.info("Server-side role revoked from DEALER to Buyer for suspended user: {}", u.getId());
                }
            });

            auditLogService.logAction(
                    adminUser.getUserId(),
                    "DEALER_APPLICATION_SUSPENDED",
                    "public.dealer_profiles/" + profile.getId(),
                    "Dealer application suspended"
            );
        } else if (targetStatus == DealerStatus.UNDER_REVIEW) {
            profile.setVerificationStatus(DealerVerificationStatus.UNDER_REVIEW);
        }

        DealerProfile saved = dealerProfileRepository.save(profile);

        auditLogService.logAction(
                adminUser.getUserId(),
                "DEALER_STATUS_CHANGED",
                "public.dealer_profiles/" + saved.getId(),
                "Transitioned from " + currentStatus + " to " + targetStatus
        );

        return DealerProfileDto.fromEntity(saved);
    }
}
