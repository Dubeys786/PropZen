package com.propzen.service.model;

public enum ServiceRequestStatus {
    NEW,
    PENDING_ASSIGNMENT,
    ASSIGNED,
    ACCEPTED,
    IN_PROGRESS,
    ON_HOLD,
    COMPLETED,
    CANCELLED,
    REJECTED;

    public boolean canTransitionTo(ServiceRequestStatus target) {
        if (this == target) {
            return true;
        }

        return switch (this) {
            case NEW -> target == PENDING_ASSIGNMENT || target == ASSIGNED || target == CANCELLED;
            case PENDING_ASSIGNMENT -> target == ASSIGNED || target == CANCELLED;
            case ASSIGNED -> target == ACCEPTED || target == REJECTED || target == PENDING_ASSIGNMENT || target == CANCELLED;
            case ACCEPTED -> target == IN_PROGRESS || target == ON_HOLD || target == CANCELLED;
            case IN_PROGRESS -> target == ON_HOLD || target == COMPLETED || target == CANCELLED;
            case ON_HOLD -> target == IN_PROGRESS || target == CANCELLED;
            case COMPLETED, CANCELLED, REJECTED -> false;
        };
    }
}
