package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.AdminDashboardSummaryDto;
import com.propzen.crm.service.AdminDashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/dashboard")
@Tag(name = "Admin Command Center", description = "Authoritative real-time administrative dashboard metrics calculated from database")
@SecurityRequirement(name = "BearerAuth")
@PreAuthorize("hasRole('ADMIN')")
public class AdminDashboardController {

    private final AdminDashboardService dashboardService;

    public AdminDashboardController(AdminDashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping("/summary")
    @Operation(summary = "Get platform-wide executive command center summary metrics (Admin only)")
    public ResponseEntity<ApiResponse<AdminDashboardSummaryDto>> getSummary() {
        AdminDashboardSummaryDto summary = dashboardService.getSummary();
        return ResponseEntity.ok(ApiResponse.ok(summary, "Admin summary retrieved"));
    }

    @GetMapping("/leads")
    @Operation(summary = "Get real-time CRM lead funnel and conversion metrics (Admin only)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getLeadsMetrics() {
        Map<String, Object> metrics = dashboardService.getLeadsMetrics();
        return ResponseEntity.ok(ApiResponse.ok(metrics, "Lead metrics retrieved"));
    }

    @GetMapping("/revenue")
    @Operation(summary = "Get platform settled revenue and pending collections (Admin only)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getRevenueMetrics() {
        Map<String, Object> metrics = dashboardService.getRevenueMetrics();
        return ResponseEntity.ok(ApiResponse.ok(metrics, "Revenue metrics retrieved"));
    }

    @GetMapping("/services")
    @Operation(summary = "Get platform service request fulfillment statistics (Admin only)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getServicesMetrics() {
        Map<String, Object> metrics = dashboardService.getServicesMetrics();
        return ResponseEntity.ok(ApiResponse.ok(metrics, "Services metrics retrieved"));
    }

    @GetMapping("/properties")
    @Operation(summary = "Get inventory and listing review distribution metrics (Admin only)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getPropertiesMetrics() {
        Map<String, Object> metrics = dashboardService.getPropertiesMetrics();
        return ResponseEntity.ok(ApiResponse.ok(metrics, "Property metrics retrieved"));
    }
}
