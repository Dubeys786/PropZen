package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CrmDashboardDto;
import com.propzen.crm.service.CrmDashboardService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/crm/dashboard")
@Tag(name = "CRM Dashboard & Analytics", description = "Endpoints for live database-calculated CRM pipeline KPIs")
public class CrmDashboardController {

    private final CrmDashboardService dashboardService;
    private final CurrentUserService currentUserService;

    public CrmDashboardController(CrmDashboardService dashboardService, CurrentUserService currentUserService) {
        this.dashboardService = dashboardService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "Get CRM pipeline KPIs and conversion metrics",
            description = "Calculates totalLeads, newLeads, followUpsDue, siteVisits, conversionRate from live database records")
    public ResponseEntity<ApiResponse<CrmDashboardDto>> getDashboard() {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        CrmDashboardDto metrics = dashboardService.getDashboard(actor);
        return ResponseEntity.ok(ApiResponse.ok(metrics, "Dashboard metrics retrieved successfully"));
    }
}
