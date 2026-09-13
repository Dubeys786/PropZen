package com.propzen.service.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.service.dto.CreateCustomerNoteRequest;
import com.propzen.service.dto.CustomerNoteDto;
import com.propzen.service.dto.PartnerCustomerDto;
import com.propzen.service.entity.ServiceCustomerNote;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.repository.ServiceCustomerNoteRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServiceRequestRepository;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class PartnerCustomerService {

    private final ServiceRequestRepository requestRepository;
    private final ServicePartnerProfileRepository partnerProfileRepository;
    private final ServiceCustomerNoteRepository noteRepository;
    private final UserRepository userRepository;
    private final AuditLogService auditLogService;

    public PartnerCustomerService(ServiceRequestRepository requestRepository,
                                  ServicePartnerProfileRepository partnerProfileRepository,
                                  ServiceCustomerNoteRepository noteRepository,
                                  UserRepository userRepository,
                                  AuditLogService auditLogService) {
        this.requestRepository = requestRepository;
        this.partnerProfileRepository = partnerProfileRepository;
        this.noteRepository = noteRepository;
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public List<PartnerCustomerDto> getCustomersForPartner(AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getRequiredPartner(partnerUser);
        List<UUID> customerIds = requestRepository.findDistinctCustomerIdsByPartnerId(partner.getId());

        List<PartnerCustomerDto> result = new ArrayList<>();
        for (UUID cid : customerIds) {
            result.add(buildCustomerDto(cid, partner.getId()));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public PartnerCustomerDto getCustomerDetails(UUID customerId, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getRequiredPartner(partnerUser);
        boolean hasAccess = requestRepository.findByPartnerId(partner.getId())
                .stream()
                .anyMatch(r -> r.getCustomerId().equals(customerId));

        boolean isAdmin = partnerUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!hasAccess && !isAdmin) {
            throw new ForbiddenException("Access denied: You have no active or completed services with this customer");
        }

        return buildCustomerDto(customerId, partner.getId());
    }

    @Transactional(readOnly = true)
    public List<CustomerNoteDto> getNotes(UUID customerId, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getRequiredPartner(partnerUser);
        return noteRepository.findByCustomerIdAndPartnerIdOrderByCreatedAtDesc(customerId, partner.getId())
                .stream()
                .map(CustomerNoteDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public CustomerNoteDto addNote(UUID customerId, CreateCustomerNoteRequest request, AuthenticatedUser partnerUser) {
        ServicePartnerProfile partner = getRequiredPartner(partnerUser);

        ServiceCustomerNote note = new ServiceCustomerNote();
        note.setCustomerId(customerId);
        note.setPartnerId(partner.getId());
        note.setServiceRequestId(request.getServiceRequestId());
        note.setNote(request.getNote().trim());
        note.setTags(request.getTags());
        note.setNextFollowupAt(request.getNextFollowupAt());
        note.setCreatedBy(partnerUser.getUserId());

        ServiceCustomerNote saved = noteRepository.save(note);

        auditLogService.logAction(
                partnerUser.getUserId(),
                "SERVICE_CUSTOMER_NOTE_ADDED",
                "public.service_customer_notes/" + saved.getId(),
                "Added note for customer " + customerId
        );

        return CustomerNoteDto.fromEntity(saved);
    }

    private PartnerCustomerDto buildCustomerDto(UUID customerId, UUID partnerId) {
        User user = userRepository.findById(customerId).orElse(null);
        List<ServiceRequest> requests = requestRepository.findByPartnerId(partnerId)
                .stream()
                .filter(r -> r.getCustomerId().equals(customerId))
                .toList();

        long total = requests.size();
        long active = requests.stream()
                .filter(r -> r.getStatus() == ServiceRequestStatus.ACCEPTED ||
                             r.getStatus() == ServiceRequestStatus.IN_PROGRESS ||
                             r.getStatus() == ServiceRequestStatus.ON_HOLD ||
                             r.getStatus() == ServiceRequestStatus.ASSIGNED)
                .count();
        long completed = requests.stream()
                .filter(r -> r.getStatus() == ServiceRequestStatus.COMPLETED)
                .count();

        OffsetDateTime lastDate = requests.stream()
                .map(ServiceRequest::getCreatedAt)
                .max(Comparator.naturalOrder())
                .orElse(null);

        PartnerCustomerDto dto = new PartnerCustomerDto();
        dto.setCustomerId(customerId);
        dto.setName(user != null && user.getFullName() != null ? user.getFullName() : "Customer");
        dto.setEmail(user != null ? user.getEmail() : "");
        dto.setPhone(user != null ? user.getPhone() : "");
        dto.setTotalServices(total);
        dto.setActiveServices(active);
        dto.setCompletedServices(completed);
        dto.setLastServiceDate(lastDate);
        return dto;
    }

    private ServicePartnerProfile getRequiredPartner(AuthenticatedUser user) {
        if (user == null) throw new ForbiddenException("Authentication required");
        return partnerProfileRepository.findByUserId(user.getUserId())
                .orElseThrow(() -> new ForbiddenException("No service partner profile found"));
    }
}
