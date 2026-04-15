package ru.vrata.backend.api.room.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record CreateRoomRequest(
        @NotNull(message = "userId is required")
        @Positive(message = "userId must be positive")
        Long userId,

        @Size(max = 100, message = "name length must be at most 100 characters")
        String name
) {
}
