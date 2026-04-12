package ru.vrata.backend.api.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "username is required")
        @Size(min = 3, max = 50, message = "username length must be between 3 and 50 characters")
        String username,

        @NotBlank(message = "password is required")
        @Size(min = 8, max = 128, message = "password length must be between 8 and 128 characters")
        String password
) {
}
