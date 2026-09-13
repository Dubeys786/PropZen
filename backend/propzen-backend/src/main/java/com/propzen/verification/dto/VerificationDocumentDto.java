package com.propzen.verification.dto;

import com.propzen.verification.entity.PropertyVerificationDocument;
import com.propzen.verification.model.VerificationDocumentType;
import java.time.OffsetDateTime;
import java.util.UUID;

public class VerificationDocumentDto {

    private UUID id;
    private String fileName;
    private VerificationDocumentType documentType;
    private Long fileSize;
    private String fileUrl;
    private String mimeType;
    private String uploadStatus;
    private OffsetDateTime createdAt;

    public VerificationDocumentDto() {
    }

    public static VerificationDocumentDto fromEntity(PropertyVerificationDocument doc) {
        if (doc == null) return null;
        VerificationDocumentDto dto = new VerificationDocumentDto();
        dto.setId(doc.getId());
        dto.setFileName(doc.getFileName());
        dto.setDocumentType(doc.getDocumentType());
        dto.setFileSize(doc.getFileSize());
        dto.setFileUrl(doc.getFileUrl());
        dto.setMimeType(doc.getMimeType());
        dto.setUploadStatus(doc.getUploadStatus());
        dto.setCreatedAt(doc.getCreatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public VerificationDocumentType getDocumentType() { return documentType; }
    public void setDocumentType(VerificationDocumentType documentType) { this.documentType = documentType; }

    public Long getFileSize() { return fileSize; }
    public void setFileSize(Long fileSize) { this.fileSize = fileSize; }

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public String getUploadStatus() { return uploadStatus; }
    public void setUploadStatus(String uploadStatus) { this.uploadStatus = uploadStatus; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
