package com.propzen.service.dto;

import com.propzen.service.entity.ServiceDocument;
import com.propzen.service.model.DocumentVerificationStatus;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServiceDocumentDto {
    private UUID id;
    private UUID serviceRequestId;
    private UUID uploadedBy;
    private String documentType;
    private String fileName;
    private String storagePath;
    private String fileUrl;
    private String mimeType;
    private Long fileSize;
    private DocumentVerificationStatus verificationStatus;
    private OffsetDateTime uploadedAt;
    private OffsetDateTime verifiedAt;
    private UUID verifiedBy;
    private String rejectionReason;

    public static ServiceDocumentDto fromEntity(ServiceDocument entity) {
        ServiceDocumentDto dto = new ServiceDocumentDto();
        dto.setId(entity.getId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setUploadedBy(entity.getUploadedBy());
        dto.setDocumentType(entity.getDocumentType());
        dto.setFileName(entity.getFileName());
        dto.setStoragePath(entity.getStoragePath());
        dto.setFileUrl(entity.getFileUrl());
        dto.setMimeType(entity.getMimeType());
        dto.setFileSize(entity.getFileSize());
        dto.setVerificationStatus(entity.getVerificationStatus());
        dto.setUploadedAt(entity.getUploadedAt());
        dto.setVerifiedAt(entity.getVerifiedAt());
        dto.setVerifiedBy(entity.getVerifiedBy());
        dto.setRejectionReason(entity.getRejectionReason());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public UUID getUploadedBy() { return uploadedBy; }
    public void setUploadedBy(UUID uploadedBy) { this.uploadedBy = uploadedBy; }

    public String getDocumentType() { return documentType; }
    public void setDocumentType(String documentType) { this.documentType = documentType; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public String getStoragePath() { return storagePath; }
    public void setStoragePath(String storagePath) { this.storagePath = storagePath; }

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public Long getFileSize() { return fileSize; }
    public void setFileSize(Long fileSize) { this.fileSize = fileSize; }

    public DocumentVerificationStatus getVerificationStatus() { return verificationStatus; }
    public void setVerificationStatus(DocumentVerificationStatus verificationStatus) { this.verificationStatus = verificationStatus; }

    public OffsetDateTime getUploadedAt() { return uploadedAt; }
    public void setUploadedAt(OffsetDateTime uploadedAt) { this.uploadedAt = uploadedAt; }

    public OffsetDateTime getVerifiedAt() { return verifiedAt; }
    public void setVerifiedAt(OffsetDateTime verifiedAt) { this.verifiedAt = verifiedAt; }

    public UUID getVerifiedBy() { return verifiedBy; }
    public void setVerifiedBy(UUID verifiedBy) { this.verifiedBy = verifiedBy; }

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
}
