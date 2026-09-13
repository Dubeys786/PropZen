package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CreateSiteVisitRequest;
import com.propzen.crm.dto.SiteVisitDto;
import com.propzen.crm.service.SiteVisitService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/site-visits")
@Tag(name = "Site Visit Management", description = "Endpoints for scheduling and managing real-estate property site visits")
public class SiteVisitController {

    private final SiteVisitService siteVisitService;
    private final CurrentUserService currentUserService;

    public SiteVisitController(SiteVisitService siteVisitService, CurrentUserService currentUserService) {
        this.siteVisitService = siteVisitService;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    @Operation(summary = "Book a property site visit",
            description = "Schedules a physical or virtual site visit for an interested buyer")
    public ResponseEntity<ApiResponse<SiteVisitDto>> bookSiteVisit(
            @Valid @RequestBody CreateSiteVisitRequest request) {
        AuthenticatedUser principal = currentUserService.getCurrentUser().orElse(null);
        SiteVisitDto dto = siteVisitService.bookSiteVisit(request, principal);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(dto, "Site visit booked successfully"));
    }

    @GetMapping("/me")
    @Operation(summary = "Get current user's site visits",
            description = "Returns site visit bookings for the authenticated user")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<SiteVisitDto>>> getMySiteVisits() {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        List<SiteVisitDto> visits = siteVisitService.getMySiteVisits(principal);
        return ResponseEntity.ok(ApiResponse.ok(visits, "Site visits retrieved successfully"));
    }

    @GetMapping("/dealer/me")
    @Operation(summary = "Get dealer's scheduled site visits",
            description = "Returns site visits assigned to the authenticated dealer")
    @PreAuthorize("hasAnyRole('DEALER', 'ADMIN')")
    public ResponseEntity<ApiResponse<List<SiteVisitDto>>> getDealerSiteVisits() {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        List<SiteVisitDto> visits = siteVisitService.getDealerSiteVisits(principal.getUserId());
        return ResponseEntity.ok(ApiResponse.ok(visits, "Dealer site visits retrieved successfully"));
    }

    @GetMapping("/property/{propertyId}")
    @Operation(summary = "Get site visits for property",
            description = "Returns scheduled site visits for a specific property")
    @PreAuthorize("hasAnyRole('DEALER', 'ADMIN')")
    public ResponseEntity<ApiResponse<List<SiteVisitDto>>> getSiteVisitsForProperty(@PathVariable String propertyId) {
        List<SiteVisitDto> visits = siteVisitService.getSiteVisitsForProperty(propertyId);
        return ResponseEntity.ok(ApiResponse.ok(visits, "Property site visits retrieved successfully"));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update site visit status",
            description = "Updates status of a site visit (e.g. Confirmed, Completed, Cancelled)")
    @PreAuthorize("hasAnyRole('DEALER', 'ADMIN')")
    public ResponseEntity<ApiResponse<SiteVisitDto>> updateStatus(
            @PathVariable UUID id,
            @RequestParam String status) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        SiteVisitDto dto = siteVisitService.updateStatus(id, status, principal);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Site visit status updated successfully"));
    }
}
