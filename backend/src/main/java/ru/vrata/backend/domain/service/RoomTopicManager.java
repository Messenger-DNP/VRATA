package ru.vrata.backend.domain.service;

public interface RoomTopicManager {
    void createRoomTopic(Long roomId);

    void deleteRoomTopic(Long roomId);
}
