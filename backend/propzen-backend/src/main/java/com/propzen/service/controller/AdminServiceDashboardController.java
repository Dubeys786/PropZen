package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.AdminServiceDashboardDto;
import com.propzen.service.service.AdminServiceDashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Admin - Services Dashboard", description = "Live administrative service ecosystem performance and revenue KPIs")
@RestController
@RequestMapping("/api/v1/admin/services")
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class AdminServiceDashboardController {

    private final AdminServiceDashboardService dashboardService;
    private final CurrentUserService currentUserService;

    public AdminServiceDashboardController(AdminServiceDashboardService dashboardService,
                                          CurrentUserService currentUserService) {
        this.dashboardService = dashboardService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Get platform-wide live database-calculated service ecosystem dashboard KPIs")
    @GetMapping("/dashboard")
    public ResponseEntity<ApiResponse<AdminServiceDashboardDto>> getDashboard() {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        AdminServiceDashboardDto dto = dashboardService.getDashboard(adminUser);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }
}
