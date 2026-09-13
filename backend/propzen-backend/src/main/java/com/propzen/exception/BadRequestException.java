package com.propzen.exception;

import org.springframework.http.HttpStatus;

/**
 * Thrown when client supplies malformed parameters or invalid business payloads.
 */
public class BadRequestException extends ApiException {

    public BadRequestException(String message) {
        super(message, HttpStatus.BAD_REQUEST, ErrorCode.BAD_REQUEST);
    }

    public BadRequestException(String message, Object details) {
        super(message, HttpStatus.BAD_REQUEST, ErrorCode.BAD_REQUEST, details);
    }
}
