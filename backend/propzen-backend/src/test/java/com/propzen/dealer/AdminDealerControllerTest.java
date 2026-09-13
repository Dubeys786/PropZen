package com.propzen.dealer;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.dealer.dto.UpdateDealerStatusRequest;
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

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminDealerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID adminUserId;
    private String adminToken;

    private UUID buyerUserId;
    private String buyerToken;

    private DealerProfile sampleProfile;

    @BeforeEach
    void setUp() {
        adminUserId = UUID.randomUUID();
        // Uses token with app_metadata.role="Admin"
        adminToken = JwtTestUtils.generateAdminToken(adminUserId, "admin.ops@propzen.ai");

        buyerUserId = UUID.randomUUID();
        buyerToken = JwtTestUtils.generateValidToken(buyerUserId, "buyer@propzen.ai", "Buyer");

        User dealerApplicantUser = new User(buyerUserId, "Dealer Candidate", "candidate@propzen.ai", "+91 9999000011", "Buyer");
        userRepository.save(dealerApplicantUser);

        sampleProfile = new DealerProfile();
        sampleProfile.setUserId(buyerUserId);
        sampleProfile.setBusinessName("Global Heights Realty");
        sampleProfile.setPhone("+91 9999000011");
        sampleProfile.setEmail("candidate@propzen.ai");
        sampleProfile.setStatus(DealerStatus.PENDING);
        sampleProfile.setVerificationStatus(DealerVerificationStatus.PENDING);
        sampleProfile = dealerProfileRepository.save(sampleProfile);
    }

    @Test
    void test15_AdminCanListDealerApplicationsWithPagination() throws Exception {
        mockMvc.perform(get("/api/v1/admin/dealers")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.page").value(0))
                .andExpect(jsonPath("$.data.pageSize").value(10))
                .andExpect(jsonPath("$.data.totalElements").isNumber());
    }

    @Test
    void test16_AdminCanApproveDealerAndActivateRole() throws Exception {
        UpdateDealerStatusRequest request = new UpdateDealerStatusRequest(
                DealerStatus.APPROVED, "Verified RERA documentation and physical office."
        );

        mockMvc.perform(patch("/api/v1/admin/dealers/" + sampleProfile.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("APPROVED"))
                .andExpect(jsonPath("$.data.verificationStatus").value("VERIFIED"));

        DealerProfile updated = dealerProfileRepository.findById(sampleProfile.getId()).orElseThrow();
        assertEquals(DealerStatus.APPROVED, updated.getStatus());
        assertEquals(DealerVerificationStatus.VERIFIED, updated.getVerificationStatus());
        assertEquals(adminUserId, updated.getReviewedBy());
        assertNotNull(updated.getReviewedAt());

        // Verify server-side role activation in public.users table
        User user = userRepository.findById(buyerUserId).orElseThrow();
        assertEquals("DEALER", user.getRole(), "User database role must be upgraded to DEALER upon approval");
    }

    @Test
    void test17_NonAdminCannotApproveDealer() throws Exception {
        UpdateDealerStatusRequest request = new UpdateDealerStatusRequest(
                DealerStatus.APPROVED, "Attempting rogue self-approval."
        );

        mockMvc.perform(patch("/api/v1/admin/dealers/" + sampleProfile.getId() + "/status")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
    }

    @Test
    void test18_InvalidStatusTransitionRejected() throws Exception {
        // PENDING -> SUSPENDED is not a direct valid transition
        UpdateDealerStatusRequest invalidRequest = new UpdateDealerStatusRequest(
                DealerStatus.SUSPENDED, "Cannot suspend an unapproved dealer"
        );

        mockMvc.perform(patch("/api/v1/admin/dealers/" + sampleProfile.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("INVALID_DEALER_STATUS_TRANSITION"));
    }
}
