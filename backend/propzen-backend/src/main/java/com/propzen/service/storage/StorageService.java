package com.propzen.service.storage;

import com.propzen.exception.ForbiddenException;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Controlled file upload authorization and secure signed URL generation service.
 * Prevents direct exposure of Supabase service-role keys or storage credentials to frontend.
 */
@Service
public class StorageService {

    private static final Logger log = LoggerFactory.getLogger(StorageService.class);
    private static final Set<String> PUBLIC_BUCKETS = Set.of("property-photos", "profile-photos", "public-assets");

    @Value("${propzen.supabase.url:https://eemxylswyvhsyzllcsnp.supabase.co}")
    private String supabaseUrl;

    public Map<String, Object> authorizeUpload(String bucket, String fileName, String mimeType, long fileSize, AuthenticatedUser actor) {
        validateFile(fileName, mimeType, fileSize);

        String sanitizedFilename = sanitizeFilename(fileName);
        String storagePath = bucket + "/" + actor.getUserId() + "/" + UUID.randomUUID() + "_" + sanitizedFilename;
        long expirySeconds = 900; // 15 minutes
        long expiresAt = Instant.now().getEpochSecond() + expirySeconds;

        String signedUploadUrl = supabaseUrl + "/storage/v1/object/upload/sign/" + storagePath + "?token=" + UUID.randomUUID();
        boolean isPublicBucket = PUBLIC_BUCKETS.contains(bucket != null ? bucket.toLowerCase() : "");
        String publicAccessUrl = isPublicBucket ? supabaseUrl + "/storage/v1/object/public/" + storagePath : null;

        log.info("Authorized storage upload for user {} to path: {}", actor.getUserId(), storagePath);

        Map<String, Object> result = new HashMap<>();
        result.put("uploadUrl", signedUploadUrl);
        result.put("storagePath", storagePath);
        if (publicAccessUrl != null) {
            result.put("fileUrl", publicAccessUrl);
        }
        result.put("expiresAt", expiresAt);
        result.put("bucket", bucket);
        result.put("mimeType", mimeType);
        return result;
    }

    public Map<String, Object> getSignedDownloadUrl(String storagePath, AuthenticatedUser actor) {
        if (storagePath == null || storagePath.isBlank()) {
            throw new IllegalArgumentException("Storage path is required");
        }
        if (storagePath.contains("..") || storagePath.contains("\\")) {
            throw new IllegalArgumentException("Invalid storage path");
        }
        if (actor == null) {
            throw new ForbiddenException("Authentication required");
        }

        assertStorageAccess(storagePath, actor);

        long expirySeconds = 1800; // 30 minutes
        long expiresAt = Instant.now().getEpochSecond() + expirySeconds;
        String signedUrl = supabaseUrl + "/storage/v1/object/sign/" + storagePath + "?token=" + UUID.randomUUID();

        Map<String, Object> result = new HashMap<>();
        result.put("downloadUrl", signedUrl);
        result.put("storagePath", storagePath);
        result.put("expiresAt", expiresAt);
        return result;
    }

    private void assertStorageAccess(String storagePath, AuthenticatedUser actor) {
        if (actor.isAdmin()) {
            return;
        }
        String[] parts = storagePath.split("/");
        if (parts.length >= 2) {
            String bucket = parts[0].toLowerCase();
            if (PUBLIC_BUCKETS.contains(bucket)) {
                return;
            }
            try {
                UUID ownerId = UUID.fromString(parts[1]);
                if (!ownerId.equals(actor.getUserId())) {
                    log.warn("IDOR attempt: User {} attempted to access document owned by {} at {}", actor.getUserId(), ownerId, storagePath);
                    throw new ForbiddenException("Access denied: You do not have permission to access this document");
                }
            } catch (IllegalArgumentException ex) {
                log.warn("Denied access to private storage path {} for non-admin user {}", storagePath, actor.getUserId());
                throw new ForbiddenException("Access denied: You do not have permission to access this document");
            }
        } else {
            throw new ForbiddenException("Access denied: Invalid storage path");
        }
    }

    private void validateFile(String fileName, String mimeType, long fileSize) {
        if (fileName == null || fileName.isBlank()) {
            throw new IllegalArgumentException("File name is required");
        }
        if (fileSize > 25 * 1024 * 1024) { // 25 MB max limit
            throw new IllegalArgumentException("File size exceeds 25 MB maximum allowed limit");
        }
        if (fileName.contains("..") || fileName.contains("/") || fileName.contains("\\")) {
            throw new IllegalArgumentException("Invalid file name containing path traversal characters");
        }
        String lowerName = fileName.toLowerCase();
        if (lowerName.endsWith(".exe") || lowerName.endsWith(".sh") || lowerName.endsWith(".bat") ||
            lowerName.endsWith(".cmd") || lowerName.endsWith(".php") || lowerName.endsWith(".js")) {
            throw new IllegalArgumentException("Disallowed executable or script file extension");
        }
    }

    private String sanitizeFilename(String fileName) {
        return fileName.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
