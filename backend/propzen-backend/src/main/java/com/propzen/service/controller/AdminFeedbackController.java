package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.service.dto.ServiceFeedbackDto;
import com.propzen.service.service.ServiceFeedbackService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "Admin - Feedback", description = "Administrative service feedback review and moderation APIs")
@RestController
@RequestMapping("/api/v1/admin/feedback")
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class AdminFeedbackController {

    private final ServiceFeedbackService feedbackService;

    public AdminFeedbackController(ServiceFeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @Operation(summary = "List all customer feedback across all service partners")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ServiceFeedbackDto>>> getAllFeedback(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ServiceFeedbackDto> result = feedbackService.getAllFeedback(pageable);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }
}
