package ru.vrata.backend.domain.model;

import java.time.Instant;

public record AuthSession(Long userId, String username, String accessToken, Instant expiresAt) {
    public AuthSession {
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("user id must be positive");
        }
        username = User.normalizeUsername(username);
        if (accessToken == null || accessToken.isBlank()) {
            throw new IllegalArgumentException("access token must not be blank");
        }
        accessToken = accessToken.trim();
        if (expiresAt == null) {
            throw new IllegalArgumentException("expiresAt must not be null");
        }
    }

    public boolean isExpiredAt(Instant timestamp) {
        if (timestamp == null) {
            throw new IllegalArgumentException("timestamp must not be null");
        }
        return !expiresAt.isAfter(timestamp);
    }

    public boolean isExpired() {
        return isExpiredAt(Instant.now());
    }
}
