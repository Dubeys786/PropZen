package com.propzen.ai.controller;

import com.propzen.ai.dto.MarketIntelligenceDto;
import com.propzen.ai.service.MarketIntelligenceService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/ai/market")
@Tag(name = "AI Market Intelligence", description = "Endpoints for AI-driven real estate market trends, price guidance, and sector analytics")
public class AiMarketController {

    private final MarketIntelligenceService marketIntelligenceService;
    private final CurrentUserService currentUserService;

    public AiMarketController(MarketIntelligenceService marketIntelligenceService,
                              CurrentUserService currentUserService) {
        this.marketIntelligenceService = marketIntelligenceService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/trends")
    @Operation(summary = "Get AI market intelligence and sector trends",
            description = "Analyzes active inventory, demand patterns, and price benchmarks for a given city and sector")
    public ResponseEntity<ApiResponse<MarketIntelligenceDto>> getMarketTrends(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) String sector) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        MarketIntelligenceDto dto = marketIntelligenceService.getMarketTrends(city, sector, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Market intelligence retrieved successfully"));
    }
}
