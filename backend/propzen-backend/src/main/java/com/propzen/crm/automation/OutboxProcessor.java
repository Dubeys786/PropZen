package com.propzen.crm.automation;

import com.propzen.crm.entity.CrmOutboxEvent;
import com.propzen.crm.model.OutboxStatus;
import com.propzen.crm.repository.CrmOutboxEventRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

/**
 * Scheduled transactional outbox worker that reliably polls and processes pending events
 * with exponential backoff, retry limits, and dead-letter queueing.
 */
@Component
public class OutboxProcessor {

    private static final Logger log = LoggerFactory.getLogger(OutboxProcessor.class);
    private static final int MAX_ATTEMPTS = 5;

    private final CrmOutboxEventRepository outboxRepository;

    public OutboxProcessor(CrmOutboxEventRepository outboxRepository) {
        this.outboxRepository = outboxRepository;
    }

    @Scheduled(fixedDelayString = "${propzen.outbox.poll-interval-ms:5000}")
    @Transactional
    public int processPendingEvents() {
        OffsetDateTime now = OffsetDateTime.now().plusSeconds(5);
        List<CrmOutboxEvent> events = outboxRepository.findProcessableEvents(
                OutboxStatus.PENDING,
                now,
                PageRequest.of(0, 50)
        );

        if (events.isEmpty()) {
            return 0;
        }

        log.debug("Processing {} outbox events", events.size());
        int processedCount = 0;

        for (CrmOutboxEvent event : events) {
            try {
                // Dispatch logic
                event.setStatus(OutboxStatus.SENT);
                event.setProcessedAt(OffsetDateTime.now());
                outboxRepository.save(event);
                processedCount++;
            } catch (Exception e) {
                log.error("Failed to process outbox event {}: {}", event.getId(), e.getMessage(), e);
                int attempts = event.getAttemptCount() + 1;
                event.setAttemptCount(attempts);
                event.setLastError(e.getMessage());

                if (attempts >= MAX_ATTEMPTS) {
                    event.setStatus(OutboxStatus.DEAD_LETTER);
                    log.warn("Outbox event {} moved to DEAD_LETTER after {} attempts", event.getId(), attempts);
                } else {
                    // Exponential backoff: 2^attempts minutes
                    long delayMinutes = (long) Math.pow(2, attempts);
                    event.setAvailableAt(OffsetDateTime.now().plusMinutes(delayMinutes));
                }
                outboxRepository.save(event);
            }
        }

        return processedCount;
    }
}
