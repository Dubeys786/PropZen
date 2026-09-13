package com.propzen.service.dto;

import jakarta.validation.constraints.NotBlank;

import java.io.Serializable;

public class CreateDeliverableRequest implements Serializable {

    @NotBlank(message = "Deliverable title is required")
    private String title;

    private String description;

    private String fileUrl;

    public CreateDeliverableRequest() {
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getFileUrl() {
        return fileUrl;
    }

    public void setFileUrl(String fileUrl) {
        this.fileUrl = fileUrl;
    }
}
