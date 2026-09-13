package com.propzen.common.notification;

import com.propzen.common.response.ApiResponse;
import com.propzen.common.response.PageResponse;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.user.CurrentUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "In-App Notifications", description = "Endpoints for retrieving and acknowledging user in-app notifications")
@SecurityRequirement(name = "BearerAuth")
public class NotificationController {

    private final NotificationService notificationService;
    private final CurrentUserService currentUserService;

    public NotificationController(NotificationService notificationService, CurrentUserService currentUserService) {
        this.notificationService = notificationService;
        this.currentUserService = currentUserService;
    }

    @GetMapping
    @Operation(summary = "Get paginated in-app notifications for authenticated user")
    public ResponseEntity<ApiResponse<PageResponse<NotificationDto>>> getNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        Pageable pageable = PageRequest.of(Math.max(0, page), Math.min(100, Math.max(1, size)));
        PageResponse<NotificationDto> result = notificationService.getUserNotifications(user, pageable);
        return ResponseEntity.ok(ApiResponse.ok(result, "Notifications retrieved"));
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get count of unread notifications for authenticated user")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount() {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        long count = notificationService.getUnreadCount(user);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("unreadCount", count), "Unread count retrieved"));
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark single notification as read")
    public ResponseEntity<ApiResponse<NotificationDto>> markRead(@PathVariable UUID id) {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        NotificationDto updated = notificationService.markAsRead(id, user);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Notification marked as read"));
    }

    @PatchMapping("/read-all")
    @Operation(summary = "Mark all notifications as read for current user")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> markAllRead() {
        AuthenticatedUser user = currentUserService.getRequiredCurrentUser();
        int count = notificationService.markAllAsRead(user);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("markedCount", count), "All notifications marked as read"));
    }
}
