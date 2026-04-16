package ru.vrata.backend.api.room;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.vrata.backend.api.room.dto.CreateRoomRequest;
import ru.vrata.backend.api.room.dto.JoinRoomRequest;
import ru.vrata.backend.api.room.dto.LeaveRoomRequest;
import ru.vrata.backend.api.room.dto.LeaveRoomResponse;
import ru.vrata.backend.api.room.dto.RoomResponse;
import ru.vrata.backend.domain.service.ChatRoomService;

@RestController
@RequestMapping("/api/v1/rooms")
public class RoomController {
    private final ChatRoomService chatRoomService;

    public RoomController(ChatRoomService chatRoomService) {
        this.chatRoomService = chatRoomService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public RoomResponse create(@Valid @RequestBody CreateRoomRequest request) {
        var room = chatRoomService.createRoom(request.userId(), request.name());
        return RoomResponse.from(room);
    }

    @PostMapping("/join")
    public RoomResponse join(@Valid @RequestBody JoinRoomRequest request) {
        var room = chatRoomService.joinRoom(request.userId(), request.inviteCode());
        return RoomResponse.from(room);
    }

    @PostMapping("/leave")
    public LeaveRoomResponse leave(@Valid @RequestBody LeaveRoomRequest request) {
        var result = chatRoomService.leaveRoom(request.userId());
        return LeaveRoomResponse.from(result);
    }
}
