package com.propzen.user.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.user.dto.UpdateUserProfileRequest;
import com.propzen.user.dto.UserDto;
import com.propzen.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "User Management", description = "Endpoints for managing authenticated user profiles")
public class UserController {

    private final UserService userService;
    private final CurrentUserService currentUserService;

    public UserController(UserService userService, CurrentUserService currentUserService) {
        this.userService = userService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/me")
    @Operation(summary = "Get current authenticated user profile")
    public ResponseEntity<ApiResponse<UserDto>> getCurrentUser() {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        UserDto profile = userService.getCurrentUserProfile(principal);
        return ResponseEntity.ok(ApiResponse.ok(profile, "User profile retrieved successfully"));
    }

    @PatchMapping("/me")
    @Operation(summary = "Update current authenticated user profile (full name, phone)")
    public ResponseEntity<ApiResponse<UserDto>> updateCurrentUser(
            @Valid @RequestBody UpdateUserProfileRequest request) {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        UserDto updated = userService.updateCurrentUserProfile(principal, request);
        return ResponseEntity.ok(ApiResponse.ok(updated, "User profile updated successfully"));
    }
}
