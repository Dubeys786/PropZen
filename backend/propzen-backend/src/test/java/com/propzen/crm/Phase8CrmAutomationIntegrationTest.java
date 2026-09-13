package com.propzen.crm;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.crm.automation.OutboxProcessor;
import com.propzen.crm.automation.OutboxService;
import com.propzen.crm.dto.CreateActivityRequest;
import com.propzen.crm.dto.CreateFollowUpDto;
import com.propzen.crm.dto.CreateLeadRequest;
import com.propzen.crm.dto.CreateNoteRequest;
import com.propzen.crm.dto.CreateTaskRequest;
import com.propzen.crm.dto.OneClickWhatsAppRequest;
import com.propzen.crm.dto.UpdateLeadStageRequest;
import com.propzen.crm.dto.UpdateNoteRequest;
import com.propzen.crm.dto.UpdateTaskRequest;
import com.propzen.crm.entity.CrmOutboxEvent;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.WhatsAppTemplateEntity;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CrmActivityType;
import com.propzen.crm.model.FollowUpPriority;
import com.propzen.crm.model.FollowUpStatus;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.LeadType;
import com.propzen.crm.model.OutboxStatus;
import com.propzen.crm.model.TaskPriority;
import com.propzen.crm.model.TaskStatus;
import com.propzen.crm.model.WhatsAppTemplateCategory;
import com.propzen.crm.model.WhatsAppTemplateStatus;
import com.propzen.crm.notification.MockWhatsAppProvider;
import com.propzen.crm.repository.ContactPreferenceRepository;
import com.propzen.crm.repository.CrmActivityRepository;
import com.propzen.crm.repository.CrmAssignmentHistoryRepository;
import com.propzen.crm.repository.CrmCommunicationRepository;
import com.propzen.crm.repository.CrmFollowUpRepository;
import com.propzen.crm.repository.CrmNoteRepository;
import com.propzen.crm.repository.CrmOutboxEventRepository;
import com.propzen.crm.repository.CrmTagRepository;
import com.propzen.crm.repository.CrmTaskRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.WhatsAppTemplateRepository;
import com.propzen.crm.service.LeadDeduplicationService;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.security.jwt.JwtTestUtils;
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

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class Phase8CrmAutomationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LeadRepository leadRepository;

    @Autowired
    private CrmActivityRepository activityRepository;

    @Autowired
    private CrmNoteRepository noteRepository;

    @Autowired
    private CrmFollowUpRepository followUpRepository;

    @Autowired
    private CrmTaskRepository taskRepository;

    @Autowired
    private CrmCommunicationRepository communicationRepository;

    @Autowired
    private WhatsAppTemplateRepository templateRepository;

    @Autowired
    private ContactPreferenceRepository preferenceRepository;

    @Autowired
    private CrmOutboxEventRepository outboxRepository;

    @Autowired
    private CrmTagRepository tagRepository;

    @Autowired
    private CrmAssignmentHistoryRepository assignmentHistoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Autowired
    private LeadDeduplicationService deduplicationService;

    @Autowired
    private OutboxService outboxService;

    @Autowired
    private OutboxProcessor outboxProcessor;

    @Autowired
    private MockWhatsAppProvider mockWhatsAppProvider;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID adminId;
    private String adminToken;

    private UUID dealerUserId;
    private UUID dealerId;
    private String dealerToken;

    private UUID customerId;
    private String customerToken;

    @BeforeEach
    void setUp() {
        mockWhatsAppProvider.clear();
        outboxRepository.deleteAll();
        communicationRepository.deleteAll();
        noteRepository.deleteAll();
        activityRepository.deleteAll();
        followUpRepository.deleteAll();
        taskRepository.deleteAll();
        assignmentHistoryRepository.deleteAll();
        leadRepository.deleteAll();
        preferenceRepository.deleteAll();
        dealerProfileRepository.deleteAll();
        userRepository.deleteAll();

        // 1. Setup Admin
        adminId = UUID.randomUUID();
        User admin = new User(adminId, "Admin PropZen", "admin@propzen.ai", "+919999900001", "Admin");
        userRepository.save(admin);
        adminToken = JwtTestUtils.generateAdminToken(adminId, "admin@propzen.ai");

        // 2. Setup Dealer
        dealerUserId = UUID.randomUUID();
        User dealerUser = new User(dealerUserId, "Dealer One", "dealer@propzen.ai", "+919999900002", "Dealer");
        userRepository.save(dealerUser);
        dealerToken = JwtTestUtils.generateDealerToken(dealerUserId, "dealer@propzen.ai");

        DealerProfile dealerProfile = new DealerProfile();
        dealerProfile.setUserId(dealerUserId);
        dealerProfile.setBusinessName("Zen Estates");
        dealerProfile.setPhone("+919999900002");
        dealerProfile.setEmail("dealer@propzen.ai");
        dealerProfile.setStatus(DealerStatus.APPROVED);
        dealerProfile.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealerId = dealerProfileRepository.save(dealerProfile).getId();

        // 3. Setup Customer
        customerId = UUID.randomUUID();
        User customer = new User(customerId, "Ananya Verma", "ananya@example.com", "+919876543210", "Buyer");
        userRepository.save(customer);
        customerToken = JwtTestUtils.generateValidToken(customerId, "ananya@example.com", "Buyer");

        // 4. Ensure WhatsApp template exists
        if (templateRepository.findByName("lead_welcome").isEmpty()) {
            WhatsAppTemplateEntity welcomeTpl = new WhatsAppTemplateEntity(
                    "lead_welcome",
                    "lead_welcome_v1",
                    "en",
                    WhatsAppTemplateCategory.UTILITY,
                    "Hello {{customer_name}}, thank you for your enquiry regarding {{property_title}} on PropZen.",
                    "customer_name,property_title"
            );
            templateRepository.save(welcomeTpl);
        }
    }

    @Test
    @DisplayName("Phase 8.1: Lead Deduplication by Phone - enriches existing lead")
    void test1_LeadDeduplication() throws Exception {
        // Create initial lead
        CreateLeadRequest req1 = new CreateLeadRequest();
        req1.setName("Ananya Verma");
        req1.setPhone("+919876543210");
        req1.setEmail("ananya@example.com");
        req1.setPropertyId("PROP-101");
        req1.setMessage("Initial inquiry");

        mockMvc.perform(post("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req1)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.phone", is("+919876543210")));

        assertEquals(1, leadRepository.count());

        // Attempt creating duplicate lead with same phone
        CreateLeadRequest req2 = new CreateLeadRequest();
        req2.setName("Ananya V.");
        req2.setPhone("+919876543210");
        req2.setPropertyId("PROP-102");
        req2.setMessage("Second inquiry for another property");

        mockMvc.perform(post("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req2)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.phone", is("+919876543210")));

        // Count must still be 1 (deduplicated!)
        assertEquals(1, leadRepository.count());
        Lead enriched = leadRepository.findAll().get(0);
        assertEquals("PROP-102", enriched.getPropertyId());
    }

    @Test
    @DisplayName("Phase 8.2: Lead Pipeline Funnel Stage Transition")
    void test2_LeadStageTransition() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-STAGE-01");
        lead.setName("Raj Malhotra");
        lead.setPhone("+919111122222");
        lead.setStage(LeadStage.NEW_LEAD);
        lead.setStatus(LeadStatus.NEW);
        lead = leadRepository.save(lead);

        UpdateLeadStageRequest stageReq = new UpdateLeadStageRequest(LeadStage.INTERESTED, "Buyer interested after call");

        mockMvc.perform(patch("/api/v1/crm/leads/" + lead.getId() + "/stage")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(stageReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.stage", is("INTERESTED")));

        Lead updated = leadRepository.findById(lead.getId()).orElseThrow();
        assertEquals(LeadStage.INTERESTED, updated.getStage());
    }

    @Test
    @DisplayName("Phase 8.3: Lead Conversion to Customer/Sale")
    void test3_LeadConversion() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-CONV-01");
        lead.setName("Pooja Hegde");
        lead.setPhone("+919333344444");
        lead.setStage(LeadStage.NEGOTIATION);
        lead.setStatus(LeadStatus.NEGOTIATION);
        lead = leadRepository.save(lead);

        mockMvc.perform(patch("/api/v1/crm/leads/" + lead.getId() + "/convert")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("CONVERTED")))
                .andExpect(jsonPath("$.data.stage", is("CONVERTED")));

        Lead converted = leadRepository.findById(lead.getId()).orElseThrow();
        assertEquals(LeadStatus.CONVERTED, converted.getStatus());
        assertEquals(LeadStage.CONVERTED, converted.getStage());
        assertNotNull(converted.getConvertedAt());
    }

    @Test
    @DisplayName("Phase 8.4: Lead Deletion by Admin and RBAC Protection")
    void test4_LeadDeletion() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-DEL-01");
        lead.setName("Vikram Seth");
        lead.setPhone("+919555566666");
        lead = leadRepository.save(lead);

        // Regular buyer cannot delete (403)
        mockMvc.perform(delete("/api/v1/crm/leads/" + lead.getId())
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());

        // Admin can delete (200)
        mockMvc.perform(delete("/api/v1/crm/leads/" + lead.getId())
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());

        assertTrue(leadRepository.findById(lead.getId()).isEmpty());
    }

    @Test
    @DisplayName("Phase 8.5: CRM Internal Notes CRUD")
    void test5_CrmNotes() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-NOTE-01");
        lead.setName("Sanjay Dutt");
        lead.setPhone("+919777788888");
        lead = leadRepository.save(lead);

        // Add note
        CreateNoteRequest noteReq = new CreateNoteRequest(lead.getId(), null, "Client requested high-floor corner unit.");
        String noteResponse = mockMvc.perform(post("/api/v1/crm/notes")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(noteReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.note", containsString("high-floor corner unit")))
                .andReturn().getResponse().getContentAsString();

        String noteIdStr = objectMapper.readTree(noteResponse).path("data").path("id").asText();
        UUID noteId = UUID.fromString(noteIdStr);

        // Fetch notes for lead
        mockMvc.perform(get("/api/v1/crm/leads/" + lead.getId() + "/notes")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)));

        // Update note
        UpdateNoteRequest updateReq = new UpdateNoteRequest("Client confirmed high-floor 14th floor unit.");
        mockMvc.perform(patch("/api/v1/crm/notes/" + noteId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.note", containsString("14th floor unit")));

        // Delete note
        mockMvc.perform(delete("/api/v1/crm/notes/" + noteId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());

        assertEquals(0, noteRepository.count());
    }

    @Test
    @DisplayName("Phase 8.6: CRM Follow-Up Scheduling and Completion")
    void test6_FollowUps() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-FUP-01");
        lead.setName("Karan Johar");
        lead.setPhone("+919888899999");
        lead = leadRepository.save(lead);

        CreateFollowUpDto fupReq = new CreateFollowUpDto();
        fupReq.setLeadId(lead.getId());
        fupReq.setTitle("Call back about loan documentation");
        fupReq.setFollowupAt(OffsetDateTime.now().plusDays(2));
        fupReq.setPriority(FollowUpPriority.HIGH);

        String fupRes = mockMvc.perform(post("/api/v1/crm/follow-ups")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(fupReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title", is("Call back about loan documentation")))
                .andExpect(jsonPath("$.data.status", is("PENDING")))
                .andReturn().getResponse().getContentAsString();

        String fupIdStr = objectMapper.readTree(fupRes).path("data").path("id").asText();
        UUID fupId = UUID.fromString(fupIdStr);

        // Complete follow-up
        mockMvc.perform(patch("/api/v1/crm/follow-ups/" + fupId + "/complete")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("Phase 8.7: CRM Internal Tasks Creation and Completion")
    void test7_CrmTasks() throws Exception {
        CreateTaskRequest taskReq = new CreateTaskRequest();
        taskReq.setTitle("Prepare resale agreement draft");
        taskReq.setDescription("Include customized payment milestones");
        taskReq.setPriority(TaskPriority.HIGH);
        taskReq.setDueAt(OffsetDateTime.now().plusDays(3));

        String taskRes = mockMvc.perform(post("/api/v1/crm/tasks")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(taskReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title", is("Prepare resale agreement draft")))
                .andExpect(jsonPath("$.data.status", is("TODO")))
                .andReturn().getResponse().getContentAsString();

        String taskIdStr = objectMapper.readTree(taskRes).path("data").path("id").asText();
        UUID taskId = UUID.fromString(taskIdStr);

        // Update task
        UpdateTaskRequest updateReq = new UpdateTaskRequest();
        updateReq.setStatus(TaskStatus.IN_PROGRESS);
        mockMvc.perform(patch("/api/v1/crm/tasks/" + taskId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("IN_PROGRESS")));

        // Complete task
        mockMvc.perform(patch("/api/v1/crm/tasks/" + taskId + "/complete")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("COMPLETED")));
    }

    @Test
    @DisplayName("Phase 8.8: Official WhatsApp Template Notification Dispatch")
    void test8_WhatsAppDispatch() throws Exception {
        OneClickWhatsAppRequest req = new OneClickWhatsAppRequest(
                "+919876543210",
                "lead_welcome",
                Map.of("customer_name", "Ananya", "property_title", "Zen Heights 3BHK")
        );

        mockMvc.perform(post("/api/v1/whatsapp/send")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.channel", is("WHATSAPP")))
                .andExpect(jsonPath("$.data.status", is("SENT")));

        assertEquals(1, mockWhatsAppProvider.getSentMessages().size());
        assertEquals("+919876543210", mockWhatsAppProvider.getSentMessages().get(0).to());
        assertEquals("lead_welcome_v1", mockWhatsAppProvider.getSentMessages().get(0).templateName());
    }

    @Test
    @DisplayName("Phase 8.9: Opt-Out & Opt-In Compliance Enforcement")
    void test9_OptOutEnforcement() throws Exception {
        // Opt out phone number
        mockMvc.perform(post("/api/v1/communication/opt-out")
                        .param("phone", "+919876543210")
                        .param("channel", "WHATSAPP"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.whatsappOptIn", is(false)));

        // Try sending WhatsApp message to opted-out phone
        OneClickWhatsAppRequest req = new OneClickWhatsAppRequest(
                "+919876543210",
                "lead_welcome",
                Map.of("customer_name", "Ananya", "property_title", "Zen Heights 3BHK")
        );

        mockMvc.perform(post("/api/v1/whatsapp/send")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("FAILED")));

        // Provider must NOT have sent the message!
        assertEquals(0, mockWhatsAppProvider.getSentMessages().size());

        // Opt back in
        mockMvc.perform(post("/api/v1/communication/opt-in")
                        .param("phone", "+919876543210")
                        .param("channel", "WHATSAPP"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.whatsappOptIn", is(true)));
    }

    @Test
    @DisplayName("Phase 8.10: WhatsApp Webhook Delivery Status Processing")
    void test10_WhatsAppWebhook() throws Exception {
        Map<String, Object> webhookPayload = Map.of(
                "providerMessageId", "mock_msg_999",
                "status", "DELIVERED"
        );

        mockMvc.perform(post("/api/v1/webhooks/whatsapp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(webhookPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", is("EVENT_RECEIVED")));
    }

    @Test
    @DisplayName("Phase 8.11: Customer 360 Aggregator")
    void test11_Customer360() throws Exception {
        // Create lead for customer
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-360-01");
        lead.setName("Ananya Verma");
        lead.setPhone("+919876543210");
        lead.setEmail("ananya@example.com");
        lead.setUserId(customerId);
        leadRepository.save(lead);

        mockMvc.perform(get("/api/v1/crm/customers/" + customerId + "/360")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.customerId", is(customerId.toString())))
                .andExpect(jsonPath("$.data.fullName", is("Ananya Verma")))
                .andExpect(jsonPath("$.data.totalLeads", is(1)));
    }

    @Test
    @DisplayName("Phase 8.12: CRM Global Search")
    void test12_CrmSearch() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-SRCH-01");
        lead.setName("Deepak Chopra");
        lead.setPhone("+919444455555");
        leadRepository.save(lead);

        mockMvc.perform(get("/api/v1/crm/search")
                        .param("q", "Deepak")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.leads", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data.leads[0].name", is("Deepak Chopra")));
    }

    @Test
    @DisplayName("Phase 8.13: CRM Analytics Performance & Funnel Conversion")
    void test13_CrmAnalytics() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-ANL-01");
        lead.setName("Sunil Gavaskar");
        lead.setPhone("+919666677777");
        lead.setStatus(LeadStatus.CONVERTED);
        lead.setStage(LeadStage.CONVERTED);
        leadRepository.save(lead);

        mockMvc.perform(get("/api/v1/crm/analytics")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalLeads", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.overallConversionRate", greaterThanOrEqualTo(0.0)));
    }

    @Test
    @DisplayName("Phase 8.14: Transactional Outbox Publishing and Async Processing")
    void test14_TransactionalOutbox() {
        UUID aggregateId = UUID.randomUUID();
        CrmOutboxEvent event = outboxService.publishEvent(
                "LEAD_CREATED",
                "CRM_LEAD",
                aggregateId,
                Map.of("leadNumber", "LEAD-OUTBOX-1", "phone", "+919876543210")
        );

        assertNotNull(event.getId());

        // Process pending events via worker
        outboxProcessor.processPendingEvents();

        CrmOutboxEvent updated = outboxRepository.findById(event.getId()).orElseThrow();
        assertEquals(OutboxStatus.SENT, updated.getStatus());
        assertNotNull(updated.getProcessedAt());
    }

    @Test
    @DisplayName("Phase 8.15: Staff Lead Assignment History Tracking")
    void test15_AssignmentHistory() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-HIST-01");
        lead.setName("Kapil Dev");
        lead.setPhone("+919222233333");
        lead = leadRepository.save(lead);

        // Assign to dealer user
        mockMvc.perform(patch("/api/v1/crm/leads/" + lead.getId() + "/assign")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("assignedTo", dealerUserId))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.assignedTo", is(dealerUserId.toString())));

        assertEquals(1, assignmentHistoryRepository.findByLeadIdOrderByCreatedAtDesc(lead.getId()).size());
        assertEquals(dealerUserId, assignmentHistoryRepository.findByLeadIdOrderByCreatedAtDesc(lead.getId()).get(0).getToUser());
    }
}
