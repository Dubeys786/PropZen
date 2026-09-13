package com.propzen.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import org.slf4j.MDC;

import java.io.Serializable;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * Enterprise standard response wrapper across all PropZen REST APIs.
 *
 * @param <T> Response body payload type
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> implements Serializable {

    private boolean success;
    private T data;
    private ErrorDetail error;
    private String message;
    private String timestamp;
    private String requestId;

    public ApiResponse() {
        this.timestamp = DateTimeFormatter.ISO_INSTANT.format(Instant.now());
        this.requestId = resolveRequestId();
    }

    public ApiResponse(boolean success, T data, String message) {
        this();
        this.success = success;
        this.data = data;
        this.message = message;
    }

    public ApiResponse(boolean success, ErrorDetail error) {
        this();
        this.success = success;
        this.error = error;
        this.message = error != null ? error.getMessage() : null;
    }

    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(true, data, "Request successful");
    }

    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(true, data, message);
    }

    public static <T> ApiResponse<T> ok(T data) {
        return success(data);
    }

    public static <T> ApiResponse<T> ok(T data, String message) {
        return success(data, message);
    }

    public static <T> ApiResponse<T> error(String code, String message) {
        return new ApiResponse<>(false, new ErrorDetail(code, message));
    }

    public static <T> ApiResponse<T> error(String code, String message, Object details) {
        return new ApiResponse<>(false, new ErrorDetail(code, message, details));
    }

    private static String resolveRequestId() {
        String reqId = MDC.get("requestId");
        return (reqId != null && !reqId.isBlank()) ? reqId : UUID.randomUUID().toString();
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public ErrorDetail getError() {
        return error;
    }

    public void setError(ErrorDetail error) {
        this.error = error;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }
}
