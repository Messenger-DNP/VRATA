package ru.vrata.backend.domain.repository.inmemory;

import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.User;
import ru.vrata.backend.domain.repository.UserRepository;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class InMemoryUserRepository implements UserRepository {
    private final Map<Long, User> usersById = new ConcurrentHashMap<>();
    private final Map<String, User> usersByUsername = new ConcurrentHashMap<>();

    @Override
    public Optional<User> findById(Long id) {
        return Optional.ofNullable(usersById.get(id));
    }

    @Override
    public Optional<User> findByUsername(String username) {
        try {
            String normalized = User.normalizeUsername(username);
            return Optional.ofNullable(usersByUsername.get(normalized));
        } catch (IllegalArgumentException exception) {
            return Optional.empty();
        }
    }

    @Override
    public User create(User user) {
        usersById.put(user.id(), user);
        usersByUsername.put(user.username(), user);
        return user;
    }
}
