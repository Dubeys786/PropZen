package com.propzen.verification.entity;

import com.propzen.verification.model.VerificationCaseStatus;
import com.propzen.verification.model.VerificationRiskLevel;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "property_verification_cases")
public class PropertyVerificationCase implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "case_number", nullable = false, unique = true, length = 50)
    private String caseNumber;

    @Column(name = "property_id")
    private String propertyId;

    @Column(name = "property_title", nullable = false)
    private String propertyTitle;

    @Column(name = "property_type", nullable = false, length = 100)
    private String propertyType;

    @Column(name = "address", nullable = false, columnDefinition = "text")
    private String address;

    @Column(name = "city", nullable = false, length = 100)
    private String city;

    @Column(name = "sector_locality", length = 100)
    private String sectorLocality;

    @Column(name = "khasra_number", length = 100)
    private String khasraNumber;

    @Column(name = "plot_number", length = 100)
    private String plotNumber;

    @Column(name = "area", length = 100)
    private String area;

    @Column(name = "owner_name", nullable = false)
    private String ownerName;

    @Column(name = "registration_number", length = 100)
    private String registrationNumber;

    @Column(name = "registration_date", length = 50)
    private String registrationDate;

    @Column(name = "submitted_by")
    private UUID submittedBy;

    @Column(name = "submitted_by_name")
    private String submittedByName;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 50)
    private VerificationCaseStatus status = VerificationCaseStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_level", nullable = false, length = 50)
    private VerificationRiskLevel riskLevel = VerificationRiskLevel.UNKNOWN;

    @Column(name = "risk_score")
    private Integer riskScore;

    @Column(name = "extracted_data", columnDefinition = "text")
    private String extractedData;

    @Column(name = "consistency_checks", columnDefinition = "text")
    private String consistencyChecks;

    @Column(name = "risk_checks", columnDefinition = "text")
    private String riskChecks;

    @Column(name = "findings", columnDefinition = "text")
    private String findings;

    @Column(name = "audit_trail", columnDefinition = "text")
    private String auditTrail;

    @OneToMany(mappedBy = "verificationCase", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PropertyVerificationDocument> documents = new ArrayList<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public PropertyVerificationCase() {
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
        if (caseNumber == null || caseNumber.isEmpty()) {
            caseNumber = "PVC-" + System.currentTimeMillis();
        }
        if (status == null) status = VerificationCaseStatus.PENDING;
        if (riskLevel == null) riskLevel = VerificationRiskLevel.UNKNOWN;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
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

    public List<PropertyVerificationDocument> getDocuments() { return documents; }
    public void setDocuments(List<PropertyVerificationDocument> documents) { this.documents = documents; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
