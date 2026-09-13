package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
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

@Tag(name = "Service Partners - Feedback", description = "Partner customer feedback and rating review APIs")
@RestController
@RequestMapping("/api/v1/partner/feedback")
@PreAuthorize("hasAnyRole('SERVICE_PARTNER', 'ADMIN')")
@SecurityRequirement(name = "BearerAuth")
public class PartnerFeedbackController {

    private final ServiceFeedbackService feedbackService;
    private final CurrentUserService currentUserService;

    public PartnerFeedbackController(ServiceFeedbackService feedbackService,
                                   CurrentUserService currentUserService) {
        this.feedbackService = feedbackService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Get feedback reviews received by the authenticated partner")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ServiceFeedbackDto>>> getFeedback(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        AuthenticatedUser partner = currentUserService.getRequiredCurrentUser();
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)), Sort.by(Sort.Direction.DESC, "createdAt"));
        PageResponse<ServiceFeedbackDto> result = feedbackService.getFeedbackForPartner(partner, pageable);
        return ResponseEntity.ok(ApiResponse.ok(result));
    }
}
