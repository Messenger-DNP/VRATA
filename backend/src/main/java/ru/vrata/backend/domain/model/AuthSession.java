package ru.vrata.backend.domain.model;

import java.time.Instant;

public record AuthSession(Long userId, String username, String accessToken, Instant expiresAt) {
}
