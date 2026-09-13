package com.propzen.service.storage;

import com.propzen.common.response.ApiResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Tag(name = "Storage & Documents", description = "Secure backend authorization for Supabase storage uploads and signed URLs")
@RestController
@RequestMapping("/api/v1/storage")
@SecurityRequirement(name = "BearerAuth")
public class StorageController {

    private final StorageService storageService;
    private final CurrentUserService currentUserService;

    public StorageController(StorageService storageService, CurrentUserService currentUserService) {
        this.storageService = storageService;
        this.currentUserService = currentUserService;
    }

    @PostMapping("/authorize-upload")
    @Operation(summary = "Authorize a file upload and obtain a secure signed upload URL")
    public ResponseEntity<ApiResponse<Map<String, Object>>> authorizeUpload(
            @RequestParam(defaultValue = "documents") String bucket,
            @RequestParam String fileName,
            @RequestParam(defaultValue = "application/octet-stream") String mimeType,
            @RequestParam(defaultValue = "1048576") long fileSize
    ) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Map<String, Object> result = storageService.authorizeUpload(bucket, fileName, mimeType, fileSize, actor);
        return ResponseEntity.ok(ApiResponse.ok(result, "Upload authorized"));
    }

    @GetMapping("/signed-download-url")
    @Operation(summary = "Generate a time-limited signed URL to download a private document")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getSignedDownloadUrl(@RequestParam String storagePath) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Map<String, Object> result = storageService.getSignedDownloadUrl(storagePath, actor);
        return ResponseEntity.ok(ApiResponse.ok(result, "Signed download URL generated"));
    }
}
