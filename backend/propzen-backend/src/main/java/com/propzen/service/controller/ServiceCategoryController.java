package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.service.dto.ServiceCategoryDto;
import com.propzen.service.service.ServiceCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Tag(name = "Services - Categories", description = "Service category discovery APIs")
@RestController
@RequestMapping("/api/v1/services/categories")
public class ServiceCategoryController {

    private final ServiceCategoryService categoryService;

    public ServiceCategoryController(ServiceCategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @Operation(summary = "List all active service categories")
    @GetMapping
    public ResponseEntity<ApiResponse<List<ServiceCategoryDto>>> getCategories() {
        List<ServiceCategoryDto> categories = categoryService.getActiveCategories();
        return ResponseEntity.ok(ApiResponse.ok(categories));
    }

    @Operation(summary = "Get service category by ID")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceCategoryDto>> getCategoryById(@PathVariable UUID id) {
        ServiceCategoryDto category = categoryService.getCategoryById(id);
        return ResponseEntity.ok(ApiResponse.ok(category));
    }
}
