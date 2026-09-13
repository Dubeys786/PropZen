package com.propzen.verification.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.propzen.verification.model.VerificationDocumentType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "property_verification_documents")
public class PropertyVerificationDocument implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "case_id", nullable = false)
    private PropertyVerificationCase verificationCase;

    @Column(name = "file_name", nullable = false)
    private String fileName;

    @Enumerated(EnumType.STRING)
    @Column(name = "document_type", nullable = false, length = 100)
    private VerificationDocumentType documentType = VerificationDocumentType.OTHER;

    @Column(name = "file_size", nullable = false)
    private Long fileSize = 0L;

    @Column(name = "file_url", length = 500)
    private String fileUrl;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "upload_status", nullable = false, length = 50)
    private String uploadStatus = "UPLOADED";

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public PropertyVerificationDocument() {
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (uploadStatus == null) uploadStatus = "UPLOADED";
        if (documentType == null) documentType = VerificationDocumentType.OTHER;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public PropertyVerificationCase getVerificationCase() { return verificationCase; }
    public void setVerificationCase(PropertyVerificationCase verificationCase) { this.verificationCase = verificationCase; }

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
