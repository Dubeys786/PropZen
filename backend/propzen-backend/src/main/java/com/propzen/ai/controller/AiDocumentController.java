package com.propzen.ai.controller;

import com.propzen.ai.dto.DocumentIntelligenceDto;
import com.propzen.ai.service.DocumentIntelligenceService;
import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/ai/documents")
@Tag(name = "AI Document Intelligence", description = "Endpoints for AI-assisted document validation, classification, and completeness checking")
public class AiDocumentController {

    private final DocumentIntelligenceService documentIntelligenceService;
    private final CurrentUserService currentUserService;

    public AiDocumentController(DocumentIntelligenceService documentIntelligenceService,
                                CurrentUserService currentUserService) {
        this.documentIntelligenceService = documentIntelligenceService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/analyze")
    @Operation(summary = "Analyze document metadata for validity and compliance",
            description = "Validates file characteristics, verifies security and format integrity, and returns classification status")
    public ResponseEntity<ApiResponse<DocumentIntelligenceDto>> analyzeDocument(
            @RequestBody Map<String, Object> payload) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        String fileName = (String) payload.getOrDefault("fileName", "document.pdf");
        String mimeType = (String) payload.getOrDefault("mimeType", "application/pdf");
        Long fileSize = payload.containsKey("fileSize") && payload.get("fileSize") instanceof Number
                ? ((Number) payload.get("fileSize")).longValue()
                : 1024L;

        DocumentIntelligenceDto dto = documentIntelligenceService.analyzeDocument(fileName, mimeType, fileSize, actor);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Document analyzed successfully"));
    }
}
