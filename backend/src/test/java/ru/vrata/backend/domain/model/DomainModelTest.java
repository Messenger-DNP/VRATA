package ru.vrata.backend.domain.model;

import org.junit.jupiter.api.Test;
import ru.vrata.backend.infrastructure.kafka.KafkaMessage;

import java.time.Instant;
import java.util.UUID;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DomainModelTest {
    private static final Pattern INVITE_CODE_PATTERN = Pattern.compile("^[a-z]{6}$");

    @Test
    void userShouldNormalizeAndValidate() {
        String hash = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        User user = new User(1L, "  rolan  ", hash);

        assertTrue(user.hasUsername("rolan"));
        assertTrue(user.hasUsername("  RoLaN "));
        assertTrue(user.matchesPasswordHash(hash.toLowerCase()));
    }

    @Test
    void chatRoomShouldGenerateInviteCode() {
        ChatRoom room = ChatRoom.create(1L, " Main room ");

        assertTrue(room.hasInviteCode(room.inviteCode().toLowerCase()));
        assertTrue(room.hasInviteCode(room.inviteCode().toUpperCase()));
        assertTrue(INVITE_CODE_PATTERN.matcher(room.inviteCode()).matches());
    }

    @Test
    void chatRoomShouldRejectInvalidInviteCode() {
        assertThrows(IllegalArgumentException.class, () -> ChatRoom.normalizeInviteCode("abc12x"));
        assertThrows(IllegalArgumentException.class, () -> ChatRoom.normalizeInviteCode("abcde"));
        assertThrows(IllegalArgumentException.class, () -> ChatRoom.normalizeInviteCode("abcdefg"));
    }

    @Test
    void messageShouldValidateFields() {
        Message message = Message.create(1L, 1L, " rolan ", " hi ");

        assertTrue(message.belongsToRoom(1L));
        assertTrue(message.writtenBy(1L));
    }

    @Test
    void messageFromKafkaShouldKeepStableId() {
        String rawId = UUID.randomUUID().toString();
        KafkaMessage kafkaMessage = new KafkaMessage(
                rawId,
                1L,
                1L,
                "rolan",
                "hello",
                Instant.parse("2026-04-25T08:00:00Z")
        );

        Message first = Message.from(kafkaMessage);
        Message second = Message.from(kafkaMessage);

        assertEquals(UUID.fromString(rawId), first.id());
        assertEquals(first.id(), second.id());
    }

    @Test
    void authSessionShouldTrackExpiration() {
        AuthSession active = new AuthSession(1L, "rolan", "token", Instant.now().plusSeconds(60));
        AuthSession expired = new AuthSession(1L, "rolan", "token", Instant.now().minusSeconds(60));

        assertFalse(active.isExpired());
        assertTrue(expired.isExpired());
    }

    @Test
    void userShouldRejectBadHash() {
        assertThrows(IllegalArgumentException.class, () -> new User(1L, "rolan", "plain-password"));
        assertDoesNotThrow(() -> new User(1L, "rolan", "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"));
    }
}
