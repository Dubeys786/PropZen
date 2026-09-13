package com.propzen.security.handler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.response.ApiResponse;
import com.propzen.exception.ErrorCode;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Returns a standardized 403 Forbidden JSON response when an authenticated user attempts
 * to perform an operation exceeding their granted role permissions.
 */
@Component
public class PropzenAccessDeniedHandler implements AccessDeniedHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void handle(HttpServletRequest request,
                       HttpServletResponse response,
                       AccessDeniedException accessDeniedException) throws IOException, ServletException {

        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        ApiResponse<Void> apiResponse = ApiResponse.error(
                ErrorCode.FORBIDDEN.getCode(),
                "Access denied: Insufficient role permissions to access this resource."
        );

        response.getWriter().write(objectMapper.writeValueAsString(apiResponse));
    }
}
