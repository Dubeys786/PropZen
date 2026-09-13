package com.propzen.crm.service;

import com.propzen.crm.dto.CreateTaskRequest;
import com.propzen.crm.dto.CrmTaskDto;
import com.propzen.crm.dto.UpdateTaskRequest;
import com.propzen.crm.entity.CrmTask;
import com.propzen.crm.model.TaskStatus;
import com.propzen.crm.repository.CrmTaskRepository;
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
public class CrmTaskService {

    private static final Logger log = LoggerFactory.getLogger(CrmTaskService.class);

    private final CrmTaskRepository taskRepository;

    public CrmTaskService(CrmTaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }

    @Transactional
    public CrmTaskDto createTask(CreateTaskRequest request) {
        CrmTask task = new CrmTask(
                request.getTitle(),
                request.getDescription(),
                request.getAssignedTo(),
                request.getLeadId(),
                request.getCustomerId(),
                request.getPriority(),
                request.getDueAt()
        );

        CrmTask saved = taskRepository.save(task);
        log.info("Created CRM task {} assigned to {}", saved.getId(), saved.getAssignedTo());
        return CrmTaskDto.fromEntity(saved);
    }

    @Transactional
    public CrmTaskDto updateTask(UUID taskId, UpdateTaskRequest request) {
        CrmTask task = taskRepository.findById(taskId)
                .orElseThrow(() -> new NoSuchElementException("Task not found: " + taskId));

        if (request.getTitle() != null && !request.getTitle().isBlank()) {
            task.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }
        if (request.getAssignedTo() != null) {
            task.setAssignedTo(request.getAssignedTo());
        }
        if (request.getPriority() != null) {
            task.setPriority(request.getPriority());
        }
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
            if (request.getStatus() == TaskStatus.COMPLETED) {
                task.setCompletedAt(OffsetDateTime.now());
            }
        }
        if (request.getDueAt() != null) {
            task.setDueAt(request.getDueAt());
        }

        CrmTask saved = taskRepository.save(task);
        return CrmTaskDto.fromEntity(saved);
    }

    @Transactional
    public CrmTaskDto completeTask(UUID taskId) {
        CrmTask task = taskRepository.findById(taskId)
                .orElseThrow(() -> new NoSuchElementException("Task not found: " + taskId));

        task.setStatus(TaskStatus.COMPLETED);
        task.setCompletedAt(OffsetDateTime.now());
        CrmTask saved = taskRepository.save(task);
        return CrmTaskDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<CrmTaskDto> getTasksByAssignedTo(UUID assignedTo) {
        return taskRepository.findByAssignedToOrderByDueAtAsc(assignedTo)
                .stream()
                .map(CrmTaskDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public Page<CrmTaskDto> getTasksByAssignedTo(UUID assignedTo, Pageable pageable) {
        return taskRepository.findByAssignedToOrderByDueAtAsc(assignedTo, pageable)
                .map(CrmTaskDto::fromEntity);
    }

    @Transactional(readOnly = true)
    public List<CrmTaskDto> getTasksByLeadId(UUID leadId) {
        return taskRepository.findByLeadIdOrderByCreatedAtDesc(leadId)
                .stream()
                .map(CrmTaskDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CrmTaskDto> getTasksByCustomerId(UUID customerId) {
        return taskRepository.findByCustomerIdOrderByCreatedAtDesc(customerId)
                .stream()
                .map(CrmTaskDto::fromEntity)
                .collect(Collectors.toList());
    }
}
