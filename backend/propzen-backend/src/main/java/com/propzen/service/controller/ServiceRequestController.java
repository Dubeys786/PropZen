package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreateServiceRequestDto;
import com.propzen.service.dto.ServicePaymentDto;
import com.propzen.service.dto.ServiceRequestDetailDto;
import com.propzen.service.dto.ServiceRequestDto;
import com.propzen.service.payment.PaymentService;
import com.propzen.service.service.ServiceRequestService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Tag(name = "Services - Requests", description = "Customer service request submission and lifecycle APIs")
@RestController
@RequestMapping({"/api/v1/services/requests", "/api/v1/service-requests"})
@SecurityRequirement(name = "BearerAuth")
public class ServiceRequestController {

    private final ServiceRequestService requestService;
    private final PaymentService paymentService;
    private final CurrentUserService currentUserService;

    public ServiceRequestController(ServiceRequestService requestService,
                                    PaymentService paymentService,
                                    CurrentUserService currentUserService) {
        this.requestService = requestService;
        this.paymentService = paymentService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Submit a new service request")
    @PostMapping
    public ResponseEntity<ApiResponse<ServiceRequestDto>> createRequest(@Valid @RequestBody CreateServiceRequestDto requestDto) {
        AuthenticatedUser customer = currentUserService.getRequiredCurrentUser();
        ServiceRequestDto created = requestService.createRequest(requestDto, customer);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(created, "Service request submitted successfully"));
    }

    @Operation(summary = "Get current authenticated customer's own service requests")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ServiceRequestDto>>> getRequests(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return getMyRequests(page, size);
    }

    @Operation(summary = "Get service request details by ID")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceRequestDetailDto>> getRequestDetails(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServiceRequestDetailDto detail = requestService.getRequestDetails(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(detail));
    }

    @Operation(summary = "Get current authenticated customer's own service requests")
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<PageResponse<ServiceRequestDto>>> getMyRequests(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        AuthenticatedUser customer = currentUserService.getRequiredCurrentUser();
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ServiceRequestDto> result = requestService.getMyRequests(customer, pageable);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @Operation(summary = "Update or cancel a service request")
    @PatchMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> updateRequest(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body
    ) {
        return cancelRequest(id, body);
    }

    @Operation(summary = "Cancel a service request")
    @PatchMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<ServiceRequestDto>> cancelRequest(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body
    ) {
        AuthenticatedUser customer = currentUserService.getRequiredCurrentUser();
        String reason = body != null ? body.get("reason") : null;
        ServiceRequestDto cancelled = requestService.cancelRequest(id, reason, customer);
        return ResponseEntity.ok(ApiResponse.ok(cancelled, "Service request cancelled"));
    }

    @Operation(summary = "Get payments for a service request")
    @GetMapping("/{id}/payments")
    public ResponseEntity<ApiResponse<List<ServicePaymentDto>>> getPayments(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<ServicePaymentDto> payments = paymentService.getPaymentsForRequest(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(payments, "Payments retrieved"));
    }
}
