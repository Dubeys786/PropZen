package com.propzen.crm.service;

import com.propzen.common.audit.AuditLogService;
import com.propzen.crm.dto.CreateFollowUpRequest;
import com.propzen.crm.dto.LeadActivityDto;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.LeadActivity;
import com.propzen.crm.model.ActivityType;
import com.propzen.crm.repository.LeadActivityRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.exception.ForbiddenException;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class FollowUpService {

    private final LeadActivityRepository leadActivityRepository;
    private final LeadRepository leadRepository;
    private final AuditLogService auditLogService;

    public FollowUpService(LeadActivityRepository leadActivityRepository,
                           LeadRepository leadRepository,
                           AuditLogService auditLogService) {
        this.leadActivityRepository = leadActivityRepository;
        this.leadRepository = leadRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional
    public LeadActivityDto addFollowUp(UUID leadId, CreateFollowUpRequest request, AuthenticatedUser actor) {
        Lead lead = leadRepository.findById(leadId)
                .orElseThrow(() -> new ResourceNotFoundException("Lead", leadId));

        LeadActivity activity = new LeadActivity();
        activity.setLeadId(leadId);
        activity.setActorUserId(actor.getUserId());
        activity.setType(request.getType() != null ? request.getType() : ActivityType.FOLLOW_UP);
        activity.setNote(request.getNote().trim());
        activity.setScheduledAt(request.getScheduledAt());
        activity.setMetadata(request.getMetadata());

        LeadActivity saved = leadActivityRepository.save(activity);

        // If scheduled in the future, update lead's nextFollowUpAt
        if (request.getScheduledAt() != null) {
            lead.setNextFollowUpAt(request.getScheduledAt());
            leadRepository.save(lead);
        }

        auditLogService.logAction(
                actor.getUserId(),
                "FOLLOW_UP_CREATED",
                "crm_lead_activities/" + saved.getId(),
                "Added follow-up to lead " + lead.getLeadNumber()
        );

        return LeadActivityDto.fromEntity(saved);
    }

    @Transactional
    public LeadActivityDto completeFollowUp(UUID activityId, AuthenticatedUser actor) {
        LeadActivity activity = leadActivityRepository.findById(activityId)
                .orElseThrow(() -> new ResourceNotFoundException("FollowUp", activityId));

        activity.setCompletedAt(OffsetDateTime.now());
        LeadActivity saved = leadActivityRepository.save(activity);

        // Update lead's lastContactedAt
        leadRepository.findById(activity.getLeadId()).ifPresent(l -> {
            l.setLastContactedAt(OffsetDateTime.now());
            leadRepository.save(l);
        });

        auditLogService.logAction(
                actor.getUserId(),
                "FOLLOW_UP_COMPLETED",
                "crm_lead_activities/" + saved.getId(),
                "Completed follow-up"
        );

        return LeadActivityDto.fromEntity(saved);
    }

    @Transactional
    public void deleteFollowUp(UUID activityId, AuthenticatedUser actor) {
        LeadActivity activity = leadActivityRepository.findById(activityId)
                .orElseThrow(() -> new ResourceNotFoundException("FollowUp", activityId));

        leadActivityRepository.delete(activity);

        auditLogService.logAction(
                actor.getUserId(),
                "FOLLOW_UP_DELETED",
                "crm_lead_activities/" + activityId,
                "Deleted follow-up"
        );
    }
}
