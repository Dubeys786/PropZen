package com.propzen.verification.dto;

import com.propzen.verification.entity.PropertyVerificationCase;
import com.propzen.verification.model.VerificationCaseStatus;
import com.propzen.verification.model.VerificationRiskLevel;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class VerificationCaseDto {

    private UUID id;
    private String caseNumber;
    private String propertyId;
    private String propertyTitle;
    private String propertyType;
    private String address;
    private String city;
    private String sectorLocality;
    private String khasraNumber;
    private String plotNumber;
    private String area;
    private String ownerName;
    private String registrationNumber;
    private String registrationDate;
    private UUID submittedBy;
    private String submittedByName;
    private VerificationCaseStatus status;
    private VerificationRiskLevel riskLevel;
    private Integer riskScore;
    private String extractedData;
    private String consistencyChecks;
    private String riskChecks;
    private String findings;
    private String auditTrail;
    private List<VerificationDocumentDto> documents = new ArrayList<>();
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public VerificationCaseDto() {
    }

    public static VerificationCaseDto fromEntity(PropertyVerificationCase entity) {
        if (entity == null) return null;
        VerificationCaseDto dto = new VerificationCaseDto();
        dto.setId(entity.getId());
        dto.setCaseNumber(entity.getCaseNumber());
        dto.setPropertyId(entity.getPropertyId());
        dto.setPropertyTitle(entity.getPropertyTitle());
        dto.setPropertyType(entity.getPropertyType());
        dto.setAddress(entity.getAddress());
        dto.setCity(entity.getCity());
        dto.setSectorLocality(entity.getSectorLocality());
        dto.setKhasraNumber(entity.getKhasraNumber());
        dto.setPlotNumber(entity.getPlotNumber());
        dto.setArea(entity.getArea());
        dto.setOwnerName(entity.getOwnerName());
        dto.setRegistrationNumber(entity.getRegistrationNumber());
        dto.setRegistrationDate(entity.getRegistrationDate());
        dto.setSubmittedBy(entity.getSubmittedBy());
        dto.setSubmittedByName(entity.getSubmittedByName());
        dto.setStatus(entity.getStatus());
        dto.setRiskLevel(entity.getRiskLevel());
        dto.setRiskScore(entity.getRiskScore());
        dto.setExtractedData(entity.getExtractedData());
        dto.setConsistencyChecks(entity.getConsistencyChecks());
        dto.setRiskChecks(entity.getRiskChecks());
        dto.setFindings(entity.getFindings());
        dto.setAuditTrail(entity.getAuditTrail());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());

        if (entity.getDocuments() != null) {
            dto.setDocuments(entity.getDocuments().stream().map(VerificationDocumentDto::fromEntity).toList());
        }
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getCaseNumber() { return caseNumber; }
    public void setCaseNumber(String caseNumber) { this.caseNumber = caseNumber; }

    public String getPropertyId() { return propertyId; }
    public void setPropertyId(String propertyId) { this.propertyId = propertyId; }

    public String getPropertyTitle() { return propertyTitle; }
    public void setPropertyTitle(String propertyTitle) { this.propertyTitle = propertyTitle; }

    public String getPropertyType() { return propertyType; }
    public void setPropertyType(String propertyType) { this.propertyType = propertyType; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getSectorLocality() { return sectorLocality; }
    public void setSectorLocality(String sectorLocality) { this.sectorLocality = sectorLocality; }

    public String getKhasraNumber() { return khasraNumber; }
    public void setKhasraNumber(String khasraNumber) { this.khasraNumber = khasraNumber; }

    public String getPlotNumber() { return plotNumber; }
    public void setPlotNumber(String plotNumber) { this.plotNumber = plotNumber; }

    public String getArea() { return area; }
    public void setArea(String area) { this.area = area; }

    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }

    public String getRegistrationNumber() { return registrationNumber; }
    public void setRegistrationNumber(String registrationNumber) { this.registrationNumber = registrationNumber; }

    public String getRegistrationDate() { return registrationDate; }
    public void setRegistrationDate(String registrationDate) { this.registrationDate = registrationDate; }

    public UUID getSubmittedBy() { return submittedBy; }
    public void setSubmittedBy(UUID submittedBy) { this.submittedBy = submittedBy; }

    public String getSubmittedByName() { return submittedByName; }
    public void setSubmittedByName(String submittedByName) { this.submittedByName = submittedByName; }

    public VerificationCaseStatus getStatus() { return status; }
    public void setStatus(VerificationCaseStatus status) { this.status = status; }

    public VerificationRiskLevel getRiskLevel() { return riskLevel; }
    public void setRiskLevel(VerificationRiskLevel riskLevel) { this.riskLevel = riskLevel; }

    public Integer getRiskScore() { return riskScore; }
    public void setRiskScore(Integer riskScore) { this.riskScore = riskScore; }

    public String getExtractedData() { return extractedData; }
    public void setExtractedData(String extractedData) { this.extractedData = extractedData; }

    public String getConsistencyChecks() { return consistencyChecks; }
    public void setConsistencyChecks(String consistencyChecks) { this.consistencyChecks = consistencyChecks; }

    public String getRiskChecks() { return riskChecks; }
    public void setRiskChecks(String riskChecks) { this.riskChecks = riskChecks; }

    public String getFindings() { return findings; }
    public void setFindings(String findings) { this.findings = findings; }

    public String getAuditTrail() { return auditTrail; }
    public void setAuditTrail(String auditTrail) { this.auditTrail = auditTrail; }

    public List<VerificationDocumentDto> getDocuments() { return documents; }
    public void setDocuments(List<VerificationDocumentDto> documents) { this.documents = documents; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
