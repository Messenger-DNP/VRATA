package ru.vrata.backend.domain.model;

import java.util.Locale;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Pattern;

public record ChatRoom(Long id, String name, String inviteCode) {
    private static final Pattern INVITE_CODE_PATTERN = Pattern.compile("^[a-z]{6}$");
    private static final int INVITE_CODE_LENGTH = 6;

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
        String normalized = raw.trim().toLowerCase(Locale.ROOT);
        if (!INVITE_CODE_PATTERN.matcher(normalized).matches()) {
            throw new IllegalArgumentException("invite code must be 6 lowercase Latin letters");
        }
        return normalized;
    }

    public boolean hasInviteCode(String candidate) {
        return inviteCode.equals(normalizeInviteCode(candidate));
    }

    private static String generateInviteCode() {
        StringBuilder code = new StringBuilder(INVITE_CODE_LENGTH);
        for (int i = 0; i < INVITE_CODE_LENGTH; i++) {
            code.append((char) ('a' + ThreadLocalRandom.current().nextInt(26)));
        }
        return code.toString();
    }
}
