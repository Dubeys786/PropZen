package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.AssignLeadRequest;
import com.propzen.crm.dto.CreateFollowUpRequest;
import com.propzen.crm.dto.CreateLeadRequest;
import com.propzen.crm.dto.LeadActivityDto;
import com.propzen.crm.dto.LeadDto;
import com.propzen.crm.dto.LeadSearchRequest;
import com.propzen.crm.dto.UpdateLeadPriorityRequest;
import com.propzen.crm.dto.UpdateLeadRequest;
import com.propzen.crm.dto.UpdateLeadStatusRequest;
import com.propzen.crm.service.FollowUpService;
import com.propzen.crm.service.LeadService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/crm/leads")
@Tag(name = "CRM Lead Management", description = "Endpoints for managing leads, assignments, follow-ups, and timelines")
public class LeadController {

    private final LeadService leadService;
    private final FollowUpService followUpService;
    private final CurrentUserService currentUserService;
    private final com.propzen.crm.service.CrmNoteService crmNoteService;
    private final com.propzen.crm.service.CrmTaskService crmTaskService;
    private final com.propzen.crm.service.ServicePartnerLeadRoutingService servicePartnerLeadRoutingService;

    public LeadController(LeadService leadService,
                          FollowUpService followUpService,
                          CurrentUserService currentUserService,
                          com.propzen.crm.service.CrmNoteService crmNoteService,
                          com.propzen.crm.service.CrmTaskService crmTaskService,
                          com.propzen.crm.service.ServicePartnerLeadRoutingService servicePartnerLeadRoutingService) {
        this.leadService = leadService;
        this.followUpService = followUpService;
        this.currentUserService = currentUserService;
        this.crmNoteService = crmNoteService;
        this.crmTaskService = crmTaskService;
        this.servicePartnerLeadRoutingService = servicePartnerLeadRoutingService;
    }

    @PostMapping
    @Operation(summary = "Create a new lead manually")
    public ResponseEntity<ApiResponse<LeadDto>> createLead(@Valid @RequestBody CreateLeadRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto created = leadService.createLead(request, actor);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Lead created successfully"));
    }

    @GetMapping
    @Operation(summary = "Search and filter CRM leads",
            description = "Provides role-based filtering: dealers only see their assigned leads, admins see all")
    public ResponseEntity<ApiResponse<Page<LeadDto>>> searchLeads(@ModelAttribute LeadSearchRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Page<LeadDto> page = leadService.searchLeads(request, actor);
        return ResponseEntity.ok(ApiResponse.ok(page, "Leads retrieved successfully"));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Retrieve lead details",
            description = "Returns full lead information with IDOR ownership validation")
    public ResponseEntity<ApiResponse<LeadDto>> getLead(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto lead = leadService.getLead(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(lead, "Lead retrieved successfully"));
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Update permitted lead details")
    public ResponseEntity<ApiResponse<LeadDto>> updateLead(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateLeadRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto updated = leadService.updateLead(id, request, actor);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Lead updated successfully"));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Transition lead lifecycle status")
    public ResponseEntity<ApiResponse<LeadDto>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateLeadStatusRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto updated = leadService.updateStatus(id, request, actor);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Lead status updated successfully"));
    }

    @PatchMapping("/{id}/priority")
    @Operation(summary = "Update lead follow-up priority")
    public ResponseEntity<ApiResponse<LeadDto>> updatePriority(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateLeadPriorityRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto updated = leadService.updatePriority(id, request, actor);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Lead priority updated successfully"));
    }

    @PatchMapping("/{id}/assign")
    @Operation(summary = "Assign or reassign lead to a dealer or staff member (Admin only)")
    public ResponseEntity<ApiResponse<LeadDto>> assignLead(
            @PathVariable UUID id,
            @Valid @RequestBody AssignLeadRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto assigned = leadService.assignLead(id, request, actor);
        return ResponseEntity.ok(ApiResponse.ok(assigned, "Lead assigned successfully"));
    }

    @GetMapping("/{id}/timeline")
    @Operation(summary = "Get chronological activity timeline for lead")
    public ResponseEntity<ApiResponse<List<LeadActivityDto>>> getTimeline(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<LeadActivityDto> timeline = leadService.getTimeline(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(timeline, "Timeline retrieved successfully"));
    }

    @GetMapping("/{id}/activities")
    @Operation(summary = "Alias for timeline")
    public ResponseEntity<ApiResponse<List<LeadActivityDto>>> getActivities(@PathVariable UUID id) {
        return getTimeline(id);
    }

    @PostMapping("/{id}/follow-ups")
    @Operation(summary = "Schedule or record a follow-up for this lead")
    public ResponseEntity<ApiResponse<LeadActivityDto>> addFollowUp(
            @PathVariable UUID id,
            @Valid @RequestBody CreateFollowUpRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadActivityDto created = followUpService.addFollowUp(id, request, actor);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Follow-up added successfully"));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete lead by ID (Admin only)")
    public ResponseEntity<ApiResponse<Void>> deleteLead(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        leadService.deleteLead(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(null, "Lead deleted successfully"));
    }

    @PatchMapping("/{id}/stage")
    @Operation(summary = "Update lead pipeline funnel stage")
    public ResponseEntity<ApiResponse<LeadDto>> updateStage(
            @PathVariable UUID id,
            @Valid @RequestBody com.propzen.crm.dto.UpdateLeadStageRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto updated = leadService.updateStage(id, request.getStage(), request.getNotes(), actor);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Lead stage updated successfully"));
    }

    @PatchMapping("/{id}/convert")
    @Operation(summary = "Convert lead to customer/sale")
    public ResponseEntity<ApiResponse<LeadDto>> convertLead(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        LeadDto converted = leadService.convertLead(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(converted, "Lead converted successfully"));
    }

    @PostMapping("/{id}/notes")
    @Operation(summary = "Add an internal note to this lead")
    public ResponseEntity<ApiResponse<com.propzen.crm.dto.CrmNoteDto>> addNote(
            @PathVariable UUID id,
            @Valid @RequestBody com.propzen.crm.dto.CreateNoteRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        request.setLeadId(id);
        com.propzen.crm.dto.CrmNoteDto note = crmNoteService.addNote(request, actor.getUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(note, "Note added successfully"));
    }

    @GetMapping("/{id}/notes")
    @Operation(summary = "Get internal notes for this lead")
    public ResponseEntity<ApiResponse<List<com.propzen.crm.dto.CrmNoteDto>>> getNotes(@PathVariable UUID id) {
        List<com.propzen.crm.dto.CrmNoteDto> notes = crmNoteService.getNotesByLeadId(id);
        return ResponseEntity.ok(ApiResponse.ok(notes, "Notes retrieved successfully"));
    }

    @PostMapping("/{id}/tasks")
    @Operation(summary = "Create an internal CRM task for this lead")
    public ResponseEntity<ApiResponse<com.propzen.crm.dto.CrmTaskDto>> createTask(
            @PathVariable UUID id,
            @Valid @RequestBody com.propzen.crm.dto.CreateTaskRequest request) {
        request.setLeadId(id);
        com.propzen.crm.dto.CrmTaskDto task = crmTaskService.createTask(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(task, "Task created successfully"));
    }

    @GetMapping("/{id}/tasks")
    @Operation(summary = "Get internal CRM tasks for this lead")
    public ResponseEntity<ApiResponse<List<com.propzen.crm.dto.CrmTaskDto>>> getTasks(@PathVariable UUID id) {
        List<com.propzen.crm.dto.CrmTaskDto> tasks = crmTaskService.getTasksByLeadId(id);
        return ResponseEntity.ok(ApiResponse.ok(tasks, "Tasks retrieved successfully"));
    }

    @PostMapping("/service-enquiry")
    @Operation(summary = "Submit a service partner enquiry lead")
    public ResponseEntity<ApiResponse<LeadDto>> createServiceEnquiry(@Valid @RequestBody CreateLeadRequest request) {
        AuthenticatedUser actor = currentUserService.getCurrentUser().orElse(null);
        if (request.getSource() == null) {
            request.setSource(com.propzen.crm.model.LeadSource.SERVICE_REQUEST);
        }
        LeadDto created = leadService.createLead(request, actor);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Service enquiry submitted successfully"));
    }

    @GetMapping("/my")
    @Operation(summary = "Get current authenticated customer's submitted service leads")
    public ResponseEntity<ApiResponse<List<LeadDto>>> getMyLeads() {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<LeadDto> list = leadService.getCustomerLeads(actor);
        return ResponseEntity.ok(ApiResponse.ok(list, "Customer leads retrieved successfully"));
    }

    @GetMapping("/{id}/eligible-partners")
    @Operation(summary = "Get list of eligible approved service partners for this lead (Admin only)")
    public ResponseEntity<ApiResponse<List<com.propzen.service.dto.ServicePartnerProfileDto>>> getEligiblePartners(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (!actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) {
            throw new com.propzen.exception.ForbiddenException("Admin access required");
        }
        List<com.propzen.service.dto.ServicePartnerProfileDto> list = servicePartnerLeadRoutingService.getEligiblePartnersForLead(id);
        return ResponseEntity.ok(ApiResponse.ok(list, "Eligible partners retrieved successfully"));
    }

    @PatchMapping("/{id}/assign-partner")
    @Operation(summary = "Manually assign a lead to a specific service partner (Admin only)")
    public ResponseEntity<ApiResponse<LeadDto>> assignPartner(
            @PathVariable UUID id,
            @Valid @RequestBody com.propzen.crm.dto.AssignPartnerRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (!actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) {
            throw new com.propzen.exception.ForbiddenException("Admin access required");
        }
        var assigned = servicePartnerLeadRoutingService.assignPartnerManually(id, request.getPartnerId(), actor);
        return ResponseEntity.ok(ApiResponse.ok(leadService.toEnrichedDto(assigned), "Partner assigned successfully"));
    }

    @PatchMapping("/{id}/unassign-partner")
    @Operation(summary = "Unassign lead back to unassigned queue (Admin only)")
    public ResponseEntity<ApiResponse<LeadDto>> unassignPartner(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (!actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) {
            throw new com.propzen.exception.ForbiddenException("Admin access required");
        }
        var unassigned = servicePartnerLeadRoutingService.unassignPartner(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(leadService.toEnrichedDto(unassigned), "Partner unassigned successfully"));
    }
}
