package com.propzen.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.service.dto.*;
import com.propzen.service.entity.*;
import com.propzen.service.model.*;
import com.propzen.service.repository.*;
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
import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ServiceManagementIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ServiceCategoryRepository categoryRepository;

    @Autowired
    private ServicePartnerProfileRepository partnerProfileRepository;

    @Autowired
    private ServiceRequestRepository serviceRequestRepository;

    @Autowired
    private ServiceRequestAssignmentRepository assignmentRepository;

    @Autowired
    private ServiceJourneyEventRepository journeyEventRepository;

    @Autowired
    private ServiceDocumentRepository documentRepository;

    @Autowired
    private ServiceMilestoneRepository milestoneRepository;

    @Autowired
    private ServicePaymentRepository paymentRepository;

    @Autowired
    private ServiceFeedbackRepository feedbackRepository;

    @Autowired
    private ServiceCustomerNoteRepository customerNoteRepository;

    private UUID adminId;
    private String adminToken;

    private UUID customer1Id;
    private String customer1Token;

    private UUID customer2Id;
    private String customer2Token;

    private UUID partner1UserId;
    private String partner1Token;

    private UUID partner2UserId;
    private String partner2Token;

    private ServiceCategory testCategory;

    @BeforeEach
    void setUp() {
        customerNoteRepository.deleteAll();
        feedbackRepository.deleteAll();
        paymentRepository.deleteAll();
        milestoneRepository.deleteAll();
        documentRepository.deleteAll();
        journeyEventRepository.deleteAll();
        assignmentRepository.deleteAll();
        serviceRequestRepository.deleteAll();
        partnerProfileRepository.deleteAll();
        categoryRepository.deleteAll();

        adminId = UUID.randomUUID();
        adminToken = JwtTestUtils.generateAdminToken(adminId, "admin@propzen.ai");

        customer1Id = UUID.randomUUID();
        customer1Token = JwtTestUtils.generateValidToken(customer1Id, "customer1@example.com", "BUYER");

        customer2Id = UUID.randomUUID();
        customer2Token = JwtTestUtils.generateValidToken(customer2Id, "customer2@example.com", "BUYER");

        partner1UserId = UUID.randomUUID();
        partner1Token = JwtTestUtils.generateValidToken(partner1UserId, "partner1@example.com", "SERVICE_PARTNER");

        partner2UserId = UUID.randomUUID();
        partner2Token = JwtTestUtils.generateValidToken(partner2UserId, "partner2@example.com", "SERVICE_PARTNER");

        // Seed core test category
        ServiceCategory cat = new ServiceCategory();
        cat.setName("Home Design & Interiors");
        cat.setSlug("home-design");
        cat.setIcon("design_services");
        cat.setDescription("Premium interior architecture and 3D space planning");
        cat.setIsActive(true);
        cat.setSortOrder(1);
        testCategory = categoryRepository.save(cat);
    }

    // ==========================================
    // 1. CATEGORY MANAGEMENT
    // ==========================================

    @Test
    @DisplayName("Public can list active categories; Admin can create new category; Non-admin is blocked")
    void testCategoryOperations() throws Exception {
        // Public list
        mockMvc.perform(get("/api/v1/services/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].slug").value("home-design"));

        // Admin create category
        CreateServiceCategoryRequest createReq = new CreateServiceCategoryRequest();
        createReq.setName("Vastu Consultation");
        createReq.setSlug("vastu-consultation");
        createReq.setIcon("compass_calibration");
        createReq.setDescription("Traditional spatial harmony consultations");
        createReq.setSortOrder(2);

        mockMvc.perform(post("/api/v1/admin/services/categories")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("Vastu Consultation"))
                .andExpect(jsonPath("$.data.slug").value("vastu-consultation"));

        // Non-admin blocked
        mockMvc.perform(post("/api/v1/admin/services/categories")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // 2. PARTNER ONBOARDING & LIFECYCLE
    // ==========================================

    @Test
    @DisplayName("Partner applies, cannot self-approve; Admin approves; Partner updates own profile")
    void testPartnerOnboardingAndApproval() throws Exception {
        ApplyServicePartnerRequest applyReq = new ApplyServicePartnerRequest();
        applyReq.setBusinessName("Zen Interiors Studio");
        applyReq.setServiceCategoryId(testCategory.getId());
        applyReq.setExperienceYears(8);
        applyReq.setCity("Bengaluru");
        applyReq.setServiceArea("Koramangala, Indiranagar, Whitefield");
        applyReq.setPhone("+919876543210");
        applyReq.setEmail("partner1@example.com");

        // 1. Partner applies
        String applyResp = mockMvc.perform(post("/api/v1/service-partners/apply")
                        .header("Authorization", "Bearer " + partner1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(applyReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.businessName").value("Zen Interiors Studio"))
                .andExpect(jsonPath("$.data.partnerStatus").value("PENDING"))
                .andExpect(jsonPath("$.data.verificationStatus").value("PENDING"))
                .andReturn().getResponse().getContentAsString();

        ServicePartnerProfileDto profileDto = objectMapper.readTree(applyResp).get("data").traverse(objectMapper).readValueAs(ServicePartnerProfileDto.class);
        UUID partnerId = profileDto.getId();

        // 2. Partner cannot self-approve via admin endpoint (403)
        UpdatePartnerStatusRequest approveReq = new UpdatePartnerStatusRequest();
        approveReq.setStatus(PartnerStatus.APPROVED);
        mockMvc.perform(patch("/api/v1/admin/service-partners/" + partnerId + "/status")
                        .header("Authorization", "Bearer " + partner1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(approveReq)))
                .andExpect(status().isForbidden());

        // 3. Admin approves partner
        mockMvc.perform(patch("/api/v1/admin/service-partners/" + partnerId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(approveReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.partnerStatus").value("APPROVED"));

        // 4. Admin verifies partner
        UpdatePartnerVerificationRequest verifyReq = new UpdatePartnerVerificationRequest();
        verifyReq.setVerificationStatus(PartnerVerificationStatus.VERIFIED);
        mockMvc.perform(patch("/api/v1/admin/service-partners/" + partnerId + "/verification")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(verifyReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.verificationStatus").value("VERIFIED"));

        // 5. Partner fetches own profile
        mockMvc.perform(get("/api/v1/service-partners/me")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.businessName").value("Zen Interiors Studio"))
                .andExpect(jsonPath("$.data.partnerStatus").value("APPROVED"));

        // 6. Partner updates contact info
        UpdateServicePartnerRequest updateReq = new UpdateServicePartnerRequest();
        updateReq.setPhone("+919988776655");
        updateReq.setDescription("Award-winning interior design studio in Bengaluru");
        mockMvc.perform(patch("/api/v1/service-partners/me")
                        .header("Authorization", "Bearer " + partner1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.phone").value("+919988776655"))
                .andExpect(jsonPath("$.data.description").value("Award-winning interior design studio in Bengaluru"));
    }

    // ==========================================
    // 3. SERVICE REQUEST SUBMISSION & IDOR
    // ==========================================

    @Test
    @DisplayName("Customer submits request; IDOR protection prevents Customer 2 from accessing it")
    void testServiceRequestSubmissionAndIdor() throws Exception {
        CreateServiceRequestDto createDto = new CreateServiceRequestDto();
        createDto.setServiceCategoryId(testCategory.getId());
        createDto.setTitle("3BHK Interior Consultation");
        createDto.setDescription("Need full wooden modular kitchen and living room false ceiling");
        createDto.setLocation("Whitefield, Bengaluru");
        createDto.setBudget(BigDecimal.valueOf(250000));
        createDto.setPriority(ServicePriority.HIGH);

        // 1. Customer 1 creates request
        String createResp = mockMvc.perform(post("/api/v1/services/requests")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createDto)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.serviceNumber").exists())
                .andExpect(jsonPath("$.data.status").value("NEW"))
                .andExpect(jsonPath("$.data.priority").value("HIGH"))
                .andExpect(jsonPath("$.data.serviceCategoryId").value(testCategory.getId().toString()))
                .andReturn().getResponse().getContentAsString();

        ServiceRequestDto requestDto = objectMapper.readTree(createResp).get("data").traverse(objectMapper).readValueAs(ServiceRequestDto.class);
        UUID requestId = requestDto.getId();

        // 2. Customer 1 can view details
        mockMvc.perform(get("/api/v1/services/requests/" + requestId)
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.request.id").value(requestId.toString()))
                .andExpect(jsonPath("$.data.request.title").value("3BHK Interior Consultation"));

        // 3. IDOR test: Customer 2 CANNOT access Customer 1's request
        mockMvc.perform(get("/api/v1/services/requests/" + requestId)
                        .header("Authorization", "Bearer " + customer2Token))
                .andExpect(status().isForbidden());

        // 4. Verify Journey event was logged automatically
        List<ServiceJourneyEvent> events = journeyEventRepository.findByServiceRequestIdOrderByCreatedAtAsc(requestId);
        assertFalse(events.isEmpty());
        assertEquals(ServiceJourneyEventType.REQUEST_CREATED, events.get(0).getEventType());
    }

    // ==========================================
    // 4. RECOMMENDATION, ASSIGNMENT & LIFECYCLE
    // ==========================================

    @Test
    @DisplayName("Admin assigns recommended partner; Partner accepts, starts, completes; Cross-partner IDOR blocked")
    void testEndToEndPartnerAssignmentAndLifecycle() throws Exception {
        // Setup approved partner 1
        ServicePartnerProfile p1 = createApprovedPartner(partner1UserId, "Master Craftsmen", "Bengaluru", 10);
        // Setup approved partner 2
        ServicePartnerProfile p2 = createApprovedPartner(partner2UserId, "Apex Design Co", "Mumbai", 5);

        // Customer creates request
        ServiceRequest req = createServiceRequest(customer1Id, testCategory.getId(), "Bengaluru", "Villa Interior", ServicePriority.HIGH);
        UUID requestId = req.getId();

        // 1. Admin gets recommendations
        mockMvc.perform(get("/api/v1/admin/service-requests/" + requestId + "/recommendations")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].businessName").value("Master Craftsmen"));

        // 2. Admin assigns partner 1
        AssignPartnerRequest assignReq = new AssignPartnerRequest();
        assignReq.setPartnerId(p1.getId());
        assignReq.setNotes("Top tier recommendation for premium villa");

        mockMvc.perform(post("/api/v1/admin/service-requests/" + requestId + "/assign")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.assignmentStatus").value("ASSIGNED"))
                .andExpect(jsonPath("$.data.partnerId").value(p1.getId().toString()));

        // 3. Partner 1 views assigned request
        mockMvc.perform(get("/api/v1/partner/service-requests/" + requestId)
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.request.id").value(requestId.toString()))
                .andExpect(jsonPath("$.data.request.status").value("ASSIGNED"));

        // 4. Partner 2 (unassigned) CANNOT access Partner 1's request (IDOR blocked)
        mockMvc.perform(get("/api/v1/partner/service-requests/" + requestId)
                        .header("Authorization", "Bearer " + partner2Token))
                .andExpect(status().isForbidden());

        // 5. Partner 1 accepts request
        mockMvc.perform(patch("/api/v1/partner/service-requests/" + requestId + "/accept")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("ACCEPTED"));

        // 6. Partner 1 starts service
        mockMvc.perform(patch("/api/v1/partner/service-requests/" + requestId + "/start")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("IN_PROGRESS"));

        // 7. Partner 1 completes service
        mockMvc.perform(patch("/api/v1/partner/service-requests/" + requestId + "/complete")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("COMPLETED"));

        // 8. Verify Journey timeline contains all state transitions
        mockMvc.perform(get("/api/v1/services/requests/" + requestId + "/journey")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(4))));
    }

    // ==========================================
    // 5. DOCUMENTS, MILESTONES & PROGRESS
    // ==========================================

    @Test
    @DisplayName("Document upload & verification; Milestone creation & customer approval; Partner self-approval blocked")
    void testDocumentsAndMilestones() throws Exception {
        ServicePartnerProfile p1 = createApprovedPartner(partner1UserId, "Design Pros", "Delhi", 7);
        ServiceRequest req = createServiceRequest(customer1Id, testCategory.getId(), "Delhi", "Full Renovation", ServicePriority.MEDIUM);
        req.setPartnerId(p1.getId());
        req.setStatus(ServiceRequestStatus.IN_PROGRESS);
        serviceRequestRepository.save(req);
        UUID requestId = req.getId();

        // 1. Upload document
        UploadDocumentRequest docReq = new UploadDocumentRequest();
        docReq.setDocumentType("FLOOR_PLAN");
        docReq.setFileName("Ground_Floor_CAD.pdf");
        docReq.setFileUrl("https://storage.propzen.ai/docs/cad_01.pdf");
        docReq.setFileSize(1024000L);

        String docResp = mockMvc.perform(post("/api/v1/services/requests/" + requestId + "/documents")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(docReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.fileName").value("Ground_Floor_CAD.pdf"))
                .andExpect(jsonPath("$.data.verificationStatus").value("UPLOADED"))
                .andReturn().getResponse().getContentAsString();

        UUID docId = objectMapper.readTree(docResp).get("data").get("id").traverse(objectMapper).readValueAs(UUID.class);

        // 2. Partner attempts to verify document -> blocked (403)
        mockMvc.perform(patch("/api/v1/services/documents/" + docId + "/verify")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isForbidden());

        // 3. Admin verifies document -> success
        mockMvc.perform(patch("/api/v1/services/documents/" + docId + "/verify")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.verificationStatus").value("VERIFIED"));

        // 4. Partner creates Milestone
        CreateMilestoneRequest mReq = new CreateMilestoneRequest();
        mReq.setTitle("Phase 1: 3D Renderings Delivery");
        mReq.setDescription("Submission and walkthrough of photorealistic 3D renders");
        mReq.setAmount(BigDecimal.valueOf(25000));
        mReq.setSequenceNumber(1);

        String mResp = mockMvc.perform(post("/api/v1/partner/service-requests/" + requestId + "/milestones")
                        .header("Authorization", "Bearer " + partner1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title").value("Phase 1: 3D Renderings Delivery"))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andReturn().getResponse().getContentAsString();

        UUID milestoneId = objectMapper.readTree(mResp).get("data").get("id").traverse(objectMapper).readValueAs(UUID.class);

        // 5. Partner attempts to approve milestone -> blocked (403)
        mockMvc.perform(patch("/api/v1/services/milestones/" + milestoneId + "/approve")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isForbidden());

        // 6. Customer approves milestone -> success
        mockMvc.perform(patch("/api/v1/services/milestones/" + milestoneId + "/approve")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("APPROVED"));

        // 7. Check calculated progress in request detail
        mockMvc.perform(get("/api/v1/services/requests/" + requestId)
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.progressPercentage").value(100.0));
    }

    // ==========================================
    // 6. PAYMENTS LEDGER & WEBHOOK SETTLEMENT
    // ==========================================

    @Test
    @DisplayName("Payment order creation; Provider webhook settlement updates balance and journey event")
    void testPaymentsLedgerAndWebhook() throws Exception {
        ServicePartnerProfile p1 = createApprovedPartner(partner1UserId, "Elite Builders", "Hyderabad", 12);
        ServiceRequest req = createServiceRequest(customer1Id, testCategory.getId(), "Hyderabad", "Structural Audit", ServicePriority.MEDIUM);
        req.setPartnerId(p1.getId());
        req.setStatus(ServiceRequestStatus.IN_PROGRESS);
        serviceRequestRepository.save(req);
        UUID requestId = req.getId();

        // 1. Customer initiates payment
        CreatePaymentRequest payReq = new CreatePaymentRequest();
        payReq.setServiceRequestId(requestId);
        payReq.setAmount(BigDecimal.valueOf(10000));
        payReq.setProvider(PaymentProviderType.MOCK);

        String payResp = mockMvc.perform(post("/api/v1/services/payments/create")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(payReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.amount").value(10000.0))
                .andExpect(jsonPath("$.data.status").value("PENDING"))
                .andExpect(jsonPath("$.data.providerOrderId").exists())
                .andReturn().getResponse().getContentAsString();

        ServicePaymentDto paymentDto = objectMapper.readTree(payResp).get("data").traverse(objectMapper).readValueAs(ServicePaymentDto.class);
        String providerOrderId = paymentDto.getProviderOrderId();

        // 2. Gateway webhook callback
        PaymentWebhookPayload webhook = new PaymentWebhookPayload();
        webhook.setOrderId(providerOrderId);
        webhook.setPaymentId("pay_gateway_mock_9999");
        webhook.setStatus("captured");
        webhook.setSignature("sig_test_valid_123");

        mockMvc.perform(post("/api/v1/services/payments/webhook")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(webhook)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value(true));

        // 3. Verify payment ledger status is updated to PAID
        mockMvc.perform(get("/api/v1/services/payments/" + paymentDto.getId())
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PAID"))
                .andExpect(jsonPath("$.data.providerPaymentId").value("pay_gateway_mock_9999"));
    }

    // ==========================================
    // 7. FEEDBACK & DUPLICATE RESTRICTION
    // ==========================================

    @Test
    @DisplayName("Customer submits feedback on completed service; Duplicate feedback is rejected")
    void testFeedbackSubmission() throws Exception {
        ServicePartnerProfile p1 = createApprovedPartner(partner1UserId, "Top Decor", "Pune", 9);
        ServiceRequest req = createServiceRequest(customer1Id, testCategory.getId(), "Pune", "Living Room Makeover", ServicePriority.LOW);
        req.setPartnerId(p1.getId());
        req.setStatus(ServiceRequestStatus.COMPLETED);
        serviceRequestRepository.save(req);
        UUID requestId = req.getId();

        // 1. Submit feedback
        CreateFeedbackRequest fbReq = new CreateFeedbackRequest();
        fbReq.setRating(5);
        fbReq.setComment("Sensational quality of work and prompt delivery. Highly recommended!");

        mockMvc.perform(post("/api/v1/services/requests/" + requestId + "/feedback")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(fbReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.rating").value(5))
                .andExpect(jsonPath("$.data.comment").value(containsString("Sensational quality")));

        // 2. Duplicate feedback attempt -> 400 DUPLICATE_RESOURCE
        mockMvc.perform(post("/api/v1/services/requests/" + requestId + "/feedback")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(fbReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error.code").value("DUPLICATE_RESOURCE"));

        // 3. Partner profile rating is updated
        ServicePartnerProfile updatedPartner = partnerProfileRepository.findById(p1.getId()).orElseThrow();
        assertEquals(0, BigDecimal.valueOf(5.0).compareTo(updatedPartner.getRating()));
    }

    // ==========================================
    // 8. PARTNER CRM CUSTOMER & NOTES
    // ==========================================

    @Test
    @DisplayName("Partner can view serviced customers and add CRM notes")
    void testPartnerCustomerCrm() throws Exception {
        ServicePartnerProfile p1 = createApprovedPartner(partner1UserId, "Master Painters", "Chennai", 6);
        ServiceRequest req = createServiceRequest(customer1Id, testCategory.getId(), "Chennai", "Full Wall Painting", ServicePriority.MEDIUM);
        req.setPartnerId(p1.getId());
        req.setStatus(ServiceRequestStatus.IN_PROGRESS);
        serviceRequestRepository.save(req);

        // 1. Partner lists serviced customers
        mockMvc.perform(get("/api/v1/partner/customers")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].customerId").value(customer1Id.toString()));

        // 2. Partner adds a CRM note
        CreateCustomerNoteRequest noteReq = new CreateCustomerNoteRequest();
        noteReq.setNote("Customer requested eco-friendly matte emulsion paint for master bedroom.");

        mockMvc.perform(post("/api/v1/partner/customers/" + customer1Id + "/notes")
                        .header("Authorization", "Bearer " + partner1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(noteReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.note").value(containsString("eco-friendly matte emulsion")));

        // 3. Partner reads CRM notes
        mockMvc.perform(get("/api/v1/partner/customers/" + customer1Id + "/notes")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].note").value(containsString("eco-friendly matte emulsion")));
    }

    // ==========================================
    // 9. DYNAMIC DASHBOARDS (PARTNER & ADMIN)
    // ==========================================

    @Test
    @DisplayName("Partner and Admin dynamic dashboard metrics are calculated from real database records")
    void testDynamicDashboards() throws Exception {
        ServicePartnerProfile p1 = createApprovedPartner(partner1UserId, "Global Architects", "Kolkata", 15);
        ServiceRequest req = createServiceRequest(customer1Id, testCategory.getId(), "Kolkata", "Architectural Blueprints", ServicePriority.HIGH);
        req.setPartnerId(p1.getId());
        req.setStatus(ServiceRequestStatus.IN_PROGRESS);
        serviceRequestRepository.save(req);

        ServicePayment pay = new ServicePayment();
        pay.setServiceRequestId(req.getId());
        pay.setPartnerId(p1.getId());
        pay.setCustomerId(customer1Id);
        pay.setAmount(BigDecimal.valueOf(50000));
        pay.setCurrency("INR");
        pay.setPaymentProvider(PaymentProviderType.MOCK);
        pay.setStatus(PaymentStatus.PAID);
        paymentRepository.save(pay);

        // 1. Partner dashboard
        mockMvc.perform(get("/api/v1/partner/dashboard")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.activeServices").value(1))
                .andExpect(jsonPath("$.data.totalEarnings").value(50000.0));

        // 2. Admin dashboard
        mockMvc.perform(get("/api/v1/admin/services/dashboard")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalRequests").value(1))
                .andExpect(jsonPath("$.data.activePartners").value(1))
                .andExpect(jsonPath("$.data.totalRevenue").value(50000.0));
    }

    // ==========================================
    // HELPER METHODS
    // ==========================================

    private ServicePartnerProfile createApprovedPartner(UUID userId, String name, String city, int years) {
        ServicePartnerProfile profile = new ServicePartnerProfile();
        profile.setUserId(userId);
        profile.setBusinessName(name);
        profile.setExperienceYears(years);
        profile.setCity(city);
        profile.setServiceArea(city);
        profile.setPhone("+919111222333");
        profile.setEmail(name.toLowerCase().replace(" ", "") + "@test.com");
        profile.setServiceCategoryId(testCategory.getId());
        profile.setPartnerStatus(PartnerStatus.APPROVED);
        profile.setVerificationStatus(PartnerVerificationStatus.VERIFIED);
        profile.setRating(BigDecimal.valueOf(4.8));
        profile.setTotalCompletedServices(25);
        profile.setTotalActiveServices(1);
        return partnerProfileRepository.save(profile);
    }

    private ServiceRequest createServiceRequest(UUID customerId, UUID categoryId, String location, String title, ServicePriority priority) {
        ServiceRequest req = new ServiceRequest();
        req.setServiceNumber("SR-" + System.currentTimeMillis() + "-" + ((int) (Math.random() * 1000)));
        req.setCustomerId(customerId);
        req.setServiceCategoryId(categoryId);
        req.setTitle(title);
        req.setDescription("Description for " + title);
        req.setLocation(location);
        req.setBudget(BigDecimal.valueOf(100000));
        req.setPriority(priority);
        req.setStatus(ServiceRequestStatus.NEW);
        return serviceRequestRepository.save(req);
    }
}
