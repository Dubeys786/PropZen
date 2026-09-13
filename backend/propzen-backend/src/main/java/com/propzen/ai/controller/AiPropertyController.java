package com.propzen.ai.controller;

import com.propzen.ai.dto.PropertyDescriptionDto;
import com.propzen.ai.dto.PropertyDescriptionRequest;
import com.propzen.ai.dto.PropertyRecommendationDto;
import com.propzen.ai.dto.PropertyRecommendationRequest;
import com.propzen.ai.service.PropertyDescriptionService;
import com.propzen.ai.service.PropertyRecommendationService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ai/properties")
@Tag(name = "AI Property Intelligence", description = "Endpoints for AI-driven property recommendations and listing description generation")
public class AiPropertyController {

    private final PropertyRecommendationService recommendationService;
    private final PropertyDescriptionService descriptionService;
    private final CurrentUserService currentUserService;

    public AiPropertyController(PropertyRecommendationService recommendationService,
                                PropertyDescriptionService descriptionService,
                                CurrentUserService currentUserService) {
        this.recommendationService = recommendationService;
        this.descriptionService = descriptionService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/recommendations")
    @Operation(summary = "Get AI-ranked property recommendations matching buyer criteria",
            description = "Scores live database properties by budget, location, BHK, and relevance")
    public ResponseEntity<ApiResponse<List<PropertyRecommendationDto>>> getRecommendations(
            @RequestBody(required = false) PropertyRecommendationRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        PropertyRecommendationRequest criteria = request != null ? request : new PropertyRecommendationRequest();
        List<PropertyRecommendationDto> recommendations = recommendationService.getRecommendations(criteria, actor);
        return ResponseEntity.ok(ApiResponse.ok(recommendations, "Property recommendations generated successfully"));
    }

    @PostMapping("/generate-description")
    @Operation(summary = "Generate professional property descriptions and SEO metadata",
            description = "Creates high-converting property overview, key highlights, and SEO tags based on verified specs")
    public ResponseEntity<ApiResponse<PropertyDescriptionDto>> generateDescription(
            @Valid @RequestBody PropertyDescriptionRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        PropertyDescriptionDto description = descriptionService.generateDescription(request, actor);
        return ResponseEntity.ok(ApiResponse.ok(description, "Property description generated successfully"));
    }
}
