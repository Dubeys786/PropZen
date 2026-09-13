package com.propzen.common.notification;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

public class NotificationDto implements Serializable {

    private UUID id;
    private UUID userId;
    private NotificationType type;
    private String channel;
    private String title;
    private String message;
    private NotificationStatus status;
    private OffsetDateTime sentAt;
    private OffsetDateTime readAt;
    private String metadata;

    public NotificationDto() {
    }

    public static NotificationDto fromEntity(Notification entity) {
        if (entity == null) return null;
        NotificationDto dto = new NotificationDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUserId());
        dto.setType(entity.getType());
        dto.setChannel(entity.getChannel());
        dto.setTitle(entity.getTitle());
        dto.setMessage(entity.getMessage());
        dto.setStatus(entity.getStatus());
        dto.setSentAt(entity.getSentAt());
        dto.setReadAt(entity.getReadAt());
        dto.setMetadata(entity.getMetadata());
        return dto;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public NotificationType getType() {
        return type;
    }

    public void setType(NotificationType type) {
        this.type = type;
    }

    public String getChannel() {
        return channel;
    }

    public void setChannel(String channel) {
        this.channel = channel;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public NotificationStatus getStatus() {
        return status;
    }

    public void setStatus(NotificationStatus status) {
        this.status = status;
    }

    public OffsetDateTime getSentAt() {
        return sentAt;
    }

    public void setSentAt(OffsetDateTime sentAt) {
        this.sentAt = sentAt;
    }

    public OffsetDateTime getReadAt() {
        return readAt;
    }

    public void setReadAt(OffsetDateTime readAt) {
        this.readAt = readAt;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
}
