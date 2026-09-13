package com.propzen.exception;

/**
 * Standardized PropZen error codes.
 */
public enum ErrorCode {
    VALIDATION_FAILED("VALIDATION_FAILED", "Request validation failed"),
    BAD_REQUEST("BAD_REQUEST", "Bad request syntax or invalid parameters"),
    UNAUTHORIZED("UNAUTHORIZED", "Authentication required or credentials invalid"),
    FORBIDDEN("FORBIDDEN", "Insufficient permissions to access this resource"),
    RESOURCE_NOT_FOUND("RESOURCE_NOT_FOUND", "Requested resource was not found"),
    METHOD_NOT_ALLOWED("METHOD_NOT_ALLOWED", "HTTP method not supported for this endpoint"),
    CONFLICT("CONFLICT", "Resource conflict or duplicate detected"),
    INTERNAL_SERVER_ERROR("INTERNAL_SERVER_ERROR", "An unexpected internal error occurred"),
    DATABASE_ERROR("DATABASE_ERROR", "A database persistence error occurred"),
    EXTERNAL_SERVICE_ERROR("EXTERNAL_SERVICE_ERROR", "An external service integration failed"),

    // Phase 4 Domain Errors
    USER_NOT_FOUND("USER_NOT_FOUND", "User record was not found"),
    DEALER_NOT_FOUND("DEALER_NOT_FOUND", "Dealer profile was not found"),
    DEALER_ALREADY_EXISTS("DEALER_ALREADY_EXISTS", "A dealer profile already exists for this user"),
    DEALER_APPLICATION_PENDING("DEALER_APPLICATION_PENDING", "A dealer application is currently pending review"),
    INVALID_DEALER_STATUS_TRANSITION("INVALID_DEALER_STATUS_TRANSITION", "Requested dealer status transition is invalid"),
    PROFILE_UPDATE_FORBIDDEN("PROFILE_UPDATE_FORBIDDEN", "Attempt to modify unauthorized profile fields"),
    INSUFFICIENT_PERMISSION("INSUFFICIENT_PERMISSION", "You do not have permission to perform this action"),

    // Phase 5 Domain Errors
    PROPERTY_NOT_FOUND("PROPERTY_NOT_FOUND", "Property record was not found"),
    PROPERTY_ACCESS_DENIED("PROPERTY_ACCESS_DENIED", "You do not have permission to access or modify this property"),
    PROPERTY_NOT_EDITABLE("PROPERTY_NOT_EDITABLE", "Property cannot be modified in its current state"),
    PROPERTY_INVALID_STATUS("PROPERTY_INVALID_STATUS", "Invalid property lifecycle status transition"),
    PROPERTY_DUPLICATE_WARNING("PROPERTY_DUPLICATE_WARNING", "Potential duplicate property detected for this dealer"),
    INVALID_PROPERTY_FILTER("INVALID_PROPERTY_FILTER", "Provided search filter criteria is invalid"),
    INVALID_PRICE_RANGE("INVALID_PRICE_RANGE", "Invalid price range specified"),
    INVALID_AREA_RANGE("INVALID_AREA_RANGE", "Invalid area range specified"),

    // Phase 6 CRM Domain Errors
    LEAD_NOT_FOUND("LEAD_NOT_FOUND", "CRM lead was not found"),
    LEAD_ACCESS_DENIED("LEAD_ACCESS_DENIED", "Access to this CRM lead is denied"),
    CAMPAIGN_NOT_FOUND("CAMPAIGN_NOT_FOUND", "Campaign was not found"),
    CAMPAIGN_ALREADY_EXECUTED("CAMPAIGN_ALREADY_EXECUTED", "Campaign has already been dispatched"),
    INVALID_LEAD_STATUS("INVALID_LEAD_STATUS", "Invalid lead status transition"),

    // Phase 7 Service Management Domain Errors
    DUPLICATE_RESOURCE("DUPLICATE_RESOURCE", "A duplicate resource already exists"),
    SERVICE_CATEGORY_NOT_FOUND("SERVICE_CATEGORY_NOT_FOUND", "Service category was not found"),
    SERVICE_PARTNER_NOT_FOUND("SERVICE_PARTNER_NOT_FOUND", "Service partner profile was not found"),
    SERVICE_REQUEST_NOT_FOUND("SERVICE_REQUEST_NOT_FOUND", "Service request was not found");

    private final String code;
    private final String defaultMessage;

    ErrorCode(String code, String defaultMessage) {
        this.code = code;
        this.defaultMessage = defaultMessage;
    }

    public String getCode() {
        return code;
    }

    public String getDefaultMessage() {
        return defaultMessage;
    }
}
