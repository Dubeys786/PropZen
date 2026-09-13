package com.propzen.ai.service;

import com.propzen.exception.BadRequestException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.regex.Pattern;

/**
 * Service protecting against prompt injection, malicious inputs, and credential leakage.
 */
@Service
public class AiSafetyService {

    private static final Logger log = LoggerFactory.getLogger(AiSafetyService.class);

    private static final Pattern[] PROMPT_INJECTION_PATTERNS = new Pattern[]{
            Pattern.compile("ignore\\s+(all\\s+)?(previous|prior)\\s+instructions", Pattern.CASE_INSENSITIVE),
            Pattern.compile("system\\s+prompt", Pattern.CASE_INSENSITIVE),
            Pattern.compile("disregard\\s+(all\\s+)?instructions", Pattern.CASE_INSENSITIVE),
            Pattern.compile("bypass\\s+rules", Pattern.CASE_INSENSITIVE),
            Pattern.compile("you\\s+are\\s+now\\s+in\\s+dan\\s+mode", Pattern.CASE_INSENSITIVE),
            Pattern.compile("show\\s+(me\\s+)?your\\s+(initial|system)\\s+instructions", Pattern.CASE_INSENSITIVE)
    };

    private static final Pattern[] SENSITIVE_TOKEN_PATTERNS = new Pattern[]{
            Pattern.compile("(?i)(password|secret|apikey|api_key|token|jwt|bearer)\\s*[:=]\\s*['\"]?[a-zA-Z0-9_.-]{8,}['\"]?"),
            Pattern.compile("\\b[A-Za-z0-9-_]{20,}\\.[A-Za-z0-9-_]{20,}\\.[A-Za-z0-9-_]{20,}\\b") // JWT-like strings
    };

    public void validateUserInput(String input) {
        if (input == null || input.isBlank()) {
            return;
        }

        for (Pattern p : PROMPT_INJECTION_PATTERNS) {
            if (p.matcher(input).find()) {
                log.warn("Prompt injection attempt detected and blocked: '{}'", p.pattern());
                throw new BadRequestException("Prompt injection attempt detected: Potential prompt manipulation. Request rejected.");
            }
        }
    }

    public void validatePayload(Object payload) {
        if (payload == null) return;
        if (payload instanceof String str) {
            validateUserInput(str);
        } else if (payload instanceof java.util.Map<?, ?> map) {
            for (Object val : map.values()) {
                validatePayload(val);
            }
        } else if (payload instanceof Iterable<?> iterable) {
            for (Object item : iterable) {
                validatePayload(item);
            }
        }
    }

    public String sanitizeInput(String input) {
        if (input == null) return "";
        validateUserInput(input);

        String sanitized = input;
        for (Pattern p : SENSITIVE_TOKEN_PATTERNS) {
            sanitized = p.matcher(sanitized).replaceAll("[REDACTED]");
        }
        return sanitized.trim();
    }
}
