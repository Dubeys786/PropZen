package com.propzen.dealer.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.dealer.dto.DealerApplicationRequest;
import com.propzen.dealer.dto.DealerProfileDto;
import com.propzen.dealer.dto.UpdateDealerProfileRequest;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.exception.DealerAlreadyExistsException;
import com.propzen.exception.DealerNotFoundException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.UserNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class DealerService {

    private static final Logger log = LoggerFactory.getLogger(DealerService.class);

    private final DealerProfileRepository dealerProfileRepository;
    private final UserRepository userRepository;
    private final AuditLogService auditLogService;

    public DealerService(DealerProfileRepository dealerProfileRepository,
                         UserRepository userRepository,
                         AuditLogService auditLogService) {
        this.dealerProfileRepository = dealerProfileRepository;
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public DealerProfileDto applyAsDealer(AuthenticatedUser principal, DealerApplicationRequest request) {
        if (principal == null || principal.getUserId() == null) {
            throw new UserNotFoundException("No authenticated principal provided");
        }

        // 1. Verify user exists in public.users
        if (!userRepository.existsById(principal.getUserId())) {
            throw new UserNotFoundException(principal.getUserId());
        }

        // 2. Prevent duplicate applications
        Optional<DealerProfile> existingOpt = dealerProfileRepository.findByUserId(principal.getUserId());
        if (existingOpt.isPresent()) {
            DealerProfile existing = existingOpt.get();
            if (existing.getStatus() == DealerStatus.APPROVED) {
                throw new DealerAlreadyExistsException("You already have an approved dealer profile", ErrorCode.DEALER_ALREADY_EXISTS);
            }
            if (existing.getStatus() == DealerStatus.PENDING || existing.getStatus() == DealerStatus.UNDER_REVIEW) {
                throw new DealerAlreadyExistsException("A dealer application is currently pending review for this user", ErrorCode.DEALER_APPLICATION_PENDING);
            }
            // If REJECTED, update existing record back to PENDING for re-application
            existing.setBusinessName(request.getBusinessName().trim());
            existing.setCompanyName(request.getCompanyName() != null ? request.getCompanyName().trim() : null);
            existing.setDisplayName(request.getDisplayName() != null ? request.getDisplayName().trim() : null);
            existing.setPhone(request.getPhone().trim());
            existing.setEmail(request.getEmail().trim().toLowerCase());
            existing.setDescription(request.getDescription());
            existing.setExperienceYears(request.getExperienceYears());
            existing.setCity(request.getCity() != null ? request.getCity().trim() : null);
            existing.setStatus(DealerStatus.PENDING);
            existing.setVerificationStatus(DealerVerificationStatus.PENDING);
            dealerProfileRepository.save(existing);

            auditLogService.logAction(
                    principal.getUserId(),
                    "DEALER_APPLICATION_RESUBMITTED",
                    "public.dealer_profiles/" + existing.getId(),
                    "Re-applied after rejection"
            );
            return DealerProfileDto.fromEntity(existing);
        }

        // 3. Create new application
        DealerProfile profile = new DealerProfile();
        profile.setUserId(principal.getUserId());
        profile.setBusinessName(request.getBusinessName().trim());
        profile.setCompanyName(request.getCompanyName() != null ? request.getCompanyName().trim() : null);
        profile.setDisplayName(request.getDisplayName() != null ? request.getDisplayName().trim() : null);
        profile.setPhone(request.getPhone().trim());
        profile.setEmail(request.getEmail().trim().toLowerCase());
        profile.setDescription(request.getDescription());
        profile.setExperienceYears(request.getExperienceYears());
        profile.setCity(request.getCity() != null ? request.getCity().trim() : null);
        profile.setStatus(DealerStatus.PENDING);
        profile.setVerificationStatus(DealerVerificationStatus.PENDING);

        DealerProfile saved = dealerProfileRepository.save(profile);

        auditLogService.logAction(
                principal.getUserId(),
                "DEALER_APPLICATION_SUBMITTED",
                "public.dealer_profiles/" + saved.getId(),
                "New dealer application submitted"
        );
        log.info("Dealer application submitted successfully by user: {}", principal.getUserId());

        return DealerProfileDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public DealerProfileDto getMyDealerProfile(AuthenticatedUser principal) {
        if (principal == null || principal.getUserId() == null) {
            throw new UserNotFoundException("No authenticated principal provided");
        }

        DealerProfile profile = dealerProfileRepository.findByUserId(principal.getUserId())
                .orElseThrow(() -> new DealerNotFoundException("No dealer profile found for current user"));

        return DealerProfileDto.fromEntity(profile);
    }

    @Transactional
    public DealerProfileDto updateMyDealerProfile(AuthenticatedUser principal, UpdateDealerProfileRequest request) {
        if (principal == null || principal.getUserId() == null) {
            throw new UserNotFoundException("No authenticated principal provided");
        }

        DealerProfile profile = dealerProfileRepository.findByUserId(principal.getUserId())
                .orElseThrow(() -> new DealerNotFoundException("No dealer profile found for current user"));

        // Only allow updating permitted business fields
        if (request.getBusinessName() != null && !request.getBusinessName().trim().isEmpty()) {
            profile.setBusinessName(request.getBusinessName().trim());
        }
        if (request.getCompanyName() != null) {
            profile.setCompanyName(request.getCompanyName().trim());
        }
        if (request.getDisplayName() != null) {
            profile.setDisplayName(request.getDisplayName().trim());
        }
        if (request.getPhone() != null && !request.getPhone().trim().isEmpty()) {
            profile.setPhone(request.getPhone().trim());
        }
        if (request.getDescription() != null) {
            profile.setDescription(request.getDescription().trim());
        }
        if (request.getExperienceYears() != null) {
            profile.setExperienceYears(request.getExperienceYears());
        }
        if (request.getCity() != null) {
            profile.setCity(request.getCity().trim());
        }

        DealerProfile saved = dealerProfileRepository.save(profile);

        auditLogService.logAction(
                principal.getUserId(),
                "DEALER_PROFILE_UPDATED",
                "public.dealer_profiles/" + saved.getId(),
                "Dealer updated allowed profile fields"
        );

        return DealerProfileDto.fromEntity(saved);
    }
}
