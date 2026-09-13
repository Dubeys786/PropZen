package com.propzen.security.jwt;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class SupabaseJwtValidatorTest {

    private SupabaseJwtValidator validator;

    @BeforeEach
    void setUp() {
        validator = new SupabaseJwtValidator(null, JwtTestUtils.TEST_SECRET, true);
    }

    @Test
    void testValidateValidToken() {
        UUID expectedUserId = UUID.randomUUID();
        String expectedEmail = "user@example.com";
        String token = JwtTestUtils.generateValidToken(expectedUserId, expectedEmail, "Buyer");

        SupabaseUserClaims claims = validator.validateToken(token);

        assertNotNull(claims);
        assertEquals(expectedUserId, claims.getUserId());
        assertEquals(expectedEmail, claims.getEmail());
        assertEquals("authenticated", claims.getRole());
        assertNotNull(claims.getExpiresAt());
    }

    @Test
    void testRejectExpiredToken() {
        UUID userId = UUID.randomUUID();
        String expiredToken = JwtTestUtils.generateExpiredToken(userId, "expired@example.com", "Buyer");

        JwtValidationException ex = assertThrows(JwtValidationException.class, () ->
                validator.validateToken(expiredToken));

        assertTrue(ex.getMessage().contains("expired"), "Exception message must mention expiration");
    }

    @Test
    void testRejectInvalidSignature() {
        UUID userId = UUID.randomUUID();
        String tamperedToken = JwtTestUtils.generateTokenWithWrongSecret(userId, "tampered@example.com", "Buyer");

        JwtValidationException ex = assertThrows(JwtValidationException.class, () ->
                validator.validateToken(tamperedToken));

        assertTrue(ex.getMessage().contains("signature"), "Exception message must mention signature failure");
    }

    @Test
    void testRejectMalformedToken() {
        assertThrows(JwtValidationException.class, () ->
                validator.validateToken("not.a.valid.jwt.payload"));
    }

    @Test
    void testRejectNullOrBlankToken() {
        assertThrows(JwtValidationException.class, () -> validator.validateToken(null));
        assertThrows(JwtValidationException.class, () -> validator.validateToken("   "));
    }
}
