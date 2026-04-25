package ru.vrata.backend.api.message;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import ru.vrata.backend.api.message.dto.MessageResponse;
import ru.vrata.backend.api.message.dto.SendMessageRequest;
import ru.vrata.backend.domain.service.MessageService;

import java.util.List;

@RestController
@RequestMapping("/api/v1")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }

    @PostMapping("/messages")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void send(@Valid @RequestBody SendMessageRequest request) {
        messageService.sendMessage(
                request.roomId(),
                request.userId(),
                request.username(),
                request.content()
        );
    }

    @GetMapping("/rooms/{roomId}/messages")
    public List<MessageResponse> getRoomMessages(@PathVariable Long roomId)
    {
        return messageService.getMessagesForRoom(roomId).stream()
                .map(MessageResponse::from)
                .toList();
    }
}
