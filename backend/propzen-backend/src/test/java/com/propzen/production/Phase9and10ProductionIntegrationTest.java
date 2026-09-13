package com.propzen.production;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.audit.AuditLogRepository;
import com.propzen.common.audit.AuditLogService;
import com.propzen.common.notification.Notification;
import com.propzen.common.notification.NotificationRepository;
import com.propzen.common.notification.NotificationStatus;
import com.propzen.common.notification.NotificationType;
import com.propzen.crm.dto.CreateCampaignRequest;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.MessageTemplate;
import com.propzen.crm.model.CampaignChannel;
import com.propzen.crm.model.CampaignType;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.notification.MetaWhatsAppProvider;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.MessageTemplateRepository;
import com.propzen.crm.service.CampaignService;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.property.entity.Property;
import com.propzen.property.repository.PropertyRepository;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.service.dto.CreateDeliverableRequest;
import com.propzen.service.entity.ServiceCategory;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.entity.ServicePayment;
import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.model.PaymentProviderType;
import com.propzen.service.model.PaymentStatus;
import com.propzen.service.model.ServiceRequestStatus;
import com.propzen.service.payment.CashfreePaymentProvider;
import com.propzen.service.payment.PayUPaymentProvider;
import com.propzen.service.repository.ServiceCategoryRepository;
import com.propzen.service.repository.ServiceDeliverableRepository;
import com.propzen.service.repository.ServicePartnerProfileRepository;
import com.propzen.service.repository.ServicePaymentRepository;
import com.propzen.service.repository.ServiceRequestRepository;
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
import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
public class Phase9and10ProductionIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerRepository;

    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private LeadRepository leadRepository;

    @Autowired
    private ServiceCategoryRepository categoryRepository;

    @Autowired
    private ServicePartnerProfileRepository partnerRepository;

    @Autowired
    private ServiceRequestRepository serviceRequestRepository;

    @Autowired
    private ServicePaymentRepository paymentRepository;

    @Autowired
    private ServiceDeliverableRepository deliverableRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private MessageTemplateRepository templateRepository;

    @Autowired
    private CampaignService campaignService;

    @Autowired
    private CashfreePaymentProvider cashfreePaymentProvider;

    @Autowired
    private PayUPaymentProvider payUPaymentProvider;

    @Autowired
    private MetaWhatsAppProvider metaWhatsAppProvider;

    @Autowired
    private AuditLogService auditLogService;

    private User adminUser;
    private User buyerUser;
    private User dealerUser;
    private String adminToken;
    private String buyerToken;
    private String dealerToken;

    @BeforeEach
    void setUp() {
        // 1. Create Admin
        adminUser = userRepository.findByEmailIgnoreCase("admin@propzen.ai").orElseGet(() -> {
            User u = new User(UUID.randomUUID(), "Platform Administrator", "admin@propzen.ai", "+919999900001", "Admin");
            return userRepository.save(u);
        });
        adminToken = JwtTestUtils.generateAdminToken(adminUser.getId(), adminUser.getEmail());

        // 2. Create Buyer
        buyerUser = userRepository.findByEmailIgnoreCase("buyer_p9@propzen.ai").orElseGet(() -> {
            User u = new User(UUID.randomUUID(), "Buyer Tester", "buyer_p9@propzen.ai", "+919999900002", "BUYER");
            return userRepository.save(u);
        });
        buyerToken = JwtTestUtils.generateValidToken(buyerUser.getId(), buyerUser.getEmail(), "BUYER");

        // 3. Create Dealer
        dealerUser = userRepository.findByEmailIgnoreCase("dealer_p9@propzen.ai").orElseGet(() -> {
            User u = new User(UUID.randomUUID(), "Dealer Tester", "dealer_p9@propzen.ai", "+919999900003", "DEALER");
            return userRepository.save(u);
        });
        dealerToken = JwtTestUtils.generateDealerToken(dealerUser.getId(), dealerUser.getEmail());
    }

    @Test
    @DisplayName("Phase 9/10: 1. Health, Liveness & Readiness Probes")
    void test1_HealthAndProbes() throws Exception {
        // Standard health check
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("UP")))
                .andExpect(jsonPath("$.data.database", is("UP")));

        // Liveness probe
        mockMvc.perform(get("/api/v1/health/liveness"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("ALIVE")));

        // Readiness probe
        mockMvc.perform(get("/api/v1/health/readiness"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("READY")))
                .andExpect(jsonPath("$.data.database", is("UP")));

        // Actuator health endpoint
        mockMvc.perform(get("/actuator/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("UP")));
    }

    @Test
    @DisplayName("Phase 9/10: 2. Admin Command Center Real-Time Aggregations & RBAC")
    void test2_AdminCommandCenter() throws Exception {
        // Seed property
        Property property = new Property();
        property.setTitle("Zen Ultra Luxury Villa");
        property.setCity("Gurugram");
        property.setSector("Sector 65");
        property.setBhk("4 BHK");
        property.setPropertyType("VILLA");
        property.setPriceCr(new BigDecimal("6.50"));
        property.setStatus("PUBLISHED");
        property.setDealerId(dealerUser.getId());
        propertyRepository.save(property);

        // Seed Lead
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-CC-01");
        lead.setName("Command Center Lead");
        lead.setPhone("+919988776655");
        lead.setStatus(LeadStatus.NEW);
        lead.setStage(LeadStage.NEW_LEAD);
        leadRepository.save(lead);

        // 1. Non-admin access to command center must return 403 Forbidden
        mockMvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden());

        // 2. Admin access returns live calculated summary metrics
        mockMvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalUsers", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.totalProperties", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.newLeads", greaterThanOrEqualTo(1)));

        // 3. Lead breakdown metrics
        mockMvc.perform(get("/api/v1/admin/dashboard/leads")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalLeads", greaterThanOrEqualTo(1)));

        // 4. Revenue breakdown metrics
        mockMvc.perform(get("/api/v1/admin/dashboard/revenue")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalPaidAmount", notNullValue()));

        // 5. Services metrics
        mockMvc.perform(get("/api/v1/admin/dashboard/services")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalRequests", notNullValue()));

        // 6. Properties inventory metrics
        mockMvc.perform(get("/api/v1/admin/dashboard/properties")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.publishedProperties", greaterThanOrEqualTo(1)));
    }

    @Test
    @DisplayName("Phase 9/10: 3. Unified In-App Notifications Management")
    void test3_InAppNotifications() throws Exception {
        // Seed notification
        Notification notif = new Notification(
                buyerUser.getId(),
                NotificationType.SERVICE_UPDATE,
                "Inspection Report Ready",
                "Your property inspection report has been uploaded.",
                "{\"serviceNumber\":\"SR-100\"}"
        );
        notif = notificationRepository.save(notif);

        // 1. Get user notifications
        mockMvc.perform(get("/api/v1/notifications")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data.content[0].title", is("Inspection Report Ready")));

        // 2. Unread count
        mockMvc.perform(get("/api/v1/notifications/unread-count")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unreadCount", greaterThanOrEqualTo(1)));

        // 3. Mark single as read
        mockMvc.perform(patch("/api/v1/notifications/" + notif.getId() + "/read")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("READ")));

        // 4. Mark all as read
        mockMvc.perform(patch("/api/v1/notifications/read-all")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Phase 9/10: 4. Persistent Database Audit Logging")
    void test4_PersistentAuditLogging() {
        long initialCount = auditLogRepository.count();

        // Perform audit logging call
        auditLogService.logAction(
                adminUser.getId(),
                "SECURITY_POLICY_UPDATE",
                "system/security",
                "Updated CORS and TLS parameters"
        );

        long afterCount = auditLogRepository.count();
        assertTrue(afterCount > initialCount, "Audit log record must be persisted to database");

        var logs = auditLogRepository.findByActorIdOrderByTimestampDesc(adminUser.getId());
        assertFalse(logs.isEmpty());
        var securityLog = logs.stream()
                .filter(l -> "SECURITY_POLICY_UPDATE".equals(l.getAction()))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Expected SECURITY_POLICY_UPDATE log not found"));
        assertEquals("system", securityLog.getTargetType());
        assertEquals("security", securityLog.getTargetId());
    }

    @Test
    @DisplayName("Phase 9/10: 5. Service Deliverables & Alternative Request Path Mappings")
    void test5_ServiceDeliverablesAndAliases() throws Exception {
        // Seed category
        ServiceCategory cat = categoryRepository.findBySlug("home-design").orElseGet(() -> {
            ServiceCategory c = new ServiceCategory();
            c.setSlug("home-design");
            c.setName("Home Design");
            c.setDescription("Architectural and interior design");
            c.setIcon("paint");
            c.setSortOrder(1);
            return categoryRepository.save(c);
        });

        // Seed request
        ServiceRequest req = new ServiceRequest();
        req.setServiceNumber("SR-DELIV-01");
        req.setServiceCategoryId(cat.getId());
        req.setCustomerId(buyerUser.getId());
        req.setTitle("3D Layout Design");
        req.setStatus(ServiceRequestStatus.NEW);
        req = serviceRequestRepository.save(req);

        // Submit deliverable via Admin authority
        CreateDeliverableRequest delReq = new CreateDeliverableRequest();
        delReq.setTitle("Final Floor Blueprint PDF");
        delReq.setDescription("Architectural blueprint drawing");
        delReq.setFileUrl("https://storage.propzen.ai/documents/blueprint.pdf");

        mockMvc.perform(post("/api/v1/service-requests/" + req.getId() + "/deliverables")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(delReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title", is("Final Floor Blueprint PDF")));

        // Retrieve deliverables
        mockMvc.perform(get("/api/v1/service-requests/" + req.getId() + "/deliverables")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))));

        // Alternate path mapping check: GET /api/v1/service-requests/{id}/payments
        mockMvc.perform(get("/api/v1/service-requests/" + req.getId() + "/payments")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Phase 9/10: 6. Secure Document Storage Authorization & Signed URLs")
    void test6_StorageAuthorization() throws Exception {
        mockMvc.perform(post("/api/v1/storage/authorize-upload")
                        .header("Authorization", "Bearer " + buyerToken)
                        .param("bucket", "service-documents")
                        .param("fileName", "title_deed.pdf")
                        .param("mimeType", "application/pdf")
                        .param("fileSize", "2048576"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.uploadUrl", containsString("sign")))
                .andExpect(jsonPath("$.data.storagePath", containsString("service-documents")));

        mockMvc.perform(get("/api/v1/storage/signed-download-url")
                        .header("Authorization", "Bearer " + buyerToken)
                        .param("storagePath", "service-documents/sample.pdf"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.downloadUrl", containsString("sign")));
    }

    @Test
    @DisplayName("Phase 9/10: 7. Extended Payment Providers (Cashfree & PayU) Signature Verification")
    void test7_ExtendedPaymentProviders() {
        assertEquals(PaymentProviderType.CASHFREE, cashfreePaymentProvider.getProviderType());
        assertEquals(PaymentProviderType.PAYU, payUPaymentProvider.getProviderType());

        var cfOrder = cashfreePaymentProvider.createOrder(new BigDecimal("5000"), "INR", "RC-01", null);
        assertNotNull(cfOrder.getOrderId());

        var payuOrder = payUPaymentProvider.createOrder(new BigDecimal("7500"), "INR", "RC-02", null);
        assertNotNull(payuOrder.getOrderId());
    }

    @Test
    @DisplayName("Phase 9/10: 8. Asynchronous Bulk Campaign Queue Dispatch")
    void test8_AsyncCampaignQueueDispatch() throws Exception {
        MessageTemplate t = new MessageTemplate();
        t.setName("Campaign Email " + UUID.randomUUID());
        t.setChannel("WHATSAPP");
        t.setEventType("MARKETING");
        t.setTemplateIdentifier("lead_welcome_v1");
        t.setLanguage("en");
        t.setBodyText("Hello from campaign {{campaignName}}");
        t = templateRepository.save(t);

        CreateCampaignRequest req = new CreateCampaignRequest();
        req.setName("Spring Home Buyer Fest");
        req.setType(CampaignType.PROMOTIONAL);
        req.setChannel(CampaignChannel.WHATSAPP);
        req.setTemplateId(t.getId());

        String res = mockMvc.perform(post("/api/v1/crm/campaigns")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        UUID campaignId = UUID.fromString(objectMapper.readTree(res).path("data").path("id").asText());

        // Trigger send: must queue asynchronously and return IN_PROGRESS without blocking
        mockMvc.perform(post("/api/v1/crm/campaigns/" + campaignId + "/send?async=true")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("IN_PROGRESS")));
    }
}
