package ru.vrata.backend.domain.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import ru.vrata.backend.domain.exception.InvalidCredentialsException;
import ru.vrata.backend.domain.exception.UserAlreadyExistsException;
import ru.vrata.backend.domain.repository.inmemory.InMemoryUserRepository;
import ru.vrata.backend.infrastructure.mongo.service.MongoCounterService;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

class UserServiceTest {
    private UserService userService;
    private MongoCounterService mongoCounterService;

    @BeforeEach
    void setUp() {
        mongoCounterService = Mockito.mock(MongoCounterService.class);

        when(mongoCounterService.nextUserId())
                .thenReturn(1L, 2L, 3L, 4L, 5L);

        userService = new UserService(new InMemoryUserRepository(), mongoCounterService);
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

        assertThrows(UserAlreadyExistsException.class, () ->
                userService.register("rolan", "AnotherStrongPassword"));
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

        assertThrows(InvalidCredentialsException.class, () ->
                userService.login("rolan", "wrong-password"));
    }
}