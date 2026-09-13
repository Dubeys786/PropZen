package com.propzen.exception;

import org.springframework.http.HttpStatus;

import java.util.UUID;

public class DealerNotFoundException extends ApiException {

    public DealerNotFoundException(UUID dealerId) {
        super("Dealer profile with identifier '" + dealerId + "' was not found", HttpStatus.NOT_FOUND, ErrorCode.DEALER_NOT_FOUND);
    }

    public DealerNotFoundException(String message) {
        super(message, HttpStatus.NOT_FOUND, ErrorCode.DEALER_NOT_FOUND);
    }
}
