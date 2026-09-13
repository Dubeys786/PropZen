package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.BusinessException;
import com.propzen.exception.ErrorCode;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.ApplyServicePartnerRequest;
import com.propzen.service.dto.ServicePartnerProfileDto;
import com.propzen.service.dto.UpdateServicePartnerRequest;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class ServicePartnerService {

    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final AuditLogService auditLogService;

    public ServicePartnerService(ServicePartnerProfileRepository partnerProfileRepository,
                                 AuditLogService auditLogService) {
        this.partnerProfileRepository = partnerProfileRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public ServicePartnerProfileDto apply(ApplyServicePartnerRequest request, AuthenticatedUser user) {
        if (user == null) {
            throw new ForbiddenException("Authentication required to apply as service partner");
        }

        if (partnerProfileRepository.existsByUserId(user.getUserId())) {
            throw new BusinessException(ErrorCode.DUPLICATE_RESOURCE, "A service partner application or profile already exists for this user");
        }

        ServicePartnerProfile profile = new ServicePartnerProfile();
        profile.setUserId(user.getUserId());
        profile.setBusinessName(request.getBusinessName().trim());
        profile.setCompanyName(request.getCompanyName());
        profile.setDisplayName(request.getDisplayName());
        profile.setPhone(request.getPhone() != null ? request.getPhone().trim() : user.getPhone());
        profile.setEmail(request.getEmail() != null ? request.getEmail().trim().toLowerCase() : user.getEmail());
        profile.setDescription(request.getDescription());
        profile.setExperienceYears(request.getExperienceYears() != null ? request.getExperienceYears() : 0);
        profile.setCity(request.getCity());
        profile.setServiceArea(request.getServiceArea());
        profile.setProfileImageUrl(request.getProfileImageUrl());
        profile.setServiceCategoryId(request.getServiceCategoryId());
        profile.setServiceCategories(request.getServiceCategories());
        profile.setVerificationStatus(PartnerVerificationStatus.PENDING);
        profile.setPartnerStatus(PartnerStatus.PENDING);

        ServicePartnerProfile saved = partnerProfileRepository.save(profile);

        auditLogService.logAction(
                user.getUserId(),
                "SERVICE_PARTNER_APPLIED",
                "public.service_partner_profiles/" + saved.getId(),
                "Service partner application submitted for " + saved.getBusinessName()
        );

        return ServicePartnerProfileDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public ServicePartnerProfileDto getMyProfile(AuthenticatedUser user) {
        if (user == null) {
            throw new ForbiddenException("Authentication required");
        }

        ServicePartnerProfile profile = partnerProfileRepository.findByUserId(user.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", user.getUserId()));

        return ServicePartnerProfileDto.fromEntity(profile);
    }

    @Transactional
    public ServicePartnerProfileDto updateMyProfile(UpdateServicePartnerRequest request, AuthenticatedUser user) {
        if (user == null) {
            throw new ForbiddenException("Authentication required");
        }

        ServicePartnerProfile profile = partnerProfileRepository.findByUserId(user.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("ServicePartnerProfile", user.getUserId()));

        if (profile.getPartnerStatus() == PartnerStatus.SUSPENDED) {
            throw new ForbiddenException("Suspended service partners cannot update profile");
        }

        if (request.getBusinessName() != null) profile.setBusinessName(request.getBusinessName().trim());
        if (request.getCompanyName() != null) profile.setCompanyName(request.getCompanyName().trim());
        if (request.getDisplayName() != null) profile.setDisplayName(request.getDisplayName().trim());
        if (request.getPhone() != null) profile.setPhone(request.getPhone().trim());
        if (request.getEmail() != null) profile.setEmail(request.getEmail().trim().toLowerCase());
        if (request.getDescription() != null) profile.setDescription(request.getDescription());
        if (request.getExperienceYears() != null) profile.setExperienceYears(request.getExperienceYears());
        if (request.getCity() != null) profile.setCity(request.getCity());
        if (request.getServiceArea() != null) profile.setServiceArea(request.getServiceArea());
        if (request.getProfileImageUrl() != null) profile.setProfileImageUrl(request.getProfileImageUrl());

        // Note: Partners CANNOT update partnerStatus or verificationStatus themselves!
        ServicePartnerProfile saved = partnerProfileRepository.save(profile);

        auditLogService.logAction(
                user.getUserId(),
                "SERVICE_PARTNER_PROFILE_UPDATED",
                "public.service_partner_profiles/" + saved.getId(),
                "Updated contact details"
        );

        return ServicePartnerProfileDto.fromEntity(saved);
    }
}
