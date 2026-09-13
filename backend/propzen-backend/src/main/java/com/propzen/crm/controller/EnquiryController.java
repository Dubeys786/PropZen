package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CreateEnquiryRequest;
import com.propzen.crm.dto.EnquiryDto;
import com.propzen.crm.service.EnquiryService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/enquiries")
@Tag(name = "Enquiry Management", description = "Endpoints for submitting property enquiries with automatic CRM lead sync")
public class EnquiryController {

    private final EnquiryService enquiryService;
    private final CurrentUserService currentUserService;

    public EnquiryController(EnquiryService enquiryService, CurrentUserService currentUserService) {
        this.enquiryService = enquiryService;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    @Operation(summary = "Submit a property enquiry",
            description = "Submits a new enquiry and automatically associates or creates an active CRM lead")
    public ResponseEntity<ApiResponse<EnquiryDto>> submitEnquiry(
            @Valid @RequestBody CreateEnquiryRequest request) {
        AuthenticatedUser principal = currentUserService.getCurrentUser().orElse(null);
        EnquiryDto dto = enquiryService.submitEnquiry(request, principal);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(dto, "Enquiry submitted successfully"));
    }

    @GetMapping("/me")
    @Operation(summary = "Get current user's submitted enquiries",
            description = "Returns historical enquiries submitted by the authenticated user")
    public ResponseEntity<ApiResponse<List<EnquiryDto>>> getMyEnquiries() {
        AuthenticatedUser principal = currentUserService.getRequiredCurrentUser();
        List<EnquiryDto> enquiries = enquiryService.getMyEnquiries(principal);
        return ResponseEntity.ok(ApiResponse.ok(enquiries, "Enquiries retrieved successfully"));
    }
}
