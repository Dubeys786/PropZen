package com.propzen.exception;

import org.springframework.http.HttpStatus;

public class OwnershipDeniedException extends ApiException {

    public OwnershipDeniedException(String message) {
        super(message, HttpStatus.FORBIDDEN, ErrorCode.INSUFFICIENT_PERMISSION);
    }
}
