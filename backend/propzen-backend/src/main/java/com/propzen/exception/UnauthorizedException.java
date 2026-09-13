package com.propzen.exception;

import org.springframework.http.HttpStatus;

/**
 * Thrown when unauthenticated requests access secured resources.
 */
public class UnauthorizedException extends ApiException {

    public UnauthorizedException(String message) {
        super(message, HttpStatus.UNAUTHORIZED, ErrorCode.UNAUTHORIZED);
    }
}
