package com.propzen.property.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.BadRequestException;
import com.propzen.exception.PropertyNotFoundException;
import com.propzen.property.dto.PropertyAdminDto;
import com.propzen.property.dto.PropertySearchRequest;
import com.propzen.property.dto.UpdatePropertyStatusRequest;
import com.propzen.property.entity.Property;
import com.propzen.property.model.PropertyStatus;
import com.propzen.property.repository.PropertyRepository;
import com.propzen.property.repository.PropertySpecifications;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;

/**
 * Service for administrative property operations, approval workflow, and moderation.
 */
@Service
public class AdminPropertyService {

    private final PropertyRepository propertyRepository;
    private final AuditLogService auditLogService;

    public AdminPropertyService(PropertyRepository propertyRepository,
                                AuditLogService auditLogService) {
        this.propertyRepository = propertyRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<PropertyAdminDto> searchProperties(PropertySearchRequest request) {
        request.validate();

        Specification<Property> spec = PropertySpecifications.withDynamicFilters(
                request.getQ(),
                request.getCity(),
                request.getSector(),
                request.getLocality(),
                request.getPropertyType(),
                request.getBhkList(),
                request.getEffectiveMinPriceCr(),
                request.getEffectiveMaxPriceCr(),
                request.getMinSqft(),
                request.getMaxSqft(),
                request.getAmenitiesList(),
                request.getStatus(),
                null
        );

        Pageable pageable = PageRequest.of(
                request.getPage(),
                request.getSize(),
                request.getSortOption().getSort()
        );

        return propertyRepository.findAll(spec, pageable).map(PropertyAdminDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public PropertyAdminDto getPropertyDetails(UUID propertyId) {
        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new PropertyNotFoundException(propertyId));
        return PropertyAdminDto.fromEntity(property);
    }

    @Transactional
    public PropertyAdminDto updatePropertyStatus(UUID propertyId,
                                                 UpdatePropertyStatusRequest request,
                                                 AuthenticatedUser admin) {
        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new PropertyNotFoundException(propertyId));

        String targetStatusStr = request.getStatus().trim().toUpperCase(Locale.ROOT);
        PropertyStatus newStatus;
        try {
            newStatus = PropertyStatus.valueOf(targetStatusStr);
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("Invalid property status: " + request.getStatus());
        }

        String oldStatus = property.getStatus();
        property.setStatus(newStatus.name());

        if (request.getAdminNote() != null) {
            property.setAdminNote(request.getAdminNote());
        }

        if (newStatus == PropertyStatus.APPROVED || newStatus == PropertyStatus.PUBLISHED) {
            property.setVerificationStatus("VERIFIED");
        } else if (newStatus == PropertyStatus.REJECTED) {
            property.setVerificationStatus("REJECTED");
        }

        Property saved = propertyRepository.save(property);

        auditLogService.logAction(
                admin != null ? admin.getUserId() : null,
                "PROPERTY_STATUS_TRANSITION",
                "public.posted_properties/" + saved.getId(),
                String.format("Transitioned status from %s to %s. Note: %s", oldStatus, newStatus.name(), request.getAdminNote())
        );

        return PropertyAdminDto.fromEntity(saved);
    }
}
