package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.LeadActivityDto;
import com.propzen.crm.service.FollowUpService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/crm/follow-ups")
@Tag(name = "CRM Follow-ups", description = "Endpoints for managing scheduled follow-ups and activity completion")
public class FollowUpController {

    private final FollowUpService followUpService;
    private final CurrentUserService currentUserService;
    private final com.propzen.crm.service.CrmFollowUpService crmFollowUpService;

    public FollowUpController(FollowUpService followUpService,
                              CurrentUserService currentUserService,
                              com.propzen.crm.service.CrmFollowUpService crmFollowUpService) {
        this.followUpService = followUpService;
        this.currentUserService = currentUserService;
        this.crmFollowUpService = crmFollowUpService;
    }

    @org.springframework.web.bind.annotation.GetMapping
    @Operation(summary = "List follow-ups assigned to current user")
    public ResponseEntity<ApiResponse<java.util.List<com.propzen.crm.dto.FollowUpDto>>> getFollowUps() {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        java.util.List<com.propzen.crm.dto.FollowUpDto> list = crmFollowUpService.getFollowUpsByAssignedTo(actor.getUserId());
        return ResponseEntity.ok(ApiResponse.ok(list, "Follow-ups retrieved successfully"));
    }

    @org.springframework.web.bind.annotation.PostMapping
    @Operation(summary = "Schedule a new follow-up")
    public ResponseEntity<ApiResponse<com.propzen.crm.dto.FollowUpDto>> scheduleFollowUp(
            @jakarta.validation.Valid @org.springframework.web.bind.annotation.RequestBody com.propzen.crm.dto.CreateFollowUpDto dto) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (dto.getAssignedTo() == null) {
            dto.setAssignedTo(actor.getUserId());
        }
        com.propzen.crm.dto.FollowUpDto created = crmFollowUpService.scheduleFollowUp(dto);
        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Follow-up scheduled successfully"));
    }

    @PatchMapping("/{id}/complete")
    @Operation(summary = "Mark a follow-up activity as completed")
    public ResponseEntity<ApiResponse<Object>> completeFollowUp(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        try {
            com.propzen.crm.dto.FollowUpDto fup = crmFollowUpService.completeFollowUp(id);
            return ResponseEntity.ok(ApiResponse.ok(fup, "Follow-up marked as completed"));
        } catch (java.util.NoSuchElementException e) {
            LeadActivityDto completed = followUpService.completeFollowUp(id, actor);
            return ResponseEntity.ok(ApiResponse.ok(completed, "Follow-up marked as completed"));
        }
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete or cancel a follow-up activity")
    public ResponseEntity<ApiResponse<Void>> deleteFollowUp(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        try {
            crmFollowUpService.cancelFollowUp(id);
        } catch (java.util.NoSuchElementException e) {
            followUpService.deleteFollowUp(id, actor);
        }
        return ResponseEntity.ok(ApiResponse.ok(null, "Follow-up deleted successfully"));
    }
}
