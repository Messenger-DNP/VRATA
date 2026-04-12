package ru.vrata.backend.api.common.dto;

import java.time.Instant;

public record ErrorResponse(String code, String message, Instant timestamp) {
}
