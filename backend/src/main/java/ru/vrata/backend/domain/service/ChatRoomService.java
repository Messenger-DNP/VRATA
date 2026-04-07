package ru.vrata.backend.domain.service;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import ru.vrata.backend.domain.repository.ChatRoomRepository;

@AllArgsConstructor
@Service
public class ChatRoomService {
    private final ChatRoomRepository chatRoomRepository;

    // TODO (logic): create room, generate room ID, invite code, join room by invite code
}
