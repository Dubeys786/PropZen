package com.propzen.crm.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.crm.dto.CreateSiteVisitRequest;
import com.propzen.crm.dto.SiteVisitDto;
import com.propzen.crm.entity.SiteVisit;
import com.propzen.crm.repository.SiteVisitRepository;
import com.propzen.exception.ApiException;
import com.propzen.exception.ErrorCode;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SiteVisitService {

    private static final Logger log = LoggerFactory.getLogger(SiteVisitService.class);

    private final SiteVisitRepository siteVisitRepository;
    private final AuditLogService auditLogService;

    public SiteVisitService(SiteVisitRepository siteVisitRepository,
                            AuditLogService auditLogService) {
        this.siteVisitRepository = siteVisitRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public SiteVisitDto bookSiteVisit(CreateSiteVisitRequest request, AuthenticatedUser principal) {
        log.info("Booking site visit for property '{}' by '{}'", request.getPropertyTitle(), request.getUserName());

        SiteVisit visit = new SiteVisit();
        visit.setPropertyId(request.getPropertyId());
        visit.setPropertyTitle(request.getPropertyTitle());
        visit.setUserName(request.getUserName().trim());
        visit.setUserEmail(request.getUserEmail() != null ? request.getUserEmail().trim().toLowerCase() : null);
        visit.setUserPhone(request.getUserPhone().trim());
        visit.setVisitDate(request.getVisitDate());
        visit.setTimeSlot(request.getTimeSlot());
        visit.setVisitorCount(request.getVisitorCount() != null ? request.getVisitorCount() : 1);
        visit.setCabRequired(request.getCabRequired() != null ? request.getCabRequired() : false);
        visit.setDealerId(request.getDealerId());
        visit.setMetadata(request.getMetadata());
        visit.setStatus("Pending Confirmation");

        if (principal != null) {
            visit.setUserId(principal.getUserId());
            if (visit.getUserEmail() == null && principal.getEmail() != null) {
                visit.setUserEmail(principal.getEmail());
            }
        }

        SiteVisit saved = siteVisitRepository.save(visit);

        auditLogService.logAction(
                principal != null ? principal.getUserId() : null,
                "SITE_VISIT_BOOKED",
                "site_visits/" + saved.getId(),
                "Booked site visit for property: " + saved.getPropertyTitle()
        );

        return SiteVisitDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<SiteVisitDto> getMySiteVisits(AuthenticatedUser principal) {
        if (principal == null) {
            return Collections.emptyList();
        }
        return siteVisitRepository.findByUserId(principal.getUserId()).stream()
                .map(SiteVisitDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SiteVisitDto> getDealerSiteVisits(UUID dealerId) {
        if (dealerId == null) {
            return Collections.emptyList();
        }
        return siteVisitRepository.findByDealerId(dealerId).stream()
                .map(SiteVisitDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<SiteVisitDto> getSiteVisitsForProperty(String propertyId) {
        return siteVisitRepository.findByPropertyId(propertyId).stream()
                .map(SiteVisitDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public SiteVisitDto updateStatus(UUID visitId, String newStatus, AuthenticatedUser principal) {
        SiteVisit visit = siteVisitRepository.findById(visitId)
                .orElseThrow(() -> new ApiException("Site visit not found: " + visitId, HttpStatus.NOT_FOUND, ErrorCode.RESOURCE_NOT_FOUND));

        String oldStatus = visit.getStatus();
        visit.setStatus(newStatus);
        SiteVisit updated = siteVisitRepository.save(visit);

        auditLogService.logAction(
                principal != null ? principal.getUserId() : null,
                "SITE_VISIT_STATUS_UPDATED",
                "site_visits/" + visit.getId(),
                String.format("Updated status from '%s' to '%s'", oldStatus, newStatus)
        );

        return SiteVisitDto.fromEntity(updated);
    }
}
