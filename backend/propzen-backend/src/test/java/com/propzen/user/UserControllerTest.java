package com.propzen.user;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.security.jwt.JwtTestUtils;
import com.propzen.user.dto.UpdateUserProfileRequest;
import com.propzen.user.entity.User;
import com.propzen.user.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private UUID testUserId;
    private String testUserEmail;
    private String validToken;

    @BeforeEach
    void setUp() {
        testUserId = UUID.randomUUID();
        testUserEmail = "user." + testUserId.toString().substring(0, 8) + "@propzen.ai";

        User user = new User(testUserId, "Sakshi Buyer", testUserEmail, "9810394068", "Buyer");
        user.setEmailVerified(false);
        userRepository.save(user);

        validToken = JwtTestUtils.generateValidToken(testUserId, testUserEmail, "Buyer");
    }

    @Test
    void test1_AuthenticatedUserGetsOwnProfile() throws Exception {
        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer " + validToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(testUserId.toString()))
                .andExpect(jsonPath("$.data.email").value(testUserEmail))
                .andExpect(jsonPath("$.data.fullName").value("Sakshi Buyer"))
                .andExpect(jsonPath("$.data.phone").value("9810394068"))
                .andExpect(jsonPath("$.data.role").value("Buyer"))
                .andExpect(jsonPath("$.data.emailVerified").value(false));
    }

    @Test
    void test2_AnonymousRequestRejected() throws Exception {
        mockMvc.perform(get("/api/v1/users/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error.code").value("UNAUTHORIZED"));
    }

    @Test
    void test3_UserCannotReadAnotherUsersPrivateProfile() throws Exception {
        UUID otherUserId = UUID.randomUUID();
        User otherUser = new User(otherUserId, "Secret Admin", "admin.secret@propzen.ai", "9999999999", "ADMIN");
        userRepository.save(otherUser);

        // Caller uses testUserId token - me endpoint only ever returns testUserId
        mockMvc.perform(get("/api/v1/users/me")
                        .header("Authorization", "Bearer " + validToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(testUserId.toString()))
                .andExpect(jsonPath("$.data.email").value(testUserEmail))
                .andExpect(jsonPath("$.data.fullName").value("Sakshi Buyer"));
    }

    @Test
    void test4_ProfileUpdateWorks() throws Exception {
        UpdateUserProfileRequest request = new UpdateUserProfileRequest("Updated Name", "+91 9876543210");

        mockMvc.perform(patch("/api/v1/users/me")
                        .header("Authorization", "Bearer " + validToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.fullName").value("Updated Name"))
                .andExpect(jsonPath("$.data.phone").value("+91 9876543210"));

        User updated = userRepository.findById(testUserId).orElseThrow();
        assertEquals("Updated Name", updated.getFullName());
        assertEquals("+91 9876543210", updated.getPhone());
    }

    @Test
    void test5_RoleModificationAttemptRejected() throws Exception {
        // Attempt to pass role=ADMIN in the payload
        Map<String, Object> maliciousPayload = Map.of(
                "fullName", "Hacker Name",
                "role", "ADMIN",
                "roles", new String[]{"ROLE_ADMIN"}
        );

        mockMvc.perform(patch("/api/v1/users/me")
                        .header("Authorization", "Bearer " + validToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(maliciousPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("Hacker Name"))
                .andExpect(jsonPath("$.data.role").value("Buyer")); // Role remains Buyer!

        User updated = userRepository.findById(testUserId).orElseThrow();
        assertEquals("Buyer", updated.getRole(), "User database role must remain Buyer");
    }

    @Test
    void test6_EmailVerificationModificationRejected() throws Exception {
        Map<String, Object> maliciousPayload = Map.of(
                "fullName", "Verified Buyer",
                "isEmailVerified", true,
                "emailVerified", true
        );

        mockMvc.perform(patch("/api/v1/users/me")
                        .header("Authorization", "Bearer " + validToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(maliciousPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.emailVerified").value(false));

        User updated = userRepository.findById(testUserId).orElseThrow();
        assertFalse(updated.getEmailVerified(), "isEmailVerified must not be modified via profile update");
    }

    @Test
    void test7_UserIdentityCannotBeOverriddenInRequest() throws Exception {
        UUID spoofedId = UUID.randomUUID();
        Map<String, Object> maliciousPayload = Map.of(
                "id", spoofedId.toString(),
                "userId", spoofedId.toString(),
                "fullName", "Impersonator"
        );

        mockMvc.perform(patch("/api/v1/users/me")
                        .header("Authorization", "Bearer " + validToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(maliciousPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(testUserId.toString())); // Remains testUserId!

        assertFalse(userRepository.existsById(spoofedId), "Spoofed ID must not be created or updated");
    }
}
