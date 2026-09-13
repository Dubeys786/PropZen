package com.propzen.ai.controller;

import com.propzen.ai.dto.EnquiryClassificationDto;
import com.propzen.ai.service.EnquiryClassificationService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/ai/enquiries")
@Tag(name = "AI Enquiry Intelligence", description = "Endpoints for AI classification, sentiment analysis, and smart triage of customer enquiries")
public class AiEnquiryController {

    private final EnquiryClassificationService classificationService;
    private final CurrentUserService currentUserService;

    public AiEnquiryController(EnquiryClassificationService classificationService,
                               CurrentUserService currentUserService) {
        this.classificationService = classificationService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/{id}/classify")
    @Operation(summary = "Classify enquiry message",
            description = "Analyzes enquiry message to detect category, priority, sentiment, and suggested department without altering the raw text")
    public ResponseEntity<ApiResponse<EnquiryClassificationDto>> classifyEnquiry(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> payload) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        String messageOverride = (payload != null && payload.containsKey("message"))
                ? payload.get("message")
                : null;
        EnquiryClassificationDto dto = classificationService.classifyEnquiry(id, messageOverride, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Enquiry classified successfully"));
    }

    @GetMapping("/{id}/classification")
    @Operation(summary = "Retrieve existing enquiry classification")
    public ResponseEntity<ApiResponse<EnquiryClassificationDto>> getClassification(@PathVariable UUID id) {
        EnquiryClassificationDto dto = classificationService.getClassification(id);
        if (dto == null) {
            // Auto-classify on first read if not yet classified
            AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
            dto = classificationService.classifyEnquiry(id, null, actor);
        }
        return ResponseEntity.ok(ApiResponse.ok(dto, "Enquiry classification retrieved successfully"));
    }
}
