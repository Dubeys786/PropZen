package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.ServicePartnerProfileDto;
import com.propzen.service.dto.UpdatePartnerStatusRequest;
import com.propzen.service.dto.UpdatePartnerVerificationRequest;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.service.AdminServicePartnerService;
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
import java.util.UUID;

@Tag(name = "Admin - Service Partners", description = "Administrative service partner approval and oversight APIs")
@RestController
@RequestMapping("/api/v1/admin/service-partners")
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class AdminServicePartnerController {

    private final AdminServicePartnerService adminPartnerService;
    private final CurrentUserService currentUserService;

    public AdminServicePartnerController(AdminServicePartnerService adminPartnerService,
                                        CurrentUserService currentUserService) {
        this.adminPartnerService = adminPartnerService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Search and list service partner applications with pagination and filters")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ServicePartnerProfileDto>>> listPartners(
            @RequestParam(required = false) PartnerStatus status,
            @RequestParam(required = false) PartnerVerificationStatus verificationStatus,
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime createdAfter,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime createdBefore,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ServicePartnerProfileDto> result = adminPartnerService.listPartners(
                status, verificationStatus, city, search, createdAfter, createdBefore, pageable
        );
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @Operation(summary = "Get service partner profile by ID")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServicePartnerProfileDto>> getPartnerById(@PathVariable UUID id) {
        ServicePartnerProfileDto partner = adminPartnerService.getPartnerById(id);
        return ResponseEntity.ok(ApiResponse.ok(partner));
    }

    @Operation(summary = "Update service partner status (approve, suspend, reject)")
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ServicePartnerProfileDto>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePartnerStatusRequest request
    ) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        ServicePartnerProfileDto updated = adminPartnerService.updatePartnerStatus(id, request, adminUser);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }

    @Operation(summary = "Update service partner verification status")
    @PatchMapping("/{id}/verification")
    public ResponseEntity<ApiResponse<ServicePartnerProfileDto>> updateVerification(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePartnerVerificationRequest request
    ) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        ServicePartnerProfileDto updated = adminPartnerService.updatePartnerVerification(id, request, adminUser);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }
}
