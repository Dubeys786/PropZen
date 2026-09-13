package com.propzen.exception;

import org.springframework.http.HttpStatus;

import java.util.UUID;

public class UserNotFoundException extends ApiException {

    public UserNotFoundException(UUID userId) {
        super("User with identifier '" + userId + "' was not found", HttpStatus.NOT_FOUND, ErrorCode.USER_NOT_FOUND);
    }

    public UserNotFoundException(String message) {
        super(message, HttpStatus.NOT_FOUND, ErrorCode.USER_NOT_FOUND);
    }
}
