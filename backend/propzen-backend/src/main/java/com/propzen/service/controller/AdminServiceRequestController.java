package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.*;
import com.propzen.service.model.ServicePriority;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.service.ServiceAssignmentService;
import com.propzen.service.service.ServiceRequestService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Tag(name = "Admin - Service Requests", description = "Administrative service request oversight, matching, and assignment APIs")
@RestController
@RequestMapping("/api/v1/admin/service-requests")
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class AdminServiceRequestController {

    private final ServiceRequestService requestService;
    private final ServiceAssignmentService assignmentService;
    private final CurrentUserService currentUserService;

    public AdminServiceRequestController(ServiceRequestService requestService,
                                        ServiceAssignmentService assignmentService,
                                        CurrentUserService currentUserService) {
        this.requestService = requestService;
        this.assignmentService = assignmentService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Search all service requests with full filters and pagination")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ServiceRequestDto>>> searchRequests(
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) ServiceRequestStatus status,
            @RequestParam(required = false) ServicePriority priority,
            @RequestParam(required = false) UUID partnerId,
            @RequestParam(required = false) UUID customerId,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime createdAfter,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime createdBefore,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ServiceRequestDto> result = requestService.searchRequestsAdmin(
                categoryId, status, priority, partnerId, customerId, location, search, createdAfter, createdBefore, pageable
        );
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @Operation(summary = "Get ranked partner recommendations for a service request")
    @GetMapping("/{id}/recommendations")
    public ResponseEntity<ApiResponse<List<PartnerRecommendationDto>>> getRecommendations(@PathVariable UUID id) {
        List<PartnerRecommendationDto> recs = assignmentService.getRecommendations(id);
        return ResponseEntity.ok(ApiResponse.ok(recs));
    }

    @Operation(summary = "Assign a partner to a service request")
    @PostMapping("/{id}/assign")
    public ResponseEntity<ApiResponse<ServiceAssignmentDto>> assignPartner(
            @PathVariable UUID id,
            @Valid @RequestBody AssignPartnerRequest request
    ) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        ServiceAssignmentDto assignment = assignmentService.assignPartner(id, request.getPartnerId(), request.getNotes(), adminUser);
        return ResponseEntity.ok(ApiResponse.ok(assignment, "Partner assigned successfully"));
    }

    @Operation(summary = "Update service request status")
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateServiceRequestStatusRequest request
    ) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        ServiceRequestDto updated = requestService.updateStatusAdmin(id, request, adminUser);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Status updated successfully"));
    }
}
