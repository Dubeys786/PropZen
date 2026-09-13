package com.propzen.security.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.response.ApiResponse;
import com.propzen.exception.ErrorCode;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Returns a standardized 401 Unauthorized JSON response when an unauthenticated request
 * accesses a protected PropZen API endpoint.
 */
@Component
public class PropzenAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void commence(HttpServletRequest request,
                         HttpServletResponse response,
                         AuthenticationException authException) throws IOException, ServletException {

        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        ApiResponse<Void> apiResponse = ApiResponse.error(
                ErrorCode.UNAUTHORIZED.getCode(),
                "Authentication required. Please provide a valid Supabase Bearer token."
        );

        response.getWriter().write(objectMapper.writeValueAsString(apiResponse));
    }
}
