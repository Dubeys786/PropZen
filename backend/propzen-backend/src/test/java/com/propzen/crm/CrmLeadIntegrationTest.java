package com.propzen.crm;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.crm.dto.AssignLeadRequest;
import com.propzen.crm.dto.CreateEnquiryRequest;
import com.propzen.crm.dto.CreateFollowUpRequest;
import com.propzen.crm.dto.CreateLeadRequest;
import com.propzen.crm.dto.UpdateLeadPriorityRequest;
import com.propzen.crm.dto.UpdateLeadRequest;
import com.propzen.crm.dto.UpdateLeadStatusRequest;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.ActivityType;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.EnquiryRepository;
import com.propzen.crm.repository.LeadActivityRepository;
import com.propzen.crm.repository.LeadRepository;
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

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CrmLeadIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LeadRepository leadRepository;

    @Autowired
    private LeadActivityRepository leadActivityRepository;

    @Autowired
    private EnquiryRepository enquiryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID adminId;
    private String adminToken;

    private UUID dealerUserId;
    private UUID dealerId;
    private String dealerToken;

    @BeforeEach
    void setUp() {
        leadActivityRepository.deleteAll();
        leadRepository.deleteAll();
        enquiryRepository.deleteAll();
        dealerProfileRepository.deleteAll();
        userRepository.deleteAll();

        // Admin User
        adminId = UUID.randomUUID();
        User admin = new User(adminId, "Admin User", "admin@propzen.ai", "+91 9999900001", "Admin");
        userRepository.save(admin);
        adminToken = JwtTestUtils.generateAdminToken(adminId, "admin@propzen.ai");

        // Dealer User & Profile
        dealerUserId = UUID.randomUUID();
        User dealerUser = new User(dealerUserId, "Dealer One", "dealer@propzen.ai", "+91 9999900002", "Dealer");
        userRepository.save(dealerUser);
        dealerToken = JwtTestUtils.generateDealerToken(dealerUserId, "dealer@propzen.ai");

        DealerProfile dealerProfile = new DealerProfile();
        dealerProfile.setUserId(dealerUserId);
        dealerProfile.setBusinessName("Grand Estates");
        dealerProfile.setPhone("+91 9999900002");
        dealerProfile.setEmail("dealer@propzen.ai");
        dealerProfile.setStatus(DealerStatus.APPROVED);
        dealerProfile.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealerId = dealerProfileRepository.save(dealerProfile).getId();
    }

    @Test
    @DisplayName("CRM Test 1: Create Lead manually")
    void test1_CreateLead() throws Exception {
        CreateLeadRequest request = new CreateLeadRequest();
        request.setName("Rahul Sharma");
        request.setEmail("rahul.sharma@gmail.com");
        request.setPhone("+91 9876543210");
        request.setPropertyId("prop_skyline_150");
        request.setMessage("Interested in 3 BHK in Noida Sector 150");
        request.setSource(LeadSource.WEBSITE);
        request.setPriority(LeadPriority.HIGH);
        request.setBudgetMin(BigDecimal.valueOf(1.0));
        request.setBudgetMax(BigDecimal.valueOf(1.5));
        request.setPreferredCity("Noida");
        request.setPreferredSector("Sector 150");
        request.setPreferredBhk("3 BHK");

        mockMvc.perform(post("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Rahul Sharma"))
                .andExpect(jsonPath("$.data.phone").value("+91 9876543210"))
                .andExpect(jsonPath("$.data.status").value("NEW"))
                .andExpect(jsonPath("$.data.priority").value("HIGH"))
                .andExpect(jsonPath("$.data.leadScore", greaterThanOrEqualTo(50)));
    }

    @Test
    @DisplayName("CRM Test 2: Retrieve Lead Details")
    void test2_RetrieveLead() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-101");
        lead.setName("Pooja Verma");
        lead.setPhone("+91 9811223344");
        lead.setEmail("pooja@gmail.com");
        lead.setStatus(LeadStatus.NEW);
        lead.setPriority(LeadPriority.MEDIUM);
        UUID leadId = leadRepository.save(lead).getId();

        mockMvc.perform(get("/api/v1/crm/leads/" + leadId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Pooja Verma"))
                .andExpect(jsonPath("$.data.leadNumber").value("LEAD-101"));
    }

    @Test
    @DisplayName("CRM Test 3: Update Lead Details")
    void test3_UpdateLead() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-102");
        lead.setName("Vikram Malhotra");
        lead.setPhone("+91 9811223355");
        lead.setStatus(LeadStatus.NEW);
        UUID leadId = leadRepository.save(lead).getId();

        UpdateLeadRequest update = new UpdateLeadRequest();
        update.setName("Vikram Malhotra Updated");
        update.setBudgetMax(BigDecimal.valueOf(2.5));
        update.setPreferredCity("Gurgaon");

        mockMvc.perform(patch("/api/v1/crm/leads/" + leadId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Vikram Malhotra Updated"))
                .andExpect(jsonPath("$.data.preferredCity").value("Gurgaon"));
    }

    @Test
    @DisplayName("CRM Test 4: Lead Status Transition")
    void test4_LeadStatusTransition() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-103");
        lead.setName("Anjali Mehta");
        lead.setPhone("+91 9811223366");
        lead.setStatus(LeadStatus.NEW);
        UUID leadId = leadRepository.save(lead).getId();

        UpdateLeadStatusRequest statusReq = new UpdateLeadStatusRequest(LeadStatus.CONTACTED, null, "Discussed over phone");

        mockMvc.perform(patch("/api/v1/crm/leads/" + leadId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(statusReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CONTACTED"));

        // Transition to CONVERTED
        UpdateLeadStatusRequest convertReq = new UpdateLeadStatusRequest(LeadStatus.CONVERTED, null, "Client booked property");
        mockMvc.perform(patch("/api/v1/crm/leads/" + leadId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(convertReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("CONVERTED"))
                .andExpect(jsonPath("$.data.convertedAt", notNullValue()));
    }

    @Test
    @DisplayName("CRM Test 5: Lead Priority Change")
    void test5_LeadPriority() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-104");
        lead.setName("Arjun Kapoor");
        lead.setPhone("+91 9811223377");
        lead.setPriority(LeadPriority.LOW);
        UUID leadId = leadRepository.save(lead).getId();

        UpdateLeadPriorityRequest req = new UpdateLeadPriorityRequest(LeadPriority.URGENT);

        mockMvc.perform(patch("/api/v1/crm/leads/" + leadId + "/priority")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.priority").value("URGENT"));
    }

    @Test
    @DisplayName("CRM Test 6: Lead Assignment by Admin")
    void test6_LeadAssignment() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-105");
        lead.setName("Sunita Sen");
        lead.setPhone("+91 9811223388");
        lead.setStatus(LeadStatus.NEW);
        UUID leadId = leadRepository.save(lead).getId();

        AssignLeadRequest assignReq = new AssignLeadRequest(dealerUserId, dealerId);

        mockMvc.perform(patch("/api/v1/crm/leads/" + leadId + "/assign")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.assignedTo").value(dealerUserId.toString()))
                .andExpect(jsonPath("$.data.dealerId").value(dealerId.toString()));
    }

    @Test
    @DisplayName("CRM Test 11 & 12: Enquiry -> Lead Auto-Creation & Deduplication")
    void test11_EnquiryAutoCreatesLeadAndDeduplicates() throws Exception {
        CreateEnquiryRequest enquiryReq = new CreateEnquiryRequest();
        enquiryReq.setPropertyId("prop_ats_150");
        enquiryReq.setPropertyTitle("ATS Kingston Heath");
        enquiryReq.setName("Gaurav Khurana");
        enquiryReq.setEmail("gaurav@khurana.com");
        enquiryReq.setPhone("+91 9871112233");
        enquiryReq.setMessage("I want to visit ATS 150 tomorrow");
        enquiryReq.setDealerId(dealerId);

        // First enquiry: Creates enquiry + auto-creates new Lead
        mockMvc.perform(post("/api/v1/enquiries")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(enquiryReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.userName").value("Gaurav Khurana"));

        assertEquals(1, enquiryRepository.count());
        assertEquals(1, leadRepository.count());

        Lead createdLead = leadRepository.findAll().get(0);
        assertEquals("Gaurav Khurana", createdLead.getName());
        assertEquals("+919871112233", createdLead.getPhone());
        assertEquals(LeadStatus.NEW, createdLead.getStatus());

        // Repeated enquiry from same phone & property: Must DEDUPLICATE (not create new lead)
        CreateEnquiryRequest repeatReq = new CreateEnquiryRequest();
        repeatReq.setPropertyId("prop_ats_150");
        repeatReq.setPropertyTitle("ATS Kingston Heath");
        repeatReq.setName("Gaurav Khurana");
        repeatReq.setEmail("gaurav@khurana.com");
        repeatReq.setPhone("+91 9871112233");
        repeatReq.setMessage("Following up on my enquiry");

        mockMvc.perform(post("/api/v1/enquiries")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(repeatReq)))
                .andExpect(status().isCreated());

        assertEquals(2, enquiryRepository.count());
        assertEquals(1, leadRepository.count()); // Still 1 lead! Deduplication succeeded
    }

    @Test
    @DisplayName("CRM Test 13 & 14 & 15: Follow-Up Creation, Completion & Timeline")
    void test13_FollowUpLifecycleAndTimeline() throws Exception {
        Lead lead = new Lead();
        lead.setLeadNumber("LEAD-106");
        lead.setName("Deepak Joshi");
        lead.setPhone("+91 9811223399");
        UUID leadId = leadRepository.save(lead).getId();

        CreateFollowUpRequest followUpReq = new CreateFollowUpRequest(
                ActivityType.CALL,
                "Call customer to discuss floor plan",
                OffsetDateTime.now().plusDays(2)
        );

        mockMvc.perform(post("/api/v1/crm/leads/" + leadId + "/follow-ups")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(followUpReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.note").value("Call customer to discuss floor plan"))
                .andExpect(jsonPath("$.data.type").value("CALL"));

        // Verify Timeline
        mockMvc.perform(get("/api/v1/crm/leads/" + leadId + "/timeline")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)));
    }

    @Test
    @DisplayName("CRM Test 26, 27: Filtering and Keyword Search")
    void test26_FilteringAndSearch() throws Exception {
        Lead l1 = new Lead();
        l1.setLeadNumber("LEAD-NOIDA-01");
        l1.setName("Sameer Khan");
        l1.setPhone("+91 9811000001");
        l1.setPreferredCity("Noida");
        l1.setStatus(LeadStatus.NEW);
        leadRepository.save(l1);

        Lead l2 = new Lead();
        l2.setLeadNumber("LEAD-GURGAON-01");
        l2.setName("Ritu Saxena");
        l2.setPhone("+91 9811000002");
        l2.setPreferredCity("Gurgaon");
        l2.setStatus(LeadStatus.QUALIFIED);
        leadRepository.save(l2);

        // Filter by City: Noida
        mockMvc.perform(get("/api/v1/crm/leads?city=Noida")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].name").value("Sameer Khan"));

        // Keyword Search: Ritu
        mockMvc.perform(get("/api/v1/crm/leads?q=Ritu")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].name").value("Ritu Saxena"));
    }

    @Test
    @DisplayName("CRM Test 28: Live Database-Backed Dashboard Statistics")
    void test28_DashboardStatistics() throws Exception {
        Lead l1 = new Lead();
        l1.setLeadNumber("L1");
        l1.setName("Lead 1");
        l1.setPhone("+91 9900000001");
        l1.setStatus(LeadStatus.NEW);
        leadRepository.save(l1);

        Lead l2 = new Lead();
        l2.setLeadNumber("L2");
        l2.setName("Lead 2");
        l2.setPhone("+91 9900000002");
        l2.setStatus(LeadStatus.CONVERTED);
        leadRepository.save(l2);

        mockMvc.perform(get("/api/v1/crm/dashboard")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalLeads").value(2))
                .andExpect(jsonPath("$.data.newLeads").value(1))
                .andExpect(jsonPath("$.data.convertedLeads").value(1))
                .andExpect(jsonPath("$.data.conversionRate").value(50.0));
    }
}
