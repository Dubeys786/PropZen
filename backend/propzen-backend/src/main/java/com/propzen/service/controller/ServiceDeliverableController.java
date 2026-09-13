package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreateDeliverableRequest;
import com.propzen.service.dto.ServiceDeliverableDto;
import com.propzen.service.service.ServiceDeliverableService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@Tag(name = "Services - Deliverables", description = "Service deliverables submission and retrieval APIs")
@RestController
@RequestMapping({"/api/v1/service-requests", "/api/v1/services/requests"})
@SecurityRequirement(name = "BearerAuth")
public class ServiceDeliverableController {

    private final ServiceDeliverableService deliverableService;
    private final CurrentUserService currentUserService;

    public ServiceDeliverableController(ServiceDeliverableService deliverableService, CurrentUserService currentUserService) {
        this.deliverableService = deliverableService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/{id}/deliverables")
    @Operation(summary = "Submit a deliverable for a service request")
    public ResponseEntity<ApiResponse<ServiceDeliverableDto>> addDeliverable(
            @PathVariable UUID id,
            @Valid @RequestBody CreateDeliverableRequest request
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServiceDeliverableDto created = deliverableService.addDeliverable(id, request, actor);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created, "Deliverable submitted successfully"));
    }

    @GetMapping("/{id}/deliverables")
    @Operation(summary = "Get all deliverables for a service request")
    public ResponseEntity<ApiResponse<List<ServiceDeliverableDto>>> getDeliverables(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<ServiceDeliverableDto> deliverables = deliverableService.getDeliverables(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(deliverables));
    }
}
