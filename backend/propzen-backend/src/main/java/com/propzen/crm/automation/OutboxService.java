package com.propzen.crm.automation;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.crm.entity.CrmOutboxEvent;
import com.propzen.crm.repository.CrmOutboxEventRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Service for publishing domain events into the Transactional Outbox.
 * Guarantees zero message loss during database transactions.
 */
@Service
public class OutboxService {

    private static final Logger log = LoggerFactory.getLogger(OutboxService.class);

    private final CrmOutboxEventRepository outboxRepository;
    private final ObjectMapper objectMapper;

    public OutboxService(CrmOutboxEventRepository outboxRepository, ObjectMapper objectMapper) {
        this.outboxRepository = outboxRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public CrmOutboxEvent publishEvent(String eventType, String aggregateType, UUID aggregateId, Object payload) {
        String payloadJson = "{}";
        try {
            if (payload != null) {
                if (payload instanceof String s) {
                    payloadJson = s;
                } else {
                    payloadJson = objectMapper.writeValueAsString(payload);
                }
            }
        } catch (Exception e) {
            log.error("Failed to serialize outbox event payload: {}", e.getMessage(), e);
            payloadJson = "{\"error\":\"Serialization failed\"}";
        }

        CrmOutboxEvent event = new CrmOutboxEvent(eventType, aggregateType, aggregateId, payloadJson);
        CrmOutboxEvent saved = outboxRepository.save(event);
        log.info("Enqueued transactional outbox event {} of type {} for aggregate {}", saved.getId(), eventType, aggregateId);
        return saved;
    }
}
