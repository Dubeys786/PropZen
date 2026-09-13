package com.propzen.security.jwt;

import org.springframework.security.core.AuthenticationException;

/**
 * Thrown when a Supabase JWT fails signature verification, is expired, or contains invalid claims.
 */
public class JwtValidationException extends AuthenticationException {

    public JwtValidationException(String message) {
        super(message);
    }

    public JwtValidationException(String message, Throwable cause) {
        super(message, cause);
    }
}
