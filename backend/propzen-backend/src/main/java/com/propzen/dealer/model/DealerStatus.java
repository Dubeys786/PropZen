package com.propzen.dealer.model;

/**
 * Lifecycle status of a Dealer Profile in PropZen.
 */
public enum DealerStatus {
    PENDING,
    UNDER_REVIEW,
    APPROVED,
    REJECTED,
    SUSPENDED;

    public boolean canTransitionTo(DealerStatus next) {
        if (this == next) return true;
        return switch (this) {
            case PENDING -> next == UNDER_REVIEW || next == APPROVED || next == REJECTED;
            case UNDER_REVIEW -> next == APPROVED || next == REJECTED || next == PENDING;
            case APPROVED -> next == SUSPENDED || next == UNDER_REVIEW;
            case REJECTED -> next == UNDER_REVIEW || next == PENDING;
            case SUSPENDED -> next == APPROVED || next == UNDER_REVIEW || next == REJECTED;
        };
    }
}
