package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CrmAnalyticsDto;
import com.propzen.crm.service.CrmAnalyticsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/crm/analytics")
@Tag(name = "CRM Analytics", description = "Performance metrics, funnel conversion, and communication analytics")
public class CrmAnalyticsController {

    private final CrmAnalyticsService analyticsService;

    public CrmAnalyticsController(CrmAnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping
    @Operation(summary = "Retrieve CRM analytics, funnel conversion, and activity performance")
    public ResponseEntity<ApiResponse<CrmAnalyticsDto>> getAnalytics() {
        CrmAnalyticsDto dto = analyticsService.getAnalytics();
        return ResponseEntity.ok(ApiResponse.ok(dto, "CRM analytics retrieved successfully"));
    }
}
