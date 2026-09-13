package com.propzen.security.jwt;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSVerifier;
import com.nimbusds.jose.crypto.ECDSAVerifier;
import com.nimbusds.jose.crypto.MACVerifier;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.ECKey;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

/**
 * Enterprise cryptographic validator for Supabase-issued Bearer JWTs.
 * Supports public JWKS verification (ES256/RS256) and optional symmetric HMAC (HS256).
 */
@Component
public class SupabaseJwtValidator implements JwtValidator {

    private static final Logger log = LoggerFactory.getLogger(SupabaseJwtValidator.class);

    @Value("${propzen.supabase.url:https://eemxylswyvhsyzllcsnp.supabase.co}")
    private String supabaseUrl;

    @Value("${propzen.supabase.jwt.jwks-url:https://eemxylswyvhsyzllcsnp.supabase.co/auth/v1/.well-known/jwks.json}")
    private String jwksUrl;

    @Value("${propzen.supabase.jwt.secret:}")
    private String jwtSecret;

    @Value("${propzen.supabase.jwt.validate-audience:true}")
    private boolean validateAudience;

    private JWKSet cachedJwkSet;
    private long jwkSetLastFetched = 0;
    private static final long JWK_CACHE_TTL_MS = 3600000; // 1 hour

    public SupabaseJwtValidator() {
    }

    /**
     * Testing constructor allowing custom JWKSet injection.
     */
    public SupabaseJwtValidator(JWKSet testJwkSet, String jwtSecret, boolean validateAudience) {
        this.cachedJwkSet = testJwkSet;
        this.jwtSecret = jwtSecret != null ? jwtSecret : "";
        this.validateAudience = validateAudience;
    }

    @Override
    public SupabaseUserClaims validateToken(String token) throws JwtValidationException {
        if (token == null || token.isBlank()) {
            throw new JwtValidationException("Bearer token must not be null or blank");
        }

        try {
            SignedJWT signedJWT = SignedJWT.parse(token);
            JWSAlgorithm algorithm = signedJWT.getHeader().getAlgorithm();

            // 1. Signature Verification
            boolean signatureValid = verifySignature(signedJWT, algorithm);
            if (!signatureValid) {
                throw new JwtValidationException("Cryptographic signature verification failed");
            }

            // 2. Claims Validation
            JWTClaimsSet claims = signedJWT.getJWTClaimsSet();
            Date now = new Date();

            // Expiration
            Date exp = claims.getExpirationTime();
            if (exp == null) {
                throw new JwtValidationException("Token is missing expiration claim ('exp')");
            }
            if (exp.before(now)) {
                throw new JwtValidationException("Token has expired at " + exp);
            }

            // Not Before
            Date nbf = claims.getNotBeforeTime();
            if (nbf != null && nbf.after(now)) {
                throw new JwtValidationException("Token is not valid before " + nbf);
            }

            // Audience Check (Supabase tokens normally specify aud='authenticated')
            if (validateAudience && claims.getAudience() != null && !claims.getAudience().isEmpty()) {
                if (!claims.getAudience().contains("authenticated")) {
                    log.warn("Token audience {} did not contain expected 'authenticated'", claims.getAudience());
                }
            }

            // 3. User Identity Resolution
            String subject = claims.getSubject();
            if (subject == null || subject.isBlank()) {
                throw new JwtValidationException("Token is missing authoritative subject claim ('sub')");
            }

            UUID userId;
            try {
                userId = UUID.fromString(subject);
            } catch (IllegalArgumentException ex) {
                throw new JwtValidationException("Token subject claim is not a valid UUID: " + subject);
            }

            String email = claims.getStringClaim("email");
            String phone = claims.getStringClaim("phone");
            String role = claims.getStringClaim("role");

            Map<String, Object> appMetadata = claims.getJSONObjectClaim("app_metadata");
            Map<String, Object> userMetadata = claims.getJSONObjectClaim("user_metadata");

            Instant issuedAt = claims.getIssueTime() != null ? claims.getIssueTime().toInstant() : Instant.now();
            Instant expiresAt = exp.toInstant();

            return new SupabaseUserClaims(
                    userId,
                    email,
                    phone,
                    role,
                    appMetadata,
                    userMetadata,
                    issuedAt,
                    expiresAt
            );

        } catch (JwtValidationException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Failed to parse and validate JWT: {}", e.getMessage());
            throw new JwtValidationException("Malformed or unparseable JWT: " + e.getMessage(), e);
        }
    }

    private boolean verifySignature(SignedJWT signedJWT, JWSAlgorithm algorithm) throws Exception {
        // Option A: If HMAC algorithm (HS256) and secret is provided
        if (JWSAlgorithm.Family.HMAC_SHA.contains(algorithm)) {
            if (jwtSecret == null || jwtSecret.isBlank()) {
                throw new JwtValidationException("Symmetric token received but SUPABASE_JWT_SECRET is not configured");
            }
            JWSVerifier verifier = new MACVerifier(jwtSecret.getBytes(StandardCharsets.UTF_8));
            return signedJWT.verify(verifier);
        }

        // Option B: Asymmetric (ES256, RS256) using Supabase JWKS
        JWKSet jwkSet = getJwkSet();
        if (jwkSet == null) {
            throw new JwtValidationException("Public JWKS is unavailable for signature verification");
        }

        String kid = signedJWT.getHeader().getKeyID();
        JWK matchingKey = null;

        if (kid != null) {
            matchingKey = jwkSet.getKeyByKeyId(kid);
        } else if (!jwkSet.getKeys().isEmpty()) {
            matchingKey = jwkSet.getKeys().get(0);
        }

        if (matchingKey == null) {
            throw new JwtValidationException("No matching public key found in Supabase JWKS for kid: " + kid);
        }

        JWSVerifier verifier;
        if (matchingKey instanceof ECKey ecKey) {
            verifier = new ECDSAVerifier(ecKey.toECPublicKey());
        } else if (matchingKey instanceof RSAKey rsaKey) {
            verifier = new RSASSAVerifier(rsaKey.toRSAPublicKey());
        } else {
            throw new JwtValidationException("Unsupported key type in Supabase JWKS: " + matchingKey.getKeyType());
        }

        return signedJWT.verify(verifier);
    }

    private synchronized JWKSet getJwkSet() {
        long now = System.currentTimeMillis();
        if (cachedJwkSet != null && (now - jwkSetLastFetched < JWK_CACHE_TTL_MS)) {
            return cachedJwkSet;
        }

        if (jwksUrl == null || jwksUrl.isBlank()) {
            return cachedJwkSet;
        }

        try {
            log.info("Fetching public JWKS from Supabase: {}", jwksUrl);
            cachedJwkSet = JWKSet.load(new URL(jwksUrl));
            jwkSetLastFetched = now;
            return cachedJwkSet;
        } catch (Exception e) {
            log.warn("Could not fetch remote JWKS from {}: {}", jwksUrl, e.getMessage());
            return cachedJwkSet;
        }
    }
}
