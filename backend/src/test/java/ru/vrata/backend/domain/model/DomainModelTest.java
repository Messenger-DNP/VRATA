package ru.vrata.backend.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DomainModelTest {

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
    }

    @Test
    void messageShouldValidateFields() {
        Message message = Message.create(1L, 1L, " rolan ", " hi ");

        assertTrue(message.belongsToRoom(1L));
        assertTrue(message.writtenBy(1L));
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
