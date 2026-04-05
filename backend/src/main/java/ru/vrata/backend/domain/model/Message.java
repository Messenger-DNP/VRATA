package ru.vrata.backend.domain.model;

import java.util.UUID;

public record Message(UUID id, Long roomId, Long userId, String username, String content) {
}