package com.propzen.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.propzen.common.response.ApiResponse;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * High-performance sliding-window rate limiting filter protecting PropZen APIs against abuse.
 * Returns HTTP 429 when client request limits are exceeded.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 5)
public class RateLimitingFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitingFilter.class);

    private static final int DEFAULT_LIMIT_PER_MINUTE = 300;
    private static final int SENSITIVE_LIMIT_PER_MINUTE = 60;

    private final Map<String, WindowCounter> requestCounts = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();
        if (path.startsWith("/api/v1/health") || path.startsWith("/swagger-ui") || path.startsWith("/v3/api-docs")) {
            filterChain.doFilter(request, response);
            return;
        }

        String clientIp = getClientIp(request);
        int limit = isSensitiveEndpoint(path) ? SENSITIVE_LIMIT_PER_MINUTE : DEFAULT_LIMIT_PER_MINUTE;

        long currentMinute = System.currentTimeMillis() / 60000;
        String key = clientIp + ":" + currentMinute + ":" + (isSensitiveEndpoint(path) ? "sens" : "gen");

        WindowCounter counter = requestCounts.computeIfAbsent(key, k -> new WindowCounter(currentMinute));
        if (counter.increment() > limit) {
            log.warn("Rate limit exceeded for client {} on path {}", clientIp, path);
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setHeader("Retry-After", "60");

            String requestId = MDC.get("requestId");
            ApiResponse<Void> errorResp = ApiResponse.error(
                    "RATE_LIMIT_EXCEEDED",
                    "Rate limit exceeded. Please wait a moment before sending more requests."
            );
            if (requestId != null) {
                errorResp.setRequestId(requestId);
            }
            response.getWriter().write(objectMapper.writeValueAsString(errorResp));
            return;
        }

        // Clean old keys occasionally
        if (requestCounts.size() > 5000) {
            requestCounts.entrySet().removeIf(e -> e.getValue().minute < currentMinute - 2);
        }

        filterChain.doFilter(request, response);
    }

    private boolean isSensitiveEndpoint(String path) {
        return path.contains("/enquiries") ||
               path.contains("/leads") ||
               path.contains("/campaigns") ||
               path.contains("/whatsapp/send") ||
               path.contains("/storage/authorize-upload") ||
               path.contains("/payments/create");
    }

    private String getClientIp(HttpServletRequest request) {
        String cfIp = request.getHeader("CF-Connecting-IP");
        if (cfIp != null && isValidIp(cfIp.trim())) {
            return cfIp.trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && isValidIp(realIp.trim())) {
            return realIp.trim();
        }
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader != null && !xfHeader.isBlank()) {
            String candidate = xfHeader.split(",")[0].trim();
            if (isValidIp(candidate)) {
                return candidate;
            }
        }
        return request.getRemoteAddr();
    }

    private boolean isValidIp(String ip) {
        if (ip == null || ip.isBlank() || ip.length() > 45) return false;
        return ip.matches("^[0-9a-fA-F:.]+$");
    }

    private static class WindowCounter {
        final long minute;
        final AtomicInteger count = new AtomicInteger(0);

        WindowCounter(long minute) {
            this.minute = minute;
        }

        int increment() {
            return count.incrementAndGet();
        }
    }
}
