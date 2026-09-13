package com.propzen.property.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.property.dto.PropertyDetailsDto;
import com.propzen.property.dto.PropertySearchRequest;
import com.propzen.property.service.PropertyService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoints for authenticated dealers to manage and monitor their property inventory.
 */
@RestController
@RequestMapping("/api/v1/dealers/me/properties")
@Tag(name = "Dealer Property Management", description = "Endpoints for dealers to manage their own property inventory")
public class DealerPropertyController {

    private final PropertyService propertyService;
    private final CurrentUserService currentUserService;

    public DealerPropertyController(PropertyService propertyService, CurrentUserService currentUserService) {
        this.propertyService = propertyService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "Get current dealer's property inventory",
            description = "Returns properties owned by the authenticated dealer. Cannot be overridden by client parameters.")
    public ResponseEntity<ApiResponse<Page<PropertyDetailsDto>>> getMyProperties(
            @ModelAttribute PropertySearchRequest request) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        Page<PropertyDetailsDto> page = propertyService.getDealerProperties(principal, request);
        return ResponseEntity.ok(ApiResponse.ok(page, "Dealer properties retrieved successfully"));
    }
}
