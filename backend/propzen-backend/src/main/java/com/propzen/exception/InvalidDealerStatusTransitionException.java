package com.propzen.exception;

import com.propzen.dealer.model.DealerStatus;
import org.springframework.http.HttpStatus;

public class InvalidDealerStatusTransitionException extends ApiException {

    public InvalidDealerStatusTransitionException(DealerStatus currentStatus, DealerStatus requestedStatus) {
        super("Cannot transition dealer status from " + currentStatus + " to " + requestedStatus,
                HttpStatus.BAD_REQUEST, ErrorCode.INVALID_DEALER_STATUS_TRANSITION);
    }
}
