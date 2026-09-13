package com.propzen.crm;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.notification.NotificationRepository;
import com.propzen.crm.dto.AssignPartnerRequest;
import com.propzen.crm.dto.CreateLeadRequest;
import com.propzen.crm.dto.LeadDto;
import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.repository.LeadActivityRepository;
import com.propzen.crm.repository.LeadRepository;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.service.entity.ServiceCategory;
import com.propzen.service.entity.ServicePartnerProfile;
import com.propzen.service.model.PartnerStatus;
import com.propzen.service.model.PartnerVerificationStatus;
import com.propzen.service.repository.ServiceCategoryRepository;
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
class ServicePartnerLeadRoutingIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LeadRepository leadRepository;

    @Autowired
    private LeadActivityRepository leadActivityRepository;

    @Autowired
    private ServicePartnerProfileRepository partnerProfileRepository;

    @Autowired
    private ServiceCategoryRepository categoryRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID adminUserId;
    private String adminToken;

    private UUID customerUserId;
    private String customerToken;

    private UUID partner1UserId;
    private ServicePartnerProfile partner1;
    private String partner1Token;

    private UUID partner2UserId;
    private ServicePartnerProfile partner2;
    private String partner2Token;

    private ServiceCategory loanCategory;

    @BeforeEach
    void setUp() {
        notificationRepository.deleteAll();
        leadActivityRepository.deleteAll();
        leadRepository.deleteAll();
        partnerProfileRepository.deleteAll();
        categoryRepository.deleteAll();
        userRepository.deleteAll();

        // 1. Setup Admin
        adminUserId = UUID.randomUUID();
        User adminUser = new User(adminUserId, "Admin Ops", "admin@propzen.ai", "+919999000001", "Admin");
        userRepository.save(adminUser);
        adminToken = JwtTestUtils.generateAdminToken(adminUserId, "admin@propzen.ai");

        // 2. Setup Customer
        customerUserId = UUID.randomUUID();
        User customerUser = new User(customerUserId, "Rahul Sharma", "rahul@customer.com", "+919876543210", "Buyer");
        userRepository.save(customerUser);
        customerToken = JwtTestUtils.generateValidToken(customerUserId, "rahul@customer.com", "Buyer");

        // 3. Setup Category
        loanCategory = new ServiceCategory();
        loanCategory.setName("Loan Consultancy");
        loanCategory.setSlug("loan-consultancy");
        loanCategory.setDescription("Home loan and financing assistance");
        loanCategory.setIsActive(true);
        loanCategory.setSortOrder(1);
        loanCategory = categoryRepository.save(loanCategory);

        // 4. Setup Partner 1 (Loan partner in Noida)
        partner1UserId = UUID.randomUUID();
        User p1User = new User(partner1UserId, "Apex Finance Corp", "apex@finance.com", "+919888800001", "SERVICE_PARTNER");
        userRepository.save(p1User);
        partner1Token = JwtTestUtils.generateValidToken(partner1UserId, "apex@finance.com", "SERVICE_PARTNER");

        partner1 = new ServicePartnerProfile();
        partner1.setUserId(partner1UserId);
        partner1.setBusinessName("Apex Finance Corp");
        partner1.setCompanyName("Apex Financial Services Pvt Ltd");
        partner1.setEmail("apex@finance.com");
        partner1.setPhone("+919888800001");
        partner1.setCity("Noida");
        partner1.setServiceArea("Noida, Greater Noida");
        partner1.setServiceCategoryId(loanCategory.getId());
        partner1.setServiceCategories("LOAN, LOAN_CONSULTANCY");
        partner1.setPartnerStatus(PartnerStatus.APPROVED);
        partner1.setVerificationStatus(PartnerVerificationStatus.VERIFIED);
        partner1.setRating(BigDecimal.valueOf(4.9));
        partner1.setTotalCompletedServices(50);
        partner1.setTotalActiveServices(2);
        partner1 = partnerProfileRepository.save(partner1);

        // 5. Setup Partner 2 (Interior Designer in Gurugram)
        partner2UserId = UUID.randomUUID();
        User p2User = new User(partner2UserId, "Zenith Interiors", "zenith@interiors.com", "+919888800002", "SERVICE_PARTNER");
        userRepository.save(p2User);
        partner2Token = JwtTestUtils.generateValidToken(partner2UserId, "zenith@interiors.com", "SERVICE_PARTNER");

        partner2 = new ServicePartnerProfile();
        partner2.setUserId(partner2UserId);
        partner2.setBusinessName("Zenith Interiors");
        partner2.setEmail("zenith@interiors.com");
        partner2.setPhone("+919888800002");
        partner2.setCity("Gurugram");
        partner2.setServiceCategories("INTERIOR_DESIGN, HOME_DESIGN");
        partner2.setPartnerStatus(PartnerStatus.APPROVED);
        partner2.setVerificationStatus(PartnerVerificationStatus.VERIFIED);
        partner2.setRating(BigDecimal.valueOf(4.8));
        partner2 = partnerProfileRepository.save(partner2);
    }

    @Test
    @DisplayName("Should automatically route service enquiry to matching eligible service partner")
    void test1_ServiceEnquiryAutoAssignedToEligiblePartner() throws Exception {
        CreateLeadRequest request = new CreateLeadRequest();
        request.setName("Rahul Sharma");
        request.setEmail("rahul@customer.com");
        request.setPhone("+919876543210");
        request.setServiceCategory("LOAN_CONSULTANCY");
        request.setPreferredCity("Noida");
        request.setMessage("Looking for home loan pre-approval for 75L in Sector 137");

        String res = mockMvc.perform(post("/api/v1/crm/leads/service-enquiry")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.serviceCategory").value("LOAN_CONSULTANCY"))
                .andExpect(jsonPath("$.data.assignmentStatus").value("ASSIGNED"))
                .andExpect(jsonPath("$.data.assignedPartnerId").value(partner1.getId().toString()))
                .andExpect(jsonPath("$.data.assignedPartnerName").value("Apex Finance Corp"))
                .andReturn().getResponse().getContentAsString();

        // Verify in-app notification delivered to partner1
        long notifs = notificationRepository.countByUserIdAndStatus(partner1UserId, com.propzen.common.notification.NotificationStatus.SENT);
        assertTrue(notifs >= 1, "In-app notification must be delivered to assigned partner");
    }

    @Test
    @DisplayName("Should route to UNASSIGNED queue when no matching partner is available")
    void test2_UnassignedFallbackWhenNoEligiblePartner() throws Exception {
        CreateLeadRequest request = new CreateLeadRequest();
        request.setName("Meera Kapoor");
        request.setEmail("meera@gmail.com");
        request.setPhone("+919876543299");
        request.setServiceCategory("SOLAR_ROOF_INSTALLATION");
        request.setPreferredCity("Noida");
        request.setMessage("Want solar panel quote for rooftop");

        mockMvc.perform(post("/api/v1/crm/leads/service-enquiry")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.assignmentStatus").value("UNASSIGNED"))
                .andExpect(jsonPath("$.data.assignedPartnerId").doesNotExist());
    }

    @Test
    @DisplayName("Should strictly isolate partner lead visibility and prevent cross-partner access")
    void test3_ServicePartnerIsolationAndAccessControl() throws Exception {
        // Create an assigned lead for partner 1
        Lead lead1 = new Lead();
        lead1.setLeadNumber("LEAD-P1-001");
        lead1.setName("Loan Applicant");
        lead1.setPhone("+919876543210");
        lead1.setServiceCategory("LOAN");
        lead1.setAssignedPartnerId(partner1.getId());
        lead1.setAssignmentStatus("ASSIGNED");
        lead1.setStatus(LeadStatus.NEW);
        lead1 = leadRepository.save(lead1);

        // Create an assigned lead for partner 2
        Lead lead2 = new Lead();
        lead2.setLeadNumber("LEAD-P2-001");
        lead2.setName("Interior Client");
        lead2.setPhone("+919876543211");
        lead2.setServiceCategory("INTERIOR_DESIGN");
        lead2.setAssignedPartnerId(partner2.getId());
        lead2.setAssignmentStatus("ASSIGNED");
        lead2.setStatus(LeadStatus.NEW);
        lead2 = leadRepository.save(lead2);

        // Partner 1 lists leads -> sees only lead 1
        mockMvc.perform(get("/api/v1/crm/leads")
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].leadNumber").value("LEAD-P1-001"));

        // Partner 1 accesses lead 1 -> 200 OK
        mockMvc.perform(get("/api/v1/crm/leads/" + lead1.getId())
                        .header("Authorization", "Bearer " + partner1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.leadNumber").value("LEAD-P1-001"));

        // Partner 2 tries to access lead 1 -> 403 Forbidden (IDOR prevention)
        mockMvc.perform(get("/api/v1/crm/leads/" + lead1.getId())
                        .header("Authorization", "Bearer " + partner2Token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Admin can list eligible partners, manually assign, and unassign a service lead")
    void test4_AdminManualAssignmentAndUnassignment() throws Exception {
        // Create unassigned lead
        Lead unassignedLead = new Lead();
        unassignedLead.setLeadNumber("LEAD-UNASSIGNED-01");
        unassignedLead.setName("Walk-in Client");
        unassignedLead.setPhone("+919876543222");
        unassignedLead.setServiceCategory("LOAN_CONSULTANCY");
        unassignedLead.setAssignmentStatus("UNASSIGNED");
        unassignedLead.setStatus(LeadStatus.NEW);
        unassignedLead = leadRepository.save(unassignedLead);

        // 1. Admin gets eligible partners
        mockMvc.perform(get("/api/v1/crm/leads/" + unassignedLead.getId() + "/eligible-partners")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].businessName").value("Apex Finance Corp"));

        // 2. Admin manually assigns to partner1
        AssignPartnerRequest assignReq = new AssignPartnerRequest(partner1.getId());
        mockMvc.perform(patch("/api/v1/crm/leads/" + unassignedLead.getId() + "/assign-partner")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(assignReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.assignmentStatus").value("ASSIGNED"))
                .andExpect(jsonPath("$.data.assignedPartnerId").value(partner1.getId().toString()))
                .andExpect(jsonPath("$.data.assignedPartnerName").value("Apex Finance Corp"));

        // 3. Admin unassigns partner
        mockMvc.perform(patch("/api/v1/crm/leads/" + unassignedLead.getId() + "/unassign-partner")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.assignmentStatus").value("UNASSIGNED"))
                .andExpect(jsonPath("$.data.assignedPartnerId").doesNotExist());
    }

    @Test
    @DisplayName("Customer can retrieve their own submitted service leads via /my")
    void test5_CustomerCanViewOwnServiceRequests() throws Exception {
        Lead customerLead = new Lead();
        customerLead.setLeadNumber("LEAD-CUST-001");
        customerLead.setUserId(customerUserId);
        customerLead.setName("Rahul Sharma");
        customerLead.setEmail("rahul@customer.com");
        customerLead.setPhone("+919876543210");
        customerLead.setServiceCategory("LOAN");
        customerLead.setAssignedPartnerId(partner1.getId());
        customerLead.setAssignmentStatus("ASSIGNED");
        customerLead.setStatus(LeadStatus.NEW);
        leadRepository.save(customerLead);

        mockMvc.perform(get("/api/v1/crm/leads/my")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].leadNumber").value("LEAD-CUST-001"))
                .andExpect(jsonPath("$.data[0].assignedPartnerName").value("Apex Finance Corp"));
    }
}
