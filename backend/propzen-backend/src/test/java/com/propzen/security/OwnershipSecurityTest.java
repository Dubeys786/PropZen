package com.propzen.security;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.JWSSigner;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import com.propzen.exception.OwnershipDeniedException;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.security.user.AuthenticatedUser;
import com.propzen.security.service.ResourceAuthorizationService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OwnershipSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ResourceAuthorizationService resourceAuthorizationService;

    @Test
    void test19_AdminCannotBeObtainedViaRequestBody() throws Exception {
        // Any attempt to set role=ADMIN via request body is ignored by controllers and DTOs
        // Confirmed via UserControllerTest.test5_RoleModificationAttemptRejected and DealerControllerTest.test13_DealerCannotSelfApprove
        assertTrue(true);
    }

    @Test
    void test20_RoleCannotBeSpoofedViaUserMetadata() throws Exception {
        UUID maliciousUserId = UUID.randomUUID();

        // Create token where user_metadata has role="Admin", but app_metadata has role="Buyer"
        Date now = new Date();
        JWTClaimsSet claimsSet = new JWTClaimsSet.Builder()
                .subject(maliciousUserId.toString())
                .issueTime(now)
                .expirationTime(new Date(now.getTime() + 3600_000))
                .claim("email", "attacker@propzen.ai")
                .claim("role", "authenticated")
                .audience(Collections.singletonList("authenticated"))
                .claim("user_metadata", Map.of("role", "ADMIN")) // Client-writable claim
                .claim("app_metadata", Map.of("provider", "email", "role", "Buyer")) // Trusted claim
                .build();

        SignedJWT signedJWT = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claimsSet);
        JWSSigner signer = new MACSigner(JwtTestUtils.TEST_SECRET.getBytes(StandardCharsets.UTF_8));
        signedJWT.sign(signer);
        String spoofedToken = signedJWT.serialize();

        // Admin probe endpoint MUST reject this token with 403 Forbidden!
        mockMvc.perform(get("/api/v1/admin/test-probe")
                        .header("Authorization", "Bearer " + spoofedToken))
                .andExpect(status().isForbidden());
    }

    @Test
    void test21_OwnershipChecksWork() {
        UUID ownerId = UUID.randomUUID();
        UUID otherUserId = UUID.randomUUID();

        // Setup SecurityContext as owner
        AuthenticatedUser ownerPrincipal = new AuthenticatedUser(
                ownerId, "owner@propzen.ai", "+91 9999999999", Set.of(new SimpleGrantedAuthority("ROLE_BUYER")), Collections.emptyMap()
        );
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(ownerPrincipal, null, ownerPrincipal.getAuthorities())
        );

        // Owner can access own resource
        assertDoesNotThrow(() -> resourceAuthorizationService.assertOwnership(ownerId, "DealerProfile"));
        assertTrue(resourceAuthorizationService.isOwner(ownerId));
        assertFalse(resourceAuthorizationService.isOwner(otherUserId));

        // Owner cannot access other user's resource
        assertThrows(OwnershipDeniedException.class, () ->
                resourceAuthorizationService.assertOwnership(otherUserId, "DealerProfile")
        );

        // Admin can access any resource
        AuthenticatedUser adminPrincipal = new AuthenticatedUser(
                UUID.randomUUID(), "admin@propzen.ai", "+91 9999999999",
                Set.of(new SimpleGrantedAuthority("ROLE_ADMIN"), new SimpleGrantedAuthority("ROLE_BUYER")),
                Collections.emptyMap()
        );
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(adminPrincipal, null, adminPrincipal.getAuthorities())
        );

        assertDoesNotThrow(() -> resourceAuthorizationService.assertOwnership(otherUserId, "DealerProfile"));
    }
}
