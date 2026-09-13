package com.propzen.crm;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.crm.dto.CommunicationPreferenceDto;
import com.propzen.crm.dto.CreateCampaignRequest;
import com.propzen.crm.dto.CreateLeadRequest;
import com.propzen.crm.entity.AutomationRule;
import com.propzen.crm.entity.Campaign;
import com.propzen.crm.entity.CampaignRecipient;
import com.propzen.crm.entity.CommunicationPreference;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.entity.MessageTemplate;
import com.propzen.crm.model.CampaignChannel;
import com.propzen.crm.model.CampaignType;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.RecipientStatus;
import com.propzen.crm.notification.MockWhatsAppProvider;
import com.propzen.crm.repository.AutomationExecutionRepository;
import com.propzen.crm.repository.AutomationRuleRepository;
import com.propzen.crm.repository.CampaignRecipientRepository;
import com.propzen.crm.repository.CampaignRepository;
import com.propzen.crm.repository.CommunicationPreferenceRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.crm.repository.MessageTemplateRepository;
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
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CrmSecurityAndAutomationIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LeadRepository leadRepository;

    @Autowired
    private CampaignRepository campaignRepository;

    @Autowired
    private CampaignRecipientRepository recipientRepository;

    @Autowired
    private MessageTemplateRepository templateRepository;

    @Autowired
    private AutomationRuleRepository automationRuleRepository;

    @Autowired
    private AutomationExecutionRepository automationExecutionRepository;

    @Autowired
    private CommunicationPreferenceRepository preferenceRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Autowired
    private MockWhatsAppProvider mockWhatsAppProvider;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID buyerId;
    private String buyerToken;

    private UUID dealer1UserId;
    private UUID dealer1Id;
    private String dealer1Token;

    private UUID dealer2UserId;
    private UUID dealer2Id;
    private String dealer2Token;

    private UUID adminId;
    private String adminToken;

    @BeforeEach
    void setUp() {
        mockWhatsAppProvider.clear();
        recipientRepository.deleteAll();
        campaignRepository.deleteAll();
        templateRepository.deleteAll();
        automationExecutionRepository.deleteAll();
        automationRuleRepository.deleteAll();
        preferenceRepository.deleteAll();
        leadRepository.deleteAll();
        dealerProfileRepository.deleteAll();
        userRepository.deleteAll();

        // 1. Buyer
        buyerId = UUID.randomUUID();
        User buyer = new User(buyerId, "Buyer User", "buyer@propzen.ai", "+91 9100000001", "Buyer");
        userRepository.save(buyer);
        buyerToken = JwtTestUtils.generateValidToken(buyerId, "buyer@propzen.ai", "Buyer");

        // 2. Dealer 1
        dealer1UserId = UUID.randomUUID();
        User dealer1User = new User(dealer1UserId, "Dealer One", "dealer1@propzen.ai", "+91 9100000002", "Dealer");
        userRepository.save(dealer1User);
        dealer1Token = JwtTestUtils.generateDealerToken(dealer1UserId, "dealer1@propzen.ai");

        DealerProfile profile1 = new DealerProfile();
        profile1.setUserId(dealer1UserId);
        profile1.setBusinessName("Agency One");
        profile1.setPhone("+91 9100000002");
        profile1.setEmail("dealer1@propzen.ai");
        profile1.setStatus(DealerStatus.APPROVED);
        profile1.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealer1Id = dealerProfileRepository.save(profile1).getId();

        // 3. Dealer 2
        dealer2UserId = UUID.randomUUID();
        User dealer2User = new User(dealer2UserId, "Dealer Two", "dealer2@propzen.ai", "+91 9100000003", "Dealer");
        userRepository.save(dealer2User);
        dealer2Token = JwtTestUtils.generateDealerToken(dealer2UserId, "dealer2@propzen.ai");

        DealerProfile profile2 = new DealerProfile();
        profile2.setUserId(dealer2UserId);
        profile2.setBusinessName("Agency Two");
        profile2.setPhone("+91 9100000003");
        profile2.setEmail("dealer2@propzen.ai");
        profile2.setStatus(DealerStatus.APPROVED);
        profile2.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealer2Id = dealerProfileRepository.save(profile2).getId();

        // 4. Admin
        adminId = UUID.randomUUID();
        User admin = new User(adminId, "Admin User", "admin@propzen.ai", "+91 9100000004", "Admin");
        userRepository.save(admin);
        adminToken = JwtTestUtils.generateAdminToken(adminId, "admin@propzen.ai");
    }

    @Test
    @DisplayName("Security: Buyer is strictly blocked from CRM endpoints (403 Forbidden)")
    void test8_BuyerCannotAccessCrm() throws Exception {
        mockMvc.perform(get("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/crm/dashboard")
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security: Dealer cannot access or view another dealer's private leads (IDOR prevention)")
    void test9_DealerIsolationEnforced() throws Exception {
        // Lead assigned exclusively to Dealer 1
        Lead lead1 = new Lead();
        lead1.setLeadNumber("LEAD-DEALER1");
        lead1.setName("VIP Client of Dealer 1");
        lead1.setPhone("+91 9899001122");
        lead1.setDealerId(dealer1Id);
        lead1.setAssignedTo(dealer1UserId);
        UUID lead1Id = leadRepository.save(lead1).getId();

        // Dealer 2 attempts to fetch Dealer 1's lead
        mockMvc.perform(get("/api/v1/crm/leads/" + lead1Id)
                        .header("Authorization", "Bearer " + dealer2Token))
                .andExpect(status().isForbidden());

        // Dealer 2 searches leads: only sees Dealer 2's leads (count = 0)
        mockMvc.perform(get("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + dealer2Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(0));

        // Dealer 1 searches leads: sees own lead
        mockMvc.perform(get("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + dealer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].leadNumber").value("LEAD-DEALER1"));
    }

    @Test
    @DisplayName("Security: Admin can access all leads globally")
    void test10_AdminCanAccessAllLeads() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-GLOBAL");
        lead.setName("Global Buyer");
        lead.setPhone("+91 9899003344");
        lead.setDealerId(dealer1Id);
        UUID leadId = leadRepository.save(lead).getId();

        mockMvc.perform(get("/api/v1/crm/leads/" + leadId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Global Buyer"));
    }

    @Test
    @DisplayName("Campaign: Bulk Campaign Creation, Opt-Out Enforcement & Dispatch")
    void test17_CampaignCreationAndOptOutEnforcement() throws Exception {
        // Create template
        MessageTemplate template = new MessageTemplate();
        template.setName("Diwali Dhamaka Offer");
        template.setEventType("CAMPAIGN");
        template.setTemplateIdentifier("diwali_offer_2026");
        template.setBodyText("Special festive discount on luxury apartments!");
        UUID templateId = templateRepository.save(template).getId();

        // Lead 1: Opted in
        Lead lead1 = new Lead();
        lead1.setLeadNumber("L-OPTIN");
        lead1.setName("Anup Sharma");
        lead1.setPhone("+91 9870000001");
        leadRepository.save(lead1);

        // Lead 2: Opted out of marketing
        Lead lead2 = new Lead();
        lead2.setLeadNumber("L-OPTOUT");
        lead2.setName("Kavita Nair");
        lead2.setPhone("+91 9870000002");
        leadRepository.save(lead2);

        CommunicationPreference optOut = new CommunicationPreference();
        optOut.setPhone("+91 9870000002");
        optOut.setMarketingOptIn(false); // OPTED OUT
        preferenceRepository.save(optOut);

        // Create campaign
        CreateCampaignRequest req = new CreateCampaignRequest();
        req.setName("Diwali Festive Blast");
        req.setType(CampaignType.PROMOTIONAL);
        req.setChannel(CampaignChannel.WHATSAPP);
        req.setTemplateId(templateId);

        String campRes = mockMvc.perform(post("/api/v1/crm/campaigns")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.totalRecipients").value(2))
                .andReturn().getResponse().getContentAsString();

        String campaignIdStr = objectMapper.readTree(campRes).get("data").get("id").asText();
        UUID campaignId = UUID.fromString(campaignIdStr);

        // Send campaign
        mockMvc.perform(post("/api/v1/crm/campaigns/" + campaignId + "/send")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.sentCount").value(1)) // 1 sent
                .andExpect(jsonPath("$.data.status").value("COMPLETED"));

        // Verify that Lead 2 was SKIPPED due to marketing opt-out
        List<CampaignRecipient> recipients = recipientRepository.findByCampaignId(campaignId);
        CampaignRecipient skippedRecip = recipients.stream()
                .filter(r -> r.getPhone().equals("+91 9870000002"))
                .findFirst().orElseThrow();
        assertEquals(RecipientStatus.SKIPPED, skippedRecip.getStatus());
        assertTrue(skippedRecip.getFailureReason().contains("opted out"));

        // Verify MockWhatsAppProvider dispatched message to Lead 1
        assertEquals(1, mockWhatsAppProvider.getSentMessages().size());
        assertEquals("+91 9870000001", mockWhatsAppProvider.getSentMessages().get(0).to());
    }

    @Test
    @DisplayName("Automation: Event triggers automated message without real network call")
    void test22_AutomationRuleExecution() throws Exception {
        // Create an active automation rule for LEAD_CREATED
        AutomationRule rule = new AutomationRule();
        rule.setName("Auto Acknowledge New Lead");
        rule.setEventType("LEAD_CREATED");
        rule.setActionType("WHATSAPP_TEMPLATE");
        automationRuleRepository.save(rule);

        // Create a lead via API
        CreateLeadRequest leadReq = new CreateLeadRequest();
        leadReq.setName("Suresh Raina");
        leadReq.setPhone("+91 9812345678");
        leadReq.setSource(LeadSource.WEBSITE);

        mockMvc.perform(post("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(leadReq)))
                .andExpect(status().isCreated());

        // Verify automation execution was recorded
        assertEquals(1, automationExecutionRepository.count());
        assertEquals("SUCCESS", automationExecutionRepository.findAll().get(0).getStatus());

        // Verify Mock WhatsApp dispatched synthetic acknowledgement
        assertEquals(1, mockWhatsAppProvider.getSentMessages().size());
        assertEquals("+91 9812345678", mockWhatsAppProvider.getSentMessages().get(0).to());
    }

    @Test
    @DisplayName("Webhook: Meta Webhook Verification and Delivery Status Processing")
    void test23_WebhookVerificationAndProcessing() throws Exception {
        // Verification handshake test
        mockMvc.perform(get("/api/v1/webhooks/whatsapp")
                        .param("hub.mode", "subscribe")
                        .param("hub.verify_token", "propzen-webhook-verify-token-2026")
                        .param("hub.challenge", "challenge_code_12345"))
                .andExpect(status().isOk())
                .andExpect(content().string("challenge_code_12345"));

        // Inbound callback processing test
        CampaignRecipient recipient = new CampaignRecipient();
        recipient.setCampaignId(UUID.randomUUID());
        recipient.setPhone("+91 9876543210");
        recipient.setStatus(RecipientStatus.SENT);
        recipient.setProviderMessageId("wamid_test_123");
        recipientRepository.save(recipient);

        Map<String, Object> callbackPayload = Map.of(
                "providerMessageId", "wamid_test_123",
                "status", "DELIVERED"
        );

        mockMvc.perform(post("/api/v1/webhooks/whatsapp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(callbackPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").value("EVENT_RECEIVED"));

        CampaignRecipient updated = recipientRepository.findByProviderMessageId("wamid_test_123").orElseThrow();
        assertEquals(RecipientStatus.DELIVERED, updated.getStatus());
        assertNotNull(updated.getDeliveredAt());
    }
}
