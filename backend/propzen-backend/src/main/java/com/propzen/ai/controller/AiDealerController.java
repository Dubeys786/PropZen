package com.propzen.ai.controller;

import com.propzen.ai.dto.DealerAiInsightsDto;
import com.propzen.ai.service.DealerAiInsightsService;
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
@RequestMapping("/api/v1/dealer/ai")
@PreAuthorize("hasAnyRole('DEALER', 'ADMIN')")
@Tag(name = "Dealer AI Intelligence", description = "Dealer-focused AI insights for lead conversion, pipeline recommendations, and performance")
public class AiDealerController {

    private final DealerAiInsightsService dealerAiInsightsService;
    private final CurrentUserService currentUserService;

    public AiDealerController(DealerAiInsightsService dealerAiInsightsService,
                              CurrentUserService currentUserService) {
        this.dealerAiInsightsService = dealerAiInsightsService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/insights")
    @Operation(summary = "Get personalized AI performance insights for dealer",
            description = "Calculates conversion rate, identifies stalled leads, and gives actionable recommendations. Tenant-isolated to current dealer.")
    public ResponseEntity<ApiResponse<DealerAiInsightsDto>> getDealerInsights(
            @RequestParam(required = false) UUID dealerId) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        DealerAiInsightsDto dto = dealerAiInsightsService.getDealerInsights(dealerId, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Dealer AI insights retrieved successfully"));
    }
}
