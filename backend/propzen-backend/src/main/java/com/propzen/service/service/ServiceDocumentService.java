package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.ServiceDocumentDto;
import com.propzen.service.dto.UploadDocumentRequest;
import com.propzen.service.dto.VerifyDocumentRequest;
import com.propzen.service.entity.ServiceDocument;
import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.DocumentVerificationStatus;
import com.propzen.service.model.ServiceJourneyEventType;
import com.propzen.service.repository.ServiceDocumentRepository;
import com.propzen.service.repository.ServiceJourneyEventRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ServiceDocumentService {

    private final ServiceDocumentRepository documentRepository;
    private final ServiceRequestRepository requestRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final ServiceJourneyEventRepository journeyEventRepository;
    private final AuditLogService auditLogService;

    public ServiceDocumentService(ServiceDocumentRepository documentRepository,
                                  ServiceRequestRepository requestRepository,
                                  ServicePartnerProfileRepository partnerProfileRepository,
                                  ServiceJourneyEventRepository journeyEventRepository,
                                  AuditLogService auditLogService) {
        this.documentRepository = documentRepository;
        this.requestRepository = requestRepository;
        this.partnerProfileRepository = partnerProfileRepository;
        this.journeyEventRepository = journeyEventRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public ServiceDocumentDto uploadDocument(UUID serviceRequestId, UploadDocumentRequest request, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertDocumentAccess(sr, actor);

        ServiceDocument doc = new ServiceDocument();
        doc.setServiceRequestId(sr.getId());
        doc.setUploadedBy(actor.getUserId());
        doc.setDocumentType(request.getDocumentType().trim());
        doc.setFileName(request.getFileName().trim());
        doc.setStoragePath(request.getStoragePath());
        doc.setFileUrl(request.getFileUrl().trim());
        doc.setMimeType(request.getMimeType());
        doc.setFileSize(request.getFileSize());
        doc.setVerificationStatus(DocumentVerificationStatus.UPLOADED);

        ServiceDocument saved = documentRepository.save(doc);

        // Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(sr.getId());
        event.setEventType(ServiceJourneyEventType.DOCUMENT_UPLOADED);
        event.setTitle("Document Uploaded");
        event.setDescription(doc.getFileName() + " (" + doc.getDocumentType() + ") uploaded.");
        event.setCreatedBy(actor.getUserId());
        journeyEventRepository.save(event);

        auditLogService.logAction(
                actor.getUserId(),
                "SERVICE_DOCUMENT_UPLOADED",
                "public.service_documents/" + saved.getId(),
                "Document " + saved.getFileName() + " uploaded for request " + sr.getServiceNumber()
        );

        return ServiceDocumentDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ServiceDocumentDto> getDocuments(UUID serviceRequestId, AuthenticatedUser actor) {
        ServiceRequest sr = requestRepository.findById(serviceRequestId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceRequest", serviceRequestId));

        assertDocumentAccess(sr, actor);

        return documentRepository.findByServiceRequestIdOrderByUploadedAtDesc(serviceRequestId)
                .stream()
                .map(ServiceDocumentDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public ServiceDocumentDto verifyDocument(UUID documentId, VerifyDocumentRequest request, AuthenticatedUser verifier) {
        ServiceDocument doc = documentRepository.findById(documentId)
                .orElseThrow(() -> new ResourceNotFoundException("ServiceDocument", documentId));

        boolean isAdminOrStaff = verifier != null && verifier.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_STAFF"));
        if (!isAdminOrStaff) {
            throw new ForbiddenException("Only administrators and staff can verify service documents");
        }

        doc.setVerificationStatus(request.getVerificationStatus());
        doc.setVerifiedBy(verifier.getUserId());
        doc.setVerifiedAt(OffsetDateTime.now());
        if (request.getRejectionReason() != null) {
            doc.setRejectionReason(request.getRejectionReason());
        }

        ServiceDocument saved = documentRepository.save(doc);

        // Record Journey event
        ServiceJourneyEvent event = new ServiceJourneyEvent();
        event.setServiceRequestId(saved.getServiceRequestId());
        event.setEventType(ServiceJourneyEventType.DOCUMENT_VERIFIED);
        event.setTitle("Document " + (request.getVerificationStatus() == DocumentVerificationStatus.VERIFIED ? "Verified" : "Rejected"));
        event.setDescription("Document " + saved.getFileName() + " marked as " + request.getVerificationStatus());
        event.setCreatedBy(verifier.getUserId());
        journeyEventRepository.save(event);

        auditLogService.logAction(
                verifier.getUserId(),
                "SERVICE_DOCUMENT_VERIFIED",
                "public.service_documents/" + saved.getId(),
                "Document status changed to " + request.getVerificationStatus()
        );

        return ServiceDocumentDto.fromEntity(saved);
    }

    private void assertDocumentAccess(ServiceRequest request, AuthenticatedUser actor) {
        if (actor == null) throw new ForbiddenException("Authentication required");

        boolean isAdminOrStaff = actor.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_STAFF"));
        if (isAdminOrStaff) return;

        if (request.getCustomerId().equals(actor.getUserId())) return;

        if (request.getPartnerId() != null) {
            ServicePartnerProfile partner = partnerProfileRepository.findByUserId(actor.getUserId()).orElse(null);
            if (partner != null && partner.getId().equals(request.getPartnerId())) {
                return;
            }
        }

        throw new ForbiddenException("Access denied to service documents");
    }
}
