package com.propzen.verification.dto;

import com.propzen.verification.model.VerificationDocumentType;
import jakarta.validation.constraints.NotBlank;
import java.util.ArrayList;
import java.util.List;

public class CreateVerificationCaseRequest {

    @NotBlank(message = "Property title is required")
    private String propertyTitle;

    @NotBlank(message = "Property type is required")
    private String propertyType;

    @NotBlank(message = "Address is required")
    private String address;

    @NotBlank(message = "City is required")
    private String city;

    private String sectorLocality;
    private String khasraNumber;
    private String plotNumber;
    private String area;

    @NotBlank(message = "Owner name is required")
    private String ownerName;

    private String registrationNumber;
    private String registrationDate;

    private List<UploadDocumentItem> documents = new ArrayList<>();

    public CreateVerificationCaseRequest() {
    }

    public static class UploadDocumentItem {
        private String fileName;
        private VerificationDocumentType documentType = VerificationDocumentType.OTHER;
        private Long fileSize = 0L;
        private String fileUrl;
        private String mimeType;

        public UploadDocumentItem() {}

        public UploadDocumentItem(String fileName, VerificationDocumentType documentType, Long fileSize, String fileUrl, String mimeType) {
            this.fileName = fileName;
            this.documentType = documentType;
            this.fileSize = fileSize;
            this.fileUrl = fileUrl;
            this.mimeType = mimeType;
        }

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
    }

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

    public List<UploadDocumentItem> getDocuments() { return documents; }
    public void setDocuments(List<UploadDocumentItem> documents) { this.documents = documents; }
}
