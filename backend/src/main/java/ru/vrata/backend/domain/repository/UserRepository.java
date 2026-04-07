package ru.vrata.backend.domain.repository;

import ru.vrata.backend.domain.model.User;

import java.util.Optional;

public interface UserRepository {
    Optional<User> findById(Long id);

    Optional<User> findByUsername(String username);

    User save(User user);
}
