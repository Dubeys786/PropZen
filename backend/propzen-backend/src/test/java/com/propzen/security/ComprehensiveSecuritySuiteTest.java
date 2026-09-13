package com.propzen.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.LeadType;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.security.jwt.JwtTestUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class ComprehensiveSecuritySuiteTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private LeadRepository leadRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Test
    @DisplayName("Security 401: Missing or null JWT must return 401 Unauthorized on protected endpoints")
    void test1_MissingJwt_Returns401() throws Exception {
        mockMvc.perform(get("/api/v1/storage/signed-download-url")
                        .param("storagePath", "verification-docs/some-uuid/aadhaar.pdf"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Security 403: Buyer role attempting Admin and Dealer APIs must return 403 Forbidden")
    void test2_BuyerRole_DeniedAdminAndDealerApis_Returns403() throws Exception {
        UUID buyerId = UUID.randomUUID();
        String buyerToken = JwtTestUtils.generateValidToken(buyerId, "buyer@propzen.ai", "Buyer");

        // Admin probe endpoint
        mockMvc.perform(get("/api/v1/admin/test-probe")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden());

        // WhatsApp template registration (Admin only)
        mockMvc.perform(post("/api/v1/whatsapp/template")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"test_template\",\"bodyText\":\"Hello {{1}}\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security IDOR: Dealer A cannot run AI scoring on Dealer B's lead (returns 403)")
    void test3_LeadIdorProtection_DealerCannotAccessOtherDealerLead_Returns403() throws Exception {
        UUID dealerAUserId = UUID.randomUUID();
        UUID dealerBUserId = UUID.randomUUID();

        // Register Dealer A profile
        DealerProfile profileA = new DealerProfile();
        profileA.setUserId(dealerAUserId);
        profileA.setBusinessName("Agency A");
        profileA.setEmail("dealera@propzen.ai");
        profileA.setPhone("+919111111111");
        profileA.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        profileA.setStatus(DealerStatus.APPROVED);
        profileA = dealerProfileRepository.save(profileA);

        // Register Dealer B profile
        DealerProfile profileB = new DealerProfile();
        profileB.setUserId(dealerBUserId);
        profileB.setBusinessName("Agency B");
        profileB.setEmail("dealerb@propzen.ai");
        profileB.setPhone("+919222222222");
        profileB.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        profileB.setStatus(DealerStatus.APPROVED);
        profileB = dealerProfileRepository.save(profileB);

        // Create Lead belonging exclusively to Dealer B
        Lead leadB = new Lead();
        leadB.setLeadNumber("LD-TEST-" + UUID.randomUUID().toString().substring(0, 8));
        leadB.setName("Confidential Buyer");
        leadB.setPhone("+919888888888");
        leadB.setEmail("hnw@example.com");
        leadB.setDealerId(profileB.getId());
        leadB.setAssignedTo(dealerBUserId);
        leadB.setStage(LeadStage.NEW_LEAD);
        leadB.setStatus(LeadStatus.NEW);
        leadB.setLeadType(LeadType.BUYER);
        leadB.setPriority(LeadPriority.HIGH);
        leadB = leadRepository.save(leadB);

        // Dealer A attempts AI scoring on Dealer B's lead
        String dealerAToken = JwtTestUtils.generateDealerToken(dealerAUserId, "dealera@propzen.ai");

        mockMvc.perform(post("/api/v1/ai/crm/lead-score/" + leadB.getId())
                        .header("Authorization", "Bearer " + dealerAToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security Webhook: Forged payment webhook signature returns 400 Bad Request")
    void test4_PaymentWebhook_ForgedSignature_Returns400() throws Exception {
        Map<String, Object> fakePayload = Map.of(
                "orderId", "order_fake_12345",
                "paymentId", "pay_fake_67890",
                "signature", "malicious_forged_hmac_signature"
        );

        mockMvc.perform(post("/api/v1/services/payments/webhook")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(fakePayload)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Security Webhook: Forged WhatsApp webhook signature returns 403 Forbidden")
    void test5_WhatsAppWebhook_ForgedSignature_Returns403() throws Exception {
        Map<String, Object> webhookPayload = Map.of(
                "object", "whatsapp_business_account",
                "providerMessageId", "wamid.fake123",
                "status", "DELIVERED"
        );

        mockMvc.perform(post("/api/v1/webhooks/whatsapp")
                        .header("X-Hub-Signature-256", "sha256=invalid_computed_sha256_hash_here")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(webhookPayload)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security Storage IDOR: Non-admin user cannot generate signed URL for another user's private documents")
    void test6_StorageIdor_CannotDownloadOtherUserPrivateDoc_Returns403() throws Exception {
        UUID userA = UUID.randomUUID();
        UUID userB = UUID.randomUUID();
        String userAToken = JwtTestUtils.generateValidToken(userA, "userA@propzen.ai", "Buyer");

        // Attempting to download user B's confidential Aadhaar document in private bucket
        String targetPath = "verification-docs/" + userB + "/aadhaar_card.pdf";

        mockMvc.perform(get("/api/v1/storage/signed-download-url")
                        .param("storagePath", targetPath)
                        .header("Authorization", "Bearer " + userAToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security Rate Limit: Repeated requests exhaust sliding window and return 429")
    void test7_RateLimiting_ExhaustionReturns429() throws Exception {
        String testIp = "198.51.100.42";
        boolean got429 = false;
        for (int i = 0; i < 75; i++) {
            int statusCode = mockMvc.perform(post("/api/v1/enquiries")
                            .header("X-Forwarded-For", testIp)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"name\":\"Test\",\"phone\":\"+919000000000\"}"))
                    .andReturn().getResponse().getStatus();
            if (statusCode == 429) {
                got429 = true;
                break;
            }
        }
        org.junit.jupiter.api.Assertions.assertTrue(got429, "Rate limiter should have triggered 429 Too Many Requests");
    }
}
