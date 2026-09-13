package com.propzen.property;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.dealer.entity.DealerProfile;
import com.propzen.dealer.model.DealerStatus;
import com.propzen.dealer.model.DealerVerificationStatus;
import com.propzen.dealer.repository.DealerProfileRepository;
import com.propzen.property.dto.CreatePropertyRequest;
import com.propzen.property.dto.UpdatePropertyRequest;
import com.propzen.property.dto.UpdatePropertyStatusRequest;
import com.propzen.property.entity.Property;
import com.propzen.property.repository.PropertyRepository;
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
class PropertySecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PropertyRepository propertyRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DealerProfileRepository dealerProfileRepository;

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

    private UUID adminUserId;
    private String adminToken;

    @BeforeEach
    void setUp() {
        propertyRepository.deleteAll();
        dealerProfileRepository.deleteAll();
        userRepository.deleteAll();

        // 1. Setup Buyer User
        buyerId = UUID.randomUUID();
        User buyer = new User(buyerId, "Normal Buyer", "buyer@propzen.ai", "+91 9111111111", "Buyer");
        userRepository.save(buyer);
        buyerToken = JwtTestUtils.generateValidToken(buyerId, "buyer@propzen.ai", "Buyer");

        // 2. Setup Dealer 1
        dealer1UserId = UUID.randomUUID();
        User dealer1User = new User(dealer1UserId, "Dealer One", "dealer1@propzen.ai", "+91 9222222222", "Dealer");
        userRepository.save(dealer1User);
        dealer1Token = JwtTestUtils.generateDealerToken(dealer1UserId, "dealer1@propzen.ai");

        DealerProfile profile1 = new DealerProfile();
        profile1.setUserId(dealer1UserId);
        profile1.setBusinessName("Dealer 1 Properties");
        profile1.setPhone("+91 9222222222");
        profile1.setEmail("dealer1@propzen.ai");
        profile1.setStatus(DealerStatus.APPROVED);
        profile1.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealer1Id = dealerProfileRepository.save(profile1).getId();

        // 3. Setup Dealer 2
        dealer2UserId = UUID.randomUUID();
        User dealer2User = new User(dealer2UserId, "Dealer Two", "dealer2@propzen.ai", "+91 9333333333", "Dealer");
        userRepository.save(dealer2User);
        dealer2Token = JwtTestUtils.generateDealerToken(dealer2UserId, "dealer2@propzen.ai");

        DealerProfile profile2 = new DealerProfile();
        profile2.setUserId(dealer2UserId);
        profile2.setBusinessName("Dealer 2 Properties");
        profile2.setPhone("+91 9333333333");
        profile2.setEmail("dealer2@propzen.ai");
        profile2.setStatus(DealerStatus.APPROVED);
        profile2.setVerificationStatus(DealerVerificationStatus.VERIFIED);
        dealer2Id = dealerProfileRepository.save(profile2).getId();

        // 4. Setup Admin
        adminUserId = UUID.randomUUID();
        User adminUser = new User(adminUserId, "PropZen Admin", "admin@propzen.ai", "+91 9444444444", "Admin");
        userRepository.save(adminUser);
        adminToken = JwtTestUtils.generateAdminToken(adminUserId, "admin@propzen.ai");
    }

    @Test
    @DisplayName("Security: Buyer cannot create property (403 Forbidden)")
    void test1_BuyerCannotCreateProperty() throws Exception {
        CreatePropertyRequest request = new CreatePropertyRequest();
        request.setTitle("Unauthorized Property");
        request.setCity("Noida");
        request.setSector("Sector 62");
        request.setPropertyType("Apartment");
        request.setPriceCr(BigDecimal.valueOf(1.0));
        request.setSqft(1200);

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + buyerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security: Approved Dealer can create property with server-assigned ownership")
    void test2_DealerCanCreateProperty() throws Exception {
        CreatePropertyRequest request = new CreatePropertyRequest();
        request.setTitle("Dealer Luxury Towers");
        request.setDescription("Premium apartments in Sector 150");
        request.setCity("Noida");
        request.setSector("Sector 150");
        request.setPropertyType("Apartment");
        request.setBhk("3 BHK");
        request.setPriceCr(BigDecimal.valueOf(1.35));
        request.setSqft(1750);
        request.setAmenities("Pool, Gym");
        request.setSubmitForReview(true);

        mockMvc.perform(post("/api/v1/properties")
                        .header("Authorization", "Bearer " + dealer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title").value("Dealer Luxury Towers"))
                .andExpect(jsonPath("$.data.status").value("SUBMITTED"))
                .andExpect(jsonPath("$.data.dealerId").value(dealer1Id.toString()));
    }

    @Test
    @DisplayName("Security: Dealer cannot modify another dealer's property")
    void test3_DealerCannotModifyAnotherDealersProperty() throws Exception {
        // Create property owned by Dealer 1
        Property p = new Property();
        p.setTitle("Dealer 1 Villa");
        p.setCity("Noida");
        p.setSector("Sector 150");
        p.setPropertyType("Villa");
        p.setPriceCr(BigDecimal.valueOf(2.5));
        p.setSqft(2500);
        p.setStatus("DRAFT");
        p.setOwnerId(dealer1UserId);
        p.setDealerId(dealer1Id);
        UUID propId = propertyRepository.save(p).getId();

        // Dealer 2 attempts to modify Dealer 1's property
        UpdatePropertyRequest update = new UpdatePropertyRequest();
        update.setTitle("Hacked Title by Dealer 2");

        mockMvc.perform(patch("/api/v1/properties/" + propId)
                        .header("Authorization", "Bearer " + dealer2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isForbidden());

        // Verify property unchanged
        Property unchanged = propertyRepository.findById(propId).orElseThrow();
        assertEquals("Dealer 1 Villa", unchanged.getTitle());
    }

    @Test
    @DisplayName("Security: Dealer cannot self-approve property")
    void test4_DealerCannotSelfApprove() throws Exception {
        Property p = new Property();
        p.setTitle("Dealer 1 Penthouse");
        p.setCity("Gurgaon");
        p.setSector("Golf Course Ext");
        p.setPropertyType("Apartment");
        p.setPriceCr(BigDecimal.valueOf(3.0));
        p.setSqft(3000);
        p.setStatus("SUBMITTED");
        p.setOwnerId(dealer1UserId);
        p.setDealerId(dealer1Id);
        UUID propId = propertyRepository.save(p).getId();

        // Attempting to call admin approval endpoint as dealer
        UpdatePropertyStatusRequest statusReq = new UpdatePropertyStatusRequest("PUBLISHED", "Self approved");

        mockMvc.perform(patch("/api/v1/admin/properties/" + propId + "/status")
                        .header("Authorization", "Bearer " + dealer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(statusReq)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Security: Admin can approve property and publish it")
    void test5_AdminCanApproveProperty() throws Exception {
        Property p = new Property();
        p.setTitle("Under Review Mansion");
        p.setCity("Gurgaon");
        p.setSector("Sector 42");
        p.setPropertyType("Villa");
        p.setPriceCr(BigDecimal.valueOf(5.0));
        p.setSqft(5000);
        p.setStatus("SUBMITTED");
        p.setOwnerId(dealer1UserId);
        p.setDealerId(dealer1Id);
        UUID propId = propertyRepository.save(p).getId();

        UpdatePropertyStatusRequest statusReq = new UpdatePropertyStatusRequest("PUBLISHED", "Verified documentation and approved");

        mockMvc.perform(patch("/api/v1/admin/properties/" + propId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(statusReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("PUBLISHED"))
                .andExpect(jsonPath("$.data.verificationStatus").value("VERIFIED"));

        // Verify it is now visible in public search
        mockMvc.perform(get("/api/v1/properties/" + propId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Under Review Mansion"));
    }

    @Test
    @DisplayName("Security: Dealer Dashboard strictly returns only own properties")
    void test6_DealerDashboardEnforcesOwnershipIsolation() throws Exception {
        // Dealer 1 property
        Property p1 = new Property();
        p1.setTitle("Dealer 1 Exclusive");
        p1.setCity("Noida");
        p1.setPriceCr(BigDecimal.valueOf(1.0));
        p1.setSqft(1000);
        p1.setStatus("DRAFT");
        p1.setDealerId(dealer1Id);
        propertyRepository.save(p1);

        // Dealer 2 property
        Property p2 = new Property();
        p2.setTitle("Dealer 2 Exclusive");
        p2.setCity("Delhi");
        p2.setPriceCr(BigDecimal.valueOf(2.0));
        p2.setSqft(2000);
        p2.setStatus("DRAFT");
        p2.setDealerId(dealer2Id);
        propertyRepository.save(p2);

        // Dealer 1 requests /api/v1/dealers/me/properties
        mockMvc.perform(get("/api/v1/dealers/me/properties")
                        .header("Authorization", "Bearer " + dealer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.content[0].title").value("Dealer 1 Exclusive"));
    }

    @Test
    @DisplayName("Security: SQL injection patterns are treated strictly as string literals")
    void test7_SqlInjectionSafety() throws Exception {
        mockMvc.perform(get("/api/v1/properties?city=' OR 1=1 --"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(0));
    }

    @Test
    @DisplayName("Security: Oversized page requests are rejected")
    void test8_OversizedPageRejected() throws Exception {
        mockMvc.perform(get("/api/v1/properties?size=500"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @DisplayName("Security: Non-published properties are hidden from unprivileged callers")
    void test9_NonPublishedPropertiesHidden() throws Exception {
        Property draft = new Property();
        draft.setTitle("Secret Off-Market Plot");
        draft.setCity("Noida");
        draft.setPriceCr(BigDecimal.valueOf(3.0));
        draft.setSqft(2000);
        draft.setStatus("DRAFT");
        draft.setDealerId(dealer1Id);
        draft.setOwnerId(dealer1UserId);
        UUID draftId = propertyRepository.save(draft).getId();

        // Public caller cannot view details
        mockMvc.perform(get("/api/v1/properties/" + draftId))
                .andExpect(status().isNotFound());

        // Buyer cannot view details
        mockMvc.perform(get("/api/v1/properties/" + draftId)
                        .header("Authorization", "Bearer " + buyerToken))
                .andExpect(status().isNotFound());

        // Owner Dealer CAN view details
        mockMvc.perform(get("/api/v1/properties/" + draftId)
                        .header("Authorization", "Bearer " + dealer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Secret Off-Market Plot"));

        // Admin CAN view details
        mockMvc.perform(get("/api/v1/admin/properties/" + draftId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Secret Off-Market Plot"));
    }
}
