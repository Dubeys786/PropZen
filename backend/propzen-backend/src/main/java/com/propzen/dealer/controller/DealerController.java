package com.propzen.dealer.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.dealer.dto.DealerApplicationRequest;
import com.propzen.dealer.dto.DealerProfileDto;
import com.propzen.dealer.dto.UpdateDealerProfileRequest;
import com.propzen.dealer.service.DealerService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/dealers")
@Tag(name = "Dealer Management", description = "Endpoints for dealer registration, profile access, and updates")
public class DealerController {

    private final DealerService dealerService;
    private final CurrentUserService currentUserService;

    public DealerController(DealerService dealerService, CurrentUserService currentUserService) {
        this.dealerService = dealerService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/apply")
    @Operation(summary = "Submit a new dealer application")
    public ResponseEntity<ApiResponse<DealerProfileDto>> applyAsDealer(
            @Valid @RequestBody DealerApplicationRequest request) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        DealerProfileDto profile = dealerService.applyAsDealer(principal, request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(profile, "Dealer application submitted successfully"));
    }

    @GetMapping("/me")
    @Operation(summary = "Retrieve current user's dealer profile")
    public ResponseEntity<ApiResponse<DealerProfileDto>> getMyDealerProfile() {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        DealerProfileDto profile = dealerService.getMyDealerProfile(principal);
        return ResponseEntity.ok(ApiResponse.ok(profile, "Dealer profile retrieved successfully"));
    }

    @PatchMapping("/me")
    @Operation(summary = "Update current dealer's business details")
    public ResponseEntity<ApiResponse<DealerProfileDto>> updateMyDealerProfile(
            @Valid @RequestBody UpdateDealerProfileRequest request) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        DealerProfileDto updated = dealerService.updateMyDealerProfile(principal, request);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Dealer profile updated successfully"));
    }
}
