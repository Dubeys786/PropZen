package com.propzen.crm.controller;

import com.propzen.common.response.ApiResponse;
import com.propzen.crm.dto.CreateTaskRequest;
import com.propzen.crm.dto.CrmTaskDto;
import com.propzen.crm.dto.UpdateTaskRequest;
import com.propzen.crm.service.CrmTaskService;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/crm/tasks")
@Tag(name = "CRM Task Management", description = "Endpoints for managing internal tasks and assignments")
public class CrmTaskController {

    private final CrmTaskService taskService;
    private final CurrentUserService currentUserService;

    public CrmTaskController(CrmTaskService taskService, CurrentUserService currentUserService) {
        this.taskService = taskService;
        this.currentUserService = currentUserService;
    }

    @PostMapping
    @Operation(summary = "Create an internal CRM task")
    public ResponseEntity<ApiResponse<CrmTaskDto>> createTask(@Valid @RequestBody CreateTaskRequest request) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        if (request.getAssignedTo() == null) {
            request.setAssignedTo(actor.getUserId());
        }
        CrmTaskDto task = taskService.createTask(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(task, "Task created successfully"));
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Update an existing task")
    public ResponseEntity<ApiResponse<CrmTaskDto>> updateTask(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTaskRequest request) {
        CrmTaskDto updated = taskService.updateTask(id, request);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Task updated successfully"));
    }

    @PatchMapping("/{id}/complete")
    @Operation(summary = "Mark task as completed")
    public ResponseEntity<ApiResponse<CrmTaskDto>> completeTask(@PathVariable UUID id) {
        CrmTaskDto completed = taskService.completeTask(id);
        return ResponseEntity.ok(ApiResponse.ok(completed, "Task marked as completed"));
    }

    @GetMapping
    @Operation(summary = "List CRM tasks assigned to the caller")
    public ResponseEntity<ApiResponse<Page<CrmTaskDto>>> getTasks(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        AuthenticatedUser actor = currentUserService.getRequiredCurrentUser();
        Page<CrmTaskDto> tasks = taskService.getTasksByAssignedTo(actor.getUserId(), PageRequest.of(page, size));
        return ResponseEntity.ok(ApiResponse.ok(tasks, "Tasks retrieved successfully"));
    }
}
