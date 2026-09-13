package com.propzen.exception;

import org.springframework.http.HttpStatus;

import java.util.UUID;

public class DealerAlreadyExistsException extends ApiException {

    public DealerAlreadyExistsException(UUID userId) {
        super("A dealer profile or pending application already exists for user '" + userId + "'", HttpStatus.CONFLICT, ErrorCode.DEALER_ALREADY_EXISTS);
    }

    public DealerAlreadyExistsException(String message, ErrorCode errorCode) {
        super(message, HttpStatus.CONFLICT, errorCode);
    }
}
