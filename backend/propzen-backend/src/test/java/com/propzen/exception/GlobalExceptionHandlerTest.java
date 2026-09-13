package com.propzen.exception;

import com.propzen.common.response.ApiResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;

import static org.junit.jupiter.api.Assertions.*;

class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler exceptionHandler;

    @BeforeEach
    void setUp() {
        exceptionHandler = new GlobalExceptionHandler();
    }

    @Test
    void testHandleResourceNotFoundException() {
        ResourceNotFoundException ex = new ResourceNotFoundException("Property", "prop-999");
        ResponseEntity<ApiResponse<Void>> responseEntity = exceptionHandler.handleApiException(ex);

        assertEquals(HttpStatus.NOT_FOUND, responseEntity.getStatusCode());
        assertNotNull(responseEntity.getBody());
        assertFalse(responseEntity.getBody().isSuccess());
        assertEquals("RESOURCE_NOT_FOUND", responseEntity.getBody().getError().getCode());
        assertTrue(responseEntity.getBody().getError().getMessage().contains("prop-999"));
    }

    @Test
    void testHandleBadRequestException() {
        BadRequestException ex = new BadRequestException("Invalid price filter");
        ResponseEntity<ApiResponse<Void>> responseEntity = exceptionHandler.handleApiException(ex);

        assertEquals(HttpStatus.BAD_REQUEST, responseEntity.getStatusCode());
        assertNotNull(responseEntity.getBody());
        assertFalse(responseEntity.getBody().isSuccess());
        assertEquals("BAD_REQUEST", responseEntity.getBody().getError().getCode());
    }

    @Test
    void testHandleAccessDeniedException() {
        AccessDeniedException ex = new AccessDeniedException("Forbidden");
        ResponseEntity<ApiResponse<Void>> responseEntity = exceptionHandler.handleAccessDeniedException(ex);

        assertEquals(HttpStatus.FORBIDDEN, responseEntity.getStatusCode());
        assertNotNull(responseEntity.getBody());
        assertFalse(responseEntity.getBody().isSuccess());
        assertEquals("FORBIDDEN", responseEntity.getBody().getError().getCode());
    }

    @Test
    void testHandleGenericException() {
        Exception ex = new RuntimeException("Simulated unexpected failure");
        ResponseEntity<ApiResponse<Void>> responseEntity = exceptionHandler.handleGenericException(ex);

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, responseEntity.getStatusCode());
        assertNotNull(responseEntity.getBody());
        assertFalse(responseEntity.getBody().isSuccess());
        assertEquals("INTERNAL_SERVER_ERROR", responseEntity.getBody().getError().getCode());
        // Verify stack trace is NOT exposed
        assertFalse(responseEntity.getBody().getError().getMessage().contains("Simulated unexpected failure"));
    }
}
