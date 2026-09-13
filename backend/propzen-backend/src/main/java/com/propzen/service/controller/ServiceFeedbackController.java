package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.CreateFeedbackRequest;
import com.propzen.service.dto.ServiceFeedbackDto;
import com.propzen.service.service.ServiceFeedbackService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Tag(name = "Services - Feedback", description = "Customer service feedback and rating submission APIs")
@RestController
@RequestMapping({"/api/v1/services", "/api/v1"})
@SecurityRequirement(name = "BearerAuth")
public class ServiceFeedbackController {

    private final ServiceFeedbackService feedbackService;
    private final CurrentUserService currentUserService;

    public ServiceFeedbackController(ServiceFeedbackService feedbackService,
                                     CurrentUserService currentUserService) {
        this.feedbackService = feedbackService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Submit feedback and 1-5 rating for a completed service")
    @PostMapping({"/requests/{id}/feedback", "/service-requests/{id}/feedback"})
    public ResponseEntity<ApiResponse<ServiceFeedbackDto>> submitFeedback(
            @PathVariable UUID id,
            @Valid @RequestBody CreateFeedbackRequest request
    ) {
        AuthenticatedUser customer = currentUserService.getRequiredCurrentUser();
        ServiceFeedbackDto feedback = feedbackService.submitFeedback(id, request, customer);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(feedback, "Feedback submitted successfully"));
    }

    @Operation(summary = "Get feedback for a specific service request")
    @GetMapping({"/requests/{id}/feedback", "/service-requests/{id}/feedback"})
    public ResponseEntity<ApiResponse<ServiceFeedbackDto>> getFeedback(@PathVariable UUID id) {
        ServiceFeedbackDto feedback = feedbackService.getFeedbackForRequest(id);
        return ResponseEntity.ok(ApiResponse.ok(feedback));
    }
}
