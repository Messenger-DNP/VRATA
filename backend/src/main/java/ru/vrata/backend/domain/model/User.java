package ru.vrata.backend.domain.model;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Locale;
import java.util.regex.Pattern;

public record User(Long id, String username, String password) {
    private static final int USERNAME_MIN = 3;
    private static final int USERNAME_MAX = 50;
    private static final Pattern SHA256_HEX = Pattern.compile("^[0-9a-f]{64}$");

    public User {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("user id must be positive");
        }

        username = normalizeUsername(username);
        password = normalizePasswordHash(password);
    }

    public static String normalizeUsername(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("username must not be blank");
        }
        String normalized = raw.trim().toLowerCase(Locale.ROOT);
        if (normalized.length() < USERNAME_MIN || normalized.length() > USERNAME_MAX) {
            throw new IllegalArgumentException("username length must be between 3 and 50");
        }
        return normalized;
    }

    public static String normalizePasswordHash(String hash) {
        if (hash == null || hash.isBlank()) {
            throw new IllegalArgumentException("password hash must not be blank");
        }
        String normalized = hash.trim().toLowerCase(Locale.ROOT);
        if (!SHA256_HEX.matcher(normalized).matches()) {
            throw new IllegalArgumentException("password hash must be sha256 hex");
        }
        return normalized;
    }

    public boolean hasUsername(String candidate) {
        return username.equals(normalizeUsername(candidate));
    }

    public boolean matchesPasswordHash(String candidateHash) {
        String normalizedCandidate = normalizePasswordHash(candidateHash);
        return MessageDigest.isEqual(
                password.getBytes(StandardCharsets.UTF_8),
                normalizedCandidate.getBytes(StandardCharsets.UTF_8)
        );
    }
}
