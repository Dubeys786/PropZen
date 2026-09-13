package com.propzen.auth;

import com.propzen.security.jwt.JwtTestUtils;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthControllerSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void testPublicHealthEndpointAccessibleWithoutToken() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("UP"));
    }

    @Test
    void testProtectedMeEndpointRejectsMissingToken() throws Exception {
        mockMvc.perform(get("/api/v1/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("UNAUTHORIZED"))
                .andExpect(jsonPath("$.error.message").isNotEmpty());
    }

    @Test
    void testProtectedMeEndpointRejectsMalformedToken() throws Exception {
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer this.is.a.malformed.token"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("UNAUTHORIZED"));
    }

    @Test
    void testProtectedMeEndpointRejectsExpiredToken() throws Exception {
        UUID userId = UUID.randomUUID();
        String expiredToken = JwtTestUtils.generateExpiredToken(userId, "expired@propzen.ai", "Buyer");

        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + expiredToken))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("UNAUTHORIZED"));
    }

    @Test
    void testProtectedMeEndpointAcceptsValidTokenAndExtractsIdentity() throws Exception {
        UUID expectedUserId = UUID.randomUUID();
        String expectedEmail = "sakshi.buyer@propzen.ai";
        String token = JwtTestUtils.generateValidToken(expectedUserId, expectedEmail, "Buyer");

        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.authenticated").value(true))
                .andExpect(jsonPath("$.data.userId").value(expectedUserId.toString()))
                .andExpect(jsonPath("$.data.email").value(expectedEmail))
                .andExpect(jsonPath("$.data.roles[0]").value("ROLE_BUYER"));
    }

    @Test
    void testAdminEndpointRejectsBuyerRole() throws Exception {
        UUID buyerId = UUID.randomUUID();
        String buyerToken = JwtTestUtils.generateValidToken(buyerId, "standard.buyer@propzen.ai", "Buyer");

        mockMvc.perform(get("/api/v1/admin/test-probe")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("FORBIDDEN"))
                .andExpect(jsonPath("$.error.message").isNotEmpty());
    }

    @Test
    void testDealerEndpointRejectsBuyerRole() throws Exception {
        UUID buyerId = UUID.randomUUID();
        String buyerToken = JwtTestUtils.generateValidToken(buyerId, "standard.buyer@propzen.ai", "Buyer");

        mockMvc.perform(get("/api/v1/dealers/test-probe")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
    }

    @Test
    void testDealerEndpointAcceptsDealerRole() throws Exception {
        UUID dealerId = UUID.randomUUID();
        String dealerToken = JwtTestUtils.generateDealerToken(dealerId, "verified.dealer@propzen.ai");

        mockMvc.perform(get("/api/v1/dealers/test-probe")
                        .header("Authorization", "Bearer " + dealerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void testAdminEndpointAcceptsDesignatedAdmin() throws Exception {
        UUID adminId = UUID.randomUUID();
        String adminToken = JwtTestUtils.generateAdminToken(adminId, "dubeysakshi618@gmail.com");

        mockMvc.perform(get("/api/v1/admin/test-probe")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void testAdminCanAlsoAccessDealerEndpoints() throws Exception {
        UUID adminId = UUID.randomUUID();
        String adminToken = JwtTestUtils.generateAdminToken(adminId, "dubeysakshi618@gmail.com");

        mockMvc.perform(get("/api/v1/dealers/test-probe")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
