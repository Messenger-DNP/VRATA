import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/chat_lobby/chat_lobby_providers.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_lobby_failure.dart';
import 'package:frontend/features/chat_lobby/domain/entities/chat_room.dart';
import 'package:frontend/features/chat_room/domain/entities/chat_message.dart';
import 'package:frontend/features/chat_room/presentation/controllers/chat_messages_controller.dart';
import 'package:frontend/features/chat_room/presentation/state/chat_messages_state.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.chatId, super.key, this.room});

  final int chatId;
  final ChatRoom? room;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLeaveConfirmationOpen = false;
  bool _isLeavingRoom = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerProvider = chatMessagesControllerProvider(widget.chatId);

    ref.listen<ChatMessagesState>(controllerProvider, (previous, next) {
      final previousCount = previous?.messages.length ?? 0;
      if (next.messages.length > previousCount && _isNearBottom()) {
        _scrollToBottom();
      }
    });

    final theme = Theme.of(context);
    final session = ref.watch(authSessionProvider);
    final state = ref.watch(controllerProvider);
    final controller = ref.read(controllerProvider.notifier);
    final title = widget.room?.name ?? 'Chat #${widget.chatId}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ChatHeader(
                    title: title,
                    username: session?.username,
                    inviteCode: widget.room?.inviteCode,
                    isLeavingRoom: _isLeaveConfirmationOpen || _isLeavingRoom,
                    onCopyInviteCode: widget.room == null
                        ? null
                        : () => _copyInviteCode(widget.room!.inviteCode),
                    onLeaveRoom: _showLeaveRoomConfirmation,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withAlpha(220),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: _MessagesPanel(
                        state: state,
                        currentUserId: session?.userId,
                        scrollController: _scrollController,
                        onRetry: controller.refreshMessages,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MessageComposer(
                    controller: _messageController,
                    state: state,
                    onSend: () => _sendMessage(controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(ChatMessagesController controller) async {
    final sent = await controller.sendMessage(_messageController.text);
    if (sent && mounted) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _copyInviteCode(String inviteCode) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Invite code copied.')));
  }

  Future<void> _showLeaveRoomConfirmation() async {
    if (_isLeaveConfirmationOpen || _isLeavingRoom) {
      return;
    }

    setState(() {
      _isLeaveConfirmationOpen = true;
    });

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave room?'),
          content: const Text(
            'If you leave this room, you will be able to join it again only by invite code. Make sure you saved the room invite code.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLeaveConfirmationOpen = false;
    });

    if (shouldLeave ?? false) {
      await _leaveRoom();
    }
  }

  Future<void> _leaveRoom() async {
    if (_isLeavingRoom) {
      return;
    }

    final session = ref.read(authSessionProvider);
    if (session == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please log in again to leave the room.')),
        );
      return;
    }

    setState(() {
      _isLeavingRoom = true;
    });

    try {
      await ref.read(leaveChatUseCaseProvider).call(userId: session.userId);

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.lobby);
    } on ChatLobbyFailureException catch (exception) {
      if (!mounted) {
        return;
      }

      final message = switch (exception.failure) {
        NetworkChatLobbyFailure(:final message) => message,
        ValidationChatLobbyFailure(:final message) => message,
        ServerChatLobbyFailure(:final message) => message,
        UnknownChatLobbyFailure(:final message) => message,
        _ => 'Could not leave room. Please try again.',
      };

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not leave room. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLeavingRoom = false;
        });
      }
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 140;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.username,
    required this.inviteCode,
    required this.isLeavingRoom,
    required this.onCopyInviteCode,
    required this.onLeaveRoom,
  });

  final String title;
  final String? username;
  final String? inviteCode;
  final bool isLeavingRoom;
  final VoidCallback? onCopyInviteCode;
  final VoidCallback onLeaveRoom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withAlpha(18),
            foregroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.forum_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username == null ? 'Signed out' : 'Signed in as $username',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(145),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (inviteCode != null && onCopyInviteCode != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: 'Copy invite code',
              child: IconButton(
                onPressed: onCopyInviteCode,
                icon: const Icon(Icons.copy_rounded),
              ),
            ),
          ],
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: isLeavingRoom ? null : onLeaveRoom,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              disabledForegroundColor: theme.colorScheme.error.withAlpha(110),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Leave room'),
          ),
        ],
      ),
    );
  }
}

class _MessagesPanel extends StatelessWidget {
  const _MessagesPanel({
    required this.state,
    required this.currentUserId,
    required this.scrollController,
    required this.onRetry,
  });

  final ChatMessagesState state;
  final int? currentUserId;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const _PanelState(
        icon: Icons.more_horiz_rounded,
        title: 'Loading messages',
        message: 'One moment.',
        isLoading: true,
      );
    }

    if (state.isInitialFailure) {
      return _PanelState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load messages',
        message: state.errorMessage ?? 'Please try again.',
        action: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }

    if (state.isEmpty) {
      return Column(
        children: [
          if (state.errorMessage != null)
            _InlineStatus(message: state.errorMessage!, isError: true),
          const Expanded(
            child: _PanelState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              message: 'Send the first message below.',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (state.errorMessage != null)
          _InlineStatus(message: state.errorMessage!, isError: true),
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
            itemBuilder: (context, index) {
              final message = state.messages[index];
              return _MessageBubble(
                message: message,
                isMine: message.userId == currentUserId,
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemCount: state.messages.length,
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withAlpha(14);
    final foregroundColor = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * .78),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine) ...[
                      Text(
                        message.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foregroundColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.state,
    required this.onSend,
  });

  final TextEditingController controller;
  final ChatMessagesState state;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.sendErrorMessage != null) ...[
            _InlineStatus(message: state.sendErrorMessage!, isError: true),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !state.isSending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: ChatMessagesController.maxMessageLength,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!state.isSending) {
                      onSend();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox.square(
                dimension: 52,
                child: IconButton.filled(
                  onPressed: state.isSending ? null : onSend,
                  tooltip: 'Send',
                  icon: state.isSending
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelState extends StatelessWidget {
  const _PanelState({
    required this.icon,
    required this.title,
    required this.message,
    this.isLoading = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isLoading;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox.square(
                dimension: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Icon(
                icon,
                size: 42,
                color: theme.colorScheme.onSurface.withAlpha(105),
              ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(145),
                height: 1.35,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
