package com.propzen.exception;

import org.springframework.http.HttpStatus;

import java.util.UUID;

/**
 * Thrown when a requested property cannot be found.
 */
public class PropertyNotFoundException extends ApiException {

    public PropertyNotFoundException(UUID propertyId) {
        super("Property with ID " + propertyId + " not found", HttpStatus.NOT_FOUND, ErrorCode.PROPERTY_NOT_FOUND);
    }

    public PropertyNotFoundException(String message) {
        super(message, HttpStatus.NOT_FOUND, ErrorCode.PROPERTY_NOT_FOUND);
    }
}
