package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CreateNoteRequest;
import com.propzen.crm.dto.CrmNoteDto;
import com.propzen.crm.dto.UpdateNoteRequest;
import com.propzen.crm.service.CrmNoteService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/crm/notes")
@Tag(name = "CRM Notes", description = "Endpoints for managing internal CRM customer/lead notes")
public class CrmNoteController {

    private final CrmNoteService noteService;
    private final CurrentUserService currentUserService;

    public CrmNoteController(CrmNoteService noteService, CurrentUserService currentUserService) {
        this.noteService = noteService;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    @Operation(summary = "Add an internal note to a lead or customer")
    public ResponseEntity<ApiResponse<CrmNoteDto>> addNote(@Valid @RequestBody CreateNoteRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        CrmNoteDto note = noteService.addNote(request, actor.getUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(note, "Note created successfully"));
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Update an existing internal note")
    public ResponseEntity<ApiResponse<CrmNoteDto>> updateNote(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateNoteRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        CrmNoteDto updated = noteService.updateNote(id, request, actor.getUserId(), isAdmin);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Note updated successfully"));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete an existing internal note")
    public ResponseEntity<ApiResponse<Void>> deleteNote(@PathVariable UUID id) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        boolean isAdmin = actor.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        noteService.deleteNote(id, actor.getUserId(), isAdmin);
        return ResponseEntity.ok(ApiResponse.ok(null, "Note deleted successfully"));
    }
}
