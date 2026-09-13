package com.propzen.ai.controller;

import com.propzen.ai.dto.ServicePartnerAiInsightsDto;
import com.propzen.ai.service.ServicePartnerAiInsightsService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/partner/ai")
@PreAuthorize("hasAnyRole('SERVICE_PARTNER', 'ADMIN')")
@Tag(name = "Service Partner AI Intelligence", description = "Service Partner AI insights for service job completion, performance, and workload optimization")
public class AiPartnerController {

    private final ServicePartnerAiInsightsService partnerAiInsightsService;
    private final CurrentUserService currentUserService;

    public AiPartnerController(ServicePartnerAiInsightsService partnerAiInsightsService,
                               CurrentUserService currentUserService) {
        this.partnerAiInsightsService = partnerAiInsightsService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/insights")
    @Operation(summary = "Get AI job performance and workload insights for service partner",
            description = "Calculates completion velocity, on-time rate, and actionable operational guidance. Tenant-isolated.")
    public ResponseEntity<ApiResponse<ServicePartnerAiInsightsDto>> getPartnerInsights(
            @RequestParam(required = false) UUID partnerId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServicePartnerAiInsightsDto dto = partnerAiInsightsService.getPartnerInsights(partnerId, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Service Partner AI insights retrieved successfully"));
    }
}
