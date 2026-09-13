package com.propzen.property.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.exception.BadRequestException;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.OwnershipDeniedException;
import com.propzen.exception.PropertyNotFoundException;
import com.propzen.property.dto.CreatePropertyRequest;
import com.propzen.property.dto.PropertyDetailsDto;
import com.propzen.property.dto.PropertyListDto;
import com.propzen.property.dto.PropertySearchRequest;
import com.propzen.property.dto.UpdatePropertyRequest;
import com.propzen.property.entity.Property;
import com.propzen.property.model.PropertyStatus;
import com.propzen.property.repository.PropertyRepository;
import com.propzen.property.repository.PropertySpecifications;
import com.propzen.security.service.ResourceAuthorizationService;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;

/**
 * Core business service for property management, search, exact filtering, and ownership enforcement.
 */
@Service
public class PropertyService {

    private static final Logger log = LoggerFactory.getLogger(PropertyService.class);

    private final PropertyRepository propertyRepository;
    private final DealerProfileRepository dealerProfileRepository;
    private final ResourceAuthorizationService resourceAuthorizationService;
    private final AuditLogService auditLogService;

    public PropertyService(PropertyRepository propertyRepository,
                           DealerProfileRepository dealerProfileRepository,
                           ResourceAuthorizationService resourceAuthorizationService,
                           AuditLogService auditLogService) {
        this.propertyRepository = propertyRepository;
        this.dealerProfileRepository = dealerProfileRepository;
        this.resourceAuthorizationService = resourceAuthorizationService;
        this.auditLogService = auditLogService;
    }

    /**
     * Database-level exact search and filtering for public / published properties.
     */
    @Transactional(readOnly = true)
    public Page<PropertyListDto> searchPublicProperties(PropertySearchRequest request) {
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
                "PUBLISHED",
                null
        );

        Pageable pageable = PageRequest.of(
                request.getPage(),
                request.getSize(),
                request.getSortOption().getSort()
        );

        return propertyRepository.findAll(spec, pageable).map(PropertyListDto::fromEntity);
    }

    /**
     * Retrieves role-aware property details.
     */
    @Transactional(readOnly = true)
    public PropertyDetailsDto getPropertyDetails(UUID propertyId, AuthenticatedUser principal) {
        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new PropertyNotFoundException(propertyId));

        boolean isPublished = "PUBLISHED".equalsIgnoreCase(property.getStatus()) ||
                              "ACTIVE".equalsIgnoreCase(property.getStatus());

        boolean isAdmin = principal != null && principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        boolean isOwner = principal != null && (
                (property.getOwnerId() != null && principal.getUserId().equals(property.getOwnerId())) ||
                isDealerOwner(principal.getUserId(), property.getDealerId())
        );

        if (!isPublished && !isAdmin && !isOwner) {
            throw new PropertyNotFoundException(propertyId);
        }

        return PropertyDetailsDto.fromEntity(property, isAdmin || isOwner);
    }

    /**
     * Dealer creates a new property. Privileged fields are assigned server-side.
     */
    @Transactional
    public PropertyDetailsDto createProperty(AuthenticatedUser principal, CreatePropertyRequest request) {
        if (principal == null || principal.getUserId() == null) {
            throw new ForbiddenException("Authentication required to create a property");
        }

        // Verify dealer eligibility
        DealerProfile dealer = dealerProfileRepository.findByUserId(principal.getUserId())
                .orElseThrow(() -> new ForbiddenException("Only registered dealers can post properties"));

        if (dealer.getStatus() != DealerStatus.APPROVED) {
            throw new ForbiddenException("Dealer account is not approved to post properties");
        }

        // Check for potential duplicate properties
        if (request.getSector() != null && request.getBhk() != null && request.getPriceCr() != null) {
            List<Property> duplicates = propertyRepository.findPotentialDuplicates(
                    dealer.getId(),
                    request.getSector(),
                    request.getBhk(),
                    request.getPriceCr()
            );
            if (!duplicates.isEmpty()) {
                log.warn("Potential duplicate property detected for dealer {}: sector={}, bhk={}, priceCr={}",
                        dealer.getId(), request.getSector(), request.getBhk(), request.getPriceCr());
            }
        }

        Property property = new Property();
        property.setTitle(request.getTitle().trim());
        property.setDescription(request.getDescription());
        property.setCity(request.getCity().trim());
        property.setSector(request.getSector().trim());
        property.setLocality(request.getLocality() != null ? request.getLocality().trim() : null);
        property.setPropertyType(request.getPropertyType().trim());
        property.setBhk(request.getBhk() != null ? request.getBhk().trim() : null);
        property.setPriceCr(request.getPriceCr());
        property.setSqft(request.getSqft());
        property.setAmenities(request.getAmenities());
        property.setImageUrl(request.getImageUrl());
        property.setImages(request.getImages());
        property.setMetadata(request.getMetadata());

        // Authoritative server-side ownership
        property.setOwnerId(principal.getUserId());
        property.setDealerId(dealer.getId());
        property.setOwnerName(dealer.getDisplayName() != null ? dealer.getDisplayName() : dealer.getBusinessName());
        property.setOwnerPhone(dealer.getPhone());
        property.setVerificationStatus("PENDING");

        // Safe initial status: SUBMITTED if requested, else DRAFT
        if (Boolean.TRUE.equals(request.getSubmitForReview())) {
            property.setStatus(PropertyStatus.SUBMITTED.name());
        } else {
            property.setStatus(PropertyStatus.DRAFT.name());
        }

        Property saved = propertyRepository.save(property);

        auditLogService.logAction(
                principal.getUserId(),
                "PROPERTY_CREATED",
                "public.posted_properties/" + saved.getId(),
                "Created property in status " + saved.getStatus()
        );

        return PropertyDetailsDto.fromEntity(saved, true);
    }

    /**
     * Dealer or Admin updates permitted fields of an existing property.
     */
    @Transactional
    public PropertyDetailsDto updateProperty(UUID propertyId, AuthenticatedUser principal, UpdatePropertyRequest request) {
        if (principal == null || principal.getUserId() == null) {
            throw new ForbiddenException("Authentication required to update property");
        }

        Property property = propertyRepository.findById(propertyId)
                .orElseThrow(() -> new PropertyNotFoundException(propertyId));

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        boolean isOwner = (property.getOwnerId() != null && principal.getUserId().equals(property.getOwnerId())) ||
                          isDealerOwner(principal.getUserId(), property.getDealerId());

        if (!isAdmin && !isOwner) {
            throw new OwnershipDeniedException("You do not own this property");
        }

        // Apply permitted field updates
        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            property.setTitle(request.getTitle().trim());
        }
        if (request.getDescription() != null) {
            property.setDescription(request.getDescription());
        }
        if (request.getCity() != null && !request.getCity().isBlank()) {
            property.setCity(request.getCity().trim());
        }
        if (request.getSector() != null && !request.getSector().isBlank()) {
            property.setSector(request.getSector().trim());
        }
        if (request.getLocality() != null) {
            property.setLocality(request.getLocality().trim());
        }
        if (request.getPropertyType() != null && !request.getPropertyType().isBlank()) {
            property.setPropertyType(request.getPropertyType().trim());
        }
        if (request.getBhk() != null) {
            property.setBhk(request.getBhk().trim());
        }
        if (request.getPriceCr() != null) {
            property.setPriceCr(request.getPriceCr());
        }
        if (request.getSqft() != null) {
            property.setSqft(request.getSqft());
        }
        if (request.getAmenities() != null) {
            property.setAmenities(request.getAmenities());
        }
        if (request.getImageUrl() != null) {
            property.setImageUrl(request.getImageUrl());
        }
        if (request.getImages() != null) {
            property.setImages(request.getImages());
        }
        if (request.getMetadata() != null) {
            property.setMetadata(request.getMetadata());
        }

        // Dealer submission workflow
        if (Boolean.TRUE.equals(request.getSubmitForReview())) {
            property.setStatus(PropertyStatus.SUBMITTED.name());
        }

        Property saved = propertyRepository.save(property);

        auditLogService.logAction(
                principal.getUserId(),
                "PROPERTY_UPDATED",
                "public.posted_properties/" + saved.getId(),
                "Updated property status: " + saved.getStatus()
        );

        return PropertyDetailsDto.fromEntity(saved, true);
    }

    /**
     * Authenticated dealer retrieves their own inventory with exact filtering.
     */
    @Transactional(readOnly = true)
    public Page<PropertyDetailsDto> getDealerProperties(AuthenticatedUser principal, PropertySearchRequest request) {
        if (principal == null || principal.getUserId() == null) {
            throw new ForbiddenException("Authentication required to view dealer properties");
        }

        DealerProfile dealer = dealerProfileRepository.findByUserId(principal.getUserId())
                .orElseThrow(() -> new ForbiddenException("No dealer profile associated with current user"));

        request.validate();

        // Enforce dealer isolation strictly by binding dealerId server-side
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
                dealer.getId()
        );

        Pageable pageable = PageRequest.of(
                request.getPage(),
                request.getSize(),
                request.getSortOption().getSort()
        );

        return propertyRepository.findAll(spec, pageable)
                .map(p -> PropertyDetailsDto.fromEntity(p, true));
    }

    private boolean isDealerOwner(UUID userId, UUID propertyDealerId) {
        if (userId == null || propertyDealerId == null) {
            return false;
        }
        Optional<DealerProfile> dealerOpt = dealerProfileRepository.findByUserId(userId);
        return dealerOpt.map(dealer -> dealer.getId().equals(propertyDealerId)).orElse(false);
    }
}
