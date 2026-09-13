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
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Tag(name = "Service Partners - Milestones", description = "Partner milestone creation and progress management APIs")
@RestController
@RequestMapping("/api/v1/partner")
@PreAuthorize("hasAnyRole('SERVICE_PARTNER', 'ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class PartnerMilestoneController {

    private final ServiceMilestoneService milestoneService;
    private final CurrentUserService currentUserService;

    public PartnerMilestoneController(ServiceMilestoneService milestoneService,
                                     CurrentUserService currentUserService) {
        this.milestoneService = milestoneService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Add a new milestone to an assigned service request")
    @PostMapping("/service-requests/{id}/milestones")
    public ResponseEntity<ApiResponse<ServiceMilestoneDto>> createMilestone(
            @PathVariable UUID id,
            @Valid @RequestBody CreateMilestoneRequest request
    ) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        ServiceMilestoneDto created = milestoneService.createMilestone(id, request, partner);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created, "Milestone created successfully"));
    }

    @Operation(summary = "Update an existing service milestone")
    @PatchMapping("/milestones/{id}")
    public ResponseEntity<ApiResponse<ServiceMilestoneDto>> updateMilestone(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateMilestoneRequest request
    ) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        ServiceMilestoneDto updated = milestoneService.updateMilestone(id, request, partner);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }
}
