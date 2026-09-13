package com.propzen.common.audit;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

/**
 * Structured audit logging service for compliance and tracking of security-sensitive operations.
 * Persists audit events to public.audit_logs and emits to SLF4J AUDIT logger.
 */
@Service
public class AuditLogService {

    private static final Logger auditLog = LoggerFactory.getLogger("AUDIT");

    private final AuditLogRepository auditLogRepository;

    public AuditLogService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public void logAction(UUID actorUserId, String action, String target, String details) {
        String requestId = MDC.get("requestId");
        if (requestId == null) {
            requestId = "SYSTEM";
        }

        auditLog.info("AUDIT_EVENT [actorUserId={}] [action={}] [target={}] [timestamp={}] [requestId={}] - {}",
                actorUserId != null ? actorUserId : "ANONYMOUS",
                action,
                target,
                Instant.now(),
                requestId,
                details != null ? details : ""
        );

        try {
            String targetType = null;
            String targetId = target;
            if (target != null && target.contains("/")) {
                String[] parts = target.split("/", 2);
                targetType = parts[0];
                targetId = parts[1];
            }
            AuditLog entity = new AuditLog(actorUserId, action, targetType, targetId, requestId, details);
            auditLogRepository.save(entity);
        } catch (Exception e) {
            auditLog.warn("Failed to persist audit log entity: {}", e.getMessage());
        }
    }
}
