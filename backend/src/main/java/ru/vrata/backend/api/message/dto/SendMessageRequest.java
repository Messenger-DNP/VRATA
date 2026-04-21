package ru.vrata.backend.api.message.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record SendMessageRequest(
        @NotNull(message = "roomId is required")
        @Positive(message = "roomId must be positive")
        Long roomId,

        @NotNull(message = "userId is required")
        @Positive(message = "userId must be positive")
        Long userId,

        @NotBlank(message = "username is required")
        @Size(min = 3, max = 50, message = "username length must be between 3 and 50 characters")
        String username,

        @NotBlank(message = "content is required")
        @Size(max = 2000, message = "content length must be at most 2000 characters")
        String content
) {
}
