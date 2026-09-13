package com.propzen.ai.service;

import com.propzen.ai.config.AiConfig;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory thread-safe cache for deterministic AI results (property descriptions, market summaries).
 */
@Service
public class AiCacheService {

    private final AiConfig config;
    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public AiCacheService(AiConfig config) {
        this.config = config;
    }

    public <T> T get(String key, Class<T> type) {
        if (!config.isCacheEnabled()) return null;

        CacheEntry entry = cache.get(key);
        if (entry != null && !entry.isExpired()) {
            return type.cast(entry.getValue());
        } else if (entry != null) {
            cache.remove(key);
        }
        return null;
    }

    public void put(String key, Object value, long ttlMs) {
        if (!config.isCacheEnabled()) return;
        cache.put(key, new CacheEntry(value, System.currentTimeMillis() + ttlMs));
    }

    public String computeKey(String operation, Object payload) {
        try {
            String combined = operation + ":" + (payload != null ? payload.toString() : "");
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(combined.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            return operation + ":" + (payload != null ? payload.hashCode() : 0);
        }
    }

    private static class CacheEntry {
        private final Object value;
        private final long expiry;

        public CacheEntry(Object value, long expiry) {
            this.value = value;
            this.expiry = expiry;
        }

        public Object getValue() {
            return value;
        }

        public boolean isExpired() {
            return System.currentTimeMillis() > expiry;
        }
    }
}
