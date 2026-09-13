package com.propzen.service.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import com.propzen.service.dto.ServiceDocumentDto;
import com.propzen.service.dto.UploadDocumentRequest;
import com.propzen.service.dto.VerifyDocumentRequest;
import com.propzen.service.model.DocumentVerificationStatus;
import com.propzen.service.service.ServiceDocumentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Tag(name = "Services - Documents", description = "Service request document upload, retrieval, and verification APIs")
@RestController
@RequestMapping("/api/v1/services")
@SecurityRequirement(name = "BearerAuth")
public class ServiceDocumentController {

    private final ServiceDocumentService documentService;
    private final CurrentUserService currentUserService;

    public ServiceDocumentController(ServiceDocumentService documentService,
                                     CurrentUserService currentUserService) {
        this.documentService = documentService;
        this.currentUserService = currentUserService;
    }

    @Operation(summary = "Upload a document to a service request")
    @PostMapping("/requests/{id}/documents")
    public ResponseEntity<ApiResponse<ServiceDocumentDto>> uploadDocument(
            @PathVariable UUID id,
            @Valid @RequestBody UploadDocumentRequest request
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        ServiceDocumentDto uploaded = documentService.uploadDocument(id, request, actor);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(uploaded, "Document uploaded successfully"));
    }

    @Operation(summary = "List all documents associated with a service request")
    @GetMapping("/requests/{id}/documents")
    public ResponseEntity<ApiResponse<List<ServiceDocumentDto>>> getDocuments(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        List<ServiceDocumentDto> docs = documentService.getDocuments(id, actor);
        return ResponseEntity.ok(ApiResponse.ok(docs));
    }

    @Operation(summary = "Verify a service document")
    @PatchMapping("/documents/{id}/verify")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<ServiceDocumentDto>> verifyDocument(@PathVariable UUID id) {
        AuthenticatedUser verifier = currentUserService.getRequiredCurrentUser();
        VerifyDocumentRequest req = new VerifyDocumentRequest();
        req.setVerificationStatus(DocumentVerificationStatus.VERIFIED);
        ServiceDocumentDto verified = documentService.verifyDocument(id, req, verifier);
        return ResponseEntity.ok(ApiResponse.ok(verified, "Document verified"));
    }

    @Operation(summary = "Reject a service document with reason")
    @PatchMapping("/documents/{id}/reject")
    @PreAuthorize("hasAnyRole('ADMIN', 'STAFF')")
    public ResponseEntity<ApiResponse<ServiceDocumentDto>> rejectDocument(
            @PathVariable UUID id,
            @RequestBody(required = false) Map<String, String> body
    ) {
        AuthenticatedUser verifier = currentUserService.getRequiredCurrentUser();
        VerifyDocumentRequest req = new VerifyDocumentRequest();
        req.setVerificationStatus(DocumentVerificationStatus.REJECTED);
        req.setRejectionReason(body != null ? body.get("reason") : null);
        ServiceDocumentDto rejected = documentService.verifyDocument(id, req, verifier);
        return ResponseEntity.ok(ApiResponse.ok(rejected, "Document rejected"));
    }
}
