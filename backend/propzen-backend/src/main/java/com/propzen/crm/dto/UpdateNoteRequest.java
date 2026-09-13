package com.propzen.crm.dto;

import jakarta.validation.constraints.NotBlank;

public class UpdateNoteRequest {

    @NotBlank(message = "Note content is required")
    private String note;

    public UpdateNoteRequest() {
    }

    public UpdateNoteRequest(String note) {
        this.note = note;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
