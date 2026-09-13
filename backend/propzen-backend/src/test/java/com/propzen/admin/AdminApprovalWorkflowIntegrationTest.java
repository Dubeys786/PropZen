package com.propzen.admin;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.audit.AuditLogRepository;
import com.propzen.dealer.dto.UpdateDealerStatusRequest;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.service.dto.UpdatePartnerStatusRequest;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminApprovalWorkflowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Autowired
    private ServicePartnerProfileRepository partnerProfileRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID adminUserId;
    private String adminToken;

    private UUID applicantDealerUserId;
    private DealerProfile pendingDealer;

    private UUID applicantPartnerUserId;
    private ServicePartnerProfile pendingPartner;

    @BeforeEach
    void setUp() {
        auditLogRepository.deleteAll();
        dealerProfileRepository.deleteAll();
        partnerProfileRepository.deleteAll();
        userRepository.deleteAll();

        // 1. Admin
        adminUserId = UUID.randomUUID();
        User adminUser = new User(adminUserId, "Admin Ops", "admin@propzen.ai", "+919999000001", "Admin");
        userRepository.save(adminUser);
        adminToken = JwtTestUtils.generateAdminToken(adminUserId, "admin@propzen.ai");

        // 2. Pending Dealer Applicant
        applicantDealerUserId = UUID.randomUUID();
        User dealerUser = new User(applicantDealerUserId, "Vikram Malhotra", "vikram@dealer.com", "+919876500001", "Buyer");
        userRepository.save(dealerUser);

        pendingDealer = new DealerProfile();
        pendingDealer.setUserId(applicantDealerUserId);
        pendingDealer.setBusinessName("Malhotra Prime Properties");
        pendingDealer.setPhone("+919876500001");
        pendingDealer.setEmail("vikram@dealer.com");
        pendingDealer.setStatus(DealerStatus.PENDING);
        pendingDealer.setVerificationStatus(DealerVerificationStatus.PENDING);
        pendingDealer = dealerProfileRepository.save(pendingDealer);

        // 3. Pending Service Partner Applicant
        applicantPartnerUserId = UUID.randomUUID();
        User partnerUser = new User(applicantPartnerUserId, "Sunita Rao", "sunita@vastu.com", "+919876500002", "Buyer");
        userRepository.save(partnerUser);

        pendingPartner = new ServicePartnerProfile();
        pendingPartner.setUserId(applicantPartnerUserId);
        pendingPartner.setBusinessName("Vastu Shastra Consultants");
        pendingPartner.setPhone("+919876500002");
        pendingPartner.setEmail("sunita@vastu.com");
        pendingPartner.setPartnerStatus(PartnerStatus.PENDING);
        pendingPartner.setVerificationStatus(PartnerVerificationStatus.PENDING);
        pendingPartner.setServiceCategories("VASTU, VASTU_CONSULTANCY");
        pendingPartner = partnerProfileRepository.save(pendingPartner);
    }

    @Test
    @DisplayName("Admin approval immediately activates DEALER role and permits dealer portal access")
    void test1_DealerApproval_ActivatesRoleImmediately() throws Exception {
        // Step 1: Dealer user logs in with their existing login credential token (claims role = Buyer)
        String dealerUserToken = JwtTestUtils.generateValidToken(applicantDealerUserId, "vikram@dealer.com", "Buyer");

        // Before approval: /auth/me returns only ROLE_BUYER
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + dealerUserToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.roles", not(hasItem("ROLE_DEALER"))));

        // Step 2: Admin clicks APPROVE in Admin Command Center
        UpdateDealerStatusRequest approveReq = new UpdateDealerStatusRequest();
        approveReq.setStatus(DealerStatus.APPROVED);
        approveReq.setAdminNotes("All RERA documents verified successfully.");

        mockMvc.perform(patch("/api/v1/admin/dealers/" + pendingDealer.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(approveReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("APPROVED"))
                .andExpect(jsonPath("$.data.verificationStatus").value("VERIFIED"));

        // Step 3: Verify user DB role is updated
        User updatedUser = userRepository.findById(applicantDealerUserId).orElseThrow();
        assertEquals("DEALER", updatedUser.getRole());

        // Step 4: User immediately receives ROLE_DEALER on next call with their EXISTING login token!
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + dealerUserToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.roles", hasItem("ROLE_DEALER")));

        // Step 5: Verify dealer probe / portal access works
        mockMvc.perform(get("/api/v1/dealers/test-probe")
                        .header("Authorization", "Bearer " + dealerUserToken))
                .andExpect(status().isOk());

        // Step 6: Verify audit trail
        boolean auditPresent = auditLogRepository.findAll().stream()
                .anyMatch(a -> "DEALER_APPLICATION_APPROVED".equals(a.getAction()));
        assertTrue(auditPresent, "Audit log DEALER_APPLICATION_APPROVED must be recorded");
    }

    @Test
    @DisplayName("Admin approval immediately activates SERVICE_PARTNER role and enables partner portal access")
    void test2_ServicePartnerApproval_ActivatesRoleImmediately() throws Exception {
        // Existing user token
        String partnerUserToken = JwtTestUtils.generateValidToken(applicantPartnerUserId, "sunita@vastu.com", "Buyer");

        // Before approval: /auth/me does not have ROLE_SERVICE_PARTNER
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + partnerUserToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.roles", not(hasItem("ROLE_SERVICE_PARTNER"))));

        // Admin approves service partner
        UpdatePartnerStatusRequest approveReq = new UpdatePartnerStatusRequest();
        approveReq.setStatus(PartnerStatus.APPROVED);
        approveReq.setAdminNotes("Certification verified.");

        mockMvc.perform(patch("/api/v1/admin/service-partners/" + pendingPartner.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(approveReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.partnerStatus").value("APPROVED"))
                .andExpect(jsonPath("$.data.verificationStatus").value("VERIFIED"));

        // Verify DB role
        User updatedUser = userRepository.findById(applicantPartnerUserId).orElseThrow();
        assertEquals("SERVICE_PARTNER", updatedUser.getRole());

        // Immediately receives ROLE_SERVICE_PARTNER
        mockMvc.perform(get("/api/v1/auth/me")
                        .header("Authorization", "Bearer " + partnerUserToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.roles", hasItem("ROLE_SERVICE_PARTNER")));

        // Verify audit trail
        boolean auditPresent = auditLogRepository.findAll().stream()
                .anyMatch(a -> "SERVICE_PARTNER_APPLICATION_APPROVED".equals(a.getAction()));
        assertTrue(auditPresent, "Audit log SERVICE_PARTNER_APPLICATION_APPROVED must be recorded");
    }

    @Test
    @DisplayName("Pending applicants cannot access protected dealer or partner portal endpoints")
    void test3_PendingApplicants_BlockedFromPortals() throws Exception {
        String pendingDealerToken = JwtTestUtils.generateValidToken(applicantDealerUserId, "vikram@dealer.com", "Buyer");
        String pendingPartnerToken = JwtTestUtils.generateValidToken(applicantPartnerUserId, "sunita@vastu.com", "Buyer");

        // Pending dealer cannot access dealer probe
        mockMvc.perform(get("/api/v1/dealers/test-probe")
                        .header("Authorization", "Bearer " + pendingDealerToken))
                .andExpect(status().isForbidden());

        // Pending partner cannot access partner dashboard
        mockMvc.perform(get("/api/v1/partner/dashboard")
                        .header("Authorization", "Bearer " + pendingPartnerToken))
                .andExpect(status().isForbidden());
    }
}
