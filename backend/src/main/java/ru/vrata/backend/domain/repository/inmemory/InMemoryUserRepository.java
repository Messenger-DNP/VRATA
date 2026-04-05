package ru.vrata.backend.domain.repository.inmemory;

import org.springframework.stereotype.Repository;
import ru.vrata.backend.domain.model.User;
import ru.vrata.backend.domain.repository.UserRepository;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Repository
public class InMemoryUserRepository implements UserRepository {
    private final Map<Long, User> users = new ConcurrentHashMap<>();

    @Override
    public Optional<User> findById(Long id) {
        return Optional.ofNullable(users.get(id));
    }

    @Override
    public Optional<User> findByUsername(String username) {
        return users.values().stream()
                .filter(user -> user.username().equals(username))
                .findFirst();
    }

    @Override
    public User save(User user) {
        users.put(user.id(), user);
        return user;
    }
}
