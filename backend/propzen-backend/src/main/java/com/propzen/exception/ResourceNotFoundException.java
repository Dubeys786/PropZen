package com.propzen.exception;

import org.springframework.http.HttpStatus;

/**
 * Thrown when a requested resource (property, enquiry, user, etc.) does not exist.
 */
public class ResourceNotFoundException extends ApiException {

    public ResourceNotFoundException(String message) {
        super(message, HttpStatus.NOT_FOUND, ErrorCode.RESOURCE_NOT_FOUND);
    }

    public ResourceNotFoundException(String resourceName, Object resourceId) {
        super(String.format("%s with identifier '%s' was not found", resourceName, resourceId),
                HttpStatus.NOT_FOUND, ErrorCode.RESOURCE_NOT_FOUND);
    }
}
