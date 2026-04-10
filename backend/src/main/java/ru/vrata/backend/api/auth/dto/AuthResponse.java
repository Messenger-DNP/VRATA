package ru.vrata.backend.api.auth.dto;

import ru.vrata.backend.domain.model.AuthSession;

import java.time.Instant;

public record AuthResponse(
        Long userId,
        String username,
        String tokenType,
        String accessToken,
        Instant expiresAt
) {
    public static AuthResponse from(AuthSession authSession) {
        return new AuthResponse(
                authSession.userId(),
                authSession.username(),
                "Bearer",
                authSession.accessToken(),
                authSession.expiresAt()
        );
    }
}
