package com.propzen.common.response;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class ApiResponseTest {

    @Test
    void testSuccessResponseCreation() {
        String testPayload = "test-data";
        ApiResponse<String> response = ApiResponse.success(testPayload, "Custom success message");

        assertTrue(response.isSuccess());
        assertEquals(testPayload, response.getData());
        assertEquals("Custom success message", response.getMessage());
        assertNotNull(response.getTimestamp());
        assertNotNull(response.getRequestId());
        assertNull(response.getError());
    }

    @Test
    void testDefaultSuccessResponse() {
        int count = 42;
        ApiResponse<Integer> response = ApiResponse.success(count);

        assertTrue(response.isSuccess());
        assertEquals(42, response.getData());
        assertEquals("Request successful", response.getMessage());
    }

    @Test
    void testErrorResponseCreation() {
        ApiResponse<Void> response = ApiResponse.error("NOT_FOUND", "Entity not found");

        assertFalse(response.isSuccess());
        assertNull(response.getData());
        assertNotNull(response.getError());
        assertEquals("NOT_FOUND", response.getError().getCode());
        assertEquals("Entity not found", response.getError().getMessage());
    }

    @Test
    void testErrorResponseWithDetails() {
        Map<String, String> fieldDetails = Map.of("email", "Must be valid email format");
        ApiResponse<Void> response = ApiResponse.error("VALIDATION_ERROR", "Invalid input", fieldDetails);

        assertFalse(response.isSuccess());
        assertNotNull(response.getError());
        assertEquals("VALIDATION_ERROR", response.getError().getCode());
        assertEquals(fieldDetails, response.getError().getDetails());
    }
}
