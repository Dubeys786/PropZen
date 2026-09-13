package com.propzen.crm.service;

import com.propzen.crm.dto.CreateFollowUpDto;
import com.propzen.crm.dto.FollowUpDto;
import com.propzen.crm.entity.CrmFollowUp;
import com.propzen.crm.model.CrmActivityType;
import com.propzen.crm.model.FollowUpStatus;
import com.propzen.crm.repository.CrmFollowUpRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CrmFollowUpService {

    private static final Logger log = LoggerFactory.getLogger(CrmFollowUpService.class);

    private final CrmFollowUpRepository followUpRepository;
    private final CrmActivityService activityService;

    public CrmFollowUpService(CrmFollowUpRepository followUpRepository, CrmActivityService activityService) {
        this.followUpRepository = followUpRepository;
        this.activityService = activityService;
    }

    @Transactional
    public FollowUpDto scheduleFollowUp(CreateFollowUpDto dto) {
        CrmFollowUp followUp = new CrmFollowUp(
                dto.getLeadId(),
                dto.getAssignedTo(),
                dto.getTitle(),
                dto.getDescription(),
                dto.getFollowupAt(),
                dto.getPriority()
        );

        CrmFollowUp saved = followUpRepository.save(followUp);

        activityService.recordSystemActivity(
                dto.getLeadId(),
                null,
                CrmActivityType.FOLLOWUP_SCHEDULED,
                "Follow-up Scheduled",
                "Follow-up scheduled for " + dto.getFollowupAt() + ": " + dto.getTitle()
        );

        log.info("Scheduled follow-up {} for lead {}", saved.getId(), saved.getLeadId());
        return FollowUpDto.fromEntity(saved);
    }

    @Transactional
    public FollowUpDto completeFollowUp(UUID followUpId) {
        CrmFollowUp followUp = followUpRepository.findById(followUpId)
                .orElseThrow(() -> new NoSuchElementException("Follow-up not found: " + followUpId));

        followUp.setStatus(FollowUpStatus.COMPLETED);
        followUp.setCompletedAt(OffsetDateTime.now());
        CrmFollowUp saved = followUpRepository.save(followUp);

        activityService.recordSystemActivity(
                saved.getLeadId(),
                null,
                CrmActivityType.FOLLOWUP_COMPLETED,
                "Follow-up Completed",
                "Completed follow-up: " + saved.getTitle()
        );

        return FollowUpDto.fromEntity(saved);
    }

    @Transactional
    public FollowUpDto cancelFollowUp(UUID followUpId) {
        CrmFollowUp followUp = followUpRepository.findById(followUpId)
                .orElseThrow(() -> new NoSuchElementException("Follow-up not found: " + followUpId));

        followUp.setStatus(FollowUpStatus.CANCELLED);
        CrmFollowUp saved = followUpRepository.save(followUp);
        return FollowUpDto.fromEntity(saved);
    }

    @Transactional
    public FollowUpDto rescheduleFollowUp(UUID followUpId, OffsetDateTime newTime) {
        CrmFollowUp followUp = followUpRepository.findById(followUpId)
                .orElseThrow(() -> new NoSuchElementException("Follow-up not found: " + followUpId));

        followUp.setFollowupAt(newTime);
        followUp.setStatus(FollowUpStatus.RESCHEDULED);
        CrmFollowUp saved = followUpRepository.save(followUp);
        return FollowUpDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<FollowUpDto> getFollowUpsByLeadId(UUID leadId) {
        return followUpRepository.findByLeadIdOrderByFollowupAtAsc(leadId)
                .stream()
                .map(FollowUpDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<FollowUpDto> getFollowUpsByLeadId(UUID leadId, Pageable pageable) {
        return followUpRepository.findByLeadIdOrderByFollowupAtAsc(leadId, pageable)
                .map(FollowUpDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public List<FollowUpDto> getFollowUpsByAssignedTo(UUID assignedTo) {
        return followUpRepository.findByAssignedToOrderByFollowupAtAsc(assignedTo)
                .stream()
                .map(FollowUpDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<FollowUpDto> getPendingDueFollowUps(OffsetDateTime cutoff) {
        return followUpRepository.findPendingDueFollowUps(cutoff)
                .stream()
                .map(FollowUpDto::fromEntity)
                .collect(Collectors.toList());
    }
}
