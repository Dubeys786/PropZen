package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreatePaymentRequest;
import com.propzen.service.dto.PaymentWebhookPayload;
import com.propzen.service.dto.ServicePaymentDto;
import com.propzen.service.payment.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Tag(name = "Services - Payments", description = "Service payment ledger and provider webhook APIs")
@RestController
@RequestMapping("/api/v1/services")
public class ServicePaymentController {

    private final PaymentService paymentService;
    private final CurrentUserService currentUserService;

    public ServicePaymentController(PaymentService paymentService,
                                    CurrentUserService currentUserService) {
        this.paymentService = paymentService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Initiate a service payment order")
    @PostMapping("/payments/create")
    @SecurityRequirement(name = "BearerAuth")
    public ResponseEntity<ApiResponse<ServicePaymentDto>> createPayment(@Valid @RequestBody CreatePaymentRequest request) {
        AuthenticatedUser customer = currentUserService.getRequiredCurrentUser();
        ServicePaymentDto payment = paymentService.createPayment(request, customer);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(payment, "Payment order created successfully"));
    }

    @Operation(summary = "Get payment details by ID")
    @GetMapping("/payments/{id}")
    @SecurityRequirement(name = "BearerAuth")
    public ResponseEntity<ApiResponse<ServicePaymentDto>> getPaymentById(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServicePaymentDto payment = paymentService.getPaymentById(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(payment));
    }

    @Operation(summary = "Get all payments for a service request")
    @GetMapping("/requests/{id}/payments")
    @SecurityRequirement(name = "BearerAuth")
    public ResponseEntity<ApiResponse<List<ServicePaymentDto>>> getPaymentsForRequest(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<ServicePaymentDto> payments = paymentService.getPaymentsForRequest(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(payments));
    }

    @Operation(summary = "Payment provider callback webhook (validates signature)")
    @PostMapping("/payments/webhook")
    public ResponseEntity<ApiResponse<Boolean>> handleWebhook(
            @RequestHeader(value = "X-Razorpay-Signature", required = false) String razorpaySignature,
            @RequestBody PaymentWebhookPayload payload) {
        if (razorpaySignature != null && !razorpaySignature.isBlank() &&
                (payload.getSignature() == null || payload.getSignature().isBlank())) {
            payload.setSignature(razorpaySignature);
        }
        if (payload.getSignature() == null || payload.getSignature().isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("BAD_REQUEST", "Missing payment webhook signature"));
        }
        boolean processed = paymentService.processWebhook(payload);
        if (!processed) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.error("BAD_REQUEST", "Webhook signature verification failed or payment order not found"));
        }
        return ResponseEntity.ok(ApiResponse.ok(true, "Webhook processed successfully"));
    }
}
