package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CommunicationPreferenceDto;
import com.propzen.crm.service.CommunicationPreferenceService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users/me/communication-preferences")
@Tag(name = "Communication Preferences", description = "Endpoints for managing user consent and marketing opt-out")
public class CommunicationPreferenceController {

    private final CommunicationPreferenceService preferenceService;
    private final CurrentUserService currentUserService;

    public CommunicationPreferenceController(CommunicationPreferenceService preferenceService,
                                             CurrentUserService currentUserService) {
        this.preferenceService = preferenceService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "Get current user's communication preferences")
    public ResponseEntity<ApiResponse<CommunicationPreferenceDto>> getPreferences() {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        CommunicationPreferenceDto dto = preferenceService.getPreferences(user.getPhone(), user);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Preferences retrieved successfully"));
    }

    @PostMapping
    @Operation(summary = "Update communication preferences and consent")
    public ResponseEntity<ApiResponse<CommunicationPreferenceDto>> updatePreferences(
            @RequestBody CommunicationPreferenceDto request) {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        CommunicationPreferenceDto updated = preferenceService.updatePreferences(request, user);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Preferences updated successfully"));
    }
}
