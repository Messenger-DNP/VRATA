package ru.vrata.backend.domain.service;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;

@Component
public class CryptoIdGenerator {
    private final SecureRandom secureRandom = new SecureRandom();

    public long nextPositiveLong() {
        return secureRandom.nextLong(1, Long.MAX_VALUE);
    }
}