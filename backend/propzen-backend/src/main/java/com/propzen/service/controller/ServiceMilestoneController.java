package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreateMilestoneRequest;
import com.propzen.service.dto.ServiceMilestoneDto;
import com.propzen.service.dto.UpdateMilestoneRequest;
import com.propzen.service.service.ServiceMilestoneService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Tag(name = "Services - Milestones", description = "Service milestone viewing, creation, updates, and sign-off APIs")
@RestController
@RequestMapping({"/api/v1/services", "/api/v1"})
@SecurityRequirement(name = "BearerAuth")
public class ServiceMilestoneController {

    private final ServiceMilestoneService milestoneService;
    private final CurrentUserService currentUserService;

    public ServiceMilestoneController(ServiceMilestoneService milestoneService,
                                      CurrentUserService currentUserService) {
        this.milestoneService = milestoneService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Get all milestones for a service request")
    @GetMapping({"/requests/{id}/milestones", "/service-requests/{id}/milestones"})
    public ResponseEntity<ApiResponse<List<ServiceMilestoneDto>>> getMilestones(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<ServiceMilestoneDto> milestones = milestoneService.getMilestones(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(milestones));
    }

    @Operation(summary = "Add a new milestone to a service request")
    @PostMapping({"/requests/{id}/milestones", "/service-requests/{id}/milestones"})
    public ResponseEntity<ApiResponse<ServiceMilestoneDto>> createMilestone(
            @PathVariable UUID id,
            @Valid @RequestBody CreateMilestoneRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServiceMilestoneDto created = milestoneService.createMilestone(id, request, actor);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created, "Milestone created successfully"));
    }

    @Operation(summary = "Update an existing service milestone")
    @PatchMapping({"/milestones/{id}", "/service-milestones/{id}"})
    public ResponseEntity<ApiResponse<ServiceMilestoneDto>> updateMilestone(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateMilestoneRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServiceMilestoneDto updated = milestoneService.updateMilestone(id, request, actor);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }

    @Operation(summary = "Approve and complete a service milestone")
    @PatchMapping({"/milestones/{id}/approve", "/service-milestones/{id}/approve"})
    public ResponseEntity<ApiResponse<ServiceMilestoneDto>> approveMilestone(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServiceMilestoneDto approved = milestoneService.approveMilestone(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(approved, "Milestone approved"));
    }
}
