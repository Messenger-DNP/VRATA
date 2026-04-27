package ru.vrata.backend.domain.service;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;

@Component
public class CryptoIdGenerator {
    // Keep IDs exactly representable in JavaScript (used by Flutter Web).
    private static final long MAX_JS_SAFE_INTEGER = 9_007_199_254_740_991L;
    private final SecureRandom secureRandom = new SecureRandom();

    public long nextPositiveLong() {
        return secureRandom.nextLong(1, MAX_JS_SAFE_INTEGER + 1);
    }
}
