package com.propzen.exception;

import org.springframework.http.HttpStatus;

/**
 * Domain business logic exception with customizable error code and HTTP status.
 */
public class BusinessException extends ApiException {

    public BusinessException(ErrorCode errorCode, String message) {
        super(message, HttpStatus.BAD_REQUEST, errorCode);
    }

    public BusinessException(ErrorCode errorCode, String message, HttpStatus status) {
        super(message, status, errorCode);
    }
}
