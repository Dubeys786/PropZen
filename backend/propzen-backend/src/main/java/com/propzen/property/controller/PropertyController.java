package com.propzen.property.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.property.dto.CreatePropertyRequest;
import com.propzen.property.dto.PropertyDetailsDto;
import com.propzen.property.dto.PropertyListDto;
import com.propzen.property.dto.PropertySearchRequest;
import com.propzen.property.dto.UpdatePropertyRequest;
import com.propzen.property.service.PropertyService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Public discovery and dealer property management REST endpoints.
 */
@RestController
@RequestMapping("/api/v1/properties")
@Tag(name = "Property Management & Search", description = "Endpoints for property discovery, filtering, creation, and updates")
public class PropertyController {

    private final PropertyService propertyService;
    private final CurrentUserService currentUserService;

    public PropertyController(PropertyService propertyService, CurrentUserService currentUserService) {
        this.propertyService = propertyService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "Search and filter published properties",
            description = "Executes database-level exact filtering across city, sector, locality, bhk, budget, area, amenities, etc.")
    public ResponseEntity<ApiResponse<Page<PropertyListDto>>> searchProperties(
            @ModelAttribute PropertySearchRequest request) {
        Page<PropertyListDto> page = propertyService.searchPublicProperties(request);
        return ResponseEntity.ok(ApiResponse.ok(page, "Properties retrieved successfully"));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Retrieve property details",
            description = "Returns public property details, or extended details if caller is the owner or an admin")
    public ResponseEntity<ApiResponse<PropertyDetailsDto>> getPropertyDetails(@PathVariable UUID id) {
        AuthenticatedUser principal = currentUserService.getCurrentUser().orElse(null);
        PropertyDetailsDto details = propertyService.getPropertyDetails(id, principal);
        return ResponseEntity.ok(ApiResponse.ok(details, "Property details retrieved successfully"));
    }

    @PostMapping
    @Operation(summary = "Create a new property",
            description = "Permitted for approved dealers and administrators. Ownership is assigned server-side.")
    public ResponseEntity<ApiResponse<PropertyDetailsDto>> createProperty(
            @Valid @RequestBody CreatePropertyRequest request) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        PropertyDetailsDto created = propertyService.createProperty(principal, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Property created successfully"));
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Update permitted property fields",
            description = "Permitted for property owners and administrators. Protected fields cannot be overridden.")
    public ResponseEntity<ApiResponse<PropertyDetailsDto>> updateProperty(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePropertyRequest request) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        PropertyDetailsDto updated = propertyService.updateProperty(id, principal, request);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Property updated successfully"));
    }
}
