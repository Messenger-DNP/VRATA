package ru.vrata.backend.api.room.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record JoinRoomRequest(
        @NotNull(message = "userId is required")
        @Positive(message = "userId must be positive")
        Long userId,

        @NotBlank(message = "inviteCode is required")
        @Size(min = 6, max = 6, message = "inviteCode length must be 6 characters")
        @Pattern(regexp = "^[A-Za-z]{6}$", message = "inviteCode must contain Latin letters only")
        String inviteCode
) {
}
