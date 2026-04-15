package ru.vrata.backend.domain.exception;

public class RoomNotFoundException extends RuntimeException {
    public RoomNotFoundException(String inviteCode) {
        super("Room with invite code '%s' not found".formatted(inviteCode));
    }
}
