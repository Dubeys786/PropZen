package com.propzen.service.model;

import java.util.Set;

public enum PartnerStatus {
    PENDING,
    UNDER_REVIEW,
    APPROVED,
    REJECTED,
    SUSPENDED,
    INACTIVE;

    public boolean canTransitionTo(PartnerStatus target) {
        if (this == target) {
            return true;
        }

        return switch (this) {
            case PENDING -> target == UNDER_REVIEW || target == APPROVED || target == REJECTED;
            case UNDER_REVIEW -> target == APPROVED || target == REJECTED || target == PENDING;
            case APPROVED -> target == SUSPENDED || target == INACTIVE;
            case SUSPENDED -> target == APPROVED || target == INACTIVE;
            case REJECTED -> target == UNDER_REVIEW;
            case INACTIVE -> target == APPROVED || target == UNDER_REVIEW;
        };
    }
}
