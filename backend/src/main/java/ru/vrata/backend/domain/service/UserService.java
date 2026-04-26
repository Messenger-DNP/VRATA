package ru.vrata.backend.domain.service;

import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.exception.InvalidCredentialsException;
import ru.vrata.backend.domain.exception.UserAlreadyExistsException;
import ru.vrata.backend.domain.model.AuthSession;
import ru.vrata.backend.domain.model.User;
import ru.vrata.backend.domain.repository.UserRepository;
import ru.vrata.backend.infrastructure.mongo.service.MongoCounterService;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class UserService {
    private static final Duration AUTH_TOKEN_TTL = Duration.ofHours(12);

    private final UserRepository userRepository;
    private final MongoCounterService mongoCounterService;

    public UserService(UserRepository userRepository,
                       MongoCounterService mongoCounterService) {
        this.userRepository = userRepository;
        this.mongoCounterService = mongoCounterService;
    }

    public synchronized AuthSession register(String username, String rawPassword) {
        var normalizedUsername = normalizeUsername(username);
        validateUserIsNotTaken(normalizedUsername);

        var user = new User(
                mongoCounterService.nextUserId(),
                normalizedUsername,
                hashPassword(rawPassword)
        );
        userRepository.create(user);

        return createAuthSession(user);
    }

    public AuthSession login(String username, String rawPassword) {
        var normalizedUsername = normalizeUsername(username);
        var user = userRepository.findByUsername(normalizedUsername)
                .orElseThrow(InvalidCredentialsException::new);

        if (!user.matchesPasswordHash(hashPassword(rawPassword))) {
            throw new InvalidCredentialsException();
        }

        return createAuthSession(user);
    }

    private void validateUserIsNotTaken(String username) {
        if (userRepository.findByUsername(username).isPresent()) {
            throw new UserAlreadyExistsException(username);
        }
    }

    private AuthSession createAuthSession(User user) {
        return new AuthSession(
                user.id(),
                user.username(),
                UUID.randomUUID().toString(),
                Instant.now().plus(AUTH_TOKEN_TTL)
        );
    }

    private String normalizeUsername(String username) {
        try {
            return User.normalizeUsername(username);
        } catch (IllegalArgumentException exception) {
            throw new InvalidCredentialsException();
        }
    }

    private String hashPassword(String rawPassword) {
        if (rawPassword == null || rawPassword.isBlank()) {
            throw new InvalidCredentialsException();
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawPassword.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 algorithm is unavailable", exception);
        }
    }
}