package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CreateWhatsAppTemplateRequest;
import com.propzen.crm.dto.CrmCommunicationDto;
import com.propzen.crm.dto.OneClickWhatsAppRequest;
import com.propzen.crm.dto.WhatsAppTemplateDto;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.service.CrmCommunicationService;
import com.propzen.crm.service.LeadService;
import com.propzen.crm.service.WhatsAppNotificationService;
import com.propzen.crm.service.WhatsAppTemplateService;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/whatsapp")
@Tag(name = "Official WhatsApp Business API", description = "Endpoints for official Meta Cloud API WhatsApp notifications and templates")
public class WhatsAppController {

    private final WhatsAppNotificationService whatsAppNotificationService;
    private final WhatsAppTemplateService whatsAppTemplateService;
    private final CrmCommunicationService communicationService;
    private final CurrentUserService currentUserService;
    private final LeadRepository leadRepository;
    private final LeadService leadService;

    public WhatsAppController(
            WhatsAppNotificationService whatsAppNotificationService,
            WhatsAppTemplateService whatsAppTemplateService,
            CrmCommunicationService communicationService,
            CurrentUserService currentUserService,
            LeadRepository leadRepository,
            LeadService leadService
    ) {
        this.whatsAppNotificationService = whatsAppNotificationService;
        this.whatsAppTemplateService = whatsAppTemplateService;
        this.communicationService = communicationService;
        this.currentUserService = currentUserService;
        this.leadRepository = leadRepository;
        this.leadService = leadService;
    }

    @PostMapping("/send")
    @Operation(summary = "Send an official WhatsApp template notification (with opt-in check)")
    public ResponseEntity<ApiResponse<CrmCommunicationDto>> sendNotification(@Valid @RequestBody OneClickWhatsAppRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (request.getLeadId() != null) {
            Lead lead = leadRepository.findById(request.getLeadId())
                    .orElseThrow(() -> new ResourceNotFoundException("Lead", request.getLeadId()));
            leadService.assertLeadAccess(lead, actor);
        }
        CrmCommunicationDto comm = whatsAppNotificationService.sendTemplateNotification(request);
        return ResponseEntity.ok(ApiResponse.ok(comm, "WhatsApp message dispatched"));
    }

    @PostMapping("/template")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Register or define an official WhatsApp message template (Admin only)")
    public ResponseEntity<ApiResponse<WhatsAppTemplateDto>> createTemplate(@Valid @RequestBody CreateWhatsAppTemplateRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        WhatsAppTemplateDto template = whatsAppTemplateService.createTemplate(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(template, "Template created successfully"));
    }

    @GetMapping("/templates")
    @Operation(summary = "List all approved WhatsApp templates")
    public ResponseEntity<ApiResponse<List<WhatsAppTemplateDto>>> getTemplates() {
        List<WhatsAppTemplateDto> templates = whatsAppTemplateService.getApprovedTemplates();
        return ResponseEntity.ok(ApiResponse.ok(templates, "Approved templates retrieved"));
    }

    @GetMapping("/messages")
    @Operation(summary = "List communications history for a lead")
    public ResponseEntity<ApiResponse<List<CrmCommunicationDto>>> getMessages(
            @RequestParam(required = false) UUID leadId,
            @RequestParam(required = false) UUID customerId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (leadId != null) {
            Lead lead = leadRepository.findById(leadId)
                    .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));
            leadService.assertLeadAccess(lead, actor);
            return ResponseEntity.ok(ApiResponse.ok(communicationService.getCommunicationsByLeadId(leadId), "Messages retrieved"));
        } else if (customerId != null) {
            if (!actor.isAdmin() && !actor.getUserId().equals(customerId)) {
                throw new ForbiddenException("Access denied: You cannot view communications for another customer");
            }
            return ResponseEntity.ok(ApiResponse.ok(communicationService.getCommunicationsByCustomerId(customerId), "Messages retrieved"));
        }
        return ResponseEntity.ok(ApiResponse.ok(List.of(), "Provide leadId or customerId parameter"));
    }
}
