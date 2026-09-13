package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.ApplyServicePartnerRequest;
import com.propzen.service.dto.ServicePartnerProfileDto;
import com.propzen.service.dto.UpdateServicePartnerRequest;
import com.propzen.service.service.ServicePartnerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Service Partners - Profile", description = "Service partner application and own profile management")
@RestController
@RequestMapping("/api/v1/service-partners")
@SecurityRequirement(name = "BearerAuth")
public class ServicePartnerController {

    private final ServicePartnerService partnerService;
    private final CurrentUserService currentUserService;

    public ServicePartnerController(ServicePartnerService partnerService,
                                   CurrentUserService currentUserService) {
        this.partnerService = partnerService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Apply to become a service partner")
    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<ServicePartnerProfileDto>> apply(@Valid @RequestBody ApplyServicePartnerRequest request) {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        ServicePartnerProfileDto dto = partnerService.apply(request, user);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(dto, "Partner application submitted successfully"));
    }

    @Operation(summary = "Get current authenticated service partner profile")
    @GetMapping("/me")
    public ResponseEntity<ApiResponse<ServicePartnerProfileDto>> getMyProfile() {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        ServicePartnerProfileDto dto = partnerService.getMyProfile(user);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }

    @Operation(summary = "Update current authenticated service partner contact details")
    @PatchMapping("/me")
    public ResponseEntity<ApiResponse<ServicePartnerProfileDto>> updateMyProfile(@Valid @RequestBody UpdateServicePartnerRequest request) {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        ServicePartnerProfileDto dto = partnerService.updateMyProfile(request, user);
        return ResponseEntity.ok(ApiResponse.ok(dto));
    }
}
