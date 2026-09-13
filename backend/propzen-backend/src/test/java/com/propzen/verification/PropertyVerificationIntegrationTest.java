package com.propzen.verification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import com.propzen.verification.dto.CreateVerificationCaseRequest;
import com.propzen.verification.dto.UpdateVerificationStatusRequest;
import com.propzen.verification.model.VerificationCaseStatus;
import com.propzen.verification.model.VerificationDocumentType;
import com.propzen.verification.repository.PropertyVerificationCaseRepository;
import com.propzen.verification.repository.PropertyVerificationDocumentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
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
class PropertyVerificationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PropertyVerificationCaseRepository caseRepository;

    @Autowired
    private PropertyVerificationDocumentRepository documentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID adminId;
    private String adminToken;

    @BeforeEach
    void setUp() {
        documentRepository.deleteAll();
        caseRepository.deleteAll();
        userRepository.deleteAll();

        adminId = UUID.randomUUID();
        User admin = new User(adminId, "Admin User", "admin@propzen.ai", "+91 9999900001", "Admin");
        userRepository.save(admin);
        adminToken = JwtTestUtils.generateAdminToken(adminId, "admin@propzen.ai");
    }

    @Test
    @DisplayName("Empty Database: Metrics must return 0 for all counters with no fake data")
    void test1_EmptyMetricsReturnsZero() throws Exception {
        mockMvc.perform(get("/api/v1/verification/metrics")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.totalCases").value(0))
                .andExpect(jsonPath("$.data.verified").value(0))
                .andExpect(jsonPath("$.data.underReview").value(0))
                .andExpect(jsonPath("$.data.highRisk").value(0))
                .andExpect(jsonPath("$.data.documentsProcessed").value(0));
    }

    @Test
    @DisplayName("Create Case: Valid property and document information creates new case in database")
    void test2_CreateVerificationCase() throws Exception {
        CreateVerificationCaseRequest req = new CreateVerificationCaseRequest();
        req.setPropertyTitle("Luxury Penthouse 4BHK");
        req.setPropertyType("Apartment");
        req.setAddress("Tower B, DLF Phase 5");
        req.setCity("Gurugram");
        req.setSectorLocality("Sector 54");
        req.setKhasraNumber("KH-892/1");
        req.setPlotNumber("Plot 12");
        req.setArea("3850 Sq.Ft");
        req.setOwnerName("Rajesh Sharma");
        req.setRegistrationNumber("REG-HR-2024-8891");
        req.setRegistrationDate("2024-03-15");

        CreateVerificationCaseRequest.UploadDocumentItem doc1 = new CreateVerificationCaseRequest.UploadDocumentItem(
                "Sale_Deed_Signed.pdf",
                VerificationDocumentType.SALE_DEED,
                2457600L,
                "https://storage.propzen.ai/docs/sale_deed.pdf",
                "application/pdf"
        );
        CreateVerificationCaseRequest.UploadDocumentItem doc2 = new CreateVerificationCaseRequest.UploadDocumentItem(
                "Khatauni_Registry_Extract.pdf",
                VerificationDocumentType.KHATAUNI,
                1048576L,
                "https://storage.propzen.ai/docs/khatauni.pdf",
                "application/pdf"
        );
        req.setDocuments(List.of(doc1, doc2));

        mockMvc.perform(post("/api/v1/verification/cases")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").isNotEmpty())
                .andExpect(jsonPath("$.data.caseNumber").value(startsWith("PVC-")))
                .andExpect(jsonPath("$.data.propertyTitle").value("Luxury Penthouse 4BHK"))
                .andExpect(jsonPath("$.data.ownerName").value("Rajesh Sharma"))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.documents", hasSize(2)));
    }

    @Test
    @DisplayName("AI Pipeline: Execute AI verification pipeline on created case, produces extracted data and risk score")
    void test3_ExecuteAiVerificationPipeline() throws Exception {
        // 1. Create Case
        CreateVerificationCaseRequest req = new CreateVerificationCaseRequest();
        req.setPropertyTitle("Greenfield Villa Parcel");
        req.setPropertyType("Villa");
        req.setAddress("Golf Course Road");
        req.setCity("Gurugram");
        req.setOwnerName("Vikramaditya Roy");
        req.setDocuments(List.of(new CreateVerificationCaseRequest.UploadDocumentItem(
                "Title_Registry.pdf",
                VerificationDocumentType.REGISTRY,
                2048000L,
                "https://storage.propzen.ai/docs/registry.pdf",
                "application/pdf"
        )));

        String createRes = mockMvc.perform(post("/api/v1/verification/cases")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String caseId = objectMapper.readTree(createRes).path("data").path("id").asText();

        // 2. Execute AI Verification
        mockMvc.perform(post("/api/v1/verification/cases/" + caseId + "/verify")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("VERIFIED"))
                .andExpect(jsonPath("$.data.riskLevel").value("LOW"))
                .andExpect(jsonPath("$.data.riskScore").value(greaterThan(80)))
                .andExpect(jsonPath("$.data.extractedData").isNotEmpty())
                .andExpect(jsonPath("$.data.consistencyChecks").isNotEmpty())
                .andExpect(jsonPath("$.data.riskChecks").isNotEmpty())
                .andExpect(jsonPath("$.data.findings").isNotEmpty());

        // 3. Confirm Metrics updated
        mockMvc.perform(get("/api/v1/verification/metrics")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalCases").value(1))
                .andExpect(jsonPath("$.data.verified").value(1))
                .andExpect(jsonPath("$.data.documentsProcessed").value(1));
    }

    @Test
    @DisplayName("Admin Status Transition: Admin updates case review status and notes")
    void test4_AdminStatusTransition() throws Exception {
        CreateVerificationCaseRequest req = new CreateVerificationCaseRequest();
        req.setPropertyTitle("Suburban Plot 500 SqYd");
        req.setPropertyType("Plot");
        req.setAddress("Sector 82");
        req.setCity("Gurugram");
        req.setOwnerName("Sanjay Mehra");

        String createRes = mockMvc.perform(post("/api/v1/verification/cases")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        String caseId = objectMapper.readTree(createRes).path("data").path("id").asText();

        UpdateVerificationStatusRequest updateReq = new UpdateVerificationStatusRequest();
        updateReq.setStatus(VerificationCaseStatus.NEEDS_CORRECTION);
        updateReq.setAdminNotes("Awaiting updated mutation ledger extract.");

        mockMvc.perform(patch("/api/v1/verification/cases/" + caseId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("NEEDS_CORRECTION"));
    }

    @Test
    @DisplayName("Security: Unauthenticated request rejected with 401")
    void test5_UnauthenticatedAccessRejected() throws Exception {
        mockMvc.perform(get("/api/v1/verification/metrics"))
                .andExpect(status().isUnauthorized());
    }
}
