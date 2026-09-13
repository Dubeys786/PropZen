package com.propzen.exception;

import org.springframework.http.HttpStatus;

/**
 * Thrown when an authenticated user attempts to access a resource they do not own
 * or do not have sufficient role permissions to access.
 */
public class ForbiddenException extends ApiException {

    public ForbiddenException(String message) {
        super(message, HttpStatus.FORBIDDEN, ErrorCode.FORBIDDEN);
    }
}
