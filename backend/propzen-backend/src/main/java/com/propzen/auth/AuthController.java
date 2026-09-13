package com.propzen.auth;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Authentication and identity verification REST endpoints.
 */
@RestController
@Tag(name = "Authentication & Identity", description = "Endpoints for verifying identity and checking roles")
public class AuthController {

    private final CurrentUserService currentUserService;

    @Autowired
    public AuthController(CurrentUserService currentUserService) {
        this.currentUserService = currentUserService;
    }

    @GetMapping("/api/v1/auth/me")
    @Operation(summary = "Get current user profile",
            description = "Returns authoritative identity derived from validated Supabase JWT.",
            security = @SecurityRequirement(name = "bearerAuth"))
    public ResponseEntity<ApiResponse<AuthUserResponse>> getCurrentUser() {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();

        List<String> roleNames = user.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .sorted()
                .toList();

        AuthUserResponse response = new AuthUserResponse(
                true,
                user.getId(),
                user.getEmail(),
                user.getPhone(),
                roleNames
        );

        return ResponseEntity.ok(ApiResponse.success(response, "Authenticated user context retrieved successfully"));
    }

    @GetMapping("/api/v1/admin/test-probe")
    @Operation(summary = "Admin role security probe",
            description = "Verifies caller has ROLE_ADMIN authority.",
            security = @SecurityRequirement(name = "bearerAuth"))
    public ResponseEntity<ApiResponse<String>> adminTestProbe() {
        return ResponseEntity.ok(ApiResponse.success("Admin role access verified"));
    }

    @GetMapping("/api/v1/dealers/test-probe")
    @Operation(summary = "Dealer role security probe",
            description = "Verifies caller has ROLE_DEALER authority.",
            security = @SecurityRequirement(name = "bearerAuth"))
    public ResponseEntity<ApiResponse<String>> dealerTestProbe() {
        return ResponseEntity.ok(ApiResponse.success("Dealer role access verified"));
    }
}
