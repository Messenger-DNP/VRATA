package ru.vrata.backend.domain.model;

import java.util.Locale;
import java.util.UUID;
import java.util.regex.Pattern;

public record ChatRoom(Long id, String name, String inviteCode) {
    private static final Pattern INVITE_CODE_PATTERN = Pattern.compile("^[A-Z0-9]{8}$");

    public ChatRoom {
        if (id == null || id <= 0) {
            throw new IllegalArgumentException("chat room id must be positive");
        }
        name = normalizeName(name);
        inviteCode = normalizeInviteCode(inviteCode);
    }

    public static ChatRoom create(Long id, String name) {
        return new ChatRoom(id, name, generateInviteCode());
    }

    public static String normalizeName(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("room name must not be blank");
        }
        String normalized = raw.trim();
        if (normalized.length() < 3 || normalized.length() > 100) {
            throw new IllegalArgumentException("room name length must be between 3 and 100");
        }
        return normalized;
    }

    public static String normalizeInviteCode(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("invite code must not be blank");
        }
        String normalized = raw.trim().toUpperCase(Locale.ROOT);
        if (!INVITE_CODE_PATTERN.matcher(normalized).matches()) {
            throw new IllegalArgumentException("invite code must be 8 chars A-Z0-9");
        }
        return normalized;
    }

    public boolean hasInviteCode(String candidate) {
        return inviteCode.equals(normalizeInviteCode(candidate));
    }

    private static String generateInviteCode() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase(Locale.ROOT);
    }
}
