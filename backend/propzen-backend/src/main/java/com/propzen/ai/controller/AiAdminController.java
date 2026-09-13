package com.propzen.ai.controller;

import com.propzen.ai.dto.AdminAiInsightsDto;
import com.propzen.ai.dto.AiUsageMetricsDto;
import com.propzen.ai.service.AdminAiInsightsService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/ai")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Admin AI Intelligence & Telemetry", description = "Admin-only operations for platform AI insights, model usage, latency, and cost telemetry")
public class AiAdminController {

    private final AdminAiInsightsService adminAiInsightsService;
    private final CurrentUserService currentUserService;

    public AiAdminController(AdminAiInsightsService adminAiInsightsService,
                             CurrentUserService currentUserService) {
        this.adminAiInsightsService = adminAiInsightsService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/insights")
    @Operation(summary = "Get executive platform AI insights",
            description = "Aggregates cross-platform health metrics, pipeline velocity, and conversion blockers")
    public ResponseEntity<ApiResponse<AdminAiInsightsDto>> getAdminInsights() {
        AuthenticatedUser admin = currentUserService.getRequiredCurrentUser();
        AdminAiInsightsDto dto = adminAiInsightsService.getAdminInsights(admin);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Admin AI insights retrieved successfully"));
    }

    @GetMapping("/usage")
    @Operation(summary = "Get AI token usage, latency, and cost telemetry",
            description = "Real-time auditing of total requests, cache hit rates, fallback frequency, and latency")
    public ResponseEntity<ApiResponse<AiUsageMetricsDto>> getAiUsageMetrics() {
        AiUsageMetricsDto metrics = adminAiInsightsService.getUsageMetrics();
        return ResponseEntity.ok(ApiResponse.ok(metrics, "AI usage metrics retrieved successfully"));
    }
}
