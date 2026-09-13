package com.propzen.crm.model;

/**
 * Status of an event in the transactional outbox table.
 */
public enum OutboxStatus {
    PENDING,
    PROCESSING,
    SENT,
    FAILED,
    DEAD_LETTER
}
