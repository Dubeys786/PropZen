package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreateServiceCategoryRequest;
import com.propzen.service.dto.ServiceCategoryDto;
import com.propzen.service.dto.UpdateServiceCategoryRequest;
import com.propzen.service.service.ServiceCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Tag(name = "Admin - Service Categories", description = "Administrative service category configuration APIs")
@RestController
@RequestMapping("/api/v1/admin/services/categories")
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class AdminServiceCategoryController {

    private final ServiceCategoryService categoryService;
    private final CurrentUserService currentUserService;

    public AdminServiceCategoryController(ServiceCategoryService categoryService,
                                          CurrentUserService currentUserService) {
        this.categoryService = categoryService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Create a new service category")
    @PostMapping
    public ResponseEntity<ApiResponse<ServiceCategoryDto>> createCategory(@Valid @RequestBody CreateServiceCategoryRequest request) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        ServiceCategoryDto created = categoryService.createCategory(request, adminUser);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created, "Category created successfully"));
    }

    @Operation(summary = "Update an existing service category")
    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceCategoryDto>> updateCategory(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateServiceCategoryRequest request) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        ServiceCategoryDto updated = categoryService.updateCategory(id, request, adminUser);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }

    @Operation(summary = "Delete a service category")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteCategory(@PathVariable UUID id) {
        AuthenticatedUser adminUser = currentUserService.getRequiredCurrentUser();
        categoryService.deleteCategory(id, adminUser);
        return ResponseEntity.ok(ApiResponse.ok(null, "Category deleted successfully"));
    }
}
