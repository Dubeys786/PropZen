package com.propzen.security.jwt;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;

import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Date;
import java.util.Map;
import java.util.UUID;

/**
 * Utility for generating synthetic Supabase JWTs in unit and integration tests.
 */
public class JwtTestUtils {

    public static final String TEST_SECRET = "propzen-test-super-secret-hmac-key-256-bits-minimum-length-2026";

    public static String generateValidToken(UUID userId, String email, String role) {
        return generateToken(userId, email, role, 3600, TEST_SECRET, true);
    }

    public static String generateAdminToken(UUID userId, String email) {
        return generateToken(userId, email, "Admin", 3600, TEST_SECRET, true);
    }

    public static String generateDealerToken(UUID userId, String email) {
        return generateToken(userId, email, "DEALER", 3600, TEST_SECRET, true);
    }

    public static String generateExpiredToken(UUID userId, String email, String role) {
        return generateToken(userId, email, role, -3600, TEST_SECRET, true);
    }

    public static String generateTokenWithWrongSecret(UUID userId, String email, String role) {
        return generateToken(userId, email, role, 3600, "wrong-secret-key-that-does-not-match-propzen-test-key-256", true);
    }

    public static String generateToken(UUID userId,
                                      String email,
                                      String role,
                                      long validitySeconds,
                                      String secret,
                                      boolean includeAudience) {
        try {
            Date now = new Date();
            Date exp = new Date(now.getTime() + (validitySeconds * 1000));

            JWTClaimsSet.Builder builder = new JWTClaimsSet.Builder()
                    .subject(userId.toString())
                    .issueTime(now)
                    .expirationTime(exp)
                    .claim("email", email)
                    .claim("role", "authenticated")
                    .claim("app_metadata", Map.of("provider", "email", "role", role))
                    .claim("user_metadata", Map.of("role", role));

            if (includeAudience) {
                builder.audience(Collections.singletonList("authenticated"));
            }

            JWTClaimsSet claimsSet = builder.build();

            SignedJWT signedJWT = new SignedJWT(
                    new JWSHeader(JWSAlgorithm.HS256),
                    claimsSet
            );

            JWSSigner signer = new MACSigner(secret.getBytes(StandardCharsets.UTF_8));
            signedJWT.sign(signer);

            return signedJWT.serialize();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate test JWT", e);
        }
    }
}
