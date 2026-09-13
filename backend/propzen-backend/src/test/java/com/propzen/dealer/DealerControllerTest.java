package com.propzen.dealer;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.dealer.dto.DealerApplicationRequest;
import com.propzen.dealer.dto.UpdateDealerProfileRequest;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class DealerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID buyerUserId;
    private String buyerEmail;
    private String buyerToken;

    @BeforeEach
    void setUp() {
        buyerUserId = UUID.randomUUID();
        buyerEmail = "dealer.applicant." + buyerUserId.toString().substring(0, 8) + "@propzen.ai";

        User user = new User(buyerUserId, "Applicant Buyer", buyerEmail, "+91 9988776655", "Buyer");
        userRepository.save(user);

        buyerToken = JwtTestUtils.generateValidToken(buyerUserId, buyerEmail, "Buyer");
    }

    @Test
    void test8_UserCanApplyAsDealer() throws Exception {
        DealerApplicationRequest request = new DealerApplicationRequest(
                "Skyline Properties",
                "Skyline Real Estate Pvt Ltd",
                "Skyline Prime",
                "+91 9988776655",
                buyerEmail,
                "Leading agency in Gurgaon DLF Phase 5",
                8,
                "Gurgaon"
        );

        mockMvc.perform(post("/api/v1/dealers/apply")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.userId").value(buyerUserId.toString()))
                .andExpect(jsonPath("$.data.businessName").value("Skyline Properties"))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.verificationStatus").value("PENDING"));

        assertTrue(dealerProfileRepository.existsByUserId(buyerUserId));
    }

    @Test
    void test9_DuplicateApplicationRejected() throws Exception {
        DealerApplicationRequest request = new DealerApplicationRequest(
                "Apex Realty", null, null, "+91 9988776655", buyerEmail, "Description", 5, "Noida"
        );

        // First application: succeeds
        mockMvc.perform(post("/api/v1/dealers/apply")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated());

        // Duplicate application: rejected with 409 Conflict
        mockMvc.perform(post("/api/v1/dealers/apply")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("DEALER_APPLICATION_PENDING"));
    }

    @Test
    void test10_UserReadsOwnDealerProfile() throws Exception {
        DealerProfile profile = new DealerProfile();
        profile.setUserId(buyerUserId);
        profile.setBusinessName("Zen Homes");
        profile.setPhone("+91 9988776655");
        profile.setEmail(buyerEmail);
        profile.setStatus(DealerStatus.PENDING);
        profile.setVerificationStatus(DealerVerificationStatus.PENDING);
        dealerProfileRepository.save(profile);

        mockMvc.perform(get("/api/v1/dealers/me")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.userId").value(buyerUserId.toString()))
                .andExpect(jsonPath("$.data.businessName").value("Zen Homes"));
    }

    @Test
    void test11_UserCannotReadAnotherDealerPrivateProfile() throws Exception {
        UUID otherUserId = UUID.randomUUID();
        DealerProfile otherDealer = new DealerProfile();
        otherDealer.setUserId(otherUserId);
        otherDealer.setBusinessName("Secret Competitor Realty");
        otherDealer.setPhone("+91 1111111111");
        otherDealer.setEmail("competitor@secret.com");
        otherDealer.setStatus(DealerStatus.APPROVED);
        otherDealer.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealerProfileRepository.save(otherDealer);

        // Current user does not have a profile yet -> returns 404 DEALER_NOT_FOUND
        mockMvc.perform(get("/api/v1/dealers/me")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error.code").value("DEALER_NOT_FOUND"));
    }

    @Test
    void test12_DealerUpdatesAllowedProfileFields() throws Exception {
        DealerProfile profile = new DealerProfile();
        profile.setUserId(buyerUserId);
        profile.setBusinessName("Original Realty");
        profile.setPhone("+91 9988776655");
        profile.setEmail(buyerEmail);
        profile.setStatus(DealerStatus.PENDING);
        profile.setVerificationStatus(DealerVerificationStatus.PENDING);
        dealerProfileRepository.save(profile);

        UpdateDealerProfileRequest updateRequest = new UpdateDealerProfileRequest(
                "Updated Realty Name", "Updated Company", "Updated Display", "+91 9123456780",
                "New description", 10, "Mumbai"
        );

        mockMvc.perform(patch("/api/v1/dealers/me")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.businessName").value("Updated Realty Name"))
                .andExpect(jsonPath("$.data.city").value("Mumbai"));

        DealerProfile updated = dealerProfileRepository.findByUserId(buyerUserId).orElseThrow();
        assertEquals("Updated Realty Name", updated.getBusinessName());
        assertEquals("Mumbai", updated.getCity());
    }

    @Test
    void test13_DealerCannotSelfApprove() throws Exception {
        DealerProfile profile = new DealerProfile();
        profile.setUserId(buyerUserId);
        profile.setBusinessName("Hacker Realty");
        profile.setPhone("+91 9988776655");
        profile.setEmail(buyerEmail);
        profile.setStatus(DealerStatus.PENDING);
        profile.setVerificationStatus(DealerVerificationStatus.PENDING);
        dealerProfileRepository.save(profile);

        // Attempting to send status=APPROVED and verificationStatus=VERIFIED
        Map<String, Object> maliciousPayload = Map.of(
                "businessName", "Hacker Realty Approved",
                "status", "APPROVED",
                "verificationStatus", "VERIFIED"
        );

        mockMvc.perform(patch("/api/v1/dealers/me")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(maliciousPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.verificationStatus").value("PENDING"));

        DealerProfile reloaded = dealerProfileRepository.findByUserId(buyerUserId).orElseThrow();
        assertEquals(DealerStatus.PENDING, reloaded.getStatus(), "Status must remain PENDING");
        assertEquals(DealerVerificationStatus.PENDING, reloaded.getVerificationStatus(), "VerificationStatus must remain PENDING");
    }

    @Test
    void test14_BuyerCannotAccessProtectedDealerOperations() throws Exception {
        // Buyer without DEALER authority tries to access a protected dealer endpoint
        mockMvc.perform(get("/api/v1/dealers/test-probe")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
    }
}
