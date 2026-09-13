package com.propzen.crm.service;

import com.propzen.crm.dto.CreateNoteRequest;
import com.propzen.crm.dto.CrmNoteDto;
import com.propzen.crm.dto.UpdateNoteRequest;
import com.propzen.crm.entity.CrmNote;
import com.propzen.crm.model.CrmActivityType;
import com.propzen.crm.repository.CrmNoteRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CrmNoteService {

    private static final Logger log = LoggerFactory.getLogger(CrmNoteService.class);

    private final CrmNoteRepository noteRepository;
    private final CrmActivityService activityService;

    public CrmNoteService(CrmNoteRepository noteRepository, CrmActivityService activityService) {
        this.noteRepository = noteRepository;
        this.activityService = activityService;
    }

    @Transactional
    public CrmNoteDto addNote(CreateNoteRequest request, UUID createdBy) {
        CrmNote note = new CrmNote(request.getLeadId(), request.getCustomerId(), createdBy, request.getNote());
        CrmNote saved = noteRepository.save(note);

        activityService.recordSystemActivity(
                request.getLeadId(),
                request.getCustomerId(),
                CrmActivityType.NOTE_ADDED,
                "Note Added",
                "Internal note added: " + (request.getNote().length() > 50 ? request.getNote().substring(0, 47) + "..." : request.getNote())
        );

        log.info("Created CRM note {} for lead {}", saved.getId(), saved.getLeadId());
        return CrmNoteDto.fromEntity(saved);
    }

    @Transactional
    public CrmNoteDto updateNote(UUID noteId, UpdateNoteRequest request, UUID requestingUserId, boolean isAdmin) {
        CrmNote note = noteRepository.findById(noteId)
                .orElseThrow(() -> new NoSuchElementException("Note not found: " + noteId));

        if (!isAdmin && !note.getCreatedBy().equals(requestingUserId)) {
            throw new AccessDeniedException("You are not authorized to update this note");
        }

        note.setNote(request.getNote());
        CrmNote saved = noteRepository.save(note);
        return CrmNoteDto.fromEntity(saved);
    }

    @Transactional
    public void deleteNote(UUID noteId, UUID requestingUserId, boolean isAdmin) {
        CrmNote note = noteRepository.findById(noteId)
                .orElseThrow(() -> new NoSuchElementException("Note not found: " + noteId));

        if (!isAdmin && !note.getCreatedBy().equals(requestingUserId)) {
            throw new AccessDeniedException("You are not authorized to delete this note");
        }

        noteRepository.delete(note);
        log.info("Deleted CRM note {}", noteId);
    }

    @Transactional(readOnly = true)
    public List<CrmNoteDto> getNotesByLeadId(UUID leadId) {
        return noteRepository.findByLeadIdOrderByCreatedAtDesc(leadId)
                .stream()
                .map(CrmNoteDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<CrmNoteDto> getNotesByLeadId(UUID leadId, Pageable pageable) {
        return noteRepository.findByLeadIdOrderByCreatedAtDesc(leadId, pageable)
                .map(CrmNoteDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public List<CrmNoteDto> getNotesByCustomerId(UUID customerId) {
        return noteRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(CrmNoteDto::fromEntity)
                .collect(Collectors.toList());
    }
}
