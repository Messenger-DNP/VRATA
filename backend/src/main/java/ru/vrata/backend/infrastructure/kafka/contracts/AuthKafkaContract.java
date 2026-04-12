package ru.vrata.backend.infrastructure.kafka.contracts;

/**
 * Shared constants for producer/consumer teams.
 * This file describes contracts only and does not contain Kafka business logic.
 */
public final class AuthKafkaContract {
    public static final String AUTH_EVENTS_TOPIC = "auth.events.v1";
    public static final String AUTH_EVENTS_CONSUMER_GROUP = "chat-auth-consumers";
    public static final String USER_REGISTERED_EVENT = "USER_REGISTERED";
    public static final String USER_LOGGED_IN_EVENT = "USER_LOGGED_IN";

    private AuthKafkaContract() {
    }
}
