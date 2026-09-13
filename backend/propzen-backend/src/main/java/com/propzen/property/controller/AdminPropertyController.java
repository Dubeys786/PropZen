package com.propzen.property.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.property.dto.PropertyAdminDto;
import com.propzen.property.dto.PropertySearchRequest;
import com.propzen.property.dto.UpdatePropertyStatusRequest;
import com.propzen.property.service.AdminPropertyService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Endpoints for administrative moderation, review, and property lifecycle management.
 */
@RestController
@RequestMapping("/api/v1/admin/properties")
@Tag(name = "Admin Property Management", description = "Endpoints for administrators to review, approve, reject, and inspect properties")
public class AdminPropertyController {

    private final AdminPropertyService adminPropertyService;
    private final CurrentUserService currentUserService;

    public AdminPropertyController(AdminPropertyService adminPropertyService, CurrentUserService currentUserService) {
        this.adminPropertyService = adminPropertyService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "Search all properties (Admin)",
            description = "Provides unfiltered access across all property statuses and dealer accounts")
    public ResponseEntity<ApiResponse<Page<PropertyAdminDto>>> searchProperties(
            @ModelAttribute PropertySearchRequest request) {
        Page<PropertyAdminDto> page = adminPropertyService.searchProperties(request);
        return ResponseEntity.ok(ApiResponse.ok(page, "Properties retrieved successfully"));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get full property details for review (Admin)",
            description = "Includes owner phone, dealer ID, internal metadata, and administrator review notes")
    public ResponseEntity<ApiResponse<PropertyAdminDto>> getPropertyDetails(@PathVariable UUID id) {
        PropertyAdminDto details = adminPropertyService.getPropertyDetails(id);
        return ResponseEntity.ok(ApiResponse.ok(details, "Property details retrieved successfully"));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update property status and review notes (Admin)",
            description = "Transitions property status (e.g. APPROVED, PUBLISHED, REJECTED, ARCHIVED) with optional admin notes")
    public ResponseEntity<ApiResponse<PropertyAdminDto>> updatePropertyStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePropertyStatusRequest request) {
        AuthenticatedUser admin = currentUserService.getRequiredCurrentUser();
        PropertyAdminDto updated = adminPropertyService.updatePropertyStatus(id, request, admin);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Property status updated successfully"));
    }
}
