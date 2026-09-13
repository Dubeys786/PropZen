package com.propzen.common.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.io.Serializable;

/**
 * Standardized error payload representation.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorDetail implements Serializable {

    private String code;
    private String message;
    private Object details;

    public ErrorDetail() {
    }

    public ErrorDetail(String code, String message) {
        this.code = code;
        this.message = message;
    }

    public ErrorDetail(String code, String message, Object details) {
        this.code = code;
        this.message = message;
        this.details = details;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Object getDetails() {
        return details;
    }

    public void setDetails(Object details) {
        this.details = details;
    }
}
