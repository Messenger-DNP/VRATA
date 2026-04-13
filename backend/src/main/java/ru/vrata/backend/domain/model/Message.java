package ru.vrata.backend.domain.model;

import java.util.UUID;

public record Message(UUID id, Long roomId, Long userId, String username, String content) {
    public Message {
        if (id == null) {
            throw new IllegalArgumentException("message id must not be null");
        }
        if (roomId == null || roomId <= 0) {
            throw new IllegalArgumentException("room id must be positive");
        }
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("user id must be positive");
        }
        username = User.normalizeUsername(username);
        content = normalizeContent(content);
    }

    public static Message create(Long roomId, Long userId, String username, String content) {
        return new Message(UUID.randomUUID(), roomId, userId, username, content);
    }

    public static String normalizeContent(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("message content must not be blank");
        }
        String normalized = raw.trim();
        if (normalized.length() > 2000) {
            throw new IllegalArgumentException("message content must be <= 2000");
        }
        return normalized;
    }

    public boolean belongsToRoom(Long candidateRoomId) {
        return roomId.equals(candidateRoomId);
    }

    public boolean writtenBy(Long candidateUserId) {
        return userId.equals(candidateUserId);
    }
}
