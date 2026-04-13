package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ru.vrata.backend.domain.exception.InvalidCredentialsException;
import ru.vrata.backend.domain.exception.UserAlreadyExistsException;
import ru.vrata.backend.domain.model.User;
import ru.vrata.backend.domain.repository.inmemory.InMemoryUserRepository;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class UserServiceTest {
    private UserService userService;
    private InMemoryUserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository = new InMemoryUserRepository();
        userService = new UserService(userRepository);
    }

    @Test
    void registerShouldCreateAuthSession() {
        var authSession = userService.register("rolan", "StrongPassword123");

        assertEquals(1L, authSession.userId());
        assertEquals("rolan", authSession.username());
        assertNotNull(authSession.accessToken());
        assertNotNull(authSession.expiresAt());
    }

    @Test
    void registerShouldFailWhenUserAlreadyExists() {
        userService.register("rolan", "StrongPassword123");

        assertThrows(UserAlreadyExistsException.class, () -> userService.register("rolan", "AnotherStrongPassword"));
    }

    @Test
    void registerShouldFailWhenUserAlreadyExistsWithDifferentCase() {
        userService.register("rolan", "StrongPassword123");

        assertThrows(UserAlreadyExistsException.class, () -> userService.register("RoLaN", "AnotherStrongPassword"));
    }

    @Test
    void loginShouldReturnAuthSessionForValidCredentials() {
        userService.register("rolan", "StrongPassword123");

        var authSession = userService.login("rolan", "StrongPassword123");

        assertEquals("rolan", authSession.username());
        assertNotNull(authSession.accessToken());
    }

    @Test
    void loginShouldFailForInvalidPassword() {
        userService.register("rolan", "StrongPassword123");

        assertThrows(InvalidCredentialsException.class, () -> userService.login("rolan", "wrong-password"));
    }

    @Test
    void registerShouldNormalizeUsernameAndStoreHash() {
        userService.register("  RoLaN  ", "StrongPassword123");

        User savedUser = userRepository.findByUsername("rolan").orElseThrow();

        assertEquals("rolan", savedUser.username());
        assertNotEquals("StrongPassword123", savedUser.password());
        assertEquals(64, savedUser.password().length());
    }

    @Test
    void loginShouldWorkWithTrimmedAndCaseInsensitiveUsername() {
        userService.register("rolan", "StrongPassword123");

        var authSession = userService.login("  RoLaN  ", "StrongPassword123");

        assertEquals("rolan", authSession.username());
    }

    @Test
    void registerShouldFailForBlankUsername() {
        assertThrows(InvalidCredentialsException.class, () -> userService.register("   ", "StrongPassword123"));
    }

    @Test
    void registerShouldFailForBlankPassword() {
        assertThrows(InvalidCredentialsException.class, () -> userService.register("rolan", "   "));
    }
}
