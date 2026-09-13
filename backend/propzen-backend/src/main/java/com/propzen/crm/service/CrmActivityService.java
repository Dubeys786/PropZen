package com.propzen.crm.service;

import com.propzen.crm.dto.ActivityDto;
import com.propzen.crm.dto.CreateActivityRequest;
import com.propzen.crm.entity.CrmActivity;
import com.propzen.crm.model.CrmActivityType;
import com.propzen.crm.repository.CrmActivityRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CrmActivityService {

    private static final Logger log = LoggerFactory.getLogger(CrmActivityService.class);

    private final CrmActivityRepository activityRepository;

    public CrmActivityService(CrmActivityRepository activityRepository) {
        this.activityRepository = activityRepository;
    }

    @Transactional
    public ActivityDto recordActivity(CreateActivityRequest request, UUID performedBy) {
        CrmActivity activity = new CrmActivity();
        activity.setLeadId(request.getLeadId());
        activity.setCustomerId(request.getCustomerId());
        activity.setActivityType(request.getActivityType());
        activity.setTitle(request.getTitle());
        activity.setDescription(request.getDescription());
        activity.setPerformedBy(performedBy);
        activity.setMetadata(request.getMetadata());

        CrmActivity saved = activityRepository.save(activity);
        log.info("Recorded CRM activity {} of type {} for lead {}", saved.getId(), saved.getActivityType(), saved.getLeadId());
        return ActivityDto.fromEntity(saved);
    }

    @Transactional
    public ActivityDto recordSystemActivity(UUID leadId, UUID customerId, CrmActivityType type, String title, String description) {
        CrmActivity activity = new CrmActivity(leadId, customerId, type, title, description, null);
        CrmActivity saved = activityRepository.save(activity);
        return ActivityDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<ActivityDto> getActivitiesByLeadId(UUID leadId) {
        return activityRepository.findByLeadIdOrderByCreatedAtDesc(leadId)
                .stream()
                .map(ActivityDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<ActivityDto> getActivitiesByLeadId(UUID leadId, Pageable pageable) {
        return activityRepository.findByLeadIdOrderByCreatedAtDesc(leadId, pageable)
                .map(ActivityDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public List<ActivityDto> getActivitiesByCustomerId(UUID customerId) {
        return activityRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(ActivityDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<ActivityDto> getActivitiesByCustomerId(UUID customerId, Pageable pageable) {
        return activityRepository.findByCustomerIdOrderByCreatedAtDesc(customerId, pageable)
                .map(ActivityDto::fromEntity);
    }
}
