package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CampaignDto;
import com.propzen.crm.dto.CreateCampaignRequest;
import com.propzen.crm.service.CampaignService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/crm/campaigns")
@Tag(name = "CRM Campaigns", description = "Endpoints for creating and executing bulk WhatsApp/Email campaigns")
public class CampaignController {

    private final CampaignService campaignService;
    private final CurrentUserService currentUserService;

    public CampaignController(CampaignService campaignService, CurrentUserService currentUserService) {
        this.campaignService = campaignService;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    @Operation(summary = "Create a new bulk campaign (Admin only)")
    public ResponseEntity<ApiResponse<CampaignDto>> createCampaign(
            @Valid @RequestBody CreateCampaignRequest request) {
        AuthenticatedUser admin = currentUserService.getRequiredCurrentUser();
        CampaignDto campaign = campaignService.createCampaign(request, admin);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(campaign, "Campaign created successfully"));
    }

    @org.springframework.web.bind.annotation.GetMapping
    @Operation(summary = "List all marketing campaigns (Admin only)")
    public ResponseEntity<ApiResponse<java.util.List<CampaignDto>>> getCampaigns() {
        AuthenticatedUser admin = currentUserService.getRequiredCurrentUser();
        java.util.List<CampaignDto> list = campaignService.getAllCampaigns(admin);
        return ResponseEntity.ok(ApiResponse.ok(list, "Campaigns retrieved successfully"));
    }

    @org.springframework.web.bind.annotation.GetMapping("/{id}")
    @Operation(summary = "Get campaign details and delivery statistics by ID (Admin only)")
    public ResponseEntity<ApiResponse<CampaignDto>> getCampaign(@PathVariable UUID id) {
        AuthenticatedUser admin = currentUserService.getRequiredCurrentUser();
        CampaignDto campaign = campaignService.getCampaign(id, admin);
        return ResponseEntity.ok(ApiResponse.ok(campaign, "Campaign retrieved successfully"));
    }

    @PostMapping("/{id}/send")
    @Operation(summary = "Execute bulk campaign dispatch (Admin only)")
    public ResponseEntity<ApiResponse<CampaignDto>> sendCampaign(
            @PathVariable UUID id,
            @RequestParam(value = "async", defaultValue = "false") boolean async) {
        AuthenticatedUser admin = currentUserService.getRequiredCurrentUser();
        CampaignDto campaign = campaignService.sendCampaign(id, admin, async);
        return ResponseEntity.ok(ApiResponse.ok(campaign, "Campaign executed successfully"));
    }
}
