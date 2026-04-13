package ru.vrata.backend.domain.service;

import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.repository.ChatRoomRepository;

@Service
public class ChatRoomService {
    private final ChatRoomRepository chatRoomRepository;

    public ChatRoomService(ChatRoomRepository chatRoomRepository) {
        this.chatRoomRepository = chatRoomRepository;
    }

    // TODO: room create/join
}
