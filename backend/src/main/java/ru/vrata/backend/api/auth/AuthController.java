package ru.vrata.backend.api.auth;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.vrata.backend.api.auth.dto.AuthResponse;
import ru.vrata.backend.api.auth.dto.LoginRequest;
import ru.vrata.backend.api.auth.dto.RegisterRequest;
import ru.vrata.backend.domain.service.UserService;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthResponse register(@Valid @RequestBody RegisterRequest request) {
        var session = userService.register(request.username(), request.password());
        return AuthResponse.from(session);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        var session = userService.login(request.username(), request.password());
        return AuthResponse.from(session);
    }
}
