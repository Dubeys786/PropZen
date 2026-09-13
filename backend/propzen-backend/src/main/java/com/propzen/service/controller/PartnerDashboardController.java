package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.PartnerDashboardDto;
import com.propzen.service.service.PartnerDashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Service Partners - Dashboard", description = "Live database-calculated partner dashboard KPIs and metrics APIs")
@RestController
@RequestMapping("/api/v1/partner")
@PreAuthorize("hasAnyRole('SERVICE_PARTNER', 'ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class PartnerDashboardController {

    private final PartnerDashboardService dashboardService;
    private final CurrentUserService currentUserService;

    public PartnerDashboardController(PartnerDashboardService dashboardService,
                                     CurrentUserService currentUserService) {
        this.dashboardService = dashboardService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Get live database-calculated dashboard metrics for the authenticated partner")
    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<PartnerDashboardDto>> getDashboard() {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        PartnerDashboardDto dto = dashboardService.getDashboard(partner);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }
}
