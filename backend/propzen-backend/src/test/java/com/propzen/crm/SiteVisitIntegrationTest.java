package com.propzen.crm;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.crm.dto.CreateSiteVisitRequest;
import com.propzen.crm.repository.SiteVisitRepository;
import com.propzen.security.jwt.JwtTestUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class SiteVisitIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private SiteVisitRepository siteVisitRepository;

    @Test
    @DisplayName("Public site visit booking should succeed and return 201 Created")
    void testPublicSiteVisitBooking() throws Exception {
        CreateSiteVisitRequest request = new CreateSiteVisitRequest();
        request.setPropertyId("PROP-TEST-101");
        request.setPropertyTitle("Luxury Palm Villa");
        request.setUserName("Aarav Sharma");
        request.setUserEmail("aarav@example.com");
        request.setUserPhone("+919876543210");
        request.setVisitDate("2026-09-15");
        request.setTimeSlot("10:00 AM - 11:00 AM");
        request.setVisitorCount(2);
        request.setCabRequired(true);

        mockMvc.perform(post("/api/v1/site-visits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", notNullValue()))
                .andExpect(jsonPath("$.data.userName", is("Aarav Sharma")))
                .andExpect(jsonPath("$.data.status", is("Pending Confirmation")));
    }

    @Test
    @DisplayName("Unauthenticated access to /site-visits/me should return 401")
    void testGetMySiteVisitsUnauthenticated() throws Exception {
        mockMvc.perform(get("/api/v1/site-visits/me"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Authenticated user can view their site visits")
    void testGetMySiteVisitsAuthenticated() throws Exception {
        UUID userId = UUID.randomUUID();
        String token = JwtTestUtils.generateValidToken(userId, "buyer@propzen.ai", "authenticated");

        mockMvc.perform(get("/api/v1/site-visits/me")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", isA(java.util.List.class)));
    }

    @Test
    @DisplayName("Malformed JSON should return 400 Bad Request instead of 500")
    void testMalformedJsonReturns400() throws Exception {
        mockMvc.perform(post("/api/v1/site-visits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{ invalid_json: true,"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.error.code", is("BAD_REQUEST")));
    }
}
