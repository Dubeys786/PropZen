package com.propzen.verification.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.verification.dto.CreateVerificationCaseRequest;
import com.propzen.verification.dto.UpdateVerificationStatusRequest;
import com.propzen.verification.dto.VerificationCaseDto;
import com.propzen.verification.dto.VerificationDashboardMetricsDto;
import com.propzen.verification.dto.VerificationDocumentDto;
import com.propzen.verification.model.VerificationCaseStatus;
import com.propzen.verification.model.VerificationRiskLevel;
import com.propzen.verification.service.PropertyVerificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/verification")
@Tag(name = "AI Property Verification", description = "Endpoints for AI-powered property verification, document analysis, consistency checking and risk assessment")
public class PropertyVerificationController {

    private final PropertyVerificationService verificationService;
    private final CurrentUserService currentUserService;

    public PropertyVerificationController(PropertyVerificationService verificationService,
                                        CurrentUserService currentUserService) {
        this.verificationService = verificationService;
        this.currentUserService = currentUserService;
    }

    @GetMapping("/metrics")
    @Operation(summary = "Get live AI property verification telemetry and KPI counters",
            description = "Calculates totalVerificationCases, verified, underReview, highRisk, documentsProcessed from live database records")
    public ResponseEntity<ApiResponse<VerificationDashboardMetricsDto>> getMetrics() {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        VerificationDashboardMetricsDto metrics = verificationService.getMetrics(actor);
        return ResponseEntity.ok(ApiResponse.ok(metrics, "Verification metrics retrieved successfully"));
    }

    @GetMapping("/cases")
    @Operation(summary = "Search and filter verification cases with pagination")
    public ResponseEntity<ApiResponse<Page<VerificationCaseDto>>> searchCases(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) VerificationCaseStatus status,
            @RequestParam(required = false) VerificationRiskLevel riskLevel,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        String[] sortParts = sort.split(",");
        Sort.Direction direction = sortParts.length > 1 && sortParts[1].equalsIgnoreCase("asc") ? Sort.Direction.ASC : Sort.Direction.DESC;
        String sortProp = sortParts[0];

        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, sortProp));
        Page<VerificationCaseDto> cases = verificationService.searchCases(q, status, riskLevel, pageable, actor);
        return ResponseEntity.ok(ApiResponse.ok(cases, "Verification cases retrieved successfully"));
    }

    @PostMapping("/cases")
    @Operation(summary = "Create a new verification case with property details and document items")
    public ResponseEntity<ApiResponse<VerificationCaseDto>> createCase(
            @Valid @RequestBody CreateVerificationCaseRequest request
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        VerificationCaseDto created = verificationService.createCase(request, actor);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Verification case created successfully"));
    }

    @GetMapping("/cases/{id}")
    @Operation(summary = "Get detailed verification case by ID")
    public ResponseEntity<ApiResponse<VerificationCaseDto>> getCase(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        VerificationCaseDto details = verificationService.getCase(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(details, "Verification case retrieved successfully"));
    }

    @PostMapping("/cases/{id}/verify")
    @Operation(summary = "Execute 8-step AI property verification pipeline on a case")
    public ResponseEntity<ApiResponse<VerificationCaseDto>> executeVerification(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        VerificationCaseDto result = verificationService.executeVerification(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(result, "AI Verification pipeline completed successfully"));
    }

    @PatchMapping("/cases/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    @Operation(summary = "Update verification status and review notes (Admin / Staff only)")
    public ResponseEntity<ApiResponse<VerificationCaseDto>> updateStatus(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateVerificationStatusRequest request
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        VerificationCaseDto updated = verificationService.updateStatus(id, request, actor);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Case status updated successfully"));
    }

    @GetMapping("/documents")
    @Operation(summary = "List all documents associated with verification cases")
    public ResponseEntity<ApiResponse<Page<VerificationDocumentDto>>> getDocuments(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<VerificationDocumentDto> docs = verificationService.getDocuments(pageable, actor);
        return ResponseEntity.ok(ApiResponse.ok(docs, "Documents retrieved successfully"));
    }

    @GetMapping("/history")
    @Operation(summary = "Get historical verification cases")
    public ResponseEntity<ApiResponse<Page<VerificationCaseDto>>> getHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<VerificationCaseDto> history = verificationService.searchCases(null, null, null, pageable, actor);
        return ResponseEntity.ok(ApiResponse.ok(history, "Verification history retrieved successfully"));
    }
}
