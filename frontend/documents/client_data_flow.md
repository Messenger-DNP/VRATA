# Client-Side Data Flow

This document describes how data moves through the Flutter client.

## Global Flow

The app follows a feature-first architecture with layer separation:

```text
Forward: 
  UI / Screen 
  -> Controller (Riverpod) 
  -> Use Case
  -> Repository (interface) 
  -> Repository (implementation)
  -> Data Source 
  -> Backend

Reverse: 
  Backend 
  -> Data Source 
  -> DTO 
  -> Mapper
  -> Domain Entity / Failure 
  -> Controller State 
  -> UI
```

## Shared Infrastructure

| File / Provider | Role |
| --- | --- |
| `main.dart` | initializes `ProviderScope` and `MaterialApp.router` |
| `app_router.dart` | handles navigation and auth redirects |
| `authSessionProvider` | stores the current in-memory session |
| `ApiConfig.baseUrl` | provides backend URL via `VRATA_API_BASE_URL` |

## Auth Flow

Handles login, registration, and session state.

### Entry Points

| Route | Screen |
| --- | --- |
| `/welcome` | `WelcomeScreen` |
| `/login` | `LoginScreen` |
| `/register` | `RegisterScreen` |

### Login

```text
LoginScreen 
  -> LoginController.submit() 
  -> AuthFormValidator
  -> LoginUseCase 
  -> AuthRepository 
  -> RemoteAuthRepository
  -> AuthRemoteDatasource 
  -> POST /api/v1/auth/login
```

### Registration

```text
RegisterScreen 
  -> RegisterController.submit() 
  -> AuthFormValidator
  -> RegisterUseCase 
  -> AuthRepository 
  -> RemoteAuthRepository
  -> AuthRemoteDatasource 
  -> POST /api/v1/auth/register
```

### Response Handling

```text
Backend response 
  -> DTO (success/error) 
  -> Mapper
  -> Domain (AuthSession / AuthFailure)
  -> Controller state 
  -> UI feedback / navigation
```

### State

```text
idle -> loading -> success | failure
```

Session is stored in memory only (not persisted).

### Error Handling

Client validation runs before API calls.

Backend errors are mapped to:

- invalid credentials
- user exists
- validation
- network
- server
- unknown

## Chat Lobby Flow

Handles room creation and joining.

### Entry Points

| Route | Screen |
| --- | --- |
| `/lobby` | `LobbyScreen` |
| `/create-chat` | `CreateChatScreen` |
| `/join-chat` | `JoinChatScreen` |

### Create Room

```text
CreateChatScreen 
  -> CreateChatController.submit() 
  -> Validator
  -> CreateChatUseCase 
  -> Repository 
  -> DataSource
  -> POST /api/v1/rooms
```

### Join Room

```text
JoinChatScreen 
  -> JoinChatController.submit() 
  -> Validator
  -> JoinChatUseCase 
  -> Repository 
  -> DataSource
  -> POST /api/v1/rooms/join
```

### Response

```text
Backend response 
  -> RoomResponseDto 
  -> Mapper 
  -> ChatRoom
  -> State update 
  -> Navigate to /chat/:chatId
```

### State

```text
idle -> loading -> success(room) | failure
```

Duplicate submits are prevented while loading.

## Chat Room Flow

Handles message history, sending, and live updates.

### Communication Model

| Flow | Transport |
| --- | --- |
| History | REST |
| Send | REST |
| Live | WebSocket/STOMP |

### Entry Point

| Route | Screen |
| --- | --- |
| `/chat/:chatId` | `ChatScreen` |

### Load History

```text
ChatScreen 
  -> ChatMessagesController 
  -> LoadChatMessagesUseCase
  -> Repository 
  -> DataSource
  -> GET /api/v1/rooms/{roomId}/messages
```

### Live Messages

```text
Controller 
  -> ObserveChatMessagesUseCase 
  -> Repository
  -> Realtime DataSource 
  -> WebSocket/STOMP connect
  -> SUBSCRIBE /topic/rooms/{roomId}/messages

STOMP message 
  -> DTO 
  -> Mapper 
  -> ChatMessage
  -> Controller state 
  -> UI
```

### Send Message

```text
Composer 
  -> Controller.sendMessage() 
  -> UseCase 
  -> Repository
  -> DataSource 
  -> POST /api/v1/messages
```

Payload:

```text
roomId
userId
username
content
```

### State

- loading
- ready (messages)
- empty
- error
- sending
- send error

### Lifecycle

```text
On open:    load history -> connect websocket -> subscribe
On dispose: unsubscribe -> disconnect
```

## Cross-Cutting Rules

### Layer Responsibilities

| Layer | Owns |
| --- | --- |
| Presentation | UI, controllers, state |
| Domain | entities, use cases, repository interfaces |
| Data | DTOs, mappers, datasources, repository implementations |

### Error Flow

```text
Backend error 
  -> DataSource exception 
  -> Repository maps failure
  -> Controller maps message 
  -> UI displays error
```

### State Pattern

```text
loading -> success(data) -> failure(error)
```

## Limitations

- Session is not persisted
- Access token is not used in requests
- Message ordering depends on backend
- WebSocket is receive-only; sending is REST

## Implemented Features

```text
features/auth
features/chat_lobby
features/chat_room
```
