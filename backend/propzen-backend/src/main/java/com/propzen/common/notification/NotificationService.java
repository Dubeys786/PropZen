package com.propzen.common.notification;

import com.propzen.common.response.PageResponse;
import com.propzen.exception.ResourceNotFoundException;
import com.propzen.security.user.AuthenticatedUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @Transactional
    public NotificationDto createNotification(UUID userId, NotificationType type, String title, String message, String metadata) {
        Notification notification = new Notification(userId, type, title, message, metadata);
        Notification saved = notificationRepository.save(notification);
        log.info("Created in-app notification {} for user {}", saved.getId(), userId);
        return NotificationDto.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public PageResponse<NotificationDto> getUserNotifications(AuthenticatedUser user, Pageable pageable) {
        Page<Notification> page = notificationRepository.findByUserIdOrderBySentAtDesc(user.getUserId(), pageable);
        return PageResponse.from(page.map(NotificationDto::fromEntity));
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(AuthenticatedUser user) {
        return notificationRepository.countByUserIdAndStatus(user.getUserId(), NotificationStatus.SENT);
    }

    @Transactional
    public NotificationDto markAsRead(UUID id, AuthenticatedUser user) {
        Notification notification = notificationRepository.findByIdAndUserId(id, user.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Notification", id));

        notification.setStatus(NotificationStatus.READ);
        notification.setReadAt(OffsetDateTime.now());
        Notification updated = notificationRepository.save(notification);
        return NotificationDto.fromEntity(updated);
    }

    @Transactional
    public int markAllAsRead(AuthenticatedUser user) {
        return notificationRepository.markAllAsRead(user.getUserId(), NotificationStatus.READ, OffsetDateTime.now());
    }
}
