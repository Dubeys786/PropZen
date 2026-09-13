package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.Customer360Dto;
import com.propzen.crm.service.Customer360Service;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/crm/customers")
@Tag(name = "Customer 360", description = "Unified customer lifecycle aggregator across leads, visits, requests, communications, and notes")
public class Customer360Controller {

    private final Customer360Service customer360Service;
    private final CurrentUserService currentUserService;

    public Customer360Controller(Customer360Service customer360Service, CurrentUserService currentUserService) {
        this.customer360Service = customer360Service;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/{id}/360")
    @Operation(summary = "Get Customer 360 journey view")
    public ResponseEntity<ApiResponse<Customer360Dto>> getCustomer360(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Customer360Dto dto = customer360Service.getCustomer360(id);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Customer 360 view retrieved successfully"));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Alias for Customer 360 journey view")
    public ResponseEntity<ApiResponse<Customer360Dto>> getCustomer(@PathVariable UUID id) {
        return getCustomer360(id);
    }
}
