package com.propzen.dealer.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.dealer.dto.DealerProfileDto;
import com.propzen.dealer.dto.UpdateDealerStatusRequest;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.service.AdminDealerService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/dealers")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Admin Dealer Management", description = "Admin-only operations for reviewing, approving, and managing dealers")
public class AdminDealerController {

    private final AdminDealerService adminDealerService;
    private final CurrentUserService currentUserService;

    public AdminDealerController(AdminDealerService adminDealerService, CurrentUserService currentUserService) {
        this.adminDealerService = adminDealerService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "List dealer applications with pagination and filters")
    public ResponseEntity<ApiResponse<PageResponse<DealerProfileDto>>> listDealers(
            @RequestParam(required = false) DealerStatus status,
            @RequestParam(required = false) DealerVerificationStatus verificationStatus,
            @RequestParam(required = false) String search,
            @PageableDefault(page = 0, size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        PageResponse<DealerProfileDto> result = adminDealerService.listDealers(status, verificationStatus, search, pageable);
        return ResponseEntity.ok(ApiResponse.ok(result, "Dealers listed successfully"));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get specific dealer profile details by ID")
    public ResponseEntity<ApiResponse<DealerProfileDto>> getDealerById(@PathVariable UUID id) {
        DealerProfileDto profile = adminDealerService.getDealerById(id);
        return ResponseEntity.ok(ApiResponse.ok(profile, "Dealer details retrieved successfully"));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update dealer status (approve, reject, suspend) and trigger server-side role activation")
    public ResponseEntity<ApiResponse<DealerProfileDto>> updateDealerStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateDealerStatusRequest request) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        DealerProfileDto updated = adminDealerService.updateDealerStatus(id, request, adminUser);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Dealer status updated successfully"));
    }
}
