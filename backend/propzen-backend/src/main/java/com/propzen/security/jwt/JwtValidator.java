package com.propzen.security.jwt;

/**
 * Interface for validating Supabase-issued Bearer JWTs.
 */
public interface JwtValidator {

    /**
     * Cryptographically validates the provided JWT string and extracts its claims.
     *
     * @param token Bearer token string (without 'Bearer ' prefix)
     * @return Validated SupabaseUserClaims
     * @throws JwtValidationException if token signature is invalid, expired, or malformed
     */
    SupabaseUserClaims validateToken(String token) throws JwtValidationException;
}
