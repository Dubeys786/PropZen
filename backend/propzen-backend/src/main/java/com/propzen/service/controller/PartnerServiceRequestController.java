package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.ServiceRequestDetailDto;
import com.propzen.service.dto.ServiceRequestDto;
import com.propzen.service.service.ServiceRequestService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Tag(name = "Service Partners - Requests", description = "Service partner request fulfillment and workflow APIs")
@RestController
@RequestMapping("/api/v1/partner")
@PreAuthorize("hasAnyRole('SERVICE_PARTNER', 'ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class PartnerServiceRequestController {

    private final ServiceRequestService requestService;
    private final CurrentUserService currentUserService;

    public PartnerServiceRequestController(ServiceRequestService requestService,
                                          CurrentUserService currentUserService) {
        this.requestService = requestService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Get all service requests assigned to the authenticated partner")
    @GetMapping({"/service-requests", "/requests"})
    public ResponseEntity<ApiResponse<PageResponse<ServiceRequestDto>>> getPartnerRequests(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ServiceRequestDto> result = requestService.getPartnerRequests(partner, pageable);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @Operation(summary = "Get details of an assigned service request")
    @GetMapping({"/service-requests/{id}", "/requests/{id}"})
    public ResponseEntity<ApiResponse<ServiceRequestDetailDto>> getRequestDetails(@PathVariable UUID id) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        ServiceRequestDetailDto detail = requestService.getRequestDetails(id, partner);
        return ResponseEntity.ok(ApiResponse.ok(detail));
    }

    @Operation(summary = "Update partner service request status")
    @PatchMapping({"/service-requests/{id}/status", "/requests/{id}/status"})
    public ResponseEntity<ApiResponse<ServiceRequestDto>> updateRequestStatus(
            @PathVariable UUID id,
            @RequestBody Map<String, String> body) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        String statusStr = body != null ? body.get("status") : null;
        if ("ACCEPTED".equalsIgnoreCase(statusStr)) {
            return ResponseEntity.ok(ApiResponse.ok(requestService.acceptRequest(id, partner), "Service request accepted"));
        } else if ("REJECTED".equalsIgnoreCase(statusStr)) {
            return ResponseEntity.ok(ApiResponse.ok(requestService.rejectRequest(id, body != null ? body.get("reason") : null, partner), "Service request declined"));
        } else if ("IN_PROGRESS".equalsIgnoreCase(statusStr)) {
            return ResponseEntity.ok(ApiResponse.ok(requestService.startService(id, partner), "Service work started"));
        } else if ("COMPLETED".equalsIgnoreCase(statusStr)) {
            return ResponseEntity.ok(ApiResponse.ok(requestService.completeService(id, partner), "Service completed successfully"));
        }
        return ResponseEntity.ok(ApiResponse.ok(requestService.getRequestDetails(id, partner).getRequest(), "Status unchanged"));
    }

    @Operation(summary = "Accept an assigned service request")
    @PatchMapping("/service-requests/{id}/accept")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> acceptRequest(@PathVariable UUID id) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        ServiceRequestDto accepted = requestService.acceptRequest(id, partner);
        return ResponseEntity.ok(ApiResponse.ok(accepted, "Service request accepted"));
    }

    @Operation(summary = "Decline/reject an assigned service request")
    @PatchMapping("/service-requests/{id}/reject")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> rejectRequest(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body
    ) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        String reason = body != null ? body.get("reason") : null;
        ServiceRequestDto rejected = requestService.rejectRequest(id, reason, partner);
        return ResponseEntity.ok(ApiResponse.ok(rejected, "Service request declined"));
    }

    @Operation(summary = "Start work on an accepted service request")
    @PatchMapping("/service-requests/{id}/start")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> startService(@PathVariable UUID id) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        ServiceRequestDto started = requestService.startService(id, partner);
        return ResponseEntity.ok(ApiResponse.ok(started, "Service work started"));
    }

    @Operation(summary = "Complete an active service request")
    @PatchMapping("/service-requests/{id}/complete")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> completeService(@PathVariable UUID id) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        ServiceRequestDto completed = requestService.completeService(id, partner);
        return ResponseEntity.ok(ApiResponse.ok(completed, "Service completed successfully"));
    }

    @Operation(summary = "List all currently active services with calculated progress")
    @GetMapping("/services/active")
    public ResponseEntity<ApiResponse<List<ServiceRequestDetailDto>>> getActiveServices() {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        List<ServiceRequestDetailDto> active = requestService.getActiveServicesForPartner(partner);
        return ResponseEntity.ok(ApiResponse.ok(active));
    }
}
