import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/features/chat_lobby/presentation/controllers/create_chat_controller.dart';
import 'package:frontend/features/chat_lobby/presentation/widgets/chat_lobby_text_field.dart';
import 'package:frontend/features/chat_lobby/presentation/widgets/invite_code_card.dart';
import 'package:go_router/go_router.dart';

class CreateChatScreen extends ConsumerStatefulWidget {
  const CreateChatScreen({super.key});

  @override
  ConsumerState<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends ConsumerState<CreateChatScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createChatControllerProvider, (previous, next) {
      final room = next.room;
      if (room == null || previous?.room?.id == room.id) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Chat created. Code: ${room.inviteCode}')),
        );

      context.go(AppRoutes.chatPath(room.id), extra: room);
    });

    final theme = Theme.of(context);
    final state = ref.watch(createChatControllerProvider);
    final controller = ref.read(createChatControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create chat'),
        leading: IconButton(
          onPressed: state.isLoading ? null : () => context.go(AppRoutes.lobby),
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Name your chat',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a shared space for your team or friends.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(155),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withAlpha(210),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChatLobbyTextField(
                          controller: _nameController,
                          label: 'Chat name',
                          hintText: 'Example: Project Mars',
                          helperText: '3-100 characters.',
                          enabled: !state.isLoading,
                          textInputAction: TextInputAction.done,
                          errorText: state.nameError,
                          onChanged: (_) => controller.onFormChanged(),
                          onSubmitted: (_) => _submit(controller),
                        ),
                        if (state.submissionError != null) ...[
                          const SizedBox(height: 16),
                          _InlineFeedback(message: state.submissionError!),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => _submit(controller),
                          icon: state.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(state.isSuccess ? 'Created' : 'Create'),
                        ),
                      ],
                    ),
                  ),
                  if (state.room != null) ...[
                    const SizedBox(height: 28),
                    _CreateSuccessPanel(
                      inviteCode: state.room!.inviteCode,
                      onCopy: () => _copyInviteCode(state.room!.inviteCode),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(CreateChatController controller) {
    controller.submit(name: _nameController.text);
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
}

class _CreateSuccessPanel extends StatelessWidget {
  const _CreateSuccessPanel({
    required this.inviteCode,
    required this.onCopy,
  });

  final String inviteCode;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.check_circle_rounded),
          ),
          const SizedBox(height: 18),
          Text(
            'Chat created successfully',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this code to invite participants.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 18),
          InviteCodeCard(inviteCode: inviteCode, onCopy: onCopy),
        ],
      ),
    );
  }
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
